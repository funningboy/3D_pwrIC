#!/usr/bin/perl

package tCAD::GRAPH;
use tCAD::DFG;
use tCAD::util;
use tCAD::tTSV;
use tCAD::tPAD;
use Data::Dumper;
use strict;

sub new {
 my $class = shift;
 my $self = { 
              Graph_list    => tCAD::DFG->new(),
              tPAD          => tCAD::tPAD->new(),
              tTSV          => tCAD::tTSV->new(),
              in_pad_list   => {},
              out_pad_list  => {},
              tsv_land_list => {},
              tsv_cell_list => {},
              cell_define   => {},
              wire_tb       => {},
              util          => shift || die,
           }; 
 bless $self, $class;
 return $self;
}

sub free_wire_tb {
    my ($self) = (@_);
        $self->{wire_tb} = {};
}

sub push_wire_from_tb {
   my ($self,$key,$val) = (@_);
   push (@{$self->{wire_tb}->{$key}->{from}},$val);
}

sub push_wire_to_tb {
   my ($self,$key,$val) = (@_);
   push (@{$self->{wire_tb}->{$key}->{to}},$val);
}

sub get_wire_tb {
   my ($self,$key) = (@_);
return $self->{wire_tb};   
}

sub set_graph_port_name {
    my ($self,$cell,$port,$module) = (@_);
return  $cell.$port.'-'.$module;  
}

sub get_graph_port_name {
    my ($self,$name) = (@_);
    if($name =~ /(\w+)\-/){ return $1; }         
}

sub is_graph_module_exist {
    my ($self,$name) = (@_);
    if( $name =~ /\:\:/ ){ return 0; }

return -1;
}

sub set_graph_module_name {
    my ($self,$cell,$module) = (@_);
return $cell.'::'.$module;
}

sub get_graph_module_name {
    my ($self,$name) = (@_);
    if($name =~ /\:\:(\w+)/){ return $1; }
    if($name =~ /\-(\w+)/){   return $1; }
}

sub get_graph_cell_name {
    my ($self,$name) = (@_);
    if($name =~ /(\S+)\:\:/){ return $1; }
}

sub get_graph_cell_level {
    my ($self,$cell) = (@_);
    my @level = split('/',$cell);
return \@level;
}

sub set_graph_wire_name {
    my ($self,$cell,$port) = (@_);
return $cell.$port;
}


sub dump_graphviz_file {
   my ($self,$path) = (@_);
   $self->{Graph_list}->dump_graphviz_file($path)        || die "dump_graphviz_by_module error\n";
}

sub set_graph_input_vertices {
    my ($self,$name,$module) = (@_);
    my $verilog_list = $self->{util}->{verilog}          || die "GRAPH->set_graph_input_vertices(1) error\n"; 

    foreach my $input (@{$verilog_list->{$module}->{input}}){

            my $in_vertex = $self->set_graph_port_name($name,$input,$module);
            my $in_wire   = $self->set_graph_wire_name($name,$input);

              $self->{Graph_list}->set_time_weighted_vertex($in_vertex,0);
              $self->{Graph_list}->set_time_logic_vertex($in_vertex,'NET');
              $self->{Graph_list}->set_time_power_vertex($in_vertex,0);
              $self->{Graph_list}->set_time_area_vertex($in_vertex,0);
              $self->{Graph_list}->set_time_layer_vertex($in_vertex,1);
              $self->{Graph_list}->set_time_pass_vertex($in_vertex,0);
              $self->{Graph_list}->set_time_type_vertex($in_vertex,0);

              $self->push_wire_from_tb($in_wire,$in_vertex);
    }
}

sub set_graph_output_vertices {
    my ($self,$name,$module) = (@_);
    my $verilog_list = $self->{util}->{verilog}           || die "GRAPH->set_graph_output_vertices(1) error\n"; 

      foreach my $output (@{$verilog_list->{$module}->{output}}){
              my $out_vertex = $self->set_graph_port_name($name,$output,$module);
              my $out_wire   = $self->set_graph_wire_name($name,$output);

                 $self->{Graph_list}->set_time_weighted_vertex($out_vertex,0);
                 $self->{Graph_list}->set_time_logic_vertex($out_vertex,'NET');
                 $self->{Graph_list}->set_time_power_vertex($out_vertex,0);
                 $self->{Graph_list}->set_time_area_vertex($out_vertex,0);
                 $self->{Graph_list}->set_time_layer_vertex($out_vertex,1);
                 $self->{Graph_list}->set_time_pass_vertex($out_vertex,0);
                 $self->{Graph_list}->set_time_type_vertex($out_vertex,1);
 
                 $self->push_wire_to_tb($out_wire,$out_vertex);
       }
}

