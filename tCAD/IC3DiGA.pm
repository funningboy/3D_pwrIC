#!/usr/bin/perl

package tCAD::IC3DiGA;
use tCAD::PowerArea;
use tCAD::util;
use tCAD::tTSV;
use tCAD::tPAD;
use Data::Dumper;
use strict;

sub new {
 my $class = shift;
 my $self = {  
               power_ratio        => '0.8',
               connect_ratio      => '0',
               target_area        => '0',
               cons_power_density => {},
               cons_feedback      => {},
               power_density_list => {},
               tsv_land_list      => {},
               tsv_cell_list      => {},
               fit_list           => {},
               best_list          => [],
               ready_list         => [],
               GA_alg_list        => { ini_population => '1',
                                       mutation_rate  => '0.5',
                                       min_fitness    => '0.7',
                                       max_population => '500',
                                       end_generation => '1',
                                       cur_generation => '0',
                                       multi_parent   => '3',
 
                                       gene      => {},
                                       gene_list => {},
                                     },
              tTSV               => tCAD::tTSV->new(),
              tPAD               => tCAD::tPAD->new(),
              pwr_area_list      => shift || die "IC3D->pwr_area_list error\n",
            }; 
 bless $self, $class;
 return $self;
}

sub set_tsv_land_hlist {
    my ($self,$layer,$wire,$pre_vex,$cur_vex,$pre_layer,$cur_layer) = (@_);
 
    push( @{$self->{tsv_land_list}->{$wire}->{$layer}->{list}}, { pre_vex   => $pre_vex,
                                                                  pre_layer => $pre_layer,
                                                                  cur_vex   => $cur_vex,
                                                                  cur_layer => $cur_layer,
                                                                 });
}

sub set_tsv_land_clist {
    my ($self,$layer,$wire,$direct) = (@_);

    my $macro_list = $self->{pwr_area_list}->{top_list}->{util}->{cell}->{MACRO} || die "IC3DiGA->set_tsv_land_clist(1) error\n";
 
   if( !defined($self->{tsv_land_list}->{$wire}->{$layer}) ){ 
 
              my $tsv_land_up_pwr = $macro_list->{$self->{tTSV}->{tsv_land}->{name}}->{PIN}->{$self->{tTSV}->{tsv_land}->{up}}->{POWER};
              my $tsv_land_dn_pwr = $macro_list->{$self->{tTSV}->{tsv_land}->{name}}->{PIN}->{$self->{tTSV}->{tsv_land}->{down}}->{POWER};
              my $tsv_land_area   = $macro_list->{$self->{tTSV}->{tsv_land}->{name}}->{AREA};

              $self->{tsv_land_list}->{$wire}->{$layer}->{power}  = $tsv_land_up_pwr + $tsv_land_up_pwr;
              $self->{tsv_land_list}->{$wire}->{$layer}->{area}   = $tsv_land_area;
              $self->{tsv_land_list}->{$wire}->{$layer}->{direct} = $direct;
              $self->{tsv_land_list}->{$wire}->{$layer}->{hit}    = 0;
   } else {
              $self->{tsv_land_list}->{$wire}->{$layer}->{hit}++;
  }
}

sub set_tsv_cell_hlist {
    my ($self,$layer,$wire,$pre_vex,$cur_vex,$pre_layer,$cur_layer) = (@_);

    push( @{$self->{tsv_cell_list}->{$wire}->{$layer}->{list}}, { pre_vex   => $pre_vex,
                                                                  pre_layer => $pre_layer,
                                                                  cur_vex   => $cur_vex,
                                                                  cur_layer => $cur_layer, 
                                                                });
}

sub set_tsv_cell_clist {
    my ($self,$layer,$wire,$direct) = (@_);

    my $macro_list = $self->{pwr_area_list}->{top_list}->{util}->{cell}->{MACRO} || die "IC3DiGA->set_tsv_cell_clist(1) error\n";
   
    if( !defined($self->{tsv_cell_list}->{$wire}->{$layer}) ){ 
              my $tsv_cell_up_pwr = $macro_list->{$self->{tTSV}->{tsv_cell}->{name}}->{PIN}->{$self->{tTSV}->{tsv_cell}->{up}}->{POWER};
              my $tsv_cell_dn_pwr = $macro_list->{$self->{tTSV}->{tsv_cell}->{name}}->{PIN}->{$self->{tTSV}->{tsv_cell}->{down}}->{POWER};
              my $tsv_cell_area   = $macro_list->{$self->{tTSV}->{tsv_cell}->{name}}->{AREA};

              $self->{tsv_cell_list}->{$wire}->{$layer}->{power}  = $tsv_cell_up_pwr + $tsv_cell_up_pwr;
              $self->{tsv_cell_list}->{$wire}->{$layer}->{area}   = $tsv_cell_area;
              $self->{tsv_cell_list}->{$wire}->{$layer}->{direct} = $direct;
              $self->{tsv_cell_list}->{$wire}->{$layer}->{hit}   = 0;
   } else {
              $self->{tsv_cell_list}->{$wire}->{$layer}->{hit}++;
   }
}

