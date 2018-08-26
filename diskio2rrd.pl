#!/usr/bin/env perl
use strict;
use RRDTool::OO;

my $rrd = RRDTool::OO->new(
                 file => "/home/shadwickt/Desktop/rrd-test/new-weight.rrd" );

$rrd->create(
	'start' => (localtime())-1,
#	'step' => 86400, # 24 hour intervals
	'step' => 28800, # 8 hour intervals
	'data_source' => {
		'name' => 'weight',
		'type' => 'GAUGE',
		'min' => 125,
		'heartbeat' => 259200, # Time until graph will draw empty.  3 days.
	},
	'data_source' => {
		'name' => 'lean',
		'type' => 'GAUGE',
		'min' => 125,
		'heartbeat' => 259200, # Time until graph will draw empty.  3 days.
	},
	'archive' => {
		'rows' => '365', # 1 year
		'cpoints' => 3,
		'cfunc' => 'AVERAGE',
	},
	'archive' => {
		'rows' => '365', # 1 year
		'cpoints' => 3,
		'cfunc' => 'LAST',
	},
	'archive' => {
		'rows' => '365', # 1 year
		'cpoints' => 3,
		'cfunc' => 'MAX',
	},
);


# Execute top to get our values.
my $top = `/usr/bin/top -d 1`;
$top =~ /Memory: (\d+)K \((\d+)K\)/;
$top =~ /Memory: (\d+)K \((\d+)K\) real, (\d+)K \((\d+)K\) virtual, (\d+)K free/;
die("Failed to retrieve memory values!") unless $1 and $2 and $3 and $4 and $5;
my $total_allocated_user_ram = $1;
my $active_allocated_user_ram = $2;
my $total_swap_space = $3;
my $active_swap_space = $4;
my $free_ram = $5;
my $system_memory = 8388608 - ($1+$2);
Memory: /Real: 2072M act, 4695M tot  /Virtual: 2832M act, 5701M tot, 1114M free
