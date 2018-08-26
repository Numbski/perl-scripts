#!/usr/bin/perl
#Please refer to the MAME license agreement when using this software.
#Basically, it's my hope that you'll honor the spirit of the license,
#and not worry about the word for word interpretation.
#Missing Command Line Final Version.

system("title 'Missing' - Commandline Final");

use strict;
#use warnings;

use Cwd;
use Archive::Zip;
use Net::FTP;
use Net::FTP::AutoReconnect;
use Net::FTP::RetrHandle;
use Win32::Console;

#######################
#Globals Initialization

my @missing_sets     = ();
my $enter            = ();
my $dir              = ();
my @sets             = ();
my $mame             = ();
my @all              = ();
my $choice           = ();
my @current          = ();
my @parents          = ();
my @allparts         = ();
my @bad_parents      = ();
my @clones           = ();
my @bad_clones       = ();
my @parts            = ();
my $html             = ();
my @romdata          = ();
my $ftpleechfile     = ();
my $mircleechfile    = ();
my @romnames         = ();
my $hostname         = ();
my $port             = ();
my $directory        = ();
my $username         = ();
my $password         = ();
my $ftp              = ();
my $filename         = ();
my $remotefilesize   = ();
my $localfilesize    = ();
my $iniexist         = ();
my $mameexist        = ();
my $dirfile          = ();
my $hashnum          = ();
my $bytenum          = ();

my $fh = ();
my $zip = ();

system("cls");
print <<INTRO;
\n
 |\\  /|    __   __                    
 | \\/ | * |__  |__  * |--   __        July 25, 2005 
 |    | |  __|  __| | |  | |__|       This release written by Numbski & E=Mc2
                            __|       http://www.hksilver.net

      Command Line Final
             v3.5a

REWRITTEN AND UPGRADED TO HTML OUTPUT BY PHYDEAUX BRIGANDS
   FTP SUPPORT ADDED BY CHRIS J. MCCOURT
   
Missing Now has FTP Support!

This little utility will help you determine what ROM sets, if any, you're
missing after downloading MAME.  Get it???  :-)

---------------------------------------------------------------------
`MISSING' does NOT have any potential for destructive behavior but
it does require the latest version of MAME to work correctly.
---------------------------------------------------------------------

Press `Control C' to stop now or...
Press ENTER to continue.

INTRO
$enter = <STDIN>;

#############################################
#Begin main program code.
system("cls");

#Obtain the current working directory, create a mame global variable.
$dir = cwd;
$dir .= '/' unless $dir =~ m#/$#;
$mame = $dir . "mame";

#Open the Mame directory, get a listing of all files.
opendir( DIR, $dir );
my @dir = readdir(DIR);
closedir(DIR);
chomp(@dir);


#Check to make sure mame.exe exists
&check_for_exe;

#Check to make sure the user created mame.ini.
&check_for_ini;

#Audit the roms. Store the output in @sets
#print "Verifying ROMS...\n";
@sets = `mame -verifyroms`;
chomp(@sets);
print "\nVerification Complete!\n";

#Store all available sets in @all.
print "Generating list of all ROMS supported by MAME.";
@all = `mame -listfull`;
print "\nComplete!\n\n";

#Parse the data output.
print "Comparing supported ROMS to existing ROMS...\n\n";

#Take all existing sets, seperate parents from clones.
&sort_parents_from_clones;

#Check all parents, keep only the bad.
&screen_bad_parents;

#Check all clones, keep only the bad.
&screen_bad_clones;

#Remove existing sets from the complete list.
&remove_existing;

#Create a single listing of missing files.
&find_missing;

#Print our output to an HTML document.
#&print_html;

#Create a ftp leech file.
&create_ftpleech_file;

#Create a mirc leech file.
&create_mircleech_file;

system("cls");

print "Auditing of your romsets is complete!\n\n";
print "Please open " . $dir . "missing.html to view what is out of sorts in you MAME sets.\n";
print "You can take this opportunity to open " . $dir . "leech.txt and remove any lines which\n";
print "you do not wish to download.\n\n";
print "Please press Enter to Download these roms now,\n";
print "or press Control-C to exit.";

