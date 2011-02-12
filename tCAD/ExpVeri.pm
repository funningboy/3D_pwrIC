#!/usr/bin/perl

package tCAD::ExpVeri;
use tCAD::PowerArea;
use tCAD::util;
use Data::Dumper;
use File::Path qw(make_path remove_tree);
use strict;

sub new {
 my $class = shift;
 my $self = { 
              layer_veri_list => {},
              layer_rst_list  => {},
              cell_port_list  => [],
              IC3DiGA         => shift || die "ExpVeri->IC3DiGA error\n", 
            }; 
 bless $self, $class;
 return $self;
}

sub get_layer_module_name {
    my ($self,$top,$layer) = (@_);
return $top.'_L'.$layer; 
}

sub set_exp_cell_port_name {
    my ($self,$port,$wire) = (@_);
return ' .'.$port.'('.$wire.')';       
}
 
sub run_Exp_cluster_DD {
    my ($self,$top) = (@_);

    my $top_list    = $self->{IC3DiGA}->{pwr_area_list}->{top_list}               || die "ExpVeri->run_Exp_cluster_DD(1) error\n";
    my $graph_list  = $self->{IC3DiGA}->{pwr_area_list}->{top_list}->{Graph_list} || die "ExpVeri->run_Exp_cluster_DD(2) error\n";
    my $util_list   = $self->{IC3DiGA}->{pwr_area_list}->{top_list}->{util}       || die "ExpVeri->run_Exp_cluster_DD(3) error\n";

    my $power_list  = $self->{IC3DiGA}->{pwr_area_list}->{irst_list}->{power}     || die "ExpVeri->run_Exp_cluster_DD(4) error\n"; 
    my $area_list   = $self->{IC3DiGA}->{pwr_area_list}->{irst_list}->{area}      || die "ExpVeri->run_Exp_cluster_DD(5) error\n";

    my $vex_list    = $graph_list->get_all_vertices();
 
    foreach my $vex (@{$vex_list}){
               $self->{cell_port_list} = [];

            if( $top_list->is_graph_module_exist($vex)==0 ){
            my $module     = $top_list->get_graph_module_name($vex);
            my $cell       = $top_list->get_graph_cell_name($vex);
               $cell       =~ s/\//\_/g;
            my $vex_layer  = $graph_list->get_time_layer_vertex($vex);

            my $level_list = $top_list->get_graph_cell_level($cell);
              
            my $pre_port_list = $graph_list->get_vertex_pre_stack($vex);
            my $nxt_port_list = $graph_list->get_vertex_nxt_stack($vex);

            foreach my $pre_port (@{$pre_port_list}){
                    my $pre_cont_list  = $graph_list->get_vertex_pre_stack($pre_port);
                    my $pre_port_layer = $graph_list->get_time_layer_vertex($pre_port);
 
                   foreach my $pre_cont (@{$pre_cont_list}){
                           my $wire_name = $graph_list->get_time_weighted_edge_name($pre_cont,$pre_port) ||
                                           $graph_list->get_time_weighted_edge_name($pre_port,$pre_cont);

                           my $pre_cont_layer = $graph_list->get_time_layer_vertex($pre_cont);
                           my $port_name      = $top_list->get_graph_port_name($pre_port);

                           if( (($pre_cont_layer != $pre_port_layer) && $graph_list->get_time_type_vertex($pre_port)==0)){
 
                           my $cell_port_name = $self->set_exp_cell_port_name($port_name,$wire_name.'_IN');
                           push (@{$self->{cell_port_list}},$cell_port_name);
                           push (@{$self->{layer_veri_list}->{$pre_port_layer}->{input_list}},$wire_name.'_IN_'.$pre_cont_layer.$pre_port_layer);

                       } elsif( (($pre_cont_layer != $pre_port_layer) && $graph_list->get_time_type_vertex($pre_port)==1)){

                           my $cell_port_name = $self->set_exp_cell_port_name($port_name,$wire_name.'_OUT');
                           push (@{$self->{cell_port_list}},$cell_port_name);
                           push (@{$self->{layer_veri_list}->{$pre_port_layer}->{output_list}},$wire_name.'_OUT_'.$pre_port_layer.$pre_cont_layer);

                       } else {
                           my $cell_port_name = $self->set_exp_cell_port_name($port_name,$wire_name);
                           push (@{$self->{cell_port_list}},$cell_port_name);
                       }
                  } 
            } 


            foreach my $nxt_port (@{$nxt_port_list}){
                    my $nxt_cont_list  = $graph_list->get_vertex_nxt_stack($nxt_port);
                    my $nxt_port_layer = $graph_list->get_time_layer_vertex($nxt_port);
 
                   foreach my $nxt_cont (@{$nxt_cont_list}){
                           my $wire_name = $graph_list->get_time_weighted_edge_name($nxt_cont,$nxt_port) ||
                                           $graph_list->get_time_weighted_edge_name($nxt_port,$nxt_cont);


                           my $nxt_cont_layer = $graph_list->get_time_layer_vertex($nxt_cont);
                           my $port_name      = $top_list->get_graph_port_name($nxt_port);

                           if( (($nxt_cont_layer != $nxt_port_layer) && $graph_list->get_time_type_vertex($nxt_port)==0)){

                           my $cell_port_name = $self->set_exp_cell_port_name($port_name,$wire_name.'_IN');
                           push (@{$self->{cell_port_list}},$cell_port_name);
                           push (@{$self->{layer_veri_list}->{$nxt_port_layer}->{input_list}},$wire_name.'_IN_'.$nxt_cont_layer.$nxt_port_layer);

                       } elsif( (($nxt_cont_layer != $nxt_port_layer) && $graph_list->get_time_type_vertex($nxt_port)==1)){

                           my $cell_port_name = $self->set_exp_cell_port_name($port_name,$wire_name.'_OUT');
                           push (@{$self->{cell_port_list}},$cell_port_name);
                           push (@{$self->{layer_veri_list}->{$nxt_port_layer}->{output_list}},$wire_name.'_OUT_'.$nxt_port_layer.$nxt_cont_layer);

                       } else {
                           my $cell_port_name = $self->set_exp_cell_port_name($port_name,$wire_name);
                           push (@{$self->{cell_port_list}},$cell_port_name);
                       }

                  } 
            } 

       push (@{$self->{layer_veri_list}->{$vex_layer}->{cell_list}}, { cell_name     => $cell,
                                                                       module_name   => $module, 
                                                                       interface_list=> $self->{cell_port_list} });
   }
 }
}


