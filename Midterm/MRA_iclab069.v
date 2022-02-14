//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NYCU ED430
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2021 Fall
//   Midterm Proejct            : MRA  
//   Author                     : Lin-Hung, Lai
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : MRA.v
//   Module Name : MRA
//   Release version : V1.0 (Release Date: 2021-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module MRA(
	// CHIP IO
	clk            ,	
	rst_n          ,	
	in_valid       ,	
	frame_id       ,	
	net_id         ,	  
	loc_x          ,	  
    loc_y          ,
	cost	 	   ,		
	busy           ,

    // AXI4 IO
	     arid_m_inf,
	   araddr_m_inf,
	    arlen_m_inf,
	   arsize_m_inf,
	  arburst_m_inf,
	  arvalid_m_inf,
	  arready_m_inf,
	
	      rid_m_inf,
	    rdata_m_inf,
	    rresp_m_inf,
	    rlast_m_inf,
	   rvalid_m_inf,
	   rready_m_inf,
	
	     awid_m_inf,
	   awaddr_m_inf,
	   awsize_m_inf,
	  awburst_m_inf,
	    awlen_m_inf,
	  awvalid_m_inf,
	  awready_m_inf,
	
	    wdata_m_inf,
	    wlast_m_inf,
	   wvalid_m_inf,
	   wready_m_inf,
	
	      bid_m_inf,
	    bresp_m_inf,
	   bvalid_m_inf,
	   bready_m_inf 
);
// ===============================================================
//  					Parameter Declaration 
// ===============================================================
parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32;    // DO NOT modify AXI4 Parameter
parameter NUM_ROW = 64, NUM_COLUMN = 64; 				
parameter MAX_NUM_MACRO = 15;


// ===============================================================
//  					Input / Output 
// ===============================================================

// << CHIP io port with system >>
input 			  	clk,rst_n;
input 			   	in_valid;
input  [4:0] 		frame_id;
input  [3:0]       	net_id;     
input  [5:0]       	loc_x; 
input  [5:0]       	loc_y; 
output reg [13:0] 	cost;
output reg          busy;       
  
// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
       Your AXI-4 interface could be designed as a bridge in submodule,
	   therefore I declared output of AXI as wire.  
	   Ex: AXI4_interface AXI4_INF(...);
*/

// ------------------------
// <<<<< AXI READ >>>>>
// ------------------------
// (1)	axi read address channel 
output wire [ID_WIDTH-1:0]      arid_m_inf;///////
output wire [1:0]            arburst_m_inf;///////
output wire [2:0]             arsize_m_inf;///////
output wire [7:0]              arlen_m_inf;
output wire                  arvalid_m_inf;
input  wire                  arready_m_inf;
output wire [ADDR_WIDTH-1:0]  araddr_m_inf;
// ------------------------
// (2)	axi read data channel 
input  wire [ID_WIDTH-1:0]       rid_m_inf;
input  wire                   rvalid_m_inf;
output wire                   rready_m_inf;
input  wire [DATA_WIDTH-1:0]   rdata_m_inf;
input  wire                    rlast_m_inf;
input  wire [1:0]              rresp_m_inf;
// ------------------------
// <<<<< AXI WRITE >>>>>
// ------------------------
// (1) 	axi write address channel 
output wire [ID_WIDTH-1:0]      awid_m_inf;///////
output wire [1:0]            awburst_m_inf;///////
output wire [2:0]             awsize_m_inf;///////
output wire [7:0]              awlen_m_inf;
output wire                  awvalid_m_inf;
input  wire                  awready_m_inf;
output wire [ADDR_WIDTH-1:0]  awaddr_m_inf;
// -------------------------
// (2)	axi write data channel 
output wire                   wvalid_m_inf;
input  wire                   wready_m_inf;
output wire [DATA_WIDTH-1:0]   wdata_m_inf;
output wire                    wlast_m_inf;
// -------------------------
// (3)	axi write response channel 
input  wire  [ID_WIDTH-1:0]      bid_m_inf;
input  wire                   bvalid_m_inf;
output wire                   bready_m_inf;
input  wire  [1:0]             bresp_m_inf;
// -----------------------------


// ===============================================================
//  					Variable Declare
// ===============================================================
parameter RESET    = 'd0;
parameter IN       = 'd1;
parameter READ     = 'd2;
parameter FILL     = 'd3;
parameter CNT_DOWN = 'd4;
parameter RETRACE  = 'd5;
parameter REMAP    = 'd6;
parameter OUT      = 'd7;

reg [3:0] n_state, curr_state;
reg [12:0] index;
wire [DATA_WIDTH-1:0] dram_read_out ,dram_read_in;
// ===============================================================
// ===============================================================
reg [3:0] map [0:NUM_ROW-1][0:NUM_COLUMN-1];
reg [3:0] map_temp [0:NUM_ROW-1][0:NUM_COLUMN-1];

reg [4:0] frame_id_reg;
reg [3:0] net_id_reg [15:1];
reg [5:0] x_reg [30:1];
reg [5:0] y_reg [30:1];
reg [4:0] cnt;
reg [5:0] x_dir, y_dir;
reg read_flag;
reg done_F, done_R;


integer i, j ,k;


reg [2:0] cnt_2;
reg [4:0] cnt_32;
reg flag;
wire [3:0] D_out;
wire [3:0] D_in;
wire [11:0] A;
reg [4:0] cnt_num;

reg [2:0] cnt_1;
reg [1:0] cnt_123;
reg [6:0] cnt_x, cnt_y;
reg fill_flag;
reg [5:0] now_x, now_y;
reg [6:0] origx [4:1], origy [4:1];



// ===============================================================
//  					Finite State Machine
// ===============================================================
//FSM current state assignment
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		curr_state <= RESET;
	end
	else begin
		curr_state <= n_state;
	end
end

//FSM next state assignment
always@(*) begin
    case(curr_state)
        RESET: begin
            n_state = (rst_n && in_valid == 1)? IN : RESET;
        end
		IN: begin
            n_state = (in_valid == 0 && cnt != 0)? READ : IN;
        end
		READ: begin
            n_state = (x_dir == 63 && y_dir == 63 )? FILL : READ;
        end
        FILL: begin
            n_state = (done_F == 1)? CNT_DOWN : FILL;
        end
		CNT_DOWN: begin
            n_state = RETRACE;
        end
		RETRACE: begin
            n_state = (done_R == 1 && cnt_num == 1)? OUT : (done_R == 1)? REMAP : RETRACE;
        end
		REMAP: begin
            n_state = FILL;
        end
        OUT: begin
            //n_state = (busy == 0)? RESET : OUT;
			n_state = (x_dir == 63 && y_dir == 63)? RESET : OUT;
        end
        default: begin
            n_state = curr_state;
        end
    endcase
end 

// ===============================================================
//  					Input Register
// ===============================================================
//frame/net id number
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		frame_id_reg <= 0;
		for(i=1; i<16; i=i+1) begin
			net_id_reg[i] <= 0;
		end
	end
	else if(n_state == RESET)begin
		frame_id_reg <= 0;
		for(i=1; i<16; i=i+1) begin
			net_id_reg[i] <= 0;
		end
	end
    else if(n_state == IN)begin
		frame_id_reg <= frame_id;
		if(cnt%2 == 0) begin
			net_id_reg[cnt/2+1] <= net_id;
		end
		
	end
    else begin
        frame_id_reg <= frame_id_reg;
		for(i=1; i<16; i=i+1) begin
			net_id_reg[i] <= net_id_reg[i];
		end
    end
