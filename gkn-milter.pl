#!/usr/bin/env perl
use strict;
use Sendmail::PMilter qw(
        :all
);
use Sys::Syslog;
use Proc::Daemon;
  use Proc::PidUtil qw(
        if_run_exit
        is_running
        make_pidfile
        zap_pidfile
        get_script_name
        :all
  );

use constant DEBUGGING => 1;

# Blocking reason codes:
# Reason 1: Sender and Recipient are the same.

my $milter = new Sendmail::PMilter;

my $milter_callbacks = {
    'helo' => \&helo_callback,
    'envfrom' => \&envfrom_callback,
    'envrcpt' => \&envrcpt_callback,
};


sub helo_callback{
    my $ctx = shift;
    my $helo = shift;
    
    # Just store the helo and move on.
    # I'm not using it right now, but at some point I might choose
    # to keep a database log of which helo's are spammers.
    my $private = {
        'helo' => $helo
    };

    $ctx->setpriv($private);
    return(SMFIS_CONTINUE);
}
# This gets run when the sender identifies themselves with an e-mail address.
# This is the first things that comes after the ehlo (or helo).
sub envfrom_callback {
    my $ctx = shift;
    my $sender = shift;
    syslog("info","Entered envfrom callback.") if DEBUGGING;

    my $private = $ctx->getpriv();

    # Clean up the sender address
    # Remove any newlines or whitespace.
    chomp($sender);
    $sender =~ s/\s//g;
    
    # Make sure it is 100% lowercased.
    $sender = lc($sender);

    syslog("info","Got the sender: $sender") if DEBUGGING;
    
    $private->{'sender'} = $sender;

    # Make a priveleged reference to the sender scalar.
    # This way it will get passed to the envrcpt callback.
    $ctx->setpriv($private);

    syslog("info","Assigned the sender to private data.  Continuing.") if DEBUGGING;

    # Return the continue code so that the MTA will keep going.
    return(SMFIS_CONTINUE);
}