sub run_Exp_Veri_DD {
    my ($self,$top) = (@_);

    my $layer_veri_list = $self->{layer_veri_list};

    foreach my $layer (keys %{$layer_veri_list}){
#            if ($layer >0 ){
            my $top_layer = $self->get_layer_module_name($top,$layer);
          
            my %seen =();
            my @input_layer_list = grep { !$seen{$_}++ } @{$layer_veri_list->{$layer}->{input_list}};
               %seen =();
            my @output_layer_list = grep { !$seen{$_}++ } @{$layer_veri_list->{$layer}->{output_list}};
 
            my $top_input = join(' ,',@input_layer_list);
            my $top_output= join(' ,',@output_layer_list);

               $top_input  =~ s/\_IN\_(\w+)/\_IN/g;
               $top_output =~ s/\_OUT\_(\w+)/\_OUT/g;

            ####?????
            if( defined($top_layer)) { $self->{layer_rst_list}->{$layer} .= 'module '.$top_layer.' ('.$top_output.','.$top_input.');'."\n\n"; }
            if( defined($top_output)){ $self->{layer_rst_list}->{$layer} .= 'output '.$top_output.';'."\n\n"; }
            if( defined($top_input)) { $self->{layer_rst_list}->{$layer} .= 'input '.$top_input.';'."\n\n";   }
          
            my @cell_sort_list = sort { $a->{module_name} cmp $b->{module_name} } @{$layer_veri_list->{$layer}->{cell_list}};

            foreach my $cell (@cell_sort_list){
                       %seen =();
                    my @interface_list = grep { !$seen{$_}++ } @{$cell->{interface_list}};
                    my $interface = join(' ,',@interface_list);

                    if( defined($top_layer)){ $self->{layer_rst_list}->{$layer} .= $cell->{module_name}.' '.$cell->{cell_name}.' ('.$interface.' );'."\n"; }
            }
            if( defined($top_layer)){ $self->{layer_rst_list}->{$layer} .= 'endmodule'."\n"; }
#        }
    }
}


