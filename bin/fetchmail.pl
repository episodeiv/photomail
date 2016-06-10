#!/usr/bin/perl

use strict;
use v5.10;

use FindBin;
use Cwd qw/realpath/;
use Dancer ':script';
use Data::Dumper;
use Email::MIME;
use Net::IMAP::Simple;

my $appdir = realpath("$FindBin::Bin/..");

Dancer::Config::setting('appdir', $appdir);
Dancer::Config::load();

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

	$mail->walk_parts(sub {
		my ($part) = @_;
		return if $part->subparts; # multipart

		print "CT: ".$part->content_type."\n";
		if($part->content_type =~ m[text/plain]i) {
			$entry->{body} = $part->body;
		}
		elsif($part->content_type =~ m[^image]i) {
			$entry->{image} = $part->filename;
		}

	});

	print Dumper($entry);
}
