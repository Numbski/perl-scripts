#!/usr/bin/env perl
use strict;
use Numbski;
my $numbski = Numbski->new(
	'path' => shift(@ARGV),
);

$numbski->read_file();
$numbski->dos2unix();
print $numbski->contents();
