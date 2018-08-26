#!/usr/bin/env perl
use strict;

# Gleaned from:
# http://perldoc.perl.org/threads.html

my $can_use_threads = eval 'use threads; 1';
unless ($can_use_threads) {
  die("This script was written specifically for perl with threads enabled.  That means perl must be 5.8 or better, and be compiled to support threads.");
}
else {
  use threads;
  
  print "Starting a thread.\n";
  my $first_thread = threads->create(
    sub{
      print "I am a thread.  w00t!\n";
	}
  );

  print "It's worth noting that I haven't actually joined my thread yet.  Joining now.\n";

  $first_thread->join();
  
  print "I could have done that as a single, full object/method too.\n";
  
  my $second_thread = threads->create(
    sub{
      print "I am a different thread.  w00t!\n";
	}
  )->join(); 

  # Check thread's state
  if ($first_thread->is_running()) {
  sleep(1);
  }
  if ($first_thread->is_joinable()) {
    $first_thread->join();
  }

 # Send a signal to a thread
 $first_thread->kill('SIGUSR1');

 # Exit a thread
 threads->exit();
}
