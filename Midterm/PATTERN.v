`ifdef RTL
`define CYCLE_TIME 15
`endif
`ifdef GATE
`define CYCLE_TIME 15
`endif


`include "../00_TESTBED/MEM_MAP_define.v"
`include "../00_TESTBED/pseudo_DRAM.v"


module PATTERN #(parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32)(
  // CHIP IO 
  clk             , 
  rst_n           , 
  in_valid        , 
  frame_id        , 
  net_id          ,   
  loc_x           ,   
    loc_y           ,
  cost      ,
  busy          ,

  // AXI4 IO
         awid_s_inf,
       awaddr_s_inf,
       awsize_s_inf,
      awburst_s_inf,
        awlen_s_inf,
      awvalid_s_inf,
      awready_s_inf,
                    
        wdata_s_inf,
        wlast_s_inf,
       wvalid_s_inf,
       wready_s_inf,
                    
          bid_s_inf,
        bresp_s_inf,
       bvalid_s_inf,
       bready_s_inf,
                    
         arid_s_inf,
       araddr_s_inf,
        arlen_s_inf,
       arsize_s_inf,
      arburst_s_inf,
      arvalid_s_inf,
                    
      arready_s_inf, 
          rid_s_inf,
        rdata_s_inf,
        rresp_s_inf,
        rlast_s_inf,
       rvalid_s_inf,
       rready_s_inf 
             );

// ===============================================================
//            Input / Output 
// ===============================================================

// << CHIP io port with system >>
output reg          clk,rst_n;
output reg          in_valid;
output reg [4:0]    frame_id;
output reg [3:0]        net_id;     
output reg [5:0]        loc_x; 
output reg [5:0]        loc_y; 
input [13:0]      cost;
input                   busy;       
 
// << AXI Interface wire connecttion for pseudo DRAM read/write >>
// (1)  axi write address channel 
//    src master
input wire [ID_WIDTH-1:0]      awid_s_inf;
input wire [ADDR_WIDTH-1:0]  awaddr_s_inf;
input wire [2:0]             awsize_s_inf;
input wire [1:0]            awburst_s_inf;
input wire [7:0]              awlen_s_inf;
input wire                  awvalid_s_inf;
//    src slave
output wire                 awready_s_inf;
// -----------------------------

// (2)  axi write data channel 
//    src master
input wire [DATA_WIDTH-1:0]   wdata_s_inf;
input wire                    wlast_s_inf;
input wire                   wvalid_s_inf;
//    src slave
output wire                  wready_s_inf;

// (3)  axi write response channel 
//    src slave
output wire  [ID_WIDTH-1:0]     bid_s_inf;
output wire  [1:0]            bresp_s_inf;
output wire                  bvalid_s_inf;
//    src master 
input wire                   bready_s_inf;
// -----------------------------

// (4)  axi read address channel 
//    src master
input wire [ID_WIDTH-1:0]      arid_s_inf;
input wire [ADDR_WIDTH-1:0]  araddr_s_inf;
input wire [7:0]              arlen_s_inf;
input wire [2:0]             arsize_s_inf;
input wire [1:0]            arburst_s_inf;
input wire                  arvalid_s_inf;
//    src slave
output wire                 arready_s_inf;
// -----------------------------

// (5)  axi read data channel 
//    src slave
output wire [ID_WIDTH-1:0]      rid_s_inf;
output wire [DATA_WIDTH-1:0]  rdata_s_inf;
output wire [1:0]             rresp_s_inf;
output wire                   rlast_s_inf;
output wire                  rvalid_s_inf;
//    src master
input wire                   rready_s_inf;





// -------------------------//
//     DRAM Connection      //
//--------------------------//

