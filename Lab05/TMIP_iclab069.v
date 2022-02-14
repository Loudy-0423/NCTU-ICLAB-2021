module TMIP(
// input signals
    clk,
    rst_n,
    in_valid,
	in_valid_2,
    image,
	img_size,
    template, 
    action,
	
// output signals
    out_valid,
    out_x,
    out_y,
    out_img_pos,
    out_value
);

input        clk, rst_n, in_valid, in_valid_2;
input [15:0] image, template;
input [4:0]  img_size;
input [1:0]  action;

output reg        out_valid;
output reg [3:0]  out_x, out_y; 
output reg [7:0]  out_img_pos;
output reg signed[39:0] out_value;

parameter RESET  = 'd0;
parameter INPUT  = 'd1;
parameter PROCESS  = 'd2;
parameter OUTPUT  = 'd3;

reg [1:0] state;
reg [1:0] n_state;


reg signed [15:0] tmp [8:0];
reg [4:0]  size;
reg [1:0]  act [7:0];

integer i, j;

reg [4:0] cnt_tmp;
reg [8:0] cnt_addr;
reg [3:0] cnt_act;
reg [7:0] cnt;
reg [6:0] m_cnt;
reg [8:0] cnt_out;
reg [8:0] cnt_hf;
reg [6:0] cnt_mp;


reg [3:0] act_idx;
reg [7:0] img_idx [8:0];
reg [8:0] mem_addr;

reg flag [7:0];
reg done;
reg signed [15:0] max;
reg signed [35:0] cross_result;
//reg signed [15:0] mem [255:0];
reg signed [15:0] mem_hf [255:0];

reg [8:0] addr;//8
reg [8:0] addr1;//8
reg w_en;
reg w_en1;
reg signed [15:0] ker [8:0];
reg signed [15:0] ker_out_pos [8:0];

reg signed [35:0] out [255:0];
reg signed [35:0] out_max;
reg [7:0] out_max_pos;
reg [7:0] hf_addr;

//FSM current state assignment
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
			n_state = (!in_valid)? RESET : INPUT;
		end

		INPUT: begin
			n_state = (!in_valid_2 && cnt_act != 0)? PROCESS : INPUT;
		end

		PROCESS: begin
			n_state = (done)? OUTPUT : PROCESS;
		end


		OUTPUT: begin
			n_state = (/* out_valid */cnt_out != size*size)? OUTPUT : RESET;
		end
		
		default: begin
			n_state = state;
		end
	endcase
end 

//Input assignment
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0; i<9; i=i+1) begin
			tmp[i] <= 0;
		end
		size <= 0;
		for(j=0; j<8; j=j+1) begin
			act[j] <= 0;
		end
	end
	else if(n_state == INPUT) begin
		if(in_valid == 1 && cnt_tmp<9) begin
			tmp[cnt_tmp] <= template;
		end

		if(in_valid == 1 && cnt_tmp<1) begin
			size <= img_size;
		end

		if(in_valid_2) begin
			act[cnt_act] <= action;
		end
	end
	else if (state == PROCESS) begin
		if(act[act_idx] == 1 && size == 16 && cnt_mp == 64 && w_en == 1) begin
			size <= size>>1;
		end
		else if(act[act_idx] == 1 && size == 8 && cnt_mp == 16 && w_en == 1) begin
			size <= size>>1;
		end
	end
	else if (state == RESET) begin
		for(i=0; i<9; i=i+1) begin
			tmp[i] <= 0;
		end
		size <= 0;
		for(j=0; j<8; j=j+1) begin
			act[j] <= 0;
		end
	end
end



//Counter
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_tmp <= 0;
		cnt_act <= 0;
		cnt_addr <= 0;
	end

	else if(n_state == INPUT) begin
		/////////////////////////////cnt///////////////////////////////////
		if(in_valid == 1 && cnt_tmp < 9) begin
			cnt_tmp <= cnt_tmp+1;
		end
		else begin
			cnt_tmp <= cnt_tmp;
		end
		///////////////////////////cnt_act/////////////////////////////////
		if(in_valid_2 == 1) begin
			cnt_act <= cnt_act+1;
		end
		else begin
			cnt_act <= cnt_act;
		end
		///////////////////////////cnt_addr////////////////////////////////
		if(in_valid) begin
			cnt_addr <= cnt_addr+1;
		end
		else begin
			cnt_addr <= cnt_addr;
		end
	end

	else if(state == RESET) begin
		cnt_tmp <= 0;
		cnt_act <= 0;
		cnt_addr <= 0;
	end

	else begin
		cnt_tmp <= cnt_tmp;
		cnt_act <= cnt_act;
		cnt_addr <= cnt_addr;
	end
end




wire [15:0] pix_in;
wire [15:0] pix_in1;
wire c_en;
wire o_en;
wire [15:0] pix_out;
wire [15:0] pix_out1;
reg switch;
//out->mem
assign pix_in = (in_valid == 1)? image : 
				(state == PROCESS && act[act_idx] == 1 && addr != 0 && cnt == 1 && w_en == 1 && switch == 0)? max : 
				(state == PROCESS && act[act_idx] == 1 && w_en == 0 && switch == 0)? out[cnt_mp] : 
				(state == PROCESS && act[act_idx] == 1 && addr != 0 && cnt == 1 && w_en1 == 1 && switch == 1)? max : 
				(state == PROCESS && act[act_idx] == 1 && w_en1 == 0 && switch == 1)? out[cnt_mp] : 
				(state == PROCESS && act[act_idx] == 3 && mem_addr != 0)? ker[0] : 
				(state == PROCESS && act[act_idx] == 2 && cnt_hf == 65 && size == 8 && switch == 0)? mem_hf[addr] : 
				(state == PROCESS && act[act_idx] == 2 && cnt_hf == 17 && size == 4 && switch == 0)? mem_hf[addr] : 
				(state == PROCESS && act[act_idx] == 2 && cnt_hf == 257 && size == 16 && switch == 0)? mem_hf[addr] :
				(state == PROCESS && act[act_idx] == 2 && cnt_hf == 65 && size == 8 && switch == 1)? mem_hf[addr1] : 
				(state == PROCESS && act[act_idx] == 2 && cnt_hf == 17 && size == 4 && switch == 1)? mem_hf[addr1] : 
				(state == PROCESS && act[act_idx] == 2 && cnt_hf == 257 && size == 16 && switch == 1)? mem_hf[addr1] :
				
				/* (state == PROCESS && act[act_idx] == 2 && size == 8 && switch == 0)? mem_hf[hf_addr] : 
				(state == PROCESS && act[act_idx] == 2 && size == 4 && switch == 0)? mem_hf[hf_addr] : 
				(state == PROCESS && act[act_idx] == 2 && size == 16 && switch == 0)? mem_hf[hf_addr] :
				(state == PROCESS && act[act_idx] == 2 && size == 8 && switch == 1)? mem_hf[hf_addr] : 
				(state == PROCESS && act[act_idx] == 2 && size == 4 && switch == 1)? mem_hf[hf_addr] : 
				(state == PROCESS && act[act_idx] == 2 && size == 16 && switch == 1)? mem_hf[hf_addr] :  */0;
				
/* assign pix_in1 = (state == PROCESS && act[act_idx] == 1 && addr != 0 && cnt == 1 && w_en1 == 1)? max : 
				(state == PROCESS && act[act_idx] == 1 && w_en1 == 0)? out[cnt_mp] : 
				(state == PROCESS && act[act_idx] == 3 && w_en1 == 0)? out[addr] : 
				(state == PROCESS && act[act_idx] == 3 && mem_addr != 0 && w_en1 == 1)? ker[0] : 
				(state == PROCESS && act[act_idx] == 2 && cnt_hf == 65 && size == 8)? out[addr] : 
				(state == PROCESS && act[act_idx] == 2 && cnt_hf == 17 && size == 4)? out[addr] : 
				(state == PROCESS && act[act_idx] == 2 && cnt_hf == 257 && size == 16)? out[addr] : 0; */
				
				
//out->mem_hp 
assign c_en = 0;
assign o_en = 0;


SRAM1 IMG1( .Q(pix_out), .CLK(clk), .CEN(c_en), .WEN(w_en), .A(addr), .D(pix_in), .OEN(o_en) );
SRAM2 IMG2( .Q(pix_out1), .CLK(clk), .CEN(c_en), .WEN(w_en1), .A(addr1), .D(pix_in), .OEN(o_en) );


//switch
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		switch <= 0;
	end
	else if(state == PROCESS) begin
		if(act[act_idx] == 3 && flag[act_idx] == 1) begin
			switch <= switch+1;
		end
	end
	else if(state == RESET) begin
		switch <= 0;
	end
end



//MEM_addr
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		mem_addr <= 0;
		m_cnt <= 0;
	end
	else if(state == PROCESS) begin
		if(act[act_idx] == 0) begin
			if(size == 4 && mem_addr < 17) begin
				if(mem_addr == 0) begin
					if(cnt < 3) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr+1;
					end
				end
				else if(mem_addr == 3) begin
					if(cnt < 3) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr+1;
					end
				end
				else if(mem_addr == 12) begin
					if(cnt < 3) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr+1;
					end
				end
				else if(mem_addr == 15) begin
					if(cnt < 3) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr+1;
					end
				end
				else if(mem_addr > 0 && mem_addr < 3) begin
					if(cnt < 5) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr+1;
					end
				end
				else if(mem_addr > 12 && mem_addr < 15) begin
					if(cnt < 5) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr+1;
					end
				end
				else if(mem_addr%4 == 0) begin
					if(cnt < 5) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr+1;
					end
				end
				else if((mem_addr+1)%4 == 0) begin
					if(cnt < 5) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr+1;
					end
				end
				else begin
					if(cnt < 8) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr+1;
					end
				end
				
			end


			
			else if(size == 8 && mem_addr < 65) begin
				if(mem_addr == 0) begin
					if(cnt < 3) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr+1;
					end
				end
				else if(mem_addr == 7) begin
					if(cnt < 3) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr+1;
					end
				end
				else if(mem_addr == 56) begin
					if(cnt < 3) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr+1;
					end
				end
				else if(mem_addr == 63) begin
					if(cnt < 3) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr+1;
					end
				end
				else if(mem_addr > 0 && mem_addr < 7) begin
					if(cnt < 5) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr+1;
					end
				end
				else if(mem_addr > 56 && mem_addr < 63) begin
					if(cnt < 5) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr+1;
					end
				end
				else if(mem_addr%8 == 0) begin
					if(cnt < 5) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr+1;
					end
				end
				else if((mem_addr+1)%8 == 0) begin
					if(cnt < 5) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr+1;
					end
				end
				else begin
					if(cnt < 8) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr+1;
					end
				end
			end





			else if(size == 16 && mem_addr < 257) begin
				if(mem_addr == 0) begin
					if(cnt < 3) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr+1;
					end
				end
				else if(mem_addr == 15) begin
					if(cnt < 3) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr+1;
					end
				end
				else if(mem_addr == 240) begin
					if(cnt < 3) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr+1;
					end
				end
				else if(mem_addr == 255) begin
					if(cnt < 3) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr+1;
					end
				end
				else if(mem_addr > 0 && mem_addr < 15) begin
					if(cnt < 5) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr+1;
					end
				end
				else if(mem_addr > 240 && mem_addr < 255) begin
					if(cnt < 5) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr+1;
					end
				end
				else if(mem_addr%16 == 0) begin
					if(cnt < 5) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr+1;
					end
				end
				else if((mem_addr+1)%16 == 0) begin
					if(cnt < 5) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr+1;
					end
				end
				else begin
					if(cnt < 8) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr+1;
					end
				end
				
			end
		end
		else if(act[act_idx] == 1 && cnt == 2) begin
			if(size == 8) begin
				if(mem_addr == 6) begin
					mem_addr <= 16;
					m_cnt <= m_cnt+1;
				end
				else if(mem_addr == 22) begin
					mem_addr <= 32;
					m_cnt <= m_cnt+1;
				end
				else if(mem_addr == 38) begin
					mem_addr <= 48;
					m_cnt <= m_cnt+1;
				end
				else if(mem_addr <= 56)begin//54
					mem_addr <= mem_addr+2;
					m_cnt <= m_cnt+1;
				end
				else begin
					mem_addr <= mem_addr;
					m_cnt <= m_cnt;
				end
			end
			else if(size == 16) begin
				if(mem_addr == 14) begin
					mem_addr <= 32;
					m_cnt <= m_cnt+1;
				end
				else if(mem_addr == 46) begin
					mem_addr <= 64;
					m_cnt <= m_cnt+1;
				end
				else if(mem_addr == 78) begin
					mem_addr <= 96;
					m_cnt <= m_cnt+1;
				end
				else if(mem_addr == 110) begin
					mem_addr <= 128;
					m_cnt <= m_cnt+1;
				end
				else if(mem_addr == 142) begin
					mem_addr <= 160;
					m_cnt <= m_cnt+1;
				end
				else if(mem_addr == 174) begin
					mem_addr <= 192;
					m_cnt <= m_cnt+1;
				end
				else if(mem_addr == 206) begin
					mem_addr <= 224;
					m_cnt <= m_cnt+1;
				end
				else if(mem_addr <= 240)begin
					mem_addr <= mem_addr+2;
					m_cnt <= m_cnt+1;
				end
				else begin
					mem_addr <= mem_addr;
					m_cnt <= m_cnt;
				end
			end
			else begin
				mem_addr <= mem_addr+2;
				m_cnt <= m_cnt+1;
			end
		end
		else if(act[act_idx] == 2) begin
			if(size == 4) begin
				if(mem_addr < 17 && w_en == 1 && switch == 0) begin
					mem_addr <= mem_addr+1;
				end
				else if(mem_addr < 17 && w_en1 == 1 && switch == 1) begin
					mem_addr <= mem_addr+1;
				end
				else if(cnt_hf == 17) begin
					if(mem_addr == 0) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr-1;
					end
					
				end
			end

			else if(size == 8) begin
				if(mem_addr < 65 && w_en == 1 && switch == 0) begin
					mem_addr <= mem_addr+1;
				end
				else if(mem_addr < 65 && w_en1 == 1 && switch == 1) begin
					mem_addr <= mem_addr+1;
				end
				////////////////////////////////////////////////////////////
				else if(cnt_hf == 65) begin
					if(mem_addr == 0) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr-1;
					end
					
				end
				///////////////////////////////////////////////////////////
				else begin
					mem_addr <= mem_addr;
				end

			end
			else if(size == 16) begin
				if(mem_addr < 257 && w_en == 1 && switch == 0) begin
					mem_addr <= mem_addr+1;
				end
				else if(mem_addr < 257 && w_en1 == 1 && switch == 1) begin
					mem_addr <= mem_addr+1;
				end
				else if(cnt_hf == 257) begin
					if(mem_addr == 0) begin
						mem_addr <= mem_addr;
					end
					else begin
						mem_addr <= mem_addr-1;
					end
					
				end
			end
		end
		else if(act[act_idx] == 3) begin
			if(size == 4) begin
				if(mem_addr < 18) begin
					mem_addr <= mem_addr+1;
				end
				else if(mem_addr <= 18) begin
					mem_addr <= mem_addr;
				end
			end
			else if(size == 8) begin
				if(mem_addr < 66) begin
					mem_addr <= mem_addr+1;
				end
				else if(mem_addr <= 66) begin
					mem_addr <= mem_addr;
				end

			end
			else if(size == 16) begin
				if(mem_addr < 258) begin
					mem_addr <= mem_addr+1;
				end
				else if(mem_addr <= 258) begin
					mem_addr <= mem_addr;
				end
			end
			
		end


		if(flag[act_idx] == 1) begin
			mem_addr <= 0;
			m_cnt <= 0;
		end

	end
	else if(state == RESET) begin
		mem_addr <= 0;
		m_cnt <= 0;
	end

