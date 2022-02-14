module pokemon(input clk, INF.pokemon_inf inf);
import usertype::*;

//================================================================
// logic 
//================================================================


P_state     state, n_state;

Player_id   id1, id2;
Action      act;
Item        itm;
PKM_Type    p_type;
Stage       stg;
Money       dollar;

Player_Info plr1, plr2, plr1_old;
Player_Info plr_re;

logic flag_id1, flag_id2, flag_type, flag_item;
logic give_new_id;
int bracer_cnt;

logic done;
logic [1:0] w_done, atk_id_cnt;
logic [4:0] cin_flag;

logic [1:0] cnt;
logic ff;
//================================================================
//   Design 
//================================================================
//================================================================
//   FSM
//================================================================

always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n)	begin
		state <= IDLE;
	end
	else begin
		state <= n_state;
	end
end

always_comb begin
	case(state)
		IDLE: begin
			n_state = (inf.rst_n)? IN : IDLE;
		end
		
		IN: begin
			if((act == Buy && p_type != No_type) || (act == Buy && itm != No_item)) begin
				n_state = READ;
			end
			else if(act == Sell) begin
				n_state = READ;
			end
			else if(act == Deposit  && dollar != 0)  begin
				n_state = READ;
			end
			else if(act == Check) begin
				n_state = READ;
			end
			else if(act == Use_item && itm != No_item) begin
				n_state = READ;
			end
			else if(act == Attack && id1 != id2) begin
				n_state = READ;
			end
			else begin
				n_state = IN;
			end
		end

		READ: begin
			if(act != Attack && inf.C_out_valid && give_new_id == 1) begin
				n_state = WORK;
			end
			else if(act != Attack && give_new_id == 0) begin
				n_state = WORK;
			end
			else if(act == Attack && inf.C_out_valid && atk_id_cnt == 1) begin
				n_state = WORK;
			end
			else begin
				n_state = READ;
			end
		end
		
		WORK: begin
			n_state = WAIT;
		end

		WAIT: begin
			n_state = WRITE;
			//n_state = OUT;
		end

		WRITE: begin
			n_state = (inf.err_msg != No_Err) ? OUT :  (inf.C_out_valid && ((act == Attack && w_done == 1) || (act != Attack)))? OUT : WRITE;
		end
		
		OUT: begin
			n_state = IDLE;
		end		
		
		default: begin
			n_state = state ;
		end
	endcase
end

//================================================================
//   INPUT
//================================================================

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)	begin
		id1 <= 0;
	end
	else if(inf.id_valid && !flag_id2) begin
		id1 <= inf.D.d_id[0];
	end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)	begin
		id2 <= 0;
	end
	else if(inf.id_valid && ((give_new_id &&  flag_id1) || (!give_new_id && !flag_id1))) begin
		id2 <= inf.D.d_id[0];
	end
	else if(n_state == OUT) begin
		id2 <= id1;
	end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		act <= No_action;
	end				
	else if(inf.act_valid) begin
		act <= inf.D.d_act[0];
	end	
	else if(n_state == OUT) begin
		act <= No_action;
	end	
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		itm <= No_item;
	end				
	else if(inf.item_valid) begin
		itm <= inf.D.d_item[0];
	end	
	else if(n_state == OUT) begin
		itm <= No_item;
	end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		p_type <= No_type;
	end				
	else if(inf.type_valid) begin
		p_type <= inf.D.d_type[0];
	end	
	else if(n_state == OUT) begin
		p_type <= No_type;
	end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		dollar <= 0;
	end				
	else if(inf.amnt_valid) begin
		dollar <= inf.D.d_money;
	end	
	else if(n_state == OUT) begin
		dollar <= 0;
	end
end

//================================================================
//   Pokemon System (pokemon.sv) vs Bridge (bridge.sv)
//================================================================

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)	begin
		inf.C_addr <= 0;
	end
	else begin
		case(n_state)
			READ: begin
				if(act == Attack) begin
					if(give_new_id == 1) begin
						if(inf.C_out_valid) begin
							inf.C_addr <= id2;
						end
						else
							inf.C_addr <= id1;
					end
					else if(give_new_id == 0)
						inf.C_addr <= id2;
					else if(atk_id_cnt == 0)
						inf.C_addr <= id1;
					else 
						inf.C_addr <= id1;
				end
				else 
					inf.C_addr <= id1;
			end
			WAIT: begin
				inf.C_addr <= id1;
			end
			WRITE: begin
				if(act == Attack) begin
					if(inf.C_out_valid) begin
						inf.C_addr <= id2;
					end
				end
				else begin
					inf.C_addr <= id1;
				end
			end
		endcase
	end
end

logic[3:0] oatk;
assign oatk = plr1[15:12]-2;
assign inf.C_data_w = (inf.C_addr == id1 && (((act == Use_item && itm == Bracer) || (bracer_cnt > 0 && act != Attack)) && act != Sell))? {plr1[7:4], plr1[3:0], oatk, plr1[11:8], plr1[23:16], plr1[31:24], plr1[39:36], plr1[35:32], plr1[47:40], (plr1[55:48]), plr1[63:56]} :
					  (inf.C_addr == id1 && !(((act == Use_item && itm == Bracer) || (bracer_cnt > 0 && act != Attack)) && act != Sell))? {plr1[7:4], plr1[3:0], plr1[15:12], plr1[11:8], plr1[23:16], plr1[31:24], plr1[39:36], plr1[35:32], plr1[47:40], plr1[55:48], plr1[63:56]} :
					  (inf.C_addr == id2)? {plr2[7:4], plr2[3:0], plr2[15:12], plr2[11:8], plr2[23:16], plr2[31:24], plr2[39:36], plr2[35:32], plr2[47:40], plr2[55:48], plr2[63:56]} : 0;
/*
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n)	begin
		inf.C_data_w = 0 ;
	end	
	else begin
		if((n_state == WAIT || n_state == WRITE) && inf.err_msg == No_Err) begin
			
			if(inf.C_addr == id1) begin
				if(((act == Use_item && itm == Bracer) || (bracer_cnt > 0 && act != Attack)) && act != Sell) begin
					inf.C_data_w = {plr1[7:4], plr1[3:0], oatk, plr1[11:8], plr1[23:16], plr1[31:24], plr1[39:36], plr1[35:32], plr1[47:40], (plr1[55:48]), plr1[63:56]};
				end
				else begin
					inf.C_data_w = {plr1[7:4], plr1[3:0], plr1[15:12], plr1[11:8], plr1[23:16], plr1[31:24], plr1[39:36], plr1[35:32], plr1[47:40], plr1[55:48], plr1[63:56]};
				end
			end
			else if(inf.C_addr == id2) begin
				inf.C_data_w = {plr2[7:4], plr2[3:0], plr2[15:12], plr2[11:8], plr2[23:16], plr2[31:24], plr2[39:36], plr2[35:32], plr2[47:40], plr2[55:48], plr2[63:56]};
			end
		end
	end
end*/

always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) begin
		cin_flag <= 0;
	end	
	else begin
		if (n_state == WRITE) begin
			cin_flag <= cin_flag+1;
		end	
		else if(n_state == IN) begin
			if(inf.C_out_valid) begin
				cin_flag <= cin_flag+1;
			end
		end
		else begin
			cin_flag <= 0;
		end						
	end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) begin
		cnt <= 0 ;
	end		
	else begin
		if(n_state == READ) begin
			cnt <= 1 ;
		end
		else if(n_state == WORK) begin
			cnt <= 0 ;
		end
		else if(n_state == WRITE) begin
			cnt <= 1 ;
		end
		else if(n_state == IN) begin
			cnt <= 0 ;
		end
	end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) begin
		inf.C_in_valid <= 0 ;
	end		
	else begin
		if(inf.err_msg == No_Err) begin
			if(n_state == READ && act != Attack && cnt ==0 && give_new_id == 1) begin
				inf.C_in_valid <= 1 ;
			end
			else if(n_state == READ && act == Attack && (cnt ==0 || inf.C_out_valid) && give_new_id == 1) begin
				inf.C_in_valid <= 1 ;
			end
			else if(n_state == READ && act == Attack && cnt ==0 && id1 != id2 && give_new_id == 0) begin
				inf.C_in_valid <= 1 ;
			end
			else if(n_state == WRITE && act != Attack && cnt ==0) begin
				inf.C_in_valid <= 1 ;
			end
			else if(n_state == WRITE && act == Attack && cnt ==0) begin
				inf.C_in_valid <= 1 ;
			end
			else if(n_state == WRITE && act == Attack && cnt ==1  && inf.C_out_valid) begin
				inf.C_in_valid <= 1 ;
			end
			else begin
				inf.C_in_valid <= 0 ;
			end
		end
	end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) begin
		inf.C_r_wb <= 0 ;
	end 	
	else begin
		case(n_state)
			IN: begin
				inf.C_r_wb <= READ_DRAM;
			end	
			WRITE: begin
				inf.C_r_wb <= WRITE_DRAM;
			end	
		endcase 
	end
