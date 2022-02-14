//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//
//   File Name   : CHECKER.sv
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module Checker(input clk, INF.CHECKER inf);
import usertype::*;

//covergroup Spec1 @();
	
       //finish your covergroup here
	
	
//endgroup

//declare other cover group
covergroup Spec1 @(negedge clk);
	option.per_instance = 1;
   	//option.at_least = 20 ;
   	coverpoint inf.out_info[31:28] iff(inf.out_valid === 1/* && inf.D.d_act[0] !== Attack*/) {
		//option.per_instance = 1;
   		option.at_least = 20 ;
   		bins b1 = {No_stage} ;
		bins b2 = {Lowest} ;
		bins b3 = {Middle} ;
		bins b4 = {Highest} ;
   	}
    coverpoint inf.out_info[27:24] iff(inf.out_valid === 1/* && inf.D.d_act[0] === Attack*/) {
		option.at_least = 20 ;
   		bins b1 = {No_type} ;
		bins b2 = {Grass} ;
		bins b3 = {Fire} ;
		bins b4 = {Water} ;
		bins b5 = {Electric} ;
   	}
       //cross inf.out_info[31:28], inf.out_info[31:28];
endgroup : Spec1

covergroup Spec2 @(posedge clk );
	option.per_instance = 1;
   	//option.at_least = 10 ;
   	coverpoint inf.D.d_id[0] iff(inf.id_valid  === 1) {
		option.at_least = 10 ;
   		option.auto_bin_max = 256 ;
   	}
endgroup : Spec2

covergroup Spec3 @(posedge clk );
	option.per_instance = 1;
   	//option.at_least = 5 ;
   	coverpoint inf.D.d_act[0] iff(inf.act_valid  === 1) {
		option.at_least = 5 ;
   		bins b1[] = (Buy, Sell, Deposit, Check, Use_item, Attack => Buy, Sell, Deposit, Check, Use_item, Attack) ;
   	}
endgroup : Spec3

covergroup Spec4 @(negedge clk);
	option.per_instance = 1;
	//option.at_least = 200 ;
	coverpoint inf.complete iff(inf.out_valid  === 1) {
		option.at_least = 200 ;
		bins b1 = {0} ;
		bins b2 = {1} ;
	}
endgroup : Spec4

covergroup Spec5 @(negedge clk );
	option.per_instance = 1;
	//option.at_least = 20 ;
	coverpoint inf.err_msg iff(inf.out_valid  === 1) {
		option.at_least = 20 ;
		bins b1 = {Already_Have_PKM } ;
		bins b2 = {Out_of_money     } ;
		bins b3 = {Bag_is_full    	} ;
		bins b4 = {Not_Having_PKM   } ;
        bins b5 = {Has_Not_Grown    } ;
        bins b6 = {Not_Having_Item  } ;
        bins b7 = {HP_is_Zero       } ;
	}
endgroup : Spec5

//declare the cover group 
//Spec1 cov_inst_1 = new();
Spec1 cov_inst_1 = new();
Spec2 cov_inst_2 = new();
Spec3 cov_inst_3 = new();
Spec4 cov_inst_4 = new();
Spec5 cov_inst_5 = new();

//************************************ below assertion is to check your pattern ***************************************** 
//                                          Please finish and hand in it
// This is an example assertion given by TA, please write the required assertions below
//  assert_interval : assert property ( @(posedge clk)  inf.out_valid |=> inf.id_valid == 0 [*2])
//  else
//  begin
//  	$display("Assertion X is violated");
//  	$fatal; 
//  end

//write other assertions

always @(negedge inf.rst_n) begin
	#1;
	assert_1 : assert ((inf.out_valid === 0) && (inf.err_msg == No_Err) && (inf.complete === 0) && (inf.out_info === 0))
	else begin
		$display("Assertion 1 is violated");
		$fatal; 
	end
end

assert_2 : assert property ( @(posedge clk) (inf.complete === 1 && inf.out_valid === 1) |-> (inf.err_msg === No_Err) )
 else
 begin
 	$display("Assertion 2 is violated");
 	$fatal; 
 end

assert_3 : assert property ( @(posedge clk) (inf.complete === 0 && inf.out_valid === 1) |-> (inf.out_info === 0) )
else
begin
	$display("Assertion 3 is violated");
 	$fatal; 
end