end




//Addr & w_en control
always@(*) begin
	if(!rst_n) begin
		w_en = 1;
		w_en1 = 1;
		addr = 0;
		addr1 = 0;
	end
	else begin
		if(in_valid) begin
			w_en = 0;
			w_en1 = 0;
			addr = cnt_addr;
			addr1 = cnt_addr;
		end
		else if(state == PROCESS) begin
			if(act[act_idx] == 0) begin
				w_en = 1;
				addr = img_idx[cnt];
				w_en1 = 1;
				addr1 = img_idx[cnt];
				
			end
			else if(act[act_idx] == 1 && switch == 0) begin
				if(size == 16 && mem_addr == 242) begin
					if(cnt_mp != 64) begin
						w_en = 0;
						addr = cnt_mp;
					end
					else if(cnt_mp == 64) begin
						w_en = 1;
						addr = 0;
					end
					else begin
						w_en = 1;
						addr = 0;
					end
				end
				
				
				else if (size == 8 && mem_addr == 58)begin//56
					if(cnt_mp != 16) begin
						w_en = 0;
						addr = cnt_mp;
					end
					else if(cnt_mp == 16) begin
						w_en = 1;
						addr = 0;
					end
					else begin
						w_en = 1;
						addr = 0;
					end
				end
				
				else if(flag[act_idx] == 1) begin
					w_en = 1;
					addr = 0;
				end
				
				else begin
					addr = img_idx[cnt];
					w_en = 1;
				end
			end
			
			
			else if(act[act_idx] == 1 && switch == 1) begin
				if(size == 16 && mem_addr == 242) begin
					if(cnt_mp != 64) begin
						w_en1 = 0;
						addr1 = cnt_mp;
					end
					else if(cnt_mp == 64) begin
						w_en1 = 1;
						addr1 = 0;
					end
					else begin
						w_en1 = 1;
						addr1 = 0;
					end
				end
				
				
				else if (size == 8 && mem_addr == 58)begin//56
					if(cnt_mp != 16) begin
						w_en1 = 0;
						addr1 = cnt_mp;
					end
					else if(cnt_mp == 16) begin
						w_en1 = 1;
						addr1 = 0;
					end
					else begin
						w_en1 = 1;
						addr1 = 0;
					end
				end
				
				
				
				
				
				else if(flag[act_idx] == 1) begin
					w_en1 = 1;
					addr1 = 0;
				end
				
				else begin
					addr1 = img_idx[cnt];
					w_en1 = 1;
				end
			end
			else if(act[act_idx] == 2 && switch == 0) begin
				if(size == 4) begin
					if(mem_addr < 17 && w_en == 1) begin
						addr = mem_addr;
						w_en = 1;
					end
					else if(cnt_hf == 17 && flag[act_idx] != 1) begin
						addr = mem_addr;
						w_en = 0;
					end
					else begin
						addr = 0;
						w_en = 1;
					end
				end
				else if(size == 8) begin
					if(mem_addr < 65 && w_en == 1) begin
						addr = mem_addr;
						w_en = 1;
					end
					else if(cnt_hf == 65 && flag[act_idx] != 1) begin
						addr = mem_addr;
						w_en = 0;
					end
					else begin
						addr = 0;
						w_en = 1;
					end
				end
				else if(size == 16) begin
					if(mem_addr < 257 && w_en == 1) begin
						addr = mem_addr;
						w_en = 1;
					end
					else if(cnt_hf == 257 && flag[act_idx] != 1) begin
						addr = mem_addr;
						w_en = 0;
					end
					else begin
						addr = 0;
						w_en = 1;
					end
				end
				else begin
					addr = 0;
					w_en = 1;
				end
			end
			
			else if(act[act_idx] == 2 && switch == 1) begin
				if(size == 4) begin
					if(mem_addr < 17 && w_en1 == 1) begin
						addr1 = mem_addr;
						w_en1 = 1;
					end
					else if(cnt_hf == 17 && flag[act_idx] != 1) begin
						addr1 = mem_addr;
						w_en1 = 0;
					end
					else begin
						addr1 = 0;
						w_en1 = 1;
					end
				end
				else if(size == 8) begin
					if(mem_addr < 65 && w_en1 == 1) begin
						addr1 = mem_addr;
						w_en1 = 1;
					end
					else if(cnt_hf == 65 && flag[act_idx] != 1) begin
						addr1 = mem_addr;
						w_en1 = 0;
					end
					else begin
						addr1 = 0;
						w_en1 = 1;
					end
				end
				else if(size == 16) begin
					if(mem_addr < 257 && w_en1 == 1) begin
						addr1 = mem_addr;
						w_en1 = 1;
					end
					else if(cnt_hf == 257 && flag[act_idx] != 1) begin
						addr1 = mem_addr;
						w_en1 = 0;
					end
					else begin
						addr1 = 0;
						w_en1 = 1;
					end
				end
				else begin
					addr1 = 0;
					w_en1 = 1;
				end
			end
			else if(act[act_idx] == 3) begin
				if(size == 4) begin
					if(mem_addr < 18 && switch == 1) begin
						addr = mem_addr-2;
						w_en = 0;
					end
					else begin
						addr = mem_addr;
						w_en = 1;
					end
					
					if(mem_addr < 18 && mem_addr > 1 && w_en == 1 && switch == 0) begin
						addr1 = mem_addr-2;
						w_en1 = 0;
					end
					else begin
						addr1 = mem_addr;
						w_en1 = 1;
					end
					
					
				end
				else if(size == 8) begin
					if(mem_addr < 66 && switch == 1) begin
						addr = mem_addr-2;
						w_en = 0;
					end
					else begin
						addr = mem_addr;
						w_en = 1;
					end
					
					if(mem_addr < 66 && mem_addr > 1 && w_en == 1 && switch == 0) begin
						addr1 = mem_addr-2;
						w_en1 = 0;
					end
					else begin
						addr1 = mem_addr;
						w_en1 = 1;
					end
					

				end
				else if(size == 16) begin
					if(mem_addr < 258 && switch == 1) begin
						addr = mem_addr-2;
						w_en = 0;
					end
					else begin
						addr = mem_addr;
						w_en = 1;
					end
					
					if(mem_addr < 258 && mem_addr > 1 && w_en == 1 && switch == 0) begin
						addr1 = mem_addr-2;
						w_en1 = 0;
					end
					else begin
						addr1 = mem_addr;
						w_en1 = 1;
					end
					

				end
				else begin
					w_en = 1;
					addr = 0;
					addr1 = 0;
					w_en1 = 1;
				end
			end
			else begin
				w_en = 1;
				addr = 0;
				addr1 = 0;
				w_en1 = 1;
			end
		end
		else begin
			w_en = 1;
			addr = 0;
			addr1 = 0;
			w_en1 = 1;
		end
	end
end

//cnt
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt <= 0;
	end
	else if(state == PROCESS) begin
		if(act[act_idx] == 0) begin
			if(size == 4) begin
				if(mem_addr == 0) begin
					if(cnt < 3) begin
						cnt <= cnt+1;
					end
					else begin
						cnt <= 0;
					end
				end
				else if(mem_addr == 3) begin
					if(cnt < 3) begin
						cnt <= cnt+1;
					end
					else begin
						cnt <= 0;
					end
				end
				else if(mem_addr == 12) begin
					if(cnt < 3) begin
						cnt <= cnt+1;
					end
					else begin
						cnt <= 0;
					end
				end
				else if(mem_addr == 15) begin
					if(cnt < 3) begin
						cnt <= cnt+1;
					end
					else begin
						cnt <= 0;
					end
				end
				else if(mem_addr > 0 && mem_addr < 3) begin
					if(cnt < 5) begin
						cnt <= cnt+1;
					end
					else begin
						cnt <= 0;
					end
				end
				else if(mem_addr > 12 && mem_addr < 15) begin
					if(cnt < 5) begin
						cnt <= cnt+1;
					end
					else begin
						cnt <= 0;
					end
				end
				else if(mem_addr%4 == 0) begin
					if(cnt < 5) begin
						cnt <= cnt+1;
					end
					else begin
						cnt <= 0;
					end
				end
				else if((mem_addr+1)%4 == 0) begin
					if(cnt < 5) begin
						cnt <= cnt+1;
					end
					else begin
						cnt <= 0;
					end
				end
				else begin
					if(cnt < 8) begin
						cnt <= cnt+1;
					end
					else begin
						cnt <= 0;
					end
				end
			end
			else if(size == 8) begin
				if(mem_addr == 0) begin
					if(cnt < 3) begin
						cnt <= cnt+1;
					end
					else begin
						cnt <= 0;
					end
				end
				else if(mem_addr == 7) begin
					if(cnt < 3) begin
						cnt <= cnt+1;
					end
					else begin
						cnt <= 0;
					end
				end
				else if(mem_addr == 56) begin
					if(cnt < 3) begin
						cnt <= cnt+1;
					end
					else begin
						cnt <= 0;
					end
				end
				else if(mem_addr == 63) begin
					if(cnt < 3) begin
						cnt <= cnt+1;
					end
					else begin
						cnt <= 0;
					end
				end
				else if(mem_addr > 0 && mem_addr < 7) begin
					if(cnt < 5) begin
						cnt <= cnt+1;
					end
					else begin
						cnt <= 0;
					end
				end
				else if(mem_addr > 56 && mem_addr < 63) begin
					if(cnt < 5) begin
						cnt <= cnt+1;
					end
					else begin
						cnt <= 0;
					end
				end
				else if(mem_addr%8 == 0) begin
					if(cnt < 5) begin
						cnt <= cnt+1;
					end
					else begin
						cnt <= 0;
					end
				end
				else if((mem_addr+1)%8 == 0) begin
					if(cnt < 5) begin
						cnt <= cnt+1;
					end
					else begin
						cnt <= 0;
					end
				end
				else begin
					if(cnt < 8) begin
						cnt <= cnt+1;
					end
					else begin
						cnt <= 0;
					end
				end
			end
			else if(size == 16) begin
				if(mem_addr == 0) begin
					if(cnt < 3) begin
						cnt <= cnt+1;
					end
					else begin
						cnt <= 0;
					end
				end
				else if(mem_addr == 15) begin
					if(cnt < 3) begin
						cnt <= cnt+1;
					end
					else begin
						cnt <= 0;
					end
				end
				else if(mem_addr == 240) begin
					if(cnt < 3) begin
						cnt <= cnt+1;
					end
					else begin
						cnt <= 0;
					end
				end
				else if(mem_addr == 255) begin
					if(cnt < 3) begin
						cnt <= cnt+1;
					end
					else begin
						cnt <= 0;
					end
				end
				else if(mem_addr > 0 && mem_addr < 15) begin
					if(cnt < 5) begin
						cnt <= cnt+1;
					end
					else begin
						cnt <= 0;
					end
				end
				else if(mem_addr > 240 && mem_addr < 255) begin
					if(cnt < 5) begin
						cnt <= cnt+1;
					end
					else begin
						cnt <= 0;
					end
				end
				else if(mem_addr%16 == 0) begin
					if(cnt < 5) begin
						cnt <= cnt+1;
					end
					else begin
						cnt <= 0;
					end
				end
				else if((mem_addr+1)%16 == 0) begin
					if(cnt < 5) begin
						cnt <= cnt+1;
					end
					else begin
						cnt <= 0;
					end
				end
				else begin
					if(cnt < 8) begin
						cnt <= cnt+1;
					end
					else begin
						cnt <= 0;
					end
				end
			end
		end
		else if(act[act_idx] == 1 /*&& img_idx[1] == 0*/) begin
			if(size == 4 && cnt < 3) begin
				cnt <= cnt+1;
			end
			else if(size == 8 && cnt < 3) begin
				cnt <= cnt+1;
			end
			else if(size == 16 && cnt < 3) begin
				cnt <= cnt+1;
			end
			else begin
				cnt <= 0;
			end
		end
		if(flag[act_idx] == 1) begin
			cnt <= 0;
		end
	end
	else if(state == RESET) begin
		cnt <= 0;
	end