sub run_cluster_ini_constrain {
    my ($self) = (@_);

    my $pwr_area_list  = $self->{pwr_area_list}                           || die "IC3DiGA->run_cluster_ini_constrain(1) error\n";
    my $constrain_list = $self->{pwr_area_list}->{top_list}->{util}       || die "IC3DiGA->run_cluster_ini_constrain(2) error\n";
    my $graph_list     = $self->{pwr_area_list}->{top_list}->{Graph_list} || die "IC3DiGA->run_cluster_ini_constrain(3) error\n";

    my $layer_size     = $constrain_list->{bench}->{LAYER};
    my $max_power_list = $constrain_list->{bench}->{MAX_POWER};

    # @ the power density constrain
    for(my $i=$layer_size; $i>=1; $i--){
        my $hit = 0;
        foreach my $max (@{$max_power_list}){
                if( defined($max->{$i}) ){ 
                    my $density = $self->{power_ratio} * $max->{$i}; 
                       $self->{cons_power_density}->{final}->{$i}   = $max->{$i};
                       $self->{cons_power_density}->{current}->{$i} = $density;  $hit =1; last;  }
        }
        if($hit==0){
          if( defined($self->{cons_power_density}->{current}->{$i+1})){
                      $self->{cons_power_density}->{current}->{$i} = $self->{power_ratio} * $self->{cons_power_density}->{current}->{$i+1};
              } else {
                      $self->{cons_power_density}->{current}->{$i} = -1; 
              }
        }   
    }

    # @ the target 
    $self->{target_area}   =  $pwr_area_list->get_core_total_area_by_layer(1) / $layer_size;

    # @ the feedback constrain, same cluster 
    $self->{cons_feedback} = $graph_list->get_a_cycle_list();
}

#
sub run_cluster_BFS_gene {
    my ($self,$layer,$ratio) = (@_);

    my $pwr_area_list = $self->{pwr_area_list}                           || die "IC3DiGA->run_cluster_BFS_gene(1) error\n"; 
    my $area_list     = $self->{pwr_area_list}->{irst_list}->{area}      || die "IC3DiGA->run_cluster_BFS_gene(2) error\n";
    my $graph_list    = $self->{pwr_area_list}->{top_list}->{Graph_list} || die "IC3DiGA->run_cluster_BFS_gene(3) error\n";
   
    my %seen =() ;
    my @unique_list = grep { ! $seen{$_}++ } @{$self->{ready_list}} ;
    @{$self->{ready_list}} = @unique_list;

 while( @{$self->{ready_list}} ){
    my $vertex = shift @{$self->{ready_list}};

   if( $self->{tmp_layer_area} < $ratio * $self->{target_area} ){
 
       $pwr_area_list->set_time_layer_cell_module($vertex,$layer);
       $pwr_area_list->set_time_pass_cell_module($vertex,1);
 
       $self->{tmp_layer_area}  += $area_list->{$vertex}->{area};               

    my $pre_cell_list = $pwr_area_list->get_pre_cell_module_stack($vertex);
    my $nxt_cell_list = $pwr_area_list->get_nxt_cell_module_stack($vertex);

    foreach my $pre_cell (@{$pre_cell_list}){
            my $pass = $graph_list->get_time_pass_vertex($pre_cell);
             if( $pass == 0 ){
                push (@{$self->{ready_list}},$pre_cell);
            }
         }
   
    foreach my $nxt_cell (@{$nxt_cell_list}){
            my $pass = $graph_list->get_time_pass_vertex($nxt_cell);
             if( $pass == 0 ){
                push (@{$self->{ready_list}},$nxt_cell);
            }
         }
    }

    $self->run_cluster_BFS_gene($layer,$ratio);
  }

}

