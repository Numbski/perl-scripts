#!/usr/bin/perl;

use strict;

my $hex = 'FF';
my $dec = 255;

if(hex($hex) == $dec){
	print "true\n";
}
else{
	print "false\n";
}
