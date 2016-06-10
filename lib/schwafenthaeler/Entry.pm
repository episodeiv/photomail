package schwafenthaeler::Entry;
use Dancer ':syntax';
use Data::Dumper;
use Encode;
use List::Util qw/max/;
use Path::Tiny;

my $fetchedEntries = false;
my %entries;

refreshEntries();

debug Dumper(%entries);

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

	## TODO: Create thumbs
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
	return %entries;
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
	$entry->{date} = shift(@body);
	$entry->{title} = shift(@body);
	## TODO: Handle markdown
	$entry->{text} = join('\n', @body);

	my $fileIterator = $entryPath->iterator;
	while (my $file = $fileIterator->()) {
		if($file->basename =~ /\.(?:jpe?g|png|gif)$/i) {
			push(@{$entry->{images}}, $file->basename);
		}
	}

	return $entry;
}

true;
