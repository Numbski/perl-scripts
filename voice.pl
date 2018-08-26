#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use Google::Voice;

my $g = Google::Voice->new->login('numbski@gmail.com', 'hnjqwhzrcbeahhwc');
print Dumper $g;