end


//IMG index
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0;i<9;i=i+1) begin
			img_idx[i] <= 0;
		end
	end

	else if (state == PROCESS) begin
		if(act[act_idx] == 0) begin
			if(size == 4) begin
				if(mem_addr == 0) begin
					img_idx[0] <= mem_addr;
					img_idx[1] <= mem_addr+1;
					img_idx[2] <= mem_addr+4;
					img_idx[3] <= mem_addr+5;
					img_idx[4] <= 0;
					img_idx[5] <= 0;
					img_idx[6] <= 0;
					img_idx[7] <= 0;
					img_idx[8] <= 0;
				end
				else if(mem_addr == 3) begin
					img_idx[0] <= mem_addr-1;
					img_idx[1] <= mem_addr;
					img_idx[2] <= mem_addr+3;
					img_idx[3] <= mem_addr+4;
					img_idx[4] <= 0;
					img_idx[5] <= 0;
					img_idx[6] <= 0;
					img_idx[7] <= 0;
					img_idx[8] <= 0;
				end
				else if(mem_addr == 12) begin
					img_idx[0] <= mem_addr-4;
					img_idx[1] <= mem_addr-3;
					img_idx[2] <= mem_addr;
					img_idx[3] <= mem_addr+1;
					img_idx[4] <= 0;
					img_idx[5] <= 0;
					img_idx[6] <= 0;
					img_idx[7] <= 0;
					img_idx[8] <= 0;
				end
				else if(mem_addr == 15) begin
					img_idx[0] <= mem_addr-5;
					img_idx[1] <= mem_addr-4;
					img_idx[2] <= mem_addr-1;
					img_idx[3] <= mem_addr;
					img_idx[4] <= 0;
					img_idx[5] <= 0;
					img_idx[6] <= 0;
					img_idx[7] <= 0;
					img_idx[8] <= 0;
				end
				else if(mem_addr > 0 && mem_addr < 3) begin
					img_idx[0] <= mem_addr-1;
					img_idx[1] <= mem_addr;
					img_idx[2] <= mem_addr+1;
					img_idx[3] <= mem_addr+3;
					img_idx[4] <= mem_addr+4;
					img_idx[5] <= mem_addr+5;
					img_idx[6] <= 0;
					img_idx[7] <= 0;
					img_idx[8] <= 0;
				end
				else if(mem_addr > 12 && mem_addr < 15) begin
					img_idx[0] <= mem_addr-5;
					img_idx[1] <= mem_addr-4;
					img_idx[2] <= mem_addr-3;
					img_idx[3] <= mem_addr-1;
					img_idx[4] <= mem_addr;
					img_idx[5] <= mem_addr+1;
					img_idx[6] <= 0;
					img_idx[7] <= 0;
					img_idx[8] <= 0;
				end
				else if(mem_addr%4 == 0) begin
					img_idx[0] <= mem_addr-4;
					img_idx[1] <= mem_addr-3;
					img_idx[2] <= mem_addr;
					img_idx[3] <= mem_addr+1;
					img_idx[4] <= mem_addr+4;
					img_idx[5] <= mem_addr+5;
					img_idx[6] <= 0;
					img_idx[7] <= 0;
					img_idx[8] <= 0;
				end
				else if((mem_addr+1)%4 == 0) begin
					img_idx[0] <= mem_addr-5;
					img_idx[1] <= mem_addr-4;
					img_idx[2] <= mem_addr-1;
					img_idx[3] <= mem_addr;
					img_idx[4] <= mem_addr+3;
					img_idx[5] <= mem_addr+4;
					img_idx[6] <= 0;
					img_idx[7] <= 0;
					img_idx[8] <= 0;
				end
				else begin
					img_idx[0] <= mem_addr-5;
					img_idx[1] <= mem_addr-4;
					img_idx[2] <= mem_addr-3;
					img_idx[3] <= mem_addr-1;
					img_idx[4] <= mem_addr;
					img_idx[5] <= mem_addr+1;
					img_idx[6] <= mem_addr+3;
					img_idx[7] <= mem_addr+4;
					img_idx[8] <= mem_addr+5;
				end
			end
			else if(size == 8) begin
				if(mem_addr == 0) begin
					img_idx[0] <= mem_addr;
					img_idx[1] <= mem_addr+1;
					img_idx[2] <= mem_addr+8;
					img_idx[3] <= mem_addr+9;
					img_idx[4] <= 0;
					img_idx[5] <= 0;
					img_idx[6] <= 0;
					img_idx[7] <= 0;
					img_idx[8] <= 0;
				end
				else if(mem_addr == 7) begin
					img_idx[0] <= mem_addr-1;
					img_idx[1] <= mem_addr;
					img_idx[2] <= mem_addr+7;
					img_idx[3] <= mem_addr+8;
					img_idx[4] <= 0;
					img_idx[5] <= 0;
					img_idx[6] <= 0;
					img_idx[7] <= 0;
					img_idx[8] <= 0;
				end
				else if(mem_addr == 56) begin
					img_idx[0] <= mem_addr-8;
					img_idx[1] <= mem_addr-7;
					img_idx[2] <= mem_addr;
					img_idx[3] <= mem_addr+1;
					img_idx[4] <= 0;
					img_idx[5] <= 0;
					img_idx[6] <= 0;
					img_idx[7] <= 0;
					img_idx[8] <= 0;
				end
				else if(mem_addr == 63) begin
					img_idx[0] <= mem_addr-9;
					img_idx[1] <= mem_addr-8;
					img_idx[2] <= mem_addr-1;
					img_idx[3] <= mem_addr;
					img_idx[4] <= 0;
					img_idx[5] <= 0;
					img_idx[6] <= 0;
					img_idx[7] <= 0;
					img_idx[8] <= 0;
				end
				else if(mem_addr > 0 && mem_addr < 7) begin
					img_idx[0] <= mem_addr-1;
					img_idx[1] <= mem_addr;
					img_idx[2] <= mem_addr+1;
					img_idx[3] <= mem_addr+7;
					img_idx[4] <= mem_addr+8;
					img_idx[5] <= mem_addr+9;
					img_idx[6] <= 0;
					img_idx[7] <= 0;
					img_idx[8] <= 0;
				end
				else if(mem_addr > 56 && mem_addr < 63) begin
					img_idx[0] <= mem_addr-9;
					img_idx[1] <= mem_addr-8;
					img_idx[2] <= mem_addr-7;
					img_idx[3] <= mem_addr-1;
					img_idx[4] <= mem_addr;
					img_idx[5] <= mem_addr+1;
					img_idx[6] <= 0;
					img_idx[7] <= 0;
					img_idx[8] <= 0;
				end
				else if(mem_addr%8 == 0) begin
					img_idx[0] <= mem_addr-8;
					img_idx[1] <= mem_addr-7;
					img_idx[2] <= mem_addr;
					img_idx[3] <= mem_addr+1;
					img_idx[4] <= mem_addr+8;
					img_idx[5] <= mem_addr+9;
					img_idx[6] <= 0;
					img_idx[7] <= 0;
					img_idx[8] <= 0;
				end
				else if((mem_addr+1)%8 == 0) begin
					img_idx[0] <= mem_addr-9;
					img_idx[1] <= mem_addr-8;
					img_idx[2] <= mem_addr-1;
					img_idx[3] <= mem_addr;
					img_idx[4] <= mem_addr+7;
					img_idx[5] <= mem_addr+8;
					img_idx[6] <= 0;
					img_idx[7] <= 0;
					img_idx[8] <= 0;
				end
				else begin
					img_idx[0] <= mem_addr-9;
					img_idx[1] <= mem_addr-8;
					img_idx[2] <= mem_addr-7;
					img_idx[3] <= mem_addr-1;
					img_idx[4] <= mem_addr;
					img_idx[5] <= mem_addr+1;
					img_idx[6] <= mem_addr+7;
					img_idx[7] <= mem_addr+8;
					img_idx[8] <= mem_addr+9;
				end
			end
			else if(size == 16) begin
				if(mem_addr == 0) begin
					img_idx[0] <= mem_addr;
					img_idx[1] <= mem_addr+1;
					img_idx[2] <= mem_addr+16;
					img_idx[3] <= mem_addr+17;
					img_idx[4] <= 0;
					img_idx[5] <= 0;
					img_idx[6] <= 0;
					img_idx[7] <= 0;
					img_idx[8] <= 0;
				end
				else if(mem_addr == 15) begin
					img_idx[0] <= mem_addr-1;
					img_idx[1] <= mem_addr;
					img_idx[2] <= mem_addr+15;
					img_idx[3] <= mem_addr+16;
					img_idx[4] <= 0;
					img_idx[5] <= 0;
					img_idx[6] <= 0;
					img_idx[7] <= 0;
					img_idx[8] <= 0;
				end
				else if(mem_addr == 240) begin
					img_idx[0] <= mem_addr-16;
					img_idx[1] <= mem_addr-15;
					img_idx[2] <= mem_addr;
					img_idx[3] <= mem_addr+1;
					img_idx[4] <= 0;
					img_idx[5] <= 0;
					img_idx[6] <= 0;
					img_idx[7] <= 0;
					img_idx[8] <= 0;
				end
				else if(mem_addr == 255) begin
					img_idx[0] <= mem_addr-17;
					img_idx[1] <= mem_addr-16;
					img_idx[2] <= mem_addr-1;
					img_idx[3] <= mem_addr;
					img_idx[4] <= 0;
					img_idx[5] <= 0;
					img_idx[6] <= 0;
					img_idx[7] <= 0;
					img_idx[8] <= 0;
				end
				else if(mem_addr > 0 && mem_addr < 15) begin
					img_idx[0] <= mem_addr-1;
					img_idx[1] <= mem_addr;
					img_idx[2] <= mem_addr+1;
					img_idx[3] <= mem_addr+15;
					img_idx[4] <= mem_addr+16;
					img_idx[5] <= mem_addr+17;
					img_idx[6] <= 0;
					img_idx[7] <= 0;
					img_idx[8] <= 0;
				end
				else if(mem_addr > 240 && mem_addr < 255) begin
					img_idx[0] <= mem_addr-17;
					img_idx[1] <= mem_addr-16;
					img_idx[2] <= mem_addr-15;
					img_idx[3] <= mem_addr-1;
					img_idx[4] <= mem_addr;
					img_idx[5] <= mem_addr+1;
					img_idx[6] <= 0;
					img_idx[7] <= 0;
					img_idx[8] <= 0;
				end
				else if(mem_addr%16 == 0) begin
					img_idx[0] <= mem_addr-16;
					img_idx[1] <= mem_addr-15;
					img_idx[2] <= mem_addr;
					img_idx[3] <= mem_addr+1;
					img_idx[4] <= mem_addr+16;
					img_idx[5] <= mem_addr+17;
					img_idx[6] <= 0;
					img_idx[7] <= 0;
					img_idx[8] <= 0;
				end
				else if((mem_addr+1)%16 == 0) begin
					img_idx[0] <= mem_addr-17;
					img_idx[1] <= mem_addr-16;
					img_idx[2] <= mem_addr-1;
					img_idx[3] <= mem_addr;
					img_idx[4] <= mem_addr+15;
					img_idx[5] <= mem_addr+16;
					img_idx[6] <= 0;
					img_idx[7] <= 0;
					img_idx[8] <= 0;
				end
				else begin
					img_idx[0] <= mem_addr-17;
					img_idx[1] <= mem_addr-16;
					img_idx[2] <= mem_addr-15;
					img_idx[3] <= mem_addr-1;
					img_idx[4] <= mem_addr;
					img_idx[5] <= mem_addr+1;
					img_idx[6] <= mem_addr+15;
					img_idx[7] <= mem_addr+16;
					img_idx[8] <= mem_addr+17;
				end
			end
		end
		else if(act[act_idx] == 1) begin
			if(size == 8 && addr != 63 && mem_addr <= 56) begin
				img_idx[0] <= mem_addr;
				img_idx[1] <= mem_addr+1;
				img_idx[2] <= mem_addr+8;
				img_idx[3] <= mem_addr+9;
			end
			
			
			else if(size == 8 /* && img_idx[3] == 63 */) begin
				for(i=0;i<9;i=i+1) begin
					img_idx[i] <= 0;
				end
			end
			else if(size == 16 && addr != 255 && mem_addr <= 240) begin
				img_idx[0] <= mem_addr;
				img_idx[1] <= mem_addr+1;
				img_idx[2] <= mem_addr+16;
				img_idx[3] <= mem_addr+17;
			end
			else if(size == 16 /* && img_idx[3] == 255 */) begin
				for(i=0;i<9;i=i+1) begin
					img_idx[i] <= 0;
				end
			end
			
			
		end
	end	

	else if(state == RESET) begin
		for(i=0;i<9;i=i+1) begin
			img_idx[i] <= 0;
		end
	end
end




//Maxpooling
always @(*) begin
	if(!rst_n) begin
		max = 0;
	end
	else begin
		if(state == PROCESS) begin
			if(act[act_idx] == 1) begin
				if(addr != 0 && cnt == 1 && size != 4 && w_en == 1) begin
					if(ker[0]>=ker[1] && ker[0]>=ker[2] && ker[0]>=ker[3]) begin
						max = ker[0];
					end
					else if(ker[1]>=ker[0] && ker[1]>=ker[2] && ker[1]>=ker[3]) begin
						max = ker[1];
					end
					else if(ker[2]>=ker[0] && ker[2]>=ker[1] && ker[2]>=ker[3]) begin
						max = ker[2];
					end
					else if(ker[3]>=ker[0] && ker[3]>=ker[1] && ker[3]>=ker[2]) begin
						max = ker[3];
					end
					else begin
						max = 0;
					end
				end
				else begin
					max = 0;
				end
			end
			else begin
				max = 0;
			end
		end
		else begin
			max = 0;
		end
	end
