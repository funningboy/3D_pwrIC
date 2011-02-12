#! /usr/bin/perl

use tCAD::BenchParser;
use tCAD::CellParser;
use tCAD::VeriParser;
use tCAD::util;
use tCAD::GRAPH;
use tCAD::PowerArea;
use tCAD::IC3DiGA;
use tCAD::ExpVeri;
use tCAD::ExpRpt;

use strict;
use Data::Dumper;

sub get_usage {
  print STDOUT '

#=============================================#
# 3D IC Design Partitioning with Power Consideration 
# author : sean chen
# mail : funningboy@gmail.com
# license: FBS
# publish: 2011/02/12 v1
# project reference : https://sites.google.com/site/funningboy/verilog/3D_IC_Partition_Algorithm_with_Power_Consideration_991224_4rd.pdf?attredirects=0&d=1 
#=============================================#

<USAGE>

-root [ design_file_loc ]
-library [ library_file ]

</USAGE>

ex: perl main.pl -root ./demo/demo_test/ \
                 -library ./design_bench_1_200.info \

ps: you can modify the GA constrains in IC3DiGA.pm
ex: ini_population = 50,
    mutation_rate  = 0.5,
    min_fitness    = 0.7,
    max_population = 200,
';
die "\n";
}

if(!@ARGV){ get_usage(); }

my $root_path;
my $bench_path= $root_path;

while(@ARGV){
  $_ = shift @ARGV;

    if( /-root/    ){ $root_path  = shift @ARGV; }
 elsif( /-library/ ){ $bench_path = shift @ARGV; }
 else { get_usage(); }
}

$bench_path = $root_path.$bench_path;

#============================================
# parsaer bench info
#============================================
my $bench_ptr = tCAD::BenchParser->new();
my $bench_rst = $bench_ptr->parser_files($bench_path);

my $net_list   = $root_path.$bench_rst->{NET_LIST};
my $cell_list  = $root_path.$bench_rst->{CELL_LIST};
my $top_design = $bench_rst->{TOP_MODULE};
print  '@pass Parser bench info ...'."\n";

#=============================================
# parser cell_lib file
# @ input : cell lib
# @ output: cell_DD 
#=============================================
my $cell_ptr   = tCAD::CellParser->new();
my $cell_rst   = $cell_ptr->parser_files($cell_list);  
print  '@pass Parser cell info ...'."\n";

#============================================
# parser verilog file
# @ input  : verilog file
# @ return : verilog_DD
#============================================
my $veri_ptr  = tCAD::VeriParser->new();
my $veri_rst  = $veri_ptr->parser_files($net_list);
print  '@pass Parser verilog info ...'."\n";

my $util_ptr  = tCAD::util->new();
   $util_ptr->set_bench_DD($bench_rst);
   $util_ptr->set_verilog_DD($veri_rst);
   $util_ptr->set_cell_DD($cell_rst);
   $util_ptr->get_check_rst($top_design);
   $util_ptr->get_debug();
   $util_ptr->free();

print  '@pass util check info ...'."\n";

#============================================
# get pop up Graph @ vertex && edge
# @ input  : verilog DD
# @ return : DFG graph
#============================================
my $graph_ptr = tCAD::GRAPH->new($util_ptr);
   $graph_ptr->run_graph_DD($top_design,-1);
   $graph_ptr->dump_graphviz_file($top_design.'.dot');
   $graph_ptr->get_debug();
   $graph_ptr->free();

print  '@pass pop up DFG(graph) info ...'."\n";

#===========================================
# get power/area info @ DFG graph
# @ input  : verilog
# @ return : power graph
#===========================================
my $pwrarea_ptr = tCAD::PowerArea->new($graph_ptr);
   $pwrarea_ptr->run_PowerArea_DD();
   $pwrarea_ptr->get_debug();
   $pwrarea_ptr->free();

print  '@pass power/area(graph) info ...'."\n";

##===========================================
## cluster partition form bottom up DFG graph
## algorithm : greedy expand + GA based
## @ input   : power graph
## @ return  : partition && TSV insert
##=========================================== 
my $ic3d_ptr   = tCAD::IC3DiGA->new($pwrarea_ptr); 
   $ic3d_ptr->run_cluster_DD();
   $ic3d_ptr->get_debug();
   $ic3d_ptr->free();

print  '@pass IC3DiGA info ...'."\n";

#==========================================
# explore the result 2 partition result verilog
# @ input  : cluster/partition result DFG
# @ return : verilog
#==========================================
my $exp_ptr    = tCAD::ExpVeri->new($ic3d_ptr);
   $exp_ptr->run_Exp_DFG2Veri_DD($top_design);
   $exp_ptr->get_debug();
   $exp_ptr->free();

#==========================================
# explore the result 2 report
# @ input  : cluster/partition result DFG
# @ return : report
#==========================================
my $rpt_ptr   = tCAD::ExpRpt->new($ic3d_ptr);
   $rpt_ptr->run_Exp_DFG2Rpt_DD($top_design);
   $rpt_ptr->get_debug();
   $rpt_ptr->free();

print '@pass report info ...'."\n";
