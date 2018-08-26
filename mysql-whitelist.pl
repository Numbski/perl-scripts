#!/usr/bin/env perl

use strict;
use DBI;
use SQL::Abstract;

my $database_handle = DBI->connect('DBI:mysql:postfix:192.168.100.41','root','L3><ic0n');
my $sql = SQL::Abstract->new;


my @whitelist = (
'BAYES_99 4.8',
'DIET_1 3.0',
'FROM_LOCAL_NOVOWEL 2.0',
'FH_XMAIL_RND_833 2.0',
'HELO_DYNAMIC_DHCP 2.0',
'HTML_IMAGE_ONLY_20 1.0 ',
'HTML_IMAGE_ONLY_08 1.0',
'HTML_IMAGE_RATIO_06 1.0',
'HTML_MESSAGE 1.0',
'MIME_HTML_ONLY 1.0',
'NORMAL_HTTP_TO_IP 3.0',
'PREST_NON_ACCREDITED 4.0',
'RAZOR2_CF_RANGE_51_100 1.0',
'RAZOR2_CF_RANGE_E8_51_100 2.0',
'RCVD_IN_PBL 4.0',
'RCVD_IN_SORBS_DUL 3.0',
'RDNS_NONE 2.5',
'RDNS_DYNAMIC 2.0',
'SARE_FASTAPPRV 3',
'SARE_HOUSEWIVES 3',
'SARE_LWACT_QUICKLY 3',
'SARE_OBFUMONEY2 3',
'SARE_SPEC_XXGEOCITIES2 2.0',
'SARE_SUB_ENC_KOI8R 5',
'SARE_UNI 3.0',
'SARE_UNSUB17 3.0',
'SARE_UNSUB24 3.0',
'SARE_UNSUB31 3.0',
'SARE_UNSUB36 3.0',
'SARE_UNSUB38 3.0',
'SARE_UNSUB38D 3.0',
'SARE_WEOFFER 3.0',
'SUBJ_YOUR_DEBT 3.0',
'URIBL_BLACK 7.0',
'URIBL_JP_SURBL 4.0',
'URIBL_RHS_DOB 4.0',
'URIBL_SBL 4.0',
);



foreach my $domain (sort @whitelist){
    chomp($domain);
    my($rule,$score) = split(/ /,$domain);
    my $row = {
        'username' => '$GLOBAL',
        'preference' => "score $rule",
        'value' => $score,
    };
    my($insert_statement, @insert_bind) = $sql->insert('spamassassin',$row);
    my $insert_sth = $database_handle->prepare($insert_statement);
    $insert_sth->execute(@insert_bind);
}