end
//source/sink location
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		for(i=1; i<31; i=i+1) begin
			x_reg[i] <= 0;
			y_reg[i] <= 0;	
		end
	end
	else if(n_state == RESET)begin
		for(i=1; i<31; i=i+1) begin
			x_reg[i] <= 0;
			y_reg[i] <= 0;	
		end
	end
    else if(n_state == IN)begin
		x_reg[cnt+1] <= loc_x;
		y_reg[cnt+1] <= loc_y;
	end
    else begin
        for(i=1; i<31; i=i+1) begin
			x_reg[i] <= x_reg[i];
			y_reg[i] <= y_reg[i];	
		end
    end
end

//Counter for source/sink location
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        cnt <= 0;
	end
	else if(n_state == IN) begin
		cnt <= cnt+1;
	end
    else if(n_state == RESET) begin
		cnt <= 0;
	end
	else begin
		cnt <= cnt;
	end
end

//map x/y index
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        x_dir <= 0;
		y_dir <= 0;
	end
	else if(n_state == READ && flag == 1) begin
		if(x_dir == 63) begin
			x_dir <= 0;
			y_dir <= y_dir+1;
		end
		else begin
			x_dir <= x_dir+1;
			y_dir <= y_dir;
		end
	end
	else if(n_state == FILL) begin
		x_dir <= 0;
		y_dir <= 0;
	end
	else if(n_state == OUT && flag == 1) begin
		if(x_dir == 63) begin
			x_dir <= 0;
			y_dir <= y_dir+1;
		end
		else begin
			x_dir <= x_dir+1;
			y_dir <= y_dir;
		end
	end
    else if(n_state == RESET) begin
		x_dir <= 0;
		y_dir <= 0;
	end
	else begin
		x_dir <= x_dir;
		y_dir <= y_dir;
	end
end

//memory counter flag
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		flag <= 0;
	end
	else if(curr_state == READ) begin
		if(rlast_m_inf == 1) begin
			flag <= 1;
		end
		else if(cnt_32 == 31) begin
			flag <= 0;
		end
		else begin
			flag <= flag;
		end
	end
    else if(curr_state == RESET) begin
		flag <= 0;
	end
end


//memory counter
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_32 <= 0;
	end
	else if(curr_state == READ && flag == 1) begin
		if(flag == 1) begin
			cnt_32 <= cnt_32+1;
		end
		else begin
			cnt_32 <= 0;
		end

	end
	else if(n_state == REMAP) begin
		cnt_32 <= 0;
	end
    else if(curr_state == RESET) begin
		cnt_32 <= 0;
	end
end

assign D_out = (cnt_32 == 0)? dram_read_out[3:0]      : (cnt_32 == 1)? dram_read_out[7:4]      : (cnt_32== 2)? dram_read_out[11:8]      : (cnt_32 == 3)? dram_read_out[15:12]    :
		   	   (cnt_32 == 4)? dram_read_out[19:16]    : (cnt_32 == 5)? dram_read_out[23:20]    : (cnt_32 == 6)? dram_read_out[27:24]    : (cnt_32 == 7)? dram_read_out[31:28]    :
		       (cnt_32 == 8)? dram_read_out[35:32]    : (cnt_32 == 9)? dram_read_out[39:36]    : (cnt_32 == 10)? dram_read_out[43:40]   : (cnt_32 == 11)? dram_read_out[47:44]   :
		       (cnt_32 == 12)? dram_read_out[51:48]   : (cnt_32 == 13)? dram_read_out[55:52]   : (cnt_32 == 14)? dram_read_out[59:56]   : (cnt_32 == 15)? dram_read_out[63:60]   :
		       (cnt_32 == 16)? dram_read_out[67:64]   : (cnt_32 == 17)? dram_read_out[71:68]   : (cnt_32 == 18)? dram_read_out[75:72]   : (cnt_32 == 19)? dram_read_out[79:76]   :
		       (cnt_32 == 20)? dram_read_out[83:80]   : (cnt_32 == 21)? dram_read_out[87:84]   : (cnt_32 == 22)? dram_read_out[91:88]   : (cnt_32 == 23)? dram_read_out[95:92]   :
		       (cnt_32 == 24)? dram_read_out[99:96]   : (cnt_32 == 25)? dram_read_out[103:100] : (cnt_32 == 26)? dram_read_out[107:104] : (cnt_32 == 27)? dram_read_out[111:108] :
		       (cnt_32 == 28)? dram_read_out[115:112] : (cnt_32 == 29)? dram_read_out[119:116] : (cnt_32 == 30)? dram_read_out[123:120] : (cnt_32 == 31)? dram_read_out[127:124] : 0;

		   
//Map memory
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        for(i=0; i<64; i=i+1) begin
			for(j=0; j<64; j=j+1) begin
				map[i][j] <= 0;
			end	
		end
	end
	else if(n_state == READ) begin
		map[y_dir][x_dir] <= D_out;
	end
	else if(n_state == RETRACE) begin
		map[now_y][now_x] <= net_id_reg[((29-cnt_num)>>1)];
	end
    else if(n_state == RESET) begin
		for(i=0; i<64; i=i+1) begin
			for(j=0; j<64; j=j+1) begin
				map[i][j] <= 0;
			end	
		end
	end
end

// ===============================================================
//  					SRAM 
// ===============================================================
wire c_en;
wire o_en;
wire w_en;
wire [3:0] Q;

assign c_en = 0;
assign o_en = 0;
assign w_en = (n_state == READ || (n_state == FILL && (x_dir == 63 && y_dir == 63 )))? flag : 0;
assign A = (curr_state == READ)? ((araddr_m_inf[11:0]-16)<<1)+cnt_32 : 0;

Mid_SRAM MAP1( .Q(Q), .CLK(clk), .CEN(c_en), .WEN(!w_en), .A(A), .D(D_out), .OEN(o_en) );

// ===============================================================
//  					Data Register
// ===============================================================





