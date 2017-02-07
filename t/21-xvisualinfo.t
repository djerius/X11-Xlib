#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 8;

use_ok('X11::Xlib::XVisualInfo') or die;
sub err(&) { my $code= shift; my $ret; { local $@= ''; eval { $code->() }; $ret= $@; } $ret }

# Create a new XEvent
my $struct= new_ok( 'X11::Xlib::XVisualInfo', [], 'blank' );
ok( defined $struct->buffer, 'buffer is defined' );
ok( length($struct->buffer) > 0, 'and has non-zero length' );

$struct->red_mask(0xFF0000);
$struct->blue_mask(0x0000FF);

# Clone an event via its fields:
my $clone= new_ok( 'X11::Xlib::XVisualInfo', [$struct->unpack], 'clone event with pack(unpack)' )
    or diag explain $struct->unpack;
is( $clone->buffer, $struct->buffer, 'clone contains identical bytes' );

is( $clone->red_mask, 0xFF0000, 'red_mask value preserved' );
is( $clone->blue_mask, 0x0000FF, 'blue_mask value preserved' );

#my $conn= X11::Xlib->new();
#my @visuals= map { $_->unpack } $conn->XGetVisualInfo(0, my $foo);
#use DDP;
#p @visuals;