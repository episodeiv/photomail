#!/usr/bin/perl

use strict;
use v5.10;

use FindBin;
use Cwd qw/realpath/;
use Dancer ':script';
use Data::Dumper;
use Email::Simple;
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
	my $mail = Email::Simple->new(join '', @{ $imap->top($_)});
	printf("[%03d] %s\n", $_, $mail->header('Subject'));
}

$imap->quit;