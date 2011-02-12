#!/usr/bin/perl

package tCAD::PowerArea;
use tCAD::GRAPH;
use tCAD::util;
use tCAD::tTSV;
use tCAD::tPAD;
use Data::Dumper;
use strict;

sub new {
 my $class = shift;
 my $self = { 
               ready_list    => [],
               irst_list     => {},
               top_list      => shift || die "PowerArea->top_list error\n",
            }; 
 bless $self, $class;
 return $self;
}

sub set_ready_list {
    my ($self,$list) = (@_);
        @{$self->{ready_list}} = @{$list};
}

# ignore the loop-back case
sub push_ready_list {
    my ($self,$name) = (@_);   
    push (@{$self->{ready_list}},$name);
}

sub pop_ready_list {
    my ($self) = (@_);
return pop @{$self->{ready_list}};
}

sub shft_ready_list {
    my ($self) = (@_);
return shift @{$self->{ready_list}};
}

sub is_ready_list_empty {
    my ($self) = (@_);
    if(!@{$self->{ready_list}}){ return 0 }
return -1;
}


sub push_irst_power_list_by_cell {
   my ($self,$pin_totpwr,$cell) = (@_);

   if( !defined($self->{irst_list}->{power}->{$cell}) ){
                $self->{irst_list}->{power}->{$cell}->{power}  = $pin_totpwr;
                $self->{irst_list}->{power}->{$cell}->{partid} = -1; 
   }else {
                $self->{irst_list}->{power}->{$cell}->{power}  += $pin_totpwr;
   }
}

sub push_irst_area_list_by_cell {
   my ($self,$cell_totarea,$cell) = (@_);

   if( !defined($self->{irst_list}->{area}->{$cell}) ){
                $self->{irst_list}->{area}->{$cell}->{area}  = $cell_totarea;
                $self->{irst_list}->{area}->{$cell}->{partid} = -1; 
   }else {
                $self->{irst_list}->{area}->{$cell}->{area}  += $cell_totarea;
   }
}




sub run_PowerAreaSearch_path {
    my ($self) = (@_);
 
    my $top_list   = $self->{top_list}                          || die "PowerArea->run_PowerAreaSearch_path(1) error\n";
    my $macro_list = $self->{top_list}->{util}->{cell}->{MACRO} || die "PowerArea->run_PowerAreaSearch_path(2) error\n";
    my $graph_list = $self->{top_list}->{Graph_list}            || die "PowerArea->run_PowerAreaSearch_path(3) error\n";

   while( $self->is_ready_list_empty()!=0 ){
       my $cur_vex      = $self->shft_ready_list();
       my $cur_tim_wght = $graph_list->get_time_weighted_vertex($cur_vex);

       my $cell_port    = $top_list->get_graph_port_name($cur_vex);
       my $cell_module  = $top_list->get_graph_module_name($cur_vex);

       my $pre_vex_list = $graph_list->get_vertex_pre_stack($cur_vex); 
       my $nxt_vex_list = $graph_list->get_vertex_nxt_stack($cur_vex); 
 
      foreach my $pre_vex (@{$pre_vex_list}){
               my $pre_tim_wght = $graph_list->get_time_weighted_vertex($pre_vex);
   
               if( $macro_list->{$cell_module}->{TYPE} eq 'SEQUENTIAL'  &&
                   $pre_vex =~ /CK\-/                                   ){
                   $graph_list->set_time_weighted_vertex($cur_vex,$pre_tim_wght);
               } else {
                   if($pre_tim_wght > $cur_tim_wght ){
                      $graph_list->set_time_weighted_vertex($cur_vex,$pre_tim_wght);
                  }
              }
     }

     if( !($macro_list->{$cell_module}->{TYPE} eq 'SEQUENTIAL' &&
           $cell_port                          eq 'D'          )){    
            foreach my $nxt_vex (@{$nxt_vex_list}){
                    $self->push_ready_list($nxt_vex);        
                } 
      } 
        $self->run_PowerAreaSearch_path();
    }
}

