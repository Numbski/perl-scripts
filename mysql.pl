#!/usr/bin/env perl

use strict;
use DBI;
use SQL::Abstract;

my $database_handle = DBI->connect('DBI:mysql:postfix:192.168.100.41','root','L3><ic0n');
my $sql = SQL::Abstract->new;

my $na_table;
my $stl_table;
my $merged_table;

my ($na_statement,@na_bind) = $sql->select('na_postfix_transport',['domain','destination']);
my $na_sth = $database_handle->prepare($na_statement);
$na_sth->execute(@na_bind);

while(my $hash = $na_sth->fetchrow_hashref()){
    $hash->{'destination'} = lc($hash->{'destination'});
    $na_table->{$hash->{'destination'}} = $hash->{'domain'};
}

my ($stl_statement,@stl_bind) = $sql->select('postfix_transport',['domain','destination']);
my $stl_sth = $database_handle->prepare($stl_statement);
$stl_sth->execute(@stl_bind);

while(my $hash = $stl_sth->fetchrow_hashref()){
    $hash->{'destination'} = lc($hash->{'destination'});
    $stl_table->{$hash->{'destination'}} = $hash->{'domain'};
}

foreach my $destination(keys %$stl_table){
#    if( $stl_table->{$destination} ne 'smtp:[192.168.100.42]'){
#        print "$destination: $stl_table->{$destination}\n";
#    }
#    if( ( $na_table->{$destination} ) && ( $stl_table->{$destination} ne 'smtp:[192.168.100.42]') ){
#        print "Compared $stl_table->{$destination} to ".'smtp:[192.168.100.42]'."\n";
#        print "Duplicate $destination:\n";
#        print "STL: $stl_table->{$destination}, NA: $na_table->{$destination}\n\n";
#    }

    $merged_table->{$destination}->{'stl_mx'} = $stl_table->{$destination};
}
foreach my $destination(keys %$na_table){
    $merged_table->{$destination}->{'na_mx'} = $na_table->{$destination};
}

foreach my $address(sort keys %$merged_table){
    my $row = {
        'address' => $address,
        'stl_mx' => $merged_table->{$address}->{'stl_mx'},
        'na_mx' => $merged_table->{$address}->{'na_mx'},
    };
    my($insert_statement, @insert_bind) = $sql->insert('mailertable',$row);
    my $insert_sth = $database_handle->prepare($insert_statement);
    $insert_sth->execute(@insert_bind);
}