//Layer3
module bench_1_L3 (X1061_OUT, N331_OUT, N333_OUT, n240_OUT, X0_IN, X34_IN, clk1_IN, clk2_IN, N16_IN, N332_IN, N334_IN, n252_IN, 
                                   n219_IN, n265_IN, n263_IN);
  input X0_IN, X34_IN, clk1_IN, clk2_IN, N16_IN, N332_IN, N334_IN, n252_IN, n219_IN, n265_IN, n263_IN;
  output X1061_OUT, N331_OUT, N333_OUT, n240_OUT;

//List of TSV
  TSV_CELL TC_1 ( .UP (X1061_OUT), .DN (X1061));
  TSV_CELL TC_2 ( .UP (N331_OUT), .DN (N331));
  TSV_CELL TC_3 ( .UP (N333_OUT), .DN (N333));
  TSV_CELL TC_4 ( .UP (n240_OUT), .DN (n240));
  TSV_CELL TC_5 ( .UP (X0_IN), .DN (X0));
  TSV_CELL TC_6 ( .UP (X34_IN), .DN (X34));
  TSV_CELL TC_7 ( .UP (clk1_IN), .DN (clk1));
  TSV_CELL TC_8 ( .UP (clk2_IN), .DN (clk2));
  TSV_CELL TC_9 ( .UP (N16_IN), .DN (N16));
  TSV_CELL TC_10 ( .UP (N332_IN), .DN (N332));
  TSV_CELL TC_11 ( .UP (N334_IN), .DN (N334));
  TSV_CELL TC_12 ( .UP (n252_IN), .DN (n252));
  TSV_CELL TC_13 ( .UP (n219_IN), .DN (n219));
  TSV_CELL TC_14 ( .UP (n265_IN), .DN (n265));
  TSV_CELL TC_15 ( .UP (n263_IN), .DN (n263));

  DFFX1 DFF1 ( .Q(N1), .D(N320), .CK(clk1) );
  DFFX1 DFF2 ( .Q(N2), .D(N315), .CK(clk1) );
  DFFX1 DFF3 ( .Q(N3), .D(N308), .CK(clk1) );
  DFFX1 DFF4 ( .Q(N4), .D(N301), .CK(clk1) );
  DFFX1 DFF9 ( .Q(N9), .D(N266), .CK(clk1) );
  DFFX1 DFF10 ( .Q(N10), .D(N259), .CK(clk1) );
  DFFX1 DFF11 ( .Q(N11), .D(N252), .CK(clk1) );
  DFFX1 DFF12 ( .Q(N12), .D(N245), .CK(clk1) );
  DFFX1 DFF13 ( .Q(N13), .D(N238), .CK(clk1) );
  DFFX1 DFF14 ( .Q(N14), .D(N231), .CK(clk1) );
  DFFX1 DFF15 ( .Q(N15), .D(N224), .CK(clk1) );

  DFFX1 DFF33 ( .Q(N331), .D(X0), .CK(clk2) );
  DFFX1 DFF35 ( .Q(N333), .D(N335), .CK(clk2) );

  DFFX2 DFF41 ( .Q(X1061), .D(N1061), .CK(clk2) );
  DFFX2 DFF42 ( .Q(X1062), .D(N1062), .CK(clk2) );

  DFFX2 DFF57 ( .Q(N1070), .D(N1080), .CK(clk1) );
  DFFX2 DFF58 ( .Q(N1071), .D(N1081), .CK(clk1) );
  DFFX2 DFF59 ( .Q(N1072), .D(N1082), .CK(clk1) );

  NOR2X2 U100 ( .A(N1), .B(N1070), .Y(N1080));
  XOR2X1 U101 ( .A(N1070), .B(N1071), .Y(N1081));
  XOR2X2 U102 ( .A(N1070), .B(N1072), .Y(N1083));
  AND2X2 U103 ( .A(N1071), .B(N1083), .Y(N1082));
  INVX1 U104 ( .A(N1070), .Y(N1090));
  INVX1 U105 ( .A(N1071), .Y(N1091));
  INVX1 U106 ( .A(N1072), .Y(N1092));
  AND4X1 U107 ( .A(N106), .B(N1090), .C(N1091), .D(N1092), .Y(N1051));
  AND4X1 U108 ( .A(N106), .B(N1070), .C(N1091), .D(N1092), .Y(N1052));
  AND4X1 U109 ( .A(N106), .B(N1090), .C(N1071), .D(N1092), .Y(N1053));
  AND4X1 U110 ( .A(N106), .B(N1070), .C(N1071), .D(N1092), .Y(N1054));
  AND4X1 U111 ( .A(N106), .B(N1090), .C(N1091), .D(N1072), .Y(N1055));
  AND4X1 U112 ( .A(N106), .B(N1070), .C(N1091), .D(N1072), .Y(N1056));
  AND4X1 U113 ( .A(N106), .B(N1090), .C(N1071), .D(N1072), .Y(N1057));
  AND4X1 U114 ( .A(N106), .B(N1070), .C(N1071), .D(N1072), .Y(N1058));
  AND2X1 U115 ( .A(N1051), .B(N1052), .Y(N1065));
  AND2X1 U116 ( .A(N1053), .B(N1054), .Y(N1066));
  AND2X1 U117 ( .A(N1055), .B(N1056), .Y(N1063));
  AND2X1 U118 ( .A(N1057), .B(N1058), .Y(N1064));
  OR2X2 U119 ( .A(X34), .B(X0), .Y(N335));
  NOR2X1 U121 ( .A(N1065), .B(N1063), .Y(N1061));
  NOR2X2 U122 ( .A(N1066), .B(N1064), .Y(N1062));
  MX2X1 U251 ( .S0(n219), .B(n218), .A(n217), .Y(N224) );
  XOR2X1 U252 ( .A(N332), .B(n218), .Y(n217) );
  INVX1 U253 ( .A(N15), .Y(n218) );
  MX2X1 U254 ( .S0(n222), .B(n221), .A(n220), .Y(N231) );
  NOR2X1 U255 ( .A(N333), .B(n221), .Y(n220) );
  INVX1 U256 ( .A(N14), .Y(n221) );
  MX2X1 U257 ( .S0(n225), .B(n224), .A(n223), .Y(N238) );
  NOR2X1 U258 ( .A(N334), .B(n224), .Y(n223) );
  INVX1 U259 ( .A(N13), .Y(n224) );
  MX2X1 U260 ( .S0(n228), .B(n227), .A(n226), .Y(N245) );
  NOR2X1 U261 ( .A(N331), .B(n227), .Y(n226) );
  INVX1 U262 ( .A(N12), .Y(n227) );
  MX2X1 U263 ( .S0(n231), .B(n230), .A(n229), .Y(N252) );
  NOR2X1 U264 ( .A(N332), .B(n230), .Y(n229) );
  INVX1 U265 ( .A(N11), .Y(n230) );
  MX2X1 U266 ( .S0(n234), .B(n233), .A(n232), .Y(N259) );
  NOR2X1 U267 ( .A(N333), .B(n233), .Y(n232) );
  INVX1 U268 ( .A(N10), .Y(n233) );
  MX2X1 U269 ( .S0(n237), .B(n236), .A(n235), .Y(N266) );
  NOR2X1 U270 ( .A(N334), .B(n236), .Y(n235) );
  INVX1 U271 ( .A(N9), .Y(n236) );
  MX2X2 U284 ( .S0(n252), .B(n251), .A(n250), .Y(N301) );
  NOR2X1 U285 ( .A(N333), .B(n251), .Y(n250) );
  INVX2 U286 ( .A(N4), .Y(n251) );
  MX2X2 U287 ( .S0(n255), .B(n254), .A(n253), .Y(N308) );
  NOR2X2 U288 ( .A(N334), .B(n254), .Y(n253) );
  INVX2 U289 ( .A(N3), .Y(n254) );
  MX2X1 U290 ( .S0(n258), .B(n257), .A(n256), .Y(N315) );
  NOR2X2 U291 ( .A(N331), .B(n256), .Y(n257) );
  NOR2X2 U292 ( .A(N332), .B(n259), .Y(N320) );
  MX2X2 U293 ( .S0(N1), .B(n261), .A(n260), .Y(n259) );
  NOR2X2 U294 ( .A(n258), .B(n256), .Y(n261) );
  OR2X1 U295 ( .A(n256), .B(n258), .Y(n260) );
  NAND2X1 U296 ( .A(N3), .B(n255), .Y(n258) );
  AND2X2 U297 ( .A(N4), .B(n252), .Y(n255) );
  AND2X1 U302 ( .A(N9), .B(n237), .Y(n240) );
  AND2X1 U303 ( .A(N10), .B(n234), .Y(n237) );
  AND2X1 U304 ( .A(N11), .B(n231), .Y(n234) );
  AND2X1 U305 ( .A(N12), .B(n228), .Y(n231) );
  AND2X1 U306 ( .A(N13), .B(n225), .Y(n228) );
  AND2X1 U307 ( .A(N14), .B(n222), .Y(n225) );
  AND2X1 U308 ( .A(N15), .B(n219), .Y(n222) );
  INVX2 U327 ( .A(N2), .Y(n256) );
  NOR2X2 U328 ( .A(n263), .B(n264), .Y(N106) );
  OR4X1 U329 ( .A(n265), .B(n266), .C(n267), .D(n268), .Y(n264) );
  NAND4X1 U330 ( .A(N9), .B(N10), .C(N11), .D(N12), .Y(n268) );
  NAND4X1 U331 ( .A(N13), .B(N14), .C(N15), .D(N16), .Y(n267) );
  NAND4X1 U332 ( .A(N1), .B(N2), .C(N3), .D(N4), .Y(n266) );
endmodule

