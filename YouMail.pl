#!/usr/bin/env perl

use strict;
#use warnings;
use YouMail;

my $youmail = YouMail->new(
            'phone_number' => '3142211473',
            'pin' => '4648'
                           );

print "Logging in...\n";
# So I stop hammering YouMail for a while...
$youmail->login;
print "Fetching update...\n";
# To get a listing of messages is a known folder name, starting from a specific id number.
#my $response = $youmail->user_agent->get('http://www.youmail.com/youmail/vm/inbox/inboxData.do?noc=1231177861046&f=Inbox&id=0');
#my $response = $youmail->user_agent->get('http://www.youmail.com/youmail/vm/inbox/inboxData.do');

#    if ($response->is_success) {
        # Todo: read the total messages comment in this response.
        #print $response->decoded_content;  # or whatever
#    }
#    else {
#        die($response->status_line);
#    }

$youmail->get_initial_server_data;
die("Nothing gathered from the server?") unless $youmail->folders;


#use JSON::DWIW;
#my $json = new JSON::DWIW;
#print $youmail->server_mailbox_data;
#exit;
#my $data = $json->from_json($youmail->server_mailbox_data);
#print $data->{'messageBox'}->{'mbName'}."\n";
#print "New Messages: ".$data->{'messageBox'}->{'newMessageCount'}."\n";
#print "Folders:\n";


my $current_folder;
foreach my $folder(reverse sort { $youmail->folders->{$a}->{'selected'} cmp $youmail->folders->{$b}->{'selected'} } keys %{$youmail->folders} ){
    $current_folder = $folder if( $youmail->folders->{$folder}->{'selected'} );
    print $youmail->folders->{$folder}->{'label'};
    print ' ('.$youmail->folders->{$folder}->{'count'}.')' if $youmail->folders->{$folder}->{'count'};
    print "\n";
}

print "\nMessages (X denotes that you've already listened to it.):\n";
#foreach my $message(reverse sort keys %{$youmail->messages}){
foreach my $message( reverse sort keys %{ $youmail->folders->{$current_folder}->{'messages'} } ){
    unless( $youmail->folders->{$current_folder}->{'messages'}->{$message}->{'isNew'} ){
        print "X ";
    }
    else{
        print "  ";
    }
#    print $youmail->messages->{$message}->{'from'}." ".$youmail->messages->{$message}->{'rawFrom'}." ".$youmail->messages->{$message}->{'created'}." ".$youmail->messages->{$message}->{'length'}."\n";
    printf (
            "%-35s %-14s %-17s %-6s\n",
            $youmail->folders->{$current_folder}->{'messages'}->{$message}->{'from'},
            $youmail->folders->{$current_folder}->{'messages'}->{$message}->{'rawFrom'},
            $youmail->folders->{$current_folder}->{'messages'}->{$message}->{'created'},
            $youmail->folders->{$current_folder}->{'messages'}->{$message}->{'length'}
    );
}