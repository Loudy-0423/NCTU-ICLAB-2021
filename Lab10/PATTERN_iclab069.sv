`ifdef RTL
`define CYCLE_TIME 5
`endif
`ifdef GATE
`define CYCLE_TIME 5
`endif


`include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype_PKG.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;




//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
integer   i, j, k, y, cycles, total_cycles;
integer   wait_val_time, total_latency;
parameter seed = 69 ;
parameter PATNUM = 8000 ;
parameter BASE_Addr = 65536 ;
integer patcount, temp;

integer color_stage = 0, color, r = 5, g = 0, b = 0 ;
//================================================================
// wire & registers 
//================================================================
logic [7:0] golden_DRAM[(65536+256*8)-1:65536+0];

Action golden_act;

logic has_given_id;

logic bracer_flag;

logic [5:0] atk_exp;
logic [4:0] def_exp;
logic change;
logic give;
logic [7:0] temp_atk, temp_stage, temp_bracer, temp_bracer_atk;
logic [7:0] past_id;

integer bracer_cnt;
//****  GOLDEN   ****//
Error_Msg     golden_err_msg;
logic         golden_complete;
logic [63:0]  golden_info;
logic [7:0]   golden_id, golden_op;
logic [16:0]  golden_DRAM_addr;
logic [15:0]  golden_money;

PKM_Type      golden_type;
Item          golden_item;
Player_Info   golden_player_info, golden_op_info, golden_sell_info, golden_use_info;

logic [63:0] golden_out_info;
//================================================================
// class random
//================================================================
class random_id;
        rand logic [7:0] ran_id;
        function new (int seed);
		    this.srandom(seed);		
	    endfunction 
        constraint range{
            ran_id inside{[0:255]};
        }
endclass


class random_act;
        rand Action ran_act;
        function new (int seed);
		    this.srandom(seed);		
	    endfunction 
        constraint range{
            ran_act inside{Buy, Sell, Deposit, Use_item, Check, Attack};
        }
endclass


class rand_delay;	
	rand int delay;
	function new (int seed);
		this.srandom(seed);		
	endfunction 
	constraint limit { delay inside {[1:3]}; }
endclass

class rand_gap;	
	rand int gap;
	function new (int seed);
		this.srandom(seed);		
	endfunction 
	constraint limit { gap inside {[2:8]}; }
endclass

class rand_give_id;
	rand int give_id;
	function new (int seed);
		this.srandom(seed);		
	endfunction 
	constraint limit { give_id inside {[0:1]}; }
endclass



class rand_type_or_item;
	rand int type_or_item;
	function new (int seed);
		this.srandom(seed);		
	endfunction 
	constraint limit { type_or_item inside {[0:1]}; } //0 for type / 1 for item
endclass


class rand_type;
	rand PKM_Type ran_type;
        function new (int seed);
		    this.srandom(seed);		
	    endfunction 
        constraint range{
            ran_type inside{Grass, Fire, Water, Electric};
        }
endclass

class rand_item;
	rand Item ran_item;
        function new (int seed);
		    this.srandom(seed);		
	    endfunction 
        constraint range{
            ran_item inside{Berry, Medicine, Candy, Bracer};
        }
endclass

class rand_money;
	rand Item ran_money;
        function new (int seed);
		    this.srandom(seed);		
	    endfunction 
        constraint range{
            ran_money inside{[1:65535]};
        }
endclass

//================================================================
// initial
//================================================================

random_id            r_id           =  new(seed);
random_act           r_act          =  new(seed);
rand_delay           r_delay        =  new(seed);
rand_gap             r_gap          =  new(seed);
rand_type            r_type         =  new(seed);
rand_item            r_item         =  new(seed);
rand_give_id         r_give_id      =  new(seed);
rand_type_or_item    r_type_or_item =  new(seed);
rand_money           r_money        =  new(seed);


initial begin

    $readmemh(DRAM_p_r, golden_DRAM);

	inf.rst_n = 1'b1 ;
	inf.id_valid = 1'b0 ;
	inf.act_valid = 1'b0 ;
	inf.item_valid = 1'b0 ;
	inf.type_valid = 1'b0 ;
    inf.amnt_valid = 1'b0 ; 
	inf.D = 'bx;

    has_given_id = 1'b0 ;
    bracer_flag = 1'b0 ;

    total_cycles = 0 ;
    reset_signal_task;


    @(negedge clk);
	for( patcount=0 ; patcount<PATNUM ; patcount+=1 ) begin


        
        r_type_or_item.randomize();
		r_act.randomize();		// which action
        golden_act  = r_act.ran_act ;
				
		
		case(golden_act)
			Buy: begin
				Buy_task;
			end
			Sell: begin
				Sell_task;
			end
			Deposit: begin
				Deposit_task;
			end
			Use_item: begin
				Use_item_task;
			end
			Check: begin
				Check_task;
			end
            Attack: begin
				Attack_task;
			end
		endcase

        get_player_info_task;
        get_op_info_task;

        wait_outvalid_task;
        output_task;
        gap_task;
        /*
        case(color_stage)
            0: begin
                r = r - 1;
                g = g + 1;
                if(r == 0) color_stage = 1;
            end
            1: begin
                g = g - 1;
                b = b + 1;
                if(g == 0) color_stage = 2;
            end
            2: begin
                b = b - 1;
                r = r + 1;
                if(b == 0) color_stage = 0;
            end
        endcase

        color = 16 + r*36 + g*6 + b;

        if(color < 100) begin
            $display("\033[38;5;%2dmPASS PATTERN NO.%4d\033[00m", color, patcount+1);
        end 
        else begin
            $display("\033[38;5;%3dmPASS PATTERN NO.%4d\033[00m", color, patcount+1);
        end */
		
	end
    //pass_task;
    $finish;
end

//================================================================
// task definition - 1
//================================================================

task give_id_task; begin
    r_give_id.randomize();		// whether to give id
    give = r_give_id.give_id;   // give=1 : give new id
    //@(negedge clk);
	if( give == 1 || has_given_id == 0) begin
		r_id.randomize();		// which id to give
		golden_id = r_id.ran_id ;
        while(past_id === golden_id) begin
            r_id.randomize();		// which id to give
		    golden_id = r_id.ran_id ;
        end
        past_id = golden_id;
		// 
		inf.id_valid = 1'b1 ;
		// 
		inf.D = { 8'd0 , golden_id } ;
		// 
		@(negedge clk);
		inf.id_valid = 1'b0 ;
		inf.D = 'bx ;
        @(negedge clk);
        has_given_id = 1'b1 ;
        get_player_info_task;
        bracer_flag = 0;
        change = 1;
	end
end endtask


task give_op_task; begin
	r_id.randomize();
    // which id to give
	golden_op = r_id.ran_id ;
    while (golden_op === golden_id) begin
        r_id.randomize();
        golden_op = r_id.ran_id ;
    end
	// 
	inf.id_valid = 1'b1 ;
	// 
	inf.D = { 8'd0 , golden_op } ;
	// 
	@(negedge clk);
	inf.id_valid = 1'b0 ;
	inf.D = 'bx ;
    @(negedge clk);
end endtask


task get_player_info_task; begin
	golden_player_info.bag_info.berry_num    = golden_DRAM[BASE_Addr+golden_id*8 + 0][7:4] ;
    golden_player_info.bag_info.medicine_num = golden_DRAM[BASE_Addr+golden_id*8 + 0][3:0] ;
    golden_player_info.bag_info.candy_num    = golden_DRAM[BASE_Addr+golden_id*8 + 1][7:4] ;
    golden_player_info.bag_info.bracer_num   = golden_DRAM[BASE_Addr+golden_id*8 + 1][3:0] ;
    golden_player_info.bag_info.money        = {golden_DRAM[BASE_Addr+golden_id*8 + 2], golden_DRAM[BASE_Addr+golden_id*8 + 3]};

    golden_player_info.pkm_info.stage     = golden_DRAM[BASE_Addr+golden_id*8 + 4][7:4] ;
    golden_player_info.pkm_info.pkm_type  = golden_DRAM[BASE_Addr+golden_id*8 + 4][3:0] ;
    golden_player_info.pkm_info.hp        = golden_DRAM[BASE_Addr+golden_id*8 + 5] ;
    golden_player_info.pkm_info.atk       = golden_DRAM[BASE_Addr+golden_id*8 + 6] ;
    golden_player_info.pkm_info.exp       = golden_DRAM[BASE_Addr+golden_id*8 + 7] ;

end endtask


task get_op_info_task; begin
	golden_op_info.bag_info.berry_num    = golden_DRAM[BASE_Addr+golden_op*8 + 0][7:4] ;
    golden_op_info.bag_info.medicine_num = golden_DRAM[BASE_Addr+golden_op*8 + 0][3:0] ;
    golden_op_info.bag_info.candy_num    = golden_DRAM[BASE_Addr+golden_op*8 + 1][7:4] ;
    golden_op_info.bag_info.bracer_num   = golden_DRAM[BASE_Addr+golden_op*8 + 1][3:0] ;
    golden_op_info.bag_info.money        = {golden_DRAM[BASE_Addr+golden_op*8 + 2], golden_DRAM[BASE_Addr+golden_op*8 + 3]};

    golden_op_info.pkm_info.stage     = golden_DRAM[BASE_Addr+golden_op*8 + 4][7:4] ;
    golden_op_info.pkm_info.pkm_type  = golden_DRAM[BASE_Addr+golden_op*8 + 4][3:0] ;
    golden_op_info.pkm_info.hp        = golden_DRAM[BASE_Addr+golden_op*8 + 5] ;
    golden_op_info.pkm_info.atk       = golden_DRAM[BASE_Addr+golden_op*8 + 6] ;
    golden_op_info.pkm_info.exp       = golden_DRAM[BASE_Addr+golden_op*8 + 7] ;
end endtask


task Buy_task; begin
    if(r_type_or_item.type_or_item == 0) begin
        r_item.randomize();
        golden_item = r_item.ran_item;
    end
    else begin
        r_type.randomize();
        golden_type = r_type.ran_type;
    end
	// id
	give_id_task;
	if(give == 1 || has_given_id == 0) begin
        delay_task;
    end

	// action
	inf.act_valid = 1'b1 ;
	inf.D = golden_act ;
    @(negedge clk);
	inf.act_valid = 1'b0 ;
	inf.D = 'bx ;
	@(negedge clk);

    // type or item
    if(r_type_or_item.type_or_item == 0) begin
        inf.item_valid = 1'b1;
	    inf.D = golden_item;
        @(negedge clk);
	    inf.item_valid = 1'b0 ;
	    inf.D = 'bx ;
    end
    else begin
        inf.type_valid = 1'b1;
	    inf.D = golden_type;
        @(negedge clk);
	    inf.type_valid = 1'b0 ;
	    inf.D = 'bx ;
    end

	if(r_type_or_item.type_or_item == 0) begin
        if(golden_item == Berry) begin
            if(golden_player_info.bag_info.money < 16) begin
                //$display("Out_of_money");
		        golden_complete = 1'b0 ;
		        golden_err_msg = Out_of_money ;
            end
            else if(golden_player_info.bag_info.berry_num == 15) begin
                //$display("Bag_is_full");
		        golden_complete = 1'b0 ;
		        golden_err_msg = Bag_is_full ;
            end
            else begin
                //$display("Successful");
                golden_complete = 1'b1 ;
		        golden_err_msg = No_Err ; 
                golden_player_info.bag_info.money = golden_player_info.bag_info.money-16;
                golden_player_info.bag_info.berry_num = golden_player_info.bag_info.berry_num+1;
                {golden_DRAM[BASE_Addr+golden_id*8 + 2], golden_DRAM[BASE_Addr+golden_id*8 + 3]} = golden_player_info.bag_info.money;
                golden_DRAM[BASE_Addr+golden_id*8 + 0][7:4] = golden_player_info.bag_info.berry_num;
            end
        end
        else if(golden_item == Medicine) begin
            if(golden_player_info.bag_info.money < 128) begin
                //$display("Out_of_money");
		        golden_complete = 1'b0 ;
		        golden_err_msg = Out_of_money ;
            end
            else if(golden_player_info.bag_info.medicine_num == 15) begin
                //$display("Bag_is_full");
		        golden_complete = 1'b0 ;
		        golden_err_msg = Bag_is_full ;
                
            end
            else begin
                //$display("Successful");
                golden_complete = 1'b1 ;
		        golden_err_msg = No_Err ; 
                golden_player_info.bag_info.money = golden_player_info.bag_info.money-128;
                golden_player_info.bag_info.medicine_num = golden_player_info.bag_info.medicine_num+1;
                {golden_DRAM[BASE_Addr+golden_id*8 + 2], golden_DRAM[BASE_Addr+golden_id*8 + 3]} = golden_player_info.bag_info.money;

                golden_DRAM[BASE_Addr+golden_id*8 + 0][3:0] = golden_player_info.bag_info.medicine_num;
            end
        end
        else if(golden_item == Candy) begin
            if(golden_player_info.bag_info.money < 300) begin
                //$display("Out_of_money");
		        golden_complete = 1'b0 ;
		        golden_err_msg = Out_of_money ;
            end
            else if(golden_player_info.bag_info.candy_num == 15) begin
                //$display("Bag_is_full");
		        golden_complete = 1'b0 ;
		        golden_err_msg = Bag_is_full ;
            end
            else begin
                //$display("Successful");
                golden_complete = 1'b1 ;
		        golden_err_msg = No_Err ; 
                golden_player_info.bag_info.money = golden_player_info.bag_info.money-300;
                golden_player_info.bag_info.candy_num = golden_player_info.bag_info.candy_num+1;
                {golden_DRAM[BASE_Addr+golden_id*8 + 2], golden_DRAM[BASE_Addr+golden_id*8 + 3]} = golden_player_info.bag_info.money;
                golden_DRAM[BASE_Addr+golden_id*8 + 1][7:4] = golden_player_info.bag_info.candy_num;
            end
        end
        else if(golden_item == Bracer) begin
            if(golden_player_info.bag_info.money < 64) begin
                //$display("Out_of_money");
		        golden_complete = 1'b0 ;
		        golden_err_msg = Out_of_money ;
            end
            else if(golden_player_info.bag_info.bracer_num == 15) begin
                //$display("Bag_is_full");
		        golden_complete = 1'b0 ;
		        golden_err_msg = Bag_is_full ;
            end
            else begin
                //$display("Successful");
                golden_complete = 1'b1 ;
		        golden_err_msg = No_Err ; 
                golden_player_info.bag_info.money = golden_player_info.bag_info.money-64;
                golden_player_info.bag_info.bracer_num = golden_player_info.bag_info.bracer_num+1;
                {golden_DRAM[BASE_Addr+golden_id*8 + 2], golden_DRAM[BASE_Addr+golden_id*8 + 3]} = golden_player_info.bag_info.money;
                golden_DRAM[BASE_Addr+golden_id*8 + 1][3:0] = golden_player_info.bag_info.bracer_num;
            end
        end
    end

    else begin
        if(golden_type == Grass) begin
            if(golden_player_info.bag_info.money < 100) begin
                //$display("Out_of_money");
		        golden_complete = 1'b0 ;
		        golden_err_msg = Out_of_money ; 
            end
            else if(golden_player_info.pkm_info.pkm_type !=  No_type) begin
                //$display("Already_Have_PKM");
		        golden_complete = 1'b0 ;
		        golden_err_msg = Already_Have_PKM ; 
            end
            else begin
                //$display("Successful");
                golden_complete = 1'b1 ;
		        golden_err_msg = No_Err ; 
                golden_player_info.bag_info.money = golden_player_info.bag_info.money-100;
                golden_player_info.pkm_info = {Lowest, Grass, 8'd128, 8'd63, 8'd0};
                {golden_DRAM[BASE_Addr+golden_id*8 + 2], golden_DRAM[BASE_Addr+golden_id*8 + 3]} = golden_player_info.bag_info.money;
                {golden_DRAM[BASE_Addr+golden_id*8 + 4], golden_DRAM[BASE_Addr+golden_id*8 + 5], golden_DRAM[BASE_Addr+golden_id*8 + 6], golden_DRAM[BASE_Addr+golden_id*8 + 7]} = golden_player_info.pkm_info;
            end
        end
        else if(golden_type == Fire) begin
            if(golden_player_info.bag_info.money < 90) begin
                //$display("Out_of_money");
		        golden_complete = 1'b0 ;
		        golden_err_msg = Out_of_money ; 
            end
            else if(golden_player_info.pkm_info.pkm_type !=  No_type) begin
                //$display("Already_Have_PKM");
		        golden_complete = 1'b0 ;
		        golden_err_msg = Already_Have_PKM ; 
            end
            else begin
                //$display("Successful");
                golden_complete = 1'b1 ;
		        golden_err_msg = No_Err ; 
                golden_player_info.bag_info.money = golden_player_info.bag_info.money-90;
                golden_player_info.pkm_info = {Lowest, Fire, 8'd119, 8'd64, 8'd0};
                {golden_DRAM[BASE_Addr+golden_id*8 + 2], golden_DRAM[BASE_Addr+golden_id*8 + 3]} = golden_player_info.bag_info.money;
                {golden_DRAM[BASE_Addr+golden_id*8 + 4], golden_DRAM[BASE_Addr+golden_id*8 + 5], golden_DRAM[BASE_Addr+golden_id*8 + 6], golden_DRAM[BASE_Addr+golden_id*8 + 7]} = golden_player_info.pkm_info;
            end
        end
        else if(golden_type == Water) begin
            if(golden_player_info.bag_info.money < 110) begin
                //$display("Out_of_money");
		        golden_complete = 1'b0 ;
		        golden_err_msg = Out_of_money ; 
            end
            else if(golden_player_info.pkm_info.pkm_type !=  No_type) begin
                //$display("Already_Have_PKM");
		        golden_complete = 1'b0 ;
		        golden_err_msg = Already_Have_PKM ; 
            end 
            else begin
                //$display("Successful");
                golden_complete = 1'b1 ;
		        golden_err_msg = No_Err ; 
                golden_player_info.bag_info.money = golden_player_info.bag_info.money-110;
                golden_player_info.pkm_info = {Lowest, Water, 8'd125, 8'd60, 8'd0};
                {golden_DRAM[BASE_Addr+golden_id*8 + 2], golden_DRAM[BASE_Addr+golden_id*8 + 3]} = golden_player_info.bag_info.money;
                {golden_DRAM[BASE_Addr+golden_id*8 + 4], golden_DRAM[BASE_Addr+golden_id*8 + 5], golden_DRAM[BASE_Addr+golden_id*8 + 6], golden_DRAM[BASE_Addr+golden_id*8 + 7]} = golden_player_info.pkm_info;
            end
        end
        else if(golden_type == Electric) begin
            if(golden_player_info.bag_info.money < 120) begin
                //$display("Out_of_money");
		        golden_complete = 1'b0 ;
		        golden_err_msg = Out_of_money ; 
            end
            else if(golden_player_info.pkm_info.pkm_type !=  No_type) begin
                //$display("Already_Have_PKM");
		        golden_complete = 1'b0 ;
		        golden_err_msg = Already_Have_PKM ; 
            end
            else begin
                //$display("Successful");
                golden_complete = 1'b1 ;
		        golden_err_msg = No_Err ; 
                golden_player_info.bag_info.money = golden_player_info.bag_info.money-120;
                golden_player_info.pkm_info = {Lowest, Electric, 8'd122, 8'd65, 8'd0};
                {golden_DRAM[BASE_Addr+golden_id*8 + 2], golden_DRAM[BASE_Addr+golden_id*8 + 3]} = golden_player_info.bag_info.money;
                {golden_DRAM[BASE_Addr+golden_id*8 + 4], golden_DRAM[BASE_Addr+golden_id*8 + 5], golden_DRAM[BASE_Addr+golden_id*8 + 6], golden_DRAM[BASE_Addr+golden_id*8 + 7]} = golden_player_info.pkm_info;
            end
        end
    end
end 
endtask


task Sell_task; begin

	// id
	give_id_task;
    
	if(give == 1 || has_given_id == 0) begin
        delay_task;
    end

	// action
	inf.act_valid = 1'b1 ;
	inf.D = golden_act ;
    @(negedge clk);
	inf.act_valid = 1'b0 ;
	inf.D = 'bx ;
	@(negedge clk);

    if(golden_player_info.pkm_info.pkm_type ==  No_type) begin
        //$display("Out_of_money");
		golden_complete = 1'b0 ;
		golden_err_msg = Not_Having_PKM ; 
    end
    else if(golden_player_info.pkm_info.stage == Lowest) begin
        //$display("Out_of_money");
		golden_complete = 1'b0 ;
		golden_err_msg = Has_Not_Grown ; 
    end
    else begin

        //$display("Successful");
        golden_sell_info.pkm_info = golden_player_info.pkm_info;
        
        golden_complete = 1'b1 ;
        golden_err_msg = No_Err ;

        case(golden_player_info.pkm_info.pkm_type)
            Grass: begin
                if(golden_player_info.pkm_info.stage == Middle) begin
                    golden_player_info.bag_info.money = golden_player_info.bag_info.money+510;
                end
                else if(golden_player_info.pkm_info.stage == Highest) begin
                    golden_player_info.bag_info.money = golden_player_info.bag_info.money+1100;
                end
            end
            Fire: begin
                if(golden_player_info.pkm_info.stage == Middle) begin
                    golden_player_info.bag_info.money = golden_player_info.bag_info.money+450;
                end
                else if(golden_player_info.pkm_info.stage == Highest) begin
                    golden_player_info.bag_info.money = golden_player_info.bag_info.money+1000;
                end
            end
            Water: begin
                if(golden_player_info.pkm_info.stage == Middle) begin
                    golden_player_info.bag_info.money = golden_player_info.bag_info.money+500;
                end
                else if(golden_player_info.pkm_info.stage == Highest) begin
                    golden_player_info.bag_info.money = golden_player_info.bag_info.money+1200;
                end
            end
            Electric: begin
                if(golden_player_info.pkm_info.stage == Middle) begin
                    golden_player_info.bag_info.money = golden_player_info.bag_info.money+550;
                end
                else if(golden_player_info.pkm_info.stage == Highest) begin
                    golden_player_info.bag_info.money = golden_player_info.bag_info.money+1300;
                end
            end
        endcase
        
        golden_player_info.pkm_info = {No_stage, No_type, 8'd0, 8'd0, 8'd0};
        {golden_DRAM[BASE_Addr+golden_id*8 + 2], golden_DRAM[BASE_Addr+golden_id*8 + 3]} = golden_player_info.bag_info.money;
        {golden_DRAM[BASE_Addr+golden_id*8 + 4], golden_DRAM[BASE_Addr+golden_id*8 + 5], golden_DRAM[BASE_Addr+golden_id*8 + 6], golden_DRAM[BASE_Addr+golden_id*8 + 7]} = golden_player_info.pkm_info;
    end
end 
endtask


task Deposit_task; begin
    r_money.randomize();
    golden_money = r_money.ran_money ;

    while (golden_player_info.bag_info.money + golden_money > 65536) begin
        r_money.randomize();
        golden_money = r_money.ran_money ;
    end
    give_id_task;
	if(give == 1 || has_given_id == 0) begin
        
        delay_task;
    end

    if( give == 1 || has_given_id == 1) begin
        get_player_info_task;
    end

	// action
	inf.act_valid = 1'b1 ;
	inf.D = golden_act ;
    @(negedge clk);
	inf.act_valid = 1'b0 ;
	inf.D = 'bx ;
	delay_task;

    inf.amnt_valid = 1'b1 ;
	inf.D = golden_money ;
    @(negedge clk);
	inf.amnt_valid = 1'b0 ;
	inf.D = 'bx ;
	@(negedge clk);

    golden_complete = 1'b1 ;
    golden_err_msg = No_Err ;
    golden_player_info.bag_info.money = golden_player_info.bag_info.money + golden_money;

    {golden_DRAM[BASE_Addr+golden_id*8 + 2], golden_DRAM[BASE_Addr+golden_id*8 + 3]} = golden_player_info.bag_info.money;
    
end 
endtask


task Check_task; begin

	// id
	give_id_task;
    
    if(give == 1 || has_given_id == 0) begin
        delay_task;
    end


	// action
	inf.act_valid = 1'b1 ;
	inf.D = golden_act ;
    @(negedge clk);
	inf.act_valid = 1'b0 ;
	inf.D = 'bx ;
	@(negedge clk);

    golden_complete = 1'b1 ;
    golden_err_msg = No_Err ;

end 
endtask


task Use_item_task; begin

	// id
	give_id_task;
    //@(negedge clk);
	if(give == 1 || has_given_id == 0) begin
        delay_task;
    end
    bracer_cnt = bracer_cnt+1;

    r_item.randomize();
    golden_item = r_item.ran_item;

	// action
	inf.act_valid = 1'b1 ;
	inf.D = golden_act ;
    
    @(negedge clk);
	inf.act_valid = 1'b0 ;
	inf.D = 'bx ;
    @(negedge clk);
	delay_task;
    

    inf.item_valid = 1'b1;
	inf.D = golden_item ;
    @(negedge clk);
	inf.item_valid = 1'b0 ;
	inf.D = 'bx ;

    @(negedge clk);

    case(golden_item)
        Berry: begin
            if(golden_player_info.pkm_info.pkm_type ==  No_type) begin
                //$display("Not_Having_PKM");
		        golden_complete = 1'b0 ;
		        golden_err_msg = Not_Having_PKM ;
            end
            else if(golden_player_info.bag_info.berry_num < 1) begin
                //$display("Not_Having_Item");
		        golden_complete = 1'b0 ;
		        golden_err_msg = Not_Having_Item ;
            end
            else begin
                case(golden_player_info.pkm_info.stage)
                    Lowest: begin
                        case(golden_player_info.pkm_info.pkm_type)
                            Grass: begin
                                if(golden_player_info.pkm_info.hp < 96) begin
                                    golden_player_info.pkm_info.hp = golden_player_info.pkm_info.hp+32;
                                end
                                else begin
                                    golden_player_info.pkm_info.hp = 128;
                                end
                            end
                            Fire: begin
                                if(golden_player_info.pkm_info.hp < 87) begin
                                    golden_player_info.pkm_info.hp = golden_player_info.pkm_info.hp+32;
                                end
                                else begin
                                    golden_player_info.pkm_info.hp = 119;
                                end
                            end
                            Water: begin
                                if(golden_player_info.pkm_info.hp < 93) begin
                                    golden_player_info.pkm_info.hp = golden_player_info.pkm_info.hp+32;
                                end
                                else begin
                                    golden_player_info.pkm_info.hp = 125;
                                end
                            end
                            Electric: begin
                                if(golden_player_info.pkm_info.hp < 90) begin
                                    golden_player_info.pkm_info.hp = golden_player_info.pkm_info.hp+32;
                                end
                                else begin
                                    golden_player_info.pkm_info.hp = 122;
                                end
                            end
                        endcase
                    end
                    Middle: begin
                        case(golden_player_info.pkm_info.pkm_type)
                            Grass: begin
                                if(golden_player_info.pkm_info.hp < 160) begin
                                    golden_player_info.pkm_info.hp = golden_player_info.pkm_info.hp+32;
                                end
                                else begin
                                    golden_player_info.pkm_info.hp = 192;
                                end
                            end
                            Fire: begin
                                if(golden_player_info.pkm_info.hp < 145) begin
                                    golden_player_info.pkm_info.hp = golden_player_info.pkm_info.hp+32;
                                end
                                else begin
                                    golden_player_info.pkm_info.hp = 177;
                                end
                            end
                            Water: begin
                                if(golden_player_info.pkm_info.hp < 155) begin
                                    golden_player_info.pkm_info.hp = golden_player_info.pkm_info.hp+32;
                                end
                                else begin
                                    golden_player_info.pkm_info.hp = 187;
                                end
                            end
                            Electric: begin
                                if(golden_player_info.pkm_info.hp < 150) begin
                                    golden_player_info.pkm_info.hp = golden_player_info.pkm_info.hp+32;
                                end
                                else begin
                                    golden_player_info.pkm_info.hp = 182;
                                end
                            end
                        endcase
                    end
                    Highest: begin
                        case(golden_player_info.pkm_info.pkm_type)
                            Grass: begin
                                if(golden_player_info.pkm_info.hp < 222) begin
                                    golden_player_info.pkm_info.hp = golden_player_info.pkm_info.hp+32;
                                end
                                else begin
                                    golden_player_info.pkm_info.hp = 254;
                                end
                            end
                            Fire: begin
                                if(golden_player_info.pkm_info.hp < 193) begin
                                    golden_player_info.pkm_info.hp = golden_player_info.pkm_info.hp+32;
                                end
                                else begin
                                    golden_player_info.pkm_info.hp = 225;
                                end
                            end
                            Water: begin
                                if(golden_player_info.pkm_info.hp < 213) begin
                                    golden_player_info.pkm_info.hp = golden_player_info.pkm_info.hp+32;
                                end
                                else begin
                                    golden_player_info.pkm_info.hp = 245;
                                end
                            end
                            Electric: begin
                                if(golden_player_info.pkm_info.hp < 203) begin
                                    golden_player_info.pkm_info.hp = golden_player_info.pkm_info.hp+32;
                                end
                                else begin
                                    golden_player_info.pkm_info.hp = 235;
                                end
                            end
                        endcase
                    end
                endcase
                //$display("Successful");
                golden_complete = 1'b1 ;
		        golden_err_msg = No_Err ;
                golden_player_info.bag_info.berry_num = golden_player_info.bag_info.berry_num-1;

                golden_DRAM[BASE_Addr+golden_id*8 + 0][7:4] = golden_player_info.bag_info.berry_num;
                {golden_DRAM[BASE_Addr+golden_id*8 + 4], golden_DRAM[BASE_Addr+golden_id*8 + 5], golden_DRAM[BASE_Addr+golden_id*8 + 6], golden_DRAM[BASE_Addr+golden_id*8 + 7]} = golden_player_info.pkm_info;
            end
        end
        Medicine: begin
            if(golden_player_info.pkm_info.pkm_type ==  No_type) begin
                //$display("Not_Having_PKM");
		        golden_complete = 1'b0 ;
		        golden_err_msg = Not_Having_PKM ;
            end
            else if(golden_player_info.bag_info.medicine_num < 1) begin
                //$display("Not_Having_Item");
		        golden_complete = 1'b0 ;
		        golden_err_msg = Not_Having_Item ;
            end
            else begin
                case(golden_player_info.pkm_info.stage)
                    Lowest: begin
                        case(golden_player_info.pkm_info.pkm_type)
                            Grass: begin
                                golden_player_info.pkm_info.hp = 128;
                            end
                            Fire: begin
                                golden_player_info.pkm_info.hp = 119;
                            end
                            Water: begin
                                golden_player_info.pkm_info.hp = 125;
                            end
                            Electric: begin
                                golden_player_info.pkm_info.hp = 122;
                            end
                        endcase
                    end
                    Middle: begin
                        case(golden_player_info.pkm_info.pkm_type)
                            Grass: begin
                                golden_player_info.pkm_info.hp = 192;
                            end
                            Fire: begin
                                golden_player_info.pkm_info.hp = 177;
                            end
                            Water: begin
                                golden_player_info.pkm_info.hp = 187;
                            end
                            Electric: begin
                                golden_player_info.pkm_info.hp = 182;
                            end
                        endcase
                    end
                    Highest: begin
                        case(golden_player_info.pkm_info.pkm_type)
                            Grass: begin
                                golden_player_info.pkm_info.hp = 254;
                            end
                            Fire: begin
                                golden_player_info.pkm_info.hp = 225;
                            end
                            Water: begin
                                golden_player_info.pkm_info.hp = 245;
                            end
                            Electric: begin
                                golden_player_info.pkm_info.hp = 235;
                            end
                        endcase
                    end
                endcase
                //$display("Successful");
                golden_complete = 1'b1 ;
		        golden_err_msg = No_Err ;
                golden_player_info.bag_info.medicine_num = golden_player_info.bag_info.medicine_num-1;

                golden_DRAM[BASE_Addr+golden_id*8 + 0][3:0] = golden_player_info.bag_info.medicine_num;
                {golden_DRAM[BASE_Addr+golden_id*8 + 4], golden_DRAM[BASE_Addr+golden_id*8 + 5], golden_DRAM[BASE_Addr+golden_id*8 + 6], golden_DRAM[BASE_Addr+golden_id*8 + 7]} = golden_player_info.pkm_info;
            end
        end
        Candy: begin
            if(golden_player_info.pkm_info.pkm_type ==  No_type) begin
                //$display("Not_Having_PKM");
		        golden_complete = 1'b0 ;
		        golden_err_msg = Not_Having_PKM ;
            end
            else if(golden_player_info.bag_info.candy_num < 1) begin
                //$display("Not_Having_Item");
		        golden_complete = 1'b0 ;
		        golden_err_msg = Not_Having_Item ;
            end
            else begin
                case(golden_player_info.pkm_info.stage)
                    Lowest: begin
                        case(golden_player_info.pkm_info.pkm_type)
                            Grass: begin
                                if(golden_player_info.pkm_info.exp < 17) begin
                                    golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+15;
                                end
                                else begin
                                    golden_player_info.pkm_info.exp = 0;
                                    golden_player_info.pkm_info.stage = Middle;
                                    golden_player_info.pkm_info.hp = 192;
                                    golden_player_info.pkm_info.atk = 94;
                                    bracer_flag=0;
                                end
                            end
                            Fire: begin
                                if(golden_player_info.pkm_info.exp < 15) begin
                                    golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+15;
                                end
                                else begin
                                    golden_player_info.pkm_info.exp = 0;
                                    golden_player_info.pkm_info.stage = Middle;
                                    golden_player_info.pkm_info.hp = 177;
                                    golden_player_info.pkm_info.atk = 96;
                                    bracer_flag=0;
                                end
                            end
                            Water: begin
                                if(golden_player_info.pkm_info.exp < 13) begin
                                    golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+15;
                                end
                                else begin
                                    golden_player_info.pkm_info.exp = 0;
                                    golden_player_info.pkm_info.stage = Middle;
                                    golden_player_info.pkm_info.hp = 187;
                                    golden_player_info.pkm_info.atk = 89;
                                    bracer_flag=0;
                                end
                            end
                            Electric: begin
                                if(golden_player_info.pkm_info.exp < 11) begin
                                    golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+15;
                                end
                                else begin
                                    golden_player_info.pkm_info.exp = 0;
                                    golden_player_info.pkm_info.stage = Middle;
                                    golden_player_info.pkm_info.hp = 182;
                                    golden_player_info.pkm_info.atk = 97;
                                    bracer_flag=0;
                                end
                            end
                        endcase
                    end
                    Middle: begin
                        case(golden_player_info.pkm_info.pkm_type)
                            Grass: begin
                                if(golden_player_info.pkm_info.exp < 48) begin
                                    golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+15;
                                end
                                else begin
                                    golden_player_info.pkm_info.exp = 0;
                                    golden_player_info.pkm_info.stage = Highest;
                                    golden_player_info.pkm_info.hp = 254;
                                    golden_player_info.pkm_info.atk = 123;
                                    bracer_flag=0;
                                end
                            end
                            Fire: begin
                                if(golden_player_info.pkm_info.exp < 44) begin
                                    golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+15;
                                end
                                else begin
                                    golden_player_info.pkm_info.exp = 0;
                                    golden_player_info.pkm_info.stage = Highest;
                                    golden_player_info.pkm_info.hp = 225;
                                    golden_player_info.pkm_info.atk = 127;
                                    bracer_flag=0;
                                end
                            end
                            Water: begin
                                if(golden_player_info.pkm_info.exp < 40) begin
                                    golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+15;
                                end
                                else begin
                                    golden_player_info.pkm_info.exp = 0;
                                    golden_player_info.pkm_info.stage = Highest;
                                    golden_player_info.pkm_info.hp = 245;
                                    golden_player_info.pkm_info.atk = 113;
                                    bracer_flag=0;
                                end
                            end
                            Electric: begin
                                if(golden_player_info.pkm_info.exp < 36) begin
                                    golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+15;
                                end
                                else begin
                                    golden_player_info.pkm_info.exp = 0;
                                    golden_player_info.pkm_info.stage = Highest;
                                    golden_player_info.pkm_info.hp = 235;
                                    golden_player_info.pkm_info.atk = 124;
                                    bracer_flag=0;
                                end
                            end
                        endcase
                    end
                    Highest: begin
                        golden_player_info.pkm_info.exp = 0;
                        golden_player_info.pkm_info.stage = Highest;
                    end
                endcase
                //$display("Successful");
                golden_complete = 1'b1 ;
		        golden_err_msg = No_Err ;
                golden_player_info.bag_info.candy_num = golden_player_info.bag_info.candy_num-1;

                golden_DRAM[BASE_Addr+golden_id*8 + 1][7:4] = golden_player_info.bag_info.candy_num;
                {golden_DRAM[BASE_Addr+golden_id*8 + 4], golden_DRAM[BASE_Addr+golden_id*8 + 5], golden_DRAM[BASE_Addr+golden_id*8 + 6], golden_DRAM[BASE_Addr+golden_id*8 + 7]} = golden_player_info.pkm_info;
            end
        end
        Bracer: begin
            if(golden_player_info.pkm_info.pkm_type ==  No_type) begin
                //$display("Not_Having_PKM");
		        golden_complete = 1'b0 ;
		        golden_err_msg = Not_Having_PKM ;
            end
            else if(golden_player_info.bag_info.bracer_num < 1) begin
                //$display("Not_Having_Item");
		        golden_complete = 1'b0 ;
		        golden_err_msg = Not_Having_Item ;
            end
            else begin
                bracer_cnt = bracer_cnt+1;
                if(bracer_flag === 0) begin
                    golden_player_info.pkm_info.atk = golden_player_info.pkm_info.atk+32;
                    temp_bracer = golden_player_info.pkm_info.atk+32;
                end
                else begin
                    golden_player_info.pkm_info.atk = golden_player_info.pkm_info.atk;
                end
                //bracer_flag = 1'b1 ;
                
                //$display("Successful");
                golden_complete = 1'b1 ;
		        golden_err_msg = No_Err ;
                golden_player_info.bag_info.bracer_num = golden_player_info.bag_info.bracer_num-1;
                //if(bracer_flag)
                //golden_use_info.pkm_info.atk = golden_player_info.pkm_info.atk;
                if(bracer_flag)
                    golden_use_info.pkm_info.atk = golden_use_info.pkm_info.atk;
                else
                    golden_use_info.pkm_info.atk = golden_player_info.pkm_info.atk;
                golden_DRAM[BASE_Addr+golden_id*8 + 1][3:0] = golden_player_info.bag_info.bracer_num;
                bracer_flag = 1'b1 ;
            end
        end
    endcase
end 
endtask


task Attack_task; begin

	// id
	give_id_task;
   
    if( give == 1  || has_given_id == 0) begin
        delay_task;
        get_player_info_task;
    end/*
    else begin
        temp_atk = golden_player_info.pkm_info.atk;
        golden_player_info.pkm_info.atk = golden_use_info.pkm_info.atk;

    end*/
    if(bracer_flag == 1) begin
        temp_stage = golden_player_info.pkm_info.stage;
        temp_atk = golden_player_info.pkm_info.atk;
        golden_player_info.pkm_info.atk = golden_use_info.pkm_info.atk;
    end


	// action
	inf.act_valid = 1'b1 ;
	inf.D = golden_act ;
    @(negedge clk);
	inf.act_valid = 1'b0 ;
	inf.D = 'bx ;
    @(negedge clk);
	delay_task;

    give_op_task;
    get_op_info_task;
    //@(negedge clk);

    case(golden_player_info.pkm_info.stage)
        Lowest: begin
            case(golden_op_info.pkm_info.stage)
                Lowest: begin
                    atk_exp = 16;
                    def_exp = 8;
                end
                Middle: begin
                    atk_exp = 24;
                    def_exp = 8;
                end
                Highest: begin
                    atk_exp = 32;
                    def_exp = 8;
                end
            endcase
        end
        Middle: begin
            case(golden_op_info.pkm_info.stage)
                Lowest: begin
                    atk_exp = 16;
                    def_exp = 12;
                end
                Middle: begin
                    atk_exp = 24;
                    def_exp = 12;
                end
                Highest: begin
                    atk_exp = 32;
                    def_exp = 12;
                end
            endcase
        end
        Highest: begin
            case(golden_op_info.pkm_info.stage)
                Lowest: begin
                    atk_exp = 16;
                    def_exp = 16;
                end
                Middle: begin
                    atk_exp = 24;
                    def_exp = 16;
                end
                Highest: begin
                    atk_exp = 32;
                    def_exp = 16;
                end
            endcase
        end
    endcase

    if(golden_op_info.pkm_info.stage === No_stage || golden_player_info.pkm_info.stage === No_stage) begin
        //$display("Not_Having_PKM");
		golden_complete = 1'b0 ;
		golden_err_msg = Not_Having_PKM ;
    end
    else if(golden_op_info.pkm_info.hp === 0 || golden_player_info.pkm_info.hp === 0) begin
        //$display("HP_is_Zero");
		golden_complete = 1'b0 ;
		golden_err_msg = HP_is_Zero ;
    end
    else begin
        case(golden_player_info.pkm_info.pkm_type)
        Grass: begin
            case(golden_op_info.pkm_info.pkm_type)
                Grass: begin
                    case(golden_player_info.pkm_info.stage)
                        Lowest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
									if(golden_op_info.pkm_info.exp+def_exp < 32) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 192;
										golden_op_info.pkm_info.atk = 94;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 32) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 192;
										golden_player_info.pkm_info.atk = 94;
                                    end
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 63) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 254;
										golden_op_info.pkm_info.atk = 123;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 32) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 192;
										golden_player_info.pkm_info.atk = 94;
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
                                    end
									
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 32) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 192;
										golden_player_info.pkm_info.atk = 94;
										
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Middle: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
									if(golden_op_info.pkm_info.exp+def_exp < 32) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 192;
										golden_op_info.pkm_info.atk = 94;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 63) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 254;
										golden_player_info.pkm_info.atk = 123;
                                    end
									
									
                                    
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 63) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 254;
										golden_op_info.pkm_info.atk = 123;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 63) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 254;
										golden_player_info.pkm_info.atk = 123;
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 63) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 254;
										golden_player_info.pkm_info.atk = 123;
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Highest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
                                    golden_player_info.pkm_info.exp = 0;
                                    
                                    if(golden_op_info.pkm_info.exp+def_exp < 32) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 192;
										golden_op_info.pkm_info.atk = 94;
                                    end
                                    
                                end
                                Middle: begin
                                    golden_player_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.exp+def_exp < 63) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 254;
										golden_op_info.pkm_info.atk = 123;
                                    end
                                    
                                end
                                Highest: begin

                                    golden_player_info.pkm_info.exp = 0;

                                    golden_op_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
                                    end
                                end
                            endcase
                        end
                    endcase
                end
                Fire: begin
                    case(golden_player_info.pkm_info.stage)
                        Lowest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
									if(golden_op_info.pkm_info.exp+def_exp < 30) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 177;
										golden_op_info.pkm_info.atk = 96;
                                    end
                                    if(golden_player_info.pkm_info.exp+atk_exp < 32) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 192;
										golden_player_info.pkm_info.atk = 94;
                                    end
                                    
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 59) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 225;
										golden_op_info.pkm_info.atk = 127;
                                    end
                                    if(golden_player_info.pkm_info.exp+atk_exp < 32) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 192;
										golden_player_info.pkm_info.atk = 94;
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
                                    end

                                    if(golden_player_info.pkm_info.exp+atk_exp < 32) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 192;
										golden_player_info.pkm_info.atk = 94;
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Middle: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
									if(golden_op_info.pkm_info.exp+def_exp < 30) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 177;
										golden_op_info.pkm_info.atk = 96;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 63) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 254;
										golden_player_info.pkm_info.atk = 123;
                                    end
                                    
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 59) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 225;
										golden_op_info.pkm_info.atk = 127;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 63) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 254;
										golden_player_info.pkm_info.atk = 123;
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 63) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 254;
										golden_player_info.pkm_info.atk = 123;
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Highest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
                                    golden_player_info.pkm_info.exp = 0;
                                    
                                    if(golden_op_info.pkm_info.exp+def_exp < 30) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 177;
										golden_op_info.pkm_info.atk = 96;
                                    end
                                    
                                end
                                Middle: begin
                                    golden_player_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.exp+def_exp < 59) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 225;
										golden_op_info.pkm_info.atk = 127;

                                    end
                                    
                                end
                                Highest: begin
                                    
                                    golden_player_info.pkm_info.exp = 0;

                                    golden_op_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
                                    end
                                end
                            endcase
                        end
                    endcase
                end
                Water: begin
                    case(golden_player_info.pkm_info.stage)
                        Lowest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
                                    
                                    if(golden_op_info.pkm_info.exp+def_exp < 28) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 187;
										golden_op_info.pkm_info.atk = 89;
                                    end
									
									if(golden_player_info.pkm_info.exp+atk_exp < 32) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 192;
										golden_player_info.pkm_info.atk = 94;
                                    end
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 55) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 245;
										golden_op_info.pkm_info.atk = 113;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 32) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 192;
										golden_player_info.pkm_info.atk = 94;
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
                                    end

                                    if(golden_player_info.pkm_info.exp+atk_exp < 32) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 192;
										golden_player_info.pkm_info.atk = 94;
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Middle: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
									if(golden_op_info.pkm_info.exp+def_exp < 28) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 187;
										golden_op_info.pkm_info.atk = 89;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 63) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 254;
										golden_player_info.pkm_info.atk = 123;
                                    end
                                    
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 55) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 245;
										golden_op_info.pkm_info.atk = 113;
                                    end
                                    if(golden_player_info.pkm_info.exp+atk_exp < 63) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 254;
										golden_player_info.pkm_info.atk = 123;
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
                                    end
                                    if(golden_player_info.pkm_info.exp+atk_exp < 63) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 254;
										golden_player_info.pkm_info.atk = 123;
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Highest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
                                    golden_player_info.pkm_info.exp = 0;
                                    
                                    if(golden_op_info.pkm_info.exp+def_exp < 28) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
                                        if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
                                            golden_op_info.pkm_info.hp = 0;
                                        end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
                                    end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 187;
										golden_op_info.pkm_info.atk = 89;
                                    end
                                    
                                end
                                Middle: begin
                                    golden_player_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.exp+def_exp < 55) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
                                        if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
                                            golden_op_info.pkm_info.hp = 0;
                                        end
                                        else begin
                                            golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
                                        end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 245;
										golden_op_info.pkm_info.atk = 113;
                                    end
                                    
                                end
                                Highest: begin
                                    
                                    golden_player_info.pkm_info.exp = 0;

                                    golden_op_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
                                    end
                                end
                            endcase
                        end
                    endcase
                end
                Electric: begin
                    case(golden_player_info.pkm_info.stage)
                        Lowest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
									if(golden_op_info.pkm_info.exp+def_exp < 26) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 182;
										golden_op_info.pkm_info.atk = 97;
                                    end
                                    if(golden_player_info.pkm_info.exp+atk_exp < 32) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 192;
										golden_player_info.pkm_info.atk = 94;
                                    end
                                    
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 51) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 235;
										golden_op_info.pkm_info.atk = 124;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 32) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 192;
										golden_player_info.pkm_info.atk = 94;
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk);
                                    end
									
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 32) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 192;
										golden_player_info.pkm_info.atk = 94;
										
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Middle: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
									if(golden_op_info.pkm_info.exp+def_exp < 26) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0 ;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 182 ;
										golden_op_info.pkm_info.atk = 97 ;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 63) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 254;
										golden_player_info.pkm_info.atk = 123;
                                    end
									
                                    
									
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 51) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 235 ;
										golden_op_info.pkm_info.atk = 124 ;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 63) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 254;
										golden_player_info.pkm_info.atk = 123;
										
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk);
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 63) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 254;
										golden_player_info.pkm_info.atk = 123;
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Highest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
                                    golden_player_info.pkm_info.exp = 0;
                                    
                                    if(golden_op_info.pkm_info.exp+def_exp < 26) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 182;
										golden_op_info.pkm_info.atk = 97;
                                    end
                                    
                                end
                                Middle: begin
                                    golden_player_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.exp+def_exp < 51) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 235;
										golden_op_info.pkm_info.atk = 124;
                                    end
                                    
                                end
                                Highest: begin
                                    
                                    golden_player_info.pkm_info.exp = 0;

                                    golden_op_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk);
                                    end
                                end
                            endcase
                        end
                    endcase
                end
            endcase
        end
        Fire: begin
            case(golden_op_info.pkm_info.pkm_type)
                Grass: begin
                    case(golden_player_info.pkm_info.stage)
                        Lowest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
									if(golden_op_info.pkm_info.exp+def_exp < 32) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 192;
										golden_op_info.pkm_info.atk = 94;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 30) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 177;
										golden_player_info.pkm_info.atk = 96;
                                    end
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 63) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 254;
										golden_op_info.pkm_info.atk = 123;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 30) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 177;
										golden_player_info.pkm_info.atk = 96;
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
                                    end
									
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 30) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 177;
										golden_player_info.pkm_info.atk = 96;
										
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Middle: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
									if(golden_op_info.pkm_info.exp+def_exp < 32) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 192;
										golden_op_info.pkm_info.atk = 94;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 59) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 225;
										golden_player_info.pkm_info.atk = 127;
                                    end
									
									
                                    
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 63) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 254;
										golden_op_info.pkm_info.atk = 123;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 59) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 225;
										golden_player_info.pkm_info.atk = 127;
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 59) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 225;
										golden_player_info.pkm_info.atk = 127;
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Highest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
                                    golden_player_info.pkm_info.exp = 0;
                                    
                                    if(golden_op_info.pkm_info.exp+def_exp < 32) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 192;
										golden_op_info.pkm_info.atk = 94;
                                    end
                                    
                                end
                                Middle: begin
                                    golden_player_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.exp+def_exp < 63) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 254;
										golden_op_info.pkm_info.atk = 123;
                                    end
                                    
                                end
                                Highest: begin

                                    golden_player_info.pkm_info.exp = 0;

                                    golden_op_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
                                    end
                                end
                            endcase
                        end
                    endcase
                end
                Fire: begin
                    case(golden_player_info.pkm_info.stage)
                        Lowest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
									if(golden_op_info.pkm_info.exp+def_exp < 30) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 177;
										golden_op_info.pkm_info.atk = 96;
                                    end
                                    if(golden_player_info.pkm_info.exp+atk_exp < 30) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 177;
										golden_player_info.pkm_info.atk = 96;
                                    end
                                    
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 59) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 225;
										golden_op_info.pkm_info.atk = 127;
                                    end
                                    if(golden_player_info.pkm_info.exp+atk_exp < 30) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 177;
										golden_player_info.pkm_info.atk = 96;
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
                                    end

                                    if(golden_player_info.pkm_info.exp+atk_exp < 30) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 177;
										golden_player_info.pkm_info.atk = 96;
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Middle: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
									if(golden_op_info.pkm_info.exp+def_exp < 30) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 177;
										golden_op_info.pkm_info.atk = 96;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 59) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 225;
										golden_player_info.pkm_info.atk = 127;
                                    end
                                    
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 59) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 225;
										golden_op_info.pkm_info.atk = 127;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 59) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 225;
										golden_player_info.pkm_info.atk = 127;
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 63) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 225;
										golden_player_info.pkm_info.atk = 127;
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Highest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
                                    golden_player_info.pkm_info.exp = 0;
                                    
                                    if(golden_op_info.pkm_info.exp+def_exp < 30) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 177;
										golden_op_info.pkm_info.atk = 96;
                                    end
                                    
                                end
                                Middle: begin
                                    golden_player_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.exp+def_exp < 59) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 225;
										golden_op_info.pkm_info.atk = 127;

                                    end
                                    
                                end
                                Highest: begin
                                    
                                    golden_player_info.pkm_info.exp = 0;

                                    golden_op_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
                                    end
                                end
                            endcase
                        end
                    endcase
                end
                Water: begin
                    case(golden_player_info.pkm_info.stage)
                        Lowest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
                                    
                                    if(golden_op_info.pkm_info.exp+def_exp < 28) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk>>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk>>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 187;
										golden_op_info.pkm_info.atk = 89;
                                    end
									
									if(golden_player_info.pkm_info.exp+atk_exp < 30) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 177;
										golden_player_info.pkm_info.atk = 96;
                                    end
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 55) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 245;
										golden_op_info.pkm_info.atk = 113;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 30) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 177;
										golden_player_info.pkm_info.atk = 96;
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk>>1)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
                                    end

                                    if(golden_player_info.pkm_info.exp+atk_exp < 30) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 177;
										golden_player_info.pkm_info.atk = 96;
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Middle: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
									if(golden_op_info.pkm_info.exp+def_exp < 28) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk>>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 187;
										golden_op_info.pkm_info.atk = 89;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 59) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 225;
										golden_player_info.pkm_info.atk = 127;
                                    end
                                    
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 55) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 245;
										golden_op_info.pkm_info.atk = 113;
                                    end
                                    if(golden_player_info.pkm_info.exp+atk_exp < 59) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 225;
										golden_player_info.pkm_info.atk = 127;
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk>>1);
                                    end
                                    if(golden_player_info.pkm_info.exp+atk_exp < 59) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 225;
										golden_player_info.pkm_info.atk = 127;
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Highest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
                                    golden_player_info.pkm_info.exp = 0;
                                    
                                    if(golden_op_info.pkm_info.exp+def_exp < 28) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
                                        if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk>>1)) begin
                                            golden_op_info.pkm_info.hp = 0;
                                        end
                                        else begin
                                            golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk>>1);
                                        end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 187;
										golden_op_info.pkm_info.atk = 89;
                                    end
                                    
                                end
                                Middle: begin
                                    golden_player_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.exp+def_exp < 55) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
                                        if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk>>1)) begin
                                            golden_op_info.pkm_info.hp = 0;
                                        end
                                        else begin
                                            golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk>>1);
                                        end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 245;
										golden_op_info.pkm_info.atk = 113;
                                    end
                                    
                                end
                                Highest: begin
                                    
                                    golden_player_info.pkm_info.exp = 0;

                                    golden_op_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk>>1)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
                                    end
                                end
                            endcase
                        end
                    endcase
                end
                Electric: begin
                    case(golden_player_info.pkm_info.stage)
                        Lowest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
									if(golden_op_info.pkm_info.exp+def_exp < 26) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 182;
										golden_op_info.pkm_info.atk = 97;
                                    end
                                    if(golden_player_info.pkm_info.exp+atk_exp < 30) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 177;
										golden_player_info.pkm_info.atk = 96;
                                    end
                                    
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 51) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 235;
										golden_op_info.pkm_info.atk = 124;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 30) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 177;
										golden_player_info.pkm_info.atk = 96;
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk);
                                    end
									
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 30) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 177;
										golden_player_info.pkm_info.atk = 96;
										
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Middle: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
									if(golden_op_info.pkm_info.exp+def_exp < 26) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0 ;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 182 ;
										golden_op_info.pkm_info.atk = 97 ;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 59) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 225;
										golden_player_info.pkm_info.atk = 127;
                                    end
									
                                    
									
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 51) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 235 ;
										golden_op_info.pkm_info.atk = 124 ;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 59) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 225;
										golden_player_info.pkm_info.atk = 127;
										
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk);
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 59) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 225;
										golden_player_info.pkm_info.atk = 127;
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Highest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
                                    golden_player_info.pkm_info.exp = 0;
                                    
                                    if(golden_op_info.pkm_info.exp+def_exp < 26) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 182;
										golden_op_info.pkm_info.atk = 97;
                                    end
                                    
                                end
                                Middle: begin
                                    golden_player_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.exp+def_exp < 51) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 235;
										golden_op_info.pkm_info.atk = 124;
                                    end
                                    
                                end
                                Highest: begin
                                    
                                    golden_player_info.pkm_info.exp = 0;

                                    golden_op_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk);
                                    end
                                end
                            endcase
                        end
                    endcase
                end
            endcase
        end
        Water: begin
            case(golden_op_info.pkm_info.pkm_type)
                Grass: begin
                    case(golden_player_info.pkm_info.stage)
                        Lowest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
									if(golden_op_info.pkm_info.exp+def_exp < 32) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 192;
										golden_op_info.pkm_info.atk = 94;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 28) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 187;
										golden_player_info.pkm_info.atk = 89;
                                    end
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 63) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 254;
										golden_op_info.pkm_info.atk = 123;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 28) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 187;
										golden_player_info.pkm_info.atk = 89;
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
                                    end
									
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 28) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 187;
										golden_player_info.pkm_info.atk = 89;
										
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Middle: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
									if(golden_op_info.pkm_info.exp+def_exp < 32) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 192;
										golden_op_info.pkm_info.atk = 94;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 55) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 245;
										golden_player_info.pkm_info.atk = 113;
                                    end
									
									
                                    
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 63) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 254;
										golden_op_info.pkm_info.atk = 123;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 55) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 245;
										golden_player_info.pkm_info.atk = 113;
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 55) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 245;
										golden_player_info.pkm_info.atk = 113;
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Highest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
                                    golden_player_info.pkm_info.exp = 0;
                                    
                                    if(golden_op_info.pkm_info.exp+def_exp < 32) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 192;
										golden_op_info.pkm_info.atk = 94;
                                    end
                                    
                                end
                                Middle: begin
                                    golden_player_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.exp+def_exp < 63) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 254;
										golden_op_info.pkm_info.atk = 123;
                                    end
                                    
                                end
                                Highest: begin

                                    golden_player_info.pkm_info.exp = 0;

                                    golden_op_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
                                    end
                                end
                            endcase
                        end
                    endcase
                end
                Fire: begin
                    case(golden_player_info.pkm_info.stage)
                        Lowest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
									if(golden_op_info.pkm_info.exp+def_exp < 30) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 177;
										golden_op_info.pkm_info.atk = 96;
                                    end
                                    if(golden_player_info.pkm_info.exp+atk_exp < 28) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 187;
										golden_player_info.pkm_info.atk = 89;
                                    end
                                    
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 59) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp <{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 225;
										golden_op_info.pkm_info.atk = 127;
                                    end
                                    if(golden_player_info.pkm_info.exp+atk_exp < 28) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 187;
										golden_player_info.pkm_info.atk = 89;
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
                                    end

                                    if(golden_player_info.pkm_info.exp+atk_exp < 28) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 187;
										golden_player_info.pkm_info.atk = 89;
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Middle: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
									if(golden_op_info.pkm_info.exp+def_exp < 30) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 177;
										golden_op_info.pkm_info.atk = 96;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 55) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 245;
										golden_player_info.pkm_info.atk = 113;
                                    end
                                    
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 59) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 225;
										golden_op_info.pkm_info.atk = 127;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 55) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 245;
										golden_player_info.pkm_info.atk = 113;
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 55) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 245;
										golden_player_info.pkm_info.atk = 113;
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Highest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
                                    golden_player_info.pkm_info.exp = 0;
                                    
                                    if(golden_op_info.pkm_info.exp+def_exp < 30) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 177;
										golden_op_info.pkm_info.atk = 96;
                                    end
                                    
                                end
                                Middle: begin
                                    golden_player_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.exp+def_exp < 59) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp <{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 225;
										golden_op_info.pkm_info.atk = 127;

                                    end
                                    
                                end
                                Highest: begin
                                    
                                    golden_player_info.pkm_info.exp = 0;

                                    golden_op_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
                                    end
                                end
                            endcase
                        end
                    endcase
                end
                Water: begin
                    case(golden_player_info.pkm_info.stage)
                        Lowest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
                                    
                                    if(golden_op_info.pkm_info.exp+def_exp < 28) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk>>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 187;
										golden_op_info.pkm_info.atk = 89;
                                    end
									
									if(golden_player_info.pkm_info.exp+atk_exp < 28) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 187;
										golden_player_info.pkm_info.atk = 89;
                                    end
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 55) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 245;
										golden_op_info.pkm_info.atk = 113;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 28) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 187;
										golden_player_info.pkm_info.atk = 89;
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk>>1)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
                                    end

                                    if(golden_player_info.pkm_info.exp+atk_exp < 28) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 187;
										golden_player_info.pkm_info.atk = 89;
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Middle: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
									if(golden_op_info.pkm_info.exp+def_exp < 28) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk>>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 187;
										golden_op_info.pkm_info.atk = 89;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 55) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 245;
										golden_player_info.pkm_info.atk = 113;
                                    end
                                    
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 55) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 245;
										golden_op_info.pkm_info.atk = 113;
                                    end
                                    if(golden_player_info.pkm_info.exp+atk_exp < 55) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 245;
										golden_player_info.pkm_info.atk = 113;
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
                                    end
                                    if(golden_player_info.pkm_info.exp+atk_exp < 55) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 245;
										golden_player_info.pkm_info.atk = 113;
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Highest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
                                    golden_player_info.pkm_info.exp = 0;
                                    
                                    if(golden_op_info.pkm_info.exp+def_exp < 28) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
                                        if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk>>1)) begin
                                            golden_op_info.pkm_info.hp = 0;
                                        end
                                        else begin
                                            golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk>>1);
                                        end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 187;
										golden_op_info.pkm_info.atk = 89;
                                    end
                                    
                                end
                                Middle: begin
                                    golden_player_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.exp+def_exp < 55) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
                                        if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk>>1)) begin
                                            golden_op_info.pkm_info.hp = 0;
                                        end
                                        else begin
                                            golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk>>1);
                                        end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 245;
										golden_op_info.pkm_info.atk = 113;
                                    end
                                    
                                end
                                Highest: begin
                                    
                                    golden_player_info.pkm_info.exp = 0;

                                    golden_op_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk>>1)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
                                    end
                                end
                            endcase
                        end
                    endcase
                end
                Electric: begin
                    case(golden_player_info.pkm_info.stage)
                        Lowest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
									if(golden_op_info.pkm_info.exp+def_exp < 26) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 182;
										golden_op_info.pkm_info.atk = 97;
                                    end
                                    if(golden_player_info.pkm_info.exp+atk_exp < 28) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 187;
										golden_player_info.pkm_info.atk = 89;
                                    end
                                    
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 51) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 235;
										golden_op_info.pkm_info.atk = 124;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 28) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 187;
										golden_player_info.pkm_info.atk = 89;
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk);
                                    end
									
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 28) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 187;
										golden_player_info.pkm_info.atk = 89;
										
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Middle: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
									if(golden_op_info.pkm_info.exp+def_exp < 26) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0 ;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 182 ;
										golden_op_info.pkm_info.atk = 97 ;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 55) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 245;
										golden_player_info.pkm_info.atk = 113;
                                    end
									
                                    
									
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 51) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 235 ;
										golden_op_info.pkm_info.atk = 124 ;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 55) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 245;
										golden_player_info.pkm_info.atk = 113;
										
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk);
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 55) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 245;
										golden_player_info.pkm_info.atk = 113;
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Highest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
                                    golden_player_info.pkm_info.exp = 0;
                                    
                                    if(golden_op_info.pkm_info.exp+def_exp < 26) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 182;
										golden_op_info.pkm_info.atk = 97;
                                    end
                                    
                                end
                                Middle: begin
                                    golden_player_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.exp+def_exp < 51) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 235;
										golden_op_info.pkm_info.atk = 124;
                                    end
                                    
                                end
                                Highest: begin
                                    
                                    golden_player_info.pkm_info.exp = 0;

                                    golden_op_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk);
                                    end
                                end
                            endcase
                        end
                    endcase
                end
            endcase
        end
        Electric: begin
            case(golden_op_info.pkm_info.pkm_type)
                Grass: begin
                    case(golden_player_info.pkm_info.stage)
                        Lowest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
									if(golden_op_info.pkm_info.exp+def_exp < 32) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 192;
										golden_op_info.pkm_info.atk = 94;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 26) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 182;
										golden_player_info.pkm_info.atk = 97;
                                    end
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 63) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 254;
										golden_op_info.pkm_info.atk = 123;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 26) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 182;
										golden_player_info.pkm_info.atk = 97;
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
                                    end
									
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 26) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 182;
										golden_player_info.pkm_info.atk = 97;
										
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Middle: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
									if(golden_op_info.pkm_info.exp+def_exp < 32) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 192;
										golden_op_info.pkm_info.atk = 94;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 51) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 235;
										golden_player_info.pkm_info.atk = 124;
                                    end
									
									
                                    
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 63) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 254;
										golden_op_info.pkm_info.atk = 123;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 51) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 235;
										golden_player_info.pkm_info.atk = 124;
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 51) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 235;
										golden_player_info.pkm_info.atk = 124;
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Highest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
                                    golden_player_info.pkm_info.exp = 0;
                                    
                                    if(golden_op_info.pkm_info.exp+def_exp < 32) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 192;
										golden_op_info.pkm_info.atk = 94;
                                    end
                                    
                                end
                                Middle: begin
                                    golden_player_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.exp+def_exp < 63) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 254;
										golden_op_info.pkm_info.atk = 123;
                                    end
                                    
                                end
                                Highest: begin

                                    golden_player_info.pkm_info.exp = 0;

                                    golden_op_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk >>1)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk >>1);
                                    end
                                end
                            endcase
                        end
                    endcase
                end
                Fire: begin
                    case(golden_player_info.pkm_info.stage)
                        Lowest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
									if(golden_op_info.pkm_info.exp+def_exp < 30) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 177;
										golden_op_info.pkm_info.atk = 96;
                                    end
                                    if(golden_player_info.pkm_info.exp+atk_exp < 26) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 182;
										golden_player_info.pkm_info.atk = 97;
                                    end
                                    
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 59) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk )) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk );
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 225;
										golden_op_info.pkm_info.atk = 127;
                                    end
                                    if(golden_player_info.pkm_info.exp+atk_exp < 26) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 182;
										golden_player_info.pkm_info.atk = 97;
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk )) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk );
                                    end

                                    if(golden_player_info.pkm_info.exp+atk_exp < 26) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 182;
										golden_player_info.pkm_info.atk = 97;
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Middle: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
									if(golden_op_info.pkm_info.exp+def_exp < 30) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk )) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk );
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 177;
										golden_op_info.pkm_info.atk = 96;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 51) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 235;
										golden_player_info.pkm_info.atk = 124;
                                    end
                                    
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 59) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < golden_player_info.pkm_info.atk ) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-golden_player_info.pkm_info.atk;
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 225;
										golden_op_info.pkm_info.atk = 127;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 51) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 235;
										golden_player_info.pkm_info.atk = 124;
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk )) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk );
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 51) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 235;
										golden_player_info.pkm_info.atk = 124;
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Highest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
                                    golden_player_info.pkm_info.exp = 0;
                                    
                                    if(golden_op_info.pkm_info.exp+def_exp < 30) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk )) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk );
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 177;
										golden_op_info.pkm_info.atk = 96;
                                    end
                                    
                                end
                                Middle: begin
                                    golden_player_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.exp+def_exp < 59) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk )) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk );
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 225;
										golden_op_info.pkm_info.atk = 127;

                                    end
                                    
                                end
                                Highest: begin
                                    
                                    golden_player_info.pkm_info.exp = 0;

                                    golden_op_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk )) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk );
                                    end
                                end
                            endcase
                        end
                    endcase
                end
                Water: begin
                    case(golden_player_info.pkm_info.stage)
                        Lowest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
                                    
                                    if(golden_op_info.pkm_info.exp+def_exp < 28) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp <{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 187;
										golden_op_info.pkm_info.atk = 89;
                                    end
									
									if(golden_player_info.pkm_info.exp+atk_exp < 26) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 182;
										golden_player_info.pkm_info.atk = 97;
                                    end
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 55) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 245;
										golden_op_info.pkm_info.atk = 113;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 26) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 182;
										golden_player_info.pkm_info.atk = 97;
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
                                    end

                                    if(golden_player_info.pkm_info.exp+atk_exp < 26) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 182;
										golden_player_info.pkm_info.atk = 97;
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Middle: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
									if(golden_op_info.pkm_info.exp+def_exp < 28) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 187;
										golden_op_info.pkm_info.atk = 89;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 51) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 235;
										golden_player_info.pkm_info.atk = 124;
                                    end
                                    
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 55) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 245;
										golden_op_info.pkm_info.atk = 113;
                                    end
                                    if(golden_player_info.pkm_info.exp+atk_exp < 51) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 235;
										golden_player_info.pkm_info.atk = 124;
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp <{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
                                    end
                                    if(golden_player_info.pkm_info.exp+atk_exp < 51) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 235;
										golden_player_info.pkm_info.atk = 124;
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Highest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
                                    golden_player_info.pkm_info.exp = 0;
                                    
                                    if(golden_op_info.pkm_info.exp+def_exp < 28) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
                                        if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
                                            golden_op_info.pkm_info.hp = 0;
                                        end
                                        else begin
                                            golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
                                        end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 187;
										golden_op_info.pkm_info.atk = 89;
                                    end
                                    
                                end
                                Middle: begin
                                    golden_player_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.exp+def_exp < 55) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
                                        if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
                                            golden_op_info.pkm_info.hp = 0;
                                        end
                                        else begin
                                            golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
                                        end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 245;
										golden_op_info.pkm_info.atk = 113;
                                    end
                                    
                                end
                                Highest: begin
                                    
                                    golden_player_info.pkm_info.exp = 0;

                                    golden_op_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.hp < {golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)}) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-{golden_player_info.pkm_info.atk[7], (golden_player_info.pkm_info.atk <<1)};
                                    end
                                end
                            endcase
                        end
                    endcase
                end
                Electric: begin
                    case(golden_player_info.pkm_info.stage)
                        Lowest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
									if(golden_op_info.pkm_info.exp+def_exp < 26) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk>>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk>>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 182;
										golden_op_info.pkm_info.atk = 97;
                                    end
                                    if(golden_player_info.pkm_info.exp+atk_exp < 26) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 182;
										golden_player_info.pkm_info.atk = 97;
                                    end
                                    
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 51) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk>>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk>>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 235;
										golden_op_info.pkm_info.atk = 124;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 26) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 182;
										golden_player_info.pkm_info.atk = 97;
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk>>1)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk>>1);
                                    end
									
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 26) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Middle;
										golden_player_info.pkm_info.hp = 182;
										golden_player_info.pkm_info.atk = 97;
										
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Middle: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
									if(golden_op_info.pkm_info.exp+def_exp < 26) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk>>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk>>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0 ;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 182 ;
										golden_op_info.pkm_info.atk = 97 ;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 51) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 235;
										golden_player_info.pkm_info.atk = 124;
                                    end
									
                                    
									
                                    
                                end
                                Middle: begin
									if(golden_op_info.pkm_info.exp+def_exp < 51) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk>>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk>>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 235 ;
										golden_op_info.pkm_info.atk = 124 ;
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 51) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 235;
										golden_player_info.pkm_info.atk = 124;
										
                                    end
                                    
                                    
                                end
                                Highest: begin
									if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk>>1)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk>>1);
                                    end
									
                                    if(golden_player_info.pkm_info.exp+atk_exp < 51) begin
                                        golden_player_info.pkm_info.exp = golden_player_info.pkm_info.exp+atk_exp;
                                    end
                                    else begin
                                        golden_player_info.pkm_info.exp = 0;
                                        golden_player_info.pkm_info.stage = Highest;
										golden_player_info.pkm_info.hp = 235;
										golden_player_info.pkm_info.atk = 124;
                                    end

                                    golden_op_info.pkm_info.exp = 0;

                                    
                                end
                            endcase
                        end
                        Highest: begin
                            case(golden_op_info.pkm_info.stage)
                                Lowest: begin
                                    golden_player_info.pkm_info.exp = 0;
                                    
                                    if(golden_op_info.pkm_info.exp+def_exp < 26) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk>>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk>>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Middle;
										golden_op_info.pkm_info.hp = 182;
										golden_op_info.pkm_info.atk = 97;
                                    end
                                    
                                end
                                Middle: begin
                                    golden_player_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.exp+def_exp < 51) begin
                                        golden_op_info.pkm_info.exp = golden_op_info.pkm_info.exp+def_exp;
										if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk>>1)) begin
											golden_op_info.pkm_info.hp = 0;
										end
										else begin
											golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk>>1);
										end
                                    end
                                    else begin
                                        golden_op_info.pkm_info.exp = 0;
                                        golden_op_info.pkm_info.stage = Highest;
										golden_op_info.pkm_info.hp = 235;
										golden_op_info.pkm_info.atk = 124;
                                    end
                                    
                                end
                                Highest: begin
                                    
                                    golden_player_info.pkm_info.exp = 0;

                                    golden_op_info.pkm_info.exp = 0;

                                    if(golden_op_info.pkm_info.hp < (golden_player_info.pkm_info.atk>>1)) begin
                                        golden_op_info.pkm_info.hp = 0;
                                    end
                                    else begin
                                        golden_op_info.pkm_info.hp = golden_op_info.pkm_info.hp-(golden_player_info.pkm_info.atk>>1);
                                    end
                                end
                            endcase
                        end
                    endcase
                end
            endcase
        end
        endcase
        //$display("Successful");
        golden_complete = 1'b1 ;
		golden_err_msg = No_Err ;
        if(temp_stage == golden_player_info.pkm_info.stage)
            if(bracer_flag)
                golden_player_info.pkm_info.atk = temp_atk;
            
        
        bracer_flag = 0;
        
        {golden_DRAM[BASE_Addr+golden_id*8 + 4], golden_DRAM[BASE_Addr+golden_id*8 + 5], golden_DRAM[BASE_Addr+golden_id*8 + 6], golden_DRAM[BASE_Addr+golden_id*8 + 7]} = golden_player_info.pkm_info;
        {golden_DRAM[BASE_Addr+golden_op*8 + 4], golden_DRAM[BASE_Addr+golden_op*8 + 5], golden_DRAM[BASE_Addr+golden_op*8 + 6], golden_DRAM[BASE_Addr+golden_op*8 + 7]} = golden_op_info.pkm_info;
    end
end 
endtask


//================================================================
// task definition - 2
//================================================================
task reset_signal_task; begin 
    #(2.0);  inf.rst_n <= 0;
    #(3.0);
	
	if((inf.out_valid   !== 'b0)|| (inf.err_msg     !== 'b0)|| (inf.complete    !== 'b0)|| (inf.out_info    !== 'b0) ) begin
        $finish;
    end
    #(2.0);  inf.rst_n <= 1;
	
end 
endtask


task wait_outvalid_task; begin
	cycles = 0 ;
	while (inf.out_valid !== 1) begin
		cycles = cycles + 1 ;
		if (cycles == 1200) begin
            $finish;
		end
		@(negedge clk);
	end
	total_cycles = total_cycles + cycles;
end 
endtask


task delay_task ; begin
	r_delay.randomize();
	for( i=0; i < r_delay.delay; i=i+1) begin
      @(negedge clk);  
    end	
end 
endtask

task gap_task ; begin
	r_gap.randomize();
	for( i=0; i < r_gap.gap; i=i+1) begin
       @(negedge clk); 
    end	
end 
endtask

//================================================================
//  output task
//================================================================
task output_task; begin
	//$display("output_task");
	y = 0;
	while (inf.out_valid===1) begin
		if (y >= 1) begin/*
			$display ("--------------------------------------------------");
			$display ("                        FAIL                      ");
			$display ("          Outvalid is more than 1 cycles          ");
			$display ("--------------------------------------------------");
	        #(100);*/
			$finish;
		end
		else begin	
			if (golden_complete) begin
				if (golden_act==Attack)
                   golden_out_info = {golden_player_info.pkm_info, golden_op_info.pkm_info} ; 
                else if (golden_act==Sell) begin
                    
                    if(bracer_flag == 1)
                        golden_out_info = {golden_player_info.bag_info, golden_sell_info.pkm_info.stage, golden_sell_info.pkm_info.pkm_type, golden_sell_info.pkm_info.hp, golden_use_info.pkm_info.atk, golden_sell_info.pkm_info.exp} ;
                    else
                        golden_out_info = {golden_player_info.bag_info, golden_sell_info.pkm_info} ;
                    bracer_flag = 0;
                end
                else if ((golden_act==Use_item && golden_item == Bracer) || (bracer_flag == 1))
                    golden_out_info = {golden_player_info.bag_info, golden_player_info.pkm_info.stage, golden_player_info.pkm_info.pkm_type, golden_player_info.pkm_info.hp, golden_use_info.pkm_info.atk, golden_player_info.pkm_info.exp} ;
                else begin
                    if(bracer_flag == 1)
                        golden_out_info = {golden_player_info.bag_info, golden_player_info.pkm_info.stage, golden_player_info.pkm_info.pkm_type, golden_player_info.pkm_info.hp, golden_use_info.pkm_info.atk, golden_player_info.pkm_info.exp} ;
                    else
                        golden_out_info = golden_player_info;
                end

                    

				if ( (inf.complete!==golden_complete) || (inf.err_msg!==golden_err_msg) || (inf.out_info!==golden_out_info)) begin
    			    $display("-----------------------------------------------------------");
    	    		$display("                           FAIL 2                 ");
    	    		$display("    Golden complete : %6d    your complete : %6d ", golden_complete, inf.complete);
    				$display("    Golden err_msg  : %6d    your err_msg  : %6d ", golden_err_msg, inf.err_msg);
    				$display("    Golden info     : %8h  your info     : %8h   ", golden_out_info, inf.out_info);
    	    		$display("-----------------------------------------------------------");
			        #(100);
    			    $finish;
    			end
    		end
    		else begin
    			golden_out_info = 0;
    			if ( (inf.complete!==golden_complete) || (inf.err_msg!==golden_err_msg) || (inf.out_info!==golden_out_info)) begin
    			    $display("-----------------------------------------------------------");
    	    		$display("                           FAIL 3                 ");
    	    		$display("    Golden complete : %6d    your complete : %6d ", golden_complete, inf.complete);
    				$display("    Golden err_msg  : %6d    your err_msg  : %6d ", golden_err_msg, inf.err_msg);
    				$display("    Golden info     : %8h  your info     : %8h   ", golden_out_info, inf.out_info);
    	    		$display("-----------------------------------------------------------");
			        #(100);
    			    $finish;
    			end
    		end	
    	end	
		@(negedge clk);
		y = y + 1;
	end
end endtask

//This task can be used when pass the pattern
task pass_task;
    $display("                                                             \033[33m`-                                                                            ");        
    $display("                                                             /NN.                                                                           ");        
    $display("                                                            sMMM+                                                                           ");        
    $display(" .``                                                       sMMMMy                                                                           ");        
    $display(" oNNmhs+:-`                                               oMMMMMh                                                                           ");        
    $display("  /mMMMMMNNd/:-`                                         :+smMMMh                                                                           ");        
    $display("   .sNMMMMMN::://:-`                                    .o--:sNMy                                                                           ");        
    $display("     -yNMMMM:----::/:-.                                 o:----/mo                                                                           ");        
    $display("       -yNMMo--------://:.                             -+------+/                                                                           ");        
    $display("         .omd/::--------://:`                          o-------o.                                                                           ");        
    $display("           `/+o+//::-------:+:`                       .+-------y                                                                            ");        
    $display("              .:+++//::------:+/.---------.`          +:------/+                                                                            ");        
    $display("                 `-/+++/::----:/:::::::::::://:-.     o------:s.          \033[37m:::::----.           -::::.          `-:////:-`     `.:////:-.    \033[33m");        
    $display("                    `.:///+/------------------:::/:- `o-----:/o          \033[37m.NNNNNNNNNNds-       -NNNNNd`       -smNMMMMMMNy   .smNNMMMMMNh    \033[33m");        
    $display("                         :+:----------------------::/:s-----/s.          \033[37m.MMMMo++sdMMMN-     `mMMmMMMs      -NMMMh+///oys  `mMMMdo///oyy    \033[33m");        
    $display("                        :/---------------------------:++:--/++           \033[37m.MMMM.   `mMMMy     yMMM:dMMM/     +MMMM:      `  :MMMM+`     `    \033[33m");        
    $display("                       :/---///:-----------------------::-/+o`           \033[37m.MMMM.   -NMMMo    +MMMs -NMMm.    .mMMMNdo:.     `dMMMNds/-`      \033[33m");        
    $display("                      -+--/dNs-o/------------------------:+o`            \033[37m.MMMMyyyhNMMNy`   -NMMm`  sMMMh     .odNMMMMNd+`   `+dNMMMMNdo.    \033[33m");        
    $display("                     .o---yMMdsdo------------------------:s`             \033[37m.MMMMNmmmdho-    `dMMMdooosMMMM+      `./sdNMMMd.    `.:ohNMMMm-   \033[33m");        
    $display("                    -yo:--/hmmds:----------------//:------o              \033[37m.MMMM:...`       sMMMMMMMMMMMMMN-  ``     `:MMMM+ ``      -NMMMs   \033[33m");        
    $display("                   /yssy----:::-------o+-------/h/-hy:---:+              \033[37m.MMMM.          /MMMN:------hMMMd` +dy+:::/yMMMN- :my+:::/sMMMM/   \033[33m");        
    $display("                  :ysssh:------//////++/-------sMdyNMo---o.              \033[37m.MMMM.         .mMMMs       .NMMMs /NMMMMMMMMmh:  -NMMMMMMMMNh/    \033[33m");        
    $display("                  ossssh:-------ddddmmmds/:----:hmNNh:---o               \033[37m`::::`         .::::`        -:::: `-:/++++/-.     .:/++++/-.      \033[33m");        
    $display("                  /yssyo--------dhhyyhhdmmhy+:---://----+-                                                                                  ");        
    $display("                  `yss+---------hoo++oosydms----------::s    `.....-.                                                                       ");        
    $display("                   :+-----------y+++++++oho--------:+sssy.://:::://+o.                                                                      ");        
    $display("                    //----------y++++++os/--------+yssssy/:--------:/s-                                                                     ");        
    $display("             `..:::::s+//:::----+s+++ooo:--------+yssssy:-----------++                                                                      ");        
    $display("           `://::------::///+/:--+soo+:----------ssssys/---------:o+s.``                                                                    ");        
    $display("          .+:----------------/++/:---------------:sys+----------:o/////////::::-...`                                                        ");        
    $display("          o---------------------oo::----------::/+//---------::o+--------------:/ohdhyo/-.``                                                ");        
    $display("          o---------------------/s+////:----:://:---------::/+h/------------------:oNMMMMNmhs+:.`                                           ");        
    $display("          -+:::::--------------:s+-:::-----------------:://++:s--::------------::://sMMMMMMMMMMNds/`                                        ");        
    $display("           .+++/////////////+++s/:------------------:://+++- :+--////::------/ydmNNMMMMMMMMMMMMMMmo`                                        ");        
    $display("             ./+oo+++oooo++/:---------------------:///++/-   o--:///////::----sNMMMMMMMMMMMMMMMmo.                                          ");        
    $display("                o::::::--------------------------:/+++:`    .o--////////////:--+mMMMMMMMMMMMMmo`                                            ");        
    $display("               :+--------------------------------/so.       +:-:////+++++///++//+mMMMMMMMMMmo`                                              ");        
    $display("              .s----------------------------------+: ````` `s--////o:.-:/+syddmNMMMMMMMMMmo`                                                ");        
    $display("              o:----------------------------------s. :s+/////--//+o-       `-:+shmNNMMMNs.                                                  ");        
    $display("             //-----------------------------------s` .s///:---:/+o.               `-/+o.                                                    ");        
    $display("            .o------------------------------------o.  y///+//:/+o`                                                                          ");        
    $display("            o-------------------------------------:/  o+//s//+++`                                                                           ");        
    $display("           //--------------------------------------s+/o+//s`                                                                                ");        
    $display("          -+---------------------------------------:y++///s                                                                                 ");        
    $display("          o-----------------------------------------oo/+++o                                                                                 ");        
    $display("         `s-----------------------------------------:s   ``                                                                                 ");        
    $display("          o-:::::------------------:::::-------------o.                                                                                     ");        
    $display("          .+//////////::::::://///////////////:::----o`                                                                                     ");        
    $display("          `:soo+///////////+++oooooo+/////////////:-//                                                                                      ");        
    $display("       -/os/--:++/+ooo:::---..:://+ooooo++///////++so-`                                                                                     ");        
    $display("      syyooo+o++//::-                 ``-::/yoooo+/:::+s/.                                                                                  ");        
    $display("       `..``                                `-::::///:++sys:                                                                                ");        
    $display("                                                    `.:::/o+  \033[37m                                                                              ");	
    $display("********************************************************************");
    $display("                        \033[0;38;5;219mCongratulations!\033[m      ");
    $display("                 \033[0;38;5;219mYou have passed all patterns!\033[m");
    $display("********************************************************************");
    $finish;
