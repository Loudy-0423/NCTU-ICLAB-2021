module CLK_1_MODULE(// Input signals
			clk_1,
			clk_2,
			in_valid,
			rst_n,
			message,
			mode,
			CRC,
			// Output signals
			clk1_0_message,
			clk1_1_message,
			clk1_CRC,
			clk1_mode,
			clk1_control_signal,
			clk1_flag_0,
			clk1_flag_1,
			clk1_flag_2,
			clk1_flag_3,
			clk1_flag_4,
			clk1_flag_5,
			clk1_flag_6,
			clk1_flag_7,
			clk1_flag_8,
			clk1_flag_9
			);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------			
input clk_1; 
input clk_2;	
input rst_n;
input in_valid;
input[59:0]message;
input CRC;
input mode;

output reg [59:0] clk1_0_message;
output reg [59:0] clk1_1_message;
output reg clk1_CRC;
output reg clk1_mode;
output reg [9 :0] clk1_control_signal;
output clk1_flag_0;
output reg clk1_flag_1;
output clk1_flag_2;
output clk1_flag_3;
output clk1_flag_4;
output clk1_flag_5;
output clk1_flag_6;
output clk1_flag_7;
output clk1_flag_8;
output clk1_flag_9;

//---------------------------------------------------------------------
// PARAMETER DECLARATION
//---------------------------------------------------------------------

always @(*) begin
	clk1_flag_1 = in_valid;
end
always @ (posedge clk_1 or negedge rst_n) begin
	if(!rst_n) begin
		clk1_0_message <= 0;
	end
	else begin
		if(in_valid) begin
			clk1_0_message <= message;
		end
		else begin
			clk1_0_message <= clk1_0_message;
		end
	end
end
always @ (posedge clk_1 or negedge rst_n) begin
	if(!rst_n) begin
		clk1_CRC <= 0;
	end
	else begin
		if(in_valid) begin
			clk1_CRC <= CRC;
		end
		else begin
			clk1_CRC <= clk1_CRC;
		end
	end
end
always @ (posedge clk_1 or negedge rst_n) begin
	if(!rst_n) begin
		clk1_mode <= 0;
	end
	else begin
		if(in_valid) begin
			clk1_mode <= mode;
		end
		else begin
			clk1_mode <= clk1_mode;
		end
	end
end


syn_XOR invalid(.IN(in_valid),.OUT(clk1_flag_0),.TX_CLK(clk_1),.RX_CLK(clk_2),.RST_N(rst_n));
	
endmodule







module CLK_2_MODULE(// Input signals
			clk_2,
			clk_3,
			rst_n,
			clk1_0_message,
			clk1_1_message,
			clk1_CRC,
			clk1_mode,
			clk1_control_signal,
			clk1_flag_0,
			clk1_flag_1,
			clk1_flag_2,
			clk1_flag_3,
			clk1_flag_4,
			clk1_flag_5,
			clk1_flag_6,
			clk1_flag_7,
			clk1_flag_8,
			clk1_flag_9,
			
			// Output signals
			clk2_0_out,
			clk2_1_out,
			clk2_CRC,
			clk2_mode,
			clk2_control_signal,
			clk2_flag_0,
			clk2_flag_1,
			clk2_flag_2,
			clk2_flag_3,
			clk2_flag_4,
			clk2_flag_5,
			clk2_flag_6,
			clk2_flag_7,
			clk2_flag_8,
			clk2_flag_9
		  
			);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------			
input clk_2;	
input clk_3;	
input rst_n;

input [59:0] clk1_0_message;
input [59:0] clk1_1_message;
input clk1_CRC;
input clk1_mode;
input [9  :0] clk1_control_signal;
input clk1_flag_0;
input clk1_flag_1;
input clk1_flag_2;
input clk1_flag_3;
input clk1_flag_4;
input clk1_flag_5;
input clk1_flag_6;
input clk1_flag_7;
input clk1_flag_8;
input clk1_flag_9;


output reg [59:0] clk2_0_out;
output reg [59:0] clk2_1_out;
output reg clk2_CRC;
output reg clk2_mode;
output reg [9  :0] clk2_control_signal;
output clk2_flag_0;
output clk2_flag_1;
output clk2_flag_2;
output clk2_flag_3;
output clk2_flag_4;
output clk2_flag_5;
output clk2_flag_6;
output clk2_flag_7;
output clk2_flag_8;
output clk2_flag_9;


//---------------------------------------------------------------------
// PARAMETER DECLARATION
//---------------------------------------------------------------------
reg [5:0] cnt;
wire [59:0] msg;
reg [59:0] cmsg;
wire [8:0] c_8;
wire [5:0] c_5;
integer i;

assign msg = clk1_0_message;
assign c_8 = 9'b100110001;
assign c_5 = 6'b101011;

