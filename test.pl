#!/usr/bin/env perl

use strict;
use Numbski;

my $file = Numbski->new(
	{
		'path' => "/home/shadwickt/pete.csv",
	}
);

$file->read_file;
print $file->contents."\n";
