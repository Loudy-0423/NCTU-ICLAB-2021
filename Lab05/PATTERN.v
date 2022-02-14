//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//      (C) Copyright NCTU OASIS Lab      
//            All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2021 ICLAB fall Course
//   Lab05		: SRAM, Template Matching with Image Processing
//   Author     : Shaowen-Cheng (shaowen0213@gmail.com)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : TESTBED.v
//   Module Name : TESTBED
//   Release version : v1.0
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
`ifdef RTL
	`timescale 1ns/10ps
	`include "TMIP.v"
	`define CYCLE_TIME 18.0
`endif
`ifdef GATE
	`timescale 1ns/10ps
	`include "TMIP_SYN.v"
	`define CYCLE_TIME 18.0
`endif

module PATTERN(
// output signals
    clk,
    rst_n,
    in_valid,
	in_valid_2,
    image,
    img_size,
    template, 
    action,
// input signals
    out_valid,
    out_x,
    out_y,
    out_img_pos,
    out_value
);

//================================================================
// input and output declaration                         
//================================================================
output reg        clk, rst_n, in_valid, in_valid_2;
output reg [15:0] image, template;
output reg [4:0]  img_size;
output reg [1:0]  action;

input         out_valid;
input [3:0]   out_x, out_y; 
input [7:0]   out_img_pos;
input signed[39:0]  out_value;

