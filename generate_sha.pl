#!/usr/bin/perl

use strict;
use Digest::SHA;

# This script should return two identical sha values.  The first is by 
# generating an sha file a file, then pushing that file into a scalar 
# and generating an sha from that.

my $dll = shift(@ARGV);

my $file_sha = Digest::SHA->new->addfile($dll, "b")->hexdigest;


open FILE, $dll or die $!;
binmode FILE;

my($n, $data_buffer, $dll_data);

while( ($n = read FILE, $data_buffer, 4) != 0){
	$dll_data .= $data_buffer;
}
close FILE;


my $scalar_sha = Digest::SHA->new->add($dll_data)->hexdigest;

print "File:\t$file_sha\nScalar:\t$scalar_sha\n";

