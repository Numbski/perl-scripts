#!/usr/bin/env perl

use Numbski;
my $numbski = Numbski->new({
	'path' => '/var/log/mail.log',
});

$numbski->read_as_array(1);
$numbski->read_file();

my %popular_rules;
while(scalar(@{$numbski->contents})){
	my $line = shift(@{$numbski->contents});
	next unless $line =~ /spamd: result:/;
	$line =~ /spamd: result: Y \d+ - (.*?) scantime/;
	die("No matches?  This is the line:\n$line\n") unless $1;
	my @rules = split(/,/,$1);
	foreach my $rule(@rules){
		$popular_rules{$rule}++;
	}
}

foreach my $rule(sort {$popular_rules{$a} <=> $popular_rules{$b}} keys %popular_rules){
	print "$rule:\t$popular_rules{$rule}\n";
}
