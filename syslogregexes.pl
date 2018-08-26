#!/usr/bin/env perl

use strict;
use XML::Twig;

my $xml_infile = shift or die("You must supply an xml input file!\n Usage: xml-cleaner infile outfile");
die("$xml_infile is not a readable xml file!") unless (-f $xml_infile && !-b $xml_infile);

my $xml_outfile = shift or die("You must supply an output file name!\n Usage: xml-cleaner infile outfile");

my $twig = XML::Twig->new(
    pretty_print => 'indented',
    discard_spaces => 1,
    empty_tags=> 'normal',
    comments=> 'keep',
);

# Instead of tabs, use 4 spaces, ie - soft tabs.
$twig->set_indent("    ");

$twig->safe_parsefile($xml_infile);

#    my $twig = shift;
    my $root = $twig->root;
#    my $topics_tag = $root->first_child('topics');

#    # Get the items beneath this (don't know why they bothered...?)
#    my $items_tag = $topics_tag->first_child('items') or die("No items tag beneath the topics tag?");

    # Now we get an array where each item is a topic tag.
    my @options = $root->children('option');

#print scalar(@options);
foreach my $option(@options){
	print $option->text()."\n";
}

#open OUT,">$xml_outfile" or die("Failed to open $xml_outfile for write.");
#print OUT qq|<?xml version="1.0"?>\n|;
#$twig->print(\*OUT);
#close OUT;
exit;
