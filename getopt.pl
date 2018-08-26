#!/usr/bin/env perl
use strict;
use Getopt::Mixed( 'nextOption' );

Getopt::Mixed::init('v verbose>v', 'h=s host>h');

while ( my ($option, $value, $pretty) = nextOption() ){
    print "option: $option\nvalue: $value\npretty: $pretty\n\n";
}
Getopt::Mixed::cleanup();

if(scalar(@ARGV)){
	print "We have leftover options!\n";
	foreach(@ARGV){
		print "$_\n";
	}
}
