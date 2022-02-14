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
parameter PATNUM=10000;

integer patcount;
integer cycles;
integer total_cycles;
integer i,maxseq;
integer gap;
//================================================================
// wire & registers 
//================================================================
reg [2:0] mode;
reg signed [8:0] data [8:0];
reg signed [8:0] max,min,avg;
reg signed [9:0] sum;
reg signed [10:0] sumseq [6:0];
reg signed [10:0] maxsum;
reg signed [8:0] ans1,ans2,ans3;
 //===============================================================
// clock
//================================================================
always	#(`CYCLE_TIME/2.0) clk = ~clk;
initial	clk = 0;
//================================================================
// initial
//================================================================
initial begin
	rst_n    = 1'b1;
	in_valid = 1'b0;
	
	cg_en    = 1'bx;//EXERCISE_wocg PATTERN.v
	//cg_en    = 1'b0;//EXERCISE PATTERN.v
	//cg_en    = 1'b1;//EXERCISE PATTERN_CG.v
	
	force clk = 0;
	total_cycles = 0;
	reset_task;
    @(negedge clk);

	for (patcount=0;patcount<PATNUM;patcount=patcount+1) begin
		input_data;
		calaulate_ans;
		wait_out_valid;
		check_ans;
		$display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32m Cycles: %3d\033[m", patcount ,cycles);
	end
	#(1000);
	YOU_PASS_task;
	$finish;
end

task reset_task ; begin
	#(10); rst_n = 0;

	#(10);
	if((out_data !== 0) || (out_valid !== 0)) begin
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                  Output signal should be 0 after initial RESET at %8t                                      ",$time);
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		
		#(100);
	    $finish ;
	end
	
	#(10); rst_n = 1 ;
	#(3.0); release clk;
end endtask

task input_data; begin
		gap = $urandom_range(1,3);
		repeat(gap)@(negedge clk);
		in_valid = 'b1;
		mode = $random();
		in_mode = mode;
				
		for(i=0;i<9;i=i+1) begin
			if(mode[0]==1) begin
				in_data[3:0] = $urandom_range(3,12);
				in_data[7:4] = $urandom_range(3,12);
				in_data[8]   = $urandom_range(0,1);
				if(in_data[8]) data[i] = (-1)*((in_data[7:4]-3)*10+(in_data[3:0]-3));
				else data[i] = (in_data[7:4]-3)*10+in_data[3:0]-3;
			end
			else begin
				data[i] = $random();
				in_data = data[i];
			end
			@(negedge clk);
			if (out_valid === 1) begin
				$display("out_valid should not be hight when in_valid is high");
				repeat(2)@(negedge clk);
				$finish;
			end
			
			if(i==1) in_mode = 'bx;
		end
		in_valid     = 'b0;
		in_data      = 'bx;
end endtask

task calaulate_ans; begin
	if(mode[1]==1) begin
		max = data[0];
		min = data[0];
		for(i=1;i<9;i=i+1) begin
			if(data[i]>max) max = data[i];
			if(data[i]<min) min = data[i];
		end
		sum = max+min;
		avg = sum/2;
		data[0] = data[0]-avg;
		data[1] = data[1]-avg;
		data[2] = data[2]-avg;
		data[3] = data[3]-avg;
		data[4] = data[4]-avg;
		data[5] = data[5]-avg;
		data[6] = data[6]-avg;
		data[7] = data[7]-avg;
		data[8] = data[8]-avg;
	end
	
	if(mode[2]==1) begin
		data[0] = (data[0]*2+data[0])/3;
		data[1] = (data[0]*2+data[1])/3;
		data[2] = (data[1]*2+data[2])/3;
		data[3] = (data[2]*2+data[3])/3;
		data[4] = (data[3]*2+data[4])/3;
		data[5] = (data[4]*2+data[5])/3;
		data[6] = (data[5]*2+data[6])/3;
		data[7] = (data[6]*2+data[7])/3;
		data[8] = (data[7]*2+data[8])/3;
	end
	
	sumseq[0] = data[0]+data[1]+data[2];
	sumseq[1] = data[1]+data[2]+data[3];
	sumseq[2] = data[2]+data[3]+data[4];
	sumseq[3] = data[3]+data[4]+data[5];
	sumseq[4] = data[4]+data[5]+data[6];
	sumseq[5] = data[5]+data[6]+data[7];
	sumseq[6] = data[6]+data[7]+data[8];
	maxsum = sumseq[0];
	maxseq = 0;
	for(i=1;i<7;i=i+1) begin
		if(sumseq[i]>maxsum) begin
			maxsum = sumseq[i];
			maxseq = i;
		end
	end
	ans1 = data[maxseq];
	ans2 = data[maxseq+1];
	ans3 = data[maxseq+2];
end endtask


task wait_out_valid; begin
	cycles = 0;
	while(out_valid === 0)begin
		cycles = cycles + 1;
		if(cycles == 3000) begin
			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			$display ("                                                                   Pattern NO.%03d                                                          ", patcount);
			$display ("                                                     The execution latency are over 3000 cycles                                            ");
			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			repeat(2)@(negedge clk);
			$finish;
		end
	@(negedge clk);
	end
	total_cycles = total_cycles + cycles;
end endtask


task check_ans; begin
    while(out_valid === 1) begin
		if(out_data !== ans1) begin
			$display ("\033[0;31mSPEC 7 IS FAIL!\033[m");
			$display ("Pattern NO.%03d", patcount);
			$display ("\033[0;31mout_data: %d,  ans: %d\033[m", out_data, ans1);
			@(negedge clk);
			$finish;
		end
		@(negedge clk);
		if(out_data !== ans2) begin
			$display ("\033[0;31mSPEC 7 IS FAIL!\033[m");
			$display ("Pattern NO.%03d", patcount);
			$display ("\033[0;31mout_data: %d,  ans: %d\033[m", out_data, ans2);
			@(negedge clk);
			$finish;
		end
		@(negedge clk);
		if(out_data !== ans3) begin
			$display ("\033[0;31mSPEC 7 IS FAIL!\033[m");
			$display ("Pattern NO.%03d", patcount);
			$display ("\033[0;31mout_data: %d,  ans: %d\033[m", out_data, ans3);
			@(negedge clk);
			$finish;
		end
		
		@(negedge clk);
    end
end endtask

task YOU_PASS_task;
	begin
	$display ("----------------------------------------------------------------------------------------------------------------------");
	$display ("                                                  Congratulations!                						            ");
	$display ("                                           You have passed all patterns!          						            ");
	$display ("                                           Your execution cycles = %5d cycles   						            ", total_cycles);
	$display ("                                           Your clock period = %.1f ns        					                ", `CYCLE_TIME);
	$display ("                                           Your total latency = %.1f ns         						            ", total_cycles*`CYCLE_TIME);
	$display ("----------------------------------------------------------------------------------------------------------------------");
	$finish;

	end
endtask


endmodule
