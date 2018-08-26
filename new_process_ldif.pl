#!/usr/bin/perl -w

use strict;

use Net::LDAP;
use Net::LDAP::Util qw(
                        ldap_error_text
                        ldap_error_name
                        ldap_error_desc
                        canonical_dn
                        );

use Net::LDAP::LDIF;
use Math::BigInt;
use Digest::MD5::File qw(file_md5_hex);

# Globals
use constant DEBUGGING => 0;

my $upload_dir = '/home/filetransfer';
my $ldap_server = '192.168.100.41';

# Each site we work with gets a definition within this hash.
# To add a new one, simply copy and paste one of the entries, and
# change the appropriate information.
my %sites = (
    'stl' => {
        'name' => 'St. Louis',
        'company' => 'GKN Aerospace North America, Inc',
        'division' => 'Aerostructures',
        'site_admin' => 'tony.shadwick@usa.gknaerospace.com',
        'country' => 'US',
        'pull_input' => 0,
    },
    
    'ala' => {
        'name' => 'Tallassee',
        'company' => 'GKN Aerospace North America, Inc',
        'division' => 'Aerostructures',
        'site_admin' => 'tony.shadwick@usa.gknaerospace.com',
        'country' => 'US',
        'pull_input' => 0,
    },    
    
    'elc' => {
        'name' => 'El Cajon',
        'company' => 'GKN Aerospace North America, Inc',
        'division' => 'Aerostructures',
        'site_admin' => 'tony.shadwick@usa.gknaerospace.com',
        'country' => 'US',
        'pull_input' => 1, # Not so sure about this...
        'scp_host' => '70.164.112.227',
    },
    
    'mon' => {
        'name' => 'Amityville',
        'company' => 'GKN Aerospace North America, Inc',
        'division' => 'Aerostructures',
        'site_admin' => 'tony.shadwick@usa.gknaerospace.com',
        'country' => 'US',
        'pull_input' => 0,
    },

    'pre' => {
        'name' => 'Wellington',
        'company' => 'GKN Aerospace North America, Inc',
        'division' => 'Aerostructures',
        'site_admin' => 'tony.shadwick@usa.gknaerospace.com',
        'country' => 'US',
        'pull_input' => 0,
    },

    'gg' => {
        'name' => 'Garden Grove',
        'company' => 'GKN Aerospace Transparency Systems, Inc',
        'division' => 'Aerostructures',
        'site_admin' => 'tony.shadwick@usa.gknaerospace.com',
        'country' => 'US',
        'pull_input' => 0,
    },

    'nash' => {
        'name' => 'Nashville',
        'company' => 'GKN Aerospace North America, Inc',
        'division' => 'Aerostructures',
        'site_admin' => 'tony.shadwick@usa.gknaerospace.com',
        'country' => 'US',
        'pull_input' => 0,
    },

    'bandy' => {
        'name' => 'Burbank',
        'company' => 'GKN Aerospace North America, Inc',
        'division' => 'Aerostructures',
        'site_admin' => 'tony.shadwick@usa.gknaerospace.com',
        'country' => 'US',
        'pull_input' => 0,
    },

    'aus' => {
        'name' => 'Australia',
        'company' => 'GKN Aerospace Australia',
        'division' => 'Aerostructures',
        'site_admin' => 'tony.shadwick@usa.gknaerospace.com',
        'country' => 'AU',
        'pull_input' => 0,
    },
);

# Let us know what user this is exec'ing as if we're in debug mode.
print "Running with permissions of the user ".getpwuid($>)."\n\n" if DEBUGGING;

######################
# Logic begins here. #
######################

# Iterate through each site, and verify the md5 hash of the
# files they have uploaded.

