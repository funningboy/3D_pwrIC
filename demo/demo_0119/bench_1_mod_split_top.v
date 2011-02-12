module bench_1_top ( X1060, X1061, X0, X1, X34, clk1, clk2 );
  input  X0, X1, X34, clk1, clk2;
  output  X1060, X1061;
// List of TSV IO Ports
  IN_PAD IN_1 ( .PD (X0), .C (X0_1));
  IN_PAD IN_2 ( .PD (X1), .C (X1_1));
  IN_PAD IN_3 ( .PD (X34), .C (X34_1));
  IN_PAD IN_4 ( .PD (clk1), .C (clk1_1));
  IN_PAD IN_5 ( .PD (clk2), .C (clk2_1));
  OUT_PAD OUT_1 ( .I (X1060_1), .PD (X1060));
  OUT_PAD OUT_2 ( .I (X1061_1), .PD (X1061));

  bench_1_L1 SP_1 ( .X1060 (X1060_1), .X1061 (X1061_1), .X0_OUT (X0_12), .X34_OUT (X34_12), .clk1_OUT (clk1_12), .clk2_OUT (clk2_12), .N23_OUT (N23_12), 
                                   .N24_OUT (N24_12), .N332_OUT (N332_12), .N334_OUT (N334_12), .n195_OUT (n195_12), .n272_OUT (n272_12), .X0 (X0_1), .X1 (X1_1), 
                                   .X34 (X34_1), .clk1 (clk1_1), .clk2 (clk2_1), .X1061_IN (X1061_21), .N331_IN (N331_21), .N333_IN (N333_21), .n180_IN (n180_21));

  bench_1_L2 SP_2 ( .N16_OUT (N16_23), .n252_OUT (n252_23), .n219_OUT (n219_23), .n265_OUT (n265_23), .n263_OUT (n263_23), .X0_OUT (X0_23),
                                   .X34_OUT (X34_23), .clk1_OUT (clk1_23), .clk2_OUT (clk2_23), .N332_OUT (N332_23), .N334_OUT (N334_23), .X1061_OUT (X1061_21),
                                   .N331_OUT (N331_21), .N333_OUT (N333_21), .n180_OUT (n180_21), .n240_IN (n240_32), .X1061_IN (X1061_32), .N331_IN (N331_32), 
                                   .N333_IN (N333_32), .X0_IN (X0_12), .X34_IN (X34_12), .clk1_IN (clk1_12), .clk2_IN (clk2_12), .N332_IN (N332_12), .N334_IN (N334_12), 
                                   .N23_IN (N23_12), .N24_IN (N24_12), .n195_IN (n195_12), .n272_IN (n272_12));

  bench_1_L3 SP_3 ( .X1061_OUT (X1061_32), .N331_OUT (N331_32), .N333_OUT (N333_32), .n240_OUT (n240_32), .X0_IN (X0_23), .X34_IN (X34_23), 
                                   .clk1_IN (clk1_23), .clk2_IN (clk2_23), .N16_IN (N16_23), .N332_IN (N332_23), .N334_IN (N334_23), .n252_IN (n252_23), .n219_IN (n219_23), 
                                   .n265_IN (n265_23), .n263_IN (n263_23));
endmodule