sub set_graph_cell_vertices {
    my ($self,$name,$module) = (@_);
    my $verilog_list = $self->{util}->{verilog}            || die "GRAPH->set_graph_cell_vertices(1) error\n"; 
    my $macro_list   = $self->{util}->{cell}->{MACRO}      || die "GRAPH->set_graph_cell_vertices(2) error\n";
   
      foreach my $nw_cell (@{$verilog_list->{$module}->{cell}}){
              my $nw_cell_name   = $nw_cell->{cell_name};
              my $nw_cell_module = $nw_cell->{cell_module};
              my $nw_cell_link   = $nw_cell->{cell_link};
              
              my $cell_define    = $name.$nw_cell_name.'/';

              if( !defined($self->{cell_define}->{$cell_define}) ){ 
                 my $nw_cell_vertex = $self->set_graph_module_name($cell_define,$nw_cell_module);

                   $self->{Graph_list}->set_time_weighted_vertex($nw_cell_vertex,0);
                   $self->{Graph_list}->set_time_logic_vertex($nw_cell_vertex,$macro_list->{$nw_cell_module}->{TYPE});
                   $self->{Graph_list}->set_time_power_vertex($nw_cell_vertex,0);
                   $self->{Graph_list}->set_time_area_vertex($nw_cell_vertex,0);
                   $self->{Graph_list}->set_time_layer_vertex($nw_cell_vertex,1);
                   $self->{Graph_list}->set_time_pass_vertex($nw_cell_vertex,0);
                   $self->{Graph_list}->set_time_type_vertex($nw_cell_vertex,3);
 
                foreach my $link (@{$nw_cell_link}){
                        my $lk_cell_port   = $link->{port_name};
                        my $lk_cell_wire   = $link->{wire_name};
                        my $wire = $name.$lk_cell_wire;
                        my $port = $self->set_graph_port_name($cell_define,$lk_cell_port,$nw_cell_module);
                        my $wvex = $self->set_graph_wire_name($cell_define,$lk_cell_port);

                        # deep module case
                        if($self->{util}->is_cell_module_deep($nw_cell_module)==0){
                              if($self->{util}->is_output_exist_by_module($lk_cell_port,$nw_cell_module)==0 ){
                                if( defined($lk_cell_wire) ){
                                    $self->{Graph_list}->set_time_weighted_vertex($port,0);
                                    $self->{Graph_list}->set_time_logic_vertex($port,'NET');
                                    $self->{Graph_list}->set_time_power_vertex($port,0);
                                    $self->{Graph_list}->set_time_area_vertex($port,0);
                                    $self->{Graph_list}->set_time_layer_vertex($port,1);
                                    $self->{Graph_list}->set_time_pass_vertex($port,0);
                                    $self->{Graph_list}->set_time_type_vertex($port,1);
 
                                    $self->push_wire_from_tb($wire,$port);
                                    $self->push_wire_from_tb($wvex,$nw_cell_vertex);
                                    $self->push_wire_to_tb($wvex,$port);
                                } else { 
                                    $self->push_wire_to_tb($wire,$nw_cell_vertex); 
                                }
                              } else {
                                if( defined($lk_cell_wire) ){
                                    $self->{Graph_list}->set_time_weighted_vertex($port,0);
                                    $self->{Graph_list}->set_time_logic_vertex($port,'NET');
                                    $self->{Graph_list}->set_time_power_vertex($port,0);
                                    $self->{Graph_list}->set_time_area_vertex($port,0);
                                    $self->{Graph_list}->set_time_layer_vertex($port,1);
                                    $self->{Graph_list}->set_time_pass_vertex($port,0);
                                    $self->{Graph_list}->set_time_type_vertex($port,0);
 
                                    $self->push_wire_to_tb($wire,$port);
                                    $self->push_wire_from_tb($wvex,$port);
                                    $self->push_wire_to_tb($wvex,$nw_cell_vertex);
                                } else {
                                    $self->push_wire_from_tb($wire,$nw_cell_vertex);
                                }
                             } 
                        # normal case
                        } else {
                              if( $self->{util}->is_output_exist_by_module($lk_cell_port,$nw_cell_module)==0 ){
                                $self->push_wire_from_tb($wire,$nw_cell_vertex);
                              } else {
                                $self->push_wire_to_tb($wire,$nw_cell_vertex);
                              }
                        }
                 }
              } else {
                foreach my $link (@{$nw_cell_link}){
                        my $lk_cell_port   = $link->{port_name};
                        my $lk_cell_wire   = $link->{wire_name} || $link->{port_name};
                        my $wire = $name.$lk_cell_wire;

                         my $nw_cell_vertex = $self->set_graph_port_name($name.$nw_cell_name.'/',$lk_cell_port,$nw_cell_module);

                        if( $self->{util}->is_output_exist_by_module($lk_cell_port,$nw_cell_module)==0 ){
                            $self->push_wire_from_tb($wire,$nw_cell_vertex);
                        } else {
                            $self->push_wire_to_tb($wire,$nw_cell_vertex);
                        }
                     
              }
          }
 
     }

  $self->{cell_define}->{$name} = 1; 
}

