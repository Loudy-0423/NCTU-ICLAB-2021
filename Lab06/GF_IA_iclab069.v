//synopsys translate_off
`include "GF2k.v"
//synopsys translate_on

module GF_IA (
input in_valid,
input [4:0] in_data,
input [2:0] deg,
input [5:0] poly,
input rst_n,
input clk,
output reg [4:0] out_data,
output reg out_valid
);

// =========================================
// Input Register
// =========================================
parameter RESET  = 'd0;
parameter IN  = 'd1;
parameter IP_CAL  = 'd2;
parameter OUT  = 'd3;
integer i, j;

reg [1:0] n_state, state;

reg [4:0] data [3:0];
reg [2:0] deg_reg;
reg [5:0] poly_reg;
reg [3:0] cnt;

// =========================================
// Finite State Machine
// =========================================

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
            n_state = (rst_n)? IN : RESET;
        end

		IN: begin
            n_state = (in_valid == 0 && cnt != 0)? IP_CAL : IN;
        end

        IP_CAL: begin
            n_state = (out_valid == 1)? OUT : IP_CAL;
        end

        OUT: begin
            n_state = (out_valid == 0)? RESET : OUT;
        end
		
        default: begin
            n_state = state;
        end
    
    endcase
end 
// =========================================
// Input data
// =========================================

//Input assignment
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		for(i=0; i<4; i=i+1) begin
            data[i] <= 0;
        end
	end
	else if(n_state == RESET)begin
		for(i=0; i<4; i=i+1) begin
            data[i] <= 0;
        end
	end
    else if(n_state == IN)begin
		if(in_valid == 1) begin
            if(cnt<1) begin
                deg_reg <= deg;
                poly_reg <= poly;
            end
            data[cnt] <= in_data;
        end
	end
    else begin
        deg_reg <= deg_reg;
        poly_reg <= poly_reg;
    end
end

//Counter
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        cnt <= 0;
	end
	else if(in_valid == 1 || n_state >= 2) begin
		cnt <= cnt+1;
	end
    else if(n_state == RESET) begin
		cnt <= 0;
	end
	else begin
		cnt <= cnt;
	end
end
// =========================================
// Soft IP
// =========================================
wire [4:0] a0_mul_a3, a1_mul_a2, temp32_1, temp32_2, detA; 
wire [3:0] temp16_1, temp16_2;
wire [2:0] temp8_1, temp8_2;
wire [1:0] temp4_1, temp4_2;
wire [4:0] a0_div, a1_div, a2_div, a3_div;
wire [4:0] ele_out;

GF2k #(5, 2) u_gf_mul0(poly_reg, data[0], data[3], temp32_1);
GF2k #(5, 2) u_gf_mul1(poly_reg, data[1], data[2], temp32_2);
GF2k #(4, 2) u_gf_mul2(poly_reg[4:0], data[0][3:0], data[3][3:0], temp16_1);
GF2k #(4, 2) u_gf_mul3(poly_reg[4:0], data[1][3:0], data[2][3:0], temp16_2);
GF2k #(3, 2) u_gf_mul4(poly_reg[3:0], data[0][2:0], data[3][2:0], temp8_1);
GF2k #(3, 2) u_gf_mul5(poly_reg[3:0], data[1][2:0], data[2][2:0], temp8_2);
GF2k #(2, 2) u_gf_mul6(poly_reg[2:0], data[0][1:0], data[3][1:0], temp4_1);
GF2k #(2, 2) u_gf_mul7(poly_reg[2:0], data[1][1:0], data[2][1:0], temp4_2);

assign a0_mul_a3 = (deg_reg == 2)? {3'b000, temp4_1} : (deg_reg == 3)? {2'b00, temp8_1} : 
                   (deg_reg == 4)? {1'b0, temp16_1} : (deg_reg == 5)? temp32_1 : 0;
assign a1_mul_a2 = (deg_reg == 2)? {3'b000, temp4_2} : (deg_reg == 3)? {2'b00, temp8_2} : 
                   (deg_reg == 4)? {1'b0, temp16_2} : (deg_reg == 5)? temp32_2 : 0;

GF2k #(5, 1) u_gf_sub(poly_reg, a0_mul_a3, a1_mul_a2, detA);

GF2k #(5, 3) u_gf_div0(poly_reg, data[0], detA, a0_div);
GF2k #(5, 3) u_gf_div1(poly_reg, data[1], detA, a1_div);
GF2k #(5, 3) u_gf_div2(poly_reg, data[2], detA, a2_div);
GF2k #(5, 3) u_gf_div3(poly_reg, data[3], detA, a3_div);

assign ele_out = (cnt == 5)? a3_div : (cnt == 6)? a1_div : (cnt == 7)? a2_div : (cnt == 8)? a0_div : 0;

// =========================================
// Output Data
// =========================================

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_data <= 0;
        out_valid <= 0;
    end
    else if (cnt >= 5 && cnt <= 8) begin
	    out_data <= ele_out;
        out_valid <= 1;
    end
    else begin
        out_data <= 0;
        out_valid <= 0;
    end
end
endmodule