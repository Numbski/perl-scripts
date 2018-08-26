#!/usr/bin/env perl

use strict;
#use warnings;

use XML::Twig;

my @thoughts;
my @topics;

my $file = shift or die("You need to pass in an xml file!");

die("No such file $file: $!") unless -f $file;

# Parse as a twig.
my $twig= XML::Twig->new(
            'twig_handlers' => {
                'topics' => \&read_topics,    
                'thoughts' => \&read_thoughts,
            },
            'comments' => 'keep',
            'pretty_print' => 'indented',
        );

$twig->safe_parsefile($file);
#print "File is loaded into \$twig.  There are ".scalar(@topics). " topics and ".scalar(@thoughts). " thoughts.\n";
#$twig->first_child('topics')->flush;

print_topics();

sub read_topics(){
    my $twig = shift;
    my $root = $twig->root;

    my $topics_tag = $root->first_child('topics');

    # Get the items beneath this (don't know why they bothered...?)
    my $items_tag = $topics_tag->first_child('items') or die("No items tag beneath the topics tag?");
    
    # Now we get an array where each item is a topic tag.
    @topics = $items_tag->children('topic');
    return(1);
}

sub read_thoughts(){
    my $twig = shift;
    my $root = $twig->root;

    my $thoughts_tag = $root->first_child('thoughts');

    # Get the items beneath this (don't know why they bothered...?)
    my $items_tag = $thoughts_tag->first_child('items') or die("No items tag beneath the thoughts tag?");
    
    # Now we get an array where each item is a thought tag.
    @thoughts = $items_tag->children('thought');
    return(1);
}

sub print_thoughts(){
    foreach my $thought(@thoughts){
        print $thought->first_child('description')->trimmed_text;
        print "\n";
    }
}

sub print_topics(){
    foreach my $topic(@topics){
        print $topic->first_child('name')->trimmed_text;
        if($topic->first_child('description')->trimmed_text){
            print " (".$topic->first_child('description')->trimmed_text.")";
        }
        print "\n";
    }
}