sub set_graph_wire_edges {
   my ($self) = (@_);

   my $wire_list = $self->get_wire_tb()                   || die "GRAPH->set_graph_wire_edges(1) error\n";

   # set edges by each module
   foreach my $wire (keys %{$wire_list}){
      foreach my $from ( @{$wire_list->{$wire}->{from}} ){
        foreach my $to ( @{$wire_list->{$wire}->{to}} ){
          $self->{Graph_list}->set_time_weighted_edge($from,$to,0,$wire);
          }
       }
     }   
    $self->free_wire_tb();
}

sub is_bound_input_list_exist_by_top {
    my ($self,$wire,$top) = (@_);

    my $input_list = $self->{Graph_list}->get_input_lists() || die "GRAPH->is_bound_input_list_exist_by_top(1) error\n";
    my $wire_name  = $self->set_graph_port_name($wire,$top);

   foreach my $input (@{$input_list}){
            if( $input eq $wire_name){ return 0; }
   }
return -1;
}

sub is_bound_output_list_exist_by_top {
    my ($self,$wire,$top) = (@_);

    my $output_list = $self->{Graph_list}->get_output_lists() || die "GRAPH->is_bound_output_list_exist_by_top(1) error\n";
    my $wire_name   = $self->set_graph_port_name($wire,$top);
    foreach my $output (@{$output_list}){
            if( $output eq $wire_name){ return 0; }
   }
return -1;
}

sub set_bound_input_list { 
    my ($self,$top) = (@_);
    my  $input_list = $self->{util}->get_input_list_by_module($top) || die "GRPAH->set_bound_input_list(1) error\n";
    my  $tmp_list   = []; 

    foreach my $input (@{$input_list}){
            my $name = $self->set_graph_port_name('',$input,$top);
        push (@{$tmp_list}, $name);
                $self->{Graph_list}->set_time_weighted_vertex($name,0);
                $self->{Graph_list}->set_time_logic_vertex($name,'IO');
                $self->{Graph_list}->set_time_power_vertex($name,0);
                $self->{Graph_list}->set_time_area_vertex($name,0);
                $self->{Graph_list}->set_time_layer_vertex($name,1);
                $self->{Graph_list}->set_time_pass_vertex($name,0);
                $self->{Graph_list}->set_time_type_vertex($name,0);
    }
        $self->{Graph_list}->set_input_lists($tmp_list);
}