//Map memory temp
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        for(i=0; i<64; i=i+1) begin
			for(j=0; j<64; j=j+1) begin
				map_temp[i][j] <= 0;
			end	
		end
	end
	else if(n_state == READ) begin
		if(D_out != 0) begin
			map_temp[y_dir][x_dir] <= 4;
		end
		else begin
			map_temp[y_dir][x_dir] <= 0;
		end
	end
	else if(n_state == FILL) begin
		if(cnt_1 == 0) begin
			if(map_temp[y_reg[30-cnt_num]+1][x_reg[30-cnt_num]] == 0) begin
				map_temp[y_reg[30-cnt_num]+1][x_reg[30-cnt_num]] <= 1;
			end
			if(map_temp[y_reg[30-cnt_num]][x_reg[30-cnt_num]+1] == 0) begin
				map_temp[y_reg[30-cnt_num]][x_reg[30-cnt_num]+1] <= 1;
			end
			if(map_temp[y_reg[30-cnt_num]-1][x_reg[30-cnt_num]] == 0) begin
				map_temp[y_reg[30-cnt_num]-1][x_reg[30-cnt_num]] <= 1;
			end
			if(map_temp[y_reg[30-cnt_num]][x_reg[30-cnt_num]-1] == 0) begin
				map_temp[y_reg[30-cnt_num]][x_reg[30-cnt_num]-1] <= 1;
			end
		end
		else if(cnt_1 == 1) begin
			if(map_temp[y_reg[30-cnt_num]+1][x_reg[30-cnt_num]] == 1) begin
				if(map_temp[y_reg[30-cnt_num]+1+cnt_y][x_reg[30-cnt_num]+cnt_x] == 0) begin
					if(cnt_x == 0) begin
						if(map_temp[y_reg[30-cnt_num]+cnt_y][x_reg[30-cnt_num]+cnt_x] == 1) begin
							map_temp[y_reg[30-cnt_num]+1+cnt_y][x_reg[30-cnt_num]+cnt_x] <= 2;
						end
						else if(map_temp[y_reg[30-cnt_num]+cnt_y][x_reg[30-cnt_num]+cnt_x] == 2) begin
							map_temp[y_reg[30-cnt_num]+1+cnt_y][x_reg[30-cnt_num]+cnt_x] <= 3;
						end
						else if(map_temp[y_reg[30-cnt_num]+cnt_y][x_reg[30-cnt_num]+cnt_x] == 3) begin
							map_temp[y_reg[30-cnt_num]+1+cnt_y][x_reg[30-cnt_num]+cnt_x] <= 1;
						end
					end
					else begin
						if(map_temp[y_reg[30-cnt_num]+1+cnt_y][x_reg[30-cnt_num]+cnt_x-1] == 1) begin
							map_temp[y_reg[30-cnt_num]+1+cnt_y][x_reg[30-cnt_num]+cnt_x] <= 2;
						end
						else if(map_temp[y_reg[30-cnt_num]+1+cnt_y][x_reg[30-cnt_num]+cnt_x-1] == 2) begin
							map_temp[y_reg[30-cnt_num]+1+cnt_y][x_reg[30-cnt_num]+cnt_x] <= 3;
						end
						else if(map_temp[y_reg[30-cnt_num]+1+cnt_y][x_reg[30-cnt_num]+cnt_x-1] == 3) begin
							map_temp[y_reg[30-cnt_num]+1+cnt_y][x_reg[30-cnt_num]+cnt_x] <= 1;
						end
						else if(map_temp[y_reg[30-cnt_num]+cnt_y][x_reg[30-cnt_num]+cnt_x] == 1) begin
							map_temp[y_reg[30-cnt_num]+1+cnt_y][x_reg[30-cnt_num]+cnt_x] <= 2;
						end
						else if(map_temp[y_reg[30-cnt_num]+cnt_y][x_reg[30-cnt_num]+cnt_x] == 2) begin
							map_temp[y_reg[30-cnt_num]+1+cnt_y][x_reg[30-cnt_num]+cnt_x] <= 3;
						end
						else if(map_temp[y_reg[30-cnt_num]+cnt_y][x_reg[30-cnt_num]+cnt_x] == 3) begin
							map_temp[y_reg[30-cnt_num]+1+cnt_y][x_reg[30-cnt_num]+cnt_x] <= 1;
						end
					end
				end
			end
		end
		else if(cnt_1 == 2) begin
			if(map_temp[y_reg[30-cnt_num]+1][x_reg[30-cnt_num]] == 1) begin
				if(map_temp[y_reg[30-cnt_num]+1+cnt_y][x_reg[30-cnt_num]-cnt_x] == 0) begin
					if(cnt_x == 0) begin
						if(map_temp[y_reg[30-cnt_num]+cnt_y][x_reg[30-cnt_num]-cnt_x] == 1) begin
							map_temp[y_reg[30-cnt_num]+1+cnt_y][x_reg[30-cnt_num]-cnt_x] <= 2;
						end
						else if(map_temp[y_reg[30-cnt_num]+cnt_y][x_reg[30-cnt_num]-cnt_x] == 2) begin
							map_temp[y_reg[30-cnt_num]+1+cnt_y][x_reg[30-cnt_num]-cnt_x] <= 3;
						end
						else if(map_temp[y_reg[30-cnt_num]+cnt_y][x_reg[30-cnt_num]-cnt_x] == 3) begin
							map_temp[y_reg[30-cnt_num]+1+cnt_y][x_reg[30-cnt_num]-cnt_x] <= 1;
						end
					end
					else begin
						if(map_temp[y_reg[30-cnt_num]+1+cnt_y][x_reg[30-cnt_num]-cnt_x+1] == 1) begin
							map_temp[y_reg[30-cnt_num]+1+cnt_y][x_reg[30-cnt_num]-cnt_x] <= 2;
						end
						else if(map_temp[y_reg[30-cnt_num]+1+cnt_y][x_reg[30-cnt_num]-cnt_x+1] == 2) begin
							map_temp[y_reg[30-cnt_num]+1+cnt_y][x_reg[30-cnt_num]-cnt_x] <= 3;
						end
						else if(map_temp[y_reg[30-cnt_num]+1+cnt_y][x_reg[30-cnt_num]-cnt_x+1] == 3) begin
							map_temp[y_reg[30-cnt_num]+1+cnt_y][x_reg[30-cnt_num]-cnt_x] <= 1;
						end
						else if(map_temp[y_reg[30-cnt_num]+cnt_y][x_reg[30-cnt_num]-cnt_x] == 1) begin
							map_temp[y_reg[30-cnt_num]+1+cnt_y][x_reg[30-cnt_num]-cnt_x] <= 2;
						end
						else if(map_temp[y_reg[30-cnt_num]+cnt_y][x_reg[30-cnt_num]-cnt_x] == 2) begin
							map_temp[y_reg[30-cnt_num]+1+cnt_y][x_reg[30-cnt_num]-cnt_x] <= 3;
						end
						else if(map_temp[y_reg[30-cnt_num]+cnt_y][x_reg[30-cnt_num]-cnt_x] == 3) begin
							map_temp[y_reg[30-cnt_num]+1+cnt_y][x_reg[30-cnt_num]-cnt_x] <= 1;
						end
					end
				end
			end
		end	
		else if(cnt_1 == 3) begin
			if(map_temp[y_reg[30-cnt_num]+1][x_reg[30-cnt_num]] == 1) begin
				if(map_temp[y_reg[30-cnt_num]+1-cnt_y][x_reg[30-cnt_num]-cnt_x] == 0) begin
					if(cnt_x == 0) begin
						if(map_temp[y_reg[30-cnt_num]-cnt_y][x_reg[30-cnt_num]-cnt_x] == 1) begin
							map_temp[y_reg[30-cnt_num]-1-cnt_y][x_reg[30-cnt_num]-cnt_x] <= 2;
						end
						else if(map_temp[y_reg[30-cnt_num]-cnt_y][x_reg[30-cnt_num]-cnt_x] == 2) begin
							map_temp[y_reg[30-cnt_num]-1-cnt_y][x_reg[30-cnt_num]-cnt_x] <= 3;
						end
						else if(map_temp[y_reg[30-cnt_num]-cnt_y][x_reg[30-cnt_num]-cnt_x] == 3) begin
							map_temp[y_reg[30-cnt_num]-1-cnt_y][x_reg[30-cnt_num]-cnt_x] <= 1;
						end
					end
					else begin
						if(map_temp[y_reg[30-cnt_num]-cnt_y+1][x_reg[30-cnt_num]-cnt_x+1] == 1) begin
							map_temp[y_reg[30-cnt_num]-cnt_y+1][x_reg[30-cnt_num]-cnt_x] <= 2;
						end
						else if(map_temp[y_reg[30-cnt_num]-cnt_y+1][x_reg[30-cnt_num]-cnt_x+1] == 2) begin
							map_temp[y_reg[30-cnt_num]-cnt_y+1][x_reg[30-cnt_num]-cnt_x] <= 3;
						end
						else if(map_temp[y_reg[30-cnt_num]-cnt_y+1][x_reg[30-cnt_num]-cnt_x+1] == 3) begin
							map_temp[y_reg[30-cnt_num]-cnt_y+1][x_reg[30-cnt_num]-cnt_x] <= 1;
						end
						else if(map_temp[y_reg[30-cnt_num]-cnt_y+2][x_reg[30-cnt_num]-cnt_x] == 1) begin
							map_temp[y_reg[30-cnt_num]-cnt_y+1][x_reg[30-cnt_num]-cnt_x] <= 2;
						end
						else if(map_temp[y_reg[30-cnt_num]-cnt_y+2][x_reg[30-cnt_num]-cnt_x] == 2) begin
							map_temp[y_reg[30-cnt_num]-cnt_y+1][x_reg[30-cnt_num]-cnt_x] <= 3;
						end
						else if(map_temp[y_reg[30-cnt_num]-cnt_y+2][x_reg[30-cnt_num]-cnt_x] == 3) begin
							map_temp[y_reg[30-cnt_num]-cnt_y+1][x_reg[30-cnt_num]-cnt_x] <= 1;
						end
					end
				end
			end
		end
		else if(cnt_1 == 4) begin
			if(map_temp[y_reg[30-cnt_num]+1][x_reg[30-cnt_num]] == 1) begin
				if(map_temp[y_reg[30-cnt_num]-cnt_y][x_reg[30-cnt_num]+cnt_x] == 0) begin
					if(cnt_x == 0) begin
						if(map_temp[y_reg[30-cnt_num]-cnt_y][x_reg[30-cnt_num]+cnt_x-1] == 1) begin
							map_temp[y_reg[30-cnt_num]-cnt_y][x_reg[30-cnt_num]+cnt_x] <= 2;
						end
						else if(map_temp[y_reg[30-cnt_num]-cnt_y][x_reg[30-cnt_num]+cnt_x-1] == 2) begin
							map_temp[y_reg[30-cnt_num]-cnt_y][x_reg[30-cnt_num]+cnt_x] <= 3;
						end
						else if(map_temp[y_reg[30-cnt_num]-cnt_y][x_reg[30-cnt_num]+cnt_x-1] == 3) begin
							map_temp[y_reg[30-cnt_num]-cnt_y][x_reg[30-cnt_num]+cnt_x] <= 1;
						end
					end
					else begin
						if(map_temp[y_reg[30-cnt_num]-cnt_y][x_reg[30-cnt_num]+cnt_x-1] == 1) begin
							map_temp[y_reg[30-cnt_num]-cnt_y][x_reg[30-cnt_num]+cnt_x] <= 2;
						end
						else if(map_temp[y_reg[30-cnt_num]-cnt_y][x_reg[30-cnt_num]+cnt_x-1] == 2) begin
							map_temp[y_reg[30-cnt_num]-cnt_y][x_reg[30-cnt_num]+cnt_x] <= 3;
						end
						else if(map_temp[y_reg[30-cnt_num]-cnt_y][x_reg[30-cnt_num]+cnt_x-1] == 3) begin
							map_temp[y_reg[30-cnt_num]-cnt_y][x_reg[30-cnt_num]+cnt_x] <= 1;
						end
						else if(map_temp[y_reg[30-cnt_num]+1-cnt_y][x_reg[30-cnt_num]+cnt_x] == 1) begin
							map_temp[y_reg[30-cnt_num]-cnt_y][x_reg[30-cnt_num]+cnt_x] <= 2;
						end
						else if(map_temp[y_reg[30-cnt_num]+1-cnt_y][x_reg[30-cnt_num]+cnt_x] == 2) begin
							map_temp[y_reg[30-cnt_num]-cnt_y][x_reg[30-cnt_num]+cnt_x] <= 3;
						end
						else if(map_temp[y_reg[30-cnt_num]+1-cnt_y][x_reg[30-cnt_num]+cnt_x] == 3) begin
							map_temp[y_reg[30-cnt_num]-cnt_y][x_reg[30-cnt_num]+cnt_x] <= 1;
						end
					end
				end
			end
		end
	end

	else if(n_state == REMAP) begin
		for(i=0; i<64; i=i+1) begin
			for(j=0; j<64; j=j+1) begin
				if(map[i][j] != 0) begin
					map_temp[i][j] <= 4;
				end
				else begin
					map_temp[i][j] <= 0;
				end
			end
		end
		
	end

    else if(n_state == RESET) begin
		for(i=0; i<64; i=i+1) begin
			for(j=0; j<64; j=j+1) begin
				map_temp[i][j] <= 0;
			end	
		end
	end