#==========================================
# @ this case 'time_weighted' = frequency
#==========================================
sub run_PowerAreaIni_path {
    my ($self) = (@_);

    my  $top_list      = $self->{top_list}                                 || die "PowerArea->run_PowerAreaIni_path(1) error\n";
    my  $pad_freq_list = $self->{top_list}->{util}->{bench}->{INPUT_PAD}   || die "PowerArea->run_PowerAreaIni_path(2) error\n"; 
    my  $graph_list    = $self->{top_list}->{Graph_list}                   || die "PowerArea->run_PowerAreaIni_path(3) error\n";
   
    my  $pad_freq;
    my  $pad_def_freq;
    my  $input_list    = $graph_list->{input_list};   
  
    foreach my $input (@{$input_list}){
       my $ipad   = $top_list->get_graph_port_name($input);
       my $module = $top_list->get_graph_module_name($input);

       my $hit =0;
       foreach my $pad (@{$pad_freq_list}){
               if( defined($pad->{DEFAULT}) ){ $pad_def_freq = $pad->{DEFAULT}; }

               if( defined($pad->{$ipad}) ){
                   $pad_freq = $pad->{$ipad};
                   $graph_list->set_time_weighted_vertex($input,$pad_freq); $hit=1;
                   $self->push_ready_list($input);                  
               } 
       } 
       if($hit==0){$graph_list->set_time_weighted_vertex($input,$pad_def_freq); 
                  $self->push_ready_list($input); }     
   }
}

sub run_StcPowerPin_by_pad {
    my ($self,$pin,$freq,$module) = (@_);
 
    my $macro_list = $self->{top_list}->{util}->{cell}->{MACRO}        || die "PowerArea->run_StcPowerPin_by_pad(1) error\n";
    my $cell_volt  = $self->{top_list}->{util}->{cell}->{IO_VOLTAGE}   || die "PowerArea->run_StcPowerPin_by_pad(2) error\n";   

    my $pin_tb     = $macro_list->{$module}->{PIN}->{$pin}             || die "PowerArea->run_StcPowerPin_by_pad(3) error\n";
 
return $freq * $pin_tb->{POWER};  
}

sub run_DymPowerPin_by_pad {
    my ($self,$pin,$freq,$module) = (@_);

    my $macro_list = $self->{top_list}->{util}->{cell}->{MACRO}        || die "PowerArea->run_DymPowerPin_by_pad(1) error\n";
    my $cell_volt  = $self->{top_list}->{util}->{cell}->{IO_VOLTAGE}   || die "PowerArea->run_DymPowerPin_by_pad(2) error\n";   

    my $pin_tb     = $macro_list->{$module}->{PIN}->{$pin}             || die "PowerArea->run_DymPowerPin_by_pad(3) error\n";
 
return 0.5 * $cell_volt * $cell_volt * $freq * $pin_tb->{CAPACITANCE};
}

sub run_StcPowerPin_by_cell {
    my ($self,$pin,$freq,$module) = (@_);
 
    my $macro_list = $self->{top_list}->{util}->{cell}->{MACRO}        || die "PowerArea->run_StcPowerPin_by_cell(1) error\n";
    my $cell_volt  = $self->{top_list}->{util}->{cell}->{CELL_VOLTAGE} || die "PowerArea->run_StcPowerPin_by_cell(2) error\n";   

    my $pin_tb     = $macro_list->{$module}->{PIN}->{$pin}             || die "PowerArea->run_StcPowerPin_by_cell(3) error\n";
 
return $freq * $pin_tb->{POWER};  
}

#====================
#ex: I1/A-AND2X1
#  @ cell I1(A) moudle @AND2X1
#====================
sub run_DymPowerPin_by_cell {
    my ($self,$pin,$freq,$module) = (@_);

    my $macro_list = $self->{top_list}->{util}->{cell}->{MACRO}        || die "PowerArea->run_DymPowerPin_by_cell(1) error\n";
    my $cell_volt  = $self->{top_list}->{util}->{cell}->{CELL_VOLTAGE} || die "PowerArea->run_DymPowerPin_by_cell(2) error\n";   

    my $pin_tb     = $macro_list->{$module}->{PIN}->{$pin}             || die "PowerArea->run_DymPowerPin_by_cell(3) error\n";
 
return 0.5 * $cell_volt * $cell_volt * $freq * $pin_tb->{CAPACITANCE};
}


