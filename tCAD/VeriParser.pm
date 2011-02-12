#! /usr/bin/perl

package tCAD::VeriParser;
use Parse::RecDescent;
use Data::Dumper;
use strict;

#    $::RD_TRACE=1;        # if defined, also trace parsers' behaviour
#    $::RD_AUTOSTUB=1;     # if defined, generates "stubs" for undefined rules
#    $::RD_AUTOACTION=1;   # if defined, appends specified action to productions
#    $::RD_HINT=1;

my $InDesignGrammar = q {

{
use Data::Dumper; 
my  $InDesignTb ={};
my  $module     =();
my  $icell      =0;
}

START		: TOKEN_MODULE START(s?)
		{
		  $return = $item[1];
		}
		| TOKEN_INPUT START(s?)
		{
		  $return = $item[1];
		}
		| TOKEN_OUTPUT START(s?)
		{
		  $return = $item[1];
		}
		| TOKEN_WIRE START(s?)
		{
		  $return = $item[1];
		}
		| TOKEN_CELLS START(s?)
		{
		  $return = $item[1];
		}
		| TOKEN_END_MODULE START(s?)
		{
		  $return = $item[1];
		}
		| TOKEN_MASK START(s?)
		{
		  $return = $item[1];
		}

TOKEN_MASK	: '//' MASK
		{
		 $return = $item[2];
		}

TOKEN_END_MODULE: 'endmodule'
		{
		   $return = $item[1];
		}

TOKEN_MODULE	: 'module' IDENTIFIER TOKEN_LFT_SC TOKEN_INT_ASSIGN(s?) TOKEN_RHT_SC TOKEN_ED
		{
		   $module = $item[2];
		   $return = $InDesignTb;
		}

TOKEN_INPUT	: 'input' TOKEN_INT_ASSIGN(s?) TOKEN_ED
		{
		   push (@{$InDesignTb->{$module}->{input}},$item[2]);
		   $return = $InDesignTb; 
		}

TOKEN_OUTPUT	: 'output' TOKEN_INT_ASSIGN(s?) TOKEN_ED
		{
		  push (@{$InDesignTb->{$module}->{output}},$item[2]);
		  $return = $InDesignTb;
		}

TOKEN_WIRE	: 'wire' TOKEN_INT_ASSIGN(s?) TOKEN_ED
		{
		  push (@{$InDesignTb->{$module}->{wire}},$item[2]);
		  $return = $InDesignTb;
		}

TOKEN_INT_ASSIGN: IDENTIFIER TOKEN_COMMA(?)
		{
		  $return = $item[1];
		}

TOKEN_CELLS	: IDENTIFIER IDENTIFIER(?) TOKEN_LFT_SC TOKEN_LNK_ASSIGN(s?) TOKEN_DIR_ASSIGN(s?) TOKEN_RHT_SC TOKEN_ED
		{
                  if( !@{$item[4]} ){
		  push (@{$InDesignTb->{$module}->{cell}},{ 
		              cell_module => $item[1],
		              cell_name   => $item[2]->[0] || '_icell_'.$icell++,
		              cell_link   => $item[5],});
		  } else {
		  push (@{$InDesignTb->{$module}->{cell}},{ 
		              cell_module => $item[1],
		              cell_name   => $item[2]->[0] || '_icell_'.$icell++,
		              cell_link   => $item[4],});
                  }
		  $return = $InDesignTb;
		}

TOKEN_LNK_ASSIGN:  '.' IDENTIFIER TOKEN_LFT_SC IDENTIFIER TOKEN_RHT_SC TOKEN_COMMA(?)
		{
		   $return = { port_name => $item[2],
		               wire_name => $item[4], };
		}

TOKEN_DIR_ASSIGN: IDENTIFIER TOKEN_COMMA(?)
		{
		  $return = { port_name => $item[1] };
		}

TOKEN_LFT_SC	: '('                 { $return = $item[1]; }

TOKEN_RHT_SC	: ')'                 { $return = $item[1]; }

TOKEN_COMMA	: ','                 { $return = $item[1]; }

TOKEN_ED	: ';'                 { $return = $item[1]; }

IDENTIFIER	: /[0-9a-zA-Z\_\[\]]+/{ $return = $item[1]; }

MASK		: /.*\n/              { $return = $item[1]; }
};

sub new {
    my $class = shift;
    my $self = {};
  
   bless $self, $class;
   return $self;
} 

sub parser_files { 
    my ($self,$path) = (@_);

    open (IVERI,$path) or die "input Verilog error\n";
    undef $/;
    my $text = <IVERI>;

    my $parse = new Parse::RecDescent($InDesignGrammar) or die 'InDesignGrammar';
    my $parse_tree = $parse->START($text) or die 'Verilog';
#    print Dumper($parse_tree);

   close(IVERI);
   return $parse_tree;
}




