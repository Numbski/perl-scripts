#!/usr/bin/env perl -w

use strict;

use Net::LDAP;
use Net::LDAP::Util qw(
			ldap_error_text
			ldap_error_name
			ldap_error_desc
			canonical_dn
			);

#my $username = shift;
#my $password = shift;

#my $uid = shift;

print "Attempting to connect to LDAP server at gknstl.com\n";
#my $ldap = Net::LDAP->new('gknstl.com') or die($@);
my $ldap = Net::LDAP->new('192.168.100.41') or die($@);
print "Connected.  Attempting to bind.\n";

my $mesg;

# bind to a directory with dn and password
#$mesg = $ldap->bind( "cn=Tony Shadwick,ou=Users and Groups,ou=IT,ou=Business Units,dc=gknstl,dc=com",
#                      password=>'gkn4oss2600!!!'
#                   );
$mesg = $ldap->bind( "cn=svc_galcontact,ou=users,dc=usa,dc=gknaerospace,dc=com",
                      password=>'GALCONTACTpassword77'
                   );

if($mesg->code){
       die( "Error ",ldap_error_name($mesg) );
}
else{
	print "Success!\n";
	exit;
}
# See if we can find me.
$mesg = $ldap->search(
                       base => "OU=Users and Groups,OU=IT,OU=Business Units,dc=gknstl,dc=com",
#			filter => "cn=Tony Shadwick"
			filter => "sAMAccountName=shadwickt"
                      );

if($mesg->code){
       die( "Error ",ldap_error_name($mesg) );
}
else{
#       while(my $entry = $mesg->shift_entry){
       	  foreach my $entry(sort{$a->get_value('cn') cmp $b->get_value('cn')} $mesg->entries){
               print $entry->get_value('cn'),"\n";
	   }
#	}
}
exit;

# bind to a directory with dn and password
$mesg = $ldap->bind( "cn=Tony Shadwick,ou=Users and Groups,ou=IT,ou=Business Units,dc=gknstl,dc=com",
                      password=>'gkn4oss2600!!!'
                   );


# bind to a directory with dn and password
#my $mesg = $ldap->bind( "cn=backupexec",
#my $mesg = $ldap->bind( 'CN=Backupexec,OU=NA Service Accounts,dc=na,dc=gkn',
#                      password => 'F0rt3l$2004'
#                   );

#print "Attempting to connect to LDAP server at 192.168.100.41\n";
#my $ldap = Net::LDAP->new( '192.168.100.41' ) or die("$@");

#print "Connection established, proceeding to bind as Manager\n";
#my $mesg = $ldap->bind('cn=Manager,dc=usa,dc=gknaerospace,dc=com', password => '0p3nld4p');

die( "Error ",ldap_error_name($mesg) ) if $mesg->code;

print "Bind as backupexec successful.\n";

#my $mesg = $ldap->search( # perform a search
#                        base   => "ou=toStLouis,dc=usa,dc=gknaerospace,dc=com",
#                        #filter => "(&(sn=Barr) (o=Texas Instruments))"
#			#filter => "memberUid=$uid",
#			filter => "(&(objectClass=inetOrgPerson)(mail=*))",
#			#sizelimit => 10,
#                      );

#	my $mesg = $ldap->search( # perform a search
#			# Warwick is the site, Global Address List CONTACT.
#                        base   => "ou=toStLouis,dc=usa,dc=gknaerospace,dc=com",
#                        filter => "(&(objectClass=inetOrgPerson)(mail=*))",
#			sizelimit => 20000
#		     	);

#my $count = 0;
#if($mesg->code){
#	die( "Error ",ldap_error_name($mesg) );
#}
#else{
#	while(my $entry = $mesg->shift_entry){
#	foreach my $entry($mesg->entries){
#		print $entry->get_value('cn'),"\n";
#		print $entry->dn,"\n";
#		print "uid: ",$entry->get_value('uidNumber'), "\n";
#		print "picture: ",$entry->get_value('apple-user-picture'), "\n";
#		print "email: ",$entry->get_value('mail'), "\n";
#		my @attributes = $entry->attributes;
#
#		foreach(@attributes){
#			print "$_: ", $entry->get_value($_) ,"\n";
#		}
#		$count++;
#	}
#}

#print "$count entries\n";

#foreach(keys %$mesg){
#	print "$_: ";
#	print "$mesg->{$_}" if $mesg->{$_};
#	print "\n";
#}
#
#foreach my $entry( @{ $mesg->{'entries'} }  ){
#	foreach my $entry_type(keys %$entry){
#		print "\t$entry_type: $entry->{$entry_type}\n";
#		if(ref($entry->{$entry_type}) eq 'ARRAY'){
#			foreach(@{ $entry->{$entry_type} } ){
#				print "\t\t$_\n";
#			}
#		}
#		elsif(ref($entry->{$entry_type}) eq 'HASH'){
#			foreach(keys %{$entry->{$entry_type}}){
#				print "\t\t$_: $entry->{$entry_type}->{$_}\n";
#			}
#		}
#		else{
#			print "\t\t No match.  Reference type was: ";
#			print ref($entry->{$entry_type}), "\n";
#		}
#	}
#}
