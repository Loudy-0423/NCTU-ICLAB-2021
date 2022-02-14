module SMC(
  // Input signals
    mode,
    W_0, V_GS_0, V_DS_0,
    W_1, V_GS_1, V_DS_1,
    W_2, V_GS_2, V_DS_2,
    W_3, V_GS_3, V_DS_3,
    W_4, V_GS_4, V_DS_4,
    W_5, V_GS_5, V_DS_5,   
  // Output signals
    out_n
);

//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
input [2:0] W_0, V_GS_0, V_DS_0;
input [2:0] W_1, V_GS_1, V_DS_1;
input [2:0] W_2, V_GS_2, V_DS_2;
input [2:0] W_3, V_GS_3, V_DS_3;
input [2:0] W_4, V_GS_4, V_DS_4;
input [2:0] W_5, V_GS_5, V_DS_5;
input [1:0] mode;
//output [8:0] out_n;         							// use this if using continuous assignment for out_n  // Ex: assign out_n = XXX;
output reg [9:0] out_n; 								// use this if using procedure assignment for out_n   // Ex: always@(*) begin out_n = XXX; end

//================================================================
//    Wire & Registers 
//================================================================
// Declare the wire/reg you would use in your circuit
// remember 
// wire for port connection and cont. assignment
// reg for proc. assignment

//reg [9:0] id [5:0];
//reg [9:0] gm [5:0];
reg [59:0] out;


wire [9:0] id [5:0];
wire [9:0] gm [5:0];

//================================================================
//    DESIGN
//================================================================
// --------------------------------------------------
// write your design here
// --------------------------------------------------
assign gm[0] = (V_GS_0-1 > V_DS_0)? ((W_0*V_DS_0)<<1)/3 : (W_0*(V_GS_0-1)<<1)/3;
assign gm[1] = (V_GS_1-1 > V_DS_1)? ((W_1*V_DS_1)<<1)/3 : (W_1*(V_GS_1-1)<<1)/3;
assign gm[2] = (V_GS_2-1 > V_DS_2)? ((W_2*V_DS_2)<<1)/3 : (W_2*(V_GS_2-1)<<1)/3;
assign gm[3] = (V_GS_3-1 > V_DS_3)? ((W_3*V_DS_3)<<1)/3 : (W_3*(V_GS_3-1)<<1)/3;
assign gm[4] = (V_GS_4-1 > V_DS_4)? ((W_4*V_DS_4)<<1)/3 : (W_4*(V_GS_4-1)<<1)/3;
assign gm[5] = (V_GS_5-1 > V_DS_5)? ((W_5*V_DS_5)<<1)/3 : (W_5*(V_GS_5-1)<<1)/3;

assign id[0] = (V_GS_0-1 > V_DS_0)? (W_0*(((V_GS_0-1)<<1)*V_DS_0-V_DS_0*V_DS_0))/3 : (W_0*(V_GS_0-1)*(V_GS_0-1))/3;
assign id[1] = (V_GS_1-1 > V_DS_1)? (W_1*(((V_GS_1-1)<<1)*V_DS_1-V_DS_1*V_DS_1))/3 : (W_1*(V_GS_1-1)*(V_GS_1-1))/3;
assign id[2] = (V_GS_2-1 > V_DS_2)? (W_2*(((V_GS_2-1)<<1)*V_DS_2-V_DS_2*V_DS_2))/3 : (W_2*(V_GS_2-1)*(V_GS_2-1))/3;
assign id[3] = (V_GS_3-1 > V_DS_3)? (W_3*(((V_GS_3-1)<<1)*V_DS_3-V_DS_3*V_DS_3))/3 : (W_3*(V_GS_3-1)*(V_GS_3-1))/3;
assign id[4] = (V_GS_4-1 > V_DS_4)? (W_4*(((V_GS_4-1)<<1)*V_DS_4-V_DS_4*V_DS_4))/3 : (W_4*(V_GS_4-1)*(V_GS_4-1))/3;
assign id[5] = (V_GS_5-1 > V_DS_5)? (W_5*(((V_GS_5-1)<<1)*V_DS_5-V_DS_5*V_DS_5))/3 : (W_5*(V_GS_5-1)*(V_GS_5-1))/3;


always@(*)
begin
if(mode == 2'b00)
begin
  out = sort(gm[0], gm[1], gm[2], gm[3], gm[4], gm[5]);
  out_n = out[29:20]+out[19:10]+out[9:0];
end
else if(mode == 2'b01)
begin
  out = sort(id[0], id[1], id[2], id[3], id[4], id[5]);
  out_n = (out[29:20]<<1)+out[29:20]+(out[19:10]<<2)+(out[9:0]<<2)+out[9:0];
end
else if(mode == 2'b10)
begin
  out = sort(gm[0], gm[1], gm[2], gm[3], gm[4], gm[5]);
  out_n = out[59:50]+out[49:40]+out[39:30];
end
else
begin
  out = sort(id[0], id[1], id[2], id[3], id[4], id[5]);
  out_n = (out[59:50]<<1)+out[59:50]+(out[49:40]<<2)+(out[39:30]<<2)+out[39:30];
end

end

  function [59:0] sort;
  input [9:0] in1, in2, in3, in4, in5, in6;
  integer i, j;
  reg [9:0] temp;
  reg [9:0] array [1:6];
  begin
    array[1] = in1;
    array[2] = in2;
    array[3] = in3;
    array[4] = in4;
    array[5] = in5;
    array[6] = in6;
    for (i = 6; i > 0; i = i - 1) begin
    for (j = 1 ; j < i; j = j + 1) begin
          if (array[j] < array[j + 1])
          begin
            temp = array[j];
            array[j] = array[j + 1];
            array[j + 1] = temp;
    end end
  end 
  sort = {array[1], array[2], array[3], array[4], array[5], array[6]};
  end
  
  endfunction
  
endmodule








//================================================================
//   SUB MODULE
//================================================================

// module BBQ (meat,vagetable,water,cost);
// input XXX;
// output XXX;
// 
// endmodule

// --------------------------------------------------
// Example for using submodule 
// BBQ bbq0(.meat(meat_0), .vagetable(vagetable_0), .water(water_0),.cost(cost[0]));
// --------------------------------------------------
// Example for continuous assignment
// assign out_n = XXX;
// --------------------------------------------------
// Example for procedure assignment
// always@(*) begin 
// 	out_n = XXX; 
// end
// --------------------------------------------------
// Example for case statement
// always @(*) begin
// 	case(op)
// 		2'b00: output_reg = a + b;
// 		2'b10: output_reg = a - b;
// 		2'b01: output_reg = a * b;
// 		2'b11: output_reg = a / b;
// 		default: output_reg = 0;
// 	endcase
// end
// --------------------------------------------------
