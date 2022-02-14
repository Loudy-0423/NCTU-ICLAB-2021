module bridge(input clk, INF.bridge_inf inf);

parameter IDLE         = 'd0 ;
parameter INPUT_R      = 'd1 ;
parameter WAIT_R       = 'd2 ;
parameter INPUT_W      = 'd3 ;
parameter WAIT_W       = 'd4 ;
parameter OUT          = 'd5 ;
//================================================================
//  logic
//================================================================
logic [2:0] state, n_state;
logic [7:0] addr;
logic [63:0] data;

//================================================================
// design 
//================================================================
//================================================================
//  FSM
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) begin
     	state <= IDLE ;
    end
	else begin
        state <= n_state ;
    end				
end


always_comb begin
	case(state)
		IDLE: begin
            n_state = (inf.C_r_wb == READ_DRAM && inf.C_in_valid)? INPUT_R : 
                      (inf.C_r_wb == WRITE_DRAM && inf.C_in_valid)? INPUT_W : IDLE;
		end
		INPUT_R: begin
            n_state = (inf.AR_READY)? WAIT_R : INPUT_R;
        end
        WAIT_R: begin
            n_state = (inf.R_VALID)? OUT : WAIT_R;
        end
		INPUT_W: begin
            n_state = (inf.AW_READY)? WAIT_W : INPUT_W;
        end 
		WAIT_W: begin
            n_state = (inf.B_VALID)? OUT : WAIT_W;
        end 
		OUT: begin
            n_state = IDLE;
        end	
        default: begin
            n_state = state;
        end
	endcase 
end

//================================================================
//   AXI Lite Signals
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin 
	if(!inf.rst_n) begin
        inf.B_READY <= 0 ;
    end	
	else begin
        inf.B_READY <= 1 ;
    end			
end	


// READ
assign inf.AR_VALID = (state == INPUT_R)? 1 : 0;
assign inf.AR_ADDR  = (state == INPUT_R)? { 1'b1, 5'b0, addr, 3'b0} : 0 ;
assign inf.R_READY  = (state == WAIT_R)? 1 : 0;


// WRITE
assign inf.AW_VALID = (state == INPUT_W)? 1 : 0;
assign inf.AW_ADDR  = (state == INPUT_W)? { 1'b1, 5'b0, addr, 3'b0} : 0 ;
assign inf.W_VALID  = (state == WAIT_W)? 1 : 0;
assign inf.W_DATA   = data;

//================================================================
//   INPUT
//================================================================


always_ff @(posedge clk or  negedge inf.rst_n) begin
	if (!inf.rst_n) begin
        addr <= 0;
    end	
	else begin
		if (inf.C_in_valid) begin
            addr <= inf.C_addr;
        end	
	end
end


always_ff @(posedge clk or  negedge inf.rst_n) begin
	if (!inf.rst_n) begin
        data <= 0;
    end	
	else begin
		if (inf.C_in_valid && inf.C_r_wb == WRITE_DRAM) begin
            data <= inf.C_data_w;
        end	/*
        else if(inf.R_VALID) begin
           data <= inf.R_DATA;
        end*/
	end
end
//================================================================
//   OUTPUT
//================================================================

always_ff @(posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) begin
        inf.C_out_valid <= 0;
    end 	
	else begin
		if (n_state == OUT) begin
            inf.C_out_valid <= 1;
        end	
		else begin
            inf.C_out_valid <= 0;
        end							
	end
end

//assign inf.C_data_r = data;

always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) begin
        inf.C_data_r <= 0;
    end	
	else begin
		if (inf.R_VALID) begin
            inf.C_data_r <= inf.R_DATA;
        end	
		else begin
            inf.C_data_r <= 0;
        end					
	end
end

endmodule