sub set_bound_output_list {
    my ($self,$top) = (@_);
    my  $output_list = $self->{util}->get_output_list_by_module($top) || die "GRAPH->set_bound_output_list(1) error\n";
    my  $tmp_list   = []; 

    foreach my $output (@{$output_list}){
            my $name = $self->set_graph_port_name('',$output,$top);
        push (@{$tmp_list}, $name);
                $self->{Graph_list}->set_time_weighted_vertex($name,0);
                $self->{Graph_list}->set_time_logic_vertex($name,'IO');
                $self->{Graph_list}->set_time_power_vertex($name,0);
                $self->{Graph_list}->set_time_area_vertex($name,0);
                $self->{Graph_list}->set_time_layer_vertex($name,1);
                $self->{Graph_list}->set_time_pass_vertex($name,0);
                $self->{Graph_list}->set_time_type_vertex($name,1);
    }
        $self->{Graph_list}->set_output_lists($tmp_list);
}

sub set_graph_InPAD {
    my ($self) = (@_);

    my $input_list = $self->{Graph_list}->get_input_lists() || die "GRAPH->set_graph_InPAD(1) error\n";

    foreach my $input (@{$input_list}){
            my $wire = $self->get_graph_port_name($input);

               $self->set_graph_InPAD_module(1);

            my $pd_in_pd = $self->{in_pad_list}->{pd};
            my $pd_ot_c  = $self->{in_pad_list}->{c};
               
            my @nxt_vex_list = @{$self->{Graph_list}->get_vertex_nxt_stack($input)};

            foreach my $nxt_vex (@nxt_vex_list){
                       $self->{Graph_list}->set_time_weighted_edge($pd_ot_c,$nxt_vex,0,$wire);
                       $self->{Graph_list}->del_time_weighted_edge($input,$nxt_vex); 
            }
                       $self->{Graph_list}->set_time_weighted_edge($input,$pd_in_pd,0,$wire);
       }
}

sub set_graph_OutPAD {
    my ($self) = (@_);

    my $output_list = $self->{Graph_list}->get_output_lists() || die "GRAPH->set_graph_OutPAD(1) error\n";

    foreach my $output (@{$output_list}){
            my $wire = $self->get_graph_port_name($output);

               $self->set_graph_OutPAD_module(1);

            my $pd_ot_pd = $self->{out_pad_list}->{pd};
            my $pd_in_i  = $self->{out_pad_list}->{i};
            
            my @pre_vex_list = @{$self->{Graph_list}->get_vertex_pre_stack($output)};

            foreach my $pre_vex (@pre_vex_list){
                       $self->{Graph_list}->set_time_weighted_edge($pre_vex,$pd_in_i,0,$wire);
                       $self->{Graph_list}->del_time_weighted_edge($pre_vex,$output); 
            }
                       $self->{Graph_list}->set_time_weighted_edge($pd_ot_pd,$output,0,$wire);
       }
}


sub run_graph_DD {
   my ($self,$top,$deep) = (@_);

  my $top_dwn_list = $self->{util}->{top_down_list}            || die "GRAPH->set_run_graph_DD(1) error\n";
  my @tp_dwn_key   = sort keys %{$top_dwn_list};

   if( $deep!=-1 && $#tp_dwn_key>$deep ){
      for(my $i = $deep+1; $i<=$#tp_dwn_key; $i++){
         delete $top_dwn_list->{$i};
      }
   }

   # set top graph by each cell
   foreach my $lvl (reverse sort keys %{$top_dwn_list}){
      foreach my $list (@{$top_dwn_list->{$lvl}}){                
              my $cell_name   = $list->{cell_name};
              my $cell_module = $list->{cell_module};
              
              $self->set_graph_input_vertices($cell_name,$cell_module);
              $self->set_graph_output_vertices($cell_name,$cell_module);
              $self->set_graph_cell_vertices($cell_name,$cell_module);
              $self->set_graph_wire_edges();
      }
   }
  
  $self->set_bound_input_list($top);
  $self->set_bound_output_list($top);

  # set PAD graph to top graph
  $self->set_graph_InPAD();
  $self->set_graph_OutPAD(); 

}

sub get_a_cycle_list {
    my ($self) = (@_);
return $self->{Graph_list}->get_a_cycle_list();
}

sub get_debug {
    my ($self) = (@_);
#print Dumper($self->{cell_define});
#print Dumper($self->{util}->{verilog});
#print Dumper($self);
#print Dumper($self->{Graph_list});
}

