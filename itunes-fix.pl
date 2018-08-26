#!/usr/bin/env perl

use Mac::iTunes::Library;
use URI::Encode;
use strict;
use warnings;

print "Starting...\n\n";

my $uri = URI::Encode->new();
#my $path = 'file://localhost/Users/tshadwick/My%20Song.mp3';
#my $decoded = $uri->decode($path);

#print "$decoded\n";

#$decoded =~ s/^file:\/\/localhost//;
#print "$decoded\n";
#print "It exists\n" if (-f $decoded);

use Mac::iTunes::Library::XML;
my $library = Mac::iTunes::Library::XML->parse( 'library.xml' );
print "This library has " . $library->num() . " items.\n";

# Assuming a previously created library
my %items = $library->items();

my $songs_checked = 0;
my $fix_count = 0;
my $uri_notfile_count = 0;
my $bogus_count = 0;
my $wontfix_count = 0;
my $ok_count = 0;

foreach my $artist (keys %items) {
	my $artistSongs = $items{$artist};

	foreach my $songName (keys %$artistSongs) {
		my $artistSongItems = $artistSongs->{$songName};

		ITEM:
		foreach my $item (@$artistSongItems) {
			# Do something here to every item in the library
			$songs_checked++;
			my $location = $item->location();
			$location = $uri->decode($location);
			if($location !~ /^file:\/\//){
				print "Not a file:// uri?\n";
				print "$location\n";
				print "********************\n\n";
				$uri_notfile_count++;
				next ITEM;
			}
			next ITEM unless ($location =~ /^file:\/\//);
			$location =~ s/^file:\/\/localhost//;
#			print $item->artist() ." - ". $item->name() . ":\n\t";
			my $new_location;
			if (-f $location){
				#print "It exists!\n\n";
				$ok_count++;
				next ITEM;
			}
			elsif($item->artist eq 'AC/DC'){
				## Test and correct AC/DC stuff here.
				if(-f '/Volumes/media/MP3/current/AC_DC/'.$item->album().'/'.$item->artist().' - '.$item->name().'.mp3'){
					$new_location = '/Volumes/media/MP3/current/AC_DC/'.$item->album().'/'.$item->artist().' - '.$item->name().'.mp3';
					$fix_count++;
				}
			}
			elsif(-d $location){
				if(-f '/Volumes/media/MP3/current/'.$item->artist().'/'.$item->album().'/'.$item->artist().' - '.$item->name().'.mp3'){
					$new_location = '/Volumes/media/MP3/current/'.$item->artist().'/'.$item->album().'/'.$item->artist().' - '.$item->name().'.mp3';
					$fix_count++;
				}
				elsif(-f '/Volumes/media/MP3/Classical/'.$item->artist().'/'.$item->album().'/'.$item->artist().' - '.$item->name().'.mp3'){
					$new_location = '/Volumes/media/MP3/Classical/'.$item->artist().'/'.$item->album().'/'.$item->artist().' - '.$item->name().'.mp3';
					$fix_count++;
				}
				elsif(-f '/Volumes/media/MP3/current/'.$item->artist().'/'.$item->album().'/'.$item->artist().' - '.$item->name().'.mp3'){
					$new_location = '/Volumes/media/MP3/Novelty Tracks/'.$item->artist().'/'.$item->album().'/'.$item->artist().' - '.$item->name().'.mp3';
					$fix_count++;
				}
				else{
					print $item->artist() ." - ". $item->name() . ":\n";
					print "\tFound directory instead of file: $location\n";
					print "\tCorrection failed. :(\n";
					print "\tIf this were a real run, I would insert a bogus mp3 file.\n\n";
					$new_location = '/my/bogus/song.mp3';
					$bogus_count++;
					print "********************\n\n";
				}
			}
			else{
				print $item->artist() ." - ". $item->name() . ":\n";
				print "\tNeither file nor directory: $location\n";
				if($item->location() =~ /\.mp3$/){
					print "\tEnds in .mp3: Probably a bad character.  Won't fix.\n\n";
						print "********************\n\n";
				}
				else{
					print "\tI have no idea what this one is.  Won't fix.\n\n";
						print "********************\n\n";
				}
				$wontfix_count++;
				next ITEM;
			}
			
			### INSERT ACTUAL LIBRARY CORRECTION CODE HERE ###
			# Add file://localhost back to the beginning
			$new_location = 'file://localhost'.$new_location;
			# $uri->encode that $new_location.
			my $encoded_new_location = $uri->encode($new_location);
			$item->location($encoded_new_location)
			### END LIBRARY CORRECTION CODE ###
			# then...

			next ITEM;
		} # End of foreach item (actual song).
	} #End of foreach Song Name (ID3 song name as hash key)
} # End of foreach artist.

# Write out the fixed library at the tail end.

# Quick Summary:
print "This library has " . $library->num() . " songs.\n";
print "Songs checked:  $songs_checked\n";
print "Songs OK:  $ok_count\n";
print "Songs without a proper file:// URI:  $uri_notfile_count\n";
print "Songs fixed:  $fix_count\n";
print "Songs needing manual correction:  $bogus_count\n";
print "Songs that were indescernable and not changed:  $wontfix_count\n";