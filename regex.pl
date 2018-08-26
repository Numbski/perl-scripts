#!/usr/bin/env perl

use strict;

my $string = 'Tony Shadwick (USA) <tony.shadwick+bogus.com@usa.gknaerospace.com>';

print "$string\n";

$string = lc($string);

if($string =~ /<(.*?)\+(.*?)@(.*?)>/){
	print "\$1: $1\n\$2: $2\n\$3: $3\n\$4: $4\n";
	exit;
}
else{
	print "Nope.\n";
	exit;
}

print "$string\n";

$string =~ s/^.*?</</;

print "$string\n";

$string =~ s/(<|>|\s)//g;

print "$string\n";