sub free {
   my ($self) = (@_);

   $self->{util}->{top_down_list}  = {};
   $self->{util}->{top_down_stack} = [];
   $self->{util}->{verilog}        = {};
   $self->{cell_define}            = {};
}

#==============================
# IO PAD graph && pass always = 1
#==============================
sub set_graph_InPAD_module {
    my ($self,$layer) = (@_);

    my $util_list    = $self->{util}                  || die "";
    my $macro_list   = $self->{util}->{cell}->{MACRO} || die "";
    my $graph_list   = $self->{Graph_list}            || die "";

       #@ InPAD define
     my $pad_module  = $self->{tPAD}->{in_pad}->{name};
     my $pad_name    = $self->{tPAD}->{in_pad}->{name}.'_'.$self->{tPAD}->{in_pad}->{id}++;
    
     my $pad_port_pd = $self->set_graph_port_name($pad_name.'/',$self->{tPAD}->{in_pad}->{pd},$pad_module);
     my $pad_port_c  = $self->set_graph_port_name($pad_name.'/',$self->{tPAD}->{in_pad}->{c},$pad_module);
     my $pad_cname   = $self->set_graph_module_name($pad_name.'/',$pad_module);
      
     my $pad_pd_pwr  = $macro_list->{$pad_module}->{PIN}->{$self->{tPAD}->{in_pad}->{pd}}->{POWER} || 0;
     my $pad_c_pwr   = $macro_list->{$pad_module}->{PIN}->{$self->{tPAD}->{in_pad}->{c}}->{POWER}  || 0;
     my $pad_area    = $macro_list->{$pad_module}->{AREA} || 0;
     my $pad_type    = $macro_list->{$pad_module}->{TYPE};
    
    # @ InPAD pd vertex
    $self->{Graph_list}->set_time_weighted_vertex($pad_port_pd,0);
    $self->{Graph_list}->set_time_logic_vertex($pad_port_pd,$pad_type);
    $self->{Graph_list}->set_time_power_vertex($pad_port_pd,$pad_pd_pwr);
    $self->{Graph_list}->set_time_area_vertex($pad_port_pd,0);
    $self->{Graph_list}->set_time_layer_vertex($pad_port_pd,$layer);
    $self->{Graph_list}->set_time_pass_vertex($pad_port_pd,1);
    
     # @ InPAD/ module vertex
    $self->{Graph_list}->set_time_weighted_vertex($pad_cname,0);
    $self->{Graph_list}->set_time_logic_vertex($pad_cname,$pad_type);
    $self->{Graph_list}->set_time_power_vertex($pad_cname,0);
    $self->{Graph_list}->set_time_area_vertex($pad_cname,$pad_area);
    $self->{Graph_list}->set_time_layer_vertex($pad_cname,$layer);
    $self->{Graph_list}->set_time_pass_vertex($pad_cname,1);
    $self->{Graph_list}->set_time_type_vertex($pad_cname,3);
  
    # @ InPAD c vertex
    $self->{Graph_list}->set_time_weighted_vertex($pad_port_c,0);
    $self->{Graph_list}->set_time_logic_vertex($pad_port_c,$pad_type);
    $self->{Graph_list}->set_time_power_vertex($pad_port_c,$pad_c_pwr);
    $self->{Graph_list}->set_time_area_vertex($pad_port_c,0);
    $self->{Graph_list}->set_time_layer_vertex($pad_port_c,$layer);
    $self->{Graph_list}->set_time_pass_vertex($pad_port_c,1);
 
    $self->{Graph_list}->set_time_weighted_edge($pad_port_pd,$pad_cname,0,$pad_port_pd);
    $self->{Graph_list}->set_time_weighted_edge($pad_cname,$pad_port_c,0,$pad_port_c);

    $self->{Graph_list}->set_time_type_vertex($pad_port_pd,0);
    $self->{Graph_list}->set_time_type_vertex($pad_port_c,1);
 
    $self->{in_pad_list}->{pd} = $pad_port_pd;
    $self->{in_pad_list}->{c}  = $pad_port_c;   
}