end

//================================================================
//   OUTPUT
//================================================================

always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) begin
		inf.out_valid <= 0;
	end	
	else begin
		if (n_state == OUT) begin
			inf.out_valid <= 1;
		end	
		else begin
			inf.out_valid <= 0;
		end						
	end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) begin
		inf.out_info <= 0;
	end	
	else begin
		if (n_state == OUT && inf.complete != 0 ) begin
			if(act == Attack) begin
				inf.out_info <= {plr1.pkm_info, plr2.pkm_info};
			end
			else if(act == Sell) begin
				inf.out_info <= {plr1.bag_info, plr1_old.pkm_info};
			end
			else begin
				inf.out_info <= plr1;	
			end
		end
		else begin
			inf.out_info <= 0;
		end		
	end
end

//================================================================
//   FLAG
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		atk_id_cnt <= 0 ;
	end				
	else begin 
		if(act == Attack && n_state == IN && give_new_id == 0) begin
			atk_id_cnt <= 1;
		end
		else if(act == Attack && n_state == READ && give_new_id == 1) begin
			if(inf.C_out_valid)
				atk_id_cnt <= atk_id_cnt+1;
		end
		else if(n_state == OUT)	begin
			atk_id_cnt <= 0 ;
		end
	end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		done <= 0 ;
	end				
	else begin 
		if(act != Attack && n_state == IN && give_new_id) begin
			if(inf.C_out_valid)
				done <= 1 ; 
		end

		else if(n_state == OUT)	begin
			done <= 0 ;
		end
	end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		w_done <= 0 ;
	end				
	else begin 
		if(act == Attack && n_state == WRITE) begin
			if(inf.C_out_valid)
				w_done <= w_done+1 ;
		end		
		else if(n_state == OUT)	begin
			w_done <= 0 ;
		end
	end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		flag_id1 <= 0 ;
	end				
	else begin 
		//if(inf.id_valid) begin
		if(give_new_id == 0 && n_state == IN)
			flag_id1 <= 0 ;
		else if(give_new_id == 1 && n_state == IN)
			flag_id1 <= 1 ;
		//end		
		else if(n_state == OUT)	begin
			flag_id1 <= 0 ;
		end
	end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		flag_id2 <= 0 ;
	end				
	else begin 
		if(n_state == IDLE) begin
			flag_id2 <= 0 ;
		end
		else if((flag_id1 && act == Attack) || (!give_new_id && act == Attack/* && n_state == IN && inf.id_valid) || (!flag_id1 && act == Attack && n_state == IN && !give_new_id*/)) begin
			flag_id2 <= 1 ;
		end/*
		else if(give_new_id == 0 && flag_id1 == 0 && n_state == IN) begin
			flag_id2 <= 1 ;
		end*/
		else if(n_state == OUT)	begin
			flag_id2 <= 0 ;
		end
	end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		flag_type <= 0 ;
	end				
	else begin 
		if(inf.type_valid) begin
			flag_type <= 1 ;
		end		
		else if(n_state == OUT)	begin
			flag_type <= 0 ;
		end
	end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		flag_item <= 0 ;
	end				
	else begin 
		if(inf.item_valid) begin
			flag_item <= 1 ;
		end		
		else if(n_state == OUT)	begin
			flag_item <= 0 ;
		end
	end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		bracer_cnt<= 0 ;
	end				
	else begin 
		if(itm == Bracer && n_state == WORK && act == Use_item) begin
			bracer_cnt <= bracer_cnt+1;
		end
		else if(inf.err_msg == No_Err && n_state == OUT && act == Sell) begin
			bracer_cnt <= 0 ;
		end
		else if(inf.err_msg == No_Err && n_state == WRITE && plr1.pkm_info.stage != plr_re.pkm_info.stage && act == Use_item && itm == Candy) begin
			bracer_cnt <= 0 ;
		end
		else if(inf.err_msg == Not_Having_Item && n_state == OUT && act == Use_item && itm == Bracer) begin
			if(bracer_cnt > 0) begin
				bracer_cnt <= bracer_cnt-1;
			end
			else begin
				bracer_cnt <= 0 ;
			end
			
		end
		else if(inf.err_msg == Not_Having_PKM && n_state == OUT && act == Use_item && itm == Bracer) begin
			bracer_cnt <= 0 ;
		end
		else if(act == Attack && n_state == OUT && inf.err_msg == No_Err) begin
			bracer_cnt <= 0 ;
		end
		else if(give_new_id && n_state == IN) begin
			bracer_cnt <= 0 ;
		end
	end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		give_new_id <= 0 ;
	end				
	else begin 
		if(inf.id_valid) begin
			if(act == Attack) begin
				give_new_id <= give_new_id;
			end
			else begin
				give_new_id <= 1;
			end
			
		end	
		else if(n_state == OUT)	begin
			give_new_id <= 0 ;
		end
		
	end