end


//cnt mp
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_mp <= 0;
	end
	else if(state == PROCESS) begin
		if(act[act_idx] == 1 && w_en == 0 && switch == 0) begin
			if (cnt_mp < 64 && size == 16) begin
				cnt_mp <= cnt_mp+1;
			end
			else if (cnt_mp < 16 && size == 8) begin
				cnt_mp <= cnt_mp+1;
			end
			else begin
				cnt_mp <= 0;
			end
		end
		else if(act[act_idx] == 1 && w_en1 == 0 && switch == 1) begin
			if (cnt_mp < 64 && size == 16) begin
				cnt_mp <= cnt_mp+1;
			end
			else if (cnt_mp < 16 && size == 8) begin
				cnt_mp <= cnt_mp+1;
			end
			else begin
				cnt_mp <= 0;
			end
		end
		else begin
			cnt_mp <= 0;
		end
		
	end
	else if(state == RESET) begin
		cnt_mp <= 0;
	end
end


//Cross Correlation
always @(*) begin
	if(!rst_n) begin
		cross_result = 0;
	end
	else begin
		if(state == PROCESS) begin
			if(act[act_idx] == 0) begin
				if(size == 4 && mem_addr != 0) begin
					if(cnt == 2 && (mem_addr-1) == 0) begin
						cross_result = ker[0]*tmp[8] + ker[1]*tmp[4] + ker[2]*tmp[5] + ker[3]*tmp[7];
					end
					else if(cnt == 2 && (mem_addr-1) == 3) begin
						cross_result = ker[0]*tmp[7] + ker[1]*tmp[3] + ker[2]*tmp[4] + ker[3]*tmp[6];
					end
					else if(cnt == 2 && (mem_addr-1) == 12) begin
						cross_result = ker[0]*tmp[5] + ker[1]*tmp[1] + ker[2]*tmp[2] + ker[3]*tmp[4];
					end
					else if(cnt == 2 && (mem_addr-1) == 15) begin
						cross_result = ker[0]*tmp[4] + ker[1]*tmp[0] + ker[2]*tmp[1] + ker[3]*tmp[3];
					end
					else if(cnt == 2 && (mem_addr-1) > 0  && (mem_addr-1) < 3) begin
						cross_result = ker[0]*tmp[8] + ker[1]*tmp[3] + ker[2]*tmp[4] + ker[3]*tmp[5] + ker[4]*tmp[6] + ker[5]*tmp[7];
					end
					else if(cnt == 2 && (mem_addr-1) > 12  && (mem_addr-1) < 15) begin
						cross_result = ker[0]*tmp[5] + ker[1]*tmp[0] + ker[2]*tmp[1] + ker[3]*tmp[2] + ker[4]*tmp[3] + ker[5]*tmp[4];
					end
					else if(cnt == 2 && (mem_addr-1)%4 == 0) begin
						cross_result = ker[0]*tmp[8] + ker[1]*tmp[1] + ker[2]*tmp[2] + ker[3]*tmp[4] + ker[4]*tmp[5] + ker[5]*tmp[7];
					end
					else if(cnt == 2 && (mem_addr)%4 == 0) begin
						cross_result = ker[0]*tmp[7] + ker[1]*tmp[0] + ker[2]*tmp[1] + ker[3]*tmp[3] + ker[4]*tmp[4] + ker[5]*tmp[6];
					end
					else if(cnt == 2 && (mem_addr-1) < 16) begin
						cross_result = ker[0]*tmp[8] + ker[1]*tmp[0] + ker[2]*tmp[1] + ker[3]*tmp[2] + ker[4]*tmp[3] + ker[5]*tmp[4] + ker[6]*tmp[5] + ker[7]*tmp[6] + ker[8]*tmp[7];
					end
					else begin
						cross_result = 0;
					end
				end
				else if(size == 8 && mem_addr != 0) begin
					if(cnt == 2 && (mem_addr-1) == 0) begin
						cross_result = ker[0]*tmp[8] + ker[1]*tmp[4] + ker[2]*tmp[5] + ker[3]*tmp[7];
					end
					else if(cnt == 2 && (mem_addr-1) == 7) begin
						cross_result = ker[0]*tmp[7] + ker[1]*tmp[3] + ker[2]*tmp[4] + ker[3]*tmp[6];
					end
					else if(cnt == 2 && (mem_addr-1) == 56) begin
						cross_result = ker[0]*tmp[5] + ker[1]*tmp[1] + ker[2]*tmp[2] + ker[3]*tmp[4];
					end
					else if(cnt == 2 && (mem_addr-1) == 63) begin
						cross_result = ker[0]*tmp[4] + ker[1]*tmp[0] + ker[2]*tmp[1] + ker[3]*tmp[3];
					end
					else if(cnt == 2 && (mem_addr-1) > 0  && (mem_addr-1) < 7) begin
						cross_result = ker[0]*tmp[8] + ker[1]*tmp[3] + ker[2]*tmp[4] + ker[3]*tmp[5] + ker[4]*tmp[6] + ker[5]*tmp[7];
					end
					else if(cnt == 2 && (mem_addr-1) > 56  && (mem_addr-1) < 63) begin
						cross_result = ker[0]*tmp[5] + ker[1]*tmp[0] + ker[2]*tmp[1] + ker[3]*tmp[2] + ker[4]*tmp[3] + ker[5]*tmp[4];
					end
					else if(cnt == 2 && (mem_addr-1)%8 == 0) begin
						cross_result = ker[0]*tmp[8] + ker[1]*tmp[1] + ker[2]*tmp[2] + ker[3]*tmp[4] + ker[4]*tmp[5] + ker[5]*tmp[7];
					end
					else if(cnt == 2 && (mem_addr)%8 == 0) begin
						cross_result = ker[0]*tmp[7] + ker[1]*tmp[0] + ker[2]*tmp[1] + ker[3]*tmp[3] + ker[4]*tmp[4] + ker[5]*tmp[6];
					end
					else if(cnt == 2 && (mem_addr-1) < 64) begin
						cross_result = ker[0]*tmp[8] + ker[1]*tmp[0] + ker[2]*tmp[1] + ker[3]*tmp[2] + ker[4]*tmp[3] + ker[5]*tmp[4] + ker[6]*tmp[5] + ker[7]*tmp[6] + ker[8]*tmp[7];
					end
					else begin
						cross_result = 0;
					end
				end
				else if(size == 16 && mem_addr != 0) begin
					if(cnt == 2 && (mem_addr-1) == 0) begin
						cross_result = ker[0]*tmp[8] + ker[1]*tmp[4] + ker[2]*tmp[5] + ker[3]*tmp[7];
					end
					else if(cnt == 2 && (mem_addr-1) == 15) begin
						cross_result = ker[0]*tmp[7] + ker[1]*tmp[3] + ker[2]*tmp[4] + ker[3]*tmp[6];
					end
					else if(cnt == 2 && (mem_addr-1) == 240) begin
						cross_result = ker[0]*tmp[5] + ker[1]*tmp[1] + ker[2]*tmp[2] + ker[3]*tmp[4];
					end
					else if(cnt == 2 && (mem_addr-1) == 255) begin
						cross_result = ker[0]*tmp[4] + ker[1]*tmp[0] + ker[2]*tmp[1] + ker[3]*tmp[3];
					end
					else if(cnt == 2 && (mem_addr-1) > 0  && (mem_addr-1) < 15) begin
						cross_result = ker[0]*tmp[8] + ker[1]*tmp[3] + ker[2]*tmp[4] + ker[3]*tmp[5] + ker[4]*tmp[6] + ker[5]*tmp[7];
					end
					else if(cnt == 2 && (mem_addr-1) > 240  && (mem_addr-1) < 255) begin
						cross_result = ker[0]*tmp[5] + ker[1]*tmp[0] + ker[2]*tmp[1] + ker[3]*tmp[2] + ker[4]*tmp[3] + ker[5]*tmp[4];
					end
					else if(cnt == 2 && (mem_addr-1)%16 == 0) begin
						cross_result = ker[0]*tmp[8] + ker[1]*tmp[1] + ker[2]*tmp[2] + ker[3]*tmp[4] + ker[4]*tmp[5] + ker[5]*tmp[7];
					end
					else if(cnt == 2 && (mem_addr)%16 == 0) begin
						cross_result = ker[0]*tmp[7] + ker[1]*tmp[0] + ker[2]*tmp[1] + ker[3]*tmp[3] + ker[4]*tmp[4] + ker[5]*tmp[6];
					end
					else if(cnt == 2 && (mem_addr-1) < 256) begin
						cross_result = ker[0]*tmp[8] + ker[1]*tmp[0] + ker[2]*tmp[1] + ker[3]*tmp[2] + ker[4]*tmp[3] + ker[5]*tmp[4] + ker[6]*tmp[5] + ker[7]*tmp[6] + ker[8]*tmp[7];
					end
					else begin
						cross_result = 0;
					end
				end
				else begin
					cross_result = 0;
				end
			end
			else begin
				cross_result = 0;
			end
		end
		else begin
			cross_result = 0;
		end
	end
end


//Out
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0;i<256;i=i+1) begin
			out[i] <= 0;
		end
		out_max <= 0;
		out_max_pos <= 0;
	end

	else if(state == RESET) begin
		for(i=0;i<256;i=i+1) begin
			out[i] <= 0;
		end
		out_max <= 0;
		out_max_pos <= 0;
	end

	else if(state == PROCESS) begin
		if(act[act_idx] == 0 && mem_addr != 0 && cnt == 2 && size == 4) begin
			if(mem_addr == 16 && cnt > 2) begin
				for(i=0;i<256;i=i+1) begin
					out[i] <= out[i];
				end
				out_max <= out_max;
			end
			else begin
				if(cross_result > out_max && mem_addr >= 2 && cnt == 2) begin
					out_max <= cross_result;
					out_max_pos <= mem_addr-1;
				end
				else if(mem_addr < 2 && cnt == 2 && mem_addr > 0) begin
					out_max <= cross_result;
					out_max_pos <= mem_addr-1;
				end
				else begin
					out_max <= out_max;
					out_max_pos <= out_max_pos;
				end
				out[mem_addr-1] <= cross_result;
			end
		end
		else if(act[act_idx] == 0 && mem_addr != 0 && cnt == 2 && size == 8) begin
			if(mem_addr == 64 && cnt > 2) begin
				for(i=0;i<256;i=i+1) begin
					out[i] <= out[i];
				end
				out_max <= out_max;
			end
			else begin
				if(cross_result > out_max && mem_addr >= 2 && cnt == 2) begin
					out_max <= cross_result;
					out_max_pos <= mem_addr-1;
				end
				else if(mem_addr < 2 && cnt == 2 && mem_addr > 0) begin
					out_max <= cross_result;
					out_max_pos <= mem_addr-1;
				end
				else begin
					out_max <= out_max;
					out_max_pos <= out_max_pos;
				end
				out[mem_addr-1] <= cross_result;
			end
		end
		else if(act[act_idx] == 0 && mem_addr != 0 && cnt == 2 && size == 16) begin
			if(mem_addr == 256 && cnt > 2) begin
				for(i=0;i<256;i=i+1) begin
					out[i] <= out[i];
				end
				out_max <= out_max;
			end
			else begin
				if(cross_result > out_max && mem_addr >= 2 && cnt == 2) begin
					out_max <= cross_result;
					out_max_pos <= mem_addr-1;
				end
				else if(mem_addr < 2 && cnt == 2 && mem_addr > 0) begin
					out_max <= cross_result;
					out_max_pos <= mem_addr-1;
				end
				else begin
					out_max <= out_max;
					out_max_pos <= out_max_pos;
				end
				out[mem_addr-1] <= cross_result;
			end
		end
		
		else if(act[act_idx] == 2 && w_en == 1 && switch == 0) begin
			if(size == 4 && mem_addr != 17 && mem_addr >0) begin
				if(pix_out[15] == 0) begin
					out[addr-1] <= pix_out;
				end
				else begin
					out[addr-1] <= {{20{pix_out[15]}}, pix_out};
				end
			end
			else if(size == 8 && mem_addr != 65 && mem_addr >0) begin
				if(pix_out[15] == 0) begin
					out[addr-1] <= pix_out;
				end
				else begin
					out[addr-1] <= {{20{pix_out[15]}}, pix_out};
				end
			end
			else if(size == 16 && mem_addr != 257 && mem_addr >0) begin
				if(pix_out[15] == 0) begin
					out[addr-1] <= pix_out;
				end
				else begin
					out[addr-1] <= {{20{pix_out[15]}}, pix_out};
				end
			end
		end
		
		
		
		
		else if(act[act_idx] == 2 && w_en1 == 1 && switch == 1) begin
			if(size == 4 && mem_addr != 17 && mem_addr >0) begin
				if(pix_out1[15] == 0) begin
					out[addr1-1] <= pix_out1;
				end
				else begin
					out[addr1-1] <= {{20{pix_out1[15]}}, pix_out1};
				end
			end
			else if(size == 8 && mem_addr != 65 && mem_addr >0) begin
				if(pix_out1[15] == 0) begin
					out[addr1-1] <= pix_out1;
				end
				else begin
					out[addr1-1] <= {{20{pix_out1[15]}}, pix_out1};
				end
			end
			else if(size == 16 && mem_addr != 257 && mem_addr >0) begin
				if(pix_out1[15] == 0) begin
					out[addr1-1] <= pix_out1;
				end
				else begin
					out[addr1-1] <= {{20{pix_out1[15]}}, pix_out1};
				end
			end
		end
		
		
		else if(act[act_idx] == 3 && flag[act_idx] == 0 && mem_addr >= 2 && w_en == 1) begin
			if(ker[0][15] == 0) begin
				out[mem_addr-2] <= ker[0];
			end
			else begin
				out[mem_addr-2] <= {{20{ker[0][15]}}, ker[0]};
			end
			//out[mem_addr-2] <= ker[0];
		end

		else if(act[act_idx] == 1 && flag[act_idx] == 0 && mem_addr >= 2 && cnt == 1) begin
			if(size == 16 && mem_addr < 242) begin
				if(pix_in[15] == 0) begin
					out[m_cnt-1] <= pix_in;
				end
				else begin
					out[m_cnt-1] <= {{20{pix_in[15]}}, pix_in};
				end
				//out[m_cnt-1] <= pix_in;
			end
			else if(size == 8 && mem_addr < 58) begin
				if(pix_in[15] == 0) begin
					out[m_cnt-1] <= pix_in;
				end
				else begin
					out[m_cnt-1] <= {{20{pix_in[15]}}, pix_in};
				end
				//out[m_cnt-1] <= pix_in;
			end
		end

		else if(flag[act_idx] == 1) begin
			for(i=0;i<256;i=i+1) begin
				out[i] <= 0;
			end
		end

	end

