//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//      (C) Copyright NCTU OASIS Lab      
//            All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   2021 ICLAB fall Course Online Test
//   Author    : Echin-Wang    (echinwang861025@gmail.com)
//               ShaoWen-Cheng (shaowen0213@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//   Release version : v1.0
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`include "PATTERN.v"

module TESTBED();

wire clk;
wire rst_n;

wire in_valid,out_valid;
wire [9:0] in_x,in_y,out_x,out_y;
wire [24:0] out_area;


GF U_GF(
	.clk(clk),
	.rst_n(rst_n),
	.in_valid(in_valid),
	.in_x(in_x),
	.in_y(in_y),
	.out_valid(out_valid),
	.out_x(out_x),
	.out_y(out_y),
	.out_area(out_area)
);

PATTERN U_PATTERN(
	.clk(clk),
	.rst_n(rst_n),
	.in_valid(in_valid),
	.in_x(in_x),
	.in_y(in_y),
	.out_valid(out_valid),
	.out_x(out_x),
	.out_y(out_y),
	.out_area(out_area)
);

initial begin
	`ifdef RTL
		$fsdbDumpfile("GF.fsdb");
		$fsdbDumpvars(0,"+mda");
		$fsdbDumpvars();
	`endif
	`ifdef GATE
		$sdf_annotate("GF_SYN.sdf",U_GF);
		$fsdbDumpfile("GF_SYN.fsdb");
		$fsdbDumpvars();
	`endif
end

endmodule