$enter = <>;

#If the user has not cancelled the process, leech the files.
&leech;

###############################
#Subroutines
sub check_for_exe
{
	@dir = map {lc} @dir;
	foreach $dirfile(@dir)
	{
		if($dirfile =~ /mame.exe/)
		{
			print "mame.exe found\n";
			system("pause");
			$mameexist = 1;
		}
	}
	
	if(!defined($mameexist))
	{
		print "mame.exe not found!\n";
		print "missing will now exit\n";
		system("pause");
		exit;
	}
}

sub check_for_ini
{

	#Check to see if user created mame.ini.
	system("cls");

   #Loop through all the files.  If mame.ini does not exists, offer to create it
	foreach $dirfile (@dir)
	{
		if ($dirfile =~ /mame.ini/)
		{
			print "mame.ini already exists\n\n";
			$iniexist = 1;
		}
	}
	if(!defined($iniexist))
	{
		system("cls");
		print "It appears that you have not yet created mame.ini.\n";
		print "Would you like to create it now?\n";
		print "1. Yes\n";
		print "9. No\n";
		$choice = <>;
		if ($choice =~ /1/ )
		{
			`mame -createconfig`;
			system("cls");
			print "Created " . $dir . "mame.ini!\n\n";
		}
		if ($choice =~ /9/ )
		{
			system("cls");
			print "You opted not to create mame.ini.\n\n";
		}
	}
}

#Sort out Parent Sets from Clone Sets
sub sort_parents_from_clones
{
	print "Seperating Parents and Clones...\n";
	my $parent_count = 0;
	my $clone_count  = 0;
	foreach (@sets)
	{
		@current = split( / /, $_ );
		my $count = 0;
		foreach my $part (@current)
		{
			$count++;
		}
		if ( $count <= 4 )
		{
			$parents[$parent_count] = $_;
			$parent_count++;
		}
		else
		{
			$clones[$clone_count] = $_;
			$clone_count++;
		}
	}
	@current = ();
	print "There are $parent_count parent sets.\n";
	print "There are $clone_count clone sets.\n\n";
}

#Screen out the good sets, keep only the bad.  Do parents first.
sub screen_bad_parents
{
	print "Screening out bad Parent sets...\n";
	my $parent_count = 0;
	foreach (@parents)
	{
		@current = split( / /, $_ );
		if ( $current[3] eq "bad" )
		{
			foreach my $line (@all)
			{
				@allparts = split( / /, $line );
				if ( $allparts[0] eq $current[1] )
				{
					$bad_parents[$parent_count] = $line;
					$parent_count++;
				}
			}
		}
	}
	@current = ();
}

