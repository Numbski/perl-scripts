#!/usr/bin/env perl
###################################################################
#
# Script:       process_ldif.p
#
# Usage:        process_ldif.p
#
# Purpose:      This script reads exports of LDAP entries from
#               Active Directory servers and loads them into
#               OpenLDAP for use by the UK
#
# Author:       Tracy Orf
#
# Date:         06/2005
#
# Modifications:
#
###################################################################

use Net::LDAP;
use Net::LDAP::Util qw(
                        ldap_error_text
                        ldap_error_name
                        ldap_error_desc
                        canonical_dn
                        );

use Net::LDAP::LDIF;

# Unused - thankfully.
# use Net::SCP qw(scp iscp);

use Digest::MD5::File qw(file_md5_hex);

# Globals
$uploadDir = "/home/shadwickt/filetransfer";
$idfile = "/root/.ssh/id_rsa";

@sites = ('stl', 'ala', 'elc', 'mon', 'pre', 'gg', 'nash', 'bandy', 'aus');
@pull_input = ('no', 'no', 'yes', 'no', 'no', 'no', 'no', 'no', 'no');
@hosts = ('', '', '70.164.112.227', '', '', '', '', '', '');

@siteAdmins = ('john.pozzoli@usa.gknaerospace.com,tracy.orf@usa.gknaerospace.com','john.pozzoli@usa.gknaerospace.com,tracy.orf@usa.gknaerospace.com','john.pozzoli@usa.gknaerospace.com,tracy.orf@usa.gknaerospace.com','john.pozzoli@usa.gknaerospace.com,tracy.orf@usa.gknaerospace.com','john.pozzoli@usa.gknaerospace.com,tracy.orf@usa.gknaerospace.com','john.pozzoli@usa.gknaerospace.com,tracy.orf@usa.gknaerospace.com','john.pozzoli@usa.gknaerospace.com,tracy.orf@usa.gknaerospace.com','john.pozzoli@usa.gknaerospace.com,tracy.orf@usa.gknaerospace.com','john.pozzoli@usa.gknaerospace.com');
@siteCompany = ('GKN Aerospace North America, Inc','GKN Aerospace North America, Inc','GKN Aerospace North America, Inc','GKN Aerospace North America, Inc','GKN Aerospace North America, Inc','GKN Aerospace Transparency Systems, Inc','GKN Aerospace North America, Inc','GKN Aerospace North America, Inc','GKN Aerospace Australia');
@siteDivision = ('Aerostructures','Aerostructures','Aerostructures','Aerostructures','Aerostructures','Aerostructures','Aerostructures','Aerostructures','Aerostructures');
@siteName = ('St. Louis','Tallassee','El Cajon','Amityville','Wellington','Garden Grove','Nashville','Burbank','Australia');
@siteCountry = ('USA','USA','USA','USA','USA','USA','USA','USA','Australia');

@output_OUs = ( '', '', '', '', '', '', '', '', '');


#--------------------------------------------------------------------

