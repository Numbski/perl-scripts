#!/usr/bin/env perl
use strict;
use Math::Trig ':pi';

my $bore = shift @ARGV or die("I need your bore size in mm!");
$bore =~s/m|\s//g;
my $stroker = 5.4;

my $cc = ( pi * ((($bore/10)/2)**2) ) * $stroker;

print "Bore is $bore mm, stroker is 54 mm\n";
print int $cc;
print "cc\n";
