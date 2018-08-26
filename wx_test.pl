#!/usr/bin/env perl -w

use strict;

package NumbskiApp;
use base 'Wx::App';
use Wx ':everything';
use LWP::UserAgent;

sub OnInit {
	# I don't get when params are pushed into "this".
	my( $this ) = @_;
	my $frame = Wx::Frame->new(
		undef,			# Parent Window
		-1,			# Window ID
		'Downloader',		# Application Title
		wxDefaultPosition,	# position
		[200 , 100],		# size X, Y
		);

	# We're creating an array reference named TXT?
	$frame->{TXT} = Wx::TextCtrl->new($frame , -1, '' );
	$frame->Show( 1 );
	download( $frame, "http://cpan.org/modules/01modules.index.html" );
}

sub download {
        my( $frame, $from ) = @_;

        my $data = '';
        my $ua = LWP::UserAgent->new();
        my $content_size = $ua->head( $from )->headers()->header('content-length');
        my $pd = Wx::ProgressDialog->new( 'Downloading File', '', $content_size, $frame,
                                        wxPD_AUTO_HIDE | wxPD_APP_MODAL | wxPD_ELAPSED_TIME |
                                        wxPD_ESTIMATED_TIME | wxPD_REMAINING_TIME );
        $ua->get( $from, ':content_cb' => sub { $data.=$_[0]; $pd->Update( length($data) ) } );
        $frame->{TXT}->SetValue( sprintf "Downloaded %d bytes", length($data) );
        $pd->Destroy();
}

NumbskiApp->new()->MainLoop();
