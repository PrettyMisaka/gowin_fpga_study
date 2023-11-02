module my_cmos_8_16bit(
	input			   rst_n			,
	input              i_pclk			,
	input [7:0]        i_pdata			,
	input              i_de				,
	output wire[23:0]  o_pdata_bgr888	,
	output wire[15:0]  o_pdata_bgr565	,
	output reg	       o_half_pclk		,
	output wire        o_de				,
	output reg		   o_down			
);
reg working = 0;
reg [15:0] byte2;

reg [7:0] pdata_o;
assign o_pdata_bgr888 = i_de ? {pdata_o[7:3],3'd0,pdata_o[2:0],i_pdata[7:5],2'd0,i_pdata[4:0],3'd0} : 24'h0000;//{r,g,b}
assign o_pdata_bgr565 = i_de ? { pdata_o, i_pdata} : 16'h0000;

reg i_de_bef;
always@(posedge i_pclk) i_de_bef <= i_de;
wire i_de_pos, i_de_neg;
assign i_de_pos = (~i_de_bef)&i_de;
assign i_de_neg = (~i_de)&i_de_bef;

assign o_de = i_de;

always@(posedge i_pclk) pdata_o <= i_pdata;
always@(posedge i_pclk )begin
	if(~rst_n)begin
		o_half_pclk <= 0;
		o_down 		<= 0;
		working		<= 0;
	end
	else begin
		byte2 <= {byte2[0], i_pdata};
		if(working)begin
			o_half_pclk <= ~o_half_pclk;
			o_down 		<= 1;
			if(i_de_neg)
				working		<= 0;
		end
		else begin
			if(i_de_pos) begin
				o_half_pclk <= 1'd1;
				working		<= 1;
			end
			else
				o_half_pclk <= 1'd0;
		end
	end
end
endmodule 