end



//cnt hf
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_hf <= 0;
	end
	else if(state == PROCESS) begin
		if(act[act_idx] == 2 && w_en == 1 && switch == 0) begin
			if(size == 4 && mem_addr != 17 && mem_addr >0) begin
				cnt_hf <= 0;
			end
			else if(size == 4 && mem_addr == 17) begin
				if(cnt_hf <= 16) begin
					cnt_hf <= cnt_hf+1;
				end
				else begin
					cnt_hf <= cnt_hf;
				end
			end
			else if(size == 8 && mem_addr != 65 && mem_addr >0) begin
				cnt_hf <= 0;
			end
			else if(size == 8 && mem_addr == 65) begin
				if(cnt_hf <= 64) begin
					cnt_hf <= cnt_hf+1;
				end
				else begin
					cnt_hf <= cnt_hf;
				end
			end
			else if(size == 16 && mem_addr != 257 && mem_addr >0) begin
				cnt_hf <= 0;
			end
			else if(size == 16 && mem_addr == 257) begin
				if(cnt_hf <= 256) begin
					cnt_hf <= cnt_hf+1;
				end
				else begin
					cnt_hf <= cnt_hf;
				end
			end
			else begin
				cnt_hf <= 0;
			end
		end
		
		else if(act[act_idx] == 2 && w_en1 == 1 && switch == 1) begin
			if(size == 4 && mem_addr != 17 && mem_addr >0) begin
				cnt_hf <= 0;
			end
			else if(size == 4 && mem_addr == 17) begin
				if(cnt_hf <= 16) begin
					cnt_hf <= cnt_hf+1;
				end
				else begin
					cnt_hf <= cnt_hf;
				end
			end
			else if(size == 8 && mem_addr != 65 && mem_addr >0) begin
				cnt_hf <= 0;
			end
			else if(size == 8 && mem_addr == 65) begin
				if(cnt_hf <= 64) begin
					cnt_hf <= cnt_hf+1;
				end
				else begin
					cnt_hf <= cnt_hf;
				end
			end
			else if(size == 16 && mem_addr != 257 && mem_addr >0) begin
				cnt_hf <= 0;
			end
			else if(size == 16 && mem_addr == 257) begin
				if(cnt_hf <= 256) begin
					cnt_hf <= cnt_hf+1;
				end
				else begin
					cnt_hf <= cnt_hf;
				end
			end
			else begin
				cnt_hf <= 0;
			end
		end
		
	end
	else if(state == RESET) begin
		cnt_hf <= 0;
	end
end




//hf addr
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		hf_addr <= 0;
	end
	else if(state == PROCESS) begin
		if(act[act_idx] == 2 && w_en == 0 && switch == 0) begin
			if(size == 4 && mem_addr == 17) begin
				if(cnt_hf >= 0 && cnt_hf <= 3) begin
					hf_addr <= 3-cnt_hf;
				end
				else if(cnt_hf >= 4 && cnt_hf <= 7) begin
					hf_addr <= 11-cnt_hf;
				end
				else if(cnt_hf >= 8 && cnt_hf <= 11) begin
					hf_addr <= 19-cnt_hf;
				end
				else if(cnt_hf >= 12 && cnt_hf <= 15) begin
					hf_addr <= 27-cnt_hf;
				end
			end
			else if(size == 8 && mem_addr == 65) begin
				if(cnt_hf >= 0 && cnt_hf <= 7) begin
					hf_addr <= 7-cnt_hf;
				end
				else if(cnt_hf >= 8 && cnt_hf <= 15) begin
					hf_addr <= 23-cnt_hf;
				end
				else if(cnt_hf >= 16 && cnt_hf <= 23) begin
					hf_addr <= 39-cnt_hf;
				end
				else if(cnt_hf >= 24 && cnt_hf <= 31) begin
					hf_addr <= 55-cnt_hf;
				end
				else if(cnt_hf >= 32 && cnt_hf <= 39) begin
					hf_addr <= 71-cnt_hf;
				end
				else if(cnt_hf >= 40 && cnt_hf <= 47) begin
					hf_addr <= 87-cnt_hf;
				end
				else if(cnt_hf >= 48 && cnt_hf <= 55) begin
					hf_addr <= 103-cnt_hf;
				end
				else if(cnt_hf >= 56 && cnt_hf <= 63) begin
					hf_addr <= 119-cnt_hf;
				end
			end
			else if(size == 16 && mem_addr == 257) begin
				if(cnt_hf >= 0 && cnt_hf <= 15) begin
					hf_addr <= 15-cnt_hf;
				end
				else if(cnt_hf >= 16 && cnt_hf <= 31) begin
					hf_addr <= 47-cnt_hf;
				end
				else if(cnt_hf >= 32 && cnt_hf <= 47) begin
					hf_addr <= 79-cnt_hf;
				end
				else if(cnt_hf >= 48 && cnt_hf <= 63) begin
					hf_addr <= 111-cnt_hf;
				end
				else if(cnt_hf >= 64 && cnt_hf <= 79) begin
					hf_addr <= 143-cnt_hf;
				end
				else if(cnt_hf >= 80 && cnt_hf <= 95) begin
					hf_addr <= 175-cnt_hf;
				end
				else if(cnt_hf >= 96 && cnt_hf <= 111) begin
					hf_addr <= 207-cnt_hf;
				end
				else if(cnt_hf >= 112 && cnt_hf <= 127) begin
					hf_addr <= 239-cnt_hf;
				end
				else if(cnt_hf >= 128 && cnt_hf <= 143) begin
					hf_addr <= 271-cnt_hf;
				end
				else if(cnt_hf >= 144 && cnt_hf <= 159) begin
					hf_addr <= 303-cnt_hf;
				end
				else if(cnt_hf >= 160 && cnt_hf <= 175) begin
					hf_addr <= 335-cnt_hf;
				end
				else if(cnt_hf >= 176 && cnt_hf <= 191) begin
					hf_addr <= 367-cnt_hf;
				end
				else if(cnt_hf >= 192 && cnt_hf <= 207) begin
					hf_addr <= 399-cnt_hf;
				end
				else if(cnt_hf >= 208 && cnt_hf <= 223) begin
					hf_addr <= 431-cnt_hf;
				end
				else if(cnt_hf >= 224 && cnt_hf <= 239) begin
					hf_addr <= 463-cnt_hf;
				end
				else if(cnt_hf >= 240 && cnt_hf <= 255) begin
					hf_addr <= 495-cnt_hf;
				end
			end
		end
		else if(act[act_idx] == 2 && w_en1 == 0 && switch == 1) begin
			if(size == 4 && mem_addr == 17) begin
				if(cnt_hf >= 0 && cnt_hf <= 3) begin
					hf_addr <= 3-cnt_hf;
				end
				else if(cnt_hf >= 4 && cnt_hf <= 7) begin
					hf_addr <= 11-cnt_hf;
				end
				else if(cnt_hf >= 8 && cnt_hf <= 11) begin
					hf_addr <= 19-cnt_hf;
				end
				else if(cnt_hf >= 12 && cnt_hf <= 15) begin
					hf_addr <= 27-cnt_hf;
				end
			end
			else if(size == 8 && mem_addr == 65) begin
				if(cnt_hf >= 0 && cnt_hf <= 7) begin
					hf_addr <= 7-cnt_hf;
				end
				else if(cnt_hf >= 8 && cnt_hf <= 15) begin
					hf_addr <= 23-cnt_hf;
				end
				else if(cnt_hf >= 16 && cnt_hf <= 23) begin
					hf_addr <= 39-cnt_hf;
				end
				else if(cnt_hf >= 24 && cnt_hf <= 31) begin
					hf_addr <= 55-cnt_hf;
				end
				else if(cnt_hf >= 32 && cnt_hf <= 39) begin
					hf_addr <= 71-cnt_hf;
				end
				else if(cnt_hf >= 40 && cnt_hf <= 47) begin
					hf_addr <= 87-cnt_hf;
				end
				else if(cnt_hf >= 48 && cnt_hf <= 55) begin
					hf_addr <= 103-cnt_hf;
				end
				else if(cnt_hf >= 56 && cnt_hf <= 63) begin
					hf_addr <= 119-cnt_hf;
				end
			end
			else if(size == 16 && mem_addr == 257) begin
				if(cnt_hf >= 0 && cnt_hf <= 15) begin
					hf_addr <= 15-cnt_hf;
				end
				else if(cnt_hf >= 16 && cnt_hf <= 31) begin
					hf_addr <= 47-cnt_hf;
				end
				else if(cnt_hf >= 32 && cnt_hf <= 47) begin
					hf_addr <= 79-cnt_hf;
				end
				else if(cnt_hf >= 48 && cnt_hf <= 63) begin
					hf_addr <= 111-cnt_hf;
				end
				else if(cnt_hf >= 64 && cnt_hf <= 79) begin
					hf_addr <= 143-cnt_hf;
				end
				else if(cnt_hf >= 80 && cnt_hf <= 95) begin
					hf_addr <= 175-cnt_hf;
				end
				else if(cnt_hf >= 96 && cnt_hf <= 111) begin
					hf_addr <= 207-cnt_hf;
				end
				else if(cnt_hf >= 112 && cnt_hf <= 127) begin
					hf_addr <= 239-cnt_hf;
				end
				else if(cnt_hf >= 128 && cnt_hf <= 143) begin
					hf_addr <= 271-cnt_hf;
				end
				else if(cnt_hf >= 144 && cnt_hf <= 159) begin
					hf_addr <= 303-cnt_hf;
				end
				else if(cnt_hf >= 160 && cnt_hf <= 175) begin
					hf_addr <= 335-cnt_hf;
				end
				else if(cnt_hf >= 176 && cnt_hf <= 191) begin
					hf_addr <= 367-cnt_hf;
				end
				else if(cnt_hf >= 192 && cnt_hf <= 207) begin
					hf_addr <= 399-cnt_hf;
				end
				else if(cnt_hf >= 208 && cnt_hf <= 223) begin
					hf_addr <= 431-cnt_hf;
				end
				else if(cnt_hf >= 224 && cnt_hf <= 239) begin
					hf_addr <= 463-cnt_hf;
				end
				else if(cnt_hf >= 240 && cnt_hf <= 255) begin
					hf_addr <= 495-cnt_hf;
				end
			end
		end
	end
	else if(state == RESET) begin
		hf_addr <= 0;
	end
end










