#!/usr/bin/env perl
use strict;
use Class::Date;
use RRDTool::OO;

# This is used to re-create the whole rrd database from scratch.
# Hopefully I won't have to do this very much.
my @entries = (
	{ 'month' => 9, 'day' =>27, 'year' => 2009, 'weight' =>189.5, 'lean' =>},
	{ 'month' => 9, 'day' =>28, 'year' => 2009, 'weight' =>189, 'lean' =>},
	{ 'month' => 9, 'day' =>30, 'year' => 2009, 'weight' =>189, 'lean' =>},
	{ 'month' => 10, 'day' =>2, 'year' => 2009, 'weight' =>191, 'lean' =>},
	{ 'month' => 10, 'day' =>5, 'year' => 2009, 'weight' =>189, 'lean' =>},
	{ 'month' => 10, 'day' =>6, 'year' => 2009, 'weight' =>188.5, 'lean' =>},
	{ 'month' => 10, 'day' =>7, 'year' => 2009, 'weight' =>188.8, 'lean' =>},
	{ 'month' => 10, 'day' =>9, 'year' => 2009, 'weight' =>189.5, 'lean' =>},
	{ 'month' => 10, 'day' =>11, 'year' => 2009, 'weight' =>189.2, 'lean' =>},
	{ 'month' => 10, 'day' =>12, 'year' => 2009, 'weight' =>188.1, 'lean' =>},
	{ 'month' => 10, 'day' =>13, 'year' => 2009, 'weight' =>191.5, 'lean' =>},
	{ 'month' => 10, 'day' =>14, 'year' => 2009, 'weight' =>188.5, 'lean' =>},
	{ 'month' => 10, 'day' =>15, 'year' => 2009, 'weight' =>185.2, 'lean' =>},
	{ 'month' => 10, 'day' =>16, 'year' => 2009, 'weight' =>188, 'lean' =>},
	{ 'month' => 10, 'day' =>20, 'year' => 2009, 'weight' =>188.5, 'lean' =>},
	{ 'month' => 10, 'day' =>21, 'year' => 2009, 'weight' =>188, 'lean' =>},
	{ 'month' => 10, 'day' =>22, 'year' => 2009, 'weight' =>189, 'lean' =>},
	{ 'month' => 10, 'day' =>23, 'year' => 2009, 'weight' =>188.5, 'lean' =>},
	{ 'month' => 10, 'day' =>24, 'year' => 2009, 'weight' =>188.2, 'lean' =>},
	{ 'month' => 10, 'day' =>26, 'year' => 2009, 'weight' =>190.2, 'lean' =>},
	{ 'month' => 10, 'day' =>27, 'year' => 2009, 'weight' =>188.5, 'lean' =>},
	{ 'month' => 10, 'day' =>28, 'year' => 2009, 'weight' =>187, 'lean' =>},
	{ 'month' => 10, 'day' =>30, 'year' => 2009, 'weight' =>188, 'lean' =>},
	{ 'month' => 11, 'day' =>2, 'year' => 2009, 'weight' =>186, 'lean' =>},
	{ 'month' => 11, 'day' =>3, 'year' => 2009, 'weight' =>186.8, 'lean' =>},
	{ 'month' => 11, 'day' =>8, 'year' => 2009, 'weight' =>185, 'lean' =>},
	{ 'month' => 11, 'day' =>9, 'year' => 2009, 'weight' =>184, 'lean' =>},
	{ 'month' => 11, 'day' =>10, 'year' => 2009, 'weight' =>184, 'lean' =>},
	{ 'month' => 11, 'day' =>11, 'year' => 2009, 'weight' =>185.2, 'lean' =>},
	{ 'month' => 11, 'day' =>12, 'year' => 2009, 'weight' =>186.8, 'lean' =>},
	{ 'month' => 11, 'day' =>17, 'year' => 2009, 'weight' =>183.3, 'lean' =>},
	{ 'month' => 11, 'day' =>20, 'year' => 2009, 'weight' =>185, 'lean' =>},
	{ 'month' => 11, 'day' =>21, 'year' => 2009, 'weight' =>184, 'lean' =>},
	{ 'month' => 11, 'day' =>23, 'year' => 2009, 'weight' =>185, 'lean' =>},
	{ 'month' => 11, 'day' =>28, 'year' => 2009, 'weight' =>186, 'lean' =>},
	{ 'month' => 11, 'day' =>30, 'year' => 2009, 'weight' =>184.5, 'lean' =>},
	{ 'month' => 12, 'day' =>1, 'year' => 2009, 'weight' =>184.5, 'lean' =>},
	{ 'month' => 12, 'day' =>3, 'year' => 2009, 'weight' =>184, 'lean' =>},
	{ 'month' => 12, 'day' =>5, 'year' => 2009, 'weight' =>188.8, 'lean' =>},
	{ 'month' => 12, 'day' =>7, 'year' => 2009, 'weight' =>186, 'lean' =>},
	{ 'month' => 12, 'day' =>8, 'year' => 2009, 'weight' =>185, 'lean' =>},
	{ 'month' => 12, 'day' =>10, 'year' => 2009, 'weight' =>186.2, 'lean' =>},
	{ 'month' => 12, 'day' =>12, 'year' => 2009, 'weight' =>187, 'lean' =>},
	{ 'month' => 12, 'day' =>15, 'year' => 2009, 'weight' =>187, 'lean' =>},
	{ 'month' => 12, 'day' =>17, 'year' => 2009, 'weight' =>186, 'lean' =>},
	{ 'month' => 12, 'day' =>21, 'year' => 2009, 'weight' =>184.3, 'lean' =>},
	{ 'month' => 12, 'day' =>23, 'year' => 2009, 'weight' =>186.2, 'lean' =>},
	{ 'month' => 12, 'day' =>24, 'year' => 2009, 'weight' =>186.2, 'lean' =>},
	{ 'month' => 12, 'day' =>28, 'year' => 2009, 'weight' =>187.2, 'lean' =>},
	{ 'month' => 12, 'day' =>29, 'year' => 2009, 'weight' =>189, 'lean' =>},
	{ 'month' => 12, 'day' =>31, 'year' => 2009, 'weight' =>190, 'lean' =>},
	{ 'month' => 01, 'day' =>1, 'year' => 2010, 'weight' =>191.5, 'lean' =>},
	{ 'month' => 01, 'day' =>3, 'year' => 2010, 'weight' =>191.8, 'lean' =>},
	{ 'month' => 01, 'day' =>4, 'year' => 2010, 'weight' =>188, 'lean' =>},
	{ 'month' => 01, 'day' =>5, 'year' => 2010, 'weight' =>190, 'lean' =>},
	{ 'month' => 01, 'day' =>8, 'year' => 2010, 'weight' =>188, 'lean' =>},
	{ 'month' => 01, 'day' =>11, 'year' => 2010, 'weight' =>188.5, 'lean' =>},
	{ 'month' => 01, 'day' =>12, 'year' => 2010, 'weight' =>187, 'lean' =>},
	{ 'month' => 01, 'day' =>13, 'year' => 2010, 'weight' =>186.8, 'lean' =>},
	{ 'month' => 01, 'day' =>14, 'year' => 2010, 'weight' =>188, 'lean' =>},
	{ 'month' => 01, 'day' =>16, 'year' => 2010, 'weight' =>186, 'lean' =>},
	{ 'month' => 01, 'day' =>19, 'year' => 2010, 'weight' =>183.6, 'lean' =>143.8 },
	{ 'month' => 01, 'day' =>20, 'year' => 2010, 'weight' =>184.4, 'lean' =>144.02 },
	{ 'month' => 01, 'day' =>21, 'year' => 2010, 'weight' =>183, 'lean' =>142.92 },
);

unlink("/home/shadwickt/Desktop/rrd-test/new-weight.rrd");

my $rrd = RRDTool::OO->new(
                 file => "/home/shadwickt/Desktop/rrd-test/new-weight.rrd" );

my $start_date = new Class::Date {
	'year' => $entries[0]->{'year'},
	'month' => $entries[0]->{'month'},
	'day' => $entries[0]->{'day'},
};

$rrd->create(
	'start' => ($start_date->epoch)-1,
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

foreach my $entry(@entries){
	my $date = new Class::Date {
		'year' => $entry->{'year'},
		'month' => $entry->{'month'},
		'day' => $entry->{'day'},
	};
	print $date->epoch . ':' . $entry->{'weight'} . "\n";
	
	my $values;
	$values->{'weight'} = $entry->{'weight'};
	$values->{'lean'} = $entry->{'lean'} || 0;
	

	$rrd->update(
		'time' => $date->epoch,
		'values' => $values,
	);
}

