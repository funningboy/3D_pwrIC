#! /usr/bin/perl

package tCAD::util;
use Data::Dumper;

use strict;

sub new {
     my $class = shift;
     my $self  = {
                   bench          => {},
                   verilog        => {},
                   cell           => {}, 
                   top_down_list  => {},
                   top_down_level => 0,
                   top_down_stack => [],
                };
     bless $self, $class;
     return $self;
}

sub set_bench_DD {
    my ($self,$bench) = (@_);
    if( !%{$bench} ){ die "util->set_bench_DD error\n"; }
    $self->{bench} = $bench;
}

sub set_verilog_DD {
    my ($self,$veri) = (@_);
    if( !%{$veri} ){ die "util->set_verilog_DD error\n"; }
    $self->{verilog} = $veri;
}

sub set_cell_DD {
    my ($self,$cell) = (@_);
    if( !%{$cell} ){ die "util->set_cell_DD error\n"; }
    $self->{cell} = $cell;
}

sub is_top_down_stack_empty {
   my ($self) = (@_);
   if( !@{$self->{top_down_stack}} ){ return 0; }
return -1;
}

sub push_top_down_stack {
   my ($self,$name) = (@_);
       push( @{$self->{top_down_stack}},$name);
}

sub pop_top_down_stack {
   my ($self) = (@_);
return pop( @{$self->{top_down_stack}} );
}

