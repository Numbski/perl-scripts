#!/usr/bin/env perl

use strict;
use DBI;

my $vibrate = 1;
my $play_sound = 0;
my $sound_to_player ='';


#if(`echo 'select count(*) from call where flags=4 and duration=0 and ROWID=(select max(ROWID) from call)' | sqlite3 /var/mobile/Library/CallHistory/call_history.db`){
#	`vibrate`;
#}

#exit;

my $dbh = DBI->connect("dbi:SQLite:dbname=/var/mobile/Library/CallHistory/call_history.db",
	"", 						# No username
	"",							# No password
	{ RaiseError => 1 },        # complain if something goes wrong
) or die $DBI::errstr;);

my $missed_calls = $dbh->selectall_arrayref('select count(*) from call where flags=4 and duration=0 and ROWID=(select max(ROWID) from call)');

if( scalar(@$missed_calls) ){
	print "You had a missed call!\n";
	`vibrate`;
}
else{
	print "I got nothin'\n";
}