//Horizontal flip (mem)
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0;i<256;i=i+1) begin
			//mem[i] <= 0;
			mem_hf[i] <= 0;
		end
	end

	else if(state == RESET) begin
		for(i=0;i<256;i=i+1) begin
			//mem[i] <= 0;
			mem_hf[i] <= 0;
		end
	end

	else if(state == PROCESS) begin
		if(act[act_idx] == 2 && w_en == 1 && switch == 0) begin
			if(size == 4 && mem_addr == 17) begin
				if(cnt_hf >= 0 && cnt_hf <= 3) begin
					mem_hf[3-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 4 && cnt_hf <= 7) begin
					mem_hf[11-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 8 && cnt_hf <= 11) begin
					mem_hf[19-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 12 && cnt_hf <= 15) begin
					mem_hf[27-cnt_hf] <= out[cnt_hf];//mem
				end
			end
			else if(size == 8 && mem_addr == 65) begin
				if(cnt_hf >= 0 && cnt_hf <= 7) begin
					mem_hf[7-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 8 && cnt_hf <= 15) begin
					mem_hf[23-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 16 && cnt_hf <= 23) begin
					mem_hf[39-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 24 && cnt_hf <= 31) begin
					mem_hf[55-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 32 && cnt_hf <= 39) begin
					mem_hf[71-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 40 && cnt_hf <= 47) begin
					mem_hf[87-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 48 && cnt_hf <= 55) begin
					mem_hf[103-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 56 && cnt_hf <= 63) begin
					mem_hf[119-cnt_hf] <= out[cnt_hf];//mem
				end
			end
			else if(size == 16 && mem_addr == 257) begin
				if(cnt_hf >= 0 && cnt_hf <= 15) begin
					mem_hf[15-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 16 && cnt_hf <= 31) begin
					mem_hf[47-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 32 && cnt_hf <= 47) begin
					mem_hf[79-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 48 && cnt_hf <= 63) begin
					mem_hf[111-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 64 && cnt_hf <= 79) begin
					mem_hf[143-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 80 && cnt_hf <= 95) begin
					mem_hf[175-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 96 && cnt_hf <= 111) begin
					mem_hf[207-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 112 && cnt_hf <= 127) begin
					mem_hf[239-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 128 && cnt_hf <= 143) begin
					mem_hf[271-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 144 && cnt_hf <= 159) begin
					mem_hf[303-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 160 && cnt_hf <= 175) begin
					mem_hf[335-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 176 && cnt_hf <= 191) begin
					mem_hf[367-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 192 && cnt_hf <= 207) begin
					mem_hf[399-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 208 && cnt_hf <= 223) begin
					mem_hf[431-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 224 && cnt_hf <= 239) begin
					mem_hf[463-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 240 && cnt_hf <= 255) begin
					mem_hf[495-cnt_hf] <= out[cnt_hf];//mem
				end
			end
		end
		else if(act[act_idx] == 2 && w_en1 == 1 && switch == 1) begin
			if(size == 4 && mem_addr == 17) begin
				if(cnt_hf >= 0 && cnt_hf <= 3) begin
					mem_hf[3-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 4 && cnt_hf <= 7) begin
					mem_hf[11-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 8 && cnt_hf <= 11) begin
					mem_hf[19-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 12 && cnt_hf <= 15) begin
					mem_hf[27-cnt_hf] <= out[cnt_hf];//mem
				end
			end
			else if(size == 8 && mem_addr == 65) begin
				if(cnt_hf >= 0 && cnt_hf <= 7) begin
					mem_hf[7-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 8 && cnt_hf <= 15) begin
					mem_hf[23-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 16 && cnt_hf <= 23) begin
					mem_hf[39-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 24 && cnt_hf <= 31) begin
					mem_hf[55-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 32 && cnt_hf <= 39) begin
					mem_hf[71-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 40 && cnt_hf <= 47) begin
					mem_hf[87-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 48 && cnt_hf <= 55) begin
					mem_hf[103-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 56 && cnt_hf <= 63) begin
					mem_hf[119-cnt_hf] <= out[cnt_hf];//mem
				end
			end
			else if(size == 16 && mem_addr == 257) begin
				if(cnt_hf >= 0 && cnt_hf <= 15) begin
					mem_hf[15-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 16 && cnt_hf <= 31) begin
					mem_hf[47-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 32 && cnt_hf <= 47) begin
					mem_hf[79-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 48 && cnt_hf <= 63) begin
					mem_hf[111-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 64 && cnt_hf <= 79) begin
					mem_hf[143-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 80 && cnt_hf <= 95) begin
					mem_hf[175-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 96 && cnt_hf <= 111) begin
					mem_hf[207-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 112 && cnt_hf <= 127) begin
					mem_hf[239-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 128 && cnt_hf <= 143) begin
					mem_hf[271-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 144 && cnt_hf <= 159) begin
					mem_hf[303-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 160 && cnt_hf <= 175) begin
					mem_hf[335-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 176 && cnt_hf <= 191) begin
					mem_hf[367-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 192 && cnt_hf <= 207) begin
					mem_hf[399-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 208 && cnt_hf <= 223) begin
					mem_hf[431-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 224 && cnt_hf <= 239) begin
					mem_hf[463-cnt_hf] <= out[cnt_hf];//mem
				end
				else if(cnt_hf >= 240 && cnt_hf <= 255) begin
					mem_hf[495-cnt_hf] <= out[cnt_hf];//mem
				end
			end
		end
	end

	else begin
		for(i=0;i<256;i=i+1) begin
			mem_hf[i] <= mem_hf[i];
		end
	end
end



