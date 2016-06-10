#!/usr/bin/env perl

use strict;
use v5.10;

use FindBin;
use Cwd qw/realpath/;
use Dancer ':script';
use schwafenthaeler::Entry;

my $appdir = realpath("$FindBin::Bin/..");

Dancer::Config::setting('appdir', $appdir);
Dancer::Config::load();

use Data::Dumper;
use Date::Parse;
use Email::MIME;
use File::Temp qw/tempfile/;
use Net::IMAP::Simple;


# Create the object
my $imap = Net::IMAP::Simple->new(
	config->{email}->{server},
	#debug => 1,
) || die "Unable to connect to IMAP: $Net::IMAP::Simple::errstr\n";

# Log on
if(!$imap->login(config->{email}->{username}, config->{email}->{password})){
	print STDERR "Login failed: " . $imap->errstr . "\n";
	exit(64);
}

my $unseenNumber = $imap->unseen();

if($unseenNumber == 0) {
	print "No unseen messages. Quitting.\n";
	exit;
}

print "Processing $unseenNumber unseen message(s)\n";

my @list = $imap->uidsearch('UNSEEN');
for(@list) {
	processMessage($_);
}

$imap->quit;

sub processMessage {
	my $id = shift;
	print " -> Processing message $id\n";

	my $entry;

	my $mail = Email::MIME->new(join('', @{$imap->get($id)}));

	$entry->{subject} = $mail->header_str('subject');
	$entry->{date} = str2time($mail->header_str('Date'));

	$mail->walk_parts(sub {
		my ($part) = @_;
		return if $part->subparts; # multipart

		if($part->content_type =~ m[text/plain]i) {
			$entry->{body} = $part->body_str;
		}
		elsif($part->content_type =~ m[^image]i) {
			push(@{$entry->{images}}, writeImage($part));
		}
	});

	schwafenthaeler::Entry::addEntry($entry);
}

sub writeImage {
	my $part = shift;

	my ($fh, $tempfile) = tempfile();

	binmode($fh);
	print $fh $part->body;
	close($fh);

	return {
		filename		=> $part->filename,
		tempfile		=> $tempfile,
		content_type	=> $part->content_type,
	}
}