end
//================================================================
//   ERROR
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) begin
		inf.err_msg <= No_Err;
	end 	
	else begin
		if(n_state == WAIT) begin
			case(act)
				Buy: begin
					if(flag_type) begin
						case(p_type)
							Grass: begin
								if(plr1.bag_info.money < 100) begin
									inf.err_msg <= Out_of_money;
								end
								else if(plr1.pkm_info.pkm_type != No_type) begin
									inf.err_msg <= Already_Have_PKM;
								end
							end
							Fire: begin
								if(plr1.bag_info.money < 90) begin
									inf.err_msg <= Out_of_money;
								end
								else if(plr1.pkm_info.pkm_type != No_type) begin
									inf.err_msg <= Already_Have_PKM;
								end
							end
							Water: begin
								if(plr1.bag_info.money < 110) begin
									inf.err_msg <= Out_of_money;
								end
								else if(plr1.pkm_info.pkm_type != No_type) begin
									inf.err_msg <= Already_Have_PKM;
								end
							end
							Electric: begin
								if(plr1.bag_info.money < 120) begin
									inf.err_msg <= Out_of_money;
								end
								else if(plr1.pkm_info.pkm_type != No_type) begin
									inf.err_msg <= Already_Have_PKM;
								end
							end
						endcase
					end
					else if(flag_item) begin
						case(itm)
							Berry: begin
								if(plr1.bag_info.money < 16) begin
									inf.err_msg <= Out_of_money;
								end
								else if(plr1.bag_info.berry_num == 15) begin
									inf.err_msg <= Bag_is_full;
								end
							end
							Medicine: begin
								if(plr1.bag_info.money < 128) begin
									inf.err_msg <= Out_of_money;
								end
								else if(plr1.bag_info.medicine_num == 15) begin
									inf.err_msg <= Bag_is_full;
								end
							end
							Candy: begin
								if(plr1.bag_info.money < 300) begin
									inf.err_msg <= Out_of_money;
								end
								else if(plr1.bag_info.candy_num == 15) begin
									inf.err_msg <= Bag_is_full;
								end
							end
							Bracer: begin
								if(plr1.bag_info.money < 64) begin
									inf.err_msg <= Out_of_money;
								end
								else if(plr1.bag_info.bracer_num == 15) begin
									inf.err_msg <= Bag_is_full;
								end
							end
						endcase
					end
				end
				Sell: begin
					if(plr1.pkm_info.pkm_type == No_type) begin
						inf.err_msg <= Not_Having_PKM;
					end
					else if(plr1.pkm_info.stage == Lowest) begin
						inf.err_msg <= Has_Not_Grown;
					end
				end
				Use_item: begin
					if(plr1.pkm_info.pkm_type == No_type) begin
						inf.err_msg <= Not_Having_PKM;
					end
					else if(itm == Berry && plr1.bag_info.berry_num == 0) begin
						inf.err_msg <= Not_Having_Item;
					end
					else if(itm == Medicine && plr1.bag_info.medicine_num == 0) begin
						inf.err_msg <= Not_Having_Item;
					end
					else if(itm == Candy && plr1.bag_info.candy_num == 0) begin
						inf.err_msg <= Not_Having_Item;
					end
					else if(itm == Bracer && plr1.bag_info.bracer_num == 0) begin
						inf.err_msg <= Not_Having_Item;
					end
				end
				Attack: begin
					if(plr1.pkm_info.pkm_type == No_type || plr2.pkm_info.pkm_type == No_type) begin
						inf.err_msg <= Not_Having_PKM;
					end
					else if(plr1.pkm_info.hp == 0 || plr2.pkm_info.hp == 0) begin
						inf.err_msg <= HP_is_Zero;
					end
				end
			endcase
		end
		else if (state == IDLE)	begin
			inf.err_msg <= No_Err;
		end	
	end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) begin
		inf.complete <= 0;
	end 	
	else begin
		if(n_state == WAIT) begin
			case(act)
				Buy: begin
					if(flag_type) begin
						case(p_type)
							Grass: begin
								if(plr1.bag_info.money < 100 || plr1.pkm_info.pkm_type != No_type) begin
									inf.complete <= 0;
								end
							end
							Fire: begin
								if(plr1.bag_info.money < 90 || plr1.pkm_info.pkm_type != No_type) begin
									inf.complete <= 0;
								end
							end
							Water: begin
								if(plr1.bag_info.money < 110 || plr1.pkm_info.pkm_type != No_type) begin
									inf.complete <= 0;
								end
							end
							Electric: begin
								if(plr1.bag_info.money < 120|| plr1.pkm_info.pkm_type != No_type) begin
									inf.complete <= 0;
								end
							end
						endcase
					end
					else if(flag_item) begin
						case(itm)
							Berry: begin
								if(plr1.bag_info.money < 16 || plr1.bag_info.berry_num == 15) begin
									inf.complete <= 0;
								end
							end
							Medicine: begin
								if(plr1.bag_info.money < 128 ||plr1.bag_info.medicine_num == 15) begin
									inf.complete <= 0;
								end
							end
							Candy: begin
								if(plr1.bag_info.money < 300 || plr1.bag_info.candy_num == 15) begin
									inf.complete <= 0;
								end
							end
							Bracer: begin
								if(plr1.bag_info.money < 64 || plr1.bag_info.bracer_num == 15) begin
									inf.complete <= 0;
								end
							end
						endcase
					end
				end
				Sell: begin
					if(plr1.pkm_info.pkm_type == No_type || plr1.pkm_info.stage == Lowest) begin
						inf.complete <= 0;
					end
				end
				Use_item: begin
					if(plr1.pkm_info.pkm_type == No_type || (itm == Berry && plr1.bag_info.berry_num == 0) || (itm == Medicine && plr1.bag_info.medicine_num == 0) || (itm == Candy && plr1.bag_info.candy_num == 0) || (itm == Bracer && plr1.bag_info.bracer_num == 0)) begin
						inf.complete <= 0;
					end
				end
				Attack: begin
					if(plr1.pkm_info.pkm_type == No_type || plr2.pkm_info.pkm_type == No_type || plr1.pkm_info.hp == 0 || plr2.pkm_info.hp == 0) begin
						inf.complete <= 0;
					end
				end
			endcase
		end
		else if (state == IDLE)	begin
			inf.complete <= 1;
		end	
	end
end
//================================================================
//   CALCULATION
//================================================================


always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		plr_re <= 0 ;
	end				
	else begin 
		if(n_state == OUT) begin
			plr_re <= plr1;
		end	
	end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		plr1_old <= 0 ;
	end				
	else begin 
		if(n_state == WAIT) begin
			plr1_old <= plr1;
		end	
	end
end


