module bench_1_L0 (clk1_OUT ,X0_OUT ,X34_OUT ,clk2_OUT ,X1_OUT,X1061_IN);

output clk1_OUT ,X0_OUT ,X34_OUT ,clk2_OUT ,X1_OUT;

input X1061_IN;

IN_PAD IN_PAD_3_ ( .PD(clk1) , .C(clk1_OUT) );
IN_PAD IN_PAD_0_ ( .PD(X0) , .C(X0_OUT) );
IN_PAD IN_PAD_2_ ( .PD(X34) , .C(X34_OUT) );
IN_PAD IN_PAD_4_ ( .PD(clk2) , .C(clk2_OUT) );
IN_PAD IN_PAD_1_ ( .PD(X1) , .C(X1_OUT) );
OUT_PAD OUT_PAD_0_ ( .I(X1061_IN) , .PD(X1061) );
endmodule
