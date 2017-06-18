package schwafenthaeler::Entry;
use Dancer ':syntax';
use Data::Dumper;
use Date::Format;
use Encode;
use Image::ExifTool;
use Image::Size;
use Imager;
use JSON qw/decode_json encode_json/;
use List::Util qw/max/;
use Path::Tiny;
use Text::Markdown qw/markdown/;

my $fetchedEntries = false;
my %entries;

refreshEntries();

sub addEntry {
	debug "Adding entry";
	my $entry = shift;

	my $id = getNewID();

	my $path = path(config->{public}, 'entries', $id);
	mkdir($path) or die("Unable to create path: $!");

	open(my $text, ">", path($path, 'entry.txt')) or die("Unable to create entry: $!");
	binmode($text, ':utf8');
	print $text $entry->{date}."\n";
	print $text $entry->{subject}."\n";
	print $text $entry->{body} // '';
	close($text);

	for my $image (@{$entry->{images}}) {
		my $i = path($image->{tempfile});

		$i->copy(path($path, $image->{filename})) or die("Unable to move image ".$image->{filename}.": ".$!);
		$i->remove();

		fixJpegRotation(path($path, $image->{filename})->stringify);
	}
	writeImageSizes($id);

	refreshEntries();
}

sub getNewID {
	debug "Generating new entry id";
	if(scalar(keys(%entries)) > 0) {
		return max(keys(%entries)) + 1;
	}
	else {
		debug "Defaulting to entry id 1";
		return 1;
	}
}

sub getEntry {
	my $id = shift;
	return $entries{$id} // {};
}

sub getAllEntries {
	my @entryList;
	for(reverse(sort {$a <=> $b} (keys(%entries)))) {
		push(@entryList, $entries{$_});
	}
	return \@entryList;
}

sub getRecentEntries {
	my @entries = @{getAllEntries()};
	my $count = config->{recentEntries};
	if($#entries < config->{recentEntries}) {
		$count = $#entries-1;
	}

	my @recent = @entries[0..$count];
	return \@recent;
}

sub refreshEntries {
	my $entryPath = path(config->{public}, 'entries');

	my %tempEntries;

	opendir(my $dir, $entryPath) or die("Unable to open entries path: $!");
	while(my $entry = readdir($dir)) {
		next if($entry !~ /^\d+$/);

		$tempEntries{$entry} = readEntryFromDisk($entry);
	}
	closedir($dir);

	%entries = %tempEntries;
}


sub readEntryFromDisk {
	my $id = shift;
	my $entry;

	my $entryPath = path(config->{public}, 'entries', $id);

	if(!-f path($entryPath, 'entry.txt')) {
		warning "Invalid entry $id, skipping";
		return {};
	}

	my @body = path($entryPath, 'entry.txt')->lines_utf8;
	$entry->{id} = $id;
	$entry->{date} = time2str('%d.%m.%Y, %H:%m', shift(@body));
	$entry->{title} = shift(@body);
	$entry->{text} = join('', @body);
	$entry->{text_rendered} = markdown($entry->{text});

	$entry->{images} = getImagesForEntry($id);

	if(!path($entryPath, 'images.json')->is_file) {
		writeImageSizes($id);
	}

	my $imageSizes = decode_json(path($entryPath, 'images.json')->slurp_utf8);
	$entry->{imageSizes} = $imageSizes;

	return $entry;
}

sub getImagesForEntry {
	my $id = shift;
	my @images;

	my $entryPath = path(config->{public}, 'entries', $id);

	my $fileIterator = $entryPath->iterator;
	while (my $file = $fileIterator->()) {
		if($file->basename =~ /\.(?:jpe?g|png|gif)$/i) {
			push(@images, $file->basename);
		}
	}
	return \@images;
}

sub writeImageSizes {
	my $id = shift;

	my %sizes;

	for my $image(@{getImagesForEntry($id)}) {
		my $path = path(config->{public}, 'entries', $id, $image)->stringify;

		($sizes{$image}->{width}, $sizes{$image}->{height}) = imgsize($path);
	}

	path(config->{public}, 'entries', $id, 'images.json')->spew_utf8(encode_json(\%sizes));
}

sub fixJpegRotation {
	my $imagePath = shift;

	my $info = new Image::ExifTool;
	$info->ExtractInfo($imagePath);
	my $orientation = $info->GetValue('Orientation', 'ValueConv');

	if(!defined($orientation)) {
		debug "Image orientation could not be determined...";
		return;
	}

	debug("Image orientation is $orientation");

	my $img = Imager->new();

	$img->read(file=>$imagePath, type=>'jpeg') or die($img->errstr());
	if($orientation == 1) {
		#noop
	}
	elsif($orientation == 2) {
		$img = $img->flip(dir=>"h");
	}
	elsif($orientation == 3) {
		$img = $img->rotate(degrees=>180);
	}
	elsif($orientation == 4) {
		$img = $img->flip(dir=>"v");
	}
	elsif($orientation == 5) {
		$img = $img->rotate(degrees=>90);
		$img = $img->flip(dir=>"h");
	}
	elsif($orientation == 6) {
		$img = $img->rotate(degrees=>90);
	}
	elsif($orientation == 7) {
		$img = $img->rotate(degrees=>270);
		$img = $img->flip(dir=>"h");
	}
	elsif($orientation == 8) {
		$img = $img->rotate(degrees=>270);
	}

	$img->write(file=>$imagePath, type=>'jpeg') or die($img->errstr());
}

true;