end


always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        cnt_x <= 0;
		cnt_y <= 0;
	end
	else if(n_state == FILL) begin
		if(cnt_1 == 1)begin
				if(cnt_x == 63-x_reg[30-cnt_num]) begin
					cnt_x <= 0;
					if(cnt_y == 61-y_reg[30-cnt_num]) begin
						cnt_y <= 0;
					end
					else begin
						cnt_y <= cnt_y+1;
					end
				end
				else begin
					cnt_x <= cnt_x+1;
					cnt_y <= cnt_y;
				end
		end
		else if(cnt_1 == 2) begin
				if(cnt_x == x_reg[30-cnt_num]) begin
					cnt_x <= 0;
					if(cnt_y == 61-y_reg[30-cnt_num]) begin
						cnt_y <= 0;
					end
					else begin
						cnt_y <= cnt_y+1;
					end
				end
				else begin
					cnt_x <= cnt_x+1;
					cnt_y <= cnt_y;
				end
		end
		else if(cnt_1 == 3) begin
			
				if(cnt_x == x_reg[30-cnt_num]) begin
					cnt_x <= 0;
					if(cnt_y == y_reg[30-cnt_num]) begin
						cnt_y <= 0;
					end
					else begin
						cnt_y <= cnt_y+1;
					end
				end
				else begin
					cnt_x <= cnt_x+1;
					cnt_y <= cnt_y;
				end
			
		end
		else if(cnt_1 == 4) begin
				if(cnt_x == 63-x_reg[30-cnt_num]) begin
					cnt_x <= 0;
					if(cnt_y == y_reg[30-cnt_num]) begin
						cnt_y <= 0;
					end
					else begin
						cnt_y <= cnt_y+1;
					end
				end
				else begin
					cnt_x <= cnt_x+1;
					cnt_y <= cnt_y;
				end
		end
		else begin
			cnt_x <= 0;
			cnt_y <= 0;
		end
	end
	else if(n_state == REMAP) begin
		cnt_x <= 0;
		cnt_y <= 0;
	end
    else if(n_state == RESET) begin
		cnt_x <= 0;
		cnt_y <= 0;
	end
