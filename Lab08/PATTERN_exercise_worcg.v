`define CYCLE_TIME 12

module PATTERN(
	// Output signals
	clk,
	rst_n,
	cg_en,
	in_valid,
	in_data,
	in_mode,
	// Input signals
	out_valid,
	out_data
);

output reg clk;
output reg rst_n;
output reg cg_en;
output reg in_valid;
output reg [8:0] in_data;
output reg [2:0] in_mode;

input out_valid;
input signed [9:0] out_data;

//================================================================
// parameters & integer
//================================================================
real CYCLE = `CYCLE_TIME;
//parameter patnumber = `PATNUMBER;
always  #(CYCLE/2.0) clk = ~clk;
initial clk = 0;

// ========================================================
// integer
// ========================================================
integer PATNUM = 1000; //  <==== Adjustable
integer patcount;
integer lat;
integer total_latency;
integer i, j, y;
integer seed;
// ========================================================
// register
// ========================================================
reg 		[8:0]	gen_in_data[0:8];
reg 		[2:0]	gen_in_mode;
reg signed	[9:0]	gold_ans[0:2];

initial begin
    rst_n = 1;    
    in_valid = 1'b0;
	in_data = 9'bx;
    in_mode = 3'bx;
	cg_en = 0;		//---->/EXERCISE/00_TESTBED/PATTERN.v
	//cg_en = 1;	//---->/EXERCISE/00_TESTBED/PATTERN_CG.v
	//cg_en = 1'bx;	//---->/EXERCISE_wocg/00_TESTBED/PATTERN.v
    
    force clk = 0;
    
    total_latency = 0; 
    reset_signal_task;
	
	seed = 1221;
    for(patcount=0;patcount<PATNUM;patcount=patcount+1)begin
        input_task;
		gen_ans;
        wait_OUT_VALID;
        check_ans;
        $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32m Latency: %3d\033[m at %8t" ,
                patcount ,lat,$time);
    end

    YOU_PASS_task;
    $finish;
end


