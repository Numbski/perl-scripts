#!/usr/bin/perl

use strict;
use warnings;
use XML::Twig;

my $xml_outfile = 'new_library.xml';

my $twig = XML::Twig->new(
    pretty_print => 'indented',
    discard_spaces => 1,
    empty_tags=> 'normal',
    comments=> 'keep',
    set_root => 'plist',
);

$twig->safe_parsefile('library.xml');
my $root = $twig->root;

my $first_dict = $root->first_child( 'dict' );


open OUT,">$xml_outfile" or die("Failed to open $xml_outfile for write.");
print OUT qq|<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">|;
$twig->print(\*OUT);
close OUT;
exit;