sub run_Exp_path_DD {
    my ($self,$top) = (@_);
  
    my $layer_rst_list = $self->{layer_rst_list};
    my $rpt_path       = './rpt/';
 
   if( !-e $rpt_path ){
      make_path($rpt_path);
   }

   foreach my $layer (keys %{$layer_rst_list}){
           my $file = $rpt_path.$top.'_L'.$layer.'.v';
        open (OUTPTR,">$file") || die "ExpVeri->run_Exp_path_DD open file error\n";

        print OUTPTR $layer_rst_list->{$layer};
        close(OUTPTR);
  }
}

sub run_Exp_top_DD {
    my ($self,$top) = (@_);

    my $top_list        = $self->{IC3DiGA}->{pwr_area_list}->{top_list}                || die "ExpVeri->run_Exp_top_DD(1) error\n";
    my $graph_list      = $self->{IC3DiGA}->{pwr_area_list}->{top_list}->{Graph_list}  || die "ExpVeri->run_Exp_top_DD(2) error\n";
    my $util_list       = $self->{IC3DiGA}->{pwr_area_list}->{top_list}->{util}        || die "ExpVeri->run_Exp_top_DD(3) error\n";

    my $layer_veri_list = $self->{layer_veri_list};
    my $input_list      = $graph_list->get_input_lists();
    my $output_list     = $graph_list->get_output_lists();
 
    my @input_layer_list  = ();
    my @output_layer_list = ();

    foreach my $input (@{$input_list}){
            my $in_port = $top_list->get_graph_port_name($input);
            push (@input_layer_list,$in_port);
    }

    foreach my $output (@{$output_list}){
            my $out_port = $top_list->get_graph_port_name($output);
            push (@output_layer_list,$out_port);
    }

    my $top_input = join(' ,',@input_layer_list);
    my $top_output= join(' ,',@output_layer_list);

    if( defined($top))       { $self->{layer_rst_list}->{top} .= 'module '.'_ic3d_top_'.' ('.$top_output.','.$top_input.');'."\n\n"; }
    if( defined($top_output)){ $self->{layer_rst_list}->{top} .= 'output '.$top_output.';'."\n\n"; }
    if( defined($top_input)) { $self->{layer_rst_list}->{top} .= 'input '.$top_input.';'."\n\n";   }

    foreach my $layer (sort keys %{$layer_veri_list}){
            my @interface_list    = ();

#            if( $layer > 0 ){
            my $cell_module = $self->get_layer_module_name($top,$layer);
            my $cell_name   = 'i_'.$cell_module;

            my %seen =();
            my @input_layer_list = grep { !$seen{$_}++ } @{$layer_veri_list->{$layer}->{input_list}};
            my %seen =();
            my @output_layer_list = grep { !$seen{$_}++ } @{$layer_veri_list->{$layer}->{output_list}};
 
           if( defined($top)) {
               my ($in_port,$out_port);
                  
               foreach my $input (@input_layer_list){
                          $in_port = $input;
                          $in_port =~ s/\_IN//g;
                          $input   =~ s/\_IN_(\w+)/\_IN/g;
                       my $cell_input = $self->set_exp_cell_port_name($input,$in_port);
                       push (@interface_list,$cell_input);
               }

               foreach my $output (@output_layer_list){
                          $out_port = $output;
                          $out_port =~ s/\_OUT//g;
                          $output   =~ s/\_OUT_(\w+)/\_OUT/g;
                       my $cell_output = $self->set_exp_cell_port_name($output,$out_port);
                       push (@interface_list,$cell_output);
               }

               my %seen =();
               my @interface_list = grep { !$seen{$_}++ } @interface_list;
               my $interface = join(' ,',@interface_list);

                    $self->{layer_rst_list}->{top} .= $cell_module.' '.$cell_name.' ('.$interface.' );'."\n\n"; 
 #          }  
        }
    }

   if( defined($top)){   $self->{layer_rst_list}->{top} .= 'endmodule'."\n"; }
}

sub run_Exp_DFG2Veri_DD {
    my ($self,$top) = (@_);

    $self->run_Exp_cluster_DD($top);
    $self->run_Exp_Veri_DD($top); 
    $self->run_Exp_top_DD($top);
    $self->run_Exp_path_DD($top);
}

sub get_debug {
    my ($self) = (@_);
#print Dumper($self->{IC3DiGA}->{pwr_area_list}->{top_list}->{Graph_list});

}

sub free {
    my ($self) = (@_);

    $self->{layer_veri_list} = {};
    $self->{layer_rst_list}  = {};
    $self->{cell_port_list}  = []; 
}

1;
