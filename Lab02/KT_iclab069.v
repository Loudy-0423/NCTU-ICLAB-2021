module KT(
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
    move_out
);

input clk,rst_n;
input in_valid;
input [2:0] in_x,in_y;
input [4:0] move_num;
input [2:0] priority_num;

output reg out_valid;
output reg [2:0] out_x,out_y;
output reg [4:0] move_out;


parameter IDLE     = 'd0;
parameter IN       = 'd1;
parameter WORK     = 'd2;
parameter OUT      = 'd3;

reg [2:0] n_state, state;
reg [4:0] cnt;

integer i, j, k;

reg [4:0] cnt_out;

reg [2:0] x_reg [24:0], y_reg [24:0];
reg [4:0] m_num, m_n;
reg [2:0] p_num, p_n;

reg [24:0] pass;

reg [2:0] tempx;
reg [2:0] tempy;


wire [2:0] p_reg;
wire signed [3:0] tx;
wire signed [3:0] ty;

wire [2:0] p_sub;
reg [7:0] check [24:0];
reg flag;

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
			n_state = (cnt != 0 && !in_valid)? WORK : IN;
        end
		WORK: begin
            n_state = (m_num == 25)? OUT : WORK;
        end
        OUT: begin
			n_state = (cnt_out == 25)? IDLE : OUT;
        end
        default: begin
            n_state = state;
        end
    endcase
end 

// ===============================================================
//  					Input Register
// ===============================================================

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		for(i=0; i<25; i=i+1) begin
			x_reg[i] <= 5;
			y_reg[i] <= 5;
		end
	end
	else begin
		if(n_state == IDLE) begin
			for(i=0; i<25; i=i+1) begin
				x_reg[i] <= 5;
				y_reg[i] <= 5;
			end
		end
		else if(n_state == IN) begin
			if(in_valid) begin
				x_reg[cnt] <= in_x;
				y_reg[cnt] <= in_y;
			end
		end
		else if(n_state == WORK) begin
			if(&pass && flag == 0) begin
				x_reg[m_num] <= tempx;
				y_reg[m_num] <= tempy;
			end
			else begin
				if(flag)begin
					x_reg[m_num-1] <= 5;
					y_reg[m_num-1] <= 5;
				end
				else begin
					if(p_num == p_n-1)begin
						x_reg[m_num-1] <= 5;
						y_reg[m_num-1] <= 5;
					end
				end
			end
		end
	end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		m_n <= 0;
	end
	else begin
		if(n_state == IDLE) begin
			m_n <= 0;
		end
		else if(n_state == IN) begin
			if(cnt == 0) begin
				if(in_valid) begin
					m_n <= move_num;
				end
			end
		end
	end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		p_n <= 0;
	end
	else begin
		if(n_state == IDLE) begin
			p_n <= 0;
		end
		else if(n_state == IN) begin
			if(cnt == 0) begin
				if(in_valid) begin
					p_n <= priority_num;
				end
			end
		end
	end
end





assign tx = x_reg[m_num-1] - x_reg[m_num-2];
assign ty = y_reg[m_num-1] - y_reg[m_num-2];

assign p_reg = (tx == -1 && ty == 2)? 3'd0 :
			   (tx == 1 && ty == 2)? 3'd1 :
			   (tx == 2 && ty == 1)? 3'd2 :
			   (tx == 2 && ty == -1)? 3'd3 :
			   (tx == 1 && ty == -2)? 3'd4 :
			   (tx == -1 && ty == -2)? 3'd5 :
			   (tx == -2 && ty == -1)? 3'd6 :
			   (tx == -2 && ty == 1)? 3'd7 : 3'd0;




assign p_sub = p_n-1;



