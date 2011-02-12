#! /usr/bin/perl

package tCAD::CellParser;
use Parse::RecDescent;
use Data::Dumper;
use strict;

#    $::RD_TRACE=1;        # if defined, also trace parsers' behaviour
#    $::RD_AUTOSTUB=1;     # if defined, generates "stubs" for undefined rules
#    $::RD_AUTOACTION=1;   # if defined, appends specified action to productions
#    $::RD_HINT=1;

my $InCellGrammar = q {

{
use Data::Dumper; 
my  $cell_list = {};
my  $tpin_list = {};
my  $macro_list= {};
}

START		: TOKEN_CELL_VOLT START(s?)
		{
		  $cell_list->{CELL_VOLTAGE} = $item[1];
		  $return = $cell_list;	
		}
		| TOKEN_IO_VOLT START(s?)
		{
		  $cell_list->{IO_VOLTAGE} = $item[1];
		  $return = $cell_list;
		}
		| TOKEN_PAD_CUR_LM START(s?)
		{
		  $cell_list->{PAD_CUR_LM} = $item[1];
		  $return = $cell_list;
		}
		| TOKEN_TSV_CUR_LM START(s?)
		{
		  $cell_list->{TSV_CUR_LM} = $item[1];
		  $return = $cell_list;
		}
		| TOKEN_MACRO START(s?)
		{
		  $cell_list->{MACRO} = $item[1];
		  $return = $cell_list;
		}

TOKEN_CELL_VOLT	: 'CELL' 'SUPPLY' 'VOLTAGE' IDENTIFIER
		{
		 $return = $item[4];
		}

TOKEN_IO_VOLT	: 'IO' 'SUPPLY' 'VOLTAGE' IDENTIFIER
		{
		 $return = $item[4];
		}

TOKEN_PAD_CUR_LM: 'PAD' 'CURRENT' 'LIMIT' IDENTIFIER
		{
		 $return = $item[4];
		}

TOKEN_TSV_CUR_LM: 'TSV' 'CURRENT' 'LIMIT' IDENTIFIER
		{
		 $return = $item[4];
		}

TOKEN_MACRO	: 'MACRO' IDENTIFIER TOKEN_LFT_BRAC(?) TOKEN_MACRO_LIST(s?) TOKEN_RHT_BRAC(?) 'END'
		{
		  $cell_list->{MACRO}->{$item[2]} = $item[4]->[0];
		  $macro_list = {};
                  $return = $cell_list->{MACRO};
		} 

TOKEN_MACRO_LIST: 'TYPE' IDENTIFIER
		{
		  $macro_list->{TYPE} = $item[2];
		  $return = $macro_list;
		}
		| 'AREA' IDENTIFIER
		{
		  $macro_list->{AREA} = $item[2];
		  $return = $macro_list;
		}
		| 'POWER' IDENTIFIER
		{
		  $macro_list->{POWER} = $item[2];
		  $return = $macro_list;
		}
		| 'PIN' IDENTIFIER TOKEN_LFT_BRAC(?) TOKEN_PIN_LIST(s?) TOKEN_RHT_BRAC(?)
		{
		   $tpin_list = {};
		   $macro_list->{PIN}->{$item[2]} = $item[4]->[0];
		   $return = $macro_list;  
		} 

TOKEN_PIN_LIST	: 'DIRECTION' IDENTIFIER
		{
		  $tpin_list->{DIRECTION} = $item[2];
		  $return = $tpin_list;
		}
		| 'POWER' IDENTIFIER
		{
		  $tpin_list->{POWER} = $item[2];
		  $return = $tpin_list;
		}
		| 'CAPACITANCE' IDENTIFIER
		{
		  $tpin_list->{CAPACITANCE} = $item[2];
		  $return = $tpin_list;
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

    open (CELL,$path) or die "input Cell error\n";
    undef $/;
    my $text = <CELL>;

    my $parse = new Parse::RecDescent($InCellGrammar) or die 'InCellGrammar';
    my $parse_tree = $parse->START($text) or die 'Cell';
#    print Dumper($parse_tree);

   close(CELL);
   return $parse_tree;
}