pseudo_DRAM u_DRAM(

      .clk(clk),
      .rst_n(rst_n),

   .   awid_s_inf(   awid_s_inf),
   . awaddr_s_inf( awaddr_s_inf),
   . awsize_s_inf( awsize_s_inf),
   .awburst_s_inf(awburst_s_inf),
   .  awlen_s_inf(  awlen_s_inf),
   .awvalid_s_inf(awvalid_s_inf),
   .awready_s_inf(awready_s_inf),

   .  wdata_s_inf(  wdata_s_inf),
   .  wlast_s_inf(  wlast_s_inf),
   . wvalid_s_inf( wvalid_s_inf),
   . wready_s_inf( wready_s_inf),

   .    bid_s_inf(    bid_s_inf),
   .  bresp_s_inf(  bresp_s_inf),
   . bvalid_s_inf( bvalid_s_inf),
   . bready_s_inf( bready_s_inf),

   .   arid_s_inf(   arid_s_inf),
   . araddr_s_inf( araddr_s_inf),
   .  arlen_s_inf(  arlen_s_inf),
   . arsize_s_inf( arsize_s_inf),
   .arburst_s_inf(arburst_s_inf),
   .arvalid_s_inf(arvalid_s_inf),
   .arready_s_inf(arready_s_inf), 

   .    rid_s_inf(    rid_s_inf),
   .  rdata_s_inf(  rdata_s_inf),
   .  rresp_s_inf(  rresp_s_inf),
   .  rlast_s_inf(  rlast_s_inf),
   . rvalid_s_inf( rvalid_s_inf),
   . rready_s_inf( rready_s_inf) 
);





// ===============================================================
//            Parameter Declaration 
// ===============================================================

integer PATNUM;
integer total_cycles;
integer patcount;
integer cycles;
integer a, b, c, i, j, k, input_file;
integer gap;



// ===============================================================
//            tmp_signal 
// ===============================================================

integer pat_num, macro_num, cnt;
reg [3:0] net_id_array [0:15];

reg [5:0] source_x [0:15];
reg [5:0] source_y [0:15];
reg [5:0] sink_x [0:15];
reg [5:0] sink_y [0:15];

reg [5:0] cur_step_x, cur_step_y, next_step_x, next_step_y;
reg [10:0] step_num;
reg [13:0] total_cost;

//================================================================
// clock
//================================================================
always  #(`CYCLE_TIME/2.0) clk = ~clk;
initial clk = 0;

  
//================================================================
// Frame / Weight
//================================================================

reg [3:0] frame [0:31][0:63][0:63];
reg [3:0] weight[0:31][0:63][0:63];

reg [3:0] original_frame[0:31][0:63][0:63];



always@(*)
begin
  if(busy === 1 && in_valid === 1)
  begin
    $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
    $display ("                                                                        FAIL!                                                               ");
    $display ("                                                  Busy should not be raised when in_valid is high !!                                        ");
    $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
    #(100);
      $finish;
  end
end


always@(*)
begin
  for(i=0;i<32;i=i+1)
    for(j=0;j<64;j=j+1)
      for(k=0;k<32;k=k+1)
      begin
        {frame[i][j][2*k+1], frame[i][j][2*k]}  = u_DRAM.DRAM_r[65536+2048*i+32*j+k];
        {weight[i][j][2*k+1], weight[i][j][2*k]} = u_DRAM.DRAM_r[65536*2+2048*i+32*j+k];
      end
end



