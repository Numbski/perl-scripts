#!/usr/bin/env perl

use strict;
use Net::Twitter;
use Scalar::Util 'blessed';
use Data::Dumper;
use XML::Twig;

my $username = 'numbski';
my $password = 'slipup77';

my @stylesheets = ('./css/thread.css');
my @javascripts = (
	'./js/mootools-1.2-core.js',
	'./js/mootools-1.2-more.js',
	'./js/threader.js',
);

my $nt = Net::Twitter->new(
	traits   => [qw/API::REST/],
	username => $username,
	password => $password

);
eval {
	my $statuses = $nt->friends_timeline(
		{ 
			#'since_id' => $high_water,
			'count' => 10,
		}
	);

	my $twig = XML::Twig->new(
		pretty_print => 'indented',
		keep_spaces => 1,
		empty_tags => 'html',
		comments => 'keep',
	);
	# Create the root <html> tag (element).
	my $html = XML::Twig::Elt->new('html');
	$twig->set_root($html);

	# Create the <head> tag (element) and paste it to <html>.
   	my $head = XML::Twig::Elt->new('head');
	$head->paste('first_child' => $html);

	# Do the same for body, only we make sure it's after <head>.
   	my $body = XML::Twig::Elt->new('body');
	$body->paste('last_child' => $html);

	# Set the page title.
   	my $title = XML::Twig::Elt->new('title');
   	$title->set_text("Scripted Threading Test");
	$title->paste('first_child' => $head);

	# Set the meta.
   	my $meta = XML::Twig::Elt->new('meta');
	$meta->set_att(
		'http-equiv' => 'Content-Type',
		'content' => 'text/html',
		'charset' => 'utf-8',
	);
	$meta->paste('after' => $title);

	# Process the stylesheets.
	foreach my $css(@stylesheets){
		my $link = XML::Twig::Elt->new('link');
		$link->set_att(
		'rel' => 'style',
		'href' => $css,
		'type' => 'text/css',
		'media' => 'screen',
		);
		$link->paste('last_child' => $head);
	}
	# Process the javascripts.
	foreach my $js(@javascripts){
		my $script = XML::Twig::Elt->new('script');
		$script->set_att(
		'type' => 'style',
		'src' => $js,
		);
		$script->paste('last_child' => $head);
	}

	# Parse the statuses we got back.
	foreach my $status ( @$statuses ) {
		if($status->{'in_reply_to_status_id'}){
			# This is already a reply, not a root.  We need to treat this differently!
		}
		else{
			my $thread = XML::Twig::Elt->new('div');
			$thread->set_att(
				'class' => 'thread',
				'threadID' => $status->{'id'},
			);
			my $comment = XML::Twig::Elt->new('div');
			$comment->set_att(
				'class' => 'comment',
				'indent' => 0,
				'commentID' => $status->{'id'},
			);
			
			my $avatar = XML::Twig::Elt->new('img');
			$avatar->set_att(
				'alt' => $status->{'user'}->{'name'},
				'src' => $status->{'user'}->{'profile_image_url'},
			);
			$comment->set_text($status->{'text'});
			$avatar->paste('first_child' => $comment);


			# Check for replies to this comment here.
			# Willc need to create a function so I can recursively
			# search for replies easily and quickly.

			$comment->paste($thread);
			$thread->paste('last_child' => $body);
		}
			
#		print "$status->{created_at} <$status->{user}{screen_name}> $status->{text}\n\n";
#		print Dumper $status;
#		print "\n";

	}
	print "Content-type: text/html\n\n";
	$twig->print;
	$twig->purge;
	exit;
};
if ( my $err = $@ ) {
	die $@ unless blessed $err && $err->isa('Net::Twitter::Error');

	warn "HTTP Response Code: ", $err->code, "\n",
	"HTTP Message......: ", $err->message, "\n",
	"Twitter error.....: ", $err->error, "\n";
}