always@(posedge clk_2 or negedge rst_n) begin
	if(!rst_n) begin
		clk2_mode <= 0;
	end
	else begin
		if(clk1_flag_0) begin
			clk2_mode <= clk1_mode;
		end
		else begin
			clk2_mode <= clk2_mode;
		end
	end
end

always@(posedge clk_2 or negedge rst_n) begin
	if(!rst_n) begin
		clk2_CRC <= 0;
	end
	else begin
		if(clk1_flag_0) begin
			clk2_CRC <= clk1_CRC;
		end
		else begin
			clk2_CRC <= clk2_CRC;
		end
	end
end


always@(posedge clk_2 or negedge rst_n) begin
	if(!rst_n) begin
		cnt <= 63;
	end
	else begin
		if(clk1_flag_0) begin
			cnt <= 0;
		end
		else if(cnt != 63) begin
			cnt <= cnt+1;
		end
	end
end

reg flag[0:1];
always@(posedge clk_2 or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0; i<2; i=i+1)begin
			flag[i] <= 0;
		end
	end
	else begin
		if(clk2_CRC == 0 && cnt < 53) begin
			flag[0] <= 1;
			flag[1] <= 0;
		end
		else if(clk2_CRC == 1 && cnt < 56) begin
			flag[0] <= 0;
			flag[1] <= 1;
		end
		else begin
			for(i=0; i<2; i=i+1)begin
				flag[i] <= 0;
			end
		end
	end
end


wire [8:0] rem;
assign rem = (!clk2_CRC)? cmsg[59:51]^c_8 : cmsg[59:54]^c_5;


always@(posedge clk_2 or negedge rst_n) begin
	if(!rst_n) begin
		cmsg <= 0;
	end
	else begin
		if(cnt == 0) begin
			cmsg <= (clk2_mode)? msg : (!clk2_CRC)? {msg[51:0], 8'b0} : {msg[54:0], 5'b0};
		end
		else begin
			if(flag[0]) begin
				cmsg <= (cmsg[59])? {rem[7:0], cmsg[50:0], 1'b0} : (cmsg << 1);
			end
			else if(flag[1]) begin
				cmsg <= (cmsg[59])? {rem[4:0], cmsg[53:0], 1'b0} : (cmsg << 1);
			end
		end
	end
end


always@(posedge clk_2 or negedge rst_n) begin
	if(!rst_n) begin
		clk2_0_out <= 0;
	end
	else begin
		if(clk2_mode == 0) begin
			clk2_0_out <= (!clk2_CRC && cnt == 53)? {msg[51:0],cmsg[59:52]} : (clk2_CRC && cnt == 56)? {msg[54:0],cmsg[59:55]} : clk2_0_out;
		end 
		else begin
			clk2_0_out <= ((!clk2_CRC && cmsg[59:52] == 0) || (clk2_CRC && cmsg[59:55] == 0))? {60{1'b0}} : {60{1'b1}};
		end
	end
end

wire flag_00;

assign flag_00 = (cnt==59)? 1:0;
syn_XOR in_valid(.IN(flag_00),.OUT(clk2_flag_0),.TX_CLK(clk_2),.RX_CLK(clk_3),.RST_N(rst_n));

endmodule






module CLK_3_MODULE(// Input signals
			clk_3,
			rst_n,
			clk2_0_out,
			clk2_1_out,
			clk2_CRC,
			clk2_mode,
			clk2_control_signal,
			clk2_flag_0,
			clk2_flag_1,
			clk2_flag_2,
			clk2_flag_3,
			clk2_flag_4,
			clk2_flag_5,
			clk2_flag_6,
			clk2_flag_7,
			clk2_flag_8,
			clk2_flag_9,
			
			// Output signals
			out_valid,
			out
		  
			);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------			
input clk_3;	
input rst_n;

input [59:0] clk2_0_out;
input [59:0] clk2_1_out;
input clk2_CRC;
input clk2_mode;
input [9  :0] clk2_control_signal;
input clk2_flag_0;
input clk2_flag_1;
input clk2_flag_2;
input clk2_flag_3;
input clk2_flag_4;
input clk2_flag_5;
input clk2_flag_6;
input clk2_flag_7;
input clk2_flag_8;
input clk2_flag_9;

output reg out_valid;
output reg [59:0]out; 		

//---------------------------------------------------------------------
// PARAMETER DECLARATION
//---------------------------------------------------------------------

always @ (posedge clk_3 or negedge rst_n) begin
	if(!rst_n) begin
		out_valid <= 0;
		out <= 0;
	end 
	else if(clk2_flag_0) begin
		out_valid<=1;
		out <= clk2_0_out;
	end 
	else begin
		out_valid <= 0;
		out <= 0;
	end
end
endmodule


