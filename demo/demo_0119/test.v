module bench_1 ( X0, X1060, clk1,);
  input X0, clk1;
  output X1060;
 
  AND2X2 U319 ( .A(X0), .B(N1), .Y(N0) );
  AND2X2 U318 ( .A(X0), .B(N1), .Y(X1060) );
  DFFX1 DFF1 ( .Q(N1), .D(N0) .CK(clk1) );

endmodule 
