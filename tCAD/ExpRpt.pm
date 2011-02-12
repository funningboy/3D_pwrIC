#!/usr/bin/perl

package tCAD::ExpRpt;
use tCAD::PowerArea;
use tCAD::util;
use Data::Dumper;
use File::Path qw(make_path remove_tree);
use strict;

sub new {
 my $class = shift;
 my $self = { 
            rpt_list    => {},
            freq_list   => {},
            IC3DiGA     => shift || die "ExpVeri->IC3DiGA error\n", 
            }; 
 bless $self, $class;
 return $self;
}

sub push_freq_list {
    my ($self,$freq) = (@_);

    if( !defined($self->{freq_list}->{$freq}) ){
         $self->{freq_list}->{$freq} = $freq;
    }
}

sub push_rpt_power_list_by_module {
    my ($self,$layer,$freq,$power,$port,$module) = (@_);

    if( !defined($self->{rpt_list}->{$layer}->{$module}->{power}->{$port}->{$freq}) ){
                 $self->{rpt_list}->{$layer}->{$module}->{power}->{$port}->{$freq}->{power} = $power;
                 $self->{rpt_list}->{$layer}->{$module}->{power}->{$port}->{$freq}->{id}    = 1;
    } else {
                 $self->{rpt_list}->{$layer}->{$module}->{power}->{$port}->{$freq}->{power} += $power;
                 $self->{rpt_list}->{$layer}->{$module}->{power}->{$port}->{$freq}->{id}    += 1;
   }
}

sub push_rpt_area_list_by_module {
    my ($self,$layer,$area,$module) = (@_);

    if( !defined($self->{rpt_list}->{$layer}->{$module}->{area}) ){
                 $self->{rpt_list}->{$layer}->{$module}->{area}->{area} = $area;
                 $self->{rpt_list}->{$layer}->{$module}->{area}->{id}   = 1;
    }else {
                 $self->{rpt_list}->{$layer}->{$module}->{area}->{area} += $area;
                 $self->{rpt_list}->{$layer}->{$module}->{area}->{id}   += 1;
   }
}



sub run_Exp_top_DD {
    my ($self) = (@_);

    my $top_list   = $self->{IC3DiGA}->{pwr_area_list}->{top_list}               || die "ExpRpt->run_Exp_top_DD(1) error\n";
    my $graph_list = $self->{IC3DiGA}->{pwr_area_list}->{top_list}->{Graph_list} || die "ExpRpt->run_Exp_top_DD(2) error\n";
    
    my $vex_list   = $graph_list->get_all_vertices();

    foreach my $vex (@{$vex_list}){
            my $layer  = $graph_list->get_time_layer_vertex($vex);
            my $logic  = $graph_list->get_time_logic_vertex($vex);

            my $module = $top_list->get_graph_module_name($vex);
            my $port   = $top_list->get_graph_port_name($vex) || undef;

            my $freq   = $graph_list->get_time_weighted_vertex($vex);
            my $power  = $graph_list->get_time_power_vertex($vex);
            my $area   = $graph_list->get_time_area_vertex($vex);

            if( defined($port) ){
               $self->push_rpt_power_list_by_module($layer,$freq,$power,$port,$module);
               $self->push_freq_list($freq);

            } elsif( !defined($port) && $logic eq 'SEQUENTIAL' ){ 
               $self->push_rpt_power_list_by_module($layer,$freq,$power,'DATA',$module);
            }

            if( $top_list->is_graph_module_exist($vex)==0 ){
               $self->push_rpt_area_list_by_module($layer,$area,$module);
            }
   }
}

sub run_Exp_rpt_DD {
    my ($self,$top) = (@_);

    my $constrain_list = $self->{IC3DiGA}->{pwr_area_list}->{top_list}->{util}|| die "ExpRpt->run_Exp_rpt_DD(1) error\n";

    my $rpt_path = './rpt/';
 
    if( !-e $rpt_path ){
        make_path($rpt_path);
    }

    my $file = $rpt_path.'partition_rpt.csv';

    open (OUTPTR,">$file") || die "ExpRpt->run_Exp_rpt_DD open file error\n";


    print OUTPTR 'Partitioned_Design'."\n";
    print OUTPTR 'Verilog_File,'.$top.'_Ltop'.'.v'."\n";
    print OUTPTR 'Top_Module,'.'_ic3d_top_'."\n";
    print OUTPTR 'Layer_Number,'.$constrain_list->{bench}->{LAYER}."\n";
    print OUTPTR "\n";
    print OUTPTR "\n";
 
   foreach my $layer (sort keys %{$self->{rpt_list}}){

    print OUTPTR 'Layer,'.$layer."\n";
    print OUTPTR 'Verilog_file,'.$top.'_L'.$layer.'.v'."\n";

    my $freq_st;
    foreach my $freq (sort keys %{$self->{freq_list}}){
               $freq_st .= ',Number-'.$freq.'(f)'.',Power-'.$freq.'(f)'; 
    }
    print OUTPTR 'Cell_name,Number,Area,Pin'.$freq_st."\n";
 
     foreach my $module  (keys %{$self->{rpt_list}->{$layer}} ){
              my $area   = $self->{rpt_list}->{$layer}->{$module}->{area}->{area};
              my $area_id= $self->{rpt_list}->{$layer}->{$module}->{area}->{id};
              print OUTPTR $module.','.$area_id.','.$area.',';

              my $time = 0;
              my $power_list = $self->{rpt_list}->{$layer}->{$module}->{power};
              foreach my $pin (keys %{$power_list}){
              
              if( $time!=0 ){
                  print OUTPTR ','.','.',';
              }   
                  print OUTPTR $pin; 
                  foreach my $freq (sort keys %{$self->{freq_list}}){
                          if( defined($power_list->{$pin}->{$freq}) ){
                             print OUTPTR ','.$power_list->{$pin}->{$freq}->{id}.','.$power_list->{$pin}->{$freq}->{power};
                           } else {
                             print OUTPTR ',0'.',0';
                           }
                   }
              $time=1;
              print OUTPTR "\n"; 
            }
      }
              print OUTPTR "\n"; 
              print OUTPTR "\n"; 
   }

close(OUTPTR);
}

sub run_Exp_DFG2Rpt_DD {
    my ($self,$top) = (@_);

        $self->run_Exp_top_DD();
        $self->run_Exp_rpt_DD($top);

}

sub get_debug {
    my ($self) = (@_);
}

sub free {
   my ($self) = (@_);
       $self->{rpt_list}    = {};
       $self->{freq_list}   = {};
}
1;