always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		plr1 <= 0 ;
	end				
	else begin 
		if( give_new_id == 0 && n_state == WORK) begin
			plr1 <= plr_re;
		end
		else if(inf.C_out_valid && flag_id1 == 1 && give_new_id == 1 && atk_id_cnt == 0 && n_state == READ && act == Attack) begin
			plr1 <= {inf.C_data_r[7:4], inf.C_data_r[3:0], inf.C_data_r[15:12], inf.C_data_r[11:8], inf.C_data_r[23:16], inf.C_data_r[31:24], inf.C_data_r[39:36], inf.C_data_r[35:32], inf.C_data_r[47:40], inf.C_data_r[55:48], inf.C_data_r[63:56]};
		end	
		else if(inf.C_out_valid && flag_id1 == 1 && give_new_id == 1 && atk_id_cnt == 0 && n_state == WORK && act != Attack) begin
			plr1 <= {inf.C_data_r[7:4], inf.C_data_r[3:0], inf.C_data_r[15:12], inf.C_data_r[11:8], inf.C_data_r[23:16], inf.C_data_r[31:24], inf.C_data_r[39:36], inf.C_data_r[35:32], inf.C_data_r[47:40], inf.C_data_r[55:48], inf.C_data_r[63:56]};
		end	
		else if(n_state == WAIT) begin

			case(act)
				Buy: begin
					if(flag_type) begin
						case(p_type)
							Grass: begin
								if(plr1.bag_info.money >= 100 && plr1.pkm_info.pkm_type == No_type) begin
									plr1.pkm_info.stage <= Lowest;
									plr1.pkm_info.pkm_type <= p_type;
									plr1.pkm_info.exp <= 0;
									plr1.pkm_info.hp <= 128;
									plr1.pkm_info.atk <= 63;
									plr1.bag_info.money <= plr1.bag_info.money-100;
								end
							end
							Fire: begin
								if(plr1.bag_info.money >= 90 && plr1.pkm_info.pkm_type == No_type) begin
									plr1.pkm_info.stage <= Lowest;
									plr1.pkm_info.pkm_type <= p_type;
									plr1.pkm_info.exp <= 0;
									plr1.pkm_info.hp <= 119;
									plr1.pkm_info.atk <= 64;
									plr1.bag_info.money <= plr1.bag_info.money-90;
								end
							end
							Water: begin
								if(plr1.bag_info.money >= 110 && plr1.pkm_info.pkm_type == No_type) begin
									plr1.pkm_info.stage <= Lowest;
									plr1.pkm_info.pkm_type <= p_type;
									plr1.pkm_info.exp <= 0;
									plr1.pkm_info.hp <= 125;
									plr1.pkm_info.atk <= 60;
									plr1.bag_info.money <= plr1.bag_info.money-110;
								end
							end
							Electric: begin
								if(plr1.bag_info.money >= 120 && plr1.pkm_info.pkm_type == No_type) begin
									plr1.pkm_info.stage <= Lowest;
									plr1.pkm_info.pkm_type <= p_type;
									plr1.pkm_info.exp <= 0;
									plr1.pkm_info.hp <= 122;
									plr1.pkm_info.atk <= 65;
									plr1.bag_info.money <= plr1.bag_info.money-120;
								end
							end
						endcase
					end
					else if(flag_item) begin
						case(itm)
							Berry: begin
								if(plr1.bag_info.money >= 16 && plr1.bag_info.berry_num < 15) begin
									plr1.bag_info.berry_num <= plr1.bag_info.berry_num+1;
									plr1.bag_info.money <= plr1.bag_info.money-16;
								end
							end
							Medicine: begin
								if(plr1.bag_info.money >= 128 && plr1.bag_info.medicine_num < 15) begin
									plr1.bag_info.medicine_num <= plr1.bag_info.medicine_num+1;
									plr1.bag_info.money <= plr1.bag_info.money-128;
								end
							end
							Candy: begin
								if(plr1.bag_info.money >= 300 && plr1.bag_info.candy_num < 15) begin
									plr1.bag_info.candy_num <= plr1.bag_info.candy_num+1;
									plr1.bag_info.money <= plr1.bag_info.money-300;
								end
							end
							Bracer: begin
								if(plr1.bag_info.money >= 64 && plr1.bag_info.bracer_num < 15) begin
									plr1.bag_info.bracer_num <= plr1.bag_info.bracer_num+1;
									plr1.bag_info.money <= plr1.bag_info.money-64;
								end
							end
						endcase
					end
				end
				Sell: begin
					if(plr1.pkm_info.pkm_type != No_type && plr1.pkm_info.stage != Lowest) begin
						case(plr1.pkm_info.pkm_type)
							Grass: begin
								case(plr1.pkm_info.stage)
									Middle: begin
										plr1.bag_info.money <= plr1.bag_info.money+510;
										plr1.pkm_info.stage <= No_stage;
										plr1.pkm_info.pkm_type <= No_type;
										plr1.pkm_info.hp <= 0;
										plr1.pkm_info.atk <= 0;
										plr1.pkm_info.exp <= 0;
									end
									Highest: begin
										plr1.bag_info.money <= plr1.bag_info.money+1100;
										plr1.pkm_info.stage <= No_stage;
										plr1.pkm_info.pkm_type <= No_type;
										plr1.pkm_info.hp <= 0;
										plr1.pkm_info.atk <= 0;
										plr1.pkm_info.exp <= 0;
									end
								endcase
							end
							Fire: begin
								case(plr1.pkm_info.stage)
									Middle: begin
										plr1.bag_info.money <= plr1.bag_info.money+450;
										plr1.pkm_info.stage <= No_stage;
										plr1.pkm_info.pkm_type <= No_type;
										plr1.pkm_info.hp <= 0;
										plr1.pkm_info.atk <= 0;
										plr1.pkm_info.exp <= 0;
									end
									Highest: begin
										plr1.bag_info.money <= plr1.bag_info.money+1000;
										plr1.pkm_info.stage <= No_stage;
										plr1.pkm_info.pkm_type <= No_type;
										plr1.pkm_info.hp <= 0;
										plr1.pkm_info.atk <= 0;
										plr1.pkm_info.exp <= 0;
									end
								endcase
							end
							Water: begin
								case(plr1.pkm_info.stage)
									Middle: begin
										plr1.bag_info.money <= plr1.bag_info.money+500;
										plr1.pkm_info.stage <= No_stage;
										plr1.pkm_info.pkm_type <= No_type;
										plr1.pkm_info.hp <= 0;
										plr1.pkm_info.atk <= 0;
										plr1.pkm_info.exp <= 0;
									end
									Highest: begin
										plr1.bag_info.money <= plr1.bag_info.money+1200;
										plr1.pkm_info.stage <= No_stage;
										plr1.pkm_info.pkm_type <= No_type;
										plr1.pkm_info.hp <= 0;
										plr1.pkm_info.atk <= 0;
										plr1.pkm_info.exp <= 0;
									end
								endcase
							end
							Electric: begin
								case(plr1.pkm_info.stage)
									Middle: begin
										plr1.bag_info.money <= plr1.bag_info.money+550;
										plr1.pkm_info.stage <= No_stage;
										plr1.pkm_info.pkm_type <= No_type;
										plr1.pkm_info.hp <= 0;
										plr1.pkm_info.atk <= 0;
										plr1.pkm_info.exp <= 0;
									end
									Highest: begin
										plr1.bag_info.money <= plr1.bag_info.money+1300;
										plr1.pkm_info.stage <= No_stage;
										plr1.pkm_info.pkm_type <= No_type;
										plr1.pkm_info.hp <= 0;
										plr1.pkm_info.atk <= 0;
										plr1.pkm_info.exp <= 0;
									end
								endcase
							end
						endcase
					end
				end
				Deposit: begin
					plr1.bag_info.money <= plr1.bag_info.money+dollar;
				end
				Use_item: begin
					case(itm)
							Berry: begin
								if(plr1.bag_info.berry_num > 0 && plr1.pkm_info.pkm_type != No_type) begin
									plr1.bag_info.berry_num <= plr1.bag_info.berry_num-1;
									case(plr1.pkm_info.pkm_type)
										Grass: begin
											case(plr1.pkm_info.stage)
												Lowest: begin
													if(plr1.pkm_info.hp < 96) begin
														plr1.pkm_info.hp <= plr1.pkm_info.hp+32;
													end
													else begin
														plr1.pkm_info.hp <= 128;
													end
												end
												Middle: begin
													if(plr1.pkm_info.hp < 160) begin
														plr1.pkm_info.hp <= plr1.pkm_info.hp+32;
													end
													else begin
														plr1.pkm_info.hp <= 192;
													end
												end
												Highest: begin
													if(plr1.pkm_info.hp < 222) begin
														plr1.pkm_info.hp <= plr1.pkm_info.hp+32;
													end
													else begin
														plr1.pkm_info.hp <= 254;
													end
												end
											endcase
										end
										Fire: begin
											case(plr1.pkm_info.stage)
												Lowest: begin
													if(plr1.pkm_info.hp < 87) begin
														plr1.pkm_info.hp <= plr1.pkm_info.hp+32;
													end
													else begin
														plr1.pkm_info.hp <= 119;
													end
												end
												Middle: begin
													if(plr1.pkm_info.hp < 145) begin
														plr1.pkm_info.hp <= plr1.pkm_info.hp+32;
													end
													else begin
														plr1.pkm_info.hp <= 177;
													end
												end
												Highest: begin
													if(plr1.pkm_info.hp < 193) begin
														plr1.pkm_info.hp <= plr1.pkm_info.hp+32;
													end
													else begin
														plr1.pkm_info.hp <= 225;
													end
												end
											endcase
										end
										Water: begin
											case(plr1.pkm_info.stage)
												Lowest: begin
													if(plr1.pkm_info.hp < 93) begin
														plr1.pkm_info.hp <= plr1.pkm_info.hp+32;
													end
													else begin
														plr1.pkm_info.hp <= 125;
													end
												end
												Middle: begin
													if(plr1.pkm_info.hp < 155) begin
														plr1.pkm_info.hp <= plr1.pkm_info.hp+32;
													end
													else begin
														plr1.pkm_info.hp <= 187;
													end
												end
												Highest: begin
													if(plr1.pkm_info.hp < 213) begin
														plr1.pkm_info.hp <= plr1.pkm_info.hp+32;
													end
													else begin
														plr1.pkm_info.hp <= 245;
													end
												end
											endcase
										end
										Electric: begin
											case(plr1.pkm_info.stage)
												Lowest: begin
													if(plr1.pkm_info.hp < 90) begin
														plr1.pkm_info.hp <= plr1.pkm_info.hp+32;
													end
													else begin
														plr1.pkm_info.hp <= 122;
													end
												end
												Middle: begin
													if(plr1.pkm_info.hp < 150) begin
														plr1.pkm_info.hp <= plr1.pkm_info.hp+32;
													end
													else begin
														plr1.pkm_info.hp <= 182;
													end
												end
												Highest: begin
													if(plr1.pkm_info.hp < 203) begin
														plr1.pkm_info.hp <= plr1.pkm_info.hp+32;
													end
													else begin
														plr1.pkm_info.hp <= 235;
													end
												end
											endcase
										end
									endcase
								end
							end
							Medicine: begin
								if(plr1.bag_info.medicine_num > 0 && plr1.pkm_info.pkm_type != No_type) begin
									plr1.bag_info.medicine_num <= plr1.bag_info.medicine_num-1;
									case(plr1.pkm_info.pkm_type)
										Grass: begin
											case(plr1.pkm_info.stage)
												Lowest: begin
													plr1.pkm_info.hp <= 128;
												end
												Middle: begin
													plr1.pkm_info.hp <= 192;
												end
												Highest: begin
													plr1.pkm_info.hp <= 254;
												end
											endcase
										end
										Fire: begin
											case(plr1.pkm_info.stage)
												Lowest: begin
													plr1.pkm_info.hp <= 119;
												end
												Middle: begin
													plr1.pkm_info.hp <= 177;
												end
												Highest: begin
													plr1.pkm_info.hp <= 225;
												end
											endcase
										end
										Water: begin
											case(plr1.pkm_info.stage)
												Lowest: begin
													plr1.pkm_info.hp <= 125;
												end
												Middle: begin
													plr1.pkm_info.hp <= 187;
												end
												Highest: begin
													plr1.pkm_info.hp <= 245;
												end
											endcase
										end
										Electric: begin
											case(plr1.pkm_info.stage)
												Lowest: begin
													plr1.pkm_info.hp <= 122;
												end
												Middle: begin
													plr1.pkm_info.hp <= 182;
												end
												Highest: begin
													plr1.pkm_info.hp <= 235;
												end
											endcase
										end
									endcase
								end
							end
							Candy: begin
								if(plr1.bag_info.candy_num > 0 && plr1.pkm_info.pkm_type != No_type) begin
									plr1.bag_info.candy_num <= plr1.bag_info.candy_num-1;
									case(plr1.pkm_info.pkm_type)
										Grass: begin
											case(plr1.pkm_info.stage)
												Lowest: begin
													if(plr1.pkm_info.exp < 17) begin
														plr1.pkm_info.exp <= plr1.pkm_info.exp+15;
													end
													else begin
														plr1.pkm_info.exp <= 0;
														plr1.pkm_info.stage <= Middle;
														plr1.pkm_info.hp <= 192;
														plr1.pkm_info.atk <= 94;
													end
												end
												Middle: begin
													if(plr1.pkm_info.exp < 48) begin
														plr1.pkm_info.exp <= plr1.pkm_info.exp+15;
													end
													else begin
														plr1.pkm_info.exp <= 0;
														plr1.pkm_info.stage <= Highest;
														plr1.pkm_info.hp <= 254;
														plr1.pkm_info.atk <= 123;
													end
												end
												Highest: begin
													plr1.pkm_info.exp <= 0;
												end
												default: begin
													plr1.pkm_info.exp <= plr1.pkm_info.exp;
													plr1.pkm_info.stage <= plr1.pkm_info.stage;
												end
											endcase
										end
										Fire: begin
											case(plr1.pkm_info.stage)
												Lowest: begin
													if(plr1.pkm_info.exp < 15) begin
														plr1.pkm_info.exp <= plr1.pkm_info.exp+15;
													end
													else begin
														plr1.pkm_info.exp <= 0;
														plr1.pkm_info.stage <= Middle;
														plr1.pkm_info.hp <= 177;
														plr1.pkm_info.atk <= 96;
													end
												end
												Middle: begin
													if(plr1.pkm_info.exp < 44) begin
														plr1.pkm_info.exp <= plr1.pkm_info.exp+15;
													end
													else begin
														plr1.pkm_info.exp <= 0;
														plr1.pkm_info.stage <= Highest;
														plr1.pkm_info.hp <= 225;
														plr1.pkm_info.atk <= 127;
													end
												end
												Highest: begin
													plr1.pkm_info.exp <= 0;
												end
												default: begin
													plr1.pkm_info.exp <= plr1.pkm_info.exp;
													plr1.pkm_info.stage <= plr1.pkm_info.stage;
												end
											endcase
										end
										Water: begin
											case(plr1.pkm_info.stage)
												Lowest: begin
													if(plr1.pkm_info.exp < 13) begin
														plr1.pkm_info.exp <= plr1.pkm_info.exp+15;
													end
													else begin
														plr1.pkm_info.exp <= 0;
														plr1.pkm_info.stage <= Middle;
														plr1.pkm_info.hp <= 187;
														plr1.pkm_info.atk <= 89;
													end
												end
												Middle: begin
													if(plr1.pkm_info.exp < 40) begin
														plr1.pkm_info.exp <= plr1.pkm_info.exp+15;
													end
													else begin
														plr1.pkm_info.exp <= 0;
														plr1.pkm_info.stage <= Highest;
														plr1.pkm_info.hp <= 245;
														plr1.pkm_info.atk <= 113;
													end
												end
												Highest: begin
													plr1.pkm_info.exp <= 0;
												end
												default: begin
													plr1.pkm_info.exp <= plr1.pkm_info.exp;
													plr1.pkm_info.stage <= plr1.pkm_info.stage;
												end
											endcase
										end
										Electric: begin
											case(plr1.pkm_info.stage)
												Lowest: begin
													if(plr1.pkm_info.exp < 11) begin
														plr1.pkm_info.exp <= plr1.pkm_info.exp+15;
													end
													else begin
														plr1.pkm_info.exp <= 0;
														plr1.pkm_info.stage <= Middle;
														plr1.pkm_info.hp <= 182;
														plr1.pkm_info.atk <= 97;
													end
												end
												Middle: begin
													if(plr1.pkm_info.exp < 36) begin
														plr1.pkm_info.exp <= plr1.pkm_info.exp+15;
													end
													else begin
														plr1.pkm_info.exp <= 0;
														plr1.pkm_info.stage <= Highest;
														plr1.pkm_info.hp <= 235;
														plr1.pkm_info.atk <= 124;
													end
												end
												Highest: begin
													plr1.pkm_info.exp <= 0;
												end
												default: begin
													plr1.pkm_info.exp <= plr1.pkm_info.exp;
													plr1.pkm_info.stage <= plr1.pkm_info.stage;
												end
											endcase
										end
									endcase
								end
							end
							Bracer: begin
								if(plr1.pkm_info.pkm_type == No_type || plr1.bag_info.bracer_num == 0) begin
									plr1.bag_info.bracer_num <= plr1.bag_info.bracer_num;
								end
								else if(plr1.bag_info.bracer_num > 0 && plr1.pkm_info.pkm_type != No_type && bracer_cnt == 1) begin
									plr1.bag_info.bracer_num <= plr1.bag_info.bracer_num-1;
									plr1.pkm_info.atk <= plr1.pkm_info.atk+32;
								end
								else if( bracer_cnt >= 1) begin
									plr1.bag_info.bracer_num <= plr1.bag_info.bracer_num-1;
								end

							end
					endcase
				end
				Check: begin
					plr1 <= plr1;
				end
				Attack: begin
					if(plr1.pkm_info.pkm_type != No_type && plr1.pkm_info.hp != 0 && plr2.pkm_info.pkm_type != No_type && plr2.pkm_info.hp != 0) begin
						case(plr1.pkm_info.pkm_type)
							Grass: begin
								case(plr1.pkm_info.stage)
									Lowest: begin
										case(plr2.pkm_info.stage)
											Lowest: begin
												if(plr1.pkm_info.exp < 16) begin
													plr1.pkm_info.exp <= plr1.pkm_info.exp+16;
													plr1.pkm_info.atk <= 63;
												end
												else begin
													plr1.pkm_info.exp <= 0;
													plr1.pkm_info.stage <= Middle;
													plr1.pkm_info.hp <= 192;
													plr1.pkm_info.atk <= 94;
												end
											end
											Middle: begin
												if(plr1.pkm_info.exp < 8) begin
													plr1.pkm_info.exp <= plr1.pkm_info.exp+24;
													plr1.pkm_info.atk <= 63;
												end
												else begin
													plr1.pkm_info.exp <= 0;
													plr1.pkm_info.stage <= Middle;
													plr1.pkm_info.hp <= 192;
													plr1.pkm_info.atk <= 94;
												end
											end
											Highest: begin
												plr1.pkm_info.exp <= 0;
												plr1.pkm_info.stage <= Middle;
												plr1.pkm_info.hp <= 192;
												plr1.pkm_info.atk <= 94;
											end
										endcase
									end
									Middle: begin
										case(plr2.pkm_info.stage)
											Lowest: begin
												if(plr1.pkm_info.exp < 47) begin
													plr1.pkm_info.exp <= plr1.pkm_info.exp+16;
													plr1.pkm_info.atk <= 94;
												end
												else begin
													plr1.pkm_info.exp <= 0;
													plr1.pkm_info.stage <= Highest;
													plr1.pkm_info.hp <= 254;
													plr1.pkm_info.atk <= 123;
												end
											end
											Middle: begin
												if(plr1.pkm_info.exp < 39) begin
													plr1.pkm_info.exp <= plr1.pkm_info.exp+24;
													plr1.pkm_info.atk <= 94;
												end
												else begin
													plr1.pkm_info.exp <= 0;
													plr1.pkm_info.stage <= Highest;
													plr1.pkm_info.hp <= 254;
													plr1.pkm_info.atk <= 123;
												end
											end
											Highest: begin
												if(plr1.pkm_info.exp < 31) begin
													plr1.pkm_info.exp <= plr1.pkm_info.exp+32;
													plr1.pkm_info.atk <= 94;
												end
												else begin
													plr1.pkm_info.exp <= 0;
													plr1.pkm_info.stage <= Highest;
													plr1.pkm_info.hp <= 254;
													plr1.pkm_info.atk <= 123;
												end
											end
										endcase
									end
									Highest: begin
										plr1.pkm_info.exp <= 0;
										plr1.pkm_info.stage <= Highest;
										plr1.pkm_info.atk <= 123;
									end
								endcase
							end
							Fire: begin
								case(plr1.pkm_info.stage)
									Lowest: begin
										case(plr2.pkm_info.stage)
											Lowest: begin
												if(plr1.pkm_info.exp < 14) begin
													plr1.pkm_info.exp <= plr1.pkm_info.exp+16;
													plr1.pkm_info.atk <= 64;
												end
												else begin
													plr1.pkm_info.exp <= 0;
													plr1.pkm_info.stage <= Middle;
													plr1.pkm_info.hp <= 177;
													plr1.pkm_info.atk <= 96;
												end
											end
											Middle: begin
												if(plr1.pkm_info.exp < 6) begin
													plr1.pkm_info.exp <= plr1.pkm_info.exp+24;
													plr1.pkm_info.atk <= 64;
												end
												else begin
													plr1.pkm_info.exp <= 0;
													plr1.pkm_info.stage <= Middle;
													plr1.pkm_info.hp <= 177;
													plr1.pkm_info.atk <= 96;
												end
											end
											Highest: begin
												plr1.pkm_info.exp <= 0;
												plr1.pkm_info.stage <= Middle;
												plr1.pkm_info.hp <= 177;
												plr1.pkm_info.atk <= 96;
											end
										endcase
									end
									Middle: begin
										case(plr2.pkm_info.stage)
											Lowest: begin
												if(plr1.pkm_info.exp < 43) begin
													plr1.pkm_info.exp <= plr1.pkm_info.exp+16;
													plr1.pkm_info.atk <= 96;
												end
												else begin
													plr1.pkm_info.exp <= 0;
													plr1.pkm_info.stage <= Highest;
													plr1.pkm_info.hp <= 225;
													plr1.pkm_info.atk <= 127;
												end
											end
											Middle: begin
												if(plr1.pkm_info.exp < 35) begin
													plr1.pkm_info.exp <= plr1.pkm_info.exp+24;
													plr1.pkm_info.atk <= 96;
												end
												else begin
													plr1.pkm_info.exp <= 0;
													plr1.pkm_info.stage <= Highest;
													plr1.pkm_info.hp <= 225;
													plr1.pkm_info.atk <= 127;
												end
											end
											Highest: begin
												if(plr1.pkm_info.exp < 27) begin
													plr1.pkm_info.exp <= plr1.pkm_info.exp+32;
													plr1.pkm_info.atk <= 96;
												end
												else begin
													plr1.pkm_info.exp <= 0;
													plr1.pkm_info.stage <= Highest;
													plr1.pkm_info.hp <= 225;
													plr1.pkm_info.atk <= 127;
												end
											end
										endcase
									end
									Highest: begin
										plr1.pkm_info.exp <= 0;
										plr1.pkm_info.stage <= Highest;
										plr1.pkm_info.atk <= 127;
									end
								endcase
							end
							Water: begin
								case(plr1.pkm_info.stage)
									Lowest: begin
										case(plr2.pkm_info.stage)
											Lowest: begin
												if(plr1.pkm_info.exp < 12) begin
													plr1.pkm_info.exp <= plr1.pkm_info.exp+16;
													plr1.pkm_info.atk <= 60;
												end
												else begin
													plr1.pkm_info.exp <= 0;
													plr1.pkm_info.stage <= Middle;
													plr1.pkm_info.hp <= 187;
													plr1.pkm_info.atk <= 89;
												end
											end
											Middle: begin
												if(plr1.pkm_info.exp < 4) begin
													plr1.pkm_info.exp <= plr1.pkm_info.exp+24;
													plr1.pkm_info.atk <= 60;
												end
												else begin
													plr1.pkm_info.exp <= 0;
													plr1.pkm_info.stage <= Middle;
													plr1.pkm_info.hp <= 187;
													plr1.pkm_info.atk <= 89;
												end
											end
											Highest: begin
												plr1.pkm_info.stage <= Middle;
												plr1.pkm_info.exp <= 0;
												plr1.pkm_info.hp <= 187;
												plr1.pkm_info.atk <= 89;
											end
										endcase
									end
									Middle: begin
										case(plr2.pkm_info.stage)
											Lowest: begin
												if(plr1.pkm_info.exp < 39) begin
													plr1.pkm_info.exp <= plr1.pkm_info.exp+16;
													plr1.pkm_info.atk <=89;
												end
												else begin
													plr1.pkm_info.exp <= 0;
													plr1.pkm_info.stage <= Highest;
													plr1.pkm_info.hp <= 245;
													plr1.pkm_info.atk <= 113;
												end
											end
											Middle: begin
												if(plr1.pkm_info.exp < 31) begin
													plr1.pkm_info.exp <= plr1.pkm_info.exp+24;
													plr1.pkm_info.atk <=89;
												end
												else begin
													plr1.pkm_info.exp <= 0;
													plr1.pkm_info.stage <= Highest;
													plr1.pkm_info.hp <= 245;
													plr1.pkm_info.atk <= 113;
												end
											end
											Highest: begin
												if(plr1.pkm_info.exp < 23) begin
													plr1.pkm_info.exp <= plr1.pkm_info.exp+32;
													plr1.pkm_info.atk <=89;
												end
												else begin
													plr1.pkm_info.exp <= 0;
													plr1.pkm_info.stage <= Highest;
													plr1.pkm_info.hp <= 245;
													plr1.pkm_info.atk <= 113;
												end
											end
										endcase
									end
									Highest: begin
										plr1.pkm_info.exp <= 0;
										plr1.pkm_info.stage <= Highest;
										plr1.pkm_info.atk <= 113;
									end
								endcase
							end
							Electric: begin
								case(plr1.pkm_info.stage)
									Lowest: begin
										case(plr2.pkm_info.stage)
											Lowest: begin
												if(plr1.pkm_info.exp < 10) begin
													plr1.pkm_info.exp <= plr1.pkm_info.exp+16;
													plr1.pkm_info.atk <= 65;
												end
												else begin
													plr1.pkm_info.exp <= 0;
													plr1.pkm_info.stage <= Middle;
													plr1.pkm_info.hp <= 182;
													plr1.pkm_info.atk <= 97;
												end
											end
											Middle: begin
												if(plr1.pkm_info.exp < 2) begin
													plr1.pkm_info.exp <= plr1.pkm_info.exp+24;
													plr1.pkm_info.atk <= 65;
												end
												else begin
													plr1.pkm_info.exp <= 0;
													plr1.pkm_info.stage <= Middle;
													plr1.pkm_info.hp <= 182;
													plr1.pkm_info.atk <= 97;
												end
											end
											Highest: begin
												plr1.pkm_info.exp <= 0;
												plr1.pkm_info.stage <= Middle;
												plr1.pkm_info.hp <= 182;
												plr1.pkm_info.atk <= 97;
											end
										endcase
									end
									Middle: begin
										case(plr2.pkm_info.stage)
											Lowest: begin
												if(plr1.pkm_info.exp < 35) begin
													plr1.pkm_info.exp <= plr1.pkm_info.exp+16;
													plr1.pkm_info.atk <= 97;
												end
												else begin
													plr1.pkm_info.exp <= 0;
													plr1.pkm_info.stage <= Highest;
													plr1.pkm_info.hp <= 235;
													plr1.pkm_info.atk <= 124;
												end
											end
											Middle: begin
												if(plr1.pkm_info.exp < 27) begin
													plr1.pkm_info.exp <= plr1.pkm_info.exp+24;
													plr1.pkm_info.atk <= 97;
												end
												else begin
													plr1.pkm_info.exp <= 0;
													plr1.pkm_info.stage <= Highest;
													plr1.pkm_info.hp <= 235;
													plr1.pkm_info.atk <= 124;
												end
											end
											Highest: begin
												if(plr1.pkm_info.exp < 19) begin
													plr1.pkm_info.exp <= plr1.pkm_info.exp+32;
													plr1.pkm_info.atk <= 97;
												end
												else begin
													plr1.pkm_info.exp <= 0;
													plr1.pkm_info.stage <= Highest;
													plr1.pkm_info.hp <= 235;
													plr1.pkm_info.atk <= 124;
												end
											end
										endcase
									end
									Highest: begin
										plr1.pkm_info.exp <= 0;
										plr1.pkm_info.stage <= Highest;
										plr1.pkm_info.atk <= 124;
									end
								endcase
							end
						endcase
					end
				end
			endcase
		end	
		else if(n_state == OUT)	begin
			plr1 <= 0 ;
		end
	end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		plr2 <= 0 ;
	end				
	else begin 
		if(inf.C_out_valid && flag_id2 && n_state == WORK) begin
			plr2 <= {inf.C_data_r[7:4], inf.C_data_r[3:0], inf.C_data_r[15:12], inf.C_data_r[11:8], inf.C_data_r[23:16],  inf.C_data_r[31:24], inf.C_data_r[39:36], inf.C_data_r[35:32], inf.C_data_r[47:40], inf.C_data_r[55:48], inf.C_data_r[63:56]};
		end
		else if(n_state == WAIT) begin
			if(act == Attack) begin
				if(plr1.pkm_info.pkm_type != No_type && plr1.pkm_info.hp != 0 && plr2.pkm_info.pkm_type != No_type && plr2.pkm_info.hp != 0) begin
					case(plr2.pkm_info.pkm_type)
						Grass: begin
							case(plr2.pkm_info.stage)
								Lowest: begin
									case(plr1.pkm_info.stage)
										Lowest: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.exp >= 24) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 192;
														plr2.pkm_info.atk <= 94;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Fire: begin
													if(plr2.pkm_info.exp >= 24) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 192;
														plr2.pkm_info.atk <= 94;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Water: begin
													if(plr2.pkm_info.exp >= 24) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 192;
														plr2.pkm_info.atk <= 94;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Electric: begin
													if(plr2.pkm_info.exp >= 24) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 192;
														plr2.pkm_info.atk <= 94;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
											endcase
										end
										Middle: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.exp >= 20) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 192;
														plr2.pkm_info.atk <= 94;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Fire: begin
													if(plr2.pkm_info.exp >= 20) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 192;
														plr2.pkm_info.atk <= 94;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Water: begin
													if(plr2.pkm_info.exp >= 20) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 192;
														plr2.pkm_info.atk <= 94;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Electric: begin
													if(plr2.pkm_info.exp >= 20) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 192;
														plr2.pkm_info.atk <= 94;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
											endcase
										end
										Highest: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.exp >= 16) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 192;
														plr2.pkm_info.atk <= 94;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Fire: begin
													if(plr2.pkm_info.exp >= 16) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 192;
														plr2.pkm_info.atk <= 94;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Water: begin
													if(plr2.pkm_info.exp >= 16) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 192;
														plr2.pkm_info.atk <= 94;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Electric: begin
													if(plr2.pkm_info.exp >= 16) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 192;
														plr2.pkm_info.atk <= 94;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
											endcase
										end
									endcase
								end
								Middle: begin
									case(plr1.pkm_info.stage)
										Lowest: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.exp >= 55) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 254;
														plr2.pkm_info.atk <= 123;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Fire: begin
													if(plr2.pkm_info.exp >= 55) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 254;
														plr2.pkm_info.atk <= 123;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Water: begin
													if(plr2.pkm_info.exp >= 55) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 254;
														plr2.pkm_info.atk <= 123;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Electric: begin
													if(plr2.pkm_info.exp >= 55) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 254;
														plr2.pkm_info.atk <= 123;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
											endcase
										end
										Middle: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.exp >= 51) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 254;
														plr2.pkm_info.atk <= 123;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Fire: begin
													if(plr2.pkm_info.exp >= 51) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 254;
														plr2.pkm_info.atk <= 123;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Water: begin
													if(plr2.pkm_info.exp >= 51) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 254;
														plr2.pkm_info.atk <= 123;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Electric: begin
													if(plr2.pkm_info.exp >= 51) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 254;
														plr2.pkm_info.atk <= 123;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
											endcase
										end
										Highest: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.exp >= 47) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 254;
														plr2.pkm_info.atk <= 123;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Fire: begin
													if(plr2.pkm_info.exp >= 47) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 254;
														plr2.pkm_info.atk <= 123;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Water: begin
													if(plr2.pkm_info.exp >= 47) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 254;
														plr2.pkm_info.atk <= 123;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Electric: begin
													if(plr2.pkm_info.exp >= 47) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 254;
														plr2.pkm_info.atk <= 123;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
											endcase
										end
									endcase
								end
								Highest: begin
									case(plr1.pkm_info.stage)
										Lowest: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Fire: begin
													if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Water: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Electric: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
											endcase
										end
										Middle: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Fire: begin
													if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Water: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Electric: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
											endcase
										end
										Highest: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Fire: begin
													if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Water: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Electric: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
											endcase
										end
									endcase
								end
							endcase
						end
						Fire: begin
							case(plr2.pkm_info.stage)
								Lowest: begin
									case(plr1.pkm_info.stage)
										Lowest: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.exp >= 22) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 177;
														plr2.pkm_info.atk <= 96;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Fire: begin
													if(plr2.pkm_info.exp >= 22) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 177;
														plr2.pkm_info.atk <= 96;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Water: begin
													if(plr2.pkm_info.exp >= 22) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 177;
														plr2.pkm_info.atk <= 96;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Electric: begin
													if(plr2.pkm_info.exp >= 22) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 177;
														plr2.pkm_info.atk <= 96;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
											endcase
										end
										Middle: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.exp >= 18) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 177;
														plr2.pkm_info.atk <= 96;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Fire: begin
													if(plr2.pkm_info.exp >= 18) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 177;
														plr2.pkm_info.atk <= 96;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Water: begin
													if(plr2.pkm_info.exp >= 18) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 177;
														plr2.pkm_info.atk <= 96;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Electric: begin
													if(plr2.pkm_info.exp >= 18) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 177;
														plr2.pkm_info.atk <= 96;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
											endcase
										end
										Highest: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.exp >= 14) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 177;
														plr2.pkm_info.atk <= 96;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Fire: begin
													if(plr2.pkm_info.exp >= 14) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 177;
														plr2.pkm_info.atk <= 96;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Water: begin
													if(plr2.pkm_info.exp >= 14) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 177;
														plr2.pkm_info.atk <= 96;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Electric: begin
													if(plr2.pkm_info.exp >= 14) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 177;
														plr2.pkm_info.atk <= 96;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
											endcase
										end
									endcase
								end
								Middle: begin
									case(plr1.pkm_info.stage)
										Lowest: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.exp >= 51) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 225;
														plr2.pkm_info.atk <= 127;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Fire: begin
													if(plr2.pkm_info.exp >= 51) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 225;
														plr2.pkm_info.atk <= 127;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Water: begin
													if(plr2.pkm_info.exp >= 51) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 225;
														plr2.pkm_info.atk <= 127;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Electric: begin
													if(plr2.pkm_info.exp >= 51) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 225;
														plr2.pkm_info.atk <= 127;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
											endcase
										end
										Middle: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.exp >= 47) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 225;
														plr2.pkm_info.atk <= 127;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Fire: begin
													if(plr2.pkm_info.exp >= 47) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 225;
														plr2.pkm_info.atk <= 127;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Water: begin
													if(plr2.pkm_info.exp >= 47) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 225;
														plr2.pkm_info.atk <= 127;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Electric: begin
													if(plr2.pkm_info.exp >= 47) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 225;
														plr2.pkm_info.atk <= 127;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
											endcase
										end
										Highest: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.exp >= 43) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 225;
														plr2.pkm_info.atk <= 127;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Fire: begin
													if(plr2.pkm_info.exp >= 43) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 225;
														plr2.pkm_info.atk <= 127;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Water: begin
													if(plr2.pkm_info.exp >= 43) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 225;
														plr2.pkm_info.atk <= 127;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Electric: begin
													if(plr2.pkm_info.exp >= 43) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 225;
														plr2.pkm_info.atk <= 127;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
											endcase
										end
									endcase
								end
								Highest: begin
									case(plr1.pkm_info.stage)
										Lowest: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Fire: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Water: begin
													if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Electric: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
											endcase
										end
										Middle: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Fire: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Water: begin
													if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Electric: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
											endcase
										end
										Highest: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Fire: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Water: begin
													if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Electric: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
											endcase
										end
									endcase
								end
							endcase
						end
						Water: begin
							case(plr2.pkm_info.stage)
								Lowest: begin
									case(plr1.pkm_info.stage)
										Lowest: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.exp >= 20) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 187;
														plr2.pkm_info.atk <= 89;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Fire: begin
													if(plr2.pkm_info.exp >= 20) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 187;
														plr2.pkm_info.atk <= 89;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Water: begin
													if(plr2.pkm_info.exp >= 20) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 187;
														plr2.pkm_info.atk <= 89;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Electric: begin
													if(plr2.pkm_info.exp >= 20) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 187;
														plr2.pkm_info.atk <= 89;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
											endcase
										end
										Middle: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.exp >= 16) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 187;
														plr2.pkm_info.atk <= 89;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Fire: begin
													if(plr2.pkm_info.exp >= 16) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 187;
														plr2.pkm_info.atk <= 89;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Water: begin
													if(plr2.pkm_info.exp >= 16) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 187;
														plr2.pkm_info.atk <= 89;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Electric: begin
													if(plr2.pkm_info.exp >= 16) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 187;
														plr2.pkm_info.atk <= 89;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
											endcase
										end
										Highest: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.exp >= 12) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 187;
														plr2.pkm_info.atk <= 89;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Fire: begin
													if(plr2.pkm_info.exp >= 12) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 187;
														plr2.pkm_info.atk <= 89;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Water: begin
													if(plr2.pkm_info.exp >= 12) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 187;
														plr2.pkm_info.atk <= 89;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Electric: begin
													if(plr2.pkm_info.exp >= 12) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 187;
														plr2.pkm_info.atk <= 89;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
											endcase
										end
									endcase
								end
								Middle: begin
									case(plr1.pkm_info.stage)
										Lowest: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.exp >= 47) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 245;
														plr2.pkm_info.atk <= 113;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Fire: begin
													if(plr2.pkm_info.exp >= 47) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 245;
														plr2.pkm_info.atk <= 113;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Water: begin
													if(plr2.pkm_info.exp >= 47) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 245;
														plr2.pkm_info.atk <= 113;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Electric: begin
													if(plr2.pkm_info.exp >= 47) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 245;
														plr2.pkm_info.atk <= 113;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
											endcase
										end
										Middle: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.exp >= 43) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 245;
														plr2.pkm_info.atk <= 113;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Fire: begin
													if(plr2.pkm_info.exp >= 43) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 245;
														plr2.pkm_info.atk <= 113;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Water: begin
													if(plr2.pkm_info.exp >= 43) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 245;
														plr2.pkm_info.atk <= 113;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Electric: begin
													if(plr2.pkm_info.exp >= 43) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 245;
														plr2.pkm_info.atk <= 113;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
											endcase
										end
										Highest: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.exp >= 39) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 245;
														plr2.pkm_info.atk <= 113;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Fire: begin
													if(plr2.pkm_info.exp >= 39) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 245;
														plr2.pkm_info.atk <= 113;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Water: begin
													if(plr2.pkm_info.exp >= 39) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 245;
														plr2.pkm_info.atk <= 113;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Electric: begin
													if(plr2.pkm_info.exp >= 39) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 245;
														plr2.pkm_info.atk <= 113;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
											endcase
										end
									endcase
								end
								Highest: begin
									case(plr1.pkm_info.stage)
										Lowest: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Fire: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Water: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Electric: begin
													if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
											endcase
										end
										Middle: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Fire: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Water: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Electric: begin
													if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
											endcase
										end
										Highest: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Fire: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Water: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Electric: begin
													if(plr2.pkm_info.hp > {plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1}) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-{plr1.pkm_info.atk[7], plr1.pkm_info.atk<<1};
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
											endcase
										end
									endcase
								end
							endcase
						end
						Electric: begin
							case(plr2.pkm_info.stage)
								Lowest: begin
									case(plr1.pkm_info.stage)
										Lowest: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.exp >= 18) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 182;
														plr2.pkm_info.atk <= 97;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Fire: begin
													if(plr2.pkm_info.exp >= 18) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 182;
														plr2.pkm_info.atk <= 97;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Water: begin
													if(plr2.pkm_info.exp >= 18) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 182;
														plr2.pkm_info.atk <= 97;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Electric: begin
													if(plr2.pkm_info.exp >= 18) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 182;
														plr2.pkm_info.atk <= 97;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
											endcase
										end
										Middle: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.exp >= 14) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 182;
														plr2.pkm_info.atk <= 97;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Fire: begin
													if(plr2.pkm_info.exp >= 14) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 182;
														plr2.pkm_info.atk <= 97;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Water: begin
													if(plr2.pkm_info.exp >= 14) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 182;
														plr2.pkm_info.atk <= 97;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Electric: begin
													if(plr2.pkm_info.exp >= 14) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 182;
														plr2.pkm_info.atk <= 97;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
											endcase
										end
										Highest: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.exp >= 10) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 182;
														plr2.pkm_info.atk <= 97;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Fire: begin
													if(plr2.pkm_info.exp >= 10) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 182;
														plr2.pkm_info.atk <= 97;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Water: begin
													if(plr2.pkm_info.exp >= 10) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 182;
														plr2.pkm_info.atk <= 97;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Electric: begin
													if(plr2.pkm_info.exp >= 10) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Middle;
														plr2.pkm_info.hp <= 182;
														plr2.pkm_info.atk <= 97;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
											endcase
										end
									endcase
								end
								Middle: begin
									case(plr1.pkm_info.stage)
										Lowest: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.exp >= 43) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 235;
														plr2.pkm_info.atk <= 124;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Fire: begin
													if(plr2.pkm_info.exp >= 43) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 235;
														plr2.pkm_info.atk <= 124;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Water: begin
													if(plr2.pkm_info.exp >= 43) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 235;
														plr2.pkm_info.atk <= 124;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Electric: begin
													if(plr2.pkm_info.exp >= 43) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 235;
														plr2.pkm_info.atk <= 124;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+8;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
											endcase
										end
										Middle: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.exp >= 39) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 235;
														plr2.pkm_info.atk <= 124;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Fire: begin
													if(plr2.pkm_info.exp >= 39) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 235;
														plr2.pkm_info.atk <= 124;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Water: begin
													if(plr2.pkm_info.exp >= 39) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 235;
														plr2.pkm_info.atk <= 124;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Electric: begin
													if(plr2.pkm_info.exp >= 39) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 235;
														plr2.pkm_info.atk <= 124;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+12;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
											endcase
										end
										Highest: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.exp >= 35) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 235;
														plr2.pkm_info.atk <= 124;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Fire: begin
													if(plr2.pkm_info.exp >= 35) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 235;
														plr2.pkm_info.atk <= 124;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Water: begin
													if(plr2.pkm_info.exp >= 35) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 235;
														plr2.pkm_info.atk <= 124;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
												Electric: begin
													if(plr2.pkm_info.exp >= 35) begin
														plr2.pkm_info.exp <= 0;
														plr2.pkm_info.stage <= Highest;
														plr2.pkm_info.hp <= 235;
														plr2.pkm_info.atk <= 124;
													end
													else begin
														plr2.pkm_info.exp <= plr2.pkm_info.exp+16;
														if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
															plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
														end
														else begin
															plr2.pkm_info.hp <= 0;
														end
													end
												end
											endcase
										end
									endcase
								end
								Highest: begin
									case(plr1.pkm_info.stage)
										Lowest: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Fire: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Water: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Electric: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
											endcase
										end
										Middle: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Fire: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Water: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Electric: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
											endcase
										end
										Highest: begin
											case(plr1.pkm_info.pkm_type)
												Grass: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Fire: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Water: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-plr1.pkm_info.atk;
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
												Electric: begin
													if(plr2.pkm_info.hp > plr1.pkm_info.atk>>1) begin
														plr2.pkm_info.hp <= plr2.pkm_info.hp-(plr1.pkm_info.atk>>1);
													end
													else begin
														plr2.pkm_info.hp <= 0;
													end
												end
											endcase
										end
									endcase
								end
							endcase
						end
					endcase
				end
			end
		end
		else if(n_state == OUT)	begin
			plr2 <= 0 ;
		end
	end
end







endmodule