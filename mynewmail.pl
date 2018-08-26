#!/usr/bin/perl

use Net::IMAP::Simple;

# IMAP Server address
$server = "localhost";


my $imap = Net::IMAP::Simple->new($server, Timeout => 30) or die "Can't connect to $server: $!";

for(1 .. $num_msgs) { 
	push @new_msgs, $_ unless $imap->seen($_);
}

    	print "You have ".scalar @new_msgs." in your mailbox!\n";


