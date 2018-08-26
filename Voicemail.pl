#!/usr/bin/env perl

use strict;

package OSS::Voicemail;

# Provides voicemail access functions in the OSS Solutions data center. :)
use Asterisk::Manager;

$|++;

my $astman = new Asterisk::Manager;

# Get this stuff from the database, obviously.
$astman->user('admin');
$astman->secret('amp111');
$astman->host('172.16.10.7');

my $new_messages = check_for_new_messages($astman);

print "You have $new_messages new Voicemail messages.\n";

sub check_for_new_messages{
	# Returns the number of new voicemail messages.
	my $astman = shift;

	$astman->connect or die($astman->error);


	# Really need to get Mailbox from the database.
	# The new system needs to have e-mail address styled mailboxes.
	my %result = $astman->sendcommand( Action => 'MailBoxCount',
					Mailbox => '105@default',
				);

	foreach my $key(keys %result){
		print "$key: $result{$key}\n";
	}
	print "\n";
	$astman->disconnect;

	return($result{'NewMessages'});
}
