#!/usr/bin/env perl
use strict;
use warnings;

use Image::Magick;
use Numbski;

my $numbski = new Numbski;
$numbski->path('/home/shadwickt');
$numbski->directory_as_array;

foreach(@{$numbski->directory_listing}){
    print "$_\n";
}