sub set_graph_OutPAD_module {
    my ($self,$layer) = (@_);

    my $macro_list   = $self->{util}->{cell}->{MACRO} || die "PowerArea->set_TSV_LAND_insert(1) error\n";
    my $graph_list   = $self->{Graph_list}            || die "";
    my $util_list    = $self->{util}                  || die "";

            #@ OutPAD define
            my $pad_module  = $self->{tPAD}->{out_pad}->{name};
            my $pad_name    = $self->{tPAD}->{out_pad}->{name}.'_'.$self->{tPAD}->{out_pad}->{id}++;
        
            my $pad_port_pd = $self->set_graph_port_name($pad_name.'/',$self->{tPAD}->{out_pad}->{pd},$pad_module);
            my $pad_port_i  = $self->set_graph_port_name($pad_name.'/',$self->{tPAD}->{out_pad}->{i},$pad_module);
            my $pad_cname   = $self->set_graph_module_name($pad_name.'/',$pad_module);
             
            my $pad_pd_pwr  = $macro_list->{$pad_module}->{PIN}->{$self->{tPAD}->{in_pad}->{pd}}->{POWER} || 0;
            my $pad_i_pwr   = $macro_list->{$pad_module}->{PIN}->{$self->{tPAD}->{in_pad}->{i}}->{POWER}  || 0;
            my $pad_area    = $macro_list->{$pad_module}->{AREA} || 0;
            my $pad_type    = $macro_list->{$pad_module}->{TYPE};
    
           # @ OutPAD pd vertex
           $self->{Graph_list}->set_time_weighted_vertex($pad_port_pd,0);
           $self->{Graph_list}->set_time_logic_vertex($pad_port_pd,$pad_type);
           $self->{Graph_list}->set_time_power_vertex($pad_port_pd,$pad_pd_pwr);
           $self->{Graph_list}->set_time_area_vertex($pad_port_pd,0);
           $self->{Graph_list}->set_time_layer_vertex($pad_port_pd,$layer);
           $self->{Graph_list}->set_time_pass_vertex($pad_port_pd,1);
    
            # @ OutPAD/ module vertex
           $self->{Graph_list}->set_time_weighted_vertex($pad_cname,0);
           $self->{Graph_list}->set_time_logic_vertex($pad_cname,$pad_type);
           $self->{Graph_list}->set_time_power_vertex($pad_cname,0);
           $self->{Graph_list}->set_time_area_vertex($pad_cname,$pad_area);
           $self->{Graph_list}->set_time_layer_vertex($pad_cname,$layer);
           $self->{Graph_list}->set_time_pass_vertex($pad_cname,1);
           $self->{Graph_list}->set_time_type_vertex($pad_cname,3);
  
           # @ OutPAD i vertex
           $self->{Graph_list}->set_time_weighted_vertex($pad_port_i,0);
           $self->{Graph_list}->set_time_logic_vertex($pad_port_i,$pad_type);
           $self->{Graph_list}->set_time_power_vertex($pad_port_i,$pad_i_pwr);
           $self->{Graph_list}->set_time_area_vertex($pad_port_i,0);
           $self->{Graph_list}->set_time_layer_vertex($pad_port_i,$layer);
           $self->{Graph_list}->set_time_pass_vertex($pad_port_i,1);
 
           $self->{Graph_list}->set_time_weighted_edge($pad_port_i,$pad_cname,0,$pad_port_i);
           $self->{Graph_list}->set_time_weighted_edge($pad_cname,$pad_port_pd,0,$pad_port_pd);

           $self->{Graph_list}->set_time_type_vertex($pad_port_pd,1);
           $self->{Graph_list}->set_time_type_vertex($pad_port_i,0);

           $self->{out_pad_list}->{pd} = $pad_port_pd;
           $self->{out_pad_list}->{i}  = $pad_port_i;   
}

