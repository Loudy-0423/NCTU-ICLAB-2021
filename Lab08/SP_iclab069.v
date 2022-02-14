// synopsys translate_off 
`ifdef RTL
`include "GATED_OR.v"
`else
`include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on

module SP(
	// Input signals
	clk,
	rst_n,
	cg_en,
	in_valid,
	in_data,
	in_mode,
	// Output signals
	out_valid,
	out_data
);

// INPUT AND OUTPUT DECLARATION  
input		clk;
input		rst_n;
input		in_valid;
input		cg_en;
input [8:0] in_data;
input [2:0] in_mode;

output reg 		  out_valid;
output reg signed[9:0] out_data;

// ===============================================================
//  					Variable Declare
// ===============================================================

parameter IDLE     = 'd0;
parameter IN       = 'd1;
parameter MODE0    = 'd2;
parameter MODE1    = 'd3;
parameter MODE2    = 'd4;
parameter WAIT     = 'd5;
parameter OUT      = 'd6;

reg [2:0] n_state, state;
reg [4:0] cnt;
reg [3:0] cnt_m0;
reg signed [8:0] data [9:1];

reg signed [8:0] data_0_r [9:1];
reg signed [9:0] data_1_r [9:1], data_2_r [9:1];

reg [2:0] mode;

integer i, j;
genvar k;

reg signed [8:0] a0 ,b0;
reg signed [9:0] c0;

wire signed [11:0] ms [7:1];
wire signed [8:0] mx;
//================================================================
//	GATED CLK
//================================================================

wire clk_0, clk_1, clk_2, clk_in, clk_out;
wire sleep_0, sleep_1, sleep_2, sleep_in, sleep_out;
GATED_OR GATED_0( .CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_0), .RST_N(rst_n), .CLOCK_GATED(clk_0));
GATED_OR GATED_1( .CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_1), .RST_N(rst_n), .CLOCK_GATED(clk_1));
GATED_OR GATED_2( .CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_2), .RST_N(rst_n), .CLOCK_GATED(clk_2));
GATED_OR GATED_in( .CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_in), .RST_N(rst_n), .CLOCK_GATED(clk_in));
GATED_OR GATED_out( .CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_out), .RST_N(rst_n), .CLOCK_GATED(clk_out));

assign sleep_0 = !(state == IN || state == MODE0);
assign sleep_1 = !(state == MODE1);
assign sleep_2 = !(state == MODE2);
assign sleep_in = !(state == IN);
assign sleep_out = !(state == WAIT || state == OUT);
// ===============================================================
//  					Finite State Machine
// ===============================================================

//FSM current state assignment
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		state <= IDLE;
	end
	else begin
		state <= n_state;
	end
end

//FSM next state assignment
always@(*) begin
    case(state)
        IDLE: begin
            n_state = (rst_n)? IN : IDLE;
        end
		IN: begin
			n_state = (in_valid == 0 && cnt == 9)? MODE0 : IN;
			
        end
		MODE0: begin
			n_state = (cnt_m0 == 9)? MODE1 : MODE0;
        end
        MODE1: begin
			n_state = (cnt == 12)? MODE2 : MODE1;
        end
		MODE2: begin
            n_state = (cnt == 9)? WAIT : MODE2;
        end
		WAIT: begin
            n_state = (cnt == 17)? OUT : WAIT;//9
        end
        OUT: begin
			n_state = (cnt == 20)? IDLE : OUT;//12
        end
        default: begin
            n_state = state;
        end
    endcase
end 

// ===============================================================
//  					Input Register
// ===============================================================

always@(posedge clk_in or negedge rst_n) begin
    if(!rst_n) begin
		for(i=1; i<10; i=i+1) begin
			data[i] <= 0;
		end
	end
	else begin
		if(n_state == IDLE) begin
			for(i=1; i<10; i=i+1) begin
				data[i] <= 0;
			end
		end
		else if(n_state == IN) begin
			if(in_valid) begin
				data[cnt+1] <= in_data;
			end
		end
	end
end