end

reg [1:0] now_num;



always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        now_x <= 0;
		now_y <= 0;
	end
	else if(n_state == CNT_DOWN) begin
		if(map[y_reg[30-cnt_num+1]-1][x_reg[30-cnt_num+1]] == 0) begin
			now_x <= x_reg[30-cnt_num+1];
			now_y <= y_reg[30-cnt_num+1]-1;
		end
		else if(map[y_reg[30-cnt_num+1]+1][x_reg[30-cnt_num+1]] == 0) begin
			now_x <= x_reg[30-cnt_num+1];
			now_y <= y_reg[30-cnt_num+1]+1;
		end
		else if(map[y_reg[30-cnt_num+1]][x_reg[30-cnt_num+1]+1] == 0) begin
			now_x <= x_reg[30-cnt_num+1]+1;
			now_y <= y_reg[30-cnt_num+1];
		end
		else if(map[y_reg[30-cnt_num+1]][x_reg[30-cnt_num+1]-1] == 0) begin
			now_x <= x_reg[30-cnt_num+1]-1;
			now_y <= y_reg[30-cnt_num+1];
		end
	end
	else if(n_state == RETRACE) begin
		if(now_x != x_reg[(((29-cnt_num)>>1)+1)] || now_y != y_reg[(((29-cnt_num)>>1)+1)]) begin
			if(now_num == 3) begin
				if(map_temp[now_y+1][now_x] == 2) begin
					now_x <= now_x;
					now_y <= now_y+1;
				end
				else if(map_temp[now_y-1][now_x] == 2) begin
					now_x <= now_x;
					now_y <= now_y-1;
				end
				else if(map_temp[now_y][now_x+1] == 2) begin
					now_x <= now_x+1;
					now_y <= now_y;
				end
				else if(map_temp[now_y][now_x-1] == 2) begin
					now_x <= now_x-1;
					now_y <= now_y;
				end
			end
			else if(now_num == 2) begin
				if(map_temp[now_y+1][now_x] == 1) begin
					now_x <= now_x;
					now_y <= now_y+1;
				end
				else if(map_temp[now_y-1][now_x] == 1) begin
					now_x <= now_x;
					now_y <= now_y-1;
				end
				else if(map_temp[now_y][now_x+1] == 1) begin
					now_x <= now_x+1;
					now_y <= now_y;
				end
				else if(map_temp[now_y][now_x-1] == 1) begin
					now_x <= now_x-1;
					now_y <= now_y;
				end
			end
			else if(now_num == 1) begin
				if(map_temp[now_y+1][now_x] == 3) begin
					now_x <= now_x;
					now_y <= now_y+1;
				end
				else if(map_temp[now_y-1][now_x] == 3) begin
					now_x <= now_x;
					now_y <= now_y-1;
				end
				else if(map_temp[now_y][now_x+1] == 3) begin
					now_x <= now_x+1;
					now_y <= now_y;
				end
				else if(map_temp[now_y][now_x-1] == 3) begin
					now_x <= now_x-1;
					now_y <= now_y;
				end
			end
		end
	end
	else if(n_state == REMAP) begin
		now_x <= 0;
		now_y <= 0;
	end
    else if(n_state == RESET) begin
		now_x <= 0;
		now_y <= 0;
	end
end



always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        now_num <= 0;
	end
	else if(n_state == RETRACE) begin
		if(map[now_y+1][now_x] == 0) begin
			now_num <= map_temp[now_y][now_x];	
		end
		else if(map[now_y-1][now_x] == 0) begin
			now_num <= map_temp[now_y][now_x];	
		end
		else if(map[now_y][now_x+1] == 0) begin
			now_num <= map_temp[now_y][now_x];	
		end
		else if(map[now_y][now_x-1] == 0) begin
			now_num <= map_temp[now_y][now_x];	
		end
	end
	else if(n_state == REMAP) begin
		now_num <= 0;
	end
    else if(n_state == RESET) begin
		now_num <= 0;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        cnt_1 <= 0;
	end
	else if(n_state == FILL) begin
			if(cnt_1 == 0) begin
				cnt_1 <= cnt_1+1;
			end
			else if(cnt_1 == 1) begin
				if(cnt_x == 63-x_reg[30-cnt_num] && cnt_y == 61-y_reg[30-cnt_num]) begin
					cnt_1 <= 2;
				end
				else begin
					cnt_1 <= 1;
				end
			end
			else if(cnt_1 == 2) begin
				if(cnt_x == x_reg[30-cnt_num] && cnt_y == 61-y_reg[30-cnt_num]) begin
					cnt_1 <= 3;
				end
				else begin
					cnt_1 <= 2;
				end
			end
			else if(cnt_1 == 3) begin
				if(cnt_x == x_reg[30-cnt_num] && cnt_y == y_reg[30-cnt_num]) begin
					cnt_1 <= 4;
				end
				else begin
					cnt_1 <= 3;
				end
			end
			else if(cnt_1 == 4) begin
				if(cnt_y == y_reg[30-cnt_num]) begin
					cnt_1 <= cnt_1+1;
				end
				else begin
					cnt_1 <= 4;
				end
				
			end
			else begin
				cnt_1 <= cnt_1+1;
			end
	end
	else if(n_state == REMAP) begin
		cnt_1 <= 0;
	end
    else if(n_state == RESET) begin
		cnt_1 <= 0;
	end
end


always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        done_F <= 0;
	end
	else if(n_state == FILL) begin
		if(map_temp[y_reg[31-cnt_num]+1][x_reg[31-cnt_num]] != 0 && map_temp[y_reg[31-cnt_num]][x_reg[31-cnt_num]+1] != 0 && map_temp[y_reg[31-cnt_num]-1][x_reg[31-cnt_num]] != 0 && map_temp[y_reg[31-cnt_num]][x_reg[31-cnt_num]-1] != 0) begin
			done_F <= 1;
		end
		else begin
			done_F <= 0;
		end
	end
	else if(n_state == RETRACE) begin
		done_F <= 0;
	end
    else if(n_state == RESET) begin
		done_F <= 0;
	end
end


always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        cnt_num <= 0;
	end
	else if(n_state == IN) begin
		cnt_num <= cnt;
	end
	else if(n_state == CNT_DOWN) begin
		cnt_num <= cnt_num-2;
	end
    else if(n_state == RESET) begin
		cnt_num <= 0;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        done_R <= 0;
	end
	else if(n_state == RETRACE) begin
		if((now_x == x_reg[((29-cnt_num)-1)]+1 && now_y == y_reg[((29-cnt_num)-1)]) || (now_x == x_reg[((29-cnt_num)-1)]-1 && now_y == y_reg[((29-cnt_num)-1)]) || (now_x == x_reg[((29-cnt_num)-1)] && now_y == y_reg[((29-cnt_num)-1)]+1) || (now_x == x_reg[((29-cnt_num)-1)] && now_y == y_reg[((29-cnt_num)-1)]-1)) begin
			done_R <= 1;
		end
		else begin
			done_R <= 0;
		end
	end
	else if(n_state == REMAP) begin
		done_R <= 0;
	end
    else if(n_state == RESET) begin
		done_R <= 0;
	end