sub run_StcPowerData_by_cell {
    my ($self,$freq,$module) = (@_);

    my $macro_list = $self->{top_list}->{util}->{cell}->{MACRO}        || die "PowerArea->run_StcPowerData_by_cell(1) error\n";

    my $power      = $macro_list->{$module}->{POWER}                   || die "PowerArea->run_StcPowerData_by_cell(2) error\n";

return $freq * $power;
}




sub run_PowerAreaAnalysis_path {
    my ($self) = (@_);

    my $top_list   = $self->{top_list}                                || die "PowerArea->run_PowerAreaAnalysis_path(1) error\n";
    my $graph_list = $self->{top_list}->{Graph_list}                  || die "PowerArea->run_PowerAreaAnalysis_path(2) error\n";
    my $macro_list = $self->{top_list}->{util}->{cell}->{MACRO}       || die "PowerArea->run_PowerAreaAnalysis_path(3) error\n";
    my $vex_list   = $graph_list->get_all_vertices()                  || die "PowerArea->run_PowerAreaAnalysis_path(4) error\n";      
 
    foreach my $vex (@{$vex_list}){
            if( $top_list->is_graph_module_exist($vex) ==0 ){

               my $cell_name    = $top_list->get_graph_cell_name($vex);
               my $cell_module  = $top_list->get_graph_module_name($vex);

               my $pre_vex_list = $graph_list->get_vertex_pre_stack($vex);

               foreach my $pre_vex (@{$pre_vex_list}){
                       my $freq = $graph_list->get_time_weighted_vertex($pre_vex);
                       my $tpre_vex;
                       my ($pin_dympwr,$pin_stcpwr,$pin_totpwr);               
            
                       if($pre_vex =~ /\/(\S+)$/){ $tpre_vex=$1; }
                       my $pin     = $top_list->get_graph_port_name($tpre_vex);
                       my $module  = $top_list->get_graph_module_name($tpre_vex);
                     
                        # @ PAD part
                       if( $macro_list->{$module}->{TYPE} eq 'IO' ){ 
                           $pin_dympwr = $self->run_DymPowerPin_by_pad($pin,$freq,$module);
                           $pin_stcpwr = $self->run_StcPowerPin_by_pad($pin,$freq,$module);
                           $pin_totpwr = $pin_dympwr + $pin_stcpwr;
                         
                      # @ COMBINATIONAL && SEQUENTIAL part 
                       }else {
                         $pin_dympwr = $self->run_DymPowerPin_by_cell($pin,$freq,$module);
                         $pin_stcpwr = $self->run_StcPowerPin_by_cell($pin,$freq,$module);
                         $pin_totpwr = $pin_dympwr + $pin_stcpwr;   
                       }

                        $self->push_irst_power_list_by_cell($pin_totpwr,$vex);
                        $graph_list->set_time_power_vertex($pre_vex,$pin_totpwr);
              }

              if( $macro_list->{$cell_module}->{TYPE} eq 'SEQUENTIAL' ){
                     my $freq = $graph_list->get_time_weighted_vertex($vex);
                     my $data_totpwr = $self->run_StcPowerData_by_cell($freq,$cell_module);

                        $self->push_irst_power_list_by_cell($data_totpwr,$vex);
                        $graph_list->set_time_power_vertex($vex,$data_totpwr);
              }

              my $cell_totarea= $macro_list->{$cell_module}->{AREA};
              $self->push_irst_area_list_by_cell($cell_totarea,$vex);
              $graph_list->set_time_area_vertex($vex,$cell_totarea);
         }
    }
}


sub get_pwr_TSV_number_by_layer {
    my ($self,$layer) = (@_);

    my $cell_list    = $self->{top_list}->{util}->{cell}                   || die "PowerArea->get_pwr_TSV_number_by_layer(1) error\n";

    my $core_voltage = $cell_list->{CELL_VOLTAGE};
    my $core_cur_lim = $cell_list->{TSV_CUR_LM};

    my $core_power   = $self->get_core_total_power_by_layer($layer);
    my $core_i       = ( $core_voltage!=0 )? $core_power / $core_voltage : die "";    
    my $tsv_number   = ( $core_cur_lim!=0 )? $core_i / ($core_cur_lim * 1000) : die "";

    if( $tsv_number > int($tsv_number) ){ return int($tsv_number)+1; }
    else {                                return int($tsv_number);   }
}

