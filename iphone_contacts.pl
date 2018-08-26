#!/usr/bin/env perl
use strict;

use DBI;
use SQL::Abstract;
use Numbski;

my $numbski = Numbski->new(
                    'path' => '/home/shadwickt/Desktop/contacts.csv',
                          );

my $database_handle = DBI->connect("dbi:SQLite:dbname=/home/shadwickt/Desktop/AddressBook.sqlitedb","","");
my $sql = SQL::Abstract->new;

my($person_statement,@person_bind) = $sql->select('ABPerson',['ROWID','First','Last','Organization','Note','Kind','JobTitle','Nickname']);
my $person_sth = $database_handle->prepare($person_statement);
$person_sth->execute(@person_bind);

#my($multivalueentry_statement,@multivalueentry_bind) = $sql->select('ABMultiValueEntry');
#my $multivalueentry_sth = $database_handle->prepare($multivalueentry_statement);
#$multivalueentry_sth->execute(@multivalueentry_bind);

my($multivalue_statement,@multivalue_bind) = $sql->select('ABMultiValue');
my $multivalue_sth = $database_handle->prepare($multivalue_statement);
$multivalue_sth->execute(@multivalue_bind);

#my($multivalueentrykey_statement,@multivalueentrykey_bind) = $sql->select('ABMultiValueEntryKey');
#my $multivalueentrykey_sth = $database_handle->prepare($multivalueentrykey_statement);
#$multivalueentrykey_sth->execute(@multivalueentrykey_bind);

#my($multivaluelabel_statement,@multivaluelabel_bind) = $sql->select('ABMultiValueLabel');
#my $multivaluelabel_sth = $database_handle->prepare($multivaluelabel_statement);
#$multivalueelabel_sth->execute(@multivaluelabel_bind);

my $csv = "First,Last,Organization,Home,Work,Mobile,Other,Homepage,Main,Fax\n";

my @people;

while(my $hash = $person_sth->fetchrow_hashref()){
    $people[$hash->{'ROWID'}]->{'first'} = $hash->{'First'};
    $people[$hash->{'ROWID'}]->{'last'} = $hash->{'Last'};
    $people[$hash->{'ROWID'}]->{'organization'} = $hash->{'Organization'};
    #$people[$hash->{'ROWID'}]->{'organization'} =~ s/,/\\,/g;
}

#my @multi_key;

#while(my $hash = $multivalueentrykey_sth->fetchrow_hashref()){
#    push(@multi_key,$hash->value);
#}

my @multi_label = ('other','home','mobile','work','homepage','main','fax');

while(my $hash = $multivalue_sth->fetchrow_hashref()){
    $people[$hash->{'record_id'}]->{$multi_label[$hash->{'label'}]} = $hash->{'value'};
}

foreach my $person(@people){
    print "Working on $person->{'first'} $person->{'last'}\n";
    $csv .= "\"$person->{'first'}\",\"$person->{'last'}\",\"$person->{'organization'}\",\"$person->{'home'}\",\"$person->{'work'}\",\"$person->{'mobile'}\",\"$person->{'other'}\",\"$person->{'homepage'}\",\"$person->{'main'}\",\"$person->{'fax'}\"\n";
}

$numbski->contents($csv);
$numbski->write_file;