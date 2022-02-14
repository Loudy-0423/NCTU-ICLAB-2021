`ifdef RTL
	`timescale 1ns/10ps
	`include "NN.v"  
	`define CYCLE_TIME 15.0
`endif
`ifdef GATE
	`timescale 1ns/1ps
	`include "NN_SYN.v"
	`define CYCLE_TIME 15.2
`endif

//synopsys translate_off
`include "/usr/synthesis/dw/sim_ver/DW_fp_cmp.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_add.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_sub.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_addsub.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_mult.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_div.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_dp3.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_dp4.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_sum4.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_ifp_conv.v"
`include "/usr/synthesis/dw/sim_ver/DW_ifp_addsub.v"
`include "/usr/synthesis/dw/sim_ver/DW_ifp_fp_conv.v"
`include "/usr/synthesis/dw/sim_ver/DW_ifp_mult.v"
//synopsys translate_on

module PATTERN(
	// Output signals
	clk,
	rst_n,
	in_valid_d,
	in_valid_t,
	in_valid_w1,
	in_valid_w2,
	data_point,
	target,
	weight1,
	weight2,
	// Input signals
	out_valid,
	out
);
//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 1;
parameter inst_arch_type = 0;
parameter MLNUM  = 8;
parameter PATNUM = 25;
parameter DATANUM= 100;

//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
output reg clk, rst_n, in_valid_d, in_valid_t, in_valid_w1, in_valid_w2;
output reg [inst_sig_width+inst_exp_width:0] data_point, target;
output reg [inst_sig_width+inst_exp_width:0] weight1, weight2;
input	out_valid;
input	[inst_sig_width+inst_exp_width:0] out;

