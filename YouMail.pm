#!/usr/bin/env perl

package YouMail;

use Moose;
use LWP::UserAgent;

has 'phone_number' => (
    isa => 'Int',
    is => 'rw',
    default => '',
);
has 'pin' => (
    isa => 'Int',
    is => 'rw',
    default => '',
);
has 'cookie_jar' => (
   # isa => 'String',
    is => 'rw',
    default => "$ENV{'HOME'}/.cookies.txt",
);
has 'user_agent' => (
    is => 'rw',
);
has 'server_mailbox_data' => (
    is => 'rw',
);
has 'folders' => (
    is => 'rw',
);
has 'current_folder' => (
    is => 'rw',
    default => 'Inbox',
);

sub login {
    my $self = shift;
    croak("You must provide a phone number.") unless $self->phone_number;
    croak("You must provide a pin number.") unless $self->pin;

    $self->user_agent(LWP::UserAgent->new);
    $self->user_agent->cookie_jar(
            {
                'file' => "$ENV{HOME}/.cookies.txt"
             }
    );
    $self->user_agent->timeout(10);
    $self->user_agent->env_proxy;

    # Allow posts to redirect, as YouMail does this.
    push @{ $self->user_agent->requests_redirectable }, 'POST';

    # This is the most lightweight way I know of to get a cookie from YouMail.
    my $response = $self->user_agent->post('http://m.youmail.com/mobile/signin.do?m=300', {
        'userIdentifier' => $self->phone_number,
        'password' => $self->pin
    });

    if ($response->is_success) {
        # Todo: read the total messages comment in this response.
        #print $response->decoded_content;  # or whatever
    }
    else {
        croak($response->status_line);
    }
}

# Until I can figure out how to either get the full messageBox json dump from a
# direct call, this has to be used in order to know what folders we have to work
# with.  There has to be a better way...
sub get_initial_server_data {
    my $self = shift;
    my $response = $self->user_agent->post('http://www.youmail.com/youmail/vm/inbox/inbox.do');
    if ($response->is_success) {
        # Parse out the message list from the javascript embedded in the page.
#        print $response->decoded_content;  # or whatever
        use XML::Twig;
        my $twig = XML::Twig->new(
            pretty_print => 'indented',
            discard_spaces => 1,
            empty_tags=> 'normal',
            comments=> 'keep',
            twig_handlers => {
                        div => sub {
                            if(($_->{'att'}->{'id'}) && ($_->{'att'}->{'id'} eq 'mainContentPane')){
                                # Get the JavaScript
                                #$_->print;
                                my $script = $_->first_child('script');
                                $script = $script->trimmed_text;
                                
                                # Regex out YouMail's embedded JSON.
                                $script =~ /Youmail.vm.data = ({.*?})\;/;
                                croak("Failed to extract JSON from message listing!") unless $1;

                                my $messages_in_json = $1;
                                
                                # Once we get here, we really should parse out the json, store the folders in
                                # $self->folders, store the messages in $self->messages.
                                # Only JSON::DWIW handles YouMail's json properly.
                                # They take some liberties with quoting some of the name/value pairs,
                                # and even setting relaxed doesn't fix it. :(
                                use JSON::DWIW;
                                my $json = new JSON::DWIW;
                                my $data = $json->from_json($messages_in_json);

                                # Just cleaning up the folders and messages to have an index rather than
                                # just be anonymous hashes.
                                my $folders;
                                my $current_folder;
                                foreach my $folder( @{ $data->{'messageBox'}->{'folders'} } ){
                                        # Make a note of which folder we're looking at, so we put our
                                        # messages in the right one.
                                        if($folder->{'selected'}){
                                            $current_folder = $folder->{'folderKey'};
                                        }
                                        foreach my $key(keys %$folder){
                                            $folders->{ $folder->{'folderKey'} }->{$key} = $folder->{$key};
                                        }
                                }
 
                                my $messages;
                                foreach my $message( @{ $data->{'messageBox'}->{'messages'} } ){
                                        foreach my $key(keys %$message){
                                            $messages->{ $message->{'XID'} }->{$key} = $message->{$key};
                                        }
                                }
                                $folders->{$current_folder}->{'messages'} = $messages;

                                $self->folders( $folders );

#                                $self->messages( $messages );

                                #$self->server_mailbox_data( $messages_in_json );
                                #croak("Failed to interpret server mailbox data!") unless $self->server_mailbox_data;
                                croak("Failed to interpret server mailbox data!") unless $self->folders;
                            }
                            else{
                                #print("Nope, not the div I want - id: ".$_->{'att'}->{'id'}."\n") if $_->{'att'}->{'id'};
                            }
                        }
            },
        );
        # In case of debug, use soft tabs.
        $twig->set_indent("    ");
        
        $twig->safe_parse_html($response->decoded_content);

    }
    else {
        croak($response->status_line);
    }

}

sub update_message_list {
    # ONLY use this routine after having already done login and get_initial_server_data!
    # Must also realize to set the current folder, otherwise you'll always get the Inbox.
    my $self = shift;
    my $response = $self->user_agent->get('http://www.youmail.com/youmail/vm/inbox/inboxData.do?f='.$self->current_folder);
    if ($response->is_success) {
        use JSON::DWIW;
        my $json = JSON::DWIW->new;
        my $data = $json->from_json($response->decoded_content);
        return unless scalar( @{ $data->{'messages'} } );

        # Flush the existing messages hash for this folder, then
        # populate the hash with what we just pulled.
        $self->folders->{ $self->current_folder }->{'messages'} = undef;
        my $messages;
        foreach my $server_message( @{ $data->{'messages'} } ){
            foreach my $key(keys %$server_message){
                $messages->{ $server_message->{'XID'} }->{$key} = $server_message->{$key};
            }
        }
        $self->folders->{ $self->current_folder }->{'messages'} = $messages;
    }
    else{
        croak("update_message_list(): Failed to get updated listing for ".$self->current_folder.", the error was: ".$response->status_line);
    }
}

sub fetch_message_as_mp3 {
    my $self = shift;
    my $xid = shift;
    # Use the following URL to grab the mp3 data.
    # http://www.youmail.com/youmail/voicemail/getDataStream.do?id=14977312
    # Where 14977312 is the XID of the voicemail.
    
    # You'll have to use LWP::UserAgent to store the file to a temp directory.
    # We'll eventually want to store the message in a SQLite Database.
}

1