end












// ===============================================================
//  					Output Register
// ===============================================================
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        busy <= 0;
        cost <= 0;
    end
    else if (n_state == READ || n_state == FILL || n_state == CNT_DOWN || n_state == RETRACE ||  n_state == REMAP || n_state == OUT) begin
	    busy <= 1;
        cost <= 0;
    end
    else begin
        busy <= 0;
        cost <= 0;
    end
end

// ===============================================================
//  					AXI4 Interfaces
// ===============================================================

// You can desing your own module here
AXI4_READ INF_AXI4_READ(
	.clk(clk),.rst_n(rst_n),.curr_state(curr_state),.index(index),.data_type(data_type) ,.frame_id_reg(frame_id_reg) ,.dram_read_out(dram_read_out),
	.arid_m_inf(arid_m_inf),
	.arburst_m_inf(arburst_m_inf), .arsize_m_inf(arsize_m_inf), .arlen_m_inf(arlen_m_inf), 
	.arvalid_m_inf(arvalid_m_inf), .arready_m_inf(arready_m_inf), .araddr_m_inf(araddr_m_inf),
	.rid_m_inf(rid_m_inf),
	.rvalid_m_inf(rvalid_m_inf), .rready_m_inf(rready_m_inf), .rdata_m_inf(rdata_m_inf),
	.rlast_m_inf(rlast_m_inf), .rresp_m_inf(rresp_m_inf)
);
// You can desing your own module here
AXI4_WRITE INF_AXI4_WRITE(
	.clk(clk),.rst_n(rst_n),.curr_state(curr_state),.index(index),.frame_id_reg(frame_id_reg) , .dram_read_in(dram_read_in),
	.awid_m_inf(awid_m_inf),
	.awburst_m_inf(awburst_m_inf), .awsize_m_inf(awsize_m_inf), .awlen_m_inf(awlen_m_inf),
	.awvalid_m_inf(awvalid_m_inf), .awready_m_inf(awready_m_inf), .awaddr_m_inf(awaddr_m_inf),
   	.wvalid_m_inf(wvalid_m_inf), .wready_m_inf(wready_m_inf),
	.wdata_m_inf(wdata_m_inf), .wlast_m_inf(wlast_m_inf),
    .bid_m_inf(bid_m_inf),
   	.bvalid_m_inf(bvalid_m_inf), .bready_m_inf(bready_m_inf), .bresp_m_inf(bresp_m_inf)
);


endmodule






























// ############################################################################
//  					AXI4 Interfaces Module
// ############################################################################
// =========================================
// Read Data from DRAM 
// =========================================
module AXI4_READ(
	clk,rst_n,curr_state, index, data_type, frame_id_reg, dram_read_out, 
	arid_m_inf,
	arburst_m_inf, arsize_m_inf, arlen_m_inf, 
	arvalid_m_inf, arready_m_inf, araddr_m_inf,
	rid_m_inf,
	rvalid_m_inf, rready_m_inf, rdata_m_inf,
	rlast_m_inf, rresp_m_inf
);
parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32;    // DO NOT modify


// (0)	CHIP IO
input clk,rst_n,data_type;
input [3:0] curr_state;
input [12:0] index;
input [4:0] frame_id_reg;
output reg [DATA_WIDTH-1:0] dram_read_out;


// ------------------------
// (1)	axi read address channel 
output wire [ID_WIDTH-1:0]      arid_m_inf;////////
output wire [1:0]            arburst_m_inf;////////
output wire [2:0]             arsize_m_inf;////////
output reg [7:0]               arlen_m_inf;////////
output reg                   arvalid_m_inf;////////
input  wire                  arready_m_inf;////////
output reg [ADDR_WIDTH-1:0]   araddr_m_inf;////////
// ------------------------
// (2)	axi read data channel 
input  wire [ID_WIDTH-1:0]       rid_m_inf;////////
input  wire                   rvalid_m_inf;////////
output wire                    rready_m_inf;////////
input  wire [DATA_WIDTH-1:0]   rdata_m_inf;////////
input  wire                    rlast_m_inf;////////
input  wire [1:0]              rresp_m_inf;////////
// ------------------------
//(3)   Parameter and reg/wire
parameter RESET    = 'd0;
parameter IN       = 'd1;
parameter READ     = 'd2;
parameter FILL     = 'd3;
parameter CNT_DOWN = 'd4;
parameter RETRACE  = 'd5;
parameter OUT      = 'd6;

reg [2:0] cnt;
reg [4:0] cnt_32;
wire c_en;
wire o_en;
wire [3:0] d_out;
wire [11:0] A;
wire [3:0] D;
reg flag;
wire [ADDR_WIDTH-1:0] araddr;
wire [ADDR_WIDTH-1:0] araddr_last;


// ***********************
// axi_master read_request
// ***********************

// << Burst & ID >>
assign arid_m_inf = 4'd0; 			// fixed id to 0 
assign arburst_m_inf = 2'd1;		// fixed mode to INCR mode 
assign arsize_m_inf = 3'b100;		// fixed size to 2^4 = 16 Bytes 

assign rready_m_inf = 1'd1;

// ***********************
// axi_master read_catch
// ***********************

assign araddr = (frame_id_reg == 0)? 'h10000 : (frame_id_reg == 1)? 'h10800 : (frame_id_reg == 2)? 'h11000 : (frame_id_reg == 3)? 'h11800 : (frame_id_reg == 4)? 'h12000 : (frame_id_reg == 5)? 'h12800 :
				(frame_id_reg == 6)? 'h13000 : (frame_id_reg == 7)? 'h13800 : (frame_id_reg == 8)? 'h14000 : (frame_id_reg == 9)? 'h14800 : (frame_id_reg == 10)? 'h15000 : (frame_id_reg == 11)? 'h15800 :
				(frame_id_reg == 12)? 'h16000 : (frame_id_reg == 13)? 'h16800 : (frame_id_reg == 14)? 'h17000 : (frame_id_reg == 15)? 'h17800 : (frame_id_reg == 16)? 'h18000 : (frame_id_reg == 17)? 'h18800 :
				(frame_id_reg == 18)? 'h19000 : (frame_id_reg == 19)? 'h19800 : (frame_id_reg == 20)? 'h1a000 : (frame_id_reg == 21)? 'h1a800 : (frame_id_reg == 22)? 'h1b000 : (frame_id_reg == 23)? 'h1b800 :
				(frame_id_reg == 24)? 'h1c000 : (frame_id_reg == 25)? 'h1c800 : (frame_id_reg == 26)? 'h1d000 : (frame_id_reg == 27)? 'h1d800 : (frame_id_reg == 28)? 'h1e000 : (frame_id_reg == 29)? 'h1e800 :
				(frame_id_reg == 30)? 'h1f000 : (frame_id_reg == 31)? 'h1f800 : 'h0;

