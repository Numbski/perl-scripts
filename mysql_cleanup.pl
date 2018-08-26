#!/usr/bin/env perl

use strict;
use DBI;
use SQL::Abstract;

my $database_handle = DBI->connect('DBI:mysql:postfix:192.168.100.41','root','L3><ic0n');
my $sql = SQL::Abstract->new;

my ($postfix_statement,@postfix_bind) = $sql->select('postfix_transport',['destination']);
my $postfix_sth = $database_handle->prepare($postfix_statement);
$postfix_sth->execute(@postfix_bind);

print "Importing the global address list\n\n";
my %gal;
while(my $hash = $postfix_sth->fetchrow_hashref()){
    $hash->{'destination'} = lc($hash->{'destination'});
#	print "adding $hash->{'destination'}\n";
	$gal{$hash->{'destination'}} = 1;
}

# Flush memory.
#$postfix_sth = undef;

#print "\n**********************\n\n";

print "Checking spamassassin rules.\n\n";
my ($sa_statement,@sa_bind) = $sql->select('spamassassin',['prefid','username','preference','value'],
	{ 
		'username' => { '!=', '\$GLOBAL', '!=', 'no_such_user@usa.gknaerospace.com' }
	}
);
my $sa_sth = $database_handle->prepare($sa_statement);
$sa_sth->execute(@sa_bind);

while(my $hash = $sa_sth->fetchrow_hashref()){
	next if ($hash->{'username'} eq '$GLOBAL');
    $hash->{'username'} = lc($hash->{'username'});
#	print "Checking $hash->{'username'}\n";
	unless($gal{$hash->{'username'}}){
		print "$hash->{'username'}\t$hash->{'preference'}\t$hash->{'value'}\n";
		my ($delete_statement,@delete_bind) = $sql->delete('spamassassin',$hash);
		my $delete_sth = $database_handle->prepare($delete_statement);
		$delete_sth->execute(@delete_bind);
	}
}


print "Checking the auto whitelist\n\n";
my ($awl_statement,@awl_bind) = $sql->select('awl',['username','email','ip'],
	{ 
		'username' => { '!=', '\$GLOBAL', '!=', 'no_such_user@usa.gknaerospace.com' }
	}
);
my $awl_sth = $database_handle->prepare($awl_statement);
$awl_sth->execute(@awl_bind);

while(my $hash = $awl_sth->fetchrow_hashref()){
	next if ($hash->{'username'} eq '$GLOBAL');
    $hash->{'username'} = lc($hash->{'username'});
#	print "Checking $hash->{'username'}\n";
	unless($gal{$hash->{'username'}}){
		print "Removing AWL for $hash->{'username'}\n";
		my ($delete_statement,@delete_bind) = $sql->delete('awl',$hash);
		my $delete_sth = $database_handle->prepare($delete_statement);
		$delete_sth->execute(@delete_bind);
	}
}

# Purge old awl entries.
# delete from awl where count<=1 and last_modified<(now() - INTERVAL 1 MONTH);

# Purge old bayes_seen entries.
# delete from bayes_seen where last_modified<(now() - INTERVAL 1 MONTH); 


# Get a table dump of bayes_vars.
# Make sure the username field exists.  If not, add that id to the removal list.
# Get a list of bayes_tokens.  Remove all that have an id in the removal list.
# Cycle through the  ids in bayes_tokens.  Make sure they exist in bayes_vars.  If not,
# remove.