//================================================================
// parameters & integer
//================================================================
real CYCLE = `CYCLE_TIME;
real delay_time = 1;
integer i, mlcount, patcount, data_count, wait_val_time, total_latency;
integer weight_1_store[0:11], weight_2_store[0:2], data_store[0:3],target_store , ans;

//================================================================
// REG & WIRE
//================================================================
reg  sign;
reg  [7:0]exp;
reg  [22:0]mantisa;
reg  [31:0]learning_rate;
reg  [inst_sig_width+inst_exp_width:0] buff[0:2];
reg  [inst_sig_width+inst_exp_width:0] varaince[0:3];
reg  [inst_sig_width+inst_exp_width:0] dp4_a, dp4_b, dp4_c, dp4_d, dp4_e, dp4_f, dp4_g, dp4_h; 
reg  [inst_sig_width+inst_exp_width:0] dp3_a, dp3_b, dp3_c, dp3_d, dp3_e, dp3_f;
reg  [inst_sig_width+inst_exp_width:0] mult_a_1, mult_a_2, mult_a_3, mult_a_4; 
reg  [inst_sig_width+inst_exp_width:0] mult_b_1, mult_b_2, mult_b_3, mult_b_4; 
reg  [inst_sig_width+inst_exp_width:0] div_a_1, div_b_1, div_a_2, div_b_2;
reg  [inst_sig_width+inst_exp_width:0] sum_a, sum_b, sum_c, sum_d;
reg  [inst_sig_width+inst_exp_width:0] sub_a_1, sub_a_2, sub_a_3, sub_a_4;
reg  [inst_sig_width+inst_exp_width:0] sub_b_1, sub_b_2, sub_b_3, sub_b_4;
reg  [inst_sig_width+inst_exp_width:0] a1, a2 ,b1, b2;
reg  [inst_sig_width+inst_exp_width:0] sum_store_1[0:2], sum_store_2[0:2];
reg  [inst_sig_width+inst_exp_width:0] relu[0:2], relu_d[0:2];
wire [inst_sig_width+inst_exp_width:0] dp4_out;
wire [inst_sig_width+inst_exp_width:0] dp3_out;
wire [inst_sig_width+inst_exp_width:0] mult_out_1, mult_out_2, mult_out_3, mult_out_4;
wire [inst_sig_width+inst_exp_width:0] div_out_1, div_out_2;
wire [inst_sig_width+inst_exp_width:0] sum_out;
wire [inst_sig_width+inst_exp_width:0] sub_out_1, sub_out_2, sub_out_3, sub_out_4;
wire z1, z2;

//================================================================
// clock
//================================================================
initial 
begin
	clk = 0;
end
always #(CYCLE/2.0) clk = ~clk;

//================================================================
// initial
//================================================================
/*DW_fp_dp4  #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type) DP41 (.a(dp4_a),.b(dp4_b),.c(dp4_c),.d(dp4_d),.e(dp4_e),.f(dp4_f),.g(dp4_g),.h(dp4_h),.rnd(3'b000),.z(dp4_out));
DW_fp_dp3  #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type) DP31 (.a(dp3_a),.b(dp3_b),.c(dp3_c),.d(dp3_d),.e(dp3_e),.f(dp3_f),.rnd(3'b000),.z(dp3_out)); */
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M1 (.a(mult_a_1), .b(mult_b_1), .rnd(3'b000), .z(mult_out_1));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M2 (.a(mult_a_2), .b(mult_b_2), .rnd(3'b000), .z(mult_out_2));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M3 (.a(mult_a_3), .b(mult_b_3), .rnd(3'b000), .z(mult_out_3));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M4 (.a(mult_a_4), .b(mult_b_4), .rnd(3'b000), .z(mult_out_4));
DW_fp_div  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) D1 (.a(div_a_1), .b(div_b_1), .rnd(3'b000), .z(div_out_1));
DW_fp_div  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) D2 (.a(div_a_2), .b(div_b_2), .rnd(3'b000), .z(div_out_2));
DW_fp_sum4 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type) S1 (.a(sum_a),.b(sum_b),.c(sum_c),.d(sum_d),.rnd(3'b000),.z(sum_out));
DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U1 ( .a(sub_a_1), .b(sub_b_1), .rnd(3'b000), .z(sub_out_1));
DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U2 ( .a(sub_a_2), .b(sub_b_2), .rnd(3'b000), .z(sub_out_2));
DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U3 ( .a(sub_a_3), .b(sub_b_3), .rnd(3'b000), .z(sub_out_3));
DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U4 ( .a(sub_a_4), .b(sub_b_4), .rnd(3'b000), .z(sub_out_4));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C1 ( .a(a1), .b(b1), .zctr(0), .agtb(z1));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C2 ( .a(a2), .b(b2), .zctr(0), .agtb(z2));


initial 
begin
	
	rst_n = 1'b1;
	in_valid_w1 = 1'b0;
	in_valid_w2 = 1'b0;
	in_valid_d = 1'b0;
	in_valid_t = 1'b0;
	total_latency = 0;
	learning_rate = 32'h358637bd;
	
	force clk = 0;
	reset_signal_task;
	for (mlcount=1; mlcount<=MLNUM; mlcount=mlcount+1)begin
		learning_rate = 32'h358637bd;
		input_weight_task;
		for(patcount=1; patcount<=PATNUM; patcount=patcount+1) 
		begin
			if(patcount%4==1 && patcount!=1)begin
				div_a_1 = learning_rate;
				div_b_1 = 32'h40000000;
				#delay_time;
				learning_rate = div_out_1;
			end
			for(data_count=1; data_count<=DATANUM; data_count=data_count+1)
			begin
				input_data_task;
				calculate_ans;
				wait_out_valid;
				check_ans;
			end
		end
	end
	YOU_PASS_task;
end


//================================================================
// task
//================================================================
task reset_signal_task; 
begin 
  #(0.5);	rst_n=0;
  #(CYCLE/2);
  if((out_valid !== 0)||(out !== 0)) 
  begin
    $display("**************************************************************");
    $display("*   Output signal should be 0 after initial RESET at %4t     *",$time);
    $display("**************************************************************");
    $finish;
  end
  #(10);	rst_n=1;
  #(3);		release clk;
end 
endtask

task input_weight_task;
begin
	repeat(2)@(negedge clk);
	in_valid_w1 = 1'b1;
	in_valid_w2 = 1'b1;
	
	for(i=0;i<12;i=i+1)
	begin
		//weight1 = $urandom_range(1000000000, 0);
		sign = $random();
		exp  = $urandom_range(130,120);
		mantisa = $random();
		weight1 = {sign,exp,mantisa};
		weight_1_store[i] = weight1;
		if(i>2) begin
			weight2 = 32'bx;
			in_valid_w2 = 1'b0;
		end
		else begin
			//weight2 = $urandom_range(1000000000, 0);
			sign = $random();
			exp  = $urandom_range(130,120);
			mantisa = $random();
			weight2 = {sign,exp,mantisa}; 
			weight_2_store[i] = weight2;
		end
		@(negedge clk);
	end
	in_valid_w1 = 1'b0;
	in_valid_w2 = 1'b0;
	weight1 = 32'bx;
	weight2 = 32'bx;
end
endtask

task input_data_task;
begin
	repeat(2)@(negedge clk);
	in_valid_d = 1'b1;
	in_valid_t = 1'b1;
	
	for(i=0;i<4;i=i+1)
	begin
		//data_point = $urandom_range(1000000000, 0);
		sign = $random();
		exp  = $urandom_range(130,120);
		mantisa = $random();
		data_point = {sign,exp,mantisa};
		data_store[i] = data_point;
		if(i>0) begin
			target = 32'bx;
			in_valid_t = 1'b0;
		end
		else begin
			//target = $urandom_range(1000000000, 0);
			sign = 0;
			exp  = $urandom_range(130,120);
			mantisa = $random(); 
			target = {sign,exp,mantisa};
			target_store = target;
		end
		@(negedge clk);
	end
	in_valid_d = 1'b0;
	in_valid_t = 1'b0;
	data_point = 32'bx;
	target = 32'bx;
end
endtask

task calculate_ans;
begin
	

	mult_a_1 = data_store[0];
	mult_a_2 = data_store[1];
	mult_a_3 = data_store[2];
	mult_a_4 = data_store[3];
	mult_b_1 = weight_1_store[0];
	mult_b_2 = weight_1_store[1];
	mult_b_3 = weight_1_store[2];
	mult_b_4 = weight_1_store[3];
	#delay_time;
	
	sum_a = mult_out_1;
	sum_b = mult_out_2;
	sum_c = mult_out_3;
	sum_d = mult_out_4;
	#delay_time;
	
	sum_store_1[0] = sum_out;
	if(sum_out[31]===0) begin
		relu[0] = sum_out;
		if(sum_out===0) begin
			relu_d[0] = 0;
		end
		else begin
			relu_d[0] = 32'h3f800000;
		end
	end
	else begin
		relu[0] = 0;
		relu_d[0] = 0;
	end
	#delay_time;
	
	mult_a_1 = data_store[0];
	mult_a_2 = data_store[1];
	mult_a_3 = data_store[2];
	mult_a_4 = data_store[3];
	mult_b_1 = weight_1_store[4];
	mult_b_2 = weight_1_store[5];
	mult_b_3 = weight_1_store[6];
	mult_b_4 = weight_1_store[7];
	#delay_time;
	
	sum_a = mult_out_1;
	sum_b = mult_out_2;
	sum_c = mult_out_3;
	sum_d = mult_out_4;
	#delay_time;
	
	sum_store_1[1] = sum_out;
	if(sum_out[31]===0) begin
		relu[1] = sum_out;
		if(sum_out===0) begin
			relu_d[1] = 0;
		end
		else begin
			relu_d[1] = 32'h3f800000;
		end
	end
	else begin
		relu[1] = 0;
		relu_d[1] = 0;
	end
	#delay_time;
	
	mult_a_1 = data_store[0];
	mult_a_2 = data_store[1];
	mult_a_3 = data_store[2];
	mult_a_4 = data_store[3];
	mult_b_1 = weight_1_store[8 ];
	mult_b_2 = weight_1_store[9 ];
	mult_b_3 = weight_1_store[10];
	mult_b_4 = weight_1_store[11];
	#delay_time;
	
	sum_a = mult_out_1;
	sum_b = mult_out_2;
	sum_c = mult_out_3;
	sum_d = mult_out_4;
	#delay_time;
	
	sum_store_1[2] = sum_out;
	if(sum_out[31]===0) begin
		relu[2] = sum_out;
		if(sum_out===0) begin
			relu_d[2] = 0;
		end
		else begin
			relu_d[2] = 32'h3f800000;
		end
	end
	else begin
		relu[2] = 0;
		relu_d[2] = 0;
	end
	#delay_time;
	
	mult_a_1 = relu[0];
	mult_a_2 = relu[1];
	mult_a_3 = relu[2];
	mult_a_4 = 0;
	mult_b_1 = weight_2_store[0];
	mult_b_2 = weight_2_store[1];
	mult_b_3 = weight_2_store[2];
	mult_b_4 = 0;
	#delay_time;
	
	
	sum_a = mult_out_1;
	sum_b = mult_out_2;
	sum_c = mult_out_3;
	sum_d = mult_out_4;
	#delay_time;
	
	ans = sum_out;
	sub_a_1 = sum_out;
	sub_b_1 = target_store;
	#delay_time;
	varaince[0] = sub_out_1;
	#delay_time;
	
	mult_a_1 = varaince[0];
	mult_a_2 = varaince[0];
	mult_a_3 = varaince[0];
	mult_b_1 = weight_2_store[0];
	mult_b_2 = weight_2_store[1];
	mult_b_3 = weight_2_store[2];
	#delay_time;
	
	mult_a_1 = mult_out_1;
	mult_a_2 = mult_out_2;
	mult_a_3 = mult_out_3;
	mult_b_1 = relu_d[0];
	mult_b_2 = relu_d[1];
	mult_b_3 = relu_d[2];
	#delay_time;
	
	varaince[1] = mult_out_1;
	varaince[2] = mult_out_2;
	varaince[3] = mult_out_3;
	mult_a_1 = learning_rate;
	mult_b_1 = varaince[0];
	#delay_time;
	
	mult_a_1 = mult_out_1;
	mult_a_2 = mult_out_1;
	mult_a_3 = mult_out_1;
	mult_b_1 = relu[0];
	mult_b_2 = relu[1];
	mult_b_3 = relu[2];
	#delay_time;
	
	sub_a_1 = weight_2_store[0];
	sub_b_1 = mult_out_1;
	sub_a_2 = weight_2_store[1];
	sub_b_2 = mult_out_2;
	sub_a_3 = weight_2_store[2];
	sub_b_3 = mult_out_3;
	
	mult_a_1 = learning_rate;
	mult_b_1 = varaince[1];
	mult_a_2 = learning_rate;
	mult_b_2 = varaince[2];
	mult_a_3 = learning_rate;
	mult_b_3 = varaince[3];
	#delay_time;
	
	weight_2_store[0] = sub_out_1;
	weight_2_store[1] = sub_out_2;
	weight_2_store[2] = sub_out_3;
	
	buff[0] = mult_out_1;
	buff[1] = mult_out_2;
	buff[2] = mult_out_3;
	mult_a_1 = mult_out_1;
	mult_b_1 = data_store[0];
	mult_a_2 = mult_out_1;
	mult_b_2 = data_store[1];
	mult_a_3 = mult_out_1;
	mult_b_3 = data_store[2];
	mult_a_4 = mult_out_1;
	mult_b_4 = data_store[3];
	#delay_time;
	
	sub_a_1 = weight_1_store[0];
	sub_b_1 = mult_out_1;
	sub_a_2 = weight_1_store[1];
	sub_b_2 = mult_out_2;
	sub_a_3 = weight_1_store[2];
	sub_b_3 = mult_out_3;
	sub_a_4 = weight_1_store[3];
	sub_b_4 = mult_out_4;
	
	mult_a_1 = buff[1];
	mult_b_1 = data_store[0];
	mult_a_2 = buff[1];
	mult_b_2 = data_store[1];
	mult_a_3 = buff[1];
	mult_b_3 = data_store[2];
	mult_a_4 = buff[1];
	mult_b_4 = data_store[3];
	#delay_time;
	
	weight_1_store[0] = sub_out_1;
	weight_1_store[1] = sub_out_2;
	weight_1_store[2] = sub_out_3;
	weight_1_store[3] = sub_out_4;
	
	sub_a_1 = weight_1_store[4];
	sub_b_1 = mult_out_1;
	sub_a_2 = weight_1_store[5];
	sub_b_2 = mult_out_2;
	sub_a_3 = weight_1_store[6];
	sub_b_3 = mult_out_3;
	sub_a_4 = weight_1_store[7];
	sub_b_4 = mult_out_4;
	
	mult_a_1 = buff[2];
	mult_b_1 = data_store[0];
	mult_a_2 = buff[2];
	mult_b_2 = data_store[1];
	mult_a_3 = buff[2];
	mult_b_3 = data_store[2];
	mult_a_4 = buff[2];
	mult_b_4 = data_store[3];
	#delay_time;
	
	weight_1_store[4] = sub_out_1;
	weight_1_store[5] = sub_out_2;
	weight_1_store[6] = sub_out_3;
	weight_1_store[7] = sub_out_4;
	
	sub_a_1 = weight_1_store[8];
	sub_b_1 = mult_out_1;
	sub_a_2 = weight_1_store[9];
	sub_b_2 = mult_out_2;
	sub_a_3 = weight_1_store[10];
	sub_b_3 = mult_out_3;
	sub_a_4 = weight_1_store[11];
	sub_b_4 = mult_out_4;
	#delay_time;
	
	weight_1_store[8 ] = sub_out_1;
	weight_1_store[9 ] = sub_out_2;
	weight_1_store[10] = sub_out_3;
	weight_1_store[11] = sub_out_4;
	
end
endtask


task wait_out_valid;
begin
  wait_val_time = 0;
  while(out_valid !== 1) begin
	wait_val_time = wait_val_time + 1;
	if(wait_val_time == 300)
	begin
		$display("***************************************************************");
		$display("*        The execution latency are over 300 cycles.           *");
		$display("***************************************************************");
		repeat(2)@(negedge clk);
		$finish;
	end
	@(negedge clk);
  end
  total_latency = total_latency + wait_val_time;
end
endtask

task check_ans;
begin
	a1 = out;
	b1 = ans;
	#delay_time;
	
	if(z1) begin
		sub_a_1 = out;
		sub_b_1 = ans;
	end else begin
		sub_a_1 = ans;
		sub_b_1 = out;
	end
	#delay_time;
	
	div_a_1 = sub_out_1;
	div_b_1 = ans;
	#delay_time;
	
	a1 = div_out_1;
	b1 = 32'h38D1B000;
	#delay_time;
	
	if(z1)
	begin
		$display ("--------------------------------------------------------------------");
		$display ("                 PATTERN #%3d-%3d-%3d  FAILED!!!                    ",mlcount ,patcount, data_count);
		$display ("                      Ans: %h, Yours: %h                            ",ans, out);		
		$display ("--------------------------------------------------------------------");
		repeat(2) @(negedge clk);		
		$finish;
    end
	$display("\033[0;34mPASS PATTERN NO.%3d-%3d-%3d,\033[m \033[0;32mexecution cycle : %3d\033[m",mlcount ,patcount, data_count ,wait_val_time);
end
endtask

task YOU_PASS_task; 
begin
  $display ("--------------------------------------------------------------------");
  $display ("             ~(￣▽￣)~(＿△＿)~(￣▽￣)~(＿△＿)~(￣▽￣)~              ");
  $display ("                         Congratulations!                           ");
  $display ("                  You have passed all patterns!                     ");
  $display ("--------------------------------------------------------------------");        
     
repeat(2) @(negedge clk);		
$finish;
end
endtask

endmodule