#Look at all the clone sets, keep only the bad ones.
sub screen_bad_clones
{
	print "Screening out bad Clone sets...\n";
	my $clone_count = 0;
	foreach (@clones)
	{
		@current = split( / /, $_ );
		if ( $current[4] eq "bad" )
		{
			foreach my $line (@all)
			{
				@allparts = split( / /, $line );
				if ( $allparts[0] eq $current[1] )
				{
					$bad_clones[$clone_count] = $line;
					$clone_count++;
				}
			}
		}
	}
	@current = ();
}
##################################################
#Take the complete list and zero out existing sets
sub remove_existing
{
	print "Searching for Missing sets...\n";
	$all[0] = "";

	#Zero out known existing sets from list.
	foreach (@sets)
	{
		@parts = split( / /, $_ );
		foreach my $line (@all)
		{
			@current = split( / /, $line );
			if ( $parts[1] eq $current[0] )
			{
				$line = " ";
			}
		}
	}
	@current = ();
}
########################################
#Create a single listing of missing sets.
sub find_missing
{
	my $missing_count = 0;
	foreach (@all)
	{
		chomp($_);
		if ( $_ gt " " )
		{
			$missing_sets[$missing_count] = $_;
			$missing_count++;
		}
	}
}
##########################
#Output HTML
sub print_html
{
	print "Outputting HTML...\n";
	$html = $dir . "missing.html";
	open( HTML, ">$html" ) || die "Can't Open $html: $!\n";
	print HTML "<html>";
	print HTML "<head><title>Your Missing ROMS</title></head>";
	print HTML "<body bgcolor=black text=white link=gray vlink=white>";
	print HTML "<base target=\"_new\">";
	print HTML "Missing v3.5a  July 25, 2005<br>";
	print HTML "<p>";
	print HTML "REWRITTEN AND UPGRADED TO HTML OUTPUT BY PHYDEAUX BRIGANDS<br>";
	print HTML "FTP SUPPORT ADDED BY CHRIS MCCOURT<br>";
	print HTML "This Release By <a href=\"mailto:=numbski\@hksilver.net\">Numbski</a> & <a href=\"mailto:=mccourt_chris\@hotmail.com\">E=Mc²</a><p>";
	print HTML "Check out Numbski's website for information on ''MISSING'' & possible FTP's that support MISSING<br>";
	print HTML "<a href=\"http://www.hksilver.net\">http://www.hksilver.net</a><br>";
	print HTML "<br>";
	print HTML "Missing v3.5a is now linked to the File Transfer Protocal using Net::Ftp";
	print HTML "<p>";
	print HTML "This little utility will help you determine what ROMsets, if any, you're<br>";
	print HTML "missing after downloading MAME.  Get it???  :-)<br>";
	print HTML "<br>";
	print HTML "---------------------------------------------------------------------<br>";
	print HTML "``MISSING'' does NOT have any potential for destructive behavior but<br>";
	print HTML "it does require the latest version of MAME to work correctly.<br>";
	print HTML "---------------------------------------------------------------------<br>";
	print HTML "<br>";
	print HTML "These are the games missing from your collection:<br>\n";
	print HTML "<!-- Start Missing -->\n\n";

	foreach (@missing_sets)
	{
		@romdata = split( / /, $_ );
		print HTML "<a href=\"ftp://$username:$password" . "@" . "$hostname/$directory/$romdata[0].zip\">$_</a><br>\n";
	}
	print HTML "<!-- End Missing -->\n\n";
	print HTML "<p>These are sets that exist on your drive, but fail to pass MAME's crc check:<p>";
	print HTML "<!-- Start Failures -->\n\n";
	
	foreach (@bad_parents)
	{
		@romdata = split( / /, $_ );
		print HTML "<a href=\"ftp://$username:$password" . "@" . "$hostname/$directory/$romdata[0].zip\">$_</a><br>\n";
	}
	print HTML "<!-- End Failures -->\n\n";
	print HTML "<p>";
	print HTML "These are the incorrect or incomplete games in your collection:<br>";
	print HTML "<br>";
	print HTML "A CLONE of a game may be listed here as being BAD if the ORIGINAL version is missing.<br>";
	print HTML "CLONES use common files found in the ORIGINAL version to save space.<br>";
	print HTML "Download the missing ORIGINAL game first, and re-scan before downloading a CLONE listed here.<br>";
	print HTML "<br>\n\n";
	print HTML "<!-- Start Clones -->\n\n";

	foreach (@bad_clones)
	{
		@romdata = split( / /, $_ );
		print HTML "<a href=\"ftp://$username:$password" . "@" . "$hostname/$directory/$romdata[0].zip\">$_</a><br>\n";
	}
	print HTML "<!-- End Clones -->\n";
	close(HTML);
}

sub create_ftpleech_file
{
	$ftpleechfile = $dir . "ftp_leech.txt";
	open(FTP_LEECH, ">$ftpleechfile") || die "Can't Open $ftpleechfile: $!\n";
	foreach (@missing_sets)
	{
		@romdata = split( / /, $_ );
		print FTP_LEECH "$romdata[0].zip\n";
	}
	foreach (@bad_parents)
	{
		@romdata = split( / /, $_ );
		print FTP_LEECH "$romdata[0].zip\n";
	}
	foreach (@bad_clones)
	{
		@romdata = split( / /, $_ );
		print FTP_LEECH "$romdata[0].zip\n";
	}
	close(FTP_LEECH);
}