# validate input files
$i = 0;
foreach $site (@sites)  {
	print "Checking MD5 for site $site\n";
	
	# Our file is /home/filetransfer/stl_to_ldap.txt
        $file = $uploadDir . "/" . $site . "_to_ldap.txt";

	# /home/filetransfer/stl_to_ldap.txt
        $remotefile = "/home/filetransfer/" . $site . "_to_ldap.txt";
        $md5file = $uploadDir . "/" . $site . "_to_ldap.md5";

	# /home/filetransfer/stl_to_ldap.md5
        $remotemd5file = "/home/filetransfer/" . $site . "_to_ldap.md5";

	# /home/filetransfer/stl_to_ldap.csv
	$pushFile = $uploadDir . "/to_" .  $site . ".csv"; 
	$remotePushFile = "/home/filetransfer/to_" . $site . ".csv";

        # get files from remote sites if pull is required
#        if (@pull_input[$i] eq "yes")   {
#                $scp = Net::SCP->new({ "host"=>@hosts[$i], "user"=>"filetransfer" } );
#                $scp->get($remotefile, $file) or die "Error getting remote AD file.\n" . $scp->{errstr};
#                $scp->get($remotemd5file, $md5file) or die "Error getting remote AD MD5 file.\n" . $scp->{errstr};
#
#		$scp->put($pushFile, $remotePushFile) or die "Error pushing new LDAP export file.\n" . $scp->{errstr};
#        }






        # verify data file exists, then open it.  Strange way of handling this.
	#  We immediately close it without reading anything from the FD filehandle.  ???
	# Change to if -f($file); 
#	print "Opening file $file\n";
#       $fileOpen = "<" . $file;
#        open (FD, $fileOpen) or die "Can't open file " . substr($fileOpen, 1) . "\n";
#        close FD;

	die("The file $file does not exist!") unless -e $file;
	die("$file is not a file!") unless -f $file;
	# $> is the same as $EUID.  Komodo Edit just whines about it. :)
	die("$file is not readable by $>") unless -r $file;

        # verify checksum file exists.  Open it's contents, and compare the uploaded
	# md5 to the $file specified above.
#        $md5file = "<" . $md5file;
#        open (FD, $md5file) or die "Can't open file " . substr($md5file, 1) . "\n";
#        $line = <FD>;
#        ($md5, $filename) = split(/ /, $line);
#        close FD;

	# Read the MD5FILE into a scalar named "$line".
	# Change this naming convention.  It's too confusing.
	die("$md5file file is not readable by $>") unless -r $md5file;
	open(MD5FILE, $md5file) or die("Cannot open file $md5file for read: $!");
	my $line = <MD5FILE>;
	close(MD5FILE);
	
	# We have to split $line by space, because the contents will be an MD5
	# hash, then an asterisk followed by the target filename.
	my($md5,$filename) = split(/ /, $line);
	
	# This really should be a mathematical comparison, NOT a textual one.
	die("MD5 checksum error for $file") unless $md5 eq file_md5_hex($file);
	
        $i++;
}

# Files should exist and match the hash at this point.


# begin processing
$outputFile = ">" . $uploadDir . "/fromStLouis.ldif";
open (OFD, $outputFile) or die "Can't open file " . substr($outputFile, 1) . "\n";
print OFD "version: 1\n";



$i = 0;
%dns = ();

foreach $site (@sites)  {
	print "Processing data for site $site\n";
	# $site == 'stl';
        $file = "<" . $uploadDir . "/" . $site . "_to_ldap.txt";

        open (FD, $file) or die "Can't open file " . $site . "_to_ldap.txt";
	
	while (<FD>)	{
		# Fix up LDAP entries.
		s/company:/organizationName:/;
		s/mobile:/mobileTelephoneNumber:/;

		# Fix carriage returns
		s/\r//;

		# Current line is the....current line.
		$line = $_;

		if (/^dn.*/)	{
			# If the line begins with "dn", split the fields at the equals sign.
			$fields = split(/=/, $line);
				#my @fields = split(/=/, $line);


			# NoOp?
			$suffix = $dns{@_[1]}++;

			#substr($fields[1],0,-3);		
			# Print to fromStLouis.ldif, "dn: CN=username,OU=fromStlouis,DC=usa,DC=gknaerospace,DC=com"
			print OFD "dn: CN=" . substr(@_[1], 0, -3) . $suffix . ",OU=fromStLouis,DC=usa,DC=gknaerospace,DC=com\n";

			# Remove backlashes from usernames, if they exist.
			@_[1] =~ s/\\//g;


			# Print to fromStLouis.lidf, "cn: username
			print OFD "cn: " . substr(@_[1], 0, -3) . $suffix . "\n";
			print OFD "objectClass: inetOrgPerson\n";
			print OFD "o: " . @siteCompany[$i] . "\n";
			
			if (/Bandy/)	{

				print OFD "localityName: Burbank\n";
				
			}	else	{
		
				print OFD "localityName: " . @siteName[$i] . "\n";

			}

		}	else	{
			$fields = split(/ /, $line);
	                @_[1] =~ s/^\s+//;
       			@_[1] =~ s/\s+$//;

			if (@_[1] eq "-")	{
				next;
			}

                        if (/telephoneNumber/)  {
                                $_ =~ s/\_//g;
                                $_ =~ s/([)])([0-9])/ \2/g;
                                $_ =~ s/[()]//g;
                                $_ =~ s/-/ /g;
                                $_ =~ s/\./ /g;
                                $_ =~ s/^(telephoneNumber: )([0-9])/\1+1 \2/;
                        }

                        if (/facsimileTelephoneNumber/)  {
                                $_ =~ s/\_//g;
                                $_ =~ s/([)])([0-9])/ \2/g;
                                $_ =~ s/[()]//g;
                                $_ =~ s/-/ /g;
                                $_ =~ s/\./ /g;
                                $_ =~ s/^(facsimileTelephoneNumber: )([0-9])/\1+1 \2/;
                        }

                        if (/mobileTelephoneNumber/)  {
                                $_ =~ s/\_//g;
                                $_ =~ s/([)])([0-9])/ \2/g;
                                $_ =~ s/[()]//g;
                                $_ =~ s/-/ /g;
                                $_ =~ s/\./ /g;
                                $_ =~ s/^(mobileTelephoneNumber: )([0-9])/\1+1 \2/;
                        }

			if (! /^changetype.*$/)	{
				print OFD $_;
			}
		}
	}

        close FD;

	$i += 1;
}