endtask

//This task can be used when fail the pattern
task fail_task; 
    $display("\033[33m	                                                         .:                                                                                         ");      
    $display("                                                   .:                                                                                                 ");
    $display("                                                  --`                                                                                                 ");
    $display("                                                `--`                                                                                                  ");
    $display("                 `-.                            -..        .-//-                                                                                      ");
    $display("                  `.:.`                        -.-     `:+yhddddo.                                                                                    ");
    $display("                    `-:-`             `       .-.`   -ohdddddddddh:                                                                                   ");
    $display("                      `---`       `.://:-.    :`- `:ydddddhhsshdddh-                       \033[31m.yhhhhhhhhhs       /yyyyy`       .yhhy`   +yhyo           \033[33m");
    $display("                        `--.     ./////:-::` `-.--yddddhs+//::/hdddy`                      \033[31m-MMMMNNNNNNh      -NMMMMMs       .MMMM.   sMMMh           \033[33m");
    $display("                          .-..   ////:-..-// :.:oddddho:----:::+dddd+                      \033[31m-MMMM-......     `dMMmhMMM/      .MMMM.   sMMMh           \033[33m");
    $display("                           `-.-` ///::::/::/:/`odddho:-------:::sdddh`                     \033[31m-MMMM.           sMMM/.NMMN.     .MMMM.   sMMMh           \033[33m");
    $display("             `:/+++//:--.``  .--..+----::://o:`osss/-.--------::/dddd/             ..`     \033[31m-MMMMysssss.    /MMMh  oMMMh     .MMMM.   sMMMh           \033[33m");
    $display("             oddddddddddhhhyo///.-/:-::--//+o-`:``````...------::dddds          `.-.`      \033[31m-MMMMMMMMMM-   .NMMN-``.mMMM+    .MMMM.   sMMMh           \033[33m");
    $display("            .ddddhhhhhddddddddddo.//::--:///+/`.````````..``...-:ddddh       `.-.`         \033[31m-MMMM:.....`  `hMMMMmmmmNMMMN-   .MMMM.   sMMMh           \033[33m");
    $display("            /dddd//::///+syhhdy+:-`-/--/////+o```````.-.......``./yddd`   `.--.`           \033[31m-MMMM.        oMMMmhhhhhhdMMMd`  .MMMM.   sMMMh```````    \033[33m");
    $display("            /dddd:/------:://-.`````-/+////+o:`````..``     `.-.``./ym.`..--`              \033[31m-MMMM.       :NMMM:      .NMMMs  .MMMM.   sMMMNmmmmmms    \033[33m");
    $display("            :dddd//--------.`````````.:/+++/.`````.` `.-      `-:.``.o:---`                \033[31m.dddd`       yddds        /dddh. .dddd`   +ddddddddddo    \033[33m");
    $display("            .ddddo/-----..`........`````..```````..  .-o`       `:.`.--/-      ``````````` \033[31m ````        ````          ````   ````     ``````````     \033[33m");
    $display("             ydddh/:---..--.````.`.-.````````````-   `yd:        `:.`...:` `................`                                                         ");
    $display("             :dddds:--..:.     `.:  .-``````````.:    +ys         :-````.:...```````````````..`                                                       ");
    $display("              sdddds:.`/`      ``s.  `-`````````-/.   .sy`      .:.``````-`````..-.-:-.````..`-                                                       ");
    $display("              `ydddd-`.:       `sh+   /:``````````..`` +y`   `.--````````-..---..``.+::-.-``--:                                                       ");
    $display("               .yddh``-.        oys`  /.``````````````.-:.`.-..`..```````/--.`      /:::-:..--`                                                       ");
    $display("                .sdo``:`        .sy. .:``````````````````````````.:```...+.``       -::::-`.`                                                         ");
    $display(" ````.........```.++``-:`        :y:.-``````````````....``.......-.```..::::----.```  ``                                                              ");
    $display("`...````..`....----:.``...````  ``::.``````.-:/+oosssyyy:`.yyh-..`````.:` ````...-----..`                                                             ");
    $display("                 `.+.``````........````.:+syhdddddddddddhoyddh.``````--              `..--.`                                                          ");
    $display("            ``.....--```````.```````.../ddddddhhyyyyyyyhhhddds````.--`             ````   ``                                                          ");
    $display("         `.-..``````-.`````.-.`.../ss/.oddhhyssssooooooossyyd:``.-:.         `-//::/++/:::.`                                                          ");
    $display("       `..```````...-::`````.-....+hddhhhyssoo+++//////++osss.-:-.           /++++o++//s+++/                                                          ");
    $display("     `-.```````-:-....-/-``````````:hddhsso++/////////////+oo+:`             +++::/o:::s+::o            \033[31m     `-/++++:-`                              \033[33m");
    $display("    `:````````./`  `.----:..````````.oysso+///////////////++:::.             :++//+++/+++/+-            \033[31m   :ymMMMMMMMMms-                            \033[33m");
    $display("    :.`-`..```./.`----.`  .----..`````-oo+////////////////o:-.`-.            `+++++++++++/.             \033[31m `yMMMNho++odMMMNo                           \033[33m");
    $display("    ..`:..-.`.-:-::.`        `..-:::::--/+++////////////++:-.```-`            +++++++++o:               \033[31m hMMMm-      /MMMMo  .ssss`/yh+.syyyyyyyyss. \033[33m");
    $display("     `.-::-:..-:-.`                 ```.+::/++//++++++++:..``````:`          -++++++++oo                \033[31m:MMMM:        yMMMN  -MMMMdMNNs-mNNNNNMMMMd` \033[33m");
    $display("        `   `--`                        /``...-::///::-.`````````.: `......` ++++++++oy-                \033[31m+MMMM`        +MMMN` -MMMMh:--. ````:mMMNs`  \033[33m");
    $display("           --`                          /`````````````````````````/-.``````.::-::::::/+                 \033[31m:MMMM:        yMMMm  -MMMM`       `oNMMd:    \033[33m");
    $display("          .`                            :```````````````````````--.`````````..````.``/-                 \033[31m dMMMm:`    `+MMMN/  -MMMN       :dMMNs`     \033[33m");
    $display("                                        :``````````````````````-.``.....````.```-::-.+                  \033[31m `yNMMMdsooymMMMm/   -MMMN     `sMMMMy/////` \033[33m");
    $display("                                        :.````````````````````````-:::-::.`````-:::::+::-.`             \033[31m   -smNMMMMMNNd+`    -NNNN     hNNNNNNNNNNN- \033[33m");
    $display("                                `......../```````````````````````-:/:   `--.```.://.o++++++/.           \033[31m      .:///:-`       `----     ------------` \033[33m");
    $display("                              `:.``````````````````````````````.-:-`      `/````..`+sssso++++:                                                        ");
    $display("                              :`````.---...`````````````````.--:-`         :-````./ysoooss++++.                                                       ");
    $display("                              -.````-:/.`.--:--....````...--:/-`            /-..-+oo+++++o++++.                                                       ");
    $display("             `:++/:.`          -.```.::      `.--:::::://:::::.              -:/o++++++++s++++                                                        ");
    $display("           `-+++++++++////:::/-.:.```.:-.`              :::::-.-`               -+++++++o++++.                                                        ");
    $display("           /++osoooo+++++++++:`````````.-::.             .::::.`-.`              `/oooo+++++.                                                         ");
    $display("           ++oysssosyssssooo/.........---:::               -:::.``.....`     `.:/+++++++++:                                                           ");
    $display("           -+syoooyssssssyo/::/+++++/+::::-`                 -::.``````....../++++++++++:`                                                            ");
    $display("             .:///-....---.-..-.----..`                        `.--.``````````++++++/:.                                                               ");
    $display("                                                                   `........-:+/:-.`                                                            \033[37m      ");
	$finish;
endtask

endprogram

