#!/usr/bin/perl

package tCAD::tTSV;
use tCAD::PowerArea;
use tCAD::util;
use Data::Dumper;
use strict;

sub new {
 my $class = shift;
 my $self = {  tsv_cell           => { name => 'TSV_CELL',
                                       id   => '0',
                                       up   => 'UP',
                                       down => 'DN',},
               tsv_land           => { name => 'TSV_LAND',
                                       id   => '0',
                                       up   => 'UP',
                                       down => 'DN',},
            }; 
 bless $self, $class;
 return $self;
}

1;