# Close the .ldif file.
close OFD;

print "Attempting to connect to LDAP server at 192.168.100.41\n";
$ldap = Net::LDAP->new( '192.168.100.41' ) or die("$@");

print "Connection established, proceeding to bind as Manager\n";
my $mesg = $ldap->bind('cn=Manager,dc=usa,dc=gknaerospace,dc=com', password => '0p3nld4p');

die( "Error ",ldap_error_name($mesg) ) if $mesg->code;

print "Bind as Manager successful.\n";

# Blow away ALL LDAP entries in ou=fromStLouis.
$mesg = $ldap->search( # perform a search
                        base   => "ou=fromStLouis,dc=usa,dc=gknaerospace,dc=com",
                        filter => "(&(objectClass=inetOrgPerson)(mail=*))",
			sizelimit => 5000
		     );

die( "Error ",ldap_error_name($mesg) ) if $mesg->code;

# Iterate and exterminate.
my $entry_count = 0;
foreach my $entry ($mesg->entries) { 
	print "Deleting entry ",$entry->get_value('cn'),"\n";
	$mesg = $ldap->delete($entry);
	die( "Error ",ldap_error_name($mesg) ) if $mesg->code;
	$entry_count++;
}
print "Total entries blown away: $entry_count.\n";
sleep 15;


# add new entries

# Create an ldif object from the contents of fromStLouis.ldif.
my $ldif = Net::LDAP::LDIF->new($uploadDir . "/fromStLouis.ldif");

# This is an awfully odd way to write this while() loop...
while(not $ldif->eof())	{
	my $entry = $ldif->read_entry();
	my $mail = $entry->get_value('mail');
	my $localityName = $entry->get_value('localityName');

	# Set the current record to their e-mail address, all lower cased.
	# Why are we doing this???  Just lc() the original...
	$mail = lc($mail);

	# If the e-mail adress contains usa.gknaerospace.com, OR, the localalities below.
	if ($mail =~ /usa.gknaerospace.com/ || 
		($localityName eq "Garden Grove") || 
		($localityName eq "Australia"))	{


		# If we hit an ldif error , die out, otherwise add the entry to ldap.
		if ( $ldif->error ( ) ) {
			# These are print() instead of warn() so that
			# the errors can be e-mailed, but we don't want to stop
			# running, so we don't die() here either.
     			print "Error msg: ", $ldif->error ( ), "\n";
			print "Error lines:\n", $ldif->error_lines ( ), "\n";
		}
		else {
			print "Adding ",$entry->get_value('cn'),"\n";
			$mesg = $ldap->add($entry);

			# If there's an error, warn on it, but keep going.
			warn( "\nError: ",ldap_error_name($mesg)," while attempting to add \n",$entry->get_value('cn'),"\n The error was:\n",ldap_error_desc($mesg),": ",ldap_error_text($mesg),"\n\n" ) if $mesg->code;
		}
	}	else	{
		print "This is not a usa.gknaerospace.com address: $mail\n";
	}
}

