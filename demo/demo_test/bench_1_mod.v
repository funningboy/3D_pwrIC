module bench_1 ( X0, X1, X1060,
                 clk1, clk2 );
  input X0, X1, clk1, clk2;
  output X1060;
  
  DFFX1 DFF1 ( .Q(N1), .D(N320), .CK(clk1) );
  DFFX1 DFF2 ( .Q(N2), .D(N315), .CK(clk1) );
  DFFX1 DFF3 ( .Q(X1060), .D(N308), .CK(clk2) );

  NOR2X2 U100 ( .A(X0), .B(X1), .Y(N320));
  XOR2X1 U101 ( .A(X0), .B(N1), .Y(N315));
  XOR2X2 U102 ( .A(X1), .B(N2), .Y(X2));
  AND2X2 U103 ( .A(X2), .B(X1), .Y(X3));
  INVX1 U104 ( .A(X3), .Y(X4));
  INVX1 U105 ( .A(X4), .Y(N308));

endmodule

