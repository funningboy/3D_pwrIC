#! /usr/bin/perl

package tCAD::BenchParser;
use Parse::RecDescent;
use Data::Dumper;
use strict;

#    $::RD_TRACE=1;        # if defined, also trace parsers' behaviour
#    $::RD_AUTOSTUB=1;     # if defined, generates "stubs" for undefined rules
#    $::RD_AUTOACTION=1;   # if defined, appends specified action to productions
#    $::RD_HINT=1;

my $InBenchGrammar = q {

{
use Data::Dumper; 
my  $bench_list ={};
}

START		: TOKEN_NETLIST START(s?)
		{
		 $bench_list->{NET_LIST} = $item[1];
		 $return = $bench_list;
		}
		| TOKEN_CELL_LIB START(s?)
		{
		 $bench_list->{CELL_LIST} = $item[1];
		 $return = $bench_list;
		}
		| TOKEN_TOP_MOD START(s?)
		{
		 $bench_list->{TOP_MODULE} = $item[1];
		 $return = $bench_list;
		}
		| TOKEN_LAYER START(s?)
		{
		 $bench_list->{LAYER} = $item[1];
		 $return = $bench_list;
		}
		| TOKEN_MAX_PWR START(s?)
		{
		 $bench_list->{MAX_POWER} = $item[1];
		 $return = $bench_list;
		}
		| TOKEN_INPUT_PAD START(s?)
		{
		 $bench_list->{INPUT_PAD} = $item[1];
		 $return = $bench_list;
		}

TOKEN_NETLIST	: 'NETLIST' 'FILENAME' IDENTIFIER
		{
		  $return = $item[3];
		}	

TOKEN_CELL_LIB	: 'CELL' 'LIBARY' 'FILENAME' IDENTIFIER
		{
		  $return = $item[4];
		}

TOKEN_TOP_MOD	: 'TOP' 'MODULE' IDENTIFIER
		{
		  $return = $item[3];
		}

TOKEN_LAYER	: 'LAYER NUMBER' IDENTIFIER
		{
		  $return = $item[2];
		}

TOKEN_MAX_PWR	: 'MAX' 'POWER' 'DENSITY' TOKEN_LFT_BRAC(?) TOKEN_LAYER_LIST(s?) TOKEN_RHT_BRAC(?)
		{
		 $return = $item[5];
		}

TOKEN_LAYER_LIST: 'LAYER' IDENTIFIER IDENTIFIER
		{
		 $return = { $item[2] => $item[3] };
		}

TOKEN_INPUT_PAD	: 'INPUT' 'PAD' 'FREQUENCY' TOKEN_LFT_BRAC(?) TOKEN_PAD_LIST(s?) TOKEN_RHT_BRAC(?)
		{
		 $return = $item[5];
		}

TOKEN_PAD_LIST	: IDENTIFIER IDENTIFIER
		{
		 $return = { $item[1] => $item[2] };
		}

TOKEN_LFT_BRAC	: '{'                   { $return = $item[1]; }

TOKEN_RHT_BRAC	: '}'                   { $return = $item[1]; }
 
TOKEN_LFT_SC	: '('                   { $return = $item[1]; }

TOKEN_RHT_SC	: ')'                   { $return = $item[1]; }

TOKEN_COMMA	: ','                   { $return = $item[1]; }

TOKEN_ED	: ';'                   { $return = $item[1]; }

IDENTIFIER	: /[0-9a-zA-Z\_\[\]\.]+/{ $return = $item[1]; }

MASK		: /.*\n/                { $return = $item[1]; }
};

sub new {
    my $class = shift;
    my $self = {};
  
   bless $self, $class;
   return $self;
} 

sub parser_files { 
    my ($self,$path) = (@_);

    open (BENCH,$path) or die "input Bench error\n";
    undef $/;
    my $text = <BENCH>;

    my $parse = new Parse::RecDescent($InBenchGrammar) or die 'InBenchGrammar';
    my $parse_tree = $parse->START($text) or die 'Bench';
#    print Dumper($parse_tree);

   close(BENCH);
   return $parse_tree;
}