#==================================
# TSV graph
#     xx/A     ->   OO/Y     :: -> direct(0) <- direct(1)
#    layer(1)      layer(3)
#      ...           ...
#----------------------------------
#              |
#             swap
#              |
#---------------------------------- 
#     OO/Y     <-   XX/A
#   layer(3)        layer(1)
#     ...             ...
#==================================
sub set_graph_TSV_land {
    my ($self,$layer,$wire,$direct) = (@_);
 
    my $macro_list   = $self->{util}->{cell}->{MACRO} || die "PowerArea->set_TSV_LAND_insert(1) error\n";
    my $graph_list   = $self->{Graph_list}            || die "";
    my $util_list    = $self->{util}                  || die "";

     #@ TSV_LAND define
     my $land_module  = $self->{tTSV}->{tsv_land}->{name};
     my $land_name    = $self->{tTSV}->{tsv_land}->{name}.'_'.$self->{tTSV}->{tsv_land}->{id}++;
    
     my $land_port_up = $self->set_graph_port_name($land_name.'/',$self->{tTSV}->{tsv_land}->{up},$land_module);
     my $land_port_dn = $self->set_graph_port_name($land_name.'/',$self->{tTSV}->{tsv_land}->{down},$land_module);
     my $land_cname   = $self->set_graph_module_name($land_name.'/',$land_module);
    
     my $land_up_pwr  = $macro_list->{$land_module}->{PIN}->{$self->{tTSV}->{tsv_land}->{up}}->{POWER}   || 0;
     my $land_dn_pwr  = $macro_list->{$land_module}->{PIN}->{$self->{tTSV}->{tsv_land}->{down}}->{POWER} || 0;
     my $land_area    = $macro_list->{$land_module}->{AREA} || 0;
     my $land_type    = $macro_list->{$land_module}->{TYPE};
    
        # @ TSV_LAND/DN vertex
    $self->{Graph_list}->set_time_weighted_vertex($land_port_dn,0);
    $self->{Graph_list}->set_time_logic_vertex($land_port_dn,'NET');
    $self->{Graph_list}->set_time_power_vertex($land_port_dn,$land_dn_pwr);
    $self->{Graph_list}->set_time_area_vertex($land_port_dn,0);
    $self->{Graph_list}->set_time_layer_vertex($land_port_dn,$layer);
    $self->{Graph_list}->set_time_pass_vertex($land_port_dn,0);
    
    # @ TSV_LAND/::module vertex
    $self->{Graph_list}->set_time_weighted_vertex($land_cname,0);
    $self->{Graph_list}->set_time_logic_vertex($land_cname,$land_type);
    $self->{Graph_list}->set_time_power_vertex($land_cname,0);
    $self->{Graph_list}->set_time_area_vertex($land_cname,$land_area);
    $self->{Graph_list}->set_time_layer_vertex($land_cname,$layer);
    $self->{Graph_list}->set_time_pass_vertex($land_cname,0);
    $self->{Graph_list}->set_time_type_vertex($land_cname,3);

    # @ TSV_LAND/UP vertex
    $self->{Graph_list}->set_time_weighted_vertex($land_port_up,0);
    $self->{Graph_list}->set_time_logic_vertex($land_port_up,'NET');
    $self->{Graph_list}->set_time_power_vertex($land_port_up,$land_up_pwr);
    $self->{Graph_list}->set_time_area_vertex($land_port_up,0);
    $self->{Graph_list}->set_time_layer_vertex($land_port_up,$layer);
    $self->{Graph_list}->set_time_pass_vertex($land_port_up,0);

    if( $direct ==0 ){    
        $self->{Graph_list}->set_time_weighted_edge($land_port_up,$land_cname,0,$land_port_up);
        $self->{Graph_list}->set_time_weighted_edge($land_cname,$land_port_dn,0,$land_port_dn);
    
        $self->{Graph_list}->set_time_type_vertex($land_port_up,0);
        $self->{Graph_list}->set_time_type_vertex($land_port_dn,1);

    } else {
        $self->{Graph_list}->set_time_weighted_edge($land_port_dn,$land_cname,0,$land_port_dn);
        $self->{Graph_list}->set_time_weighted_edge($land_cname,$land_port_up,0,$land_port_up);

        $self->{Graph_list}->set_time_type_vertex($land_port_up,1);
        $self->{Graph_list}->set_time_type_vertex($land_port_dn,0);
     }

    $self->{tsv_land_list}->{$wire}->{$layer}->{down} = $land_port_dn;
    $self->{tsv_land_list}->{$wire}->{$layer}->{up}   = $land_port_up;  
}

