   module MAZE(
    //Input Port
    clk,
    rst_n,
    in_valid,
    in,
    //Output Port
    out_valid,
    out
);

input            clk, rst_n, in_valid, in;
output reg		 out_valid;
output reg [1:0] out;

reg [8:0] cnt;
reg cnt1;
reg maze [288:0];
reg map [288:0];
reg [2:0] state;
reg [2:0] n_state;
reg [1:0] out_reg;
reg [8:0] now;
reg [8:0] path [288:0];
reg up;
reg right;
reg down;
reg left;
reg [8:0] step;
integer i, j, k;

parameter RESET  = 3'd0;
parameter WAIT1  = 3'd1;
parameter IN  = 3'd2;
parameter GO  = 3'd3;
parameter WAIT2  = 3'd4;
//parameter OUT = 3'd5;
parameter RESTART  = 3'd6; 


	
//FSM current state assignment
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		state <= RESET;
	end
	else begin
		state <= n_state;
	end
end
	
	
always@(*) begin
	case(state)
		RESET: begin
			if(rst_n)
				n_state = WAIT1;
			else
				n_state = RESET;
		end
		WAIT1: begin
			if(!in_valid)
				n_state = WAIT1;
			else
				n_state = IN;
		end
		IN: begin
			if(in_valid)
				n_state = IN;
			else
				n_state = GO;
		end
		GO: begin
			if(now == 288)
				n_state = RESTART;
			else
				n_state = GO;
		end
		WAIT2: begin
			n_state = RESTART;
		end
		RESTART: begin
			n_state = WAIT1;
		end
		
		default: begin
			n_state = state;
		end
	endcase
end 




//counter
always@(posedge clk or negedge rst_n) begin
if(!rst_n) begin
	cnt <= 0;
	cnt1 <= 0;
end
else begin
	case(state)
		RESET: begin
			cnt <= 0;
			cnt1 <= 0;
		end
		IN: begin
			if(in_valid == 1) begin
				cnt <= cnt + 'd1;
			end
		end
		GO: begin
			if(now == 288)begin
				cnt1 <= 0;
			end
			else begin
				cnt1 <= 1;
			end
		end
		RESTART: begin
			cnt <= 0;
			cnt1 <= 0;
		end
	endcase
end
end


			


//direction
always@(*) begin
	if(state == GO && now != 288) begin
		if(17 <= now) begin
			if(maze[now-17] == 1 && map[now-17] == 0) begin
				up = 1;
			end
			else begin
				up = 0;
			end
		end
		else begin
			up = 0;
		end
		
		if(now%17 == 0) begin
			left = 0;
		end
		else begin
			if(maze[now-1] == 1 && map[now-1] == 0 && now%17 != 0) begin
				left = 1;
			end
			else begin
				left = 0;
			end
		end
		
		if(now <= 271) begin
			if(maze[now+17] == 1 && map[now+17] == 0) begin
				down = 1;
			end
			else begin
				down = 0;
			end
		end
		else begin
			down = 0;
		end
		
		if((now+1)%17 == 0 && now != 0) begin
			right = 0;
		end
		else begin
			if(maze[now+1] == 1 && map[now+1] == 0 && (now+1)%17 != 0) begin
				right = 1;
			end
			else begin
				right = 0;
			end
		end
	end
	else begin
		up = 0;
		right = 0;
		down = 0;
		left = 0;
	end
end



wire [3:0] flag;
assign flag = {up, left, down, right};





always@(posedge clk or negedge rst_n) begin
if(!rst_n) begin
	for(j=0;j<289;j=j+1) begin
		path[j] <= 0;
	end
end
else begin
	if(state == GO)begin
		if(flag == 4'b0000) begin
			path[step] <= 0;
		end
		else begin
			path[step] <= now;
		end
	end	
	else if(state == RESTART) begin
		for(j=0;j<289;j=j+1) begin
			path[j] <= 0;
		end
	end
end
end



//main
always@(posedge clk or negedge rst_n) begin
if(!rst_n) begin
	for(j=0;j<289;j=j+1) begin
		maze[j] <= 0;
		map[j] <= 0;
	end
	now <= 0;
	step <= 0;
end
else begin
	case(state)
		RESET: begin
			for(j=0;j<289;j=j+1) begin
				maze[j] <= 0;
				map[j] <= 0;
			end
			now <= 0;
			step <= 0;
			out_reg <= 2'd3;
		end
		WAIT1: begin
			map[0] <= 1;
			if(in_valid) begin
				maze[0] <= in;
			end
		end
		IN: begin
			if(in_valid) begin
				maze[cnt+1] <= in;
			end
		end
		GO: begin
			if(now == 0) begin
				if(maze[now+1] == 1 && map[now+1] == 0) begin
					now <= now+1;
					map[now+1] <= 1;
					step <= step+1;
					out_reg <= 2'd0;
				end
				else if(maze[now+17] == 1 && map[now+17] == 0) begin
					now <= now+17;
					map[now+17] <= 1;
					step <= step+1;
					out_reg <= 2'd1;
				end
			end
			else if(now == 288)begin
				now <= now;
			end
			else begin
				if(maze[now+1] == 1 && map[now+1] == 0 && (now+1)%17 != 0) begin					
					now <= now+1;
					map[now+1] <= 1;
					step <= step+1;
					out_reg <= 2'd0;
				end
				else if(maze[now+17] == 1 && map[now+17] == 0 && now <= 271) begin
					now <= now+17;
					map[now+17] <= 1;
					step <= step+1;
					out_reg <= 2'd1;
				end
				else if(maze[now-1] == 1 && map[now-1] == 0 && now%17 != 0) begin
					now <= now-1;
					map[now-1] <= 1;
					step <= step+1;
					out_reg <= 2'd2;
				end
				else if(maze[now-17] == 1 && map[now-17] == 0 && now >= 17) begin
					now <= now-17;
					map[now-17] <= 1;
					step <= step+1;
					out_reg <= 2'd3;
				end
				else if(flag == 4'b0000) begin
					now <= path[step-1];
					step <= step-1;
					if(now-path[step-1] == 1) begin
						out_reg <= 2'd2;
					end
					else if(now-path[step-1] == 17) begin
						out_reg <= 2'd3;
					end
					else if(path[step-1]-now == 1) begin
						out_reg <= 2'd0;
					end
					else if(path[step-1]-now == 17) begin
						out_reg <= 2'd1;
					end
				end
			end
		end
		WAIT2: begin
			step <= step;
		end
		/* OUT: begin
			step <= step;
		end */
		RESTART: begin
			for(k=0;k<289;k=k+1) begin
				maze[k] <= 0;
				map[k] <= 0;
			end
			now <= 0;
			step <= 0;
		end
	endcase
end
end


	
//Output assignment
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_valid <= 0;
		out <= 0;	
	end
	else if(/* state == WAIT2 ||  */cnt1 == 1) begin
		out_valid <= 1; 
		out <= out_reg;
	end
	else if(state == RESTART)begin
		out_valid <= 0;
		out <= 0;
	end
	else begin
		out_valid <= 0;
		out <= 0;
	end
end	
	
endmodule
