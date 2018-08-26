#/usr/bin/env perl

use strict;
use warnings;

use Device::USB;


use constant BUTTON_C => 0x02;
use constant BUTTON_B => 0x04;
use constant BUTTON_A => 0x08;
use constant BUTTON_UP => 0x20;
use constant BUTTON_DOWN => 0x40;
use constant BUTTON_LEFT => 0x60;
use constant BUTTON_RIGHT => 0x80;

my $usb = Device::USB->new();
my $dev = $usb->find_device(0x0b9a,0x016a);
die("No gun was found!") unless $dev;

#printf "Device: %04X:%04X\n", $dev->idVendor(), $dev->idProduct();

# Get our handle for reading from the device.
$dev->open() || die "$!";

#print "Manufactured by ", $dev->manufacturer(), "\n",
#          " Product: ", $dev->product(), "\n";

# Not sure why we set what's already hardcoded, but hey...
$dev->set_configuration(1);

# GunCon2 only has 1 interface, "#0".
die("Failed to claim this GunCon2's interface.  Exiting.") if ($dev->claim_interface(0) < 0);

while($dev){
	my $controls = poll_gun();
#my $xaxis = sprintf( "%0016b ", ord($xaxis) );
#my $yaxis = sprintf( "%0016b ", ord($yaxis) );
#$yaxis = sprintf( "%04d ", ord($yaxis) );

	print "Buttons: $controls->{'buttons'}\n";
	print "Triggers: $controls->{'triggers'}\n";
	print "X-Axis: $controls->{'xaxis'}\n";
	print "Y-Axis: $controls->{'yaxis'}\n";
	print "Pressed: ";
	foreach my $key(keys %$controls){
		if($controls->{$key} == 1){
			print "$key ";
		}
	}
	sleep(1);
	system("clear");
}


sub poll_gun{
	# Set up our control hash ref
	my $controls;


	my $ep = 0x81;
	my $bytes = 1;
	my $size = 6;
	my $timeout = 6;
	my $output = $dev->interrupt_read(0x81,$bytes,$size,$timeout);

	warn("Short read from gun.") unless ($output == 6);

	$bytes =~/(.)(.)(.)(.)(.)(.)/;

	my $xaxis1 = sprintf("%1d ", ord($3) );
	my $xaxis2 = sprintf("%1d ", ord($4) );
	my $yaxis1 = sprintf("%1d ", ord($5) );
	my $yaxis2 = sprintf("%1d ", ord($6) );

	# Flip the button bytes for easier reading.

	$controls->{'xaxis'} = "$4$3";
	$controls->{'yaxis'} = "$6$5";
	$controls->{'buttons'} = sprintf("%08b ", ord(~$1) );
	$controls->{'triggers'} = sprintf("%08b ", ord(~$2) );

	if( (BUTTON_C & $controls->{'buttons'}) == BUTTON_C){
		$controls->{'button_c'} = 1;
	}
	else{
		$controls->{'button_c'} = 0;
	}
	if( (BUTTON_B & $controls->{'buttons'}) == BUTTON_B){
		$controls->{'button_b'} = 1;
	}
	else{
		$controls->{'button_b'} = 0;
	}
	if( (BUTTON_A & $controls->{'buttons'}) == BUTTON_A){
		$controls->{'button_a'} = 1;
	}
	else{
		$controls->{'button_a'} = 0;
	}
	if( (BUTTON_UP & $controls->{'buttons'}) == BUTTON_UP){
		$controls->{'button_up'} = 1;
	}
	else{
		$controls->{'button_up'} = 0;
	}
	if( (BUTTON_DOWN & $controls->{'buttons'}) == BUTTON_DOWN){
		$controls->{'button_down'} = 1;
	}
	else{
		$controls->{'button_down'} = 0;
	}
	if( (BUTTON_LEFT & $controls->{'buttons'}) == BUTTON_LEFT){
		$controls->{'button_left'} = 1;
	}
	else{
		$controls->{'button_left'} = 0;
	}
	if( (BUTTON_RIGHT & $controls->{'buttons'}) == BUTTON_RIGHT){
		$controls->{'button_right'} = 1;
	}
	else{
		$controls->{'button_right'} = 0;
	}

	return($controls);
}