always@(posedge clk_in or negedge rst_n) begin
    if(!rst_n) begin
		mode <= 0;
	end
	else begin
		if(n_state == IDLE) begin
			mode <= 0;
		end
		else if(n_state == IN) begin
			if(cnt == 0) begin
				if(in_valid) begin
					mode <= in_mode;
				end
			end
		end
	end
end

//Counter
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        cnt <= 0;
	end
	else begin
		if(n_state == IDLE) begin
			cnt <= 0;
		end
		else if(n_state == IN) begin
			if(in_valid) begin
				cnt <= cnt+1;
			end
		end
		else if(n_state == MODE1 || n_state == MODE2) begin
			if(cnt == 12) begin
				cnt <= 0;
			end
			else begin
				cnt <= cnt+1;
			end
		end
		else if(n_state == WAIT || n_state == OUT) begin
			cnt <= cnt+1;
		end
		else begin
			cnt <= 0;
		end
	end
end


// ===============================================================
//  					       Mode 0
// ===============================================================


//Counter M0
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        cnt_m0 <= 0;
	end
	else begin
		if(n_state == IDLE) begin
			cnt_m0 <= 0;
		end
		else if(n_state == MODE0) begin
			cnt_m0 <= cnt_m0+1;
		end
		else if(state == MODE2) begin
			cnt_m0 <= cnt_m0+1;
		end
		else begin
			cnt_m0 <= 0;
		end
	end
end

always @(posedge clk_0 or negedge rst_n) begin
	if(!rst_n) begin
		for(i=1; i<10; i=i+1)begin
			data_0_r[i] <= 0;
		end
	end
	else begin
		if(n_state == IDLE) begin
			for(i=1; i<10; i=i+1)begin
				data_0_r[i] <= 0;
			end
		end
		else if(n_state == MODE0) begin
			if(mode[0]) begin
				if(data[cnt_m0+1][8]) begin
					if((~(((data[cnt_m0+1][7:4]-3)<<3)+((data[cnt_m0+1][7:4]-3)<<1)+(data[cnt_m0+1][3:0]-3))+1) != 8'b0) begin
						data_0_r[cnt_m0+1][8] <= 1'b1;
					end
					else begin
						data_0_r[cnt_m0+1][8] <= 1'b0;
					end
					data_0_r[cnt_m0+1][7:0] <= (~(((data[cnt_m0+1][7:4]-3)<<3)+((data[cnt_m0+1][7:4]-3)<<1)+(data[cnt_m0+1][3:0]-3))+1);
				end
				else begin
					data_0_r[cnt_m0+1] <= ((data[cnt_m0+1][7:4]-3)<<3)+((data[cnt_m0+1][7:4]-3)<<1)+(data[cnt_m0+1][3:0]-3);
				end
			end
			else begin
				for(i=1; i<10; i=i+1)begin
					data_0_r[i] <=  data[i];
				end
			end
		end
	end
end

// ===============================================================
//  					       Mode 1
// ===============================================================


always @(posedge clk_1 or negedge rst_n) begin
	if(!rst_n) begin
        for(i=1; i<10; i=i+1)begin
			data_1_r[i] <= 0;
		end
	end
	else begin
		if(n_state == IDLE) begin
			for(i=1; i<10; i=i+1)begin
				data_1_r[i] <= 0;
			end
		end
		else if(n_state == MODE1) begin
			if(mode[1]) begin
				for(i=1; i<10; i=i+1)begin
					data_1_r[i] <= data_0_r[i]-c0;
				end
			end
			else begin
				for(i=1; i<10; i=i+1)begin
					data_1_r[i] <=  data_0_r[i];
				end
			end
		end
	end
end

// ===============================================================
//  					       Mode 2
// ===============================================================

always @(posedge clk_2 or negedge rst_n) begin
	if(!rst_n) begin
		for(i=1; i<10; i=i+1)begin
			data_2_r[i] <= 0;
		end
	end
	else begin
		if(n_state == IDLE) begin
			for(i=1; i<10; i=i+1)begin
				data_2_r[i] <= 0;
			end
		end
		else if(n_state == MODE2) begin
			if(mode[2]) begin
				data_2_r[1] <= data_1_r[1];
				if(cnt_m0 > 0)
					data_2_r[cnt_m0+1] <= ((data_2_r[cnt_m0]<<1)+data_1_r[cnt_m0+1])/3;
			end
			else begin
				for(i=1; i<10; i=i+1)begin
					data_2_r[i] <=  data_1_r[i];
				end
			end
		end
	end
end

// ===============================================================
//  					      MAX/MIN
// ===============================================================
wire signed [9:0] sum;
assign sum = a0+b0;

always@(posedge clk_1 or negedge rst_n) begin
	if(!rst_n) begin
        c0 <= 0;
	end
	else begin
		if(n_state == MODE1) begin
			if(cnt == 10) begin
				if(((sum)>>>1) >= 0)
					if(sum[0] == 1)
						c0 <= ((sum)>>1);
					else 
						c0 <= ((sum)>>1);
				else 
					if(sum[0] == 1)
						c0 <= ((sum)>>>1)+1;
					else 
						c0 <= ((sum)>>>1);
			end
			else begin
				c0 <= c0;
			end
		end
	end
end


always@(posedge clk_1 or negedge rst_n) begin
	if(!rst_n) begin
        a0 <= {1'b1, 8'b0};
	end
	else begin
		if(n_state == MODE1) begin
			if(mx >= a0)begin
				a0 <= mx;
			end
			else begin
				a0 <= a0;
			end
		end
		else
			a0 <= {1'b1, 8'b0};
	end
end

always@(posedge clk_1 or negedge rst_n) begin
	if(!rst_n) begin
        b0 <= {1'b0, {8{1'b1}}};
	end
	else begin
		if(n_state == MODE1) begin
			if(mx <= b0)begin
				b0 <= mx;
			end
			else begin
				b0 <= b0;
			end
		end
		else 
			b0 <= {1'b0, {8{1'b1}}};
	end