//================================================================
// parameters & integer
//================================================================
real CYCLE = `CYCLE_TIME;
real delay_time = 1;
parameter MISSIONUM = 10; //100

integer missioncount;
integer matrixcount;
integer actioncount;

integer total_latency;
integer latency;
integer i, j, k, l;
integer gap;

//================================================================
// reg & wire
//================================================================
reg [2:0] size_seed;
reg [3:0] action_seed;
reg [4:0] size_data; // current size of matrix
reg [4:0] change_num;
reg [4:0] target_column, target_row; // for 1_max_pooling
reg [4:0] couple_column; // for 2_horizontal_flip
reg [8:0] total_element;
reg [3:0] action_num; // the number of instruction

reg signed [15:0] matrix_store[0:255];
reg signed [15:0] matrix_array[0:15][0:15];
reg signed [15:0] template_store[0:8];
reg signed [15:0] template_array[0:2][0:2];
reg signed [39:0] result_array[0:15][0:15];
reg signed [39:0] cross_result;
reg [1:0] action_store[0:7];

reg signed [15:0] temp_1, temp_2;
reg signed [39:0] temp_3, temp_4;

reg [3:0] x_coordinate, y_coordinate;
reg [7:0] position_step;
reg [7:0] pos_0, pos_1, pos_2, pos_3, pos_4, pos_5, pos_6, pos_7, pos_8, golden_pos;
reg [3:0] position_x, position_y;
reg [3:0] position_at;
reg index_fail;

//================================================================
// clock
//================================================================
initial begin
    clk = 0;
end
always #(CYCLE/2.0) clk = ~clk;

//================================================================
// initial
//================================================================
initial begin
    rst_n = 1'b1;
    in_valid   = 1'b0;
    in_valid_2 = 1'b0;
    total_latency = 0;
    x_coordinate = 0;
    y_coordinate = 0;

    image = 'bx;
    template = 'bx;
    img_size = 'bx;
    action = 'bx;

    force clk = 0;
    reset_signal_task;

    for (missioncount=0; missioncount<MISSIONUM; missioncount=missioncount+1) begin
        input_matrix_task;
        input_action_task;
        template_matching;
        wait_out_valid;
        check_ans;
    end
    you_pass_task;
end

//================================================================
// reset & specifications
//================================================================
task reset_signal_task; begin
    #(0.5);  rst_n = 0;

    #(CYCLE/2.0);
    if ((out_valid !== 0) || (out_x !== 0) || (out_y !== 0) || (out_value !== 0)) begin
        $display("**************************************************************");
        $display("*   Output signal should be 0 after initial RESET at %4t     *",$time);
        $display("**************************************************************");
        $finish;
    end
    #(10); rst_n = 1;
    #(3);  release clk;
end endtask

task  wait_out_valid; begin
    latency = 0;
    while (out_valid !== 1) begin
        latency = latency + 1;
        if (latency == 4000) begin
            $display("***************************************************************");
            $display("*        The execution latency are over 4000 cycles           *");
            $display("***************************************************************");
            repeat(2)@(negedge clk);
            $finish;
        end
        @(negedge clk);
    end
    total_latency = total_latency + latency;
end endtask

//================================================================
// input
//================================================================
task input_matrix_task; begin
    
    // mission operation
    gap = $urandom_range(2,5);
    repeat(gap) @(negedge clk);

    in_valid  = 1'b1;
    // initialize store vector
    for (i=0; i<256; i=i+1) begin
        matrix_store[i] = 0;
    end
    for (i=0; i<9; i=i+1) begin
        template_store[i] = 0;
    end

    // initialize cross correlation result array
    for (i=0; i<16; i=i+1) begin
        for (j=0; j<16; j=j+1) begin
            result_array[i][j] = 0;
        end
    end

    // set matrix size
    //size_seed = $random();
    size_seed = 3'd3;
    if      ((size_seed <= 3'd7) && (size_seed >= 3'd5)) size_data = 5'd16; // origin size
    else if ((size_seed <= 3'd4) && (size_seed >= 3'd2)) size_data = 5'd8;
    else                                                 size_data = 5'd4;
    total_element = size_data * size_data;

    // input matrix data
    for (matrixcount=0; matrixcount<total_element; matrixcount=matrixcount+1) begin
        image = $random();
        matrix_store[matrixcount] = image;

        if (matrixcount == 0) img_size = size_data;
        else                  img_size = 'bx;

        if (matrixcount <= 8) begin
            template = $random();
            template_store[matrixcount] = template;
        end
        else template = 'bx;

        @(negedge clk);
    end
    image = 'bx;
    in_valid  = 1'b0; // finish

    // transform matrix data to array (initial first)
    for (i=0; i<16; i=i+1) begin
        for (j=0; j<16; j=j+1) begin
            matrix_array[i][j] = 0;
        end
    end
    for (i=0; i<size_data; i=i+1) begin
        for (j=0; j<size_data; j=j+1) begin
            matrix_array[i][j]  = matrix_store[i*size_data+j];
        end
    end

    // transform template data to array (initial first)
    for (i=0; i<3; i=i+1) begin
        for (j=0; j<3; j=j+1) begin
            template_array[i][j] = 0;
        end
    end
    for (i=0; i<3; i=i+1) begin
        for (j=0; j<3; j=j+1) begin
            template_array[i][j]  = template_store[i*3+j];
        end
    end
end endtask


task input_action_task; begin
    @(negedge clk);
    in_valid_2 = 1'b1;

    // clear & initialize
    for (i=0; i<8; i=i+1) begin
        action_store[i] = 0;
    end

    // the number of instruction ranges from 1 to 8
    //action_num = $urandom_range(1,8);
    action_num = 8;

    //input action
    for (actioncount=1; actioncount <= action_num; actioncount=actioncount+1) begin
        if (actioncount == action_num) begin
            action = 0;
            action_store[actioncount] = action; // dummy (due to previous initialization)
        end
        else begin
            action_seed = $random();
            case(action_seed)
                4'd0: action = 2'd1;
                4'd1: action = 2'd2;
                4'd2: action = 2'd3;
                4'd3: action = 2'd1;
                4'd4: action = 2'd2;
                4'd5: action = 2'd3;
                4'd6: action = 2'd1;
                4'd7: action = 2'd2;
                4'd8: action = 2'd3;
                4'd9: action = 2'd1;
                4'd10: action = 2'd2;
                4'd11: action = 2'd3;
                4'd12: action = 2'd1;
                4'd13: action = 2'd2;
                4'd14: action = 2'd3;
                4'd15: action = 2'd1;
                default: action = 2'd2;
            endcase
            //action = $urandom_range(1,3);
            action_store[actioncount] = action;
        end
        @(negedge clk);
    end
    action = 'bx;
    in_valid_2 = 1'b0; // finish
end endtask

//================================================================
// mission execution
//================================================================
task template_matching; begin
    for (actioncount=1; actioncount <= action_num; actioncount=actioncount+1) begin
        // parameter
        change_num = size_data / 2;
        // 4 possible operations
        case(action_store[actioncount])
            2'd0:     cross_correlation;     
            2'd1:     max_pooling;           
            2'd2:     horizontal_flip;       
            2'd3:     brightness_adjustment; 
            default:  cross_correlation;     
        endcase
        #(delay_time); // all actions can be finish in about 8~10ns
    end

    // find the position of maximum
    find_maximum_matching;
end endtask

// 4 possible operations
// on   matrix_array
// with template_array
task cross_correlation;  begin // last operation
    for (i=0; i<size_data; i=i+1) begin
        for (j=0; j<size_data; j=j+1) begin
            // 3x3 matrix calculation
            cross_result = 0; // initialize
            for (k=0; k<3; k=k+1) begin
                for (l=0; l<3; l=l+1) begin
                    temp_1 = template_array[k][l];
                    // temp_2
                        if      ((i==0) && (k==0)) temp_2 = 0;
                        else if ((j==0) && (l==0)) temp_2 = 0;
                        else if ((i==size_data-1) && (k==2)) temp_2 = 0;
                        else if ((j==size_data-1) && (l==2)) temp_2 = 0;
                        else begin
                            case(3*k+l)
                                0: temp_2 = matrix_array[i-1][j-1];
                                1: temp_2 = matrix_array[i-1][j];
                                2: temp_2 = matrix_array[i-1][j+1];
                                3: temp_2 = matrix_array[i][j-1];
                                4: temp_2 = matrix_array[i][j];
                                5: temp_2 = matrix_array[i][j+1];
                                6: temp_2 = matrix_array[i+1][j-1];
                                7: temp_2 = matrix_array[i+1][j];
                                8: temp_2 = matrix_array[i+1][j+1];
                                default: temp_2 = 0;
                            endcase
                        end
                    // temp_2
                    temp_3 = temp_1 * temp_2;
                    cross_result = cross_result + temp_3;
                end
            end
            result_array[i][j] = cross_result; // store to cross correlation result array
        end
    end
end endtask

task max_pooling; begin
    if ((size_data == 5'd8) || (size_data == 5'd16)) begin
        for (i=0; i<change_num; i=i+1) begin
            target_row = i * 2;
            for (j=0; j<change_num; j=j+1) begin
                target_column = j * 2;
                // max pooling
                temp_1 = matrix_array[target_row][target_column];
                matrix_array[target_row][target_column] = 0;
                for (k=1; k<4; k=k+1) begin
                    case(k)
                        1: begin
                            temp_2 = matrix_array[target_row][target_column + 1];
                            matrix_array[target_row][target_column + 1] = 0;
                        end
                        2: begin
                            temp_2 = matrix_array[target_row + 1][target_column];
                            matrix_array[target_row + 1][target_column] = 0;
                        end
                        3: begin
                            temp_2 = matrix_array[target_row + 1][target_column + 1];
                            matrix_array[target_row + 1][target_column + 1] = 0;
                        end
                        default: temp_2 = 0;
                    endcase
                    if (temp_2 > temp_1) temp_1 = temp_2;
                    else                 temp_1 = temp_1;
                end
                matrix_array[i][j] = temp_1;
            end
        end
        size_data = size_data / 2;
    end
    // else(4x4) keep the same
end endtask

task horizontal_flip; begin
    for (j=0; j<change_num; j=j+1) begin
        couple_column = size_data - j - 1;
        for (i=0; i<size_data; i=i+1) begin
            temp_1 = matrix_array[i][j];
            temp_2 = matrix_array[i][couple_column];
            matrix_array[i][j] = temp_2;
            matrix_array[i][couple_column] = temp_1;
        end
    end
end endtask

task brightness_adjustment; begin
    for (i=0; i<size_data; i=i+1) begin
        for (j=0; j<size_data; j=j+1) begin
            temp_1 = matrix_array[i][j];
            matrix_array[i][j] = (temp_1 >>> 1) + 50; // arithmetic shift operator
        end
    end
end endtask

// find the position of maximum value
task find_maximum_matching; begin
    temp_3 = result_array[0][0];
    x_coordinate = 0;
    y_coordinate = 0;
    for (i=0; i<size_data; i=i+1) begin
        for (j=0; j<size_data; j=j+1) begin
            temp_4 = result_array[i][j];
            if (temp_4 > temp_3) begin
                temp_3 = temp_4;
                x_coordinate = i;
                y_coordinate = j;
            end
        end
    end
    // for check answer
    if      ((x_coordinate == 0) && (y_coordinate == 0))                     position_at = 4'd0;
    else if ((x_coordinate == 0) && (y_coordinate == size_data-1))           position_at = 4'd1;
    else if ((x_coordinate == size_data-1) && (y_coordinate == 0))           position_at = 4'd2;
    else if ((x_coordinate == size_data-1) && (y_coordinate == size_data-1)) position_at = 4'd3;
    else if (x_coordinate == 0)           position_at = 4'd4;
    else if (y_coordinate == 0)           position_at = 4'd5;
    else if (y_coordinate == size_data-1) position_at = 4'd6;
    else if (x_coordinate == size_data-1) position_at = 4'd7;
    else                                  position_at = 4'd8;
end endtask

//================================================================
// verification
//================================================================
task check_ans; begin
    position_step = 0;
    index_fail = 1;
    while(out_valid === 1) begin
        // check cross correlation result
        position_x = position_step / size_data;
        position_y = position_step % size_data;
        if (out_value !== result_array[position_x][position_y]) begin
            $display ("--------------------------------------------------------------------");
            $display ("                    PATTERN #%3d  FAILED!!!                         ", missioncount);
            $display ("          Your cross correlation result -> out_value: %d            ", out_value);
            $display ("        Golden cross correlation result -> out_value: %d            ", result_array[position_x][position_y]);
            $display ("                          position step -> %d                       ", position_step);	
            $display ("--------------------------------------------------------------------");
            repeat(2) @(negedge clk);		
            $finish;
        end

        // check the index of matching template positions
        pos_4 = (x_coordinate * size_data) + y_coordinate;
        pos_0 = ((x_coordinate - 1) * size_data) + y_coordinate - 1;
        pos_1 = ((x_coordinate - 1) * size_data) + y_coordinate;
        pos_2 = ((x_coordinate - 1) * size_data) + y_coordinate + 1;
        pos_3 = (x_coordinate * size_data) + y_coordinate - 1;
        pos_5 = (x_coordinate * size_data) + y_coordinate + 1;
        pos_6 = ((x_coordinate + 1) * size_data) + y_coordinate - 1;
        pos_7 = ((x_coordinate + 1) * size_data) + y_coordinate;
        pos_8 = ((x_coordinate + 1) * size_data) + y_coordinate + 1;

        case(position_at)
            8'd0: begin
                case(position_step)
                    8'd0: if (out_img_pos !== pos_4) begin index_fail = 1; golden_pos = pos_4; end else index_fail = 0;
                    8'd1: if (out_img_pos !== pos_5) begin index_fail = 1; golden_pos = pos_5; end else index_fail = 0;
                    8'd2: if (out_img_pos !== pos_7) begin index_fail = 1; golden_pos = pos_7; end else index_fail = 0;
                    8'd3: if (out_img_pos !== pos_8) begin index_fail = 1; golden_pos = pos_8; end else index_fail = 0;
                    default: if (out_img_pos !== 0)  begin index_fail = 1; golden_pos = 0;     end else index_fail = 0;
                endcase
            end
            8'd1: begin
                case(position_step)
                    8'd0: if (out_img_pos !== pos_3) begin index_fail = 1; golden_pos = pos_3; end else index_fail = 0;
                    8'd1: if (out_img_pos !== pos_4) begin index_fail = 1; golden_pos = pos_4; end else index_fail = 0;
                    8'd2: if (out_img_pos !== pos_6) begin index_fail = 1; golden_pos = pos_6; end else index_fail = 0;
                    8'd3: if (out_img_pos !== pos_7) begin index_fail = 1; golden_pos = pos_7; end else index_fail = 0;
                    default: if (out_img_pos !== 0)  begin index_fail = 1; golden_pos = 0;     end else index_fail = 0;
                endcase
            end
            8'd2: begin
                case(position_step)
                    8'd0: if (out_img_pos !== pos_1) begin index_fail = 1; golden_pos = pos_1; end else index_fail = 0;
                    8'd1: if (out_img_pos !== pos_2) begin index_fail = 1; golden_pos = pos_2; end else index_fail = 0;
                    8'd2: if (out_img_pos !== pos_4) begin index_fail = 1; golden_pos = pos_4; end else index_fail = 0;
                    8'd3: if (out_img_pos !== pos_5) begin index_fail = 1; golden_pos = pos_5; end else index_fail = 0;
                    default: if (out_img_pos !== 0)  begin index_fail = 1; golden_pos = 0;     end else index_fail = 0;
                endcase
            end
            8'd3: begin
                case(position_step)
                    8'd0: if (out_img_pos !== pos_0) begin index_fail = 1; golden_pos = pos_0; end else index_fail = 0;
                    8'd1: if (out_img_pos !== pos_1) begin index_fail = 1; golden_pos = pos_1; end else index_fail = 0;
                    8'd2: if (out_img_pos !== pos_3) begin index_fail = 1; golden_pos = pos_3; end else index_fail = 0;
                    8'd3: if (out_img_pos !== pos_4) begin index_fail = 1; golden_pos = pos_4; end else index_fail = 0;
                    default: if (out_img_pos !== 0)  begin index_fail = 1; golden_pos = 0;     end else index_fail = 0;
                endcase
            end
            8'd4: begin
                case(position_step)
                    8'd0: if (out_img_pos !== pos_3) begin index_fail = 1; golden_pos = pos_3; end else index_fail = 0;
                    8'd1: if (out_img_pos !== pos_4) begin index_fail = 1; golden_pos = pos_4; end else index_fail = 0;
                    8'd2: if (out_img_pos !== pos_5) begin index_fail = 1; golden_pos = pos_5; end else index_fail = 0;
                    8'd3: if (out_img_pos !== pos_6) begin index_fail = 1; golden_pos = pos_6; end else index_fail = 0;
                    8'd4: if (out_img_pos !== pos_7) begin index_fail = 1; golden_pos = pos_7; end else index_fail = 0;
                    8'd5: if (out_img_pos !== pos_8) begin index_fail = 1; golden_pos = pos_8; end else index_fail = 0;
                    default: if (out_img_pos !== 0)  begin index_fail = 1; golden_pos = 0;     end else index_fail = 0;
                endcase
            end
            8'd5: begin
                case(position_step)
                    8'd0: if (out_img_pos !== pos_1) begin index_fail = 1; golden_pos = pos_1; end else index_fail = 0;
                    8'd1: if (out_img_pos !== pos_2) begin index_fail = 1; golden_pos = pos_2; end else index_fail = 0;
                    8'd2: if (out_img_pos !== pos_4) begin index_fail = 1; golden_pos = pos_4; end else index_fail = 0;
                    8'd3: if (out_img_pos !== pos_5) begin index_fail = 1; golden_pos = pos_5; end else index_fail = 0;
                    8'd4: if (out_img_pos !== pos_7) begin index_fail = 1; golden_pos = pos_7; end else index_fail = 0;
                    8'd5: if (out_img_pos !== pos_8) begin index_fail = 1; golden_pos = pos_8; end else index_fail = 0;
                    default: if (out_img_pos !== 0)  begin index_fail = 1; golden_pos = 0;     end else index_fail = 0;
                endcase
            end
            8'd6: begin
                case(position_step)
                    8'd0: if (out_img_pos !== pos_0) begin index_fail = 1; golden_pos = pos_0; end else index_fail = 0;
                    8'd1: if (out_img_pos !== pos_1) begin index_fail = 1; golden_pos = pos_1; end else index_fail = 0;
                    8'd2: if (out_img_pos !== pos_3) begin index_fail = 1; golden_pos = pos_3; end else index_fail = 0;
                    8'd3: if (out_img_pos !== pos_4) begin index_fail = 1; golden_pos = pos_4; end else index_fail = 0;
                    8'd4: if (out_img_pos !== pos_6) begin index_fail = 1; golden_pos = pos_6; end else index_fail = 0;
                    8'd5: if (out_img_pos !== pos_7) begin index_fail = 1; golden_pos = pos_7; end else index_fail = 0;
                    default: if (out_img_pos !== 0)  begin index_fail = 1; golden_pos = 0;     end else index_fail = 0;
                endcase
            end
            8'd7: begin
                case(position_step)
                    8'd0: if (out_img_pos !== pos_0) begin index_fail = 1; golden_pos = pos_0; end else index_fail = 0;
                    8'd1: if (out_img_pos !== pos_1) begin index_fail = 1; golden_pos = pos_1; end else index_fail = 0;
                    8'd2: if (out_img_pos !== pos_2) begin index_fail = 1; golden_pos = pos_2; end else index_fail = 0;
                    8'd3: if (out_img_pos !== pos_3) begin index_fail = 1; golden_pos = pos_3; end else index_fail = 0;
                    8'd4: if (out_img_pos !== pos_4) begin index_fail = 1; golden_pos = pos_4; end else index_fail = 0;
                    8'd5: if (out_img_pos !== pos_5) begin index_fail = 1; golden_pos = pos_5; end else index_fail = 0;
                    default: if (out_img_pos !== 0)  begin index_fail = 1; golden_pos = 0;     end else index_fail = 0;
                endcase
            end
            8'd8: begin
                case(position_step)
                    8'd0: if (out_img_pos !== pos_0) begin index_fail = 1; golden_pos = pos_0; end else index_fail = 0;
                    8'd1: if (out_img_pos !== pos_1) begin index_fail = 1; golden_pos = pos_1; end else index_fail = 0;
                    8'd2: if (out_img_pos !== pos_2) begin index_fail = 1; golden_pos = pos_2; end else index_fail = 0;
                    8'd3: if (out_img_pos !== pos_3) begin index_fail = 1; golden_pos = pos_3; end else index_fail = 0;
                    8'd4: if (out_img_pos !== pos_4) begin index_fail = 1; golden_pos = pos_4; end else index_fail = 0;
                    8'd5: if (out_img_pos !== pos_5) begin index_fail = 1; golden_pos = pos_5; end else index_fail = 0;
                    8'd6: if (out_img_pos !== pos_6) begin index_fail = 1; golden_pos = pos_6; end else index_fail = 0;
                    8'd7: if (out_img_pos !== pos_7) begin index_fail = 1; golden_pos = pos_7; end else index_fail = 0;
                    8'd8: if (out_img_pos !== pos_8) begin index_fail = 1; golden_pos = pos_8; end else index_fail = 0;
                    default: if (out_img_pos !== 0)  begin index_fail = 1; golden_pos = 0;     end else index_fail = 0;
                endcase
            end
            default: if (out_img_pos !== 0)  begin index_fail = 1; golden_pos = 0; end else index_fail = 0;
        endcase
        
        if (index_fail == 1) begin
            $display ("--------------------------------------------------------------------");
            $display ("                    PATTERN #%3d  FAILED!!!                         ", missioncount);
            $display ("          Your matching template position -> out_img_pos: %d        ", out_img_pos);
            $display ("        Golden matching template position -> out_img_pos: %d        ", golden_pos);	
            $display ("--------------------------------------------------------------------");
            repeat(2) @(negedge clk);		
            $finish;
        end

        // check the coordinate of maximum value
        if ((out_x !== x_coordinate) || (out_y !== y_coordinate)) begin
            $display ("--------------------------------------------------------------------");
            $display ("                    PATTERN #%3d  FAILED!!!                         ", missioncount);
            $display ("             Your coordinate -> out_x: %d,  out_y: %d               ", out_x, out_y);
            $display ("           Golden coordinate -> out_x: %d,  out_y: %d               ", x_coordinate, y_coordinate);	
            $display ("--------------------------------------------------------------------");
            repeat(2) @(negedge clk);		
            $finish;
        end

        @(negedge clk);
        position_step = position_step + 1;
    end
    $display("\033[0;34mPASS PATTERN NO.%3d,\033[m \033[0;32mexecution cycle : %3d\033[m",missioncount ,latency);
end endtask

//================================================================
// mission completed
//================================================================
task you_pass_task; begin
        $display("\n");
        $display("\n");
        $display("        ----------------------------               ");
        $display("        --                        --       |\__||  ");
        $display("        --  Congratulations !!    --      / O.O  | ");
        $display("        --                        --    /_____   | ");
        $display("        --  \033[0;32mSimulation PASS!!\033[m     --   /^ ^ ^ \\  |");
        $display("        --                        --  |^ ^ ^ ^ |w| ");
        $display("        ----------------------------   \\m___m__|_|");
        $display("\n");

        repeat(2) @(negedge clk);
        $finish;
end endtask

endmodule