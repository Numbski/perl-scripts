#!/usr/bin/env perl
use Net::Akismet;

print "Running...\n";

my $akismet = Net::Akismet->new(
	KEY => '5e321be034e0',
        URL => 'http://www.numbski.com/',
) or die('Key verification failure!');

        my $verdict = $akismet->check(
                        USER_IP                         => '10.10.10.11',
#                        COMMENT_USER_AGENT      => 'Mozilla/5.0',
#                        COMMENT_CONTENT         => 'Run, Lola, Run, the spam will catch you!',
#                        COMMENT_AUTHOR          => 'dosser',
#                        COMMENT_AUTHOR_EMAIL    => 'dosser@subway.de',
#                        REFERRER                => 'http://lola.home/',
#USER_IP                 => '24.9.125.255',
 COMMENT_CONTENT         => "I'm still working on this module to make it a bit more intuitive.",
 COMMENT_AUTHOR          => 'Tony',
 COMMENT_AUTHOR_EMAIL     => '',
 COMMENT_AUTHOR_URL     => '',
 REFERRER                => 'http://www.numbski.com/hacks/masterlock.html',
 COMMENT_USER_AGENT		=> 'blosxom-writebackplus/3.01',
 PERMALINK		=> 'http://www.numbski.com/hacks/masterlock.html',

                ) or die('Is the server here?');

        if ('true' eq $verdict) {

                print "I found spam. I am a spam-founder!\n";
        }
	elsif('false' eq $verdict){
		print "This is not spam.\n";
	}
	else{
		print "An error occurred: Verdict is $verdict\n";
	}
