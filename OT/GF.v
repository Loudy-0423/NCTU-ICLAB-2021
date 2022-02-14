module GF (  
    clk,
    rst_n,
    in_valid,
    in_x,
    in_y,
    out_valid,
    out_x,
    out_y,
    out_area);
	
input             clk,rst_n,in_valid;
input      [9:0]  in_x,in_y;
output reg [9:0]  out_x,out_y;
output reg [24:0] out_area;
output reg        out_valid;


// =========================================
// Input Register
// =========================================
parameter RESET  = 'd0;
parameter IN  = 'd1;
parameter CAL  = 'd2;
parameter OUT  = 'd3;
integer i, j;

reg [1:0] n_state, state;
reg [9:0] datax [0:5];
reg [9:0] datay [0:5];
reg [2:0] cnt;
reg [4:0] cnt2;
wire signed [10:0] v1x, v2x, v3x, v4x, v5x;
wire signed [10:0] v1y, v2y, v3y, v4y, v5y;

wire signed [21:0] c_p [0:3];
//wire [9:0] tempx, temp;
wire [9:0] x1,x2,x3,x4,x5;
wire [9:0] y1,y2,y3,y4,y5;

wire [24:0] area;
reg [24:0] area_temp;


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
            n_state = (in_valid == 0 && cnt != 0)? CAL : IN;
        end

        CAL: begin
            n_state = (out_valid == 1)? OUT : CAL;
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
		for(i=0; i<6; i=i+1) begin
            datax[i] <= 0;
			datay[i] <= 0;
        end
	end
	else if(n_state == RESET)begin
		for(i=0; i<6; i=i+1) begin
            datax[i] <= 0;
			datay[i] <= 0;
        end
	end
    else if(n_state == IN)begin
		if(in_valid == 1) begin
            datax[cnt] <= in_x;
			datay[cnt] <= in_y;
        end
	end
	else if(n_state == CAL)begin
		if(c_p[0] > 0 && (cnt2 == 0||cnt2 == 4||cnt2 == 7||cnt2 == 9))begin
			for(i=0; i<6; i=i+1) begin
				datax[i] <= datax[i];
				datay[i] <= datay[i];
			end
		end
		else if(c_p[0] < 0 && (cnt2 == 0||cnt2 == 4||cnt2 == 7||cnt2 == 9))begin
			datax[1] <= datax[2];
			datay[1] <= datay[2];
			datax[2] <= datax[1];
			datay[2] <= datay[1];
			
			datax[3] <= datax[3];
			datay[3] <= datay[3];
			datax[4] <= datax[4];
			datay[4] <= datay[4];
			datax[5] <= datax[5];
			datay[5] <= datay[5];
		end
		
		else if(c_p[1] > 0 && (cnt2 == 1||cnt2 == 5||cnt2 == 8))begin
			for(i=0; i<6; i=i+1) begin
				datax[i] <= datax[i];
				datay[i] <= datay[i];
			end
		end
		else if(c_p[1] < 0 && (cnt2 == 1||cnt2 == 5||cnt2 == 8))begin
			datax[2] <= datax[3];
			datay[2] <= datay[3];
			datax[3] <= datax[2];
			datay[3] <= datay[2];
			
			datax[1] <= datax[1];
			datay[1] <= datay[1];
			datax[4] <= datax[4];
			datay[4] <= datay[4];
			datax[5] <= datax[5];
			datay[5] <= datay[5];
		end
		
		else if(c_p[2] > 0 && (cnt2 == 2||cnt2 == 6))begin
			for(i=0; i<6; i=i+1) begin
				datax[i] <= datax[i];
				datay[i] <= datay[i];
			end
		end
		else if(c_p[2] < 0 && (cnt2 == 2||cnt2 == 6))begin
			datax[3] <= datax[4];
			datay[3] <= datay[4];
			datax[4] <= datax[3];
			datay[4] <= datay[3];
			
			datax[1] <= datax[1];
			datay[1] <= datay[1];
			datax[2] <= datax[2];
			datay[2] <= datay[2];
			datax[5] <= datax[5];
			datay[5] <= datay[5];
		end
		
		else if(c_p[3] > 0 && cnt2 == 3)begin
			for(i=0; i<6; i=i+1) begin
				datax[i] <= datax[i];
				datay[i] <= datay[i];
			end
		end
		else if(c_p[3] < 0 && cnt2 == 3)begin
			datax[4] <= datax[5];
			datay[4] <= datay[5];
			datax[5] <= datax[4];
			datay[5] <= datay[4];
			
			datax[1] <= datax[1];
			datay[1] <= datay[1];
			datax[2] <= datax[2];
			datay[2] <= datay[2];
			datax[3] <= datax[3];
			datay[3] <= datay[3];
		end
	end
    else begin
        for(i=0; i<6; i=i+1) begin
            datax[i] <= datax[i];
			datay[i] <= datay[i];
        end
    end