sub set_graph_TSV_cell {
    my ($self,$layer,$wire,$direct) = (@_);

    my $macro_list   = $self->{util}->{cell}->{MACRO} || die "PowerArea->set_TSV_LAND_insert(1) error\n";
    my $graph_list   = $self->{Graph_list}            || die "";
    my $util_list    = $self->{util}                  || die "";

     #@ TSV_CELL define
    my $cell_module  = $self->{tTSV}->{tsv_cell}->{name};
    my $cell_name    = $self->{tTSV}->{tsv_cell}->{name}.'_'.$self->{tTSV}->{tsv_cell}->{id}++;
   
    my $cell_port_up = $self->set_graph_port_name($cell_name.'/',$self->{tTSV}->{tsv_cell}->{up},$cell_module);
    my $cell_port_dn = $self->set_graph_port_name($cell_name.'/',$self->{tTSV}->{tsv_cell}->{down},$cell_module);
    my $cell_cname   = $self->set_graph_module_name($cell_name.'/',$cell_module);
   
    my $cell_up_pwr  = $macro_list->{$cell_module}->{PIN}->{$self->{tTSV}->{tsv_cell}->{up}}->{POWER}   || 0;
    my $cell_dn_pwr  = $macro_list->{$cell_module}->{PIN}->{$self->{tTSV}->{tsv_cell}->{down}}->{POWER} || 0;
    my $cell_area    = $macro_list->{$cell_module}->{AREA} || 0;
    my $cell_type    = $macro_list->{$cell_module}->{TYPE};
   
    # @ TSV CELL/DN vertex
    $self->{Graph_list}->set_time_weighted_vertex($cell_port_dn,0);
    $self->{Graph_list}->set_time_logic_vertex($cell_port_dn,'NET');
    $self->{Graph_list}->set_time_power_vertex($cell_port_dn,$cell_dn_pwr);
    $self->{Graph_list}->set_time_area_vertex($cell_port_dn,0);
    $self->{Graph_list}->set_time_layer_vertex($cell_port_dn,$layer);
    $self->{Graph_list}->set_time_pass_vertex($cell_port_dn,0);
    
    # @ TSV_CELL/ module vertex
    $self->{Graph_list}->set_time_weighted_vertex($cell_cname,0);
    $self->{Graph_list}->set_time_logic_vertex($cell_cname,$cell_type);
    $self->{Graph_list}->set_time_power_vertex($cell_cname,0);
    $self->{Graph_list}->set_time_area_vertex($cell_cname,$cell_area);
    $self->{Graph_list}->set_time_layer_vertex($cell_cname,$layer);
    $self->{Graph_list}->set_time_pass_vertex($cell_cname,0);
    $self->{Graph_list}->set_time_type_vertex($cell_cname,3);
    
    # @ TSV_CELL/UP vertex
    $self->{Graph_list}->set_time_weighted_vertex($cell_port_up,0);
    $self->{Graph_list}->set_time_logic_vertex($cell_port_up,'NET');
    $self->{Graph_list}->set_time_power_vertex($cell_port_up,$cell_up_pwr);
    $self->{Graph_list}->set_time_area_vertex($cell_port_up,0);
    $self->{Graph_list}->set_time_layer_vertex($cell_port_up,$layer);
    $self->{Graph_list}->set_time_pass_vertex($cell_port_up,0);
 
   if( $direct ==0 ){ 
       $self->{Graph_list}->set_time_weighted_edge($cell_port_up,$cell_cname,0,$cell_port_up);
       $self->{Graph_list}->set_time_weighted_edge($cell_cname,$cell_port_dn,0,$cell_port_dn);

       $self->{Graph_list}->set_time_type_vertex($cell_port_up,0);
       $self->{Graph_list}->set_time_type_vertex($cell_port_dn,1);
 
   } else {
       $self->{Graph_list}->set_time_weighted_edge($cell_port_dn,$cell_cname,0,$cell_port_dn);
       $self->{Graph_list}->set_time_weighted_edge($cell_cname,$cell_port_up,0,$cell_port_up);

       $self->{Graph_list}->set_time_type_vertex($cell_port_up,1);
       $self->{Graph_list}->set_time_type_vertex($cell_port_dn,0);
   }

   $self->{tsv_cell_list}->{$wire}->{$layer}->{down} = $cell_port_dn;
   $self->{tsv_cell_list}->{$wire}->{$layer}->{up}   = $cell_port_up;   
}

1;