$ldif->done();

# create export file to return to Active Directory
# This file is in csv format.
# $count is our iterator.
$count = 0;
foreach my $site(@sites){
	print "Working on export file for $site\n";	

	# /home/filetransfer/to_stl.csv
	my $outputFile = "$uploadDir/to_$site.csv";
#	open (OFD, $outputFile) or die "Can't open file " . substr($outputFile, 1) . "\n";
	open(OFD, ">$outputFile") or die("Cannot open file $outputFile for write: $!");
	
	# Spreadsheet column headers (the very first line).
	# Since this is going to Windows, newlines are \r\n instead of just \n.
	print OFD "DN,mailNickname,givenName,sn,l,displayName,title,physicalDeliveryOfficeName,telephoneNumber,company,mail,mobile,facsimileTelephoneNumber,c\r\n";

	# read entries from the UK and write to a CSV file
	# Note the sizelimit.
	$mesg = $ldap->search( # perform a search
			# Warwick is the site, Global Address List CONTACT.
                        base   => "ou=WARWICK GALCONTACT,dc=usa,dc=gknaerospace,dc=com",
                        filter => "(&(objectClass=inetOrgPerson)(mail=*))",
			sizelimit => 20000
		     	);
	die( "\nError: ",ldap_error_name($mesg)," while looking up Warwick contacts for export to CSV\n The error was:\n",ldap_error_desc($mesg),": ",ldap_error_text($mesg),"\n\n" ) if $mesg->code;

	foreach my $entry($mesg->entries) { 

		# Get the cn - Lname, Fname
		my $cn =  $entry->get_value ( 'cn');
		# Remove commas from cn
		$cn =~ s/,//g;
		# Remove backlashes from cn.
		# No clue why he did a "one or more of" here instead of just
		# a single backslash escaped.
		$cn =~ s/\+//g;
		
		# cn is now: Lname Fname

		# Country
		my $c = $entry->get_value ( 'c');

		# First name
		# Replace quotes with escaped quotes ie - change " into \" 
		my $givenName = $entry->get_value ( 'givenName');
		$givenName =~ s/\"/\\\"/g;

		# Last Name
		$sn = $entry->get_value ('sn');

		# "Lname FnameCountry"
		$mailNickName = $cn . $c;

		# change to \w instead of "\ ".
		# Remove spaces from mailNickName
		# ShadwickTonyUS
		$mailNickName =~ s/\ //g;

		# Remove quotes from mailNickName.
		$mailNickName =~ s/\"//g;

		# Get the city.
		$l = $entry->get_value ( 'l');

		# If country is NOT defined (change to if !($c) )
		if ($c eq "") {
			# Shadwick, Tony
			$displayName = $sn . ", " . $givenName;
		}
		else	{
			# Shadwick, Tony (US)
			$displayName = $sn . ", " . $givenName . " (" . $c . ")";
		}

		my $title = $entry->get_value ('title');
		my $telephoneNumber = $entry->get_value ('telephoneNumber');
		my $mail = $entry->get_value ('mail');
		my $mobile = $entry->get_value ('mobileTelephoneNumber');
		my $facsimileTelephoneNumber = $entry->get_value ('facsimileTelephoneNumber');
		my $o = $entry->get_value ('o');

		# Replace quotes with escaped quotes ie - change " into \" 
		$cn =~ s/\"/\\\"/g;

		# CN=Shadwick Tony,,,,,,
#		$dn = "CN=" . $cn . "," . @output_OUs[$count];
		my $dn = "CN=$cn,$output_OUs[$count]";
#		my $dn = "CN=$cn";


		print "Current dn is: $dn\n";

		# There's a logical breakage here.  Above after CN=$cn we insert
		# a comma, yet below we also insert one, so we wind up printing
		# a comma in the actual spreadsheet field, AND as a field separator.
		# I also don't understand why we're appending $output_OUs[$count],
		# since $count is the loop iterator, and @output_OUs is an array
		# of empty fields, so no matter what $count is, we're slapping
		# a null value on the end, giving us a comma then nothing.


		# print to csv:
		# CN=Shadwick Tony,,,,,,ShadwickTonyUSA,Tony,Shadwick,St. Louis,Tony Shadwick,dunno,St. Louis,555-1212,GKN Aerospace,shadwick@gknstl.com,555-1212,555-1212,USA
		print OFD "\"$dn\",\"$mailNickName\",\"$givenName\",\"$sn\",\"$l\",\"$displayName\",\"$title\",\"$l\",\"$telephoneNumber\",\"$o\",\"$mail\",\"$mobile\",\"$facsimileTelephoneNumber\",\"$c\"\r\n";

	}

	# read entries from NA and write to a CSV file excluding each sites own entries
	$mesg = $ldap->search( # perform a search
                        base   => "ou=fromStLouis,dc=usa,dc=gknaerospace,dc=com",
                        filter => "(&(objectClass=inetOrgPerson)(mail=*))",
			sizelimit => 20000
		     	);
	$mesg->code && die $mesg->error;
	die( "\nError: ",ldap_error_name($mesg)," while looking up fromStLouis contacts for export to CSV\n The error was:\n",ldap_error_desc($mesg),": ",ldap_error_text($mesg),"\n\n" ) if $mesg->code;

	foreach my $entry($mesg->entries) { 

		# l is "locale".  City in otherwords.
		my $l = $entry->get_value ( 'l');

		# if this locale is not the same as this site name (BAD way of doing this, btw...)
		# Change this to a hash so we're going by names and not iteration numbers. :(
		if ($l ne @siteName[$count]){

			# Get the cn and remove any commas from it.
			# Typically this is Lname, Fname
			# So we end up with LnameFname
			my $cn =  $entry->get_value ('cn');
			$cn =~ s/,//g;

			# Get the country.
			my $c = $entry->get_value ('c');

			# Get the givenName (First Name).
			# Be sure to properly escape our escapes to escape quotes. :P
			my $givenName = $entry->get_value ('givenName');
			$givenName =~ s/\"/\\\"/g;


			# Get the surname (Last Name)		
			my $sn = $entry->get_value ('sn');

			# Here we start with bizarre regexp's to give us Fname Lname (Country)
			# where desired.  Could probably use some cleaning up.

			# Append the country name to the tail of of the CN.
			# We now have Lname FnameCountry
			my $mailNickName = $cn . $c;

			# Delete any spaces or quotes.  The first one is better
			# written as $mailNickName =~ s/\s//g;
			$mailNickName =~ s/\ //g;
			$mailNickName =~ s/\"//g;

			# Fix up display name to make sure it is Lname, Fname.
			my $displayName = "$sn, $givenName";

			my $title = $entry->get_value ('title');
			my $telephoneNumber = $entry->get_value ('telephoneNumber');
			my $mail = $entry->get_value ('mail');
			my $mobile = $entry->get_value ('mobileTelephoneNumber');
			my $facsimileTelephoneNumber = $entry->get_value ('facsimileTelephoneNumber');
			my $o = $entry->get_value ('o');

			# Now we're back to futzing with the cn again.
			# This time we're escaping already escaped quotes.
			$cn =~ s/\"/\\\"/g;

#			$dn = "CN=" . $cn . "," . @output_OUs[$count];
			$dn = "CN=$cn,$output_OUs[$count]";
#			$dn = "CN=$cn";


			# This last line has the same problem as the last routine.
			# we're slapping a comma and a known null ($output_OUs[$count])
			# at the end of every cn.  WHY???

			print OFD "\"$dn\",\"$mailNickName\",\"$givenName\",\"$sn\",\"$l\",\"$displayName\",\"$title\",\"$l\",\"$telephoneNumber\",\"$o\",\"$mail\",\"$mobile\",\"$facsimileTelephoneNumber\",\"$c\"\r\n";
		}

	}

	$count++;

	close OFD;
}

# Why are we waiting so long to unbind?  We should probably pull our records,
# then immediately unbind, do our work, then re-bind again to push.  If we
# don't, then if the connection to the server is broken, we're SOL.
$ldap->unbind;
