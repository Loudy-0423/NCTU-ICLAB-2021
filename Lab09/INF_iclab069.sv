//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2021 ICLAB Fall Course
//   Lab09      : PSG
//   Author     : Chih-Wei Peng
//                
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : INF.sv
//   Module Name : INF
//   Release version : v1.0 (Release Date: Nov-2021)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

interface INF(input clk);
	import      usertype::*;
	logic 	rst_n ; 
	logic   id_valid;
	logic   act_valid;
	logic   item_valid;
	logic   type_valid;
	logic	amnt_valid;
	DATA  	D;
	
	logic   	out_valid;
	logic 		complete;
	Error_Msg 	err_msg;
	logic[63:0] out_info;
	
	logic [7:0]  C_addr;
	logic [63:0] C_data_w;
	logic [63:0] C_data_r;
	logic C_in_valid;
	logic C_out_valid;
	logic C_r_wb;
	
	logic   AR_READY, R_VALID, AW_READY, W_READY, B_VALID,
	        AR_VALID, R_READY, AW_VALID, W_VALID, B_READY;
	logic [1:0]	 R_RESP, B_RESP;
    logic [63:0] R_DATA, W_DATA;
	logic [16:0] AW_ADDR, AR_ADDR;

    modport PATTERN(
	    input  clk,
		       out_valid, err_msg,  complete, out_info,
	    output rst_n,
			   D, id_valid, act_valid, item_valid, type_valid, amnt_valid
    );
	
    modport DRAM(
	    input  clk,
		       AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY,
	    output AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP
    );
	
	//  sub module port //
    modport pokemon_inf(
	    input  clk, rst_n,
			   D, id_valid, act_valid, item_valid, type_valid, amnt_valid,
			   C_out_valid, C_data_r,
        output out_valid, err_msg,  complete, out_info, 
			   C_addr, C_data_w, C_in_valid, C_r_wb
	);
		
    modport bridge_inf(
	    input  clk, rst_n,
		       C_addr, C_data_w, C_in_valid, C_r_wb,
			   AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP,
        output C_out_valid, C_data_r, 
		       AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY
    );
	
	//This will be used during demo
	//You can change the modport if you want to test the design independently
	modport PATTERN_pokemon(
	    input  clk, rst_n,
		       out_valid, err_msg,  complete, out_info, 
		       C_addr, C_data_w, C_in_valid, C_r_wb,
			   D, id_valid, act_valid, item_valid, type_valid, amnt_valid,
			   C_out_valid, C_data_r
    );
	
	//This will be used during demo
	//You can change the modport if you want to test the design independently
	modport PATTERN_bridge(
	    input  clk, rst_n, C_in_valid,
		       C_out_valid, C_data_r, AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY, 
			   C_addr, C_data_w, C_r_wb,
			   AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP
    );
	
	//Uncomment this for Lab10
	/*
	modport CHECKER(
	input  clk,rst_n,
			D, id_valid, act_valid, item_valid, type_valid, amnt_valid,
			out_valid, err_msg,  complete, out_info
    );
	*/

endinterface