VERIFY:
foreach my $site(keys %sites){
    print "Checking MD5 for site $site\n" if DEBUGGING;
	
    # $site."_to_ldap.txt" should be the uploaded contacts.
    my $input_file = "$upload_dir/$site"."_to_ldap.txt";
    print "Input file: $input_file\n" if DEBUGGING;

    # $md5file is the file the remote site uploaded with the md5 hash
    # and the name of the file the hash applies to.  I *really* wish
    # they had just put the hash and not the *$filename bit...
    my $md5_file = "$upload_dir/$site" . "_to_ldap.md5";
    print "MD5 file: $md5_file\n" if DEBUGGING;


    # $output_csv is the file the remote sites can pull in order to
    # update their own global address book or contact lists.
    my $output_csv = "$upload_dir/to_$site.csv"; 
    print "Output CSV: $output_csv\n" if DEBUGGING;

#   The following logic is disabled - apparently at one point in time this
#   was done, so I'm retaining it just in case, but this is typically unused.
#
#    Get files from remote sites if pull is required
#    if ( $sites{$site}->{'pull_input'} ){
#        my $scp = Net::SCP->new({
#            'host' => $sites{$site}->{'scp_host'},
#            'user' => 'filetransfer',
#            });
#
#        These each need to be full paths, remote file, local file on get, and
#        vice-versa on put.
#        $scp->get($input_file, $input_file) or die("Error getting remote AD file.\n" . $scp->{errstr});
#        $scp->get($md5_file, $md5_file) or die("Error getting remote AD MD5 file.\n" . $scp->{errstr});
#        $scp->put($output_csv, $output_csv) or die("Error pushing new LDAP export file.\n" . $scp->{errstr});
#    }

        next VERIFY and warn("The file $input_file does not exist!") unless -e $input_file;
        next VERIFY and warn("$input_file is not a file!") unless -f $input_file;
        # $> is the Effective User ID, or $EUID.  Komodo Edit
        # whines if I try to use $EUID for some reason though.
        next VERIFY and warn("$input_file is not readable by $>") unless -r $input_file;

        # Go ahead and read in the md5_file.
        print "MD5FILE: $md5_file\n";
        die("$md5_file file is not readable by $>") unless -r $md5_file;
        open(MD5FILE, $md5_file) or die("Cannot open file $md5_file for read: $!");
        my $md5_file_contents = <MD5FILE>;
        $md5_file_contents =~ s/\r\n$//;
        close(MD5FILE);

        # We have to split $md5_file_contents by space, because the contents
        # will be an MD5 hash, then an asterisk followed by the target filename.
        # Normalize this in case they get sloppy.
        $md5_file_contents =~ s/\s+/ /g;
        my($md5,$filename) = split(/\s/, $md5_file_contents);
        $filename = lc($filename);
        $filename =~ s/\*//g;
        print "MD5: $md5\nFILE: $filename\n\n";

        # Check the md5 out and die out on failure.
        if(-f "$upload_dir/$filename"){
            print "Comparing ". Math::BigInt->new('0x'.$md5)->as_hex ." to ". Math::BigInt->new('0x'.file_md5_hex("$upload_dir/$filename"))->as_hex ."\n" if DEBUGGING;
            die("MD5 checksum error for $upload_dir/$filename.  The comparison was:
                Provided MD5: ".Math::BigInt->new('0x'.$md5)->as_hex."
                Actual MD5: ".Math::BigInt->new('0x'.file_md5_hex("$upload_dir/$filename"))->as_hex)
                unless Math::BigInt->new('0x'.$md5)->as_int ==
                    Math::BigInt->new('0x'.file_md5_hex("$upload_dir/$filename"))->as_int;
        }
        else{
            # Change this to die() before putting into production.
            warn("$upload_dir/$filename does not exist.  Moving to the next file.  Change me to die()");
        }
}

# Files should exist and match the hash at this point.

# Begin creating the ldif for import back into LDAP.
# The fromStLouis OU will be the one that UK reads for everyone else's contacts.
open (LDIF, ">$upload_dir/fromStLouis.ldif") or die "Can't open file $upload_dir/fromStLouis.ldif for write! $!";

# Print the header into the ldif file.
print LDIF "version: 1\n";


# Iterate the sites again.  This time we're going to munge the contacts
# to our preferred format, and write them to the ldif.  We know these are good,
# because they passed our md5 check above.
foreach my $site(keys %sites){
    print "Processing data for site $site\n" if DEBUGGING;
    open(TXT, "$upload_dir/$site"."_to_ldap.txt") or die("Can't open file $upload_dir/$site" . "_to_ldap.txt for read: $!");

    while (<TXT>)	{
        # Remove carriage returns and newlines.
        s/\r//;
        s/\n//;

        # Move to the next record unless this line is not blank.
        if(!$_){
            next;
        }
        # If our current record (current line) begins with dn...
        elsif (/^dn.*/){

            /^dn:\scn=(.*?),\w+=/i;
            
            die("Failed to find a value cn in this string:\n$_\nThe regex used was:
".'/^dn:\scn=(.*?),\w+=/i'."\n") unless $1;

            my $cn = $1;
            
            # Print to fromStLouis.ldif, "dn: CN=username,OU=fromStlouis,DC=usa,DC=gknaerospace,DC=com"
            print LDIF "\ndn: CN=$cn,OU=fromStLouis,DC=usa,DC=gknaerospace,DC=com\n";

            # Remove backlashes from usernames, if they exist.
            $cn =~ s/\\//g;


            # Print the following to fromStLouis.ldif
            print LDIF "cn: $cn\n";
            print LDIF "objectClass: inetOrgPerson\n";
            print LDIF "o: $sites{$site}->{'company'}\n";
            print LDIF "localityName: $sites{$site}->{'name'}\n";
            print LDIF "c: ".$sites{$site}->{'country'}."\n";
        }
        
        # Otherwise, if our current record is *not* a DN...
        else{
            # Properly format these LDAP entries.
            s/company:/organizationName:/;
            s/mobile:/mobileTelephoneNumber:/;

            /^(\w+):+(.*)/;
            die("I received no field and value for this line:\n$_\n") unless $1 && $2;
            my $field = $1;
            my $value = $2;

            # If the field is any type of phone number..
            if ( ($field eq 'telephoneNumber') or
                 ($field eq 'facsimileTelephoneNumber') or
                 ($field eq 'mobileTelephoneNumber') ){

                # Get rid of underscores.
                $value =~ s/\_//g;
                # Hunt down any right parens followed by numbers, and leave just the numbers.
                # This logic needs fixed.
                #$value =~ s/([)])([0-9])/ \2/g;

                # Classify and delete any parens...
                $value =~ s/[()]//g;
                # ...or dashes...
                $value =~ s/-/ /g;
                # ...or dots...
                $value =~ s/\./ /g;
                #...or spaces...
                $value =~ s/\s//g;
                # Clean up the formatting.
                # Blindly presume that the country code is North America.
                $value =~ /(\d{3})(\d{3})(\d{4})/;
                $value = "+1 ($1) $2 $3";
            }

            # Print this field and value to the LDIF so long as it isn't
            # specifying a change type, since we're reloading the whole thing
            # anyway, and they will all be changetype: add.
            print LDIF "$field: $value\n" unless ($field eq 'changetype');
        }
    }
    # Once we've processed all records from the file, we can close it.
    close TXT;
}

# Once we've gotten all of our records, we can close out the LDIF file.
close LDIF;

# Next we attempt to reach the LDAP server and instantiate an ldap object.
print "Attempting to connect to LDAP server at 192.168.100.41\n" if DEBUGGING;
my $ldap = Net::LDAP->new( $ldap_server ) or die("$@");

print "Connection established, proceeding to bind as Manager\n" if DEBUGGING;
my $mesg = $ldap->bind('cn=Manager,dc=usa,dc=gknaerospace,dc=com', password => '0p3nld4p');

# If we failed to bind, die out and tell us why.
die( "Error: ",ldap_error_name($mesg)," while attempting to bind as Manager to $ldap_server.  The error was:
    ",ldap_error_desc($mesg),": ",ldap_error_text($mesg) ) if $mesg->code;

print "Bind as Manager successful.\n" if DEBUGGING;

# Search for all entries in fromStLouis.  We will then iterate and delete them all.
$mesg = $ldap->search( # perform a search
                        base   => "ou=fromStLouis,dc=usa,dc=gknaerospace,dc=com",
                        filter => "(&(objectClass=inetOrgPerson)(mail=*))",
                        sizelimit => 5000
    );

# Die out if the search failed, and tell us precisely what went wrong.
die( "Error: ",ldap_error_name($mesg)," while attempting to search for all entries in ou=fromStLouis.  The error was:
    ",ldap_error_desc($mesg),": ",ldap_error_text($mesg) ) if $mesg->code;

# Iterate and exterminate.
print "Proceeding to purge the fromStLouis OU.\n" if DEBUGGING;
print "Since we are in debug mode, I am only going to pretend to delete entries.\n" if DEBUGGING;
sleep 3 if DEBUGGING;

my $entry_count = 0;
foreach my $entry ($mesg->entries) { 
    print "Pretending to delete entry ",$entry->get_value('cn'),"\n" if DEBUGGING;
    $mesg = $ldap->delete($entry) unless DEBUGGING;
    die( "Error: ",ldap_error_name($mesg),
        " while attempting to delete ".$entry->get_value('cn').
        " from ou=StLouis.  The error was: ",
        ldap_error_desc($mesg),": ",ldap_error_text($mesg) ) if $mesg->code;
    $entry_count++;
}

((print "Total entries that would have been deleted from ou=fromStLouis: $entry_count.\n") &&
 (sleep 5)) if DEBUGGING;

# Read the contents of our newly created LDIF file, and push the contents into LDAP.
# Create an ldif object from the contents of fromStLouis.ldif.
my $ldif = Net::LDAP::LDIF->new("$upload_dir/fromStLouis.ldif") or
    die("Failed to create an LDIF instance using $upload_dir/fromStLouis.ldif: $!");

# Iterate the contents of the LDIF.

print "Proceeding to re-populate the fromStLouis OU\n" if DEBUGGING;
print "Since we are in debug mode, I will only pretend to insert entries into LDAP.\n" if DEBUGGING;

while(not $ldif->eof())	{
    my $entry = $ldif->read_entry();

    # Get the e-mail address and lowercase it.
    my $mail = $entry->get_value('mail');
    $mail = lc($mail);

    my $localityName = $entry->get_value('localityName');

    # If the e-mail adress contains usa.gknaerospace.com, OR, the localalities below.
    if ($mail =~ /usa.gknaerospace.com/ || 
        ($localityName eq "Garden Grove") || 
        ($localityName eq "Australia")){

        # If we hit an ldif error , die out, otherwise add the entry to ldap.
        if ( $ldif->error() ){
            # These are print() instead of warn() so that
            # the errors go to STDOUT and can be e-mailed, but we don't want to
            # stop running, so we don't die() here either.
            print "Error msg: ", $ldif->error ( ), "\n";
            print "Error lines:\n", $ldif->error_lines ( ), "\n";
            sleep 3;
        }
        else {
            print "Pretending to add ".$entry->get_value('cn'),"\n" if DEBUGGING;
            $mesg = $ldap->add($entry) unless DEBUGGING;

            # Same story here.  print() instead of warn().
            print( "\nError: ",ldap_error_name($mesg)," while attempting to add \n",
                 $entry->get_value('cn'),"\nThe error was - ",ldap_error_desc($mesg),
                 ":\n",ldap_error_text($mesg) ) if $mesg->code;
        }
    }
    else{
        # Same here.  We print() instead of warn() so that it goes to STDOUT.
        print "This is not a usa.gknaerospace.com address: $mail\n";
    }
}
# Close out the ldif now that we're done going through it.
$ldif->done();

# Now we create a contact export file in csv format for all sites other than the
# UK.  These sites will do with that file as they see fit to populate their own
# contacts database.

# Iterate the sites yet again.
foreach my $site(keys %sites){
    print "Working on export file for $site\n" if DEBUGGING;

    # Set the $output_file to be to_$site.csv
    open(CSV, ">$upload_dir/to_"."$site.csv") or die("Cannot open file $upload_dir/to_"."$site.csv for write: $!");

    # Spreadsheet (csv) column headers - ie, the very first line.
    # Since this is going to Windows, newlines are \r\n instead of just \n.
    print CSV "DN,mailNickname,givenName,sn,l,displayName,title,physicalDeliveryOfficeName,telephoneNumber,company,mail,mobile,facsimileTelephoneNumber,c\r\n";

    # Read entries from the UK and write to a CSV file
    # Note the sizelimit.
    $mesg = $ldap->search( # perform a search
        # Warwick is the site, Global Address List CONTACT.
        base   => "ou=WARWICK GALCONTACT,dc=usa,dc=gknaerospace,dc=com",
        filter => "(&(objectClass=inetOrgPerson)(mail=*))",
        sizelimit => 20000
        );
    # If this failed, die out and tell us why.
    die( "Error: ",ldap_error_name($mesg),
        " while looking up Warwick contacts for export to CSV
The error was:
",ldap_error_desc($mesg),": ",ldap_error_text($mesg) ) if $mesg->code;

        # Iterate through all of the LDAP entries returned for ou=WARWICK GALCONTACT
        foreach my $entry($mesg->entries) { 
            # Get the CN (Common Name)- Lname, Fname
            my $cn =  $entry->get_value('cn');

            # Remove commas from the CN.
            $cn =~ s/,//g;

            # Remove backlashes from CN.
            $cn =~ s/\\//g;
            # cn is now: Lname Fname

            # Replace quotes with escaped quotes ie - change " into \" 
            $cn =~ s/\"/\\\"/g;

            # Country - If we get no value, it's safe to presume they're in the UK.
            # Not so fast, detect by phone number country code if possible.
            my $c;
            if ( $entry->get_value('telephoneNumber') ){
                if($entry->get_value('telephoneNumber') =~ /^\++1.*/ ){
                    $c = 'US';
                }
                elsif($entry->get_value('telephoneNumber') =~ /^\++44.*/ ){
                    $c = 'UK';
                }
                elsif($entry->get_value('telephoneNumber') =~ /^\++61.*/ ){
                    $c = 'AU';
                }
            }
            elsif ( $entry->get_value('facsimileTelephoneNumber') ){
                if($entry->get_value('facsimileNumber') =~ /^\++1.*/ ){
                    $c = 'US';
                }
                elsif($entry->get_value('facsimileNumber') =~ /^\++44.*/ ){
                    $c = 'UK';
                }
                elsif($entry->get_value('facsimileNumber') =~ /^\++61.*/ ){
                    $c = 'AU';
                }
            }
            elsif ( $entry->get_value('mobileTelephoneNumber') ){
                if($entry->get_value('mobileNumber') =~ /^\++1.*/ ){
                    $c = 'US';
                }
                elsif($entry->get_value('mobileNumber') =~ /^\++44.*/ ){
                    $c = 'UK';
                }
                elsif($entry->get_value('mobileNumber') =~ /^\++61.*/ ){
                    $c = 'AU';
                }
            }

            # First name
            # Replace quotes with escaped quotes ie - change " into \" 
            my $givenName = $entry->get_value('givenName') || "";
            $givenName =~ s/\"/\\\"/g;

            # Last Name ("Surname")
            my $sn = $entry->get_value('sn') || "";

            # Append the country to mailNickName so long as it is defined and
            # not null or zero.  mailNickName should come out without spaces,
            # with the country appended at the end, so LnameFnameCountry
#            my $mailNickName = $cn;
            my $mailNickName = $sn.$givenName;

            $mailNickName .= " $c" if $c;

            # Remove white space from mailNickName
            $mailNickName =~ s/\s//g;

            # Remove quotes from mailNickName.
            $mailNickName =~ s/\"//g;

            # Kill the trailing zero if it has hung around.
            $mailNickName =~ s/0$//;


            print "mailNickname for $cn is $mailNickName\n" if DEBUGGING;

            # Get the city (locale).  If there isn't one, set it blank.
            my $l = $entry->get_value('l') || "";

            my $displayName;
            # If country is either not defined, null, or zero...
            if (!$c) {
                # set the displayName as Lname, Fname
                $displayName = "$sn, $givenName";
            }
            else{
                # otherwise, make it Lname, Fname (Country)
                $displayName = "$sn, $givenName ($c)";
            }

            # Grab the remaining values that matter.
            my $title = $entry->get_value('title') || "";
            my $telephoneNumber = $entry->get_value('telephoneNumber') || "";
            my $mail = $entry->get_value('mail') || "";
            my $mobile = $entry->get_value('mobileTelephoneNumber') || "";
            my $facsimileTelephoneNumber = $entry->get_value('facsimileTelephoneNumber') || "";
            my $o = $entry->get_value('o') || "";

            # Define the output DN.
            # in the original script, this included all of the DN, including OU's
            # and DC's.  The current running version outputs nulls as a bug.  I'm
            # thus leaving this as just the CN until such time I see a need to
            # go through and put in all of that data.
            my $dn = "CN=$cn";

            # Print the contact information to the CSV.  Remember that each value
            # has to be quoted in the output, and escaped here.
            print CSV "\"$dn\",\"$mailNickName\",\"$givenName\",\"$sn\",\"$l\",\"$displayName\",\"$title\",\"$l\",\"$telephoneNumber\",\"$o\",\"$mail\",\"$mobile\",\"$facsimileTelephoneNumber\",\"$c\"\r\n";
        }

	# Read entries from NA and write to a CSV file excluding each site's own entries
	$mesg = $ldap->search( # perform a search
                        base   => "ou=fromStLouis,dc=usa,dc=gknaerospace,dc=com",
                        filter => "(&(objectClass=inetOrgPerson)(mail=*))",
                        sizelimit => 20000,
            );

	die( "Error: ",ldap_error_name($mesg),
            " while looking up fromStLouis contacts for export to CSV
The error was:
",ldap_error_desc($mesg),": ",ldap_error_text($mesg),"\n\n" ) if $mesg->code;


        # Iterate through the returned entries.
        foreach my $entry($mesg->entries) { 
            # Get the city (locale).
            my $l = $entry->get_value('l') || "";

            # If the locale does not match the current site's name...
            if ($l ne $sites{$site}->{'name'}){
                # Get the cn (Common Name) and remove any commas from it.
                # Typically this is Lname, Fname
                # So we end up with Lname Fname
            my $cn =  $entry->get_value('cn') || "";
            $cn =~ s/,//g;
            
            # Fix the self-perpetuating 0's attached to the ends of cn's.
            $cn =~ s/0$//;

            print "Working on ". $cn. "\n" if DEBUGGING;

            # Get the country.
            my $c = $entry->get_value('c') || "";
            print "Country for this person is: $c\n" if DEBUGGING;

            # Get the givenName (First Name).
            # Be sure to properly escape our escapes to escape quotes. :P
            my $givenName = $entry->get_value('givenName') || "";
            $givenName =~ s/\"/\\\"/g;


            # Get the surname (Last Name)
            my $sn = $entry->get_value('sn') || "";

            # Create the mailNickName.  It should be LnameFnameCountry

            #print "Creating mailNickName\n" if DEBUGGING;
            #my $mailNickName = $cn;
            my $mailNickName = $sn.$givenName;
            
            # Remove whitespace and quotes.
            $mailNickName =~ s/\s//g;
            $mailNickName =~ s/\"//g;
	# Remove the zero at the end, if it managed to hand around.
            $mailNickName =~ s/0$//;

            # Append the country.
            $mailNickName .= " $c" if $c;
            print "mailNickName for $cn is $mailNickName\n" if DEBUGGING;

            # Delete any spaces or quotes.
            $mailNickName =~ s/\s//g;
            $mailNickName =~ s/\"//g;

            # Fix up display name to make sure it is Lname, Fname.
            my $displayName = "$sn, $givenName";

            # Parse up the rest of the entries.
            my $title = $entry->get_value('title') || "";
            my $telephoneNumber = $entry->get_value('telephoneNumber') || "";
            my $mail = $entry->get_value('mail') || "";
            my $mobile = $entry->get_value('mobileTelephoneNumber') || "";
            my $facsimileTelephoneNumber = $entry->get_value('facsimileTelephoneNumber') || "";
            my $o = $entry->get_value ('o') || "";

            # Escape any already escaped quotes in the CN.
            $cn =~ s/\"/\\\"/g;

            # The DN is abbreviated to only the CN portion, just as with the UK.
            # The original script had apparently capacity to include OU's and
            # DC's, but for whatever reason they were nulled out, and introduced
            # a bug into the system.  For compatibility and bug fixing, I'm only
            # using the CN.  I can always fix this part later.
            my $dn = "CN=$cn";

            print CSV "\"$dn\",\"$mailNickName\",\"$givenName\",\"$sn\",\"$l\",\"$displayName\",\"$title\",\"$l\",\"$telephoneNumber\",\"$o\",\"$mail\",\"$mobile\",\"$facsimileTelephoneNumber\",\"$c\"\r\n";
        }
    }
    close CSV;
}

# Unbind after processing all sites to CSV.
$ldap->unbind;
