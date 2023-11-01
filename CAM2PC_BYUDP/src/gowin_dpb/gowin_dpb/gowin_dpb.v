//Copyright (C)2014-2023 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//GOWIN Version: V1.9.9 Beta-5
//Part Number: GW2A-LV18PG256C8/I7
//Device: GW2A-18
//Device Version: C
//Created Time: Wed Nov 01 10:12:53 2023

module Gowin_DPB_128_2048 (douta, doutb, clka, ocea, cea, reseta, wrea, clkb, oceb, ceb, resetb, wreb, ada, dina, adb, dinb);

output [127:0] douta;
output [127:0] doutb;
input clka;
input ocea;
input cea;
input reseta;
input wrea;
input clkb;
input oceb;
input ceb;
input resetb;
input wreb;
input [10:0] ada;
input [127:0] dina;
input [10:0] adb;
input [127:0] dinb;

wire [8:0] dpx9b_inst_0_douta_w;
wire [8:0] dpx9b_inst_0_doutb_w;
wire [8:0] dpx9b_inst_1_douta_w;
wire [8:0] dpx9b_inst_1_doutb_w;
wire [8:0] dpx9b_inst_2_douta_w;
wire [8:0] dpx9b_inst_2_doutb_w;
wire [8:0] dpx9b_inst_3_douta_w;
wire [8:0] dpx9b_inst_3_doutb_w;
wire [8:0] dpx9b_inst_4_douta_w;
wire [8:0] dpx9b_inst_4_doutb_w;
wire [8:0] dpx9b_inst_5_douta_w;
wire [8:0] dpx9b_inst_5_doutb_w;
wire [8:0] dpx9b_inst_6_douta_w;
wire [8:0] dpx9b_inst_6_doutb_w;
wire [8:0] dpx9b_inst_7_douta_w;
wire [8:0] dpx9b_inst_7_doutb_w;
wire [7:0] dpb_inst_8_douta_w;
wire [7:0] dpb_inst_8_doutb_w;
wire [7:0] dpb_inst_9_douta_w;
wire [7:0] dpb_inst_9_doutb_w;
wire [7:0] dpb_inst_10_douta_w;
wire [7:0] dpb_inst_10_doutb_w;
wire [7:0] dpb_inst_11_douta_w;
wire [7:0] dpb_inst_11_doutb_w;
wire [7:0] dpb_inst_12_douta_w;
wire [7:0] dpb_inst_12_doutb_w;
wire [7:0] dpb_inst_13_douta_w;
wire [7:0] dpb_inst_13_doutb_w;
wire [7:0] dpb_inst_14_douta_w;
wire [7:0] dpb_inst_14_doutb_w;
wire gw_gnd;

assign gw_gnd = 1'b0;

