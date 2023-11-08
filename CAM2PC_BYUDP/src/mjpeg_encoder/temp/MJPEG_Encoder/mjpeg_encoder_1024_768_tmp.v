//Copyright (C)2014-2023 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: V1.9.9 Beta-5
//Part Number: GW2A-LV18PG256C8/I7
//Device: GW2A-18
//Device Version: C
//Created Time: Wed Nov 08 12:38:36 2023

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	MJPEG_Encoder_Top your_instance_name(
		.clk(clk_i), //input clk
		.rstn(rstn_i), //input rstn
		.DE(DE_i), //input DE
		.data_in(data_in_i), //input [23:0] data_in
		.img_out(img_out_o), //output [7:0] img_out
		.img_valid(img_valid_o), //output img_valid
		.img_done(img_done_o) //output img_done
	);

//--------Copy end-------------------
