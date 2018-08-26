#!/usr/bin/env perl
use strict;
use lib "./";
require "perlplist.pl";
use URI::Encode;

sub getPlistObject {
  my ( $object, @keysIndexes ) = ( @_ );
  if ( @keysIndexes ) {
    foreach my $keyIndex ( @keysIndexes ) {
      if ( $object and $$object ) {
        if ( $object->isKindOfClass_( NSArray->class ) ) {
          $object = $object->objectAtIndex_( $keyIndex );
        } elsif ( $object->isKindOfClass_( NSDictionary->class ) ) {
          $object = $object->objectForKey_( $keyIndex );
        } else {
          print STDERR "Unknown type (not an array or a dictionary):\n";
          return;
        }
      } else {
        print STDERR "Got nil or other error for $keyIndex.\n";
        return;
      }
    }
  }
  return $object;
}

my $songs_checked = 0;
my $fix_count = 0;
my $chibi_local = 0;
my $uri_notfile_count = 0;
my $bogus_count = 0;
my $wontfix_count = 0;
my $ok_count = 0;


print "Starting...\n\n";

my $uri = URI::Encode->new();

my $file = 'library.xml';
my $plist = NSDictionary->dictionaryWithContentsOfFile_( $file );
if ( $plist and $$plist) {
	my $tracks = getPlistObject( $plist, "Tracks" );
	if ( $tracks and $$tracks ) {
		# print perlValue( $tracks ) . "\n";
		my $track_enumerator = $tracks->keyEnumerator();
		my $current_track_id;

		ITEM:
		while ( $current_track_id = $track_enumerator->nextObject() and $$current_track_id ) {
			$songs_checked++;
  			#printf "Current Track ID: %s\n", perlValue( $current_track_id);
  			my $current_track_values = getPlistObject($plist, "Tracks", $current_track_id);
  			#print perlValue($current_track_values)."\n";

			my $location_parent = getPlistObject($plist, 'Tracks', $current_track_id, 'Location');
			my $location = perlValue($location_parent);
			my $artist = getPlistObject($plist, 'Tracks', $current_track_id, 'Artist');
			$artist = perlValue($artist) if $artist;
			my $album = getPlistObject($plist, 'Tracks', $current_track_id, 'Album');
			$album = perlValue($album) if $album;
			my $name = getPlistObject($plist, 'Tracks', $current_track_id, 'Name');
			$name = perlValue($name) if $name;

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
			my $new_location;
			if (-f $location){
				#print "It exists!\n\n";
				$ok_count++;
				next ITEM;
			}
			elsif($location =~ /^\/Users\/baroque/){
				print "$artist - $name:\n";
				print "File is local to chibi.  Skipping.\n\n";
				$chibi_local++;
				print "********************\n\n";
				next ITEM;
			}
			elsif($artist eq 'AC/DC'){
				## Test and correct AC/DC stuff here.
				if(-f "/Volumes/media/MP3/current/AC_DC/$album/$artist - $name.mp3"){
					$new_location = "/Volumes/media/MP3/current/AC_DC/$album/$artist - $name.mp3";
					$fix_count++;
				}
			}
			elsif(-d $location){
				my @folders = ('current','Classical','Novelty Tracks');
				FOLDERTEST:
				foreach my $folder(@folders){
					my $test_location = "/Volumes/media/MP3/$folder/$artist/$album/$artist - $name.mp3";
					if(-f $test_location){
						$new_location = $test_location;
						$fix_count++;
						last FOLDERTEST;
					}
					$test_location =~ s/:/_/g;
					if(-f $test_location){
						$new_location = $test_location;
						$fix_count++;
						last FOLDERTEST;
					}
				}
				unless($new_location){
					print "$artist - $name:\n";
					print "\tFound directory instead of file: $location\n";
					print "\tCorrection failed. :(\n";
					print "\tIf this were a real run, I would insert a bogus mp3 file.\n\n";
					$new_location = '/my/bogus/song.mp3';
					$bogus_count++;
					print "********************\n\n";
				}
			}
			else{
				print "$artist - $name:\n";
				print "\tNeither file nor directory: $location\n";
				if($location =~ /\.mp3$/){
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
			
			# Set the changed location in the plist.
			# The following is from the busted XML code. :(
			#$item->location($encoded_new_location)
			$current_track_values->setObject_forKey_($encoded_new_location, "Location");
			#print "Changed dictionary: " . perlValue( $current_track_values ) . "\n";
 

			### END LIBRARY CORRECTION CODE ###
			# then...

			next ITEM;
		} # End of track id iterator. "ITEM" Label.
	} # End of "if $tracks and $$tracks" conditional
	else {
    	die "Could not find the value.\n";
  	}
} # End of "if $plist and $$plist" conditional. 
else {
  die "Error loading file.\n";
}

# Write out the fixed library at the tail end.
$plist->writeToFile_atomically_( "new_library.plist", "0" );

# Quick Summary:
#print "This library has " . $library->num() . " songs.\n";
print "Songs checked:  $songs_checked\n";
print "Songs OK:  $ok_count\n";
print "Songs without a proper file:// URI:  $uri_notfile_count\n";
print "Songs local to chibi:  $chibi_local\n";
print "Songs fixed:  $fix_count\n";
print "Songs needing manual correction:  $bogus_count\n";
print "Songs that were indescernable and not changed:  $wontfix_count\n";