assign araddr_last = (frame_id_reg == 0)? 'h10800 : (frame_id_reg == 1)? 'h11000 : (frame_id_reg == 2)? 'h11800 : (frame_id_reg == 3)? 'h12000 : (frame_id_reg == 4)? 'h12800 : (frame_id_reg == 5)? 'h13000 :
					 (frame_id_reg == 6)? 'h13800 : (frame_id_reg == 7)? 'h14000 : (frame_id_reg == 8)? 'h14800 : (frame_id_reg == 9)? 'h15000 : (frame_id_reg == 10)? 'h15800 : (frame_id_reg == 11)? 'h16000 :
					 (frame_id_reg == 12)? 'h16800 : (frame_id_reg == 13)? 'h17000 : (frame_id_reg == 14)? 'h17800 : (frame_id_reg == 15)? 'h18000 : (frame_id_reg == 16)? 'h18800 : (frame_id_reg == 17)? 'h19000 :
					 (frame_id_reg == 18)? 'h19800 : (frame_id_reg == 19)? 'h1a000 : (frame_id_reg == 20)? 'h1a800 : (frame_id_reg == 21)? 'h1b000 : (frame_id_reg == 22)? 'h1b800 : (frame_id_reg == 23)? 'h1c000 :
					 (frame_id_reg == 24)? 'h1c800 : (frame_id_reg == 25)? 'h1d000 : (frame_id_reg == 26)? 'h1d800 : (frame_id_reg == 27)? 'h1e000 : (frame_id_reg == 28)? 'h1e800 : (frame_id_reg == 29)? 'h1f000 :
					 (frame_id_reg == 30)? 'h1f800 : (frame_id_reg == 31)? 'h20000 : 'h0;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		araddr_m_inf <= 'h0;
	end
	else if(curr_state == IN) begin
		araddr_m_inf <= araddr;
	end
	else if(curr_state == READ) begin
		if(arready_m_inf) begin
			if(araddr_m_inf != araddr_last) begin
				araddr_m_inf <= araddr_m_inf+16;
			end
			else begin
				araddr_m_inf <= araddr_m_inf;
			end
		end
	end
    else if(curr_state == RESET) begin
		araddr_m_inf <= 'h0;
	end
	else begin
		araddr_m_inf <= 'h0;
	end
end



always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		arvalid_m_inf = 0;
	end
	else if(curr_state == READ) begin
		if(rlast_m_inf) begin
			arvalid_m_inf = 0;
		end
		else begin
			if(cnt == 2) begin
				arvalid_m_inf = 0;
			end
			else begin
				arvalid_m_inf = 1;
			end
		end
	end
    else if(curr_state == RESET) begin
		arvalid_m_inf = 0;
	end
	else begin
		arvalid_m_inf = 0;
	end
end



always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		dram_read_out <= 0;
	end
	else if(curr_state == READ) begin
		if(rvalid_m_inf) begin
			dram_read_out <= rdata_m_inf;
		end
	end
    else if(curr_state == RESET) begin
		dram_read_out <= 0;
	end
	else begin
		dram_read_out <= 0;
	end
end


always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		flag <= 0;
	end
	else if(curr_state == READ) begin
		if(rlast_m_inf == 1) begin
			flag <= 1;
		end
		else if(cnt_32 == 31) begin
			flag <= 0;
		end
		else begin
			flag <= flag;
		end
	end
    else if(curr_state == RESET) begin
		flag <= 0;
	end
end


always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt <= 0;
	end
	else if(curr_state == READ) begin
		if(cnt != 2) begin
			cnt <= cnt+1;
		end
		else begin
			if(cnt_32 == 31) begin
				cnt <= 0;
			end
			else begin
				cnt <= cnt;
			end
		end
	end
    else if(curr_state == RESET) begin
		cnt <= 0;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_32 <= 0;
	end
	else if(curr_state == READ) begin
		if(flag == 1 && cnt == 2) begin
			cnt_32 <= cnt_32+1;
		end
		else begin
			cnt_32 <= 0;
		end
	end
    else if(curr_state == RESET) begin
		cnt_32 <= 0;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		arlen_m_inf <= 0;
	end
	else if(curr_state == READ) begin
		arlen_m_inf <= 0;
	end
    else if(curr_state == RESET) begin
		arlen_m_inf <= 0;
	end
end

// ===============================================================
//  					SRAM 
// ===============================================================
/*
assign c_en = 0;
assign o_en = 0;
assign A = ((araddr_m_inf[11:0]-16)<<1)+cnt_32;
Mid_SRAM MAP1( .Q(d_out), .CLK(clk), .CEN(c_en), .WEN(!flag), .A(A), .D(D), .OEN(o_en) );

assign D = (cnt_32 == 0)? dram_read_out[3:0] : (cnt_32 == 1)? dram_read_out[7:4] : (cnt_32== 2)? dram_read_out[11:8] : (cnt_32 == 3)? dram_read_out[15:12] :
		   (cnt_32 == 4)? dram_read_out[19:16] : (cnt_32 == 5)? dram_read_out[23:20] : (cnt_32 == 6)? dram_read_out[27:24] : (cnt_32 == 7)? dram_read_out[31:28] :
		   (cnt_32 == 8)? dram_read_out[35:32] : (cnt_32 == 9)? dram_read_out[39:36] : (cnt_32 == 10)? dram_read_out[43:40] : (cnt_32 == 11)? dram_read_out[47:44] :
		   (cnt_32 == 12)? dram_read_out[51:48] : (cnt_32 == 13)? dram_read_out[55:52] : (cnt_32 == 14)? dram_read_out[59:56] : (cnt_32 == 15)? dram_read_out[63:60] :
		   (cnt_32 == 16)? dram_read_out[67:64] : (cnt_32 == 17)? dram_read_out[71:68] : (cnt_32 == 18)? dram_read_out[75:72] : (cnt_32 == 19)? dram_read_out[79:76] :
		   (cnt_32 == 20)? dram_read_out[83:80] : (cnt_32 == 21)? dram_read_out[87:84] : (cnt_32 == 22)? dram_read_out[91:88] : (cnt_32 == 23)? dram_read_out[95:92] :
		   (cnt_32 == 24)? dram_read_out[99:96] : (cnt_32 == 25)? dram_read_out[103:100] : (cnt_32 == 26)? dram_read_out[107:104] : (cnt_32 == 27)? dram_read_out[111:108] :
		   (cnt_32 == 28)? dram_read_out[115:112] : (cnt_32 == 29)? dram_read_out[119:116] : (cnt_32 == 30)? dram_read_out[123:120] : (cnt_32 == 31)? dram_read_out[127:124] : 
		   0;

*/



endmodule
























// =========================================
// Write Data to DRAM 
// =========================================
module AXI4_WRITE(
	clk,rst_n,curr_state, index, frame_id_reg, dram_read_in, 
	awid_m_inf,
	awburst_m_inf,awsize_m_inf,awlen_m_inf,
	awvalid_m_inf, awready_m_inf, awaddr_m_inf,
   	wvalid_m_inf,wready_m_inf,
	wdata_m_inf, wlast_m_inf,
    bid_m_inf,
   	bvalid_m_inf, bready_m_inf, bresp_m_inf
  
);
parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32;    // DO NOT modify

// (0)	CHIP IO
input clk,rst_n;
input [3:0] curr_state;
input [12:0] index;
input [4:0] frame_id_reg;
input [DATA_WIDTH-1:0] dram_read_in;
// ------------------------
// (1) 	axi write address channel 
output wire [ID_WIDTH-1:0]      awid_m_inf;////////
output wire [1:0]            awburst_m_inf;////////
output wire [2:0]             awsize_m_inf;////////
output reg [7:0]               awlen_m_inf;////////
output reg                   awvalid_m_inf;////////
input  wire                  awready_m_inf;////////
output reg [ADDR_WIDTH-1:0]   awaddr_m_inf;////////
// -------------------------

