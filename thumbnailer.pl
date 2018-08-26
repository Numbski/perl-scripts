#!/usr/bin/env perl
use strict;
use warnings;

use Image::Magick;
use File::Copy;
use Numbski;

my $path = shift(@ARGV) or die("Please provide a directory path to your images for thumbnailing.");
die("The path you provided is not a valid directory: $!") unless -d $path;

my $numbski = new Numbski;
$numbski->path($path);
$numbski->directory_as_array;

IMAGE:
foreach my $filename(@{$numbski->directory_listing}){
    print "Entering loop with filename $filename.\n";
    if($filename =~ /(jpg|png|gif|jp2)$/){

        # Make sure the filename is all lowercase.
        move($numbski->path.'/'.$filename,$numbski->path.'/'.lc($filename)) or
            die("Failed to rename file: $!");
        $filename = lc($filename);
        $filename =~ /(.*?)\.(jpg|png|gif|jp2)$/;
        die("Failed to glean filename base for new images from $filename") unless $1;
        die("Failed to glean file type from $filename") unless $2;
        my $basename = $1;
        my $image_type = $2;

        print "Opening ".$numbski->path."/$filename.\n";
        # Create a new ImageMagick instance.
        my $image = new Image::Magick;
#        warn("Something went wrong while reading ".$numbski->path."/$filename: $!") if
#            $image->Read($numbski->path."/$filename.");
        my $x = $image->Read($numbski->path."/$filename");
        die($x) if $x;

        move($numbski->path.'/'.$filename,$numbski->path.'/'.$basename."_LRG.$image_type");

        print "Determining geometry.\n";
        my $width = $image->Get('width') or die("Failed to determine image width!");
        my $height = $image->Get('height') or die("Failed to determine image height!");

        if ($width >= 400){
            print "Scaling ".$numbski->path."/$filename down to 400 pixels wide.\n";

            # Resize the image.
            $image->Scale(
                width =>  400,
                height => ((400*$height)/$width),
            );

            print "Saving ".$numbski->path."/$basename\_MED.$image_type\n\n";
            my $x = $image->Write($numbski->path."/$basename\_MED.$image_type");
            die($x) if $x;
        }
        else{
            warn "This image is already smaller than 400 pixels.  Skipping."; 
        }
        if ($width >= 200){
            print "Scaling ".$numbski->path."/$filename down to 200 pixels wide.\n";

        
            # Resize the image.
            $image->Scale(
                width =>  200,
                height => ((200*$height)/$width),
            );

            print "Saving ".$numbski->path."/$basename.$image_type\n\n";
            my $x = $image->Write($numbski->path."/$basename.$image_type");
            die($x) if $x;
        }
        else{
            warn "This image is already smaller than 200 pixels.  Skipping."; 
        }

    }
}

