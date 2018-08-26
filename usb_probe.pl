#!/usr/bin/env perl

use Device::USB;

my $usb = Device::USB->new();

my $busses = $usb->find_busses;
my $devices = $usb->find_devices;

#print "Probing busses\n";
#my @bus = $usb->list_busses;

print "Probing devices\n";
my @dev = $usb->list_devices;

#print ref($bus)."\n";
#print ref($dev)."\n";



#printf "Device: %04X:%04X\n", $dev->idVendor(), $dev->idProduct();
#$dev->open();
#print "Manufactured by ", $dev->manufacturer(), "\n",
#          " Product: ", $dev->product(), "\n";