// (2)	axi write data channel 
output wire                    wvalid_m_inf;
input  wire                   wready_m_inf;////////
output reg [DATA_WIDTH-1:0]   wdata_m_inf;
output wire                     wlast_m_inf;
// -------------------------

// (3)	axi write response channel 
input  wire  [ID_WIDTH-1:0]      bid_m_inf;////////
input  wire                   bvalid_m_inf;////////
output reg                    bready_m_inf;
input  wire  [1:0]             bresp_m_inf;////////
// ------------------------
//(4) Parameter reg/wire
parameter RESET    = 'd0;
parameter IN       = 'd1;
parameter READ     = 'd2;
parameter FILL     = 'd3;
parameter CNT_DOWN = 'd4;
parameter RETRACE  = 'd5;
parameter OUT      = 'd6;

reg [2:0] cnt;




// *************************
// axi_master write request
// *************************

// << Burst & ID >>
assign awid_m_inf = 4'd0;
assign awburst_m_inf = 2'd1;
assign awsize_m_inf = 3'b100;


// *************************
// axi_master write send
// *************************
wire [ADDR_WIDTH-1:0] awaddr;
wire [ADDR_WIDTH-1:0] awaddr_last;

assign awaddr = (frame_id_reg == 0)? 'h10000 : (frame_id_reg == 1)? 'h10800 : (frame_id_reg == 2)? 'h11000 : (frame_id_reg == 3)? 'h11800 : (frame_id_reg == 4)? 'h12000 : (frame_id_reg == 5)? 'h12800 :
				(frame_id_reg == 6)? 'h13000 : (frame_id_reg == 7)? 'h13800 : (frame_id_reg == 8)? 'h14000 : (frame_id_reg == 9)? 'h14800 : (frame_id_reg == 10)? 'h15000 : (frame_id_reg == 11)? 'h15800 :
				(frame_id_reg == 12)? 'h16000 : (frame_id_reg == 13)? 'h16800 : (frame_id_reg == 14)? 'h17000 : (frame_id_reg == 15)? 'h17800 : (frame_id_reg == 16)? 'h18000 : (frame_id_reg == 17)? 'h18800 :
				(frame_id_reg == 18)? 'h19000 : (frame_id_reg == 19)? 'h19800 : (frame_id_reg == 20)? 'h1a000 : (frame_id_reg == 21)? 'h1a800 : (frame_id_reg == 22)? 'h1b000 : (frame_id_reg == 23)? 'h1b800 :
				(frame_id_reg == 24)? 'h1c000 : (frame_id_reg == 25)? 'h1c800 : (frame_id_reg == 26)? 'h1d000 : (frame_id_reg == 27)? 'h1d800 : (frame_id_reg == 28)? 'h1e000 : (frame_id_reg == 29)? 'h1e800 :
				(frame_id_reg == 30)? 'h1f000 : (frame_id_reg == 31)? 'h1f800 : 'h0;

assign awaddr_last = (frame_id_reg == 0)? 'h10800 : (frame_id_reg == 1)? 'h11000 : (frame_id_reg == 2)? 'h11800 : (frame_id_reg == 3)? 'h12000 : (frame_id_reg == 4)? 'h12800 : (frame_id_reg == 5)? 'h13000 :
					 (frame_id_reg == 6)? 'h13800 : (frame_id_reg == 7)? 'h14000 : (frame_id_reg == 8)? 'h14800 : (frame_id_reg == 9)? 'h15000 : (frame_id_reg == 10)? 'h15800 : (frame_id_reg == 11)? 'h16000 :
					 (frame_id_reg == 12)? 'h16800 : (frame_id_reg == 13)? 'h17000 : (frame_id_reg == 14)? 'h17800 : (frame_id_reg == 15)? 'h18000 : (frame_id_reg == 16)? 'h18800 : (frame_id_reg == 17)? 'h19000 :
					 (frame_id_reg == 18)? 'h19800 : (frame_id_reg == 19)? 'h1a000 : (frame_id_reg == 20)? 'h1a800 : (frame_id_reg == 21)? 'h1b000 : (frame_id_reg == 22)? 'h1b800 : (frame_id_reg == 23)? 'h1c000 :
					 (frame_id_reg == 24)? 'h1c800 : (frame_id_reg == 25)? 'h1d000 : (frame_id_reg == 26)? 'h1d800 : (frame_id_reg == 27)? 'h1e000 : (frame_id_reg == 28)? 'h1e800 : (frame_id_reg == 29)? 'h1f000 :
					 (frame_id_reg == 30)? 'h1f800 : (frame_id_reg == 31)? 'h20000 : 'h0;
					 
					 
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		awaddr_m_inf <= 'h0;
	end
	else if(curr_state == IN) begin
		awaddr_m_inf <= awaddr;
	end
	else if(curr_state == OUT) begin
		if(bvalid_m_inf) begin
			if(awaddr_m_inf != awaddr_last) begin
				awaddr_m_inf <= awaddr_m_inf+16;
			end
			else begin
				awaddr_m_inf <= awaddr_m_inf;
			end
		end
	end
    else if(curr_state == RESET) begin
		awaddr_m_inf <= 'h0;
	end
	else begin
		awaddr_m_inf <= awaddr_m_inf;
	end
end


always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		bready_m_inf = 0;
	end
	else if(curr_state == OUT) begin
		
		if(cnt == 2) begin
			bready_m_inf = 1;
		end
		else if(bvalid_m_inf) begin
			bready_m_inf = 0;
		end
	end
    else if(curr_state == RESET) begin
		bready_m_inf = 0;
	end
	else begin
		bready_m_inf = 0;
	end
end


always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		awvalid_m_inf = 0;
	end
	else if(curr_state == OUT) begin
		
		if(cnt == 2) begin
			awvalid_m_inf = 0;
		end
		else begin
			awvalid_m_inf = 1;
		end
	end
    else if(curr_state == RESET) begin
		awvalid_m_inf = 0;
	end
	else begin
		awvalid_m_inf = 0;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt <= 0;
	end
	else if(curr_state == OUT) begin
		if(cnt != 2) begin
			cnt <= cnt+1;
		end
		else if(bvalid_m_inf) begin
			cnt <= 0;
		end
		else begin
			cnt <= cnt;
		end
	end
    else if(curr_state == RESET) begin
		cnt <= 0;
	end
end

assign wlast_m_inf = (curr_state == OUT)? wready_m_inf : 0;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		awlen_m_inf <= 0;
	end
	else if(curr_state == OUT) begin
		awlen_m_inf <= 0;
	end
    else if(curr_state == RESET) begin
		awlen_m_inf <= 0;
	end
end

assign wvalid_m_inf = 1;


always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		wdata_m_inf <= 0;
	end
	else if(curr_state == OUT) begin
		if(wvalid_m_inf) begin
			wdata_m_inf <= dram_read_in;
		end
	end
    else if(curr_state == RESET) begin
		wdata_m_inf <= 0;
	end
	else begin
		wdata_m_inf <= 0;
	end
end

endmodule