initial begin
  rst_n    = 1'b1;
  in_valid = 1'b0;
    frame_id = 'dx;
    net_id   = 'dx;
    loc_x    = 'dx;
    loc_y    = 'dx;
  
  force clk = 0;
  total_cycles = 0;
  reset_task;
  
  input_file=$fopen("../00_TESTBED/TEST_CASE/input_0.txt","r");
  a = $fscanf(input_file,"%d",PATNUM);
    repeat(10) @(negedge clk);
  
  initialize_original_frame;

  for (patcount=0;patcount<PATNUM;patcount=patcount+1) begin
    //$display("PATNUM %4d",patcount);
    input_data;
    wait_busy;
    check_consistency;
    check_conectivity_cost;
    $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32m Cycles: %3d\033[m", patcount ,cycles);
  end
  #(1000);
  YOU_PASS_task;
  $finish;

end




task initialize_original_frame ; begin

  for(i=0;i<32;i=i+1)
    for(j=0;j<64;j=j+1)
      for(k=0;k<32;k=k+1)
        {original_frame[i][j][2*k+1],original_frame[i][j][2*k]}  = u_DRAM.DRAM_r[65536+2048*i+32*j+k];


end endtask



task input_data ; 
  begin
    gap = $urandom_range(1,3);
    repeat(gap)@(negedge clk);
    in_valid = 'b1;
    a = $fscanf(input_file,"%d %d",pat_num,macro_num);
    frame_id = pat_num;
    
    for(i=0;i<macro_num;i=i+1)begin
      b = $fscanf(input_file,"%d",net_id);
      
      net_id_array[i] = net_id;
      
      for(j=0;j<2;j=j+1)
      begin
        b = $fscanf(input_file,"%d %d",loc_x, loc_y);
        if(j==0)
        begin
          source_x[i] = loc_x;
          source_y[i] = loc_y;
        end else begin
          sink_x[i] = loc_x;
          sink_y[i] = loc_y;
        end
        @(negedge clk);
      end
    end
    
    in_valid     = 'b0;
    frame_id     = 'bx;
    net_id       = 'bx;
    loc_x        = 'bx;
    loc_y        = 'bx;
    @(negedge clk);
  end 
endtask


task check_consistency ; begin
  for(i=0;i<64;i=i+1)
    for(j=0;j<64;j=j+1)
      if(original_frame[pat_num][i][j] !== 0 && original_frame[pat_num][i][j] !== frame[pat_num][i][j])
      begin
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                                        FAIL!                                                               ");
        $display ("                                                  Consistency Check Fail at Frame : %4d                                                     ", pat_num);
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
              $display ("                                                               Golden_FRAME                                                                 ");
              for(i=0;i<64;i=i+1)
              begin
                for(j=0;j<64;j=j+1)
                  $write("%1d", original_frame[pat_num][i][j]);
                $display(" ");
              end
              $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
              $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
              $display ("                                                               YOUR_FRAME                                                                 ");
              for(i=0;i<64;i=i+1)
              begin
                for(j=0;j<64;j=j+1)
                  $write("%1d", frame[pat_num][i][j]);
                $display(" ");
              end
              $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        #(100);
              $finish;
          end 
end endtask

task check_conectivity_cost ; begin
  total_cost = 0;
  for(i=0;i<macro_num;i=i+1)
  begin
    cur_step_x = source_x[i];
    cur_step_y = source_y[i];
    step_num = 0;
    
    
    original_frame[pat_num][sink_y[i]][sink_x[i]] = 0;
    
    while(!(cur_step_x == sink_x[i] && cur_step_y == sink_y[i]))
    begin
      //$display("cur_x : %2d, cur_y :%2d ", cur_step_x, cur_step_y);
      //$display("Net id : %2d", net_id_array[i]);
      step_num = step_num + 1;
      cnt = 0;
      
      
      
      if(cur_step_y>=1)
        if(frame[pat_num][cur_step_y-1][cur_step_x] == net_id_array[i] && original_frame[pat_num][cur_step_y-1][cur_step_x] == 0)
        begin
          //$display("condition 1");
          cnt = cnt + 1;
          next_step_x = cur_step_x;
          next_step_y = cur_step_y-1;
        end
          
      if(cur_step_y<=62)
        if(frame[pat_num][cur_step_y+1][cur_step_x] == net_id_array[i] && original_frame[pat_num][cur_step_y+1][cur_step_x] == 0)
        begin
          //$display("condition 2");
          cnt = cnt + 1;
          next_step_x = cur_step_x;
          next_step_y = cur_step_y+1;
        end
          
      if(cur_step_x>=1)
        if(frame[pat_num][cur_step_y][cur_step_x-1] == net_id_array[i] && original_frame[pat_num][cur_step_y][cur_step_x-1] == 0)
        begin
          //$display("condition 3");
          cnt = cnt + 1;
          next_step_x = cur_step_x-1;
          next_step_y = cur_step_y;
        end
        
      if(cur_step_x<=62)
        if(frame[pat_num][cur_step_y][cur_step_x+1] == net_id_array[i] && original_frame[pat_num][cur_step_y][cur_step_x+1] == 0)
        begin
          //$display("condition 4");
          cnt = cnt + 1;
          next_step_x = cur_step_x+1;
          next_step_y = cur_step_y;
          
        end
      original_frame[pat_num][next_step_y][next_step_x] = net_id_array[i];
      
      cur_step_x = next_step_x;
      cur_step_y = next_step_y;
      
      
      if(cnt > 1)
      begin
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                                        FAIL!                                                               ");
        $display ("                                                               Connectivity Check Fail!                                                     ");
        $display ("                                                             Multiple Route at Frame : %4d                                                  ", pat_num);
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        //display_frame;
        #(100);
        $finish;
      end
      
      if(step_num > 1000)
      begin
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                                        FAIL!                                                               ");
        $display ("                                                               Connectivity Check Fail!                                                     ");
        $display ("                                                             Over 1000 step at Frame : %4d                                                  ", pat_num);
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        //display_frame;
        #(100);
        $finish;
      end
      
      if(!(cur_step_x == sink_x[i] && cur_step_y == sink_y[i]))
      begin
        total_cost = total_cost + weight[pat_num][cur_step_y][cur_step_x];
        //$display("Total Cost: %4d", total_cost);
      end
    end
    //$display("Total Cost: %4d", total_cost);
  end
  
  
  if(cost !== total_cost)
  begin
    //display_weight;
    //display_frame;
    $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
    $display ("                                                                        FAIL!                                                               ");
    $display ("                                                                     Cost Check Fail!                                                       ");
    $display ("                                                                    Golden_Cost: %6d                                                        ", total_cost);
    $display ("                                                                      Your_Cost: %6d                                                        ", cost);
    $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
    #(100);
    $finish;
  end

end endtask



task display_frame ; begin
  $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
  $display ("                                                               Golden_FRAME                                                                 ");
  for(i=0;i<64;i=i+1)
  begin
    for(j=0;j<64;j=j+1)
      $write("%1h", original_frame[pat_num][i][j]);
    $display(" ");
  end
  $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
  $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
  $display ("                                                               YOUR_FRAME                                                                 ");
  for(i=0;i<64;i=i+1)
  begin
    for(j=0;j<64;j=j+1)
      $write("%1h", frame[pat_num][i][j]);
    $display(" ");
  end
  $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
end endtask


task display_weight ; begin
  $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
  $display ("                                                               WEIGHT                                                                       ");
  for(i=0;i<64;i=i+1)
  begin
      for(j=0;j<64;j=j+1)
        $write("%1h", weight[pat_num][i][j]);
      $display(" ");
  end
  $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
end endtask


task reset_task ; begin
  #(10); rst_n = 0;

  #(10);
  if(busy !== 0 || cost !== 0) begin
    $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
    $display ("                                                                        FAIL!                                                               ");
    $display ("                                                  Output signal should be 0 after initial RESET at %8t                                      ",$time);
    $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
    
    #(100);
      $finish ;
  end
  
  #(10); rst_n = 1 ;
  #(3.0); release clk;
end endtask


task wait_busy ; 
begin
  cycles = 0;
  while(busy === 1)begin
    cycles = cycles + 1;
    if(cycles == 1000000) begin
      $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
      $display ("                                                                        FAIL!                                                               ");
      $display ("                                                                   Pattern NO.%03d                                                          ", patcount);
      $display ("                                                     The execution latency are over 1000000 cycles                                          ");
      $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
      repeat(2)@(negedge clk);
      $finish;
    end
  @(negedge clk);
  end
  total_cycles = total_cycles + cycles;
end 
endtask

task YOU_PASS_task;
  begin
  $display ("----------------------------------------------------------------------------------------------------------------------");
  $display ("                                                  Congratulations!                                       ");
  $display ("                                           You have passed all patterns!                                 ");
  $display ("                                           Your execution cycles = %5d cycles                          ", total_cycles);
  $display ("                                           Your clock period = %.1f ns                                 ", `CYCLE_TIME);
  $display ("                                           Your total latency = %.1f ns                                ", total_cycles*`CYCLE_TIME);
  $display ("----------------------------------------------------------------------------------------------------------------------");
  $finish;

  end
endtask

endmodule