DPX9B dpx9b_inst_0 (
    .DOA({dpx9b_inst_0_douta_w[8:0],douta[8:0]}),
    .DOB({dpx9b_inst_0_doutb_w[8:0],doutb[8:0]}),
    .CLKA(clka),
    .OCEA(ocea),
    .CEA(cea),
    .RESETA(reseta),
    .WREA(wrea),
    .CLKB(clkb),
    .OCEB(oceb),
    .CEB(ceb),
    .RESETB(resetb),
    .WREB(wreb),
    .BLKSELA({gw_gnd,gw_gnd,gw_gnd}),
    .BLKSELB({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({ada[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIA({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dina[8:0]}),
    .ADB({adb[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIB({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dinb[8:0]})
);

defparam dpx9b_inst_0.READ_MODE0 = 1'b1;
defparam dpx9b_inst_0.READ_MODE1 = 1'b1;
defparam dpx9b_inst_0.WRITE_MODE0 = 2'b00;
defparam dpx9b_inst_0.WRITE_MODE1 = 2'b00;
defparam dpx9b_inst_0.BIT_WIDTH_0 = 9;
defparam dpx9b_inst_0.BIT_WIDTH_1 = 9;
defparam dpx9b_inst_0.BLK_SEL_0 = 3'b000;
defparam dpx9b_inst_0.BLK_SEL_1 = 3'b000;
defparam dpx9b_inst_0.RESET_MODE = "SYNC";

DPX9B dpx9b_inst_1 (
    .DOA({dpx9b_inst_1_douta_w[8:0],douta[17:9]}),
    .DOB({dpx9b_inst_1_doutb_w[8:0],doutb[17:9]}),
    .CLKA(clka),
    .OCEA(ocea),
    .CEA(cea),
    .RESETA(reseta),
    .WREA(wrea),
    .CLKB(clkb),
    .OCEB(oceb),
    .CEB(ceb),
    .RESETB(resetb),
    .WREB(wreb),
    .BLKSELA({gw_gnd,gw_gnd,gw_gnd}),
    .BLKSELB({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({ada[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIA({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dina[17:9]}),
    .ADB({adb[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIB({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dinb[17:9]})
);

defparam dpx9b_inst_1.READ_MODE0 = 1'b1;
defparam dpx9b_inst_1.READ_MODE1 = 1'b1;
defparam dpx9b_inst_1.WRITE_MODE0 = 2'b00;
defparam dpx9b_inst_1.WRITE_MODE1 = 2'b00;
defparam dpx9b_inst_1.BIT_WIDTH_0 = 9;
defparam dpx9b_inst_1.BIT_WIDTH_1 = 9;
defparam dpx9b_inst_1.BLK_SEL_0 = 3'b000;
defparam dpx9b_inst_1.BLK_SEL_1 = 3'b000;
defparam dpx9b_inst_1.RESET_MODE = "SYNC";

DPX9B dpx9b_inst_2 (
    .DOA({dpx9b_inst_2_douta_w[8:0],douta[26:18]}),
    .DOB({dpx9b_inst_2_doutb_w[8:0],doutb[26:18]}),
    .CLKA(clka),
    .OCEA(ocea),
    .CEA(cea),
    .RESETA(reseta),
    .WREA(wrea),
    .CLKB(clkb),
    .OCEB(oceb),
    .CEB(ceb),
    .RESETB(resetb),
    .WREB(wreb),
    .BLKSELA({gw_gnd,gw_gnd,gw_gnd}),
    .BLKSELB({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({ada[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIA({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dina[26:18]}),
    .ADB({adb[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIB({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dinb[26:18]})
);

defparam dpx9b_inst_2.READ_MODE0 = 1'b1;
defparam dpx9b_inst_2.READ_MODE1 = 1'b1;
defparam dpx9b_inst_2.WRITE_MODE0 = 2'b00;
defparam dpx9b_inst_2.WRITE_MODE1 = 2'b00;
defparam dpx9b_inst_2.BIT_WIDTH_0 = 9;
defparam dpx9b_inst_2.BIT_WIDTH_1 = 9;
defparam dpx9b_inst_2.BLK_SEL_0 = 3'b000;
defparam dpx9b_inst_2.BLK_SEL_1 = 3'b000;
defparam dpx9b_inst_2.RESET_MODE = "SYNC";

DPX9B dpx9b_inst_3 (
    .DOA({dpx9b_inst_3_douta_w[8:0],douta[35:27]}),
    .DOB({dpx9b_inst_3_doutb_w[8:0],doutb[35:27]}),
    .CLKA(clka),
    .OCEA(ocea),
    .CEA(cea),
    .RESETA(reseta),
    .WREA(wrea),
    .CLKB(clkb),
    .OCEB(oceb),
    .CEB(ceb),
    .RESETB(resetb),
    .WREB(wreb),
    .BLKSELA({gw_gnd,gw_gnd,gw_gnd}),
    .BLKSELB({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({ada[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIA({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dina[35:27]}),
    .ADB({adb[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIB({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dinb[35:27]})
);

defparam dpx9b_inst_3.READ_MODE0 = 1'b1;
defparam dpx9b_inst_3.READ_MODE1 = 1'b1;
defparam dpx9b_inst_3.WRITE_MODE0 = 2'b00;
defparam dpx9b_inst_3.WRITE_MODE1 = 2'b00;
defparam dpx9b_inst_3.BIT_WIDTH_0 = 9;
defparam dpx9b_inst_3.BIT_WIDTH_1 = 9;
defparam dpx9b_inst_3.BLK_SEL_0 = 3'b000;
defparam dpx9b_inst_3.BLK_SEL_1 = 3'b000;
defparam dpx9b_inst_3.RESET_MODE = "SYNC";

DPX9B dpx9b_inst_4 (
    .DOA({dpx9b_inst_4_douta_w[8:0],douta[44:36]}),
    .DOB({dpx9b_inst_4_doutb_w[8:0],doutb[44:36]}),
    .CLKA(clka),
    .OCEA(ocea),
    .CEA(cea),
    .RESETA(reseta),
    .WREA(wrea),
    .CLKB(clkb),
    .OCEB(oceb),
    .CEB(ceb),
    .RESETB(resetb),
    .WREB(wreb),
    .BLKSELA({gw_gnd,gw_gnd,gw_gnd}),
    .BLKSELB({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({ada[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIA({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dina[44:36]}),
    .ADB({adb[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIB({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dinb[44:36]})
);

defparam dpx9b_inst_4.READ_MODE0 = 1'b1;
defparam dpx9b_inst_4.READ_MODE1 = 1'b1;
defparam dpx9b_inst_4.WRITE_MODE0 = 2'b00;
defparam dpx9b_inst_4.WRITE_MODE1 = 2'b00;
defparam dpx9b_inst_4.BIT_WIDTH_0 = 9;
defparam dpx9b_inst_4.BIT_WIDTH_1 = 9;
defparam dpx9b_inst_4.BLK_SEL_0 = 3'b000;
defparam dpx9b_inst_4.BLK_SEL_1 = 3'b000;
defparam dpx9b_inst_4.RESET_MODE = "SYNC";

DPX9B dpx9b_inst_5 (
    .DOA({dpx9b_inst_5_douta_w[8:0],douta[53:45]}),
    .DOB({dpx9b_inst_5_doutb_w[8:0],doutb[53:45]}),
    .CLKA(clka),
    .OCEA(ocea),
    .CEA(cea),
    .RESETA(reseta),
    .WREA(wrea),
    .CLKB(clkb),
    .OCEB(oceb),
    .CEB(ceb),
    .RESETB(resetb),
    .WREB(wreb),
    .BLKSELA({gw_gnd,gw_gnd,gw_gnd}),
    .BLKSELB({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({ada[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIA({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dina[53:45]}),
    .ADB({adb[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIB({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dinb[53:45]})
);

defparam dpx9b_inst_5.READ_MODE0 = 1'b1;
defparam dpx9b_inst_5.READ_MODE1 = 1'b1;
defparam dpx9b_inst_5.WRITE_MODE0 = 2'b00;
defparam dpx9b_inst_5.WRITE_MODE1 = 2'b00;
defparam dpx9b_inst_5.BIT_WIDTH_0 = 9;
defparam dpx9b_inst_5.BIT_WIDTH_1 = 9;
defparam dpx9b_inst_5.BLK_SEL_0 = 3'b000;
defparam dpx9b_inst_5.BLK_SEL_1 = 3'b000;
defparam dpx9b_inst_5.RESET_MODE = "SYNC";

DPX9B dpx9b_inst_6 (
    .DOA({dpx9b_inst_6_douta_w[8:0],douta[62:54]}),
    .DOB({dpx9b_inst_6_doutb_w[8:0],doutb[62:54]}),
    .CLKA(clka),
    .OCEA(ocea),
    .CEA(cea),
    .RESETA(reseta),
    .WREA(wrea),
    .CLKB(clkb),
    .OCEB(oceb),
    .CEB(ceb),
    .RESETB(resetb),
    .WREB(wreb),
    .BLKSELA({gw_gnd,gw_gnd,gw_gnd}),
    .BLKSELB({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({ada[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIA({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dina[62:54]}),
    .ADB({adb[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIB({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dinb[62:54]})
);

defparam dpx9b_inst_6.READ_MODE0 = 1'b1;
defparam dpx9b_inst_6.READ_MODE1 = 1'b1;
defparam dpx9b_inst_6.WRITE_MODE0 = 2'b00;
defparam dpx9b_inst_6.WRITE_MODE1 = 2'b00;
defparam dpx9b_inst_6.BIT_WIDTH_0 = 9;
defparam dpx9b_inst_6.BIT_WIDTH_1 = 9;
defparam dpx9b_inst_6.BLK_SEL_0 = 3'b000;
defparam dpx9b_inst_6.BLK_SEL_1 = 3'b000;
defparam dpx9b_inst_6.RESET_MODE = "SYNC";

DPX9B dpx9b_inst_7 (
    .DOA({dpx9b_inst_7_douta_w[8:0],douta[71:63]}),
    .DOB({dpx9b_inst_7_doutb_w[8:0],doutb[71:63]}),
    .CLKA(clka),
    .OCEA(ocea),
    .CEA(cea),
    .RESETA(reseta),
    .WREA(wrea),
    .CLKB(clkb),
    .OCEB(oceb),
    .CEB(ceb),
    .RESETB(resetb),
    .WREB(wreb),
    .BLKSELA({gw_gnd,gw_gnd,gw_gnd}),
    .BLKSELB({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({ada[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIA({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dina[71:63]}),
    .ADB({adb[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIB({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dinb[71:63]})
);

defparam dpx9b_inst_7.READ_MODE0 = 1'b1;
defparam dpx9b_inst_7.READ_MODE1 = 1'b1;
defparam dpx9b_inst_7.WRITE_MODE0 = 2'b00;
defparam dpx9b_inst_7.WRITE_MODE1 = 2'b00;
defparam dpx9b_inst_7.BIT_WIDTH_0 = 9;
defparam dpx9b_inst_7.BIT_WIDTH_1 = 9;
defparam dpx9b_inst_7.BLK_SEL_0 = 3'b000;
defparam dpx9b_inst_7.BLK_SEL_1 = 3'b000;
defparam dpx9b_inst_7.RESET_MODE = "SYNC";

DPB dpb_inst_8 (
    .DOA({dpb_inst_8_douta_w[7:0],douta[79:72]}),
    .DOB({dpb_inst_8_doutb_w[7:0],doutb[79:72]}),
    .CLKA(clka),
    .OCEA(ocea),
    .CEA(cea),
    .RESETA(reseta),
    .WREA(wrea),
    .CLKB(clkb),
    .OCEB(oceb),
    .CEB(ceb),
    .RESETB(resetb),
    .WREB(wreb),
    .BLKSELA({gw_gnd,gw_gnd,gw_gnd}),
    .BLKSELB({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({ada[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIA({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dina[79:72]}),
    .ADB({adb[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIB({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dinb[79:72]})
);

defparam dpb_inst_8.READ_MODE0 = 1'b1;
defparam dpb_inst_8.READ_MODE1 = 1'b1;
defparam dpb_inst_8.WRITE_MODE0 = 2'b00;
defparam dpb_inst_8.WRITE_MODE1 = 2'b00;
defparam dpb_inst_8.BIT_WIDTH_0 = 8;
defparam dpb_inst_8.BIT_WIDTH_1 = 8;
defparam dpb_inst_8.BLK_SEL_0 = 3'b000;
defparam dpb_inst_8.BLK_SEL_1 = 3'b000;
defparam dpb_inst_8.RESET_MODE = "SYNC";

DPB dpb_inst_9 (
    .DOA({dpb_inst_9_douta_w[7:0],douta[87:80]}),
    .DOB({dpb_inst_9_doutb_w[7:0],doutb[87:80]}),
    .CLKA(clka),
    .OCEA(ocea),
    .CEA(cea),
    .RESETA(reseta),
    .WREA(wrea),
    .CLKB(clkb),
    .OCEB(oceb),
    .CEB(ceb),
    .RESETB(resetb),
    .WREB(wreb),
    .BLKSELA({gw_gnd,gw_gnd,gw_gnd}),
    .BLKSELB({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({ada[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIA({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dina[87:80]}),
    .ADB({adb[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIB({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dinb[87:80]})
);

defparam dpb_inst_9.READ_MODE0 = 1'b1;
defparam dpb_inst_9.READ_MODE1 = 1'b1;
defparam dpb_inst_9.WRITE_MODE0 = 2'b00;
defparam dpb_inst_9.WRITE_MODE1 = 2'b00;
defparam dpb_inst_9.BIT_WIDTH_0 = 8;
defparam dpb_inst_9.BIT_WIDTH_1 = 8;
defparam dpb_inst_9.BLK_SEL_0 = 3'b000;
defparam dpb_inst_9.BLK_SEL_1 = 3'b000;
defparam dpb_inst_9.RESET_MODE = "SYNC";

DPB dpb_inst_10 (
    .DOA({dpb_inst_10_douta_w[7:0],douta[95:88]}),
    .DOB({dpb_inst_10_doutb_w[7:0],doutb[95:88]}),
    .CLKA(clka),
    .OCEA(ocea),
    .CEA(cea),
    .RESETA(reseta),
    .WREA(wrea),
    .CLKB(clkb),
    .OCEB(oceb),
    .CEB(ceb),
    .RESETB(resetb),
    .WREB(wreb),
    .BLKSELA({gw_gnd,gw_gnd,gw_gnd}),
    .BLKSELB({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({ada[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIA({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dina[95:88]}),
    .ADB({adb[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIB({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dinb[95:88]})
);

defparam dpb_inst_10.READ_MODE0 = 1'b1;
defparam dpb_inst_10.READ_MODE1 = 1'b1;
defparam dpb_inst_10.WRITE_MODE0 = 2'b00;
defparam dpb_inst_10.WRITE_MODE1 = 2'b00;
defparam dpb_inst_10.BIT_WIDTH_0 = 8;
defparam dpb_inst_10.BIT_WIDTH_1 = 8;
defparam dpb_inst_10.BLK_SEL_0 = 3'b000;
defparam dpb_inst_10.BLK_SEL_1 = 3'b000;
defparam dpb_inst_10.RESET_MODE = "SYNC";

DPB dpb_inst_11 (
    .DOA({dpb_inst_11_douta_w[7:0],douta[103:96]}),
    .DOB({dpb_inst_11_doutb_w[7:0],doutb[103:96]}),
    .CLKA(clka),
    .OCEA(ocea),
    .CEA(cea),
    .RESETA(reseta),
    .WREA(wrea),
    .CLKB(clkb),
    .OCEB(oceb),
    .CEB(ceb),
    .RESETB(resetb),
    .WREB(wreb),
    .BLKSELA({gw_gnd,gw_gnd,gw_gnd}),
    .BLKSELB({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({ada[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIA({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dina[103:96]}),
    .ADB({adb[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIB({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dinb[103:96]})
);

defparam dpb_inst_11.READ_MODE0 = 1'b1;
defparam dpb_inst_11.READ_MODE1 = 1'b1;
defparam dpb_inst_11.WRITE_MODE0 = 2'b00;
defparam dpb_inst_11.WRITE_MODE1 = 2'b00;
defparam dpb_inst_11.BIT_WIDTH_0 = 8;
defparam dpb_inst_11.BIT_WIDTH_1 = 8;
defparam dpb_inst_11.BLK_SEL_0 = 3'b000;
defparam dpb_inst_11.BLK_SEL_1 = 3'b000;
defparam dpb_inst_11.RESET_MODE = "SYNC";

DPB dpb_inst_12 (
    .DOA({dpb_inst_12_douta_w[7:0],douta[111:104]}),
    .DOB({dpb_inst_12_doutb_w[7:0],doutb[111:104]}),
    .CLKA(clka),
    .OCEA(ocea),
    .CEA(cea),
    .RESETA(reseta),
    .WREA(wrea),
    .CLKB(clkb),
    .OCEB(oceb),
    .CEB(ceb),
    .RESETB(resetb),
    .WREB(wreb),
    .BLKSELA({gw_gnd,gw_gnd,gw_gnd}),
    .BLKSELB({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({ada[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIA({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dina[111:104]}),
    .ADB({adb[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIB({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dinb[111:104]})
);

defparam dpb_inst_12.READ_MODE0 = 1'b1;
defparam dpb_inst_12.READ_MODE1 = 1'b1;
defparam dpb_inst_12.WRITE_MODE0 = 2'b00;
defparam dpb_inst_12.WRITE_MODE1 = 2'b00;
defparam dpb_inst_12.BIT_WIDTH_0 = 8;
defparam dpb_inst_12.BIT_WIDTH_1 = 8;
defparam dpb_inst_12.BLK_SEL_0 = 3'b000;
defparam dpb_inst_12.BLK_SEL_1 = 3'b000;
defparam dpb_inst_12.RESET_MODE = "SYNC";

DPB dpb_inst_13 (
    .DOA({dpb_inst_13_douta_w[7:0],douta[119:112]}),
    .DOB({dpb_inst_13_doutb_w[7:0],doutb[119:112]}),
    .CLKA(clka),
    .OCEA(ocea),
    .CEA(cea),
    .RESETA(reseta),
    .WREA(wrea),
    .CLKB(clkb),
    .OCEB(oceb),
    .CEB(ceb),
    .RESETB(resetb),
    .WREB(wreb),
    .BLKSELA({gw_gnd,gw_gnd,gw_gnd}),
    .BLKSELB({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({ada[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIA({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dina[119:112]}),
    .ADB({adb[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIB({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dinb[119:112]})
);

defparam dpb_inst_13.READ_MODE0 = 1'b1;
defparam dpb_inst_13.READ_MODE1 = 1'b1;
defparam dpb_inst_13.WRITE_MODE0 = 2'b00;
defparam dpb_inst_13.WRITE_MODE1 = 2'b00;
defparam dpb_inst_13.BIT_WIDTH_0 = 8;
defparam dpb_inst_13.BIT_WIDTH_1 = 8;
defparam dpb_inst_13.BLK_SEL_0 = 3'b000;
defparam dpb_inst_13.BLK_SEL_1 = 3'b000;
defparam dpb_inst_13.RESET_MODE = "SYNC";

DPB dpb_inst_14 (
    .DOA({dpb_inst_14_douta_w[7:0],douta[127:120]}),
    .DOB({dpb_inst_14_doutb_w[7:0],doutb[127:120]}),
    .CLKA(clka),
    .OCEA(ocea),
    .CEA(cea),
    .RESETA(reseta),
    .WREA(wrea),
    .CLKB(clkb),
    .OCEB(oceb),
    .CEB(ceb),
    .RESETB(resetb),
    .WREB(wreb),
    .BLKSELA({gw_gnd,gw_gnd,gw_gnd}),
    .BLKSELB({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({ada[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIA({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dina[127:120]}),
    .ADB({adb[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIB({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dinb[127:120]})
);

defparam dpb_inst_14.READ_MODE0 = 1'b1;
defparam dpb_inst_14.READ_MODE1 = 1'b1;
defparam dpb_inst_14.WRITE_MODE0 = 2'b00;
defparam dpb_inst_14.WRITE_MODE1 = 2'b00;
defparam dpb_inst_14.BIT_WIDTH_0 = 8;
defparam dpb_inst_14.BIT_WIDTH_1 = 8;
defparam dpb_inst_14.BLK_SEL_0 = 3'b000;
defparam dpb_inst_14.BLK_SEL_1 = 3'b000;
defparam dpb_inst_14.RESET_MODE = "SYNC";

endmodule //Gowin_DPB_128_2048
