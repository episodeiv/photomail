package schwafenthaeler::Entry;
use Dancer ':syntax';
use Data::Dumper;
use Encode;
use GD;
use JSON;
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
	print $text $entry->{body};
	close($text);

	for my $image (@{$entry->{images}}) {
		my $i = path($image->{tempfile});
		$i->move(path($path, $image->{filename})) or die("Unable to move image ".$image->{filename}.": ".$!);

	}
	writeImageSizes($id);
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
	for(sort(keys(%entries))) {
		push(@entryList, $entries{$_});
	}
	return \@entryList;
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
	$entry->{date} = shift(@body);
	$entry->{title} = shift(@body);
	$entry->{text} = join('', @body);
	$entry->{text_rendered} = markdown($entry->{text});

	my $fileIterator = $entryPath->iterator;
	while (my $file = $fileIterator->()) {
		if($file->basename =~ /\.(?:jpe?g|png|gif)$/i) {
			push(@{$entry->{images}}, $file->basename);
		}
	}

	my $imageSizes = decode_json(path($entryPath, 'images.json')->slurp_utf8);

	$entry->{imageSizes} = $imageSizes;

	return $entry;
}

sub writeImageSizes {
	my $id = shift;
	debug "Writing sizes for $id";

	my $entry = readEntryFromDisk($id);

	my %sizes;

	for my $image(@{$entry->{images}}) {
		debug "Calculating size for $image";

		my $path = path(config->{public}, 'entries', $id, $image)->stringify;

		my $gd = GD::Image->new($path);
		my ($width,$height) = $gd->getBounds();

		$sizes{$image}->{width} = $width;
		$sizes{$image}->{height} = $height;
	}

	path(config->{public}, 'entries', $id, 'images.json')->spew_utf8(encode_json(\%sizes));
}

true;