sub get_pad_total_area_by_layer {
    my ($self,$layer) = (@_);

    my $graph_list = $self->{top_list}->{Graph_list}                       || die "PowerArea->get_pad_total_area_by_layer(1) error\n";

    my $vex_list  = $graph_list->get_all_vertices();
    my $tot_area =0;

    foreach my $vex (@{$vex_list}){
            my $ilayer = $graph_list->get_time_layer_vertex($vex);
            my $logic  = $graph_list->get_time_logic_vertex($vex);
            if( $layer == $ilayer && $logic eq 'IO' ){
               $tot_area += $graph_list->get_time_area_vertex($vex);
            }
    }
return $tot_area;
}

sub get_core_total_area_by_layer {
    my ($self,$layer) = (@_);

    my $graph_list = $self->{top_list}->{Graph_list}                       || die "PowerArea->get_core_total_area_by_layer(1) error\n";

    my $vex_list  = $graph_list->get_all_vertices();
    my $tot_area =0;

    foreach my $vex (@{$vex_list}){
            my $ilayer = $graph_list->get_time_layer_vertex($vex);
            my $logic  = $graph_list->get_time_logic_vertex($vex);
            if( $layer == $ilayer && $logic ne 'IO' ){
               $tot_area += $graph_list->get_time_area_vertex($vex);
            }
    }
return $tot_area;
}

sub get_pad_total_power_by_layer {
    my ($self,$layer) = (@_);
 
    my $graph_list = $self->{top_list}->{Graph_list}                       || die "PowerArea->get_pad_total_power_by_layer(1) error\n";

    my $vex_list  = $graph_list->get_all_vertices();
    my $tot_power =0;

    foreach my $vex (@{$vex_list}){
            my $ilayer = $graph_list->get_time_layer_vertex($vex);
            my $logic  = $graph_list->get_time_logic_vertex($vex);
            if( $layer == $ilayer && $logic eq 'IO' ){
               $tot_power += $graph_list->get_time_power_vertex($vex);
            }
    }
return $tot_power;
}

sub get_core_total_power_by_layer {
    my ($self,$layer) = (@_);
 
    my $graph_list = $self->{top_list}->{Graph_list}                       || die "PowerArea->get_core_total_power_by_layer(1) error\n";

    my $vex_list  = $graph_list->get_all_vertices();
    my $tot_power =0;

    foreach my $vex (@{$vex_list}){
            my $ilayer = $graph_list->get_time_layer_vertex($vex);
            my $logic  = $graph_list->get_time_logic_vertex($vex);
            if( $layer == $ilayer && $logic ne 'IO' ){
               $tot_power += $graph_list->get_time_power_vertex($vex);
            }
    }
return $tot_power;
}

sub get_nxt_cell_module_stack {
    my ($self,$cell_module) = (@_); 

    my $top_list       = $self->{top_list}                                || die "PowerArea->get_nxt_cell_module_stack(1) error\n"; 
    my $graph_list     = $self->{top_list}->{Graph_list}                  || die "PowerArea->get_nxt_cell_module_stack(2) error\n";
    my @nxt_cell_list;

    if( $top_list->is_graph_module_exist($cell_module)==0 ){ 
     my $nxt_port_list = $graph_list->get_vertex_nxt_stack($cell_module); 

        # @ nxt vertex check 
       foreach my $nxt_port (@{$nxt_port_list}){
               my $nxt_cont_list = $graph_list->get_vertex_nxt_stack($nxt_port);

            foreach my $nxt_cont (@{$nxt_cont_list}){
                    my $nxt_cell_list = $graph_list->get_vertex_nxt_stack($nxt_cont);

                    foreach my $nxt_cell (@{$nxt_cell_list}){
                            push (@nxt_cell_list, $nxt_cell);                    
                    }
            }
      }
   }

return \@nxt_cell_list;
}