end

assign mx = data_0_r[cnt];


///////////////////Max Sum//////////////////////

generate
	for(k=1; k<8; k=k+1) begin
		assign ms[k] = data_2_r[k]+data_2_r[k+1]+data_2_r[k+2];
	end
endgenerate


wire signed [11:0] mst;

assign mst = (cnt > 9 && n_state == 5)? ms[cnt-9] : {1'b1, 11'b0};

reg signed [11:0] t0;

always@(posedge clk_out or negedge rst_n) begin
	if(!rst_n) begin
        t0 <= {1'b1, 11'b0};
	end
	else begin
		if(n_state == WAIT) begin
			if(cnt > 9)begin
				if(mst > t0) begin
					t0 <= mst;
				end
				else begin
					t0 <= t0;
				end
			end
		end
		else if(n_state == OUT)
			t0 <= t0;
		else 
			t0 <= {1'b1, 11'b0};
	end
end


// ===============================================================
//  					Output Register
// ===============================================================

//Output assignment
always@(posedge clk_out or negedge rst_n) begin
	if(!rst_n) begin
		out_valid <= 0;
		out_data <= 0;	
	end
	else begin
		if(n_state == IDLE) begin
			out_valid <= 0;
			out_data <= 0;	
		end
		else if(n_state == OUT) begin
			if(cnt > 0) begin
				out_valid <= 1;
				if(t0 == ms[1])
					out_data <= data_2_r[cnt-16];
				else if(t0 == ms[2])
					out_data <= data_2_r[cnt-15];
				else if(t0 == ms[3])
					out_data <= data_2_r[cnt-14];
				else if(t0 == ms[4])
					out_data <= data_2_r[cnt-13];
				else if(t0 == ms[5])
					out_data <= data_2_r[cnt-12];
				else if(t0 == ms[6])
					out_data <= data_2_r[cnt-11];
				else if(t0 == ms[7])
					out_data <= data_2_r[cnt-10];
			end
		end
		else begin
			out_valid <= 0;
			out_data <= 0;	
		end
	end
end	


endmodule