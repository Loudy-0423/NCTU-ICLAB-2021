module CHIP( 	
	clk,
    rst_n,
    in_valid,
    in_x,
    in_y,
    move_num,
    priority_num,
    out_valid,
    out_x,
    out_y,
    move_out);

input clk,rst_n;
input in_valid;
input [2:0] in_x,in_y;
input [4:0] move_num;
input [2:0] priority_num;

output out_valid;
output [2:0] out_x,out_y;
output [4:0] move_out;

wire   C_clk;
wire   C_rst_n;
wire   C_IN_VALID;
wire  [2:0] C_IN_X,C_IN_Y;
wire  [4:0] C_MOVE_NUM;
wire  [2:0] C_PRIORITY_NUM;

wire  C_OUT_VALID;
wire  [2:0] C_OUT_X,C_OUT_Y;
wire  [4:0] C_MOVE_OUT;

wire BUF_clk;
CLKBUFX20 buf0(.A(C_clk),.Y(BUF_clk));

KT I_KT(
	// Input signals
	.clk(BUF_clk),
	.rst_n(C_rst_n),
	.in_valid(C_IN_VALID),
	.in_x(C_IN_X),
	.in_y(C_IN_Y),
	.move_num(C_MOVE_NUM),
    .priority_num(C_PRIORITY_NUM),
    .out_valid(C_OUT_VALID),
    .out_x(C_OUT_X),
    .out_y(C_OUT_Y),
    .move_out(C_MOVE_OUT)
);


// Input Pads
P8C I_CLK      ( .Y(C_clk),       .P(clk),       .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b0), .CSEN(1'b1) );
P8C I_RESET    ( .Y(C_rst_n),     .P(rst_n),     .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_VALID    ( .Y(C_IN_VALID),  .P(in_valid),  .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_INX_0    ( .Y(C_IN_X[0]),   .P(in_x[0]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_INX_1    ( .Y(C_IN_X[1]),   .P(in_x[1]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_INX_2    ( .Y(C_IN_X[2]),   .P(in_x[2]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_INY_0    ( .Y(C_IN_Y[0]),   .P(in_y[0]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_INY_1    ( .Y(C_IN_Y[1]),   .P(in_y[1]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_INY_2    ( .Y(C_IN_Y[2]),   .P(in_y[2]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );

P4C I_MN_0     ( .Y(C_MOVE_NUM[0]),   .P(move_num[0]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_MN_1     ( .Y(C_MOVE_NUM[1]),   .P(move_num[1]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_MN_2     ( .Y(C_MOVE_NUM[2]),   .P(move_num[2]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_MN_3     ( .Y(C_MOVE_NUM[3]),   .P(move_num[3]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_MN_4     ( .Y(C_MOVE_NUM[4]),   .P(move_num[4]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PN_0     ( .Y(C_PRIORITY_NUM[0]),  .P(priority_num[0]),  .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PN_1     ( .Y(C_PRIORITY_NUM[1]),  .P(priority_num[1]),  .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PN_2     ( .Y(C_PRIORITY_NUM[2]),  .P(priority_num[2]),  .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
// Output Pads
P8C O_VALID      ( .A(C_OUT_VALID),.P(out_valid),.ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTX_0     ( .A(C_OUT_X[0]), .P(out_x[0]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTX_1     ( .A(C_OUT_X[1]), .P(out_x[1]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTX_2     ( .A(C_OUT_X[2]), .P(out_x[2]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTY_0     ( .A(C_OUT_Y[0]), .P(out_y[0]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTY_1     ( .A(C_OUT_Y[1]), .P(out_y[1]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTY_2     ( .A(C_OUT_Y[2]), .P(out_y[2]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_MO_0       ( .A(C_MOVE_OUT[0]),.P(move_out[0]),.ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_MO_1       ( .A(C_MOVE_OUT[1]),.P(move_out[1]),.ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_MO_2       ( .A(C_MOVE_OUT[2]),.P(move_out[2]),.ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_MO_3       ( .A(C_MOVE_OUT[3]),.P(move_out[3]),.ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_MO_4       ( .A(C_MOVE_OUT[4]),.P(move_out[4]),.ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
// IO power 
PVDDR VDDP0 ();
PVSSR GNDP0 ();
PVDDR VDDP1 ();
PVSSR GNDP1 ();
PVDDR VDDP2 ();
PVSSR GNDP2 ();
PVDDR VDDP3 ();
PVSSR GNDP3 ();
PVDDR VDDP4 ();
PVSSR GNDP4 ();
PVDDR VDDP5 ();
PVSSR GNDP5 ();
PVDDR VDDP6 ();
PVSSR GNDP6 ();
PVDDR VDDP7 ();
PVSSR GNDP7 ();

// Core power
PVDDC VDDC0 ();
PVSSC GNDC0 ();
PVDDC VDDC1 ();
PVSSC GNDC1 ();
PVDDC VDDC2 ();
PVSSC GNDC2 ();
PVDDC VDDC3 ();
PVSSC GNDC3 ();

endmodule