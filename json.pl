#!/usr/bin/env perl
use JSON;

my $json = new JSON;

my $hash = {
	'name1' => 'value1',
	'array1' => [
		2,4,6
	],
};

my $string = "Meh, it's a living.";

my $string = $json->encode($hash);
print $string;
