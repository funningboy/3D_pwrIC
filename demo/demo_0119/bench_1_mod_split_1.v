//Layer1
module bench_1_L1 (X1060, X1061, X0_OUT, X34_OUT, clk1_OUT, clk2_OUT, N23_OUT, N24_OUT, N332_OUT, N334_OUT, n195_OUT, n272_OUT, 
                                   X0, X1, X34, clk1, clk2, X1061_IN, N331_IN, N333_IN, n180_IN);
  input X0, X1, X34, clk1, clk2, X1061_IN, N331_IN, N333_IN, n180_IN;
  output X1060, X1061, X0_OUT, X34_OUT, clk1_OUT, clk2_OUT, N23_OUT, N24_OUT, N332_OUT, N334_OUT, n195_OUT, n272_OUT;

//List of TSV
  TSV_LAND TL_1 ( .UP (X0_OUT), .DN (X0));
  TSV_LAND TL_2 ( .UP (X34_OUT), .DN (X34));
  TSV_LAND TL_3 ( .UP (clk1_OUT), .DN (clk1));
  TSV_LAND TL_4 ( .UP (clk2_OUT), .DN (clk2));
  TSV_LAND TL_5 ( .UP (N23_OUT), .DN (N23));
  TSV_LAND TL_6 ( .UP (N24_OUT), .DN (N24));
  TSV_LAND TL_7 ( .UP (N332_OUT), .DN (N332));
  TSV_LAND TL_8 ( .UP (N334_OUT), .DN (N334));
  TSV_LAND TL_9 ( .UP (n195_OUT), .DN (n195));
  TSV_LAND TL_10 ( .UP (n272_OUT), .DN (n272));
  TSV_LAND TL_11 ( .UP (X1061_IN), .DN (X1061));
  TSV_LAND TL_12 ( .UP (N331_IN), .DN (N331));
  TSV_LAND TL_13 ( .UP (N333_IN), .DN (N333));
  TSV_LAND TL_14 ( .UP (n180_IN), .DN (n180));


  DFFX2 DFF23 ( .Q(N23), .D(N168), .CK(clk1) );
  DFFX2 DFF24 ( .Q(N24), .D(N161), .CK(clk1) );
  DFFX2 DFF25 ( .Q(N25), .D(N154), .CK(clk1) );
  DFFX2 DFF26 ( .Q(N26), .D(N147), .CK(clk1) );
  DFFX2 DFF27 ( .Q(N27), .D(N140), .CK(clk1) );
  DFFX2 DFF28 ( .Q(N28), .D(N133), .CK(clk1) );
  DFFX1 DFF34 ( .Q(N332), .D(X1), .CK(clk2) );
  DFFX1 DFF36 ( .Q(N334), .D(N336), .CK(clk2) );
  OR2X2 U120 (.A(X34), .B(X1), .Y(N336));
  MX2X2 U212 ( .S0(n180), .B(n179), .A(n178), .Y(N133) );
  XOR2X2 U213 ( .A(N331), .B(n179), .Y(n178) );
  INVX1 U214 ( .A(N28), .Y(n179) );
  MX2X1 U215 ( .S0(n183), .B(n182), .A(n181), .Y(N140) );
  NOR2X1 U216 ( .A(N332), .B(n182), .Y(n181) );
  INVX1 U217 ( .A(N27), .Y(n182) );
  MX2X1 U218 ( .S0(n186), .B(n185), .A(n184), .Y(N147) );
  NOR2X1 U219 ( .A(N333), .B(n185), .Y(n184) );
  INVX1 U220 ( .A(N26), .Y(n185) );
  MX2X1 U221 ( .S0(n189), .B(n188), .A(n187), .Y(N154) );
  XOR2X1 U222 ( .A(N334), .B(n188), .Y(n187) );
  INVX1 U223 ( .A(N25), .Y(n188) );
  MX2X1 U224 ( .S0(n192), .B(n191), .A(n190), .Y(N161) );
  XOR2X1 U225 ( .A(N331), .B(n191), .Y(n190) );
  INVX1 U226 ( .A(N24), .Y(n191) );
  MX2X1 U227 ( .S0(n195), .B(n194), .A(n193), .Y(N168) );
  XNOR2X1 U228 ( .A(N332), .B(n194), .Y(n193) );
  INVX1 U229 ( .A(N23), .Y(n194) );
  AND2X2 U317 ( .A(N24), .B(n192), .Y(n195) );
  AND2X2 U318 ( .A(N25), .B(n189), .Y(n192) );
  AND2X2 U319 ( .A(N26), .B(n186), .Y(n189) );
  AND2X2 U320 ( .A(N27), .B(n183), .Y(n186) );
  AND2X2 U321 ( .A(N28), .B(n180), .Y(n183) );
  NAND4X2 U335 ( .A(N25), .B(N26), .C(N27), .D(N28), .Y(n272) );
endmodule