/////////////////////////////////////////////////////////////////////
Action act ;
logic flag ;
always_ff @(posedge clk or negedge inf.rst_n)  begin
       if (!inf.rst_n) begin
           act <= No_action;   
       end				
	else begin 
		if (inf.act_valid == 1) begin
            act <= inf.D.d_act[0] ;   
        end	
	end
end

always_ff @(posedge clk or negedge inf.rst_n)  begin
       if (!inf.rst_n) begin
           flag <= 0;   
       end				
	else begin 
		if (inf.act_valid == 1) begin
            flag <= 1;   
        end	
		else if(inf.out_valid == 1) begin
			flag <= 0;  
		end
	end
end
/////////////////////////////////////////////////////////////////////

assert_4_1 : assert property ( @(posedge clk)  (inf.id_valid === 1 && flag == 0)  |=> ##[1:5] (inf.act_valid === 1) )  
else
begin
 	$display("Assertion 4 is violated");
 	$fatal; 
end

assert_4_2 : assert property ( @(posedge clk)  (inf.act_valid === 1 && inf.D.d_act[0] === Use_item)  |=> ##[1:5] (inf.item_valid===1) )  
else
begin
 	$display("Assertion 4 is violated");
 	$fatal; 
end

assert_4_3 : assert property ( @(posedge clk)  (inf.act_valid === 1 && inf.D.d_act[0] === Buy)  |=> ##[1:5] (inf.type_valid === 1 || inf.item_valid === 1) )  
else
begin
 	$display("Assertion 4 is violated");
 	$fatal; 
end

assert_4_4 : assert property ( @(posedge clk)  (inf.act_valid === 1 && inf.D.d_act[0] === Deposit)  |=> ##[1:5] (inf.amnt_valid === 1) )  
else
begin
 	$display("Assertion 4 is violated");
 	$fatal; 
end

assert_4_5 : assert property ( @(posedge clk)  (inf.act_valid === 1 && inf.D.d_act[0] === Attack)  |=> ##[1:5] (inf.id_valid === 1) )  
else
begin
 	$display("Assertion 4 is violated");
 	$fatal; 
end


logic no_one;
assign no_one = !( inf.id_valid || inf.act_valid || inf.item_valid || inf.type_valid || inf.amnt_valid ) ;


assert_5 : assert property ( @(posedge clk)   $onehot({ inf.id_valid, inf.act_valid, inf.item_valid, inf.type_valid, inf.amnt_valid , no_one }) )  
else
begin
 	$display("Assertion 5 is violated");
 	$fatal; 
end

assert_6 : assert property ( @(posedge clk)  (inf.out_valid === 1) |=> (inf.out_valid === 0) )
else
begin
	$display("Assertion 6 is violated");
	$fatal; 
end

assert_7 : assert property ( @(posedge clk) (inf.out_valid === 1)  |-> ##[2:10] ( inf.id_valid === 1 || inf.act_valid === 1) )  
else begin
 	$display("Assertion 7 is violated");
 	$fatal; 
end

assert_7_2 : assert property ( @(posedge clk)  inf.out_valid |-> ##1 (inf.id_valid | inf.act_valid) != 1)
else
begin
	$display("Assertion 7 is violated");
	$fatal; 
end

assert_8_1 : assert property ( @(posedge clk) ( act == Buy && (inf.type_valid === 1 || inf.item_valid === 1) ) |-> ( ##[1:1200] inf.out_valid === 1 ) )
else
begin
	$display("Assertion 8 is violated");
	$fatal; 
end

assert_8_2 : assert property ( @(posedge clk) ( act === Deposit && inf.amnt_valid === 1 ) |-> ( ##[1:1200] inf.out_valid === 1 ) )
else
begin
	$display("Assertion 8 is violated");
	$fatal; 
end

assert_8_3 : assert property ( @(posedge clk) ( act === Use_item && inf.item_valid === 1 ) |-> ( ##[1:1200] inf.out_valid===1 ) )
else
begin
	$display("Assertion 8 is violated");
	$fatal; 
end

assert_8_4 : assert property ( @(posedge clk) ( act === Attack && inf.id_valid === 1 ) |-> ( ##[1:1200] inf.out_valid === 1 ) )
else
begin
	$display("Assertion 8 is violated");
	$fatal; 
end

assert_8_5 : assert property ( @(posedge clk) ( act === Sell || act == Check ) |-> ( ##[1:1200] inf.out_valid===1 ) )
else
begin
	$display("Assertion 8 is violated");
	$fatal; 
end

endmodule