sub get_pre_cell_module_stack {
    my ($self,$cell_module) = (@_); 

    my $top_list       = $self->{top_list}                               || die "PowerArea->get_pre_cell_module_stack(1) error\n";
    my $graph_list     = $self->{top_list}->{Graph_list}                 || die "PowerArea->get_pre_cell_module_stack(2) error\n";
    my @pre_cell_list;

    if( $top_list->is_graph_module_exist($cell_module)==0 ){ 
     my $pre_port_list = $graph_list->get_vertex_pre_stack($cell_module); 

        # @ pre vertex check 
       foreach my $pre_port (@{$pre_port_list}){
               my $pre_cont_list = $graph_list->get_vertex_pre_stack($pre_port);

            foreach my $pre_cont (@{$pre_cont_list}){
                    my $pre_cell_list = $graph_list->get_vertex_pre_stack($pre_cont);

                    foreach my $pre_cell (@{$pre_cell_list}){
                            push (@pre_cell_list, $pre_cell);                    
                    }
            }
      }
   }

return \@pre_cell_list;
}

sub set_time_pass_cell_module {
    my ($self,$cell_name,$pass) = (@_);
   
    my $top_list   = $self->{top_list}                                    || die "PowerArea->set_time_pass_cell_module(1) error\n";
    my $graph_list = $self->{top_list}->{Graph_list}                      || die "PowerArea->set_time_pass_cell_module(2) error\n";
 
    if( $top_list->is_graph_module_exist($cell_name)==0 ){
    my $pre_port_list = $graph_list->get_vertex_pre_stack($cell_name); 
    my $nxt_port_list = $graph_list->get_vertex_nxt_stack($cell_name); 
 
       $graph_list->set_time_pass_vertex($cell_name,$pass);

       foreach my $pre_port (@{$pre_port_list}){
                  $graph_list->set_time_pass_vertex($pre_port,$pass);
       }

       foreach my $nxt_port (@{$nxt_port_list}){
                  $graph_list->set_time_pass_vertex($nxt_port,$pass);
       }
    }
}


sub set_time_layer_cell_module {
    my ($self,$cell_name,$layer) = (@_);

    my $top_list   = $self->{top_list}                                   || die "PowerArea->set_time_layer_cell_module(1) error\n";
    my $graph_list = $self->{top_list}->{Graph_list}                     || die "PowerArea->set_time_layer_cell_module(2) error\n";

    if( $top_list->is_graph_module_exist($cell_name)==0 ){  
    my $pre_port_list = $graph_list->get_vertex_pre_stack($cell_name); 
    my $nxt_port_list = $graph_list->get_vertex_nxt_stack($cell_name); 
 
       $graph_list->set_time_layer_vertex($cell_name,$layer);

       foreach my $pre_port (@{$pre_port_list}){
                  $graph_list->set_time_layer_vertex($pre_port,$layer);
       }

       foreach my $nxt_port (@{$nxt_port_list}){
                  $graph_list->set_time_layer_vertex($nxt_port,$layer);
       }
   }
}

sub run_PowerArea_DD {
    my ($self) = (@_);
    my $graph_list = $self->{top_list}->{Graph_list}                    || die "PowerArea->run_power_DD(1) error\n";

    # @ the loop back case  -> @ boundary(end) pin Flip->D
    $self->run_PowerAreaIni_path();
    $self->run_PowerAreaSearch_path();
    $self->run_PowerAreaAnalysis_path();
}


sub get_debug {
    my ($self) = (@_);

#print $self->get_core_total_area_by_layer(1);
#print Dumper($self->{top_list}->{Graph_list}->{logic_list});
#print Dumper($self->{top_list}->{Graph_list}->{power_list});
#print Dumper($self->{top_list}->{Graph_list}->{area_list});
#print Dumper($self->{top_list}->{Graph_list}->{layer_list});
#print Dumper($self->{top_list}->{Graph_list});

#print Dumper($self->{top_list}->{util}->{verilog});
#print Dumper($self->{top_list}->{util});
#print Dumper($self->{itmp_list});
#print Dumper($self->{irst_list});

}

sub free {
    my ($self) = (@_);
        $self->{ready_list} = [];
}

1;