# Gets called after the sender admits where the message is coming from.
# We should have the sender's address set in $ctx private data, so we
# can compare at this point.
sub envrcpt_callback {
    my $ctx = shift;
    my $recipient = shift;
    
    my $private = $ctx->getpriv();

    syslog("info","Entered envrcpt callback with sender $private->{'sender'}") if DEBUGGING;

    # Clean up our recipient.
    # Remove any newlines or whitespace.
    chomp($recipient);
    $recipient =~ s/\s//g;
    
    # Make sure it is 100% lowercased.
    $recipient = lc($recipient);
    syslog("info","Recipient is: $recipient") if DEBUGGING;


    # Compare the sender and recipient.  Reject if they are the same.
    # Remember that we are de-referencing the sender scalar, so 2 $'s are
    # required.
    if($recipient eq $private->{'sender'}){

        syslog("warning","Sender and recipient are the same.  KILL! KILL! KILL!!!") if DEBUGGING;

        # Purge the private data.
        $ctx->setpriv();

        # Set a proper reply and reject the message before the body even comes through.
        $ctx->setreply('550','5.7.1',"Blocked by GKN Milter, reason 1");
        return(SMFIS_REJECT);        
    }
    else{
        syslog("info","Sender and recipient are different. Carry on then.") if DEBUGGING;

        return(SMFIS_CONTINUE);
    }


}

  BEGIN:
  {
        my $unix_socket = shift(@ARGV);
        die("You must specify the path to where you want the socket for this milter to exist! - eg /var/spool/postfix/gknmilter.sock") unless $unix_socket;

        # Routine hardly makes sense...
        # If we have a pid file that contains a currently-running process, exit.
        # If either the file isn't there, or the pid isn't running, return true.
        # Then we will try to zap the pid file if it's there.  Oi.
        if( if_run_exit('/var/run',"Milter is already running.  Exiting.") ){
            zap_pidfile('/var/run'); # We don't care if this succeeds.  The file might not even exist.
        }

        print "Opening syslog statement.\n" if DEBUGGING;
        # Set up our initial syslogging parameters.
        openlog('gknmilter','ndelay,nwait,pid','mail');
        syslog("info","Attempting to startup.");

        if(-d $unix_socket){ # If they tried to pass us a directory...
            syslog("error","The path specified, $unix_socket, is a directory.  Exiting.");
            die("The sock path, $unix_socket is a directory.  Please correct this or choose a different socket path.")
        }
        # If by chance the socket path exists, we'll try to clean it up
        # and continue anyway.
        if(-e $unix_socket){
            print "The socket path specified already exists.  Attempting to clean up and continue...\n";
            syslog("warning","The socket path specified already exists.  Attempting to clean up and continue.");

            unless( unlink($unix_socket) ){
                syslog("error","Failed to remove $unix_socket.  We are running as $>>, maybe a permissions problem?  Exiting.");
                die("Failed to remove $unix_socket.  We are running as $>>, maybe a permissions problem?");
            }
            else{
                syslog("info","Cleanup of $unix_socket succeeded.  Continuing.");
                print "Succeeded in cleanup.  Proceeding!\n";
            }
        }

        syslog("info","Setting up socket at $unix_socket");
        print "Setting up socket.\n" if DEBUGGING;
        
        # This should create a new socket.
        # /dev/null is specified as the location to look for sendmail.cf,
        # as under Postfix it doesn't exist.
        $milter->setconn("local:$unix_socket");
        
        syslog("info","Socket created, attempting to register callbacks.");
        print "Socket created, attempting to register callbacks.\n" if DEBUGGING;

        print "Attempting to drop permissions to user postfix.\n" if DEBUGGING;

        my $postfix_uid = getpwnam('postfix');
        syslog("error",'Failed to determine the uid for user "postfix".  Exiting.') unless $postfix_uid;
        die("Failed to determine postfix's uid.  Does the user not exist?") unless $postfix_uid;
        my $postfix_gid = getgrnam('postfix');
        syslog("error",'Failed to determine the gid for group "postfix".  Exiting.') unless $postfix_gid;
        die("Failed to determine postfix's gid.  Does the group not exist?") unless $postfix_gid;

        syslog("info","Changing ownership of $unix_socket to postfix:postfix");
        chown($postfix_uid,$postfix_gid,$unix_socket);

        # This should register our new callbacks.
        $milter->register("gknmilter",$milter_callbacks, SMFI_CURR_ACTS);

        syslog("info","Callbacks registered.  Attempting to drop permissions.");
        print "Callbacks registered.  Attempting to drop permissions.\n" if DEBUGGING;

        # Set our effective UID (EUID) to $postfix_uid.
        $> = $postfix_uid;
        syslog("error","Failed to drop permissions to postfix user with uid $postfix_uid") unless ($> == $postfix_uid);
        die("Failed to drop permissions to postfix user with uid $postfix_uid") unless ($> == $postfix_uid);
        print "Successfully dropped permissions to user postfix with uid $postfix_uid.\n" if DEBUGGING;

        # Set our effective GID (EGID) to $postfix_gid.
        # This is not an error.  Apparently to force a single gid, you have to give
        # the gid, then give it again in a space-separated list to force setgroup() to use just one.
        $) = "$postfix_gid $postfix_gid";

        syslog("warning","Failed to drop permissions to postfix group with gid $postfix_gid") unless ( $) eq "$postfix_gid $postfix_gid" );
        warn("Failed to drop permissions to postfix group with gid $postfix_gid.  Our EGID is $).
             This is not fatal, as not all systems support it.  Continuing.") unless ( $) eq "$postfix_gid $postfix_gid");
        print "Successfully dropped permissions to group postfix with gid $postfix_gid.\n"
            if ( DEBUGGING && ( $) eq "$postfix_gid $postfix_gid") );

        print "Entering main loop to daemonize.\n" if DEBUGGING;
        syslog("info","Entering main loop to daemonize.");
        # And this loops us indefinitely, creating a daemon.
        Proc::Daemon::Init;
        
        # Create a pid file for later killings.
        my $me = get_script_name(); 
        die("Failed to create pid file /var/run/$me.pid") unless make_pidfile('/var/run/$me.pid',$$);

        $milter->main();

        # Never reaches here, callbacks are called from Milter.
  }