end


assign area = (cnt2 == 11)? (((datax[0]*datay[1]-datax[1]*datay[0])+(datax[1]*datay[2]-datax[2]*datay[1])+(datax[2]*datay[3]-datax[3]*datay[2])+
							(datax[3]*datay[4]-datax[4]*datay[3])+(datax[4]*datay[5]-datax[5]*datay[4])+(datax[5]*datay[0]-datax[0]*datay[5]))>>1) : 0;
							
							
							
							
							
always@(posedge clk or negedge rst_n)begin
	if(!rst_n) begin
		area_temp <= 0;
	end
	else if(cnt2 == 11) begin
		area_temp <= area;
	end
    else if(n_state == RESET) begin
		area_temp <= 0;
	end
	else begin
		area_temp <= area_temp;
	end
end


//Counter1
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        cnt <= 0;
	end
	else if(in_valid == 1) begin
		cnt <= cnt+1;
	end
    else if(n_state == RESET) begin
		cnt <= 0;
	end
	else begin
		cnt <= cnt;
	end
end
//Counter2
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        cnt2 <= 0;
	end
	else if(n_state == CAL) begin
		cnt2 <= cnt2+1;
	end
    else if(n_state == RESET) begin
		cnt2 <= 0;
	end
	else begin
		cnt2 <= cnt2;
	end
end



assign v1x = datax[1]-datax[0];
assign v2x = datax[2]-datax[0];
assign v3x = datax[3]-datax[0];
assign v4x = datax[4]-datax[0];
assign v5x = datax[5]-datax[0];
	
assign v1y = datay[1]-datay[0];
assign v2y = datay[2]-datay[0];
assign v3y = datay[3]-datay[0];
assign v4y = datay[4]-datay[0];
assign v5y = datay[5]-datay[0];

assign c_p[0] = v1x*v2y-v2x*v1y;
assign c_p[1] = v2x*v3y-v3x*v2y;
assign c_p[2] = v3x*v4y-v4x*v3y;
assign c_p[3] = v4x*v5y-v5x*v4y;

reg [2:0] cnt_out;
//Counter out
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        cnt_out <= 0;
	end
	else if(cnt2 >= 12) begin
		cnt_out <= cnt_out+1;
	end
    else if(n_state == RESET) begin
		cnt_out <= 0;
	end
	else begin
		cnt_out <= cnt_out;
	end
end



// =========================================
// Output Data
// =========================================

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_x <= 0;
		out_y <= 0;
		out_area <= 0;
        out_valid <= 0;
    end
    else if (cnt2 >= 12 && cnt_out <= 5) begin
	    out_x <= datax[cnt_out];
		out_y <= datay[cnt_out];
		out_area <= area_temp;
        out_valid <= 1;
    end
    else begin
        out_x <= 0;
		out_y <= 0;
		out_area <= 0;
        out_valid <= 0;
    end
end


endmodule

