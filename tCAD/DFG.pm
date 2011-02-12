#!/usr/bin/perl

package tCAD::DFG;
use Graph;
use Graph::Easy;
use Data::Dumper;
use strict;

sub new {
 my $class = shift;
 my $self = { Graph_list  => Graph->new(),
              logic_list  => {},
              power_list  => {},
              area_list   => {},
              layer_list  => {},
              pass_list   => {},
              type_list   => {}, #0:input, 1:output, 2:inout, 3:module
              Vertex_list => {},
              input_list  => [],
              output_list => [],
            }; 
 bless $self, $class;
 return $self;
}


sub get_all_edges {
   my ($self) = (@_);
   my @arr = $self->{Graph_list}->edges();
return \@arr;
}

sub get_all_vertices {
   my ($self) = (@_);
   my @arr = $self->{Graph_list}->vertices();
return \@arr;
}

sub dump_time_weighted_vertices {
    my ($self) = (@_);

    my $arr = $self->get_all_vertices();
    my @arr = @{$arr};

    foreach my $vex (@arr){
     my $tm = $self->get_time_weighted_vertex($vex);
     print $vex." , ".$tm."\n";
   }
}

sub dump_time_weighted_edges {
   my ($self) = (@_);

  my $arr = $self->get_all_edges();
  my @arr = @{$arr};

  foreach my $edg (@arr){
   my $tm = $self->get_time_weighted_edge($edg->[0],$edg->[1]);
   print $edg->[0]." , ".$edg->[1].' , '.$tm."\n";
 }
}

sub is_input_list_empty {
   my ($self) = (@_);
   if( !@{$self->{input_list}}){ return 0; }
return -1;
}

sub push_input_list {
   my ($self,$vertex) = (@_);
       push (@{$self->{input_list}},$vertex);
}

sub pop_input_list {
   my ($self) = (@_);
return pop (@{$self->{input_list}});
}

sub set_input_lists {
   my ($self,$arr) = (@_);
       @{$self->{input_list}} = @{$arr};
}

sub get_input_lists {
   my ($self) = (@_);
return $self->{input_list};
}

sub is_input_list_exist {
    my ($self,$begin) = (@_);
    my @arr = @{$self->{input_list}};
    for(my $i=0; $i<=$#arr; $i++){
       if( $arr[$i] eq $begin){ return 0; last; }
   }

return -1;
}

sub is_output_list_empty {
   my ($self) = (@_);
   if( !@{$self->{output_list}}){ return 0; }
return -1;
}

sub push_output_list {
   my ($self,$vertex) = (@_);
       push (@{$self->{output_list}},$vertex);
}

sub pop_output_list {
   my ($self) = (@_);
return pop (@{$self->{output_list}});
}

sub set_output_lists {
   my ($self,$arr) = (@_);
       @{$self->{output_list}} = @{$arr};
}

sub get_output_lists {
   my ($self) = (@_);
return $self->{output_list};
}

sub is_output_list_exist {
    my ($self,$end) = (@_);
    my @arr = @{$self->{output_list}};
    for(my $i=0; $i<=$#arr; $i++){
       if( $arr[$i] eq $end){ return 0; last; }
   }

return -1;
}


sub is_vertex_pre_stack_empty {
    my ($self,$vertex) = (@_);
    if (   !$self->{Vertex_list}->{pre}->{$vertex} ||
         !@{$self->{Vertex_list}->{pre}->{$vertex}} ){ return 0; }

return -1;
}

sub push_vertex_pre_stack {
    my ($self,$vertex,$pre) = (@_);
        push (@{$self->{Vertex_list}->{pre}->{$vertex}},$pre);
}

sub pop_vertex_pre_stack {
    my ($self,$vertex) = (@_);
return pop (@{$self->{Vertex_list}->{pre}->{$vertex}});
}

sub shft_vertex_pre_stack {
    my ($self,$vertex) = (@_);
return shift (@{$self->{Vertex_list}->{pre}->{$vertex}}); 
}

sub del_vertex_pre_stack {
    my ($self,$vertex,$pre) = (@_);
    my @tmp;
    my @arr;
 
   if ( $self->is_vertex_pre_stack_empty($vertex)!=0 ){
        @arr = @{$self->{Vertex_list}->{pre}->{$vertex}};
 
     for(my $i=0; $i<=$#arr; $i++){
        if( $arr[$i] eq $pre ){
            delete $self->{Vertex_list}->{pre}->{$vertex}->[$i];
        }
      }

     #remove undef
     foreach my $ky (@{$self->{Vertex_list}->{pre}->{$vertex}}){
       if(defined($ky)){ 
         push (@tmp,$ky);
      }
    }
   
   @{$self->{Vertex_list}->{pre}->{$vertex}} = @tmp;
  }
 
}