//Kernel reg
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0;i<9;i=i+1) begin
			ker[i] <= 0;
		end
	end
	else if(state == PROCESS) begin
		if(act[act_idx] == 0) begin
			if(size == 4 && switch == 0) begin
				if(mem_addr-1 == 0 && cnt <= 3 && cnt != 0) begin
					ker[cnt] <= pix_out;
					for(i=4;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 == 3 && cnt <= 3) begin
					ker[cnt] <= pix_out;
					for(i=4;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 == 12 && cnt <= 3) begin
					ker[cnt] <= pix_out;
					for(i=4;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 == 15 && cnt <= 3) begin
					ker[cnt] <= pix_out;
					for(i=4;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 > 0 && mem_addr-1 < 3 && cnt <= 5) begin
					ker[cnt] <= pix_out;
					for(i=6;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 > 12 && mem_addr-1 < 15 && cnt <= 5) begin
					ker[cnt] <= pix_out;
					for(i=6;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if((mem_addr-1)%4 == 0 && cnt <= 5) begin
					ker[cnt] <= pix_out;
					for(i=6;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if((mem_addr)%4 == 0 && cnt <= 5) begin
					ker[cnt] <= pix_out;
					for(i=6;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(cnt <= 8) begin
					ker[cnt] <= pix_out;
				end
			end
			else if(size == 8 && switch == 0) begin
				if(mem_addr-1 == 0 && cnt <= 3 && cnt != 0) begin
					ker[cnt] <= pix_out;
					for(i=4;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 == 7 && cnt <= 3) begin
					ker[cnt] <= pix_out;
					for(i=4;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 == 56 && cnt <= 3) begin
					ker[cnt] <= pix_out;
					for(i=4;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 == 63 && cnt <= 3) begin
					ker[cnt] <= pix_out;
					for(i=4;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 > 0 && mem_addr-1 < 7 && cnt <= 5) begin
					ker[cnt] <= pix_out;
					for(i=6;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 > 56 && mem_addr-1 < 63 && cnt <= 5) begin
					ker[cnt] <= pix_out;
					for(i=6;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if((mem_addr-1)%8 == 0 && cnt <= 5) begin
					ker[cnt] <= pix_out;
					for(i=6;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if((mem_addr)%8 == 0 && cnt <= 5) begin
					ker[cnt] <= pix_out;
					for(i=6;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(cnt <= 8) begin
					ker[cnt] <= pix_out;
				end
			end
			else if(size == 16 && switch == 0) begin
				if(mem_addr-1 == 0 && cnt <= 3) begin
					ker[cnt] <= pix_out;
					for(i=4;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 == 15 && cnt <= 3) begin
					ker[cnt] <= pix_out;
					for(i=4;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 == 240 && cnt <= 3) begin
					ker[cnt] <= pix_out;
					for(i=4;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 == 255 && cnt <= 3) begin
					ker[cnt] <= pix_out;
					for(i=4;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 > 0 && mem_addr-1 < 15 && cnt <= 5) begin
					ker[cnt] <= pix_out;
					for(i=6;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 > 240 && mem_addr-1 < 255 && cnt <= 5) begin
					ker[cnt] <= pix_out;
					for(i=6;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if((mem_addr-1)%16 == 0 && cnt <= 5) begin
					ker[cnt] <= pix_out;
					for(i=6;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if((mem_addr)%16 == 0 && cnt <= 5) begin
					ker[cnt] <= pix_out;
					for(i=6;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(cnt <= 8) begin
					ker[cnt] <= pix_out;
				end
			end
			else if(size == 4 && switch == 1) begin
				if(mem_addr-1 == 0 && cnt <= 3 && cnt != 0) begin
					ker[cnt] <= pix_out1;
					for(i=4;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 == 3 && cnt <= 3) begin
					ker[cnt] <= pix_out1;
					for(i=4;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 == 12 && cnt <= 3) begin
					ker[cnt] <= pix_out1;
					for(i=4;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 == 15 && cnt <= 3) begin
					ker[cnt] <= pix_out1;
					for(i=4;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 > 0 && mem_addr-1 < 3 && cnt <= 5) begin
					ker[cnt] <= pix_out1;
					for(i=6;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 > 12 && mem_addr-1 < 15 && cnt <= 5) begin
					ker[cnt] <= pix_out1;
					for(i=6;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if((mem_addr-1)%4 == 0 && cnt <= 5) begin
					ker[cnt] <= pix_out1;
					for(i=6;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if((mem_addr)%4 == 0 && cnt <= 5) begin
					ker[cnt] <= pix_out1;
					for(i=6;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(cnt <= 8) begin
					ker[cnt] <= pix_out1;
				end
			end
			else if(size == 8 && switch == 1) begin
				if(mem_addr-1 == 0 && cnt <= 3 && cnt != 0) begin
					ker[cnt] <= pix_out1;
					for(i=4;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 == 7 && cnt <= 3) begin
					ker[cnt] <= pix_out1;
					for(i=4;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 == 56 && cnt <= 3) begin
					ker[cnt] <= pix_out1;
					for(i=4;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 == 63 && cnt <= 3) begin
					ker[cnt] <= pix_out1;
					for(i=4;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 > 0 && mem_addr-1 < 7 && cnt <= 5) begin
					ker[cnt] <= pix_out1;
					for(i=6;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 > 56 && mem_addr-1 < 63 && cnt <= 5) begin
					ker[cnt] <= pix_out1;
					for(i=6;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if((mem_addr-1)%8 == 0 && cnt <= 5) begin
					ker[cnt] <= pix_out1;
					for(i=6;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if((mem_addr)%8 == 0 && cnt <= 5) begin
					ker[cnt] <= pix_out1;
					for(i=6;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(cnt <= 8) begin
					ker[cnt] <= pix_out1;
				end
			end
			else if(size == 16 && switch == 1) begin
				if(mem_addr-1 == 0 && cnt <= 3) begin
					ker[cnt] <= pix_out1;
					for(i=4;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 == 15 && cnt <= 3) begin
					ker[cnt] <= pix_out1;
					for(i=4;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 == 240 && cnt <= 3) begin
					ker[cnt] <= pix_out1;
					for(i=4;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 == 255 && cnt <= 3) begin
					ker[cnt] <= pix_out1;
					for(i=4;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 > 0 && mem_addr-1 < 15 && cnt <= 5) begin
					ker[cnt] <= pix_out1;
					for(i=6;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(mem_addr-1 > 240 && mem_addr-1 < 255 && cnt <= 5) begin
					ker[cnt] <= pix_out1;
					for(i=6;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if((mem_addr-1)%16 == 0 && cnt <= 5) begin
					ker[cnt] <= pix_out1;
					for(i=6;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if((mem_addr)%16 == 0 && cnt <= 5) begin
					ker[cnt] <= pix_out1;
					for(i=6;i<9;i=i+1) begin
						ker[i] <= 0;
					end
				end
				else if(cnt <= 8) begin
					ker[cnt] <= pix_out1;
				end
			end
		end
		else if(act[act_idx] == 1) begin
			if(switch == 0) begin
				ker[cnt] <= pix_out;
			end
			else begin
				ker[cnt] <= pix_out1;
			end
		end
		else if(act[act_idx] == 3) begin
			if(switch == 0) begin
				if(pix_out[15] == 1) begin
					ker[0] <= {pix_out[15], (pix_out[14:0]>>1)}+16'b0100000000000000+50;
				end
				else begin
					ker[0] <= {pix_out[15], (pix_out[14:0]>>1)}+50;
				end
			end
			else begin
				if(pix_out1[15] == 1) begin
					ker[0] <= {pix_out1[15], (pix_out1[14:0]>>1)}+16'b0100000000000000+50;
				end
				else begin
					ker[0] <= {pix_out1[15], (pix_out1[14:0]>>1)}+50;
				end
			end
		
		end

		if(flag[act_idx] == 1) begin
			for(i=0;i<9;i=i+1) begin
				ker[i] <= 0;
			end
		end
		
	end
	else if(state ==RESET) begin
		for(i=0;i<9;i=i+1) begin
			ker[i] <= 0;
		end
	end
end


//Action index counter 
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		act_idx <= 0;
	end

	else if(state == RESET) begin
		act_idx <= 0;
	end

	else if(state == PROCESS) begin
		if(flag[act_idx] == 1) begin
			act_idx <= act_idx+1;
		end
		else begin
			act_idx <= act_idx;
		end

	end

	else begin
		act_idx <= act_idx;
	end
end



//Done
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		done <= 0;
	end

	else if(state == RESET) begin
		done <= 0;
	end

	else if(state == PROCESS) begin
		if(act[act_idx] == 0) begin
			if(size == 4 && mem_addr == 17) begin
				done <= 1;
			end

			else if(size == 8 && mem_addr == 65) begin
				done <= 1;
			end

			else if(size == 16 && mem_addr == 257) begin
				done <= 1;
			end
			else begin
				done <= 0;
			end
		end
		else begin
			done <= 0;
		end

	end

	else begin
		done <= 0;
	end
end


//flag
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for (i=0;i<8;i=i+1) begin
			flag[i] <= 0;
		end
	end
	else if(state == PROCESS) begin
		if(act[act_idx] == 1 && switch == 0) begin
			if(size == 4) begin
				flag[act_idx] <= 1;
			end
			else if(size == 8 && addr == 15 && w_en == 0) begin
				flag[act_idx] <= 1;
			end
			else if(size == 16 && addr == 63 && w_en == 0) begin
				flag[act_idx] <= 1;
			end
			
		end	
		else if(act[act_idx] == 2 && switch == 0) begin
			if(size == 4 && mem_addr == 0 && w_en == 0) begin
				flag[act_idx] <= 1;
			end
			else if(size == 8 && mem_addr == 0 && w_en == 0) begin////////////////////////////////////////////////////////////////////////////////
				flag[act_idx] <= 1;
			end
			else if(size == 16 && mem_addr == 0 && w_en == 0) begin
				flag[act_idx] <= 1;
			end
			
		end		
		else if(act[act_idx] == 3 && switch == 0) begin
			if(size == 4 && mem_addr == 18 && w_en1 == 1) begin
				flag[act_idx] <= 1;
			end
			else if(size == 8 && mem_addr == 66 && w_en1 == 1) begin
				flag[act_idx] <= 1;
			end
			else if(size == 16 && mem_addr == 258 && w_en1 == 1) begin
				flag[act_idx] <= 1;
			end
			
		end	
		else if(act[act_idx] == 1 && switch == 1) begin
			if(size == 4) begin
				flag[act_idx] <= 1;
			end
			else if(size == 8 && addr1 == 15 && w_en1 == 0) begin
				flag[act_idx] <= 1;
			end
			else if(size == 16 && addr1 == 63 && w_en1 == 0) begin
				flag[act_idx] <= 1;
			end
			
		end	
		else if(act[act_idx] == 2 && switch == 1) begin
			if(size == 4 && mem_addr == 0 && w_en1 == 0) begin
				flag[act_idx] <= 1;
			end
			else if(size == 8 && mem_addr == 0 && w_en1 == 0) begin////////////////////////////////////////////////////////////////////////////////
				flag[act_idx] <= 1;
			end
			else if(size == 16 && mem_addr == 0 && w_en1 == 0) begin
				flag[act_idx] <= 1;
			end
			
		end		
		else if(act[act_idx] == 3 && switch == 1) begin
			if(size == 4 && mem_addr == 18 && w_en == 1) begin
				flag[act_idx] <= 1;
			end
			else if(size == 8 && mem_addr == 66 && w_en == 1) begin
				flag[act_idx] <= 1;
			end
			else if(size == 16 && mem_addr == 258 && w_en == 1) begin
				flag[act_idx] <= 1;
			end
			
		end	
		else begin
			for (i=0;i<8;i=i+1) begin
				flag[i] <= 0;
			end
		end
	end
end


//ker_out_pos
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0;i<9;i=i+1) begin
			ker_out_pos[i] <= 0;
		end
	end

	else if(state == RESET) begin
		for(i=0;i<9;i=i+1) begin
			ker_out_pos[i] <= 0;
		end
	end

	else if(state == PROCESS && act[act_idx] == 0) begin
		if(size == 4) begin
			if(out_max_pos == 0) begin
				ker_out_pos[0] <= out_max_pos;
				ker_out_pos[1] <= out_max_pos+1;
				ker_out_pos[2] <= out_max_pos+4;
				ker_out_pos[3] <= out_max_pos+5;
				ker_out_pos[4] <= 0;
				ker_out_pos[5] <= 0;
				ker_out_pos[6] <= 0;
				ker_out_pos[7] <= 0;
				ker_out_pos[8] <= 0;
			end
			else if(out_max_pos == 3) begin
				ker_out_pos[0] <= out_max_pos-1;
				ker_out_pos[1] <= out_max_pos;
				ker_out_pos[2] <= out_max_pos+3;
				ker_out_pos[3] <= out_max_pos+4;
				ker_out_pos[4] <= 0;
				ker_out_pos[5] <= 0;
				ker_out_pos[6] <= 0;
				ker_out_pos[7] <= 0;
				ker_out_pos[8] <= 0;
			end
			else if(out_max_pos == 12) begin
				ker_out_pos[0] <= out_max_pos-4;
				ker_out_pos[1] <= out_max_pos-3;
				ker_out_pos[2] <= out_max_pos;
				ker_out_pos[3] <= out_max_pos+1;
				ker_out_pos[4] <= 0;
				ker_out_pos[5] <= 0;
				ker_out_pos[6] <= 0;
				ker_out_pos[7] <= 0;
				ker_out_pos[8] <= 0;
			end
			else if(out_max_pos == 15) begin
				ker_out_pos[0] <= out_max_pos-5;
				ker_out_pos[1] <= out_max_pos-4;
				ker_out_pos[2] <= out_max_pos-1;
				ker_out_pos[3] <= out_max_pos;
				ker_out_pos[4] <= 0;
				ker_out_pos[5] <= 0;
				ker_out_pos[6] <= 0;
				ker_out_pos[7] <= 0;
				ker_out_pos[8] <= 0;
			end
			else if(out_max_pos > 0 && out_max_pos < 3) begin
				ker_out_pos[0] <= out_max_pos-1;
				ker_out_pos[1] <= out_max_pos;
				ker_out_pos[2] <= out_max_pos+1;
				ker_out_pos[3] <= out_max_pos+3;
				ker_out_pos[4] <= out_max_pos+4;
				ker_out_pos[5] <= out_max_pos+5;
				ker_out_pos[6] <= 0;
				ker_out_pos[7] <= 0;
				ker_out_pos[8] <= 0;
			end
			else if(out_max_pos > 12 && out_max_pos < 15) begin
				ker_out_pos[0] <= out_max_pos-5;
				ker_out_pos[1] <= out_max_pos-4;
				ker_out_pos[2] <= out_max_pos-3;
				ker_out_pos[3] <= out_max_pos-1;
				ker_out_pos[4] <= out_max_pos;
				ker_out_pos[5] <= out_max_pos+1;
				ker_out_pos[6] <= 0;
				ker_out_pos[7] <= 0;
				ker_out_pos[8] <= 0;
			end
			else if(out_max_pos%4 == 0) begin
				ker_out_pos[0] <= out_max_pos-4;
				ker_out_pos[1] <= out_max_pos-3;
				ker_out_pos[2] <= out_max_pos;
				ker_out_pos[3] <= out_max_pos+1;
				ker_out_pos[4] <= out_max_pos+4;
				ker_out_pos[5] <= out_max_pos+5;
				ker_out_pos[6] <= 0;
				ker_out_pos[7] <= 0;
				ker_out_pos[8] <= 0;
			end
			else if((out_max_pos+1)%4 == 0) begin
				ker_out_pos[0] <= out_max_pos-5;
				ker_out_pos[1] <= out_max_pos-4;
				ker_out_pos[2] <= out_max_pos-1;
				ker_out_pos[3] <= out_max_pos;
				ker_out_pos[4] <= out_max_pos+3;
				ker_out_pos[5] <= out_max_pos+4;
				ker_out_pos[6] <= 0;
				ker_out_pos[7] <= 0;
				ker_out_pos[8] <= 0;
			end
			else begin
				ker_out_pos[0] <= out_max_pos-5;
				ker_out_pos[1] <= out_max_pos-4;
				ker_out_pos[2] <= out_max_pos-3;
				ker_out_pos[3] <= out_max_pos-1;
				ker_out_pos[4] <= out_max_pos;
				ker_out_pos[5] <= out_max_pos+1;
				ker_out_pos[6] <= out_max_pos+3;
				ker_out_pos[7] <= out_max_pos+4;
				ker_out_pos[8] <= out_max_pos+5;
			end
		end
		else if(size == 8) begin
			if(out_max_pos == 0) begin
				ker_out_pos[0] <= out_max_pos;
				ker_out_pos[1] <= out_max_pos+1;
				ker_out_pos[2] <= out_max_pos+8;
				ker_out_pos[3] <= out_max_pos+9;
				ker_out_pos[4] <= 0;
				ker_out_pos[5] <= 0;
				ker_out_pos[6] <= 0;
				ker_out_pos[7] <= 0;
				ker_out_pos[8] <= 0;
			end
			else if(out_max_pos == 7) begin
				ker_out_pos[0] <= out_max_pos-1;
				ker_out_pos[1] <= out_max_pos;
				ker_out_pos[2] <= out_max_pos+7;
				ker_out_pos[3] <= out_max_pos+8;
				ker_out_pos[4] <= 0;
				ker_out_pos[5] <= 0;
				ker_out_pos[6] <= 0;
				ker_out_pos[7] <= 0;
				ker_out_pos[8] <= 0;
			end
			else if(out_max_pos == 56) begin
				ker_out_pos[0] <= out_max_pos-8;
				ker_out_pos[1] <= out_max_pos-7;
				ker_out_pos[2] <= out_max_pos;
				ker_out_pos[3] <= out_max_pos+1;
				ker_out_pos[4] <= 0;
				ker_out_pos[5] <= 0;
				ker_out_pos[6] <= 0;
				ker_out_pos[7] <= 0;
				ker_out_pos[8] <= 0;
			end
			else if(out_max_pos == 63) begin
				ker_out_pos[0] <= out_max_pos-9;
				ker_out_pos[1] <= out_max_pos-8;
				ker_out_pos[2] <= out_max_pos-1;
				ker_out_pos[3] <= out_max_pos;
				ker_out_pos[4] <= 0;
				ker_out_pos[5] <= 0;
				ker_out_pos[6] <= 0;
				ker_out_pos[7] <= 0;
				ker_out_pos[8] <= 0;
			end
			else if(out_max_pos > 0 && out_max_pos < 7) begin
				ker_out_pos[0] <= out_max_pos-1;
				ker_out_pos[1] <= out_max_pos;
				ker_out_pos[2] <= out_max_pos+1;
				ker_out_pos[3] <= out_max_pos+7;
				ker_out_pos[4] <= out_max_pos+8;
				ker_out_pos[5] <= out_max_pos+9;
				ker_out_pos[6] <= 0;
				ker_out_pos[7] <= 0;
				ker_out_pos[8] <= 0;
			end
			else if(out_max_pos > 56 && out_max_pos < 63) begin
				ker_out_pos[0] <= out_max_pos-9;
				ker_out_pos[1] <= out_max_pos-8;
				ker_out_pos[2] <= out_max_pos-7;
				ker_out_pos[3] <= out_max_pos-1;
				ker_out_pos[4] <= out_max_pos;
				ker_out_pos[5] <= out_max_pos+1;
				ker_out_pos[6] <= 0;
				ker_out_pos[7] <= 0;
				ker_out_pos[8] <= 0;
			end
			else if(out_max_pos%8 == 0) begin
				ker_out_pos[0] <= out_max_pos-8;
				ker_out_pos[1] <= out_max_pos-7;
				ker_out_pos[2] <= out_max_pos;
				ker_out_pos[3] <= out_max_pos+1;
				ker_out_pos[4] <= out_max_pos+8;
				ker_out_pos[5] <= out_max_pos+9;
			end
			else if((out_max_pos+1)%8 == 0) begin
				ker_out_pos[0] <= out_max_pos-9;
				ker_out_pos[1] <= out_max_pos-8;
				ker_out_pos[2] <= out_max_pos-1;
				ker_out_pos[3] <= out_max_pos;
				ker_out_pos[4] <= out_max_pos+7;
				ker_out_pos[5] <= out_max_pos+8;
				ker_out_pos[6] <= 0;
				ker_out_pos[7] <= 0;
				ker_out_pos[8] <= 0;
			end
			else begin
				ker_out_pos[0] <= out_max_pos-9;
				ker_out_pos[1] <= out_max_pos-8;
				ker_out_pos[2] <= out_max_pos-7;
				ker_out_pos[3] <= out_max_pos-1;
				ker_out_pos[4] <= out_max_pos;
				ker_out_pos[5] <= out_max_pos+1;
				ker_out_pos[6] <= out_max_pos+7;
				ker_out_pos[7] <= out_max_pos+8;
				ker_out_pos[8] <= out_max_pos+9;
			end
		end
		else if(size == 16) begin
			if(out_max_pos == 0) begin
				ker_out_pos[0] <= out_max_pos;
				ker_out_pos[1] <= out_max_pos+1;
				ker_out_pos[2] <= out_max_pos+16;
				ker_out_pos[3] <= out_max_pos+17;
				ker_out_pos[4] <= 0;
				ker_out_pos[5] <= 0;
				ker_out_pos[6] <= 0;
				ker_out_pos[7] <= 0;
				ker_out_pos[8] <= 0;
			end
			else if(out_max_pos == 3) begin
				ker_out_pos[0] <= out_max_pos-1;
				ker_out_pos[1] <= out_max_pos;
				ker_out_pos[2] <= out_max_pos+15;
				ker_out_pos[3] <= out_max_pos+16;
				ker_out_pos[4] <= 0;
				ker_out_pos[5] <= 0;
				ker_out_pos[6] <= 0;
				ker_out_pos[7] <= 0;
				ker_out_pos[8] <= 0;
			end
			else if(out_max_pos == 12) begin
				ker_out_pos[0] <= out_max_pos-16;
				ker_out_pos[1] <= out_max_pos-15;
				ker_out_pos[2] <= out_max_pos;
				ker_out_pos[3] <= out_max_pos+1;
				ker_out_pos[4] <= 0;
				ker_out_pos[5] <= 0;
				ker_out_pos[6] <= 0;
				ker_out_pos[7] <= 0;
				ker_out_pos[8] <= 0;
			end
			else if(out_max_pos == 15) begin
				ker_out_pos[0] <= out_max_pos-17;
				ker_out_pos[1] <= out_max_pos-16;
				ker_out_pos[2] <= out_max_pos-1;
				ker_out_pos[3] <= out_max_pos;
				ker_out_pos[4] <= 0;
				ker_out_pos[5] <= 0;
				ker_out_pos[6] <= 0;
				ker_out_pos[7] <= 0;
				ker_out_pos[8] <= 0;
			end
			else if(out_max_pos > 0 && out_max_pos < 15) begin
				ker_out_pos[0] <= out_max_pos-1;
				ker_out_pos[1] <= out_max_pos;
				ker_out_pos[2] <= out_max_pos+1;
				ker_out_pos[3] <= out_max_pos+15;
				ker_out_pos[4] <= out_max_pos+16;
				ker_out_pos[5] <= out_max_pos+17;
				ker_out_pos[6] <= 0;
				ker_out_pos[7] <= 0;
				ker_out_pos[8] <= 0;
			end
			else if(out_max_pos > 240 && out_max_pos < 255) begin
				ker_out_pos[0] <= out_max_pos-17;
				ker_out_pos[1] <= out_max_pos-16;
				ker_out_pos[2] <= out_max_pos-15;
				ker_out_pos[3] <= out_max_pos-1;
				ker_out_pos[4] <= out_max_pos;
				ker_out_pos[5] <= out_max_pos+1;
				ker_out_pos[6] <= 0;
				ker_out_pos[7] <= 0;
				ker_out_pos[8] <= 0;
			end
			else if(out_max_pos%16 == 0) begin
				ker_out_pos[0] <= out_max_pos-16;
				ker_out_pos[1] <= out_max_pos-15;
				ker_out_pos[2] <= out_max_pos;
				ker_out_pos[3] <= out_max_pos+1;
				ker_out_pos[4] <= out_max_pos+16;
				ker_out_pos[5] <= out_max_pos+17;
				ker_out_pos[6] <= 0;
				ker_out_pos[7] <= 0;
				ker_out_pos[8] <= 0;
			end
			else if((out_max_pos+1)%16 == 0) begin
				ker_out_pos[0] <= out_max_pos-17;
				ker_out_pos[1] <= out_max_pos-16;
				ker_out_pos[2] <= out_max_pos-1;
				ker_out_pos[3] <= out_max_pos;
				ker_out_pos[4] <= out_max_pos+15;
				ker_out_pos[5] <= out_max_pos+16;
				ker_out_pos[6] <= 0;
				ker_out_pos[7] <= 0;
				ker_out_pos[8] <= 0;
			end
			else begin
				ker_out_pos[0] <= out_max_pos-17;
				ker_out_pos[1] <= out_max_pos-16;
				ker_out_pos[2] <= out_max_pos-15;
				ker_out_pos[3] <= out_max_pos-1;
				ker_out_pos[4] <= out_max_pos;
				ker_out_pos[5] <= out_max_pos+1;
				ker_out_pos[6] <= out_max_pos+15;
				ker_out_pos[7] <= out_max_pos+16;
				ker_out_pos[8] <= out_max_pos+17;
			end
		end

	end
end

//Count out
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_out <= 0;
	end

	else if(state == RESET) begin
		cnt_out <= 0;
	end

	else if(n_state == OUTPUT) begin
		if(size == 4) begin
			if(cnt_out <16) begin
				cnt_out <= cnt_out+1;
			end
			else begin
				cnt_out <= cnt_out;
			end
		end
		else if(size == 8) begin
			if(cnt_out <64) begin
				cnt_out <= cnt_out+1;
			end
			else begin
				cnt_out <= cnt_out;
			end
		end
		else if(size == 16) begin
			if(cnt_out <256) begin
				cnt_out <= cnt_out+1;
			end
			else begin
				cnt_out <= cnt_out;
			end
		end
	end
end


// Output Assignment
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_valid   <= 0;
		out_x       <= 0;
		out_y       <= 0;
		out_img_pos <= 0;
		out_value   <= 0;
	end
	else if(n_state == OUTPUT) begin 
		if(size == 4) begin
			if(cnt_out < 16) begin
				out_valid   <= 1;
			end
			else begin
				out_valid   <= 0;
			end
			if(cnt_out < 16) begin
				out_value   <= out[cnt_out];
			end
			else begin
				out_value <= 0;
			end
			if(out_max_pos%4 == 0 && cnt_out < 16) begin
				out_y <= 0;
				out_x <= out_max_pos/4;
			end
			else if((out_max_pos-1)%4 == 0 && cnt_out < 16) begin
				out_y <= 1;
				out_x <= out_max_pos/4;
			end
			else if((out_max_pos-2)%4 == 0 && cnt_out < 16) begin
				out_y <= 2;
				out_x <= out_max_pos/4;
			end
			else if((out_max_pos-3)%4 == 0 && cnt_out < 16) begin
				out_y <= 3;
				out_x <= out_max_pos/4;
			end
			else begin
				out_x       <= 0;
				out_y       <= 0;
			end
			if(out_max_pos == 0) begin
				if(cnt_out < 9) begin
					out_img_pos <= ker_out_pos[cnt_out];
				end
				else begin
					out_img_pos <= 0;
				end
			end
			else if(out_max_pos == 3) begin
				if(cnt_out < 9) begin
					out_img_pos <= ker_out_pos[cnt_out];
				end
				else begin
					out_img_pos <= 0;
				end
			end
			else if(out_max_pos == 12) begin
				if(cnt_out < 9) begin
					out_img_pos <= ker_out_pos[cnt_out];
				end
				else begin
					out_img_pos <= 0;
				end
			end
			else if(out_max_pos == 15) begin
				if(cnt_out < 9) begin
					out_img_pos <= ker_out_pos[cnt_out];
				end
				else begin
					out_img_pos <= 0;
				end
			end
			else if(out_max_pos > 0 && out_max_pos < 3) begin
				if(cnt_out < 9) begin
					out_img_pos <= ker_out_pos[cnt_out];
				end
				else begin
					out_img_pos <= 0;
				end
			end
			else if(out_max_pos > 12 && out_max_pos < 15) begin
				if(cnt_out < 9) begin
					out_img_pos <= ker_out_pos[cnt_out];
				end
				else begin
					out_img_pos <= 0;
				end
			end
			else if(out_max_pos%4 == 0) begin
				if(cnt_out < 9) begin
					out_img_pos <= ker_out_pos[cnt_out];
				end
				else begin
					out_img_pos <= 0;
				end
			end
			else if((out_max_pos-1)%4 == 0) begin
				if(cnt_out < 9) begin
					out_img_pos <= ker_out_pos[cnt_out];
				end
				else begin
					out_img_pos <= 0;
				end
			end
			else begin
				if(cnt_out < 9) begin
					out_img_pos <= ker_out_pos[cnt_out];
				end
				else begin
					out_img_pos <= 0;
				end
			end
		end
		





		else if(size == 8) begin
			if(cnt_out < 64) begin
				out_valid   <= 1;
			end
			else begin
				out_valid   <= 0;
			end
			if(cnt_out < 64) begin
				out_value   <= out[cnt_out];
			end
			else begin
				out_value <= 0;
			end
			if(out_max_pos%8 == 0 && cnt_out < 64) begin
				out_y <= 0;
				out_x <= out_max_pos/8;
			end
			else if((out_max_pos-1)%8 == 0 && cnt_out < 64) begin
				out_y <= 1;
				out_x <= out_max_pos/8;
			end
			else if((out_max_pos-2)%8 == 0 && cnt_out < 64) begin
				out_y <= 2;
				out_x <= out_max_pos/8;
			end
			else if((out_max_pos-3)%8 == 0 && cnt_out < 64) begin
				out_y <= 3;
				out_x <= out_max_pos/8;
			end
			else if((out_max_pos-4)%8 == 0 && cnt_out < 64) begin
				out_y <= 4;
				out_x <= out_max_pos/8;
			end
			else if((out_max_pos-5)%8 == 0 && cnt_out < 64) begin
				out_y <= 5;
				out_x <= out_max_pos/8;
			end
			else if((out_max_pos-6)%8 == 0 && cnt_out < 64) begin
				out_y <= 6;
				out_x <= out_max_pos/8;
			end
			else if((out_max_pos-7)%8 == 0 && cnt_out < 64) begin
				out_y <= 7;
				out_x <= out_max_pos/8;
			end
			else begin
				out_x       <= 0;
				out_y       <= 0;
			end
			if(out_max_pos == 0) begin
				if(cnt_out < 9) begin
					out_img_pos <= ker_out_pos[cnt_out];
				end
				else begin
					out_img_pos <= 0;
				end
			end
			else if(out_max_pos == 7) begin
				if(cnt_out < 9) begin
					out_img_pos <= ker_out_pos[cnt_out];
				end
				else begin
					out_img_pos <= 0;
				end
			end
			else if(out_max_pos == 56) begin
				if(cnt_out < 9) begin
					out_img_pos <= ker_out_pos[cnt_out];
				end
				else begin
					out_img_pos <= 0;
				end
			end
			else if(out_max_pos == 63) begin
				if(cnt_out < 9) begin
					out_img_pos <= ker_out_pos[cnt_out];
				end
				else begin
					out_img_pos <= 0;
				end
			end
			else if(out_max_pos > 0 && out_max_pos < 7) begin
				if(cnt_out < 9) begin
					out_img_pos <= ker_out_pos[cnt_out];
				end
				else begin
					out_img_pos <= 0;
				end
			end
			else if(out_max_pos > 56 && out_max_pos < 63) begin
				if(cnt_out < 9) begin
					out_img_pos <= ker_out_pos[cnt_out];
				end
				else begin
					out_img_pos <= 0;
				end
			end
			else if(out_max_pos%8 == 0) begin
				if(cnt_out < 9) begin
					out_img_pos <= ker_out_pos[cnt_out];
				end
				else begin
					out_img_pos <= 0;
				end
			end
			else if((out_max_pos-1)%8 == 0) begin
				if(cnt_out < 9) begin
					out_img_pos <= ker_out_pos[cnt_out];
				end
				else begin
					out_img_pos <= 0;
				end
			end
			else begin
				if(cnt_out < 9) begin
					out_img_pos <= ker_out_pos[cnt_out];
				end
				else begin
					out_img_pos <= 0;
				end
			end
		end








		else if(size == 16) begin
			if(cnt_out < 256) begin
				out_valid   <= 1;
			end
			else begin
				out_valid   <= 0;
			end
			if(cnt_out < 256) begin
				out_value   <= out[cnt_out];
			end
			else begin
				out_value <= 0;
			end
			
			if(out_max_pos%16 == 0 && cnt_out < 256) begin
				out_y <= 0;
				out_x <= out_max_pos/16;
			end
			else if((out_max_pos-1)%16 == 0 && cnt_out < 256) begin
				out_y <= 1;
				out_x <= out_max_pos/16;
			end
			else if((out_max_pos-2)%16 == 0 && cnt_out < 256) begin
				out_y <= 2;
				out_x <= out_max_pos/16;
			end
			else if((out_max_pos-3)%16 == 0 && cnt_out < 256) begin
				out_y <= 3;
				out_x <= out_max_pos/16;
			end
			else if((out_max_pos-4)%16 == 0 && cnt_out < 256) begin
				out_y <= 4;
				out_x <= out_max_pos/16;
			end
			else if((out_max_pos-5)%16 == 0 && cnt_out < 256) begin
				out_y <= 5;
				out_x <= out_max_pos/16;
			end
			else if((out_max_pos-6)%16 == 0 && cnt_out < 256) begin
				out_y <= 6;
				out_x <= out_max_pos/16;
			end
			else if((out_max_pos-7)%16 == 0 && cnt_out < 256) begin
				out_y <= 7;
				out_x <= out_max_pos/16;
			end
			else if((out_max_pos-8)%16 == 0 && cnt_out < 256) begin
				out_y <= 8;
				out_x <= out_max_pos/16;
			end
			else if((out_max_pos-9)%16 == 0 && cnt_out < 256) begin
				out_y <= 9;
				out_x <= out_max_pos/16;
			end
			else if((out_max_pos-10)%16 == 0 && cnt_out < 256) begin
				out_y <= 10;
				out_x <= out_max_pos/16;
			end
			else if((out_max_pos-11)%16 == 0 && cnt_out < 256) begin
				out_y <= 11;
				out_x <= out_max_pos/16;
			end
			else if((out_max_pos-12)%16 == 0 && cnt_out < 256) begin
				out_y <= 12;
				out_x <= out_max_pos/16;
			end
			else if((out_max_pos-13)%16 == 0 && cnt_out < 256) begin
				out_y <= 13;
				out_x <= out_max_pos/16;
			end
			else if((out_max_pos-14)%16 == 0 && cnt_out < 256) begin
				out_y <= 14;
				out_x <= out_max_pos/16;
			end
			else if((out_max_pos-15)%16 == 0 && cnt_out < 256) begin
				out_y <= 15;
				out_x <= out_max_pos/16;
			end
			else begin
				out_x       <= 0;
				out_y       <= 0;
			end
			if(out_max_pos == 0) begin
				if(cnt_out < 9) begin
					out_img_pos <= ker_out_pos[cnt_out];
				end
				else begin
					out_img_pos <= 0;
				end
			end
			else if(out_max_pos == 15) begin
				if(cnt_out < 9) begin
					out_img_pos <= ker_out_pos[cnt_out];
				end
				else begin
					out_img_pos <= 0;
				end
			end
			else if(out_max_pos == 240) begin
				if(cnt_out < 9) begin
					out_img_pos <= ker_out_pos[cnt_out];
				end
				else begin
					out_img_pos <= 0;
				end
			end
			else if(out_max_pos == 256) begin
				if(cnt_out < 9) begin
					out_img_pos <= ker_out_pos[cnt_out];
				end
				else begin
					out_img_pos <= 0;
				end
			end
			else if(out_max_pos > 0 && out_max_pos < 15) begin
				if(cnt_out < 9) begin
					out_img_pos <= ker_out_pos[cnt_out];
				end
				else begin
					out_img_pos <= 0;
				end
			end
			else if(out_max_pos > 240 && out_max_pos < 256) begin
				if(cnt_out < 9) begin
					out_img_pos <= ker_out_pos[cnt_out];
				end
				else begin
					out_img_pos <= 0;
				end
			end
			else if(out_max_pos%16 == 0) begin
				if(cnt_out < 9) begin
					out_img_pos <= ker_out_pos[cnt_out];
				end
				else begin
					out_img_pos <= 0;
				end
			end
			else if((out_max_pos-1)%16 == 0) begin
				if(cnt_out < 9) begin
					out_img_pos <= ker_out_pos[cnt_out];
				end
				else begin
					out_img_pos <= 0;
				end
			end
			else begin
				if(cnt_out < 9) begin
					out_img_pos <= ker_out_pos[cnt_out];
				end
				else begin
					out_img_pos <= 0;
				end
			end
		end
	end 
	else begin
		out_valid   <= 0;
		out_x       <= 0;
		out_y       <= 0;
		out_img_pos <= 0;
		out_value   <= 0;
	end
end

endmodule