sub run_cluster_ini_gene {
    my ($self) = (@_);

    my $pwr_area_list  = $self->{pwr_area_list}                           || die "IC3DiGA->run_cluster_ini_gene(1) error\n";
    my $top_list       = $self->{pwr_area_list}->{top_list}               || die "IC3DiGA->run_cluster_ini_gene(2) error\n";
    my $constrain_list = $self->{pwr_area_list}->{top_list}->{util}       || die "IC3DiGA->run_cluster_ini_gene(3) error\n";
    my $graph_list     = $self->{pwr_area_list}->{top_list}->{Graph_list} || die "IC3DiGA->run_cluster_ini_gene(4) error\n";
 
    my $layer_size     = $constrain_list->{bench}->{LAYER};
    my $feedback_list  = $self->{cons_feedback};
   
    # @ feedback constrain
    my $rand_layer = int(rand($layer_size))+1;
    foreach my $feedback (@{$feedback_list}){
            if(  $top_list->is_graph_module_exist($feedback) ==0 ){
                 $self->{GA_alg_list}->{gene}->{$feedback} = $rand_layer;

               $pwr_area_list->set_time_layer_cell_module($feedback,$rand_layer);
               $pwr_area_list->set_time_pass_cell_module($feedback,1);
            }
    }

    # @ BFS rand rate area search constrain 
    # @ ps: power_list -> replace the $grapj_list->get_all_vertices();
    my @tmp_list  = @{$graph_list->get_all_vertices()};

    while( @tmp_list ){
        my $rand_inx = int(rand($#tmp_list+1));
        my $rand_vex =  $tmp_list[$rand_inx];
 
        if( defined($rand_vex)                                && 
            $top_list->is_graph_module_exist($rand_vex) ==0   ){

            my $pass     = $graph_list->get_time_pass_vertex($rand_vex);
            my $layer    = $graph_list->get_time_layer_vertex($rand_vex);

            if( $pass == 0 ){
             my $rand_layer = int(rand($layer_size))+1;
                $self->{GA_alg_list}->{gene}->{$rand_vex} = $rand_layer;   
 
                push (@{$self->{ready_list}}, $rand_vex);
                $self->{tmp_layer_area} = 0;

                $self->run_cluster_BFS_gene($rand_layer,1); # ratio =1? 

            } else {
                $self->{GA_alg_list}->{gene}->{$rand_vex} = $layer;
            }
        }
 
        delete $tmp_list[$rand_inx];  
    }
}

sub run_cluster_TSV_check {
    my ($self) = (@_);

    my $constrain_list = $self->{pwr_area_list}->{top_list}->{util}       || die "IC3DiGA->run_cluster_TSV_check(1) error\n";
    my $graph_list     = $self->{pwr_area_list}->{top_list}->{Graph_list} || die "IC3DiGA->run_cluster_TSV_check(2) error\n";
    my $GA_alg_list    = $self->{GA_alg_list}                             || die "IC3DiGA->run_cluster_TSV_check(3) error\n";

    my $layer_size     = $constrain_list->{bench}->{LAYER};
    my $already_list   = {};
     
   foreach my $gene ( keys %{$GA_alg_list->{gene}} ){

           my $pre_port_list = $graph_list->get_vertex_pre_stack($gene); 
           my $nxt_port_list = $graph_list->get_vertex_nxt_stack($gene); 
       
       # @ pre vertex check 
       foreach my $pre_port (@{$pre_port_list}){
               my $pre_cont_list = $graph_list->get_vertex_pre_stack($pre_port);
            
            foreach my $pre_cont (@{$pre_cont_list}){
                    my $wire_name = $graph_list->get_time_weighted_edge_name($pre_cont,$pre_port) || undef;
                    
                    if( defined($wire_name) ){

                        my $port_layer = $graph_list->get_time_layer_vertex($pre_port);
                        my $cont_layer = $graph_list->get_time_layer_vertex($pre_cont);

                        my $direct     = ($graph_list->is_time_weighted_edge_exist($pre_cont,$pre_port)==0)? 1:0;

                        my ($ipre_cont,$ipre_port)     = ($pre_cont,$pre_port);
                        my ($icont_layer,$iport_layer) = ($cont_layer,$port_layer);
                        my ($idirect)                  = ($direct);

                        # swap @ tsv_land && tsv_cell
                        if( $port_layer > $cont_layer ){  
                           ($ipre_cont,$ipre_port)     = ($pre_port,$pre_cont);
                           ($icont_layer,$iport_layer) = ($port_layer,$cont_layer);    
                            $idirect                   = ($direct==0)? 1: 0;                                                      
                       }

                          for(my $i=$iport_layer; $i<$icont_layer; $i++){
                               $self->set_tsv_land_clist($i,$wire_name,$idirect);
                               $self->set_tsv_cell_clist($i+1,$wire_name,$idirect);

                               if( $i==$icont_layer-1 ){
                                   $self->set_tsv_land_hlist($i,$wire_name,$ipre_cont,$ipre_port,$icont_layer,$iport_layer);
                                   $self->set_tsv_cell_hlist($i+1,$wire_name,$ipre_cont,$ipre_port,$icont_layer,$iport_layer);              
                               }
                          } 
                  }  
             }
         }

       # @ nxt vertex check 
       foreach my $nxt_port (@{$nxt_port_list}){
               my $nxt_cont_list = $graph_list->get_vertex_nxt_stack($nxt_port);
            
            foreach my $nxt_cont (@{$nxt_cont_list}){
                    my $wire_name = $graph_list->get_time_weighted_edge_name($nxt_port,$nxt_cont) || undef;

                    if( defined($wire_name) ){
                        my $port_layer = $graph_list->get_time_layer_vertex($nxt_port);
                        my $cont_layer = $graph_list->get_time_layer_vertex($nxt_cont);

                        my $direct     = ($graph_list->is_time_weighted_edge_exist($nxt_port,$nxt_cont)==0)? 0:1;

                        my ($inxt_cont,$inxt_port)     = ($nxt_cont,$nxt_port);
                        my ($icont_layer,$iport_layer) = ($cont_layer,$port_layer);
                        my ($idirect)                  = ($direct);

                        # swap @ tsv_land && tsv_cell
                        if( $port_layer > $cont_layer ){  
                           ($inxt_cont,$inxt_port)     = ($nxt_port,$nxt_cont);
                           ($icont_layer,$iport_layer) = ($port_layer,$cont_layer);    
                            $idirect                   = ($direct==0)? 1: 0;                                                      
                       }

                          for(my $i=$iport_layer; $i<$icont_layer; $i++){
                               $self->set_tsv_land_clist($i,$wire_name,$idirect);
                               $self->set_tsv_cell_clist($i+1,$wire_name,$idirect);

                               if( $i==$icont_layer-1 ){
                                   $self->set_tsv_land_hlist($i,$wire_name,$inxt_cont,$inxt_port,$icont_layer,$iport_layer);
                                   $self->set_tsv_cell_hlist($i+1,$wire_name,$inxt_cont,$inxt_port,$icont_layer,$iport_layer);              
                               }
                          } 
                   } 
             }
         }


    }    
}

sub run_cluster_constrain {
    my ($self) = (@_);
   
    my $pwr_area_list    = $self->{pwr_area_list}                             || die "IC3DiGA->run_cluster_constrain(1) error\n";
    my $graph_list       = $self->{pwr_area_list}->{top_list}->{Graph_list}   || die "IC3DiGA->run_cluster_constrain(2) error\n";
    my $constrain_list   = $self->{pwr_area_list}->{top_list}->{util}         || die "IC3DiGA->run_cluster_constrain(3) error\n";
    my $power_list       = $self->{pwr_area_list}->{irst_list}->{power}       || die "IC3DiGA->run_cluster_constrain(4) error\n"; 
    my $area_list        = $self->{pwr_area_list}->{irst_list}->{area}        || die "IC3DiGA->run_cluster_constrain(5) error\n";
    my $cell_list        = $self->{pwr_area_list}->{top_list}->{util}->{cell} || die "IC3DiGA->run_cluster_constrain(6) error\n";

    my $cons_density_list= $self->{cons_power_density};
    my $tsv_land_list    = $self->{tsv_land_list};
    my $tsv_cell_list    = $self->{tsv_cell_list};
    my $gene_list        = $self->{GA_alg_list}->{gene};

    my $core_voltage     = $cell_list->{CELL_VOLTAGE};
    my $core_cur_lim     = $cell_list->{TSV_CUR_LM};

    my $layer_size       = $constrain_list->{bench}->{LAYER};
 
    my $fit =0;
    my $cot =0; 

      # @ core
       foreach my $gene (keys %{$gene_list}){
               my $hit = 0;
               my $layer = $gene_list->{$gene};
                  $self->{fit_list}->{$layer}->{power} += $power_list->{$gene}->{power};
                  $self->{fit_list}->{$layer}->{area}  += $area_list->{$gene}->{area};               

           my $pre_port_list = $graph_list->get_vertex_pre_stack($gene); 

          foreach my $pre_port (@{$pre_port_list}){
                  my $pre_cont_list = $graph_list->get_vertex_pre_stack($pre_port);
            
              foreach my $pre_cont (@{$pre_cont_list}){
                      my $pre_cont_layer = $graph_list->get_time_layer_vertex($pre_cont);
                      if( $pre_cont_layer == $layer ){ $hit=1; }
              }
          }
           if( $hit==1 ){ $fit++; }
           $cot++;
       }
      
      if($fit < $self->{connect_ratio}*$cot){ return -1; }

     # @ TSV land
      foreach my $wire (keys %{$tsv_land_list}){
          foreach my $layer (keys %{$tsv_land_list->{$wire}}){
                     $self->{fit_list}->{$layer}->{power} += $tsv_land_list->{$wire}->{$layer}->{power};
                     $self->{fit_list}->{$layer}->{area}  += $tsv_land_list->{$wire}->{$layer}->{area};
          }
       }

     # @ TSV cell
       foreach my $wire (keys %{$tsv_cell_list}){
          foreach my $layer (keys %{$tsv_cell_list->{$wire}}){
                     $self->{fit_list}->{$layer}->{power} += $tsv_cell_list->{$wire}->{$layer}->{power};
                     $self->{fit_list}->{$layer}->{area}  += $tsv_cell_list->{$wire}->{$layer}->{area};
          }
       }

      my $top_layer = 0;
      foreach my $layer (sort keys %{$self->{fit_list}}){
              my $power = $self->{fit_list}->{$layer}->{power};
              my $area  = $self->{fit_list}->{$layer}->{area};
 
              # @ TSV P/G VCC VSS 
              my $core_i = ($core_voltage!=0)? $power / $core_voltage  : die "div 0\n";
              my $pg_num = ($core_cur_lim!=0)? $core_i / $core_cur_lim : die "div 0\n";
                 $pg_num = ($pg_num > int($pg_num))? int($pg_num)+1 : int($pg_num);

                 #????
 
                 if( $area < 0.5 * $self->{target_area} ||
                     $area > 2.5 * $self->{target_area} ){ return -1; }
 
              if( defined($cons_density_list->{final}->{$layer}) ){
                  my $density = $power / $area * 100;

                  if($density < $cons_density_list->{final}->{$layer}){
                     $self->{fit_list}->{$layer}->{density} = $density;
                  } else { return -1; }
             }
             $top_layer = $layer;
      }

     if( $top_layer < $layer_size ){ return -1; }

return 0;   
}

# fitness 
sub run_cluster_fitness {
    my ($self) = (@_);
    my $cur_generation = $self->{GA_alg_list}->{cur_generation};
    my $gene_list      = $self->{GA_alg_list}->{gene_list}->{$cur_generation};

    my @sort_list = (rand() > 0.5 )? sort { $a->{area}     <=> $b->{area}     } @{$gene_list} :
                                     sort { $a->{tsv_land} <=> $b->{tsv_land} } @{$gene_list};

    my $remain = $self->{GA_alg_list}->{min_fitness} * $#sort_list;
   
    my @tmp_list = ();
    for(my $i=0; $i<=$remain; $i++){
           push (@tmp_list,$sort_list[$i]);
    }

       $self->{GA_alg_list}->{gene_list}->{$cur_generation} = \@tmp_list;
}


sub run_cluster_best_parent {
    my ($self,$cur,$cur_generation) = (@_);

    my $cur_gene_list  = $self->{GA_alg_list}->{gene_list}->{$cur_generation};
    my $cur_gene_size  = $#$cur_gene_list;
    my $hit            = ();
    my $best_list      = {};

    for(my $i=0; $i<=$cur_gene_size; $i++){
        $hit =0;
        if( $i!= $cur ){
        my $vector_1 = $cur_gene_list->[$cur]->{gene};
        my $vector_2 = $cur_gene_list->[$i]->{gene};

        foreach my $vex ( keys %{$vector_1}){
                if( $vector_1->{$vex} == $vector_2->{$vex} ){
                    $hit++;
                }
        }
        $best_list->{$i} = $hit;
       }
    }

   my $j =0;
   my $rst_list = [];
   foreach my $vex ( reverse sort {$best_list->{$a}<=>$best_list->{$b}} keys %{$best_list}){
           if($j<= $self->{GA_alg_list}->{multi_parent}){ push (@{$rst_list},$vex); $j++; }
  }

return $rst_list;
}

sub run_cluster_crossover {
    my ($self) = (@_);

    my $pwr_area_list  = $self->{pwr_area_list}                       || die "IC3DiGA->run_cluster_crossover(1) error\n";
    my $constrain_list = $self->{pwr_area_list}->{top_list}->{util}   || die "IC3DiGA->run_cluster_crossover(2) error\n";

    my $layer_size     = $constrain_list->{bench}->{LAYER};
 
    my $cur_generation = $self->{GA_alg_list}->{cur_generation}++;
    my $cur_gene_list  = $self->{GA_alg_list}->{gene_list}->{$cur_generation};
    my $cur_gene_size  = $#$cur_gene_list;

    for(my $i=0; $i<=$cur_gene_size; $i++){
        my $best_parent = $self->run_cluster_best_parent($i,$cur_generation);

        foreach my $best (@{$best_parent}){
                my $gene_parent_1 = $cur_gene_list->[$i];
                my $gene_parent_2 = $cur_gene_list->[$best];

                my $gene_vector_1 = $gene_parent_1->{gene};
                my $gene_vector_2 = $gene_parent_2->{gene};
                
                my @gene_list  = keys %{$gene_vector_1};
                my $cross_bond = int(rand($#gene_list+1));
       
               # @ child 1 
                my $inx =0;
                foreach my $vertex ( keys %{$gene_vector_1} ){
                        my $new_layer = ( $inx>=$cross_bond )? $gene_vector_2->{$vertex} : $gene_vector_1->{$vertex};
 
                           $self->{GA_alg_list}->{gene}->{$vertex} = $new_layer;   
                           $pwr_area_list->set_time_layer_cell_module($vertex,$new_layer);
                           $inx++;
                }
 
                          $self->run_cluster_TSV_check();
                my $end = $self->run_cluster_constrain();
                if($end!=-1){
                         $self->run_cluster_set_gene_list();                
                }
                $self->run_cluster_clear();

                # @ child 2
                my $inx =0;
                foreach my $vertex ( keys %{$gene_vector_1} ){
                        my $new_layer = ( $inx>=$cross_bond )? $gene_vector_1->{$vertex} : $gene_vector_2->{$vertex};
 
                           $self->{GA_alg_list}->{gene}->{$vertex} = $new_layer;   
                           $pwr_area_list->set_time_layer_cell_module($vertex,$new_layer);
                           $inx++;
                }
 
                          $self->run_cluster_TSV_check();
                my $end = $self->run_cluster_constrain();
                if($end!=-1){
                         $self->run_cluster_set_gene_list();                
                }
                $self->run_cluster_clear();
       }
    }
}

sub run_cluster_mutation {
    my ($self) = (@_);

    my $constrain_list = $self->{pwr_area_list}->{top_list}->{util}            || die "IC3DiGA->run_cluster_mutation(1) error\n";

    my $layer_size     = $constrain_list->{bench}->{LAYER};
    my $cur_generation = $self->{GA_alg_list}->{cur_generation};
    my $gene_list      = $self->{GA_alg_list}->{gene_list}->{$cur_generation};
    my $gene_size      = $#$gene_list;

    foreach my $gene_child (@{$gene_list}){
            my $gene_vector = $gene_child->{gene};

            if( rand() <= $self->{GA_alg_list}->{mutation_rate} ){
                my $rand_layer = int(rand($layer_size))+1;
                my @gene_list  = keys %{$gene_vector};
                my $rand_sel   = int(rand($#gene_list+1));
                my $mut_vex    = $gene_list[$rand_sel];

                foreach my $vertex ( keys %{$gene_vector} ){
                        my $new_layer = ($vertex eq $mut_vex)? $rand_layer : $gene_vector->{$vertex};
                           $gene_vector->{$vertex} = $new_layer;
                }
            }
   }
}


sub run_cluster_clear {
    my ($self) = (@_);

        $self->{fit_list}            = {};
        $self->{tsv_land_list}       = {};
        $self->{tsv_cell_list}       = {};
        $self->{GA_alg_list}->{gene} = {};
       
    my $graph_list  = $self->{pwr_area_list}->{top_list}->{Graph_list}          || die "IC3DiGA->run_cluster_clear(1) error\n";

    my $vex_list    = $graph_list->get_all_vertices(); 
 
    foreach my $vex (@{$vex_list}){
            if( $graph_list->get_time_logic_vertex($vex) ne 'IO' ){ 
                $graph_list->set_time_pass_vertex($vex,0);
            }
    }
}

sub run_cluster_set_gene_list {
    my ($self) = (@_);

    my  $cur_generation = $self->{GA_alg_list}->{cur_generation}; 
    my  $fit_list       = $self->{fit_list};
    my  $tsv_land_list  = $self->{tsv_land_list};
    my  $tsv_cell_list  = $self->{tsv_cell_list};

    my  $tsv_land_num   = 0;
    my  $tsv_cell_num   = 0;
    my  $fit_area       = 0;

        foreach my $layer (keys %{$fit_list}){
                if( $fit_list->{$layer}->{area} > $fit_area ){ $fit_area = $fit_list->{$layer}->{area}; }
        }

        foreach my $wire (keys %{$tsv_land_list}){
          foreach my $layer  (keys %{$tsv_land_list->{$wire}} ){
                  $tsv_land_num++; 
          }
        }

        foreach my $wire (keys %{$tsv_cell_list}){
          foreach my $layer  (keys %{$tsv_cell_list->{$wire}} ){
                  $tsv_cell_num++; 
          }
        }

       push (@{$self->{GA_alg_list}->{gene_list}->{$cur_generation}}, { gene      => $self->{GA_alg_list}->{gene},
                                                                        area      => $fit_area,
                                                                        tsv_land  => $tsv_land_num,
                                                                        tsv_cell  => $tsv_cell_num, });
}

sub run_cluster_best {
    my ($self) = (@_);

    my $cur_generation = $self->{GA_alg_list}->{cur_generation} ;

    my $gene_list = $self->{GA_alg_list}->{gene_list}->{$cur_generation};
    push (@{$self->{best_list}} ,$gene_list->[0]);

    if($cur_generation > 0){
        delete $self->{GA_alg_list}->{gene_list}->{$cur_generation-1};
    }
}

sub run_cluster_result {
    my ($self) = (@_);

    my $pwr_area_list = $self->{pwr_area_list}                   || die "IC3DiGA->run_cluster_result(1) error\n";
    my $best_list = $self->{best_list};

    my @sort_list = sort { $a->{area}     <=> $b->{area},
                           $a->{tsv_land} <=> $b->{tsv_land} } @{$best_list};

    my $gene_list = $sort_list[0]->{gene};

       $self->{GA_alg_list}->{gene} = $gene_list;

    foreach my $vertex (keys %{$gene_list}){
            my $layer = $gene_list->{$vertex};
               $pwr_area_list->set_time_layer_cell_module($vertex,$layer);
   }
}

sub run_cluster_TSV_insert {
    my ($self) = (@_);

    my $pwr_area_list = $self->{pwr_area_list}                           || die "IC3DiGA->run_cluster_TSV_insert(1) error\n";
    my $top_list      = $self->{pwr_area_list}->{top_list}               || die "IC3DiGA->run_cluster_TSV_insert(2) error\n";
    my $graph_list    = $self->{pwr_area_list}->{top_list}->{Graph_list} || die "IC3DiGA->run_cluster_TSV_insert(3) error\n";

    my $tsv_land_list = $self->{tsv_land_list};
    my $tsv_cell_list = $self->{tsv_cell_list};

    foreach my $wire (keys %{$tsv_land_list}){
       foreach my $land_layer ( sort keys %{$tsv_land_list->{$wire}} ){
               my $direct = $tsv_land_list->{$wire}->{$land_layer}->{direct};

               $top_list->set_graph_TSV_land($land_layer,$wire,$direct);
               $top_list->set_graph_TSV_cell($land_layer+1,$wire,$direct);

               my $cur_land_up = $top_list->{tsv_land_list}->{$wire}->{$land_layer}->{up};
               my $cur_land_dn = $top_list->{tsv_land_list}->{$wire}->{$land_layer}->{down};

               my $cur_cell_up = $top_list->{tsv_cell_list}->{$wire}->{$land_layer+1}->{up};
               my $cur_cell_dn = $top_list->{tsv_cell_list}->{$wire}->{$land_layer+1}->{down};

               if( $direct ==0 ) {
                   $graph_list->set_time_weighted_edge($cur_cell_dn,$cur_land_up,0,$wire);
               } else {
                   $graph_list->set_time_weighted_edge($cur_land_up,$cur_cell_dn,0,$wire);
               }
                            
               # connect pre_layer(cell_up) -> cur_layer(land_down)
               if( defined($top_list->{tsv_land_list}->{$wire}->{$land_layer-1}) ){
                   my $pre_cell_up = $top_list->{tsv_cell_list}->{$wire}->{$land_layer}->{up};

                   if( $direct ==0 ) {
                       $graph_list->set_time_weighted_edge($cur_land_dn,$pre_cell_up,0,$wire);
                   } else {
                       $graph_list->set_time_weighted_edge($pre_cell_up,$cur_land_dn,0,$wire);
                   }
              }
         }
    }
}


sub run_cluster_TSV_update {
    my ($self) = (@_);

    my $top_list     = $self->{pwr_area_list}->{top_list}               || die "IC3DiGA->run_cluster_TSV_update(1) error\n";
    my $graph_list   = $self->{pwr_area_list}->{top_list}->{Graph_list} || die "IC3DiGA->run_cluster_TSV_update(2) error\n";

    my $tsv_land_list= $self->{tsv_land_list};
    my $tsv_cell_list= $self->{tsv_cell_list};

    foreach my $wire (keys %{$tsv_land_list}){
       foreach my $land_layer ( sort keys %{$tsv_land_list->{$wire}} ){
               my $direct = $tsv_land_list->{$wire}->{$land_layer}->{direct};

               # remap the graph 
               if( defined($tsv_land_list->{$wire}->{$land_layer}->{list}) ){
                   my @land_list  = @{$tsv_land_list->{$wire}->{$land_layer}->{list}};
 
               foreach my $land (@land_list){
                       my $pre_vex   = $land->{pre_vex};
                       my $cur_vex   = $land->{cur_vex};
                       my $pre_layer = $land->{pre_layer};
                       my $cur_layer = $land->{cur_layer};

                       my $land_dn   = $top_list->{tsv_land_list}->{$wire}->{$cur_layer}->{down}; 
                       my $cell_up   = $top_list->{tsv_cell_list}->{$wire}->{$pre_layer}->{up};

                          if( $direct ==0 ){
                             $graph_list->del_time_weighted_edge($pre_vex,$cur_vex);
                             $graph_list->set_time_weighted_edge($land_dn,$cur_vex,0,$wire);
                             $graph_list->set_time_weighted_edge($pre_vex,$cell_up,0,$wire);                                                   
                          } else {
                             $graph_list->del_time_weighted_edge($cur_vex,$pre_vex);
                             $graph_list->set_time_weighted_edge($cur_vex,$land_dn,0,$wire);
                             $graph_list->set_time_weighted_edge($cell_up,$pre_vex,0,$wire);                                                   
                          }
               }
             }
        }
    }
}

sub run_cluster_PAD_update {
    my ($self) = (@_);

    my $graph_list   = $self->{pwr_area_list}->{top_list}->{Graph_list} || die "IC3DiGA->run_cluster_PAD_update(1) error\n";

    my $all_vex_list = $graph_list->get_all_vertices(); 

    foreach my $vex (@{$all_vex_list}){
            my $logic = $graph_list->get_time_logic_vertex($vex);
            if( $logic eq 'IO' ){
                $graph_list->set_time_layer_vertex($vex,0);
            }
    } 
}


sub run_cluster_DD {
    my ($self) = (@_);

   my $ini_population = $self->{GA_alg_list}->{ini_population};

       $self->run_cluster_ini_constrain();

#=============================
# step 1. ini the population 
#=============================
for(my $i=0; $i<$ini_population; $i++){ 
    my $end  = -1;
  while($end ==-1){
        $self->run_cluster_ini_gene();
        $self->run_cluster_TSV_check();
  $end =$self->run_cluster_constrain();

     if($end!=-1){
        $self->run_cluster_set_gene_list();                
     }
       $self->run_cluster_clear();
   }
 }

print '@pass GA->ini_population ...'."\n";

while( $self->{GA_alg_list}->{cur_generation} < $self->{GA_alg_list}->{end_generation} ){

     #===========================
     # step 2. fitness
     #===========================
     $self->run_cluster_fitness();
     $self->run_cluster_best();

     my $cur_generation = $self->{GA_alg_list}->{cur_generation};
     my $gene_list = $self->{GA_alg_list}->{gene_list}->{$cur_generation};
     
     print '@pass GA->generation          :: '.$cur_generation.' population  ::'.($#$gene_list+1)."\n";
     print '      GA->best->TSV_number    :: '.$gene_list->[0]->{tsv_land}."\n";
     print '      GA->best->area          :: '.$gene_list->[0]->{area}."\n";

     if($#$gene_list<1){ last; }
 
     #===========================
     # step 3. crossover && cur_generation++
     #===========================
     $self->run_cluster_crossover();

     my $nxt_generation = $self->{GA_alg_list}->{cur_generation};
     my $gene_list = $self->{GA_alg_list}->{gene_list}->{$nxt_generation};
    
     # @ reduce the population 
     while($#$gene_list > $self->{GA_alg_list}->{max_population}){
           $self->run_cluster_fitness();
           $gene_list = $self->{GA_alg_list}->{gene_list}->{$nxt_generation}; 
     }

     #===========================
     # step 4. mutation
     #===========================
     $self->run_cluster_mutation();

     $self->run_cluster_clear();  
   }

$self->run_cluster_result();
$self->run_cluster_TSV_check();
$self->run_cluster_TSV_insert();
$self->run_cluster_TSV_update();
$self->run_cluster_PAD_update();
}

sub free {
    my ($self) = (@_);
        $self->{cons_power_density} = {};
        $self->{cons_feedback}      = {};
        $self->{power_density_list} = {};
        $self->{tsv_land_list}      = {};
        $self->{tsv_cell_list}      = {};
        $self->{fit_list}           = {};
        $self->{best_list}          = [];
        $self->{ready_list}         = [];
}

sub get_debug {
    my ($self) = (@_);

#print Dumper($self->{GA_alg_list});
#print Dumper($self->{tsv_land_list}); 
#print Dumper($self->{tsv_cell_list});
#print Dumper($self->{cons_power_density});
#print Dumper($self->{pwr_area_list}->{top_list}->{Graph_list});
#print Dumper($self->{pwr_area_list}->{top_list}->{Graph_list}->{layer_list});
#print Dumper($self->{pwr_area_list}->{top_list}->{util}->{bench});
#print Dumper($self->{GA_alg_list}->{gene_list});

}

1;