sub get_vertex_pre_stack {
    my ($self,$vertex) = (@_);
return $self->{Vertex_list}->{pre}->{$vertex};
}

sub get_vertex_pre_stacks {
   my ($self) = (@_);
return $self->{Vertex_list}->{pre};
}

sub set_vertex_pre_stacks {
   my ($self,$arr) = (@_);
      foreach my $ky (keys %{$arr}){ 
        @{$self->{Vertex_list}->{pre}->{$ky}} = @{$arr->{$ky}};
  }
}

sub is_vertex_nxt_stack_empty {
    my ($self,$vertex) = (@_);
    if (   !$self->{Vertex_list}->{nxt}->{$vertex}  ||
         !@{$self->{Vertex_list}->{nxt}->{$vertex}} ){ return 0; }

return -1;
}

sub push_vertex_nxt_stack {
    my ($self,$vertex,$nxt) = (@_);
        push (@{$self->{Vertex_list}->{nxt}->{$vertex}},$nxt);
}

sub pop_vertex_nxt_stack {
    my ($self,$vertex) = (@_);
return pop (@{$self->{Vertex_list}->{nxt}->{$vertex}});
}

sub shft_vertex_nxt_stack {
    my ($self,$vertex) = (@_);
return shift (@{$self->{Vertex_list}->{nxt}->{$vertex}});
}

sub del_vertex_nxt_stack {
    my ($self,$vertex,$nxt) = (@_);
    my @tmp;
    my @arr;
 
   if ( $self->is_vertex_nxt_stack_empty($vertex)!=0 ){
        @arr = @{$self->{Vertex_list}->{nxt}->{$vertex}};
 
     for(my $i=0; $i<=$#arr; $i++){
        if( $arr[$i] eq $nxt ){
            delete $self->{Vertex_list}->{nxt}->{$vertex}->[$i];
        }
      }

     foreach my $ky (@{$self->{Vertex_list}->{nxt}->{$vertex}}){
       if(defined($ky)){ 
         push (@tmp,$ky);
      }
    }
   
   @{$self->{Vertex_list}->{nxt}->{$vertex}} = @tmp;
  }
}

sub get_vertex_nxt_stack {
    my ($self,$vertex) = (@_);
return $self->{Vertex_list}->{nxt}->{$vertex};
}

sub set_vertex_nxt_stacks {
   my ($self,$arr) = (@_);
   foreach my $ky (keys %{$arr}){
      @{$self->{Vertex_list}->{nxt}->{$ky}} = @{$arr->{$ky}}; 
  }
}

sub get_vertex_nxt_stacks {
   my ($self) = (@_);
return $self->{Vertex_list}->{nxt}; 
}


sub is_time_weighted_edge_exist {
    my ($self,$src,$dst) = (@_);
return $self->{Graph_list}->has_edge($src,$dst);
}

sub set_time_weighted_edge {
    my ($self,$src,$dst,$weight,$name) = (@_);
    $self->{Graph_list}->add_edge($src,$dst);
    $self->{Graph_list}->add_weighted_edge($src,$dst,$weight);
    $self->push_vertex_pre_stack($dst,$src);
    $self->push_vertex_nxt_stack($src,$dst);

    $self->{Graph_list}->set_edge_attribute($src,$dst,$src.'|'.$dst,$name);
}

sub get_time_weighted_edge_name {
    my ($self,$src,$dst) = (@_);
return $self->{Graph_list}->get_edge_attribute($src,$dst,$src.'|'.$dst); 
}

sub del_time_weighted_edge {
    my ($self,$src,$dst) = (@_);
    $self->{Graph_list}->delete_edge($src,$dst);
    $self->{Graph_list}->delete_edge_weight($src,$dst);
    $self->del_vertex_pre_stack($dst,$src);
    $self->del_vertex_nxt_stack($src,$dst);
}

sub updt_time_weighted_edge {
    my ($self,$src,$dst) = (@_);
    $self->{Graph_list}->set_edge_weight($src,$dst);
}

sub get_time_weighted_edge {
    my ($self,$src,$dst) = (@_);
    return $self->{Graph_list}->get_edge_weight($src,$dst);
}

sub clr_time_weighted_edges {
    my ($self) = (@_);

  my $arr = $self->get_all_edges();
  my @arr = @{$arr};

  foreach my $edg (@arr){
   my $tm = $self->set_time_weighted_edge($edg->[0],$edg->[1],0);
 }

}

sub set_time_power_vertex {
    my ($self,$vertex,$power) = (@_);
        $self->{power_list}->{$vertex} = $power;
}

sub get_time_power_vertex {
    my ($self,$vertex) = (@_);
return $self->{power_list}->{$vertex};
}

