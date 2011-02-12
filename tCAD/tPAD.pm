#!/usr/bin/perl

package tCAD::tPAD;
use tCAD::util;
use Data::Dumper;
use strict;

sub new {
 my $class = shift;
 my $self = {   in_pad => { name => 'IN_PAD',
                            id   => '0',
                            pd   => 'PD',
                            c    => 'C',},
                out_pad =>{ name => 'OUT_PAD',
                            id   => '0',
                            pd   => 'PD',
                            i    => 'I',},
            }; 
 bless $self, $class;
 return $self;
}

1
