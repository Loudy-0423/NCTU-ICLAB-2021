//synopsys translate_off
`include "/usr/synthesis/dw/sim_ver/DW01_dec.v" 
//synopsys translate_on



module GF2k
#( parameter DEG = 2 , parameter OP = 0)
(
input[DEG:0] POLY,
input[DEG-1:0] IN1,
input[DEG-1:0] IN2,
output reg [DEG-1:0] RESULT
);

genvar k, l;

wire [DEG-1:0] data1, data2;
wire [DEG:0] P;
wire [DEG-1:0] RESULT_TEMP;

wire [DEG-1:0] out1[DEG-1:0], out2 [DEG-1:0];
wire temp0, temp1;


wire [DEG-1:0] vec[2*DEG-1:0];
wire [DEG-1:0] a_sh[2*DEG-1:0], b_sh[2*DEG-1:0], a[2*DEG-1:0];
wire [DEG:0] IRP [2*DEG-1:0], b[2*DEG-1:0];
wire signed [DEG+1:0] delta[2*DEG-1:0];
wire signed [DEG+1:0] delta_dw[2*DEG-1:0];




assign data1 = IN1;
assign data2 = IN2;
assign P = POLY;


generate
    
    if(OP == 0 || OP == 1) begin
        always @(*) begin
            RESULT = data1 ^ data2;
	    end
    end

    else if(OP == 2) begin
        for (k = 0; k<DEG; k=k+1) begin
            for (l = 0; l<DEG; l=l+1) begin
                if (k==0) begin
                    assign out1[k][l] = (P[l] & 1'b0) ^ data2[l];
                    assign out2[k][l] = (data1[k] & out1[k][l]) ^ 1'b0;
                end
                else if (l==0) begin
                    assign out1[k][l] = (P[l] & out1[k-1][DEG-1]) ^ 1'b0;
                    assign out2[k][l] = (data1[k] & out1[k][l]) ^ out2[k-1][l];
                end
                else begin
                    
                    assign out1[k][l] = (P[l] & out1[k-1][DEG-1]) ^ out1[k-1][l-1];
                    assign out2[k][l] = (data1[k] & out1[k][l]) ^ out2[k-1][l];
                end
            end
        end
        always @(*) begin
            RESULT = out2[DEG-1];
        end
    end

    else if(OP == 3) begin
		assign IRP[0] = POLY;
		assign b_sh[0] = IN2;
		assign a_sh[0] = IN1;
		assign delta[0] = -1;
		assign vec[0] = 0;
		for (k = 1; k < 2*DEG; k = k+1) begin
			assign b[k] = (b_sh[k-1][0])? {1'b0, b_sh[k-1][DEG-1:0]} ^ IRP[k-1][DEG:0] : {1'b0, b_sh[k-1][DEG-1:0]};

			assign a[k] = (b_sh[k-1][0])? a_sh[k-1] ^ vec[k-1] : a_sh[k-1];

			assign IRP[k] = (delta[k-1][DEG+1] & b_sh[k-1][0])? {1'b0, b_sh[k-1]} : IRP[k-1];

			assign vec[k] = (delta[k-1][DEG+1] & b_sh[k-1][0])? a_sh[k-1] : vec[k-1];

			assign a_sh[k] = {1'b0, a[k][DEG-1:1]} ^ ({DEG{a[k][0]}} & POLY[DEG:1]);

			assign b_sh[k] = b[k][DEG:1] ^ ({DEG{b[k][0]}} & POLY[DEG:1]);

			DW01_dec #(DEG+2) U_dec(.A(delta[k-1]), .SUM(delta_dw[k]));

			assign delta[k] = (delta[k-1][DEG+1] & b_sh[k-1][0])? ~delta[k-1] : delta_dw[k];
		end
        always @(*) begin
            RESULT = vec[2*DEG-1];
	    end
    end

endgenerate
endmodule