always@(*) begin
	if(check[m_num] == 8'b11111111)begin
		flag = 1;
	end
	else begin
		flag = 0;
	end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		for(i=0; i<25; i=i+1) begin
			check[i] <= 0;
		end
	end
	else begin
		if(n_state == IDLE) begin
			for(i=0; i<25; i=i+1) begin
				check[i] <= 0;
			end
		end
		else if(n_state == WORK) begin
			if(&pass && flag == 0) begin
				check[m_num][p_num] <= 1;
			end
			else begin
				if(flag)begin
					check[m_num] <= 0;
				end
				else begin
					if(p_num == p_n-1)begin
						check[m_num] <= 0;
					end
					else begin
						check[m_num][p_num] <= 1;
					end
				end
			end
		end
	end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		m_num <= 0;
	end
	else begin
		if(n_state == IDLE) begin
			m_num <= 0;
		end
		else if(n_state == IN) begin
			if(cnt == 0) begin
				if(in_valid) begin
					m_num <= move_num;
				end
			end
		end
		else if(n_state == WORK) begin
			if(&pass && flag == 0) begin
				m_num <= m_num+1;
			end
			else begin
				if(flag)begin
					m_num <= m_num-1;
				end
				else begin
					if(p_num == p_n-1)begin
						m_num <= m_num-1;
					end
				end
			end
		end
	end
end



always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		p_num <= 0;
	end
	else begin
		if(n_state == IDLE) begin
			p_num <= 0;
		end
		else if(n_state == IN) begin
			if(cnt == 0) begin
				if(in_valid) begin
					p_num <= priority_num;
				end
			end
		end
		else if(n_state == WORK) begin
			if(&pass && flag == 0) begin
				p_num <= p_n;
			end
			else begin
				if(flag)begin
					p_num <= p_reg+1;
				end
				else begin
					if(p_num == p_n-1)begin
						p_num <= p_reg+1;
					end
					else begin
						p_num <= p_num+1;
					end
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
	end
end


always@(*) begin
	case(p_num)
		3'd0: begin
			tempx = x_reg[m_num-1]-1;
			tempy = y_reg[m_num-1]+2;
		end
		3'd1: begin
			tempx = x_reg[m_num-1]+1;
			tempy = y_reg[m_num-1]+2;
		end
		3'd2: begin
			tempx = x_reg[m_num-1]+2;
			tempy = y_reg[m_num-1]+1;
		end
		3'd3: begin
			tempx = x_reg[m_num-1]+2;
			tempy = y_reg[m_num-1]-1;
		end
		3'd4: begin
			tempx = x_reg[m_num-1]+1;
			tempy = y_reg[m_num-1]-2;
		end
		3'd5: begin
			tempx = x_reg[m_num-1]-1;
			tempy = y_reg[m_num-1]-2;
		end
		3'd6: begin
			tempx = x_reg[m_num-1]-2;
			tempy = y_reg[m_num-1]-1;
		end
		3'd7: begin
			tempx = x_reg[m_num-1]-2;
			tempy = y_reg[m_num-1]+1;
		end
	endcase
end


always@(*) begin
	for(j=0;j<25;j=j+1) begin
		if((0 <= tempx) && (tempx <= 4) && (0 <= tempy) && (tempy <= 4)) begin
			if((tempx == x_reg[j]) && (tempy == y_reg[j]))
				pass[j] = 0;
			else
				pass[j] = 1;
		end
		else begin
			pass = 0;
		end
	end
end



//Counter
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        cnt_out <= 0;
	end
	else begin
		if(n_state == IDLE) begin
			cnt_out <= 0;
		end
		else if(n_state == OUT) begin
			cnt_out <= cnt_out+1;
		end
	end
end

// ===============================================================
//  					Output Register
// ===============================================================

//Output assignment
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_valid <= 0;
		out_x <= 0;	
		out_y <= 0;	
		move_out <= 0;
	end
	else begin
		if(n_state == IDLE) begin
			out_valid <= 0;
			out_x <= 0;	
			out_y <= 0;	
			move_out <= 0;
		end
		else if(n_state == OUT) begin
			out_valid <= 1;
			out_x <= x_reg[cnt_out];	
			out_y <= y_reg[cnt_out];	
			move_out <= cnt_out+1;
		end
	end
end	

endmodule