sub set_time_area_vertex {
    my ($self,$vertex,$area) = (@_);
        $self->{area_list}->{$vertex} = $area;
}

sub get_time_area_vertex {
    my ($self,$vertex) = (@_);
return $self->{area_list}->{$vertex};
}

sub set_time_layer_vertex {
    my ($self,$vertex,$layer) = (@_);
        $self->{layer_list}->{$vertex} = $layer;
}

sub get_time_layer_vertex {
    my ($self,$vertex) = (@_);
return $self->{layer_list}->{$vertex};
}

sub set_time_pass_vertex {
    my ($self,$vertex,$pass) = (@_);
        $self->{pass_list}->{$vertex} = $pass;
}

sub get_time_pass_vertex {
    my ($self,$vertex) = (@_);
return  $self->{pass_list}->{$vertex};
}

sub set_time_logic_vertex {
    my ($self,$vertex,$logic) = (@_);
        $self->{logic_list}->{$vertex} = $logic;
}

sub get_time_logic_vertex {
    my ($self,$vertex) = (@_);
return $self->{logic_list}->{$vertex};
}

sub set_time_type_vertex {
    my ($self,$vertex,$type) = (@_);
        $self->{type_list}->{$vertex} = $type;
}

sub get_time_type_vertex {
    my ($self,$vertex) = (@_);
return  $self->{type_list}->{$vertex};
}

sub set_time_weighted_vertex {
    my ($self,$vertex,$weight) = (@_);
    $self->{Graph_list}->add_vertex($vertex);
    $self->{Graph_list}->add_weighted_vertex($vertex,$weight);
}

sub del_time_weighted_vertex {
    my ($self,$vertex) = (@_);
    $self->{Graph_list}->delete_vertex($vertex);
    $self->{Graph_list}->delete_vertex_weight($vertex);
}

sub updt_time_weighted_vertex {
    my ($self,$vertex,$weight) = (@_);
    $self->{Graph_list}->set_vertex_weight($vertex,$weight);
}

sub get_time_weighted_vertex {
    my ($self,$vertex) = (@_);
    return $self->{Graph_list}->get_vertex_weight($vertex);
}

sub clr_time_weighted_vertices { 
    my ($self) = (@_);

    my $arr = $self->get_all_vertices();
    my @arr = @{$arr};

    foreach my $vex (@arr){
     my $tm = $self->set_time_weighted_vertex($vex,0);
   }
}

sub clr_time_logic_vertices { 
    my ($self) = (@_);

    my $arr = $self->get_all_vertices();
    my @arr = @{$arr};

    foreach my $vex (@arr){
     my $lgic = ($vex =~ /\:\:(\w+)/)? $1 : 'x'; 
     my $tm   = $self->set_time_logic_vertex($vex,$lgic);
   }
}

sub dump_graph {
   my ($self) = (@_);
   print $self->{Graph_list}."\n";
}

sub dump_vertex_pre_stack {
   my ($self,$vertex) = (@_);
   print Dumper( $self->{Vertex_list}->{pre}->{$vertex} );
}

sub get_deep_copy_DFG {
   my ($self) = (@_);
return $self;
}

sub get_deep_copy_graph {
   my ($self) = (@_);
return $self->{Graph_list}->deep_copy_graph();
}

sub get_directed_copy_graph {
  my ($self) = (@_);
return $self->{Graph_list}->directed_copy_graph();
}

sub dump_graph_ascii {
   my ($self) = (@_);

   my $all_vet = $self->get_all_vertices();
   my $all_edg = $self->get_all_edges();

   my $tt = Graph::Easy->new();
   foreach (@{$all_vet}){
      $tt->add_node($_);
   }

   foreach (@{$all_edg}){
     my @arr = @{$_};
     $tt->add_edge($arr[0],$arr[1]);
  }

  print $tt->as_ascii();
}

sub dump_graphviz_file {
   my ($self,$path) = (@_);

   my $all_vet = $self->get_all_vertices();
   my $all_edg = $self->get_all_edges();

   my $tt = Graph::Easy->new();
   foreach (@{$all_vet}){
      $tt->add_node($_);
   }

   foreach (@{$all_edg}){
     my @arr = @{$_};
     $tt->add_edge($arr[0],$arr[1]);
  }
      open (optr,">$path") || die "open $path error\n";
      print optr $tt->as_graphviz_file();

close(optr);
}

sub get_a_cycle_list {
    my ($self) = (@_);
    my  @cyc_list = $self->{Graph_list}->find_a_cycle();
return \@cyc_list;
}

sub get_debug {
    my ($self) = (@_);
}

sub free {
   my ($self) = (@_);

# $self->{Begin_list} = [];
# $self->{End_list} = [];
}

1;
