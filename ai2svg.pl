#!/usr/bin/perl

# ill2svg.pl: Translation script from Adobe Illustrator to SVG.
#
# Copyright (C) 2000 Eazel, Inc.
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.
# 
# Author: Raph Levien <raph@artofcode.com>

# convert an illustrator file (on stdin) to svg (on stdout)

# This script is tested against Adobe Illustrator 5 format files. However,
# it should be relatively easy to adapt to other Illustrator versions.

# For documentation on the Illustrator file format, please see Adobe
# Technical Note #5007, Adobe Illustrator File Format Specification
# Version 7.0.
# http://partners.adobe.com/asn/developer/PDFS/TN/5007.AI7FileFormat.pdf

$fillpaint = "#000";
$strokewidth = 1;
$linejoin = "miter";
$linecap = "butt";
$miterlimit = 8;
$dasharray = "none";
$dashoffset = 0;
$_pola = 0;

sub cmyk_to_paint {
    my ($c, $m, $y, $k) = @_;
    my ($r, $g, $b);

#    print "$c $m $y $k\n";
    $r = 1 - ($k + $c);
    if ($r < 0) { $r = 0; }
    $g = 1 - ($k + $m);
    if ($g < 0) { $g = 0; }
    $b = 1 - ($k + $y);
    if ($b < 0) { $b = 0; }
    return rgb_to_paint ($r, $g, $b);
}

sub rgb_to_paint {
    my ($r, $g, $b) = @_;

    return sprintf ("#%02x%02x%02x", 255 * $r, 255 * $g, 255 * $b);
}

sub nice_float {
    my ($x) = @_;

    my $result = sprintf ("%.3f", $x);
    $result =~ s/0*$//;
    $result =~ s/\.$//;
    return $result;
}

sub xform_xy {
    my ($x, $y) = @_;
    my @result = ();

    for my $i (0..$#_) {
	if ($i & 1) {
	    push @result, $y1 - $_[$i];
	} else {
	    push @result, $_[$i] - $x0;
	}
    }
    return join ' ', map { nice_float ($_) } @result;
}

sub fill_style {
    return "fill: $fillpaint";
};

sub stroke_style {
    my $result = "stroke: $strokepaint";
    if ($strokewidth != 1) {
	$result .= "; stroke-width: $strokewidth";
    }
    if ($linecap ne 'butt') {
	$result .= "; stroke-linecap: $linecap";
    }
    if ($linejoin ne 'miter') {
	$result .= "; stroke-linejoin: $linejoin";
    }
    if ($miterlimit != 8) {
	$result .= "; stroke-miterlimit: $miterlimit";
    }
    if ($dasharray ne 'none') {
	$result .= "; stroke-dasharray: $dasharray";
	if ($dashoffset != 0) {
	$result .= "; stroke-dashoffset: $dashoffset";
	}
    }
    return $result;
};

sub smash_name {
    my ($name) = @_;

    $name =~ s/\W+/\_/g;
    return $name;
}

# A tokenizer breaking PostScript into tokens