sub get_top_top_down_stack {
    my ($self) = (@_);
    my @tmp_st = @{$self->{top_down_stack}}; 
return  $tmp_st[$#tmp_st];
}

#=============================
# @ Root =0 
#=============================
sub get_top_down_deep {
    my ($self) = (@_);
    if( $self->is_top_down_stack_empty() ==0 ){ return 0; }
    my @tmp_st = @{$self->{top_down_stack}};
return  $#tmp_st+1;
}

sub get_top_down_name {
   my ($self) = (@_);
   my $st = join('/',@{$self->{top_down_stack}});
   if(!$st) { return (); }
return $st.'/'; 
}

sub push_top_down_list {
    my ($self,$lvl,$name) = (@_);
    push (@{$self->{top_down_list}->{$lvl}},$name);
}

sub get_top_down_list {
    my ($self) = (@_);
return $self->{top_down_list};  
}

sub get_input_list_by_module {
    my ($self,$module) = (@_);

    my $top_list = $self->{verilog};
    my $in_list = [];
 
    foreach my $lv_1 ( @{$top_list->{$module}->{input}} ){     
         push ( @{$in_list}, $lv_1 );  
   }   
return $in_list;
}

sub get_output_list_by_module {
    my ($self,$module) = (@_);

    my $top_list = $self->{verilog};
    my $out_list = [];
 
    foreach my $lv_1 ( @{$top_list->{$module}->{output}} ){     
         push ( @{$out_list}, $lv_1 );  
   }   
return $out_list;
}

sub get_wire_list_by_module {
    my ($self,$module) = (@_);

    my $top_list = $self->{verilog};
    my $wire_list = [];
 
    foreach my $lv_1 ( @{$top_list->{$module}->{wire}} ){     
         push ( @{$wire_list}, $lv_1 );  
   }   
return $wire_list;
}

sub get_cell_list_by_module {
    my ($self,$top) = (@_);
    
    my $top_list  = $self->{verilog};
    my $cell_list = $top_list->{$top}->{cell};
 
return $cell_list;
}

sub is_output_exist_by_module {
    my ($self,$out,$module) = (@_);

    my $out_list = $self->get_output_list_by_module($module);

   foreach my $lv_1 ( @{$out_list} ){     
          if( $out eq $lv_1 ){ return 0; } 
   }

return -1;
}

sub is_input_exist_by_module {
    my ($self,$in,$module) = (@_);

    my $in_list = $self->get_input_list_by_module($module);
   
    foreach my $lv_1 ( @{$in_list} ){ 
          if( $in eq $lv_1 ){ return 0; } 
      }

return -1;        
}

sub is_wire_exist_by_module {
    my ($self,$wire,$module) = (@_);

    my $wire_list = $self->get_wire_list_by_module($module);

   foreach my $lv_1 ( @{$wire_list} ){     
          if( $wire eq $lv_1 ){ return 0; } 
   }

return -1;        
}

#==================================
# define cell
#==================================
sub is_cell_module_deep {
    my ($self,$cell) = (@_);
    if( defined($self->{cell}->{MACRO}->{$cell}) ){ return 0; }
return -1;
}

#=================================
# DFS 2 top_down_list 
#=================================
sub run_top_down_list {
    my ($self,$top) = (@_);

    if( $self->is_cell_module_deep($top)!=0 ){

        my $name =  $self->get_top_down_name();
        my $lvl  =  $self->get_top_down_deep();

    $self->push_top_down_list($lvl,{ cell_name => $name,
                                     cell_module=> $top}); 
    }

    my $cell_list = $self->get_cell_list_by_module($top);

    foreach my $cell (@{$cell_list}){
       my $cell_name   = $cell->{cell_name};
       my $cell_module = $cell->{cell_module};
    
       $self->push_top_down_stack($cell_name);
       $self->run_top_down_list($cell_module);
       $self->pop_top_down_stack();
    }
}

sub check_top_down_list {
   my ($self,$name) = (@_); 
   my $top_dwn_list =  $self->{top_down_list};

   my @level = keys %{$top_dwn_list} || die "util->check_top_down_list(1) error\n";
   if( $#level>0 ) { die "we only support the flatten design\n"; }
}


sub get_top_down_level {
    my ($self,$name) = (@_);
    my @tmp_st = split('/',$name); 
return $#tmp_st;
}

#==========================
# 2 space to 1 space array
#==========================
sub get_check_input {
    my ($self) = (@_);
    my $veri_list = $self->{verilog};
 
   foreach my $veri ( keys %{$veri_list} ){
            my $input_list = $veri_list->{$veri}->{input};
            my $new_input_list = [];

             foreach my $input_1 ( @{$input_list}){
                foreach my $input_2 ( @{$input_1} ){
                    push (@{$new_input_list}, $input_2);
                }
             }
     $self->{verilog}->{$veri}->{input} = $new_input_list;
   }

}

sub get_check_output {
    my ($self) = (@_);
    my $veri_list = $self->{verilog};
 
   foreach my $veri ( keys %{$veri_list} ){
            my $output_list = $veri_list->{$veri}->{output};
            my $new_output_list = [];

             foreach my $output_1 ( @{$output_list}){
                foreach my $output_2 ( @{$output_1} ){
                    push (@{$new_output_list}, $output_2);
                }
             }
     $self->{verilog}->{$veri}->{output} = $new_output_list;
   }
}

sub get_check_wire {
    my ($self) = (@_);
    my $veri_list = $self->{verilog};
 
   foreach my $veri ( keys %{$veri_list} ){
            my $wire_list = $veri_list->{$veri}->{wire};
            my $new_wire_list = [];

             foreach my $wire_1 ( @{$wire_list}){
                foreach my $wire_2 ( @{$wire_1} ){
                    push (@{$new_wire_list}, $wire_2);
                }
             }
     $self->{verilog}->{$veri}->{wire} = $new_wire_list;
   }
}


sub get_cell_2_verilog {
    my ($self) = (@_);
    my  $macro_list = $self->{cell}->{MACRO};

    foreach my $macro (keys %{$macro_list}){
       my  $macro_tb = {};

       foreach my $pin (keys %{$macro_list->{$macro}->{PIN}}){
               if( $macro_list->{$macro}->{PIN}->{$pin}->{DIRECTION} eq 'INPUT' ){
                   push (@{$macro_tb->{INPUT}}, $pin);
                } else {
                   push (@{$macro_tb->{OUTPUT}}, $pin);
                }  
       }
       
        @{$self->{verilog}->{$macro}->{input}}  = $macro_tb->{INPUT};
        @{$self->{verilog}->{$macro}->{output}} = $macro_tb->{OUTPUT};

    }
}

sub get_check_rst {
    my ($self,$top) = (@_);

        $self->get_cell_2_verilog();
        $self->get_check_input();
        $self->get_check_output();
        $self->get_check_wire();
        $self->run_top_down_list($top);
        # only support flat design 
        $self->check_top_down_list();
}

sub get_debug {
    my ($self) = (@_);

#print Dumper($self->{cell}->{MACRO});
#print Dumper($self->{verilog});
#print Dumper($self->get_top_down_list());
#print Dumper($self->{cell});
#die;
} 

sub free {
    my ($self) = (@_);

  $self->{top_down_stack} = [];
}

1;