task reset_signal_task; begin 
    #(0.5);   rst_n=0;
    
    #(2.0);
    if((out_valid !== 0)||(out_data !== 'b0)) begin
        $display ("-------------------------------------------------------------------------------------");
        $display ("                             SPEC 4 FAIL!                                             ");
        $display ("        Output signal should be 0 after initial RESET at %8t                          ",$time);
        $display ("---------------------------------------------------------------------------------------");

        $finish;
    end
    #(10);   rst_n=1;
    #(3);   
    release clk;
end
endtask


integer gap;
task input_task; begin
    gap = $urandom_range(2,5);
    repeat(gap)@(negedge clk);
	
	gen_in_mode = $random(seed) % 'd8; // 0~7
	
	for ( i = 0 ; i < 9 ; i = i + 1)begin
		if (gen_in_mode[0] === 1)begin // XS-3
			gen_in_data[i][3:0] = $random(seed) % 'd10 + 3; // 0~9 + 3
			gen_in_data[i][7:4] = $random(seed) % 'd10 + 3; // 0~9 + 3
			gen_in_data[i][8] = $random(seed) % 'd2; // 0~1
		end else begin
			gen_in_data[i] = $random(seed) % 'd512; // 0~511
		end
	end
	
	in_valid = 1;
    for( i = 0 ; i < 9 ; i = i + 1 ) begin 
        if (i == 0)begin
			in_data = gen_in_data[i];
			in_mode = gen_in_mode;
		end else begin
			in_data = gen_in_data[i];
			in_mode = 3'bx;
		end
		if(out_valid!==0)begin
			$display ("------------------------------------------------------------------------------------------------");
			$display ("                                SPEC 18 FAIL!                                                   ");
			$display ("                     The out_valid cannot overlap with in_valid                                 ");
			$display ("------------------------------------------------------------------------------------------------");
			repeat(2)@(negedge clk);
			$finish;
		end
        @(negedge clk); 
    end
	in_valid = 0;
	in_data = 9'bx;
    in_mode = 3'bx;
end
endtask

reg signed	[8:0]	swap_temp, max, min;
reg	signed	[9:0]	midpoint;
reg 		[3:0]	temp10, temp1;
reg signed	[8:0]	in_data_after_xs[0:8];
reg signed	[9:0]	in_data_after_mid[0:8];
reg signed	[8:0]	in_data_temp[0:8];
reg signed	[9:0]	in_data_after_cum[0:8];
reg			[2:0]	max_index;
reg signed	[11:0]	max_sum;

task gen_ans; begin
	for ( i=0 ; i<9 ; i=i+1)begin
		if (gen_in_mode[0] == 1)begin // XS-3
			case(gen_in_data[i][7:4])
				4'b0011: temp10 = 4'd0;
				4'b0100: temp10 = 4'd1;
				4'b0101: temp10 = 4'd2;
				4'b0110: temp10 = 4'd3;
				4'b0111: temp10 = 4'd4;
				4'b1000: temp10 = 4'd5;
				4'b1001: temp10 = 4'd6;
				4'b1010: temp10 = 4'd7;
				4'b1011: temp10 = 4'd8;
				4'b1100: temp10 = 4'd9;
			endcase
			case(gen_in_data[i][3:0])
				4'b0011: temp1 = 4'd0;
				4'b0100: temp1 = 4'd1;
				4'b0101: temp1 = 4'd2;
				4'b0110: temp1 = 4'd3;
				4'b0111: temp1 = 4'd4;
				4'b1000: temp1 = 4'd5;
				4'b1001: temp1 = 4'd6;
				4'b1010: temp1 = 4'd7;
				4'b1011: temp1 = 4'd8;
				4'b1100: temp1 = 4'd9;
			endcase
			if (gen_in_data[i][8] == 1) // negative
				in_data_after_xs[i] = -( 10*temp10 + temp1);
			else // positive
				in_data_after_xs[i] = 10*temp10 + temp1;
		end else begin
			in_data_after_xs[i] = gen_in_data[i];
		end
		in_data_temp[i] = in_data_after_xs[i];
	end
	
	for ( i = 0 ; i < 9 ; i = i + 1)begin
		for ( j = 0; j < 9-i ; j = j + 1 )begin
			if ( in_data_temp[j] > in_data_temp[j+1] )begin
				swap_temp 		  = in_data_temp[j];
				in_data_temp[j]   = in_data_temp[j+1];
				in_data_temp[j+1] = swap_temp;
			end
		end
	end
	max = in_data_temp[8];
	min = in_data_temp[0];
	midpoint = (max + min)/2;
	
	for ( i=0 ; i<9 ; i=i+1)begin
		if (gen_in_mode[1] == 1)begin // sub midpoint
			in_data_after_mid[i] = in_data_after_xs[i] - midpoint;
		end else begin
			in_data_after_mid[i] = in_data_after_xs[i];
		end
	end
	
	for ( i=0 ; i<9 ; i=i+1)begin
		if (gen_in_mode[2] == 1)begin // cumulation
			if(i == 0)begin
				in_data_after_cum[0] = in_data_after_mid[0];
			end
			else begin
				in_data_after_cum[i] = (in_data_after_cum[i-1]*2+in_data_after_mid[i])/3;
			end
		end else begin
			in_data_after_cum[i] = in_data_after_mid[i];
		end
	end
	
	for ( i=0 ; i<7 ; i=i+1)begin
		if(i == 0)begin
			max_index = 0;
			max_sum = in_data_after_cum[0]+in_data_after_cum[1]+in_data_after_cum[2];
		end
		else begin
			if((in_data_after_cum[i]+in_data_after_cum[i+1]+in_data_after_cum[i+2]) > max_sum)begin
				max_index = i;
				max_sum = in_data_after_cum[i]+in_data_after_cum[i+1]+in_data_after_cum[i+2];
			end
		end
	end
	
	for ( i=0 ; i<3 ; i=i+1)begin
		gold_ans[i] = in_data_after_cum[max_index + i];
	end
end
endtask

task wait_OUT_VALID; begin
  lat = -1;
  while(!out_valid) begin
    lat = lat + 1;
    if(lat == 1000) begin
        $display ("---------------------------------------------------------------------------------------------");
        $display ("                              SPEC 16 FAIL!                                                   ");
        $display ("                 The execution latency are over 1000   cycles                                ");
        $display ("---------------------------------------------------------------------------------------------");

        repeat(2)@(negedge clk);
        $finish;
    end
	/*
    if(out_data!==0)begin
			$display ("------------------------------------------------------------------------------------------------");
			$display ("                                SPEC 18 FAIL!                                                    ");
			$display ("                     Out shoud 0 when out_valid is low                                         ");
			$display ("------------------------------------------------------------------------------------------------");
			repeat(2)@(negedge clk);
			$finish;
		end
	*/
    @(negedge clk);
  end
  total_latency = total_latency + lat;
end endtask


task check_ans; begin
    y=0;
    while(out_valid)
    begin
        if(y>=3)begin
            $display ("-----------------------------------------------------------------------------------");
            $display ("                                 SPEC 5 FAIL!                                      ");
            $display ("                       Outvalid is more than 3 cycles                             ");
            $display ("-----------------------------------------------------------------------------------");
            #(100);
            $finish;
        end
        if(out_data!==gold_ans[y])begin
            $display ("------------------------------------------------------------");
            $display ("                     SPEC 8 FAIL!                            ");
            $display ("                    PATTERN NO.%4d                           ",patcount);
            $display ("              Ans: %d,  Your output : %d  at %8t               ",gold_ans[y],out_data,$time);
            $display ("---------------------------------------------------------------");
			#(100);
            $finish;
        end
        @(negedge clk); 
        y=y+1;
    end  
	/*
    if(out_data!== 0) begin
        $display ("----------------------------------------------------------------------------------------");
        $display ("                           SPEC 4 FAIL!                                                 ");
        $display ("        The out should be reset after your out_valid is pulled down                     ");
        $display ("----------------------------------------------------------------------------------------");
        #(100);
        $finish;
    end
	*/
end endtask

task YOU_PASS_task; begin
	$display ("---------------------------------------------------------------------");
	$display ("                         Congratulations!                            ");
	$display ("                  You have passed all patterns!                      ");
	$display ("                 Your execution cycles = %5d cycles  			    ", total_latency);
	$display ("                 Your clock period = %.1f ns        					", `CYCLE_TIME);
	$display ("                 Your total latency = %.1f ns         				", total_latency*`CYCLE_TIME);
	$display ("---------------------------------------------------------------------");
	$finish;
end
endtask

endmodule

