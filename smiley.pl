#!/usr/bin/env perl

use strict;

use Text::Emoticon;

my $emoticon = Text::Emoticon->new('', { strict => 1, xhtml => 0 });
 print $emoticon->filter('Hello ;)');
