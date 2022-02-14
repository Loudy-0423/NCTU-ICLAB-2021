//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2020 ICLAB Fall Course
//   Lab06       : GF inverse array
//   Author      : Tien-Hui Lee (bnfw623@gmail.com)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//   Release version : v1.0
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
`ifdef RTL
    `define CYCLE_TIME 2.6
`endif

`ifdef GATE
    `define CYCLE_TIME 2.6
`endif

module PATTERN(
    // Output signals
    in_valid, in_data,
	deg, poly,
	rst_n, clk,
    // Input signals
    out_data,
    out_valid
);

//================================================================
//   INPUT AND OUTPUT DECLARATION
//================================================================
output reg        clk, rst_n, in_valid;
output reg [2:0]  deg;
output reg [5:0]  poly;
output reg [4:0]  in_data;

input         out_valid;
input [4:0]   out_data; 

//================================================================
//   CLOCK
//================================================================
real CYCLE = `CYCLE_TIME;
initial 
begin
	clk = 0;
end
always #(CYCLE/2.0) clk = ~clk;

//================================================================
//   FILE
//================================================================
integer fin,fout,in_hold,out_hold;
integer patcount,PATNUM,total_latency;
integer SEED = 123;//$urandom_range(2,4);
integer wait_val_time;
integer i,j,iii,jjj;

//================================================================
//   GOLD
//================================================================
integer goldas;
integer goldset[0:3];
integer savedeg,savepoly;

//================================================================
//   pattern
//================================================================
initial 
begin


	//+++++++++++++++++++++++++++++++++++++++++++++++++++
	fin=$fopen("../00_TESTBED/in.txt","r");
	fout=$fopen("../00_TESTBED/out.txt","r");	
	in_hold=$fscanf(fin,"%d",PATNUM);
	//+++++++++++++++++++++++++++++++++++++++++++++++++++


	rst_n=1'b1;
	in_valid=1'b0;
	deg='bx;poly='bx;in_data='bx;
	

	
	force clk = 0;
 	total_latency = 0;
	reset_signal_task;
	
	

	repeat(1)@(negedge clk);
	
	for(patcount=1; patcount<=PATNUM; patcount=patcount+1) 
	begin
		input_task;
		wait_out_valid;
		check_ans;
		
		$display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mexecution cycle : %3d deg=%d,poly=%d  \033[m",patcount ,wait_val_time,savedeg,savepoly);
		
		repeat(1)@(negedge clk);
		
	end	
  	YOU_PASS_task;
	
	

end

//================================================================
// task
//================================================================
task reset_signal_task; 
begin 
  #(0.5);  rst_n=0;
  #(2.0);
  if((out_valid !== 0)||(out_data !== 0)) 
  begin
    $display("**************************************************************");
    $display("*   Output signal should be 0 after initial RESET at %4t     *",$time);
    $display("**************************************************************");
    $finish;
  end
  #(10);  rst_n=1;
  #(3);  release clk;
end 
endtask


task input_task;
begin
	in_hold=$fscanf(fin,"%d",deg);savedeg=deg;
	in_hold=$fscanf(fin,"%d",poly);savepoly=poly;
	in_hold=$fscanf(fin,"%d",in_data);
	in_valid=1'b1;
	@(negedge clk);
	deg='bx;poly='bx;
	in_hold=$fscanf(fin,"%d",in_data);
	@(negedge clk);
	in_hold=$fscanf(fin,"%d",in_data);
	@(negedge clk);
	in_hold=$fscanf(fin,"%d",in_data);
	@(negedge clk);
	in_valid=1'b0;in_data='bx;
end
endtask


task wait_out_valid; begin
	wait_val_time = -1;
	while(out_valid !== 1) begin
		wait_val_time = wait_val_time + 1;
		if(wait_val_time == 300)
		begin
			$display("***************************************************************");
			$display("*         The execution latency are over 300 cycles.         *");
			$display("***************************************************************");
			#(5);
			$finish;
		end
		@(negedge clk);
	end
end endtask




task check_ans ; 
begin
	for(iii=0;iii<4;iii=iii+1)begin
		if(out_valid!==1)begin
			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			$display ("                                                                        FAIL!                                                               ");
			$display ("                                                                   Pattern NO.%03d                                                     ", patcount);
			$display ("	                                                   out_valid should be high during output                                        ");
			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			#(2.0);
			$finish;
		end
		
		out_hold=$fscanf(fout,"%d",goldas);
		goldset[iii]=goldas;
		
		if(out_data!==goldas)begin
			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			$display ("                                                                        FAIL!                                                               ");
			$display ("                                                                   Pattern NO.%03d                                                     ", patcount);
			$display ("	                                    %d    Golden  =%d\t|\tYour =%d  \t                                         ",iii,goldas,out_data);
			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			#(2.0);
			$finish;
		end
		
		@(negedge clk);
	end
	
	if(out_valid!==0)begin
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                        FAIL!                                                               ");
		$display ("                                                                   Pattern NO.%03d                                                     ", patcount);
		$display ("	                                                   out_valid should be low after output                                         ");
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		#(2.0);
		$finish;
	end
		
	total_latency=total_latency+wait_val_time;
	
end 
endtask



task YOU_PASS_task; 
begin
	$display ("--------------------------------------------------------------------");
	$display ("          ~( ˘ω˘ )~(๑╹ᆺ╹)~(｡•ᴗ•｡)~(๑╹ᆺ╹)~(*´꒳`*)ﾟ*.・♡            ");
	$display ("                         Congratulations!                           ");
	$display ("                  You have passed all patterns!                     ");
	$display ("                 Total Cycle = %d  ",total_latency);
	$display ("                 Total Time = %d  ",total_latency*CYCLE);
	$display ("--------------------------------------------------------------------");        
	#(5);
	$finish;
end
endtask



endmodule
