// synopsys translate_off
`include "/usr/synthesis/dw/sim_ver/DW_fp_mult.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_add.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_sub.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_addsub.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_sum4.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_sum3.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_ifp_conv.v"
`include "/usr/synthesis/dw/sim_ver/DW_ifp_addsub.v"
`include "/usr/synthesis/dw/sim_ver/DW_ifp_fp_conv.v"


// synopsys translate_on

module NN(
	// Input signals
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
	// Output signals
	out_valid,
	out
);

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 1;
parameter inst_arch = 1;

parameter LEARNING_RATE = 32'b0_0110_1011_00001100011011110111101;
parameter LEARNING_RATE1 = 32'b0_0110_1010_00001100011011110111101;
parameter LEARNING_RATE2 = 32'b0_0110_1001_00001100011011110111101;
parameter LEARNING_RATE3 = 32'b0_0110_1000_00001100011011110111101;
parameter LEARNING_RATE4 = 32'b0_0110_0111_00001100011011110111101;
parameter LEARNING_RATE5 = 32'b0_0110_0110_00001100011011110111101;
parameter LEARNING_RATE6 = 32'b0_0110_0101_00001100011011110111101;

parameter ZERO = 32'b0_0000_0000_00000000000000000000000 ;
parameter ONE = 32'b0_0111_1111_00000000000000000000000 ;
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input  clk, rst_n, in_valid_d, in_valid_t, in_valid_w1, in_valid_w2;
input [inst_sig_width+inst_exp_width:0] data_point, target;
input [inst_sig_width+inst_exp_width:0] weight1, weight2;
output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
parameter RESET  = 'd0;
parameter WAIT  = 'd1;
parameter INPUT_W  = 'd2;
parameter INPUT_D  = 'd3;
parameter CAL  = 'd4;
parameter OUTPUT = 'd5;

reg [2:0] n_state;
reg [2:0] state;
reg [inst_sig_width+inst_exp_width:0] w1 [11:0];
reg [inst_sig_width+inst_exp_width:0] w2 [2:0];
reg [inst_sig_width+inst_exp_width:0] data [3:0];
reg [inst_sig_width+inst_exp_width:0] tar;
integer i, j;
reg [3:0] cnt_w;
reg [2:0] cnt_d;
reg [11:0] cnt_lr;
reg [inst_sig_width+inst_exp_width:0] lr_dv;


wire [inst_sig_width+inst_exp_width:0] h_1 [11:0];
wire [inst_sig_width+inst_exp_width:0] h_1_sum [2:0];
wire [inst_sig_width+inst_exp_width:0] y_1 [2:0];
wire [inst_sig_width+inst_exp_width:0] h_2 [2:0];
wire [inst_sig_width+inst_exp_width:0] y_2;
wire [inst_sig_width+inst_exp_width:0] delta2;
wire [inst_sig_width+inst_exp_width:0] goh [2:0];
wire [inst_sig_width+inst_exp_width:0] h_3 [2:0];
wire [inst_sig_width+inst_exp_width:0] delta1 [2:0];
wire [inst_sig_width+inst_exp_width:0] r1_1 [11:0];
wire [inst_sig_width+inst_exp_width:0] r1_2 [11:0];
wire [inst_sig_width+inst_exp_width:0] r2_1 [2:0];
wire [inst_sig_width+inst_exp_width:0] r2_2 [2:0];
wire [inst_sig_width+inst_exp_width:0] w1_n [11:0];
wire [inst_sig_width+inst_exp_width:0] w2_n [2:0];



reg pipeline [11:0];
reg flag;


//---------------------------------------------------------------------
//   Design
//---------------------------------------------------------------------

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		state <= RESET;
	end
	else begin
		state <= n_state;
	end
end
	
	
//FSM next state assignment
always@(*) begin
    case(state)
        
        RESET: begin
            n_state = (rst_n)? WAIT : RESET;
        end
		
		WAIT: begin
            n_state = (in_valid_w1)? INPUT_W : WAIT;
        end

        INPUT_W: begin
            n_state = (out_valid == 0 && cnt_lr == 2500)? WAIT : ((in_valid_w1) || (!in_valid_w1 && !in_valid_d))? INPUT_W : INPUT_D;
        end
		
		INPUT_D: begin
            n_state = (in_valid_d)? INPUT_D : CAL;
        end

        CAL: begin
            n_state = (pipeline[5] == 1)? OUTPUT : CAL;
        end
        
        OUTPUT: begin
            n_state = (pipeline[5] == 1)? INPUT_W : OUTPUT;
        end
        
        default: begin
            n_state = state;
        end
    
    endcase
end 

//input
always@(posedge clk) begin
    case (state)
        RESET: begin
			for(i=0;i<12;i=i+1) begin
				w1[i] <= 0;
			end
			for(j=0;j<3;j=j+1) begin
				w2[j] <= 0;
			end
        end
		WAIT: begin
			if(in_valid_w1) begin
				w1[0] <= weight1;
				w2[0] <= weight2;
			end
        end
		
        INPUT_W: begin
			if(in_valid_d) begin
				data[0] <= data_point;
			end
			if(in_valid_t) begin
				tar <= target;
			end
			
			
			if(in_valid_w1) begin
				w1[cnt_w-1] <= weight1;
			end
			else begin
				if(flag == 1 && pipeline[11] == 1) begin//11
					for(i=0;i<12;i=i+1)begin
						w1[i] <= w1_n[i];
					end
				end
			end
			
			
			if(in_valid_w2) begin
				w2[cnt_w-1] <= weight2;
			end
			else begin
				if(flag == 1 && pipeline[11] == 1) begin//11
					for(i=0;i<3;i=i+1)begin
						w2[i] <= w2_n[i];
					end
				end
			end
        end
		
		INPUT_D: begin
            data[cnt_d+1] <= data_point;
			if(flag == 1 && pipeline[11] == 1) begin//11
				for(i=0;i<12;i=i+1)begin
					w1[i] <= w1_n[i];
				end
			end
			if(flag == 1 && pipeline[11] == 1) begin//11
				for(i=0;i<3;i=i+1)begin
					w2[i] <= w2_n[i];
				end
			end
        end
		
        CAL: begin
			if(flag == 1 && pipeline[11] == 1) begin//11
				for(i=0;i<12;i=i+1)begin
					w1[i] <= w1_n[i];
				end
			end
			if(flag == 1 && pipeline[11] == 1) begin//11
				for(i=0;i<3;i=i+1)begin
					w2[i] <= w2_n[i];
				end
			end
		
        end
        OUTPUT: begin
        end
        default: begin
        end
    endcase
    
end

//pipeline_stage
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=1;i<12;i=i+1) begin
			pipeline[i] <= 0;
		end
		pipeline[0] <= 1;
	end
	else begin
		if(flag == 1 && pipeline[11] != 1) begin
			for(i=0;i<11;i=i+1) begin
				pipeline[i+1] <= pipeline[i];
			end
		end
		else begin
			for(i=1;i<12;i=i+1) begin
				pipeline[i] <= 0;
			end
			pipeline[0] <= 1;
		end			
	end
end

//flag
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		flag <= 0;
	end
	else begin
		if(state == CAL) begin
			flag <= 1;
		end
		else if(out_valid == 0 && cnt_lr == 0) begin
			flag <= 0;
		end
	end
	
end

//counter
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_w <= 0;
		cnt_d <= 0;
	end
	else begin
		if(state == WAIT || state == INPUT_W) begin
			cnt_w <= cnt_w+1;
		end
		if(state == INPUT_D) begin
			cnt_d <= cnt_d+1;
		end
		if(state == OUTPUT) begin
			cnt_d <= 0;
		end
		if(cnt_lr == 2500 && pipeline[7] == 1 && pipeline[8] == 0) begin
			cnt_w <= 0;
		end
		
	end
	
end

//learning rate counter
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_lr <= 0;
	end
	else begin
		if(in_valid_t == 1)begin
			cnt_lr <= cnt_lr+in_valid_t;
		end
		else if(in_valid_w2 == 1)begin
			cnt_lr <= 0;
		end
		else begin
			cnt_lr <= cnt_lr;
		end
	end
	
end

//learning rate divider
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		lr_dv <= LEARNING_RATE;
	end
	else begin
		if(cnt_lr <= 400)begin
			lr_dv <= LEARNING_RATE;
			//lr_dv <= 0;
		end
		else if(cnt_lr <= 800)begin
			lr_dv <= LEARNING_RATE1;
			//lr_dv <= 1;
		end
		else if(cnt_lr <= 1200)begin
			lr_dv <= LEARNING_RATE2;
			//lr_dv <= 2;
		end
		else if(cnt_lr <= 1600)begin
			lr_dv <= LEARNING_RATE3;
			//lr_dv <= 3;
		end
		else if(cnt_lr <= 2000)begin
			lr_dv <= LEARNING_RATE4;
			//lr_dv <= 4;
		end
		else if(cnt_lr <= 2400)begin
			lr_dv <= LEARNING_RATE5;
			//lr_dv <= 5;
		end
		else if(cnt_lr <= 2500)begin
			lr_dv <= LEARNING_RATE6;
			//lr_dv <= 6;
		end
		else begin
			lr_dv <= LEARNING_RATE;
			//lr_dv <= 0;
		end
	end
	
end

//---------------------------------------------------------------------
//   REG DECLARATION
//---------------------------------------------------------------------

reg [inst_sig_width+inst_exp_width:0] h_1_r [11:0];
reg [inst_sig_width+inst_exp_width:0] h_1_sum_r [2:0];
reg [inst_sig_width+inst_exp_width:0] y_1_r [2:0];
reg [inst_sig_width+inst_exp_width:0] h_2_r [2:0];
reg [inst_sig_width+inst_exp_width:0] y_2_r;
reg [inst_sig_width+inst_exp_width:0] delta2_r;
reg [inst_sig_width+inst_exp_width:0] goh_r [2:0];
reg [inst_sig_width+inst_exp_width:0] h_3_r [2:0];
reg [inst_sig_width+inst_exp_width:0] delta1_r [2:0];
reg [inst_sig_width+inst_exp_width:0] r1_1_r [11:0];
reg [inst_sig_width+inst_exp_width:0] r1_2_r [11:0];
reg [inst_sig_width+inst_exp_width:0] r2_1_r [2:0];
reg [inst_sig_width+inst_exp_width:0] r2_2_r [2:0];



//---------------------------------------------------------------------
//   Pipeline register
//---------------------------------------------------------------------

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0;i<12;i=i+1)begin
			h_1_r[i] <= ZERO;
		end
	end
	else begin
		if(flag == 1 && pipeline[1] == 1 && in_valid_d != 1) begin
			for(i=0;i<12;i=i+1)begin
				h_1_r[i] <= h_1[i];
			end
		end
		
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0;i<3;i=i+1)begin
			h_1_sum_r[i] <= ZERO;
		end
	end
	else begin
		if(flag == 1 && pipeline[2] == 1) begin
			for(i=0;i<3;i=i+1)begin
				h_1_sum_r[i] <= h_1_sum[i];
			end
		end
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0;i<3;i=i+1)begin
			y_1_r[i] <= ZERO;
		end
	end
	else begin
		if(flag == 1 && pipeline[3] == 1) begin
			for(i=0;i<3;i=i+1)begin
				y_1_r[i] <= y_1[i];
			end
		end
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0;i<3;i=i+1)begin
			h_2_r[i] <= ZERO;
		end
	end
	else begin
		if(flag == 1 && pipeline[4] == 1 && in_valid_d != 1) begin
			for(i=0;i<3;i=i+1)begin
				h_2_r[i] <= h_2[i];
			end
		end
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		y_2_r <= ZERO;
	end
	else begin
		if(flag == 1 && pipeline[5] == 1) begin
			y_2_r <= y_2;
		end
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		delta2_r <= ZERO;
	end
	else begin
		if(flag == 1 && pipeline[6] == 1 && in_valid_d != 1) begin
			delta2_r <= delta2;
		end
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0;i<3;i=i+1)begin
			goh_r[i] <= ZERO;
			h_3_r[i] <= ZERO;
		end
	end
	else begin
		if(flag == 1 && pipeline[7] == 1 && in_valid_d != 1) begin
			for(i=0;i<3;i=i+1)begin
				goh_r[i] <= goh[i];
				h_3_r[i] <= h_3[i];
			end
		end
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0;i<3;i=i+1) begin
			delta1_r[i] <= ZERO;
		end
	end
	else begin
		if(flag == 1 && pipeline[8] == 1 && in_valid_d != 1) begin
			for(i=0;i<3;i=i+1) begin
				delta1_r[i] <= delta1[i];
			end
		end
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0;i<3;i=i+1)begin
			r2_1_r[i] <= ZERO;
		end
	end
	else begin
		if(flag == 1 && pipeline[9] == 1) begin
			for(i=0;i<3;i=i+1)begin
				r2_1_r[i] <= r2_1[i];
			end
		end
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0;i<12;i=i+1)begin
			r1_1_r[i] <= ZERO;
		end
	end
	else begin
		if(flag == 1 && pipeline[9] == 1 && in_valid_t == 1) begin
			for(i=0;i<12;i=i+1)begin
				r1_1_r[i] <= r1_1[i];
			end
		end
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0;i<3;i=i+1)begin
			r2_2_r[i] <= ZERO;
		end
	end
	else begin
		if(flag == 1 && pipeline[10] == 1 && cnt_d == 0) begin
			for(i=0;i<3;i=i+1)begin
				r2_2_r[i] <= r2_2[i];
			end
		end
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0;i<12;i=i+1)begin
			r1_2_r[i] <= ZERO;
		end
	end
	else begin
		if(flag == 1 && pipeline[10] == 1 && cnt_d == 0) begin
			for(i=0;i<12;i=i+1)begin
				r1_2_r[i] <= r1_2[i];
			end
		end
	end
end





//---------------------------------------------------------------------
//   IP calculation
//---------------------------------------------------------------------
genvar k;
//forward layer1-1
generate
for(k=0;k<3;k=k+1) begin
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M1 (.a(data[0]), .b(w1[(k<<2)]), .rnd(3'b000), .z(h_1[(k<<2)]));
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M2 (.a(data[1]), .b(w1[(k<<2)+1]), .rnd(3'b000), .z(h_1[(k<<2)+1]));
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M3 (.a(data[2]), .b(w1[(k<<2)+2]), .rnd(3'b000), .z(h_1[(k<<2)+2]));
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M4 (.a(data[3]), .b(w1[(k<<2)+3]), .rnd(3'b000), .z(h_1[(k<<2)+3]));
end
endgenerate


//forward layer1-2
generate

for(k=0;k<3;k=k+1) begin
	DW_fp_sum4 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) S1 (.a(h_1_r[k<<2]),.b(h_1_r[(k<<2)+1]),.c(h_1_r[(k<<2)+2]),.d(h_1_r[(k<<2)+3]),.rnd(3'b000),.z(h_1_sum[k]));
end
endgenerate


generate
for(k=0;k<3;k=k+1) begin
	assign y_1[k] = (h_1_sum_r[k][31]==1'b1) ? ZERO : h_1_sum_r[k];
end
endgenerate

//forward layer2
generate
for(k=0;k<3;k=k+1) begin
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M1 (.a(y_1_r[k]), .b(w2[k]), .rnd(3'b000), .z(h_2[k]));
end
endgenerate

DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) S1 (.a(h_2_r[0]),.b(h_2_r[1]),.c(h_2_r[2]),.rnd(3'b000),.z(y_2));

//backward 

DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U1 ( .a(y_2_r), .b(tar), .rnd(3'b000), .z(delta2));


generate
for(k=0;k<3;k=k+1) begin
	assign goh[k] = (h_1_sum_r[k][31]==1'b1) ? ZERO : ONE;
end
endgenerate


generate
for(k=0;k<3;k=k+1) begin
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M1 (.a(w2[k]), .b(delta2_r), .rnd(3'b000), .z(h_3[k]));
end
endgenerate

generate
for(k=0;k<3;k=k+1) begin
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M1 (.a(goh_r[k]), .b(h_3_r[k]), .rnd(3'b000), .z(delta1[k]));
end
endgenerate

//update

generate
for(k=0;k<3;k=k+1) begin
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M1 (.a(y_1_r[k]), .b(delta2_r), .rnd(3'b000), .z(r2_1[k]));
end
endgenerate

generate
for(k=0;k<3;k=k+1) begin
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M1 (.a((lr_dv)), .b(r2_1_r[k]), .rnd(3'b000), .z(r2_2[k]));//r2_1_r
end
endgenerate

generate
for(k=0;k<3;k=k+1) begin
	DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U1 ( .a(w2[k]), .b(r2_2_r[k]), .rnd(3'b000), .z(w2_n[k]));
end
endgenerate


generate
for(k=0;k<3;k=k+1) begin
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M1 (.a(data[0]), .b(delta1_r[k]), .rnd(3'b000), .z(r1_1[(k<<2)]));
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M2 (.a(data[1]), .b(delta1_r[k]), .rnd(3'b000), .z(r1_1[(k<<2)+1]));
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M3 (.a(data[2]), .b(delta1_r[k]), .rnd(3'b000), .z(r1_1[(k<<2)+2]));
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M4 (.a(data[3]), .b(delta1_r[k]), .rnd(3'b000), .z(r1_1[(k<<2)+3]));
end
endgenerate

generate
for(k=0;k<3;k=k+1) begin
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M1 (.a((lr_dv)), .b(r1_1_r[(k<<2)]), .rnd(3'b000), .z(r1_2[(k<<2)]));//r1_1_r
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M2 (.a((lr_dv)), .b(r1_1_r[(k<<2)+1]), .rnd(3'b000), .z(r1_2[(k<<2)+1]));
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M3 (.a((lr_dv)), .b(r1_1_r[(k<<2)+2]), .rnd(3'b000), .z(r1_2[(k<<2)+2]));
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M4 (.a((lr_dv)), .b(r1_1_r[(k<<2)+3]), .rnd(3'b000), .z(r1_2[(k<<2)+3]));
end
endgenerate

generate
for(k=0;k<12;k=k+1) begin
	DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U1 ( .a(w1[k]), .b(r1_2_r[k]), .rnd(3'b000), .z(w1_n[k]));
end
endgenerate




//Output assignment
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_valid <= 0;
		out <= 0;	
	end
	else begin
		if(/* cnt_w == 2 && flag == 1 */state == OUTPUT)begin
			out_valid <= 1;
			out <= y_2_r;
		end
		else begin
			out_valid <= 0;
			out <= 0;
		end
		
	end
end	
	
endmodule




