# @tokens = ps_token ($line);
# Breaks $line into tokens, returning the list in @tokens.
# Note: strings lose quoting internally, but can still be distinguished
# by the surrounding '(' and ')'.
sub ps_tokenize {
    my ($line) = @_;
    my @result;

    chomp $line;
    $line =~ s/\%.*$//; # remove comment
    while (length ($line) > 0) {
	if ($line =~ /^([^\s\%\(\[\]]*)([\s\%\(\[\]])(.*)$/) {
	    if (length ($1) > 0) {
		push @result, $1;
	    }
	    if ($2 eq '%') {
		$line = '';
	    } elsif ($2 eq '(') {
		my $str = '';
		my $len = length ($line);
		my $i;
		my $nest = 0;

		for ($i = 0; $i < $len; $i++) {
		    my $c = substr ($line, $i, 1);
		    if ($c eq '\\') {
			$str .= substr ($line, $i + 1, 1);
			$i++;
		    } else {
			$str .= $c;
			if ($c eq '(') {
			    $nest++;
			} elsif ($c eq ')') {
			    $nest--;
			    last if $nest == 0;
			}
		    }
		}
		push @result, $str;
		$line = substr ($line, $i + 1);
	    } elsif ($2 eq '[' || $2 eq ']') {
		push @result, $2;
		$line = $3;
	    } else {
		$line = $3;
	    }
	} else {
	    push @result, $line;
	    $line = '';
	}
    }
    return @result;
}

# A really naive "interpreter" for PostScript

sub ps_close_array {
    for (my $i = length @ps_stack - 1; $i >= 0; $i--) {
	if ($ps_stack[$i] eq '[') {
	    my @array_contents = splice (@ps_stack, $i + 1);
	    pop (@ps_stack);
	    push @ps_stack, \@array_contents;
	}
    }
}

sub set_style {
    my ($new_style) = @_;
    if (defined $style) {
	if ($style eq $new_style) { return; }
	$layer_contents .= "  </g>\n";
    }
    $style = $new_style;
    $layer_contents .= "  <g style=\"$style\">\n";
};

sub end_style {
    if (defined $style) {
	if ($style eq $new_style) { return; }
	$layer_contents .= "  </g>\n";
	undef $style;
    }
};

sub path_new {
    $path = '';
    $path_closable = 0;
};

sub path_lineto {
    my ($x, $y) = @_;
    $path .= 'L'.xform_xy($x, $y);
    $path_closable = 1;
}

sub path_curveto {
    my ($x1, $y1, $x2, $y2, $x3, $y3) = @_;
    $path .= 'C'.xform_xy($x1, $y1, $x2, $y2, $x3, $y3);
    $path_closable = 1;
};

sub path_moveto {
    my ($x, $y) = @_;
    $path .= 'M'.xform_xy($x, $y);
    $path_closable = 0;
}

sub path_close {
    if ($path_closable) {
	$path .= 'z';
	$path_closable = 0;
    }
};

sub apply_affine {
    my ($a, $b, $c, $d, $tx, $ty, $x, $y) = @_;

    return ($a * $x + $b * $y + $tx,
	    $c * $x + $d * $y + $ty);
}

sub invert_affine {
    my ($a, $b, $c, $d, $tx, $ty) = @_;
    my $r_det = 1 / ($a * $d - $b * $c);
    ($a, $b, $c, $d) = ($d * $r_det, -$b * $r_det, -$c * $r_det, $d * $r_det);
    return ($a, $b, $c, $d, -($tx * $a + $ty * $c), -($tx * $b + $ty * $d));
}

sub exec_Lb {
    splice (@ps_stack, -10);
    # I believe that there is some stuff having to do with clipping here.
}

sub exec_LB {
    # I believe that there is some stuff having to do with clipping here.
}

sub exec_A {
    pop (@ps_stack);
}

sub exec_u {
}

sub exec_U {
}

sub exec_O {
    pop (@ps_stack);
    # Overprinting foo
}

sub exec_R {
    pop (@ps_stack);
    # Overprinting foo
}

sub exec_Ar {
    pop (@ps_stack);
    # Sets flatness; we ignore it here
}

sub exec_d {
    my ($darray, $doffset) = splice (@ps_stack, -2);
    if (@$darray) {
	$dasharray = join ' ', @$darray;
    } else {
	$dasharray = 'none';
    }
    $dashoffset = $doffset;
}

sub exec_D {
    pop (@ps_stack);
}

sub exec_Ln {
    my ($name) = pop (@ps_stack);
    $layer_name = substr ($name, 1, -1);
}

sub exec_m {
    my ($x, $y) = splice (@ps_stack, -2);
    path_moveto ($x, $y);
    $cpx = $x;
    $cpy = $y;
}

sub exec_l {
    my ($x, $y) = splice (@ps_stack, -2);
    path_lineto ($x, $y);
    $cpx = $x;
    $cpy = $y;
}

sub exec_L {
    exec_l ();
}

sub exec_v {
    my ($x2, $y2, $x3, $y3) = splice (@ps_stack, -4);
    path_curveto ($cpx, $cpy, $x2, $y2, $x3, $y3);
    $cpx = $x3;
    $cpy = $y3;
}

sub exec_V {
    exec_v ();
}

sub exec_y {
    my ($x1, $y1, $x3, $y3) = splice (@ps_stack, -4);
    path_curveto ($x1, $y1, $x3, $y3, $x3, $y3);
    $cpx = $x3;
    $cpy = $y3;
}

sub exec_Y {
    exec_y ();
}

sub exec_c {
    my ($x1, $y1, $x2, $y2, $x3, $y3) = splice (@ps_stack, -6);
    path_curveto ($x1, $y1, $x2, $y2, $x3, $y3);
    $cpx = $x3;
    $cpy = $y3;
}

sub exec_C {
    exec_c ();
}

sub exec_h {
    path_close ();
}

sub exec_j {
    $linejoin = ('miter', 'round', 'bevel')[pop (@ps_stack)];
}

sub exec_J {
    $linecap = ('butt', 'round', 'square')[pop (@ps_stack)];
}

sub exec_M {
    $miterlimit = pop (@ps_stack);
}

sub exec_w {
    $strokewidth = pop (@ps_stack);
}

sub render_path {
    if ($pola == 0) {
	$layer_contents .= "   <path d=\"$path\"/>\n";
	path_new ();
    }
}

sub exec_B {
    set_style (fill_style()."; ".stroke_style());
    render_path ();
}

sub exec_b {
    path_close ();
    exec_B ();
}

sub exec_F {
    set_style (fill_style());
    render_path ();
}

sub exec_f {
    path_close ();
    exec_F ();
}

sub exec_S {
    set_style ("fill:none; ".stroke_style());
    render_path ();
}

sub exec_s {
    path_close ();
    exec_S ();
}

sub exec_k {
    $fillpaint = cmyk_to_paint (splice (@ps_stack, -4));
}

sub exec_K {
    $strokepaint = cmyk_to_paint (splice (@ps_stack, -4));
}

sub exec_x {
    my ($c, $m, $y, $k, $colorname, $dummy) = splice (@ps_stack, -6);
    $fillpaint = cmyk_to_paint ($c, $m, $y, $k);
}

sub exec_X {
    my ($c, $m, $y, $k, $colorname, $dummy) = splice (@ps_stack, -6);
    $strokepaint = cmyk_to_paint ($c, $m, $y, $k);
}

# Xa and XA are not documented in the Illustrator 7 spec, but appear in
# files generated by Illustrator 9's ai7 export filter.
sub exec_Xa {
    my ($r, $g, $b) = splice (@ps_stack, -3);
    $fillpaint = rgb_to_paint ($r, $g, $b);
}

sub exec_XA {
    my ($r, $g, $b) = splice (@ps_stack, -3);
    $strokepaint = rgb_to_paint ($r, $g, $b);
}

sub exec_XR {
    # todo: even/odd rule
    pop (@ps_stack);
}

sub exec_g {
    $fillpaint = cmyk_to_paint (0, 0, 0, 1 - pop (@ps_stack));
}

sub exec_G {
    $strokepaint = cmyk_to_paint (0, 0, 0, 1 - pop (@ps_stack));
}

sub execstar_u {
    $pola++;
}

sub execstar_U {
    $pola--;
    if ($pola == 0) {
	render_path ();
    }
}

# Gradients

sub exec_Bd {
    my ($name, $type, $nColors) = splice (@ps_stack, -3);
    $gradient_name = substr ($name, 1, -1);
    $gradient_type = $type;
    $gradient_nColors = $nColors;
}

sub exec_BD {
    my $color;
    my @stops;
    my @rampPoints;

    my $last_rp = -1;
    $stops = '';
    for (my $i = 0; $i < $gradient_nColors; $i++) {
	my ($colorStyle, $midPoint, $rampPoint) = splice (@ps_stack, -3);

	# issue: midPoint is currently ignored.

	my $n_colorSpec = (1, 4, 7, 6, 10)[$colorStyle];
	my @colorSpec = splice (@ps_stack, -$n_colorSpec);
	if ($colorStyle == 0) {
	    $color = cmyk_to_paint (0, 0, 0, 1 - $colorSpec[0]);
	} elsif ($colorStyle == 1) {
	    $color = cmyk_to_paint (@colorSpec);
	} elsif ($colorStyle == 2) {
	    $color = rgb_to_paint (@colorSpec[4..6]);
	} elsif ($colorStyle == 3) {
	    $color = cmyk_to_paint (@colorSpec[0..3]);
	} else {
	    $color = "blue";
	}
	unshift @rampPoints, $rampPoint;
	unshift @stops, "   <stop offset=\"$rampPoint\%\" style=\"stop-color:$color\"/>\n";
    }

    # Note: the spec shows gradient stops arranged with ascending
    # rampPoints in the file. Adobe Illustrator files have them
    # descending. CorelDraw 9 export has them ascending. Note that
    # the order on the stack is the reverse as the order in the file,
    # thanks to reverse polish notation. Here, we reverse them if
    # needed to put them in ascending order.
    if ($rampPoints[0] > $rampPoints[@rampPoints - 1]) {
	@stops = reverse @stops;
    }

    $gradient_type{$gradient_name} =
	('linearGradient', 'radialGradient')[$gradient_type];
    $gradient_stops{$gradient_name} = join ' ', @stops;
    $gradient_instances{$gradient_name} = [];
    @ps_stack = 0;
}

# Gradient instances

sub exec_Bb {
}

sub exec_Bg {
    my ($flag, $name, $xOrigin, $yOrigin, $angle, $length, $a, $b, $c, $d,
	$tx, $ty) = splice (@ps_stack, -12);
    my $instance;

    $name = substr ($name, 1, -1);
    $angle = $angle * 3.14159265358979323 / 180;
    my $type = $gradient_type{$name};
    my $instance_ix = @{$gradient_instances{$name}} + 1;
    my $instance_name = smash_name ($name)."__".$instance_ix;
    $instance = "  <".$type." id=\"$instance_name\"\n";
    if ($gradient_type{$name} eq 'linearGradient') {
	my $x1 = $xOrigin;
	my $y1 = $yOrigin;
	my $x2 = $x1 + $length * cos ($angle);
	my $y2 = $y1 + $length * sin ($angle);
	my $x0 = -4014;
	my $y0 = 4716;
	my @aff2 = ($a, $b, $c, $d,
		    $tx + $x0 * (1 - $a) - $y0 * $b,
		    -$ty - $x0 * $c + $y0 * (1 - $d));
	($x1, $y1) = split / /,	xform_xy (apply_affine (@aff2, $x1, $y1));
	($x2, $y2) = split / /,	xform_xy (apply_affine (@aff2, $x2, $y2));

	# issues: does not handle skewing of gradient

	$instance .= "        x1=\"$x1\" y1=\"$y1\" x2=\"$x2\" y2=\"$y2\"\n";
    } elsif ($gradient_type{$name} eq 'radialGradient') {
	my $x1 = $xOrigin;
	my $y1 = $yOrigin;
	my $x0 = -4014;
	my $y0 = 4716;
	my @aff2 = ($a, $b, $c, $d,
		    $tx + $x0 * (1 - $a) - $y0 * $b,
		    -$ty - $x0 * $c + $y0 * (1 - $d));
	$r *= sqrt ($a * $d - $b * $c);

	($x1, $y1) = split / /,	xform_xy (apply_affine (@aff2, $x1, $y1));
	# issues: does not handle anamorphic distortion; no highlight
	# (ie, need to implement Bh operator).

	$instance .= "        cx=\"$x1\" cy=\"$y1\" r=\"$length\" fx=\"$x1\" fy=\"$y1\"\n";
    }
#    $instance .= "        gradientTransform=\"matrix($a $b $c $d $tx $tx)\"\n";
    $instance .= "        >\n";
    $instance .= $gradient_stops{$name};
    $instance .= "  </$type>\n";
    push @{$gradient_instances{$name}}, $instance;
    $fillpaint = "url(#$instance_name)";
}

sub exec_BB {
}

sub ps_exec {
    my ($tok) = @_;
    if ($tok =~ /^[\(\-\d\[]/) {
	push @ps_stack, $tok;
    } elsif ($tok eq ']') {
	ps_close_array ();
    } else {
	my $subname;
	if ($tok =~ /^\*(.*)$/) {
	    $subname = "execstar_$1";
	} else {
	    $subname = "exec_$tok";
	}
	if (defined &{$main::{$subname}}) {
	    &{$main::{$subname}};
	} else {
	    $layer_contents .= "   <!-- ".join (' ', @ps_stack, $tok)." -->\n";
	    @ps_stack = ();
	}
    }
}

$handler = \&handle_begin;

# Handlers for various sections of the Illustrator input file

sub handle_begin {
    if (/^\%\!PS/) { $handler = \&handle_header; }
    else { die "File does not start with PostScript header!\n"; }
}

sub handle_header {
    if (/^\%\%EndComments/) {
	if ($header{"BoundingBox"} =~ /(\d+) (\d+) (\d+) (\d+)/) {
	    $x0 = $1; $y0 = $2; $x1 = $3; $y1 = $4;
	} else {
	    $x0 = 0; $y0 = 0; $x1 = 8.5 * 72; $y1 = 11 * 72;
	}
	$handler = \&handle_wait_setup;
    }
    elsif (/^\%\%(\w+):\s+(.*)$/) { $header{$1} = $2; }
    elsif (/^\%(AI\w+):\s+(.*)$/) { $ai{$1} = $2; }
}

sub handle_wait_setup {
    if (/^\%\%BeginSetup/) { $handler = \&handle_setup; }
}

sub handle_setup {
    if (/\%AI\d_BeginGradient/) {
	$handler = \&handle_gradient;
    } elsif (/\%\%EndSetup/) { $handler = \&handle_wait_layer; }
}

sub handle_gradient {
    if (/\%AI\d_EndGradient/) {
#	print $layer_contents;
	$handler = \&handle_setup;
    } else {
	my @tokens = ps_tokenize ($_);
	foreach my $tok (@tokens) {
	    ps_exec ($tok);
	}
    }
}

sub handle_wait_layer {
    if (/\%AI\d_BeginLayer/) {
	$handler = \&handle_layer;
	$layer_num++;
	$layer_name = "layer$layer_num";
	$layer_contents = '';
    }
}

sub handle_layer {
    if (/\%AI\d_EndLayer/) {
	end_style ();
	push @layers, " <g> <!-- Layer: $layer_name -->\n$layer_contents </g>\n";
	$handler = \&handle_wait_layer;
    }
    else {
	my @tokens = ps_tokenize ($_);
	foreach my $tok (@tokens) {
	    ps_exec ($tok);
	}
    }
}

sub print_gradient_instances {
    print " <defs>\n";
    foreach my $gradient (sort keys %gradient_stops) {
	my @instances = @{$gradient_instances{$gradient}};
	for my $instance (@instances) {
	    print $instance;
	}
    }
    print " </defs>\n";
}

while (<>) {
    &$handler ();
}

$width = $x1 - $x0;
$height = $y1 - $y0;
print "<svg width=\"$width\" height=\"$height\">\n";
if ($header{'Title'}) {
    my $title = substr ($header{'Title'}, 1, -1);
    print " <!-- $title converted by ill2svg.pl -->\n";
}
print_gradient_instances ();
foreach my $layer (@layers) {
    print $layer;
}
print "</svg>\n";