sub create_mircleech_file
{
	$mircleechfile = $dir . "leech.txt";
	open( MIRC_LEECH, ">$mircleechfile" ) || die "Can't Open $mircleechfile: $!\n";
	foreach (@missing_sets)
	{
		@romdata = split( / /, $_ );
		print MIRC_LEECH "get $romdata[0].zip\n";
	}
	foreach (@bad_parents)
	{
		@romdata = split( / /, $_ );
		print MIRC_LEECH "get $romdata[0].zip\n";
	}
	foreach (@bad_clones)
	{
		@romdata = split( / /, $_ );
		print MIRC_LEECH "get $romdata[0].zip\n";
	}
	close(MIRC_LEECH);
}

sub leech
{
	system("cls");
	open FTP_LEECH, $ftpleechfile || die "Can't open $ftpleechfile for read: $!\n";

	#Load each line into an array, get rid of any newlines at the end.
	while (<FTP_LEECH>)
	{
		push(@romnames, $_ );
		chomp(@romnames);
	}
	close FTP_LEECH;

	#Make sure the newroms directory exists.
	mkdir( $dir . "newroms", 0777 );
#####################################################
#FTP

	#This routine is used for the ftp login
	print "Hostname: ";
	$hostname = <>;
	chomp($hostname);
	print "Port: ";
	$port = <>;
	chomp($port);
	print "Directory: ";
	$directory = <>;
	chomp($directory);
	print "Username: ";
	$username = <>;
	chomp($username);
	print "Password: ";
	$password = <>;
	chomp($password);
        
        #Print our output to an HTML document.
        &print_html;

	# Open the connection to the host
	$ftp = Net::FTP->new( $hostname, Port => $port, Timeout => 200 );
	die "FTP Failed $@\n" unless defined $ftp;

	# Login
	$ftp->login( $username, $password )
	  || die "FTP Failed: Incorrect Username and/or Password\n";

	# Change directory
	$ftp->cwd($directory) || die "FTP Failed: No such directory\n";

	# Set FTP to bnary mode
	#$ftp->binary() || die "FTP Failed: Binary mode not supported\n";
	
	foreach $filename(@romnames)
	{
		print "Searching for $filename...\n";
		$remotefilesize = $ftp->size($filename);
                #need to see if a local file exist be for checking size
		$localfilesize = -s $dir . "newroms/$filename";
                
                ########## ADDED CODE ############
                
                
                system("pause");#############################
                
		if(!defined($remotefilesize))
		{
			print "FTP Failed: file $filename not found\n\n";
		}
		elsif(defined($localfilesize) && $remotefilesize > $localfilesize)
		{
			print "Resuming $filename\n";
			&resume_template;
			$ftp->get($filename, $dir . "newroms/$filename", "$filename");
			print "Download Complete!\n\n";
			
		}
		else
		{
                   $fh = Net::FTP::RetrHandle->new($ftp, $filename);
                        $zip = Archive::Zip->new($fh);
                        foreach my $fn ($zip->memberNames())
                        {
                            print "$filename $fn\n";
                        }
                        system('pause');
                        
			print "Downloading $filename\n";
			&progressbar;
			$ftp->get($filename, $dir . "newroms/$filename" );
			print "Download Complete!/n";
		}
	}
	$ftp->quit;
	print "Update Complete!";
##########################################################
#FTP SUB
	sub progressbar
	{
		$hashnum = 25;
		$bytenum = $remotefilesize / $hashnum;
                $ftp->hash( 1, $bytenum );
                print progress_template(), "[ ";
	}

	sub progress_template
	{
		my ($width) = @_;
		$width ||= 25;
		sprintf "%${width}s ] $remotefilesize Total bytes\r";
	}
	
	sub resume_template
	{
		my $placeholder;
		my $filler;
		$placeholder = $remotefilesize - $localfilesize;
		&progressbar;
		while($placeholder >= 1)
		{
			print '#';
			$placeholder = $placeholder - $bytenum;
			
		}
	}
}
