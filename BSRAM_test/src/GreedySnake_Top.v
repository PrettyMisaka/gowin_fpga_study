`timescale 1ps/1ps
module GreedySnake_Top(
    input clk
);

localparam
    FORWARD_X_UP    = 2'b00,
    FORWARD_X_DOWN  = 2'b01,
    FORWARD_Y_UP    = 2'b10,
    FORWARD_Y_DOWN  = 2'b11;
/****************** dpb reg ********************/
wire i_a_clk_en, i_a_data_en, i_a_wr_en;
wire [7:0]   i_a_data;
wire [7:0]   o_a_data;
wire [10:0]  i_a_address;

wire i_b_clk_en, i_b_data_en, i_b_wr_en;
wire [7:0]   i_b_data;
wire [7:0]   o_b_data;
wire [10:0]  i_b_address;
/****************** snake reg ********************/
reg en;
wire busy;
reg [1:0] forward;
reg [3:0] mode;
reg [7:0] snake_point_pos;
/******************** CHAN A AND B WIRE ********************/
wire [10:0] list_length_wire;
wire [10:0] list_head_addr_wire;
/***************CHAN B AND HDMI_TX*************/
wire [15:0] snake_map_arr [0:15];
wire hdmi_tx_en;
wire game_over_flag;

GreedySnake_dpb_w GreedySnake_dpb_w0(
    .clk            (clk),
    .en             (en),
    .forward        (forward),
    .mode           (mode),
    .snake_point_pos(snake_point_pos),
    .busy           (busy),
// Gowin_DPB channel A
    .i_a_clk_en     (i_a_clk_en),
    .i_a_data_en    (i_a_data_en),
    .i_a_wr_en      (i_a_wr_en),
    .o_a_data       (o_a_data),
    .i_a_data       (i_a_data),
    .i_a_address    (i_a_address),
// Gowin_DPB channel B DATA
    .list_length_wire       (list_length_wire),
    .list_head_addr_wire    (list_head_addr_wire)
);

GreedySnake_dpb_r GreedySnake_dpb_r0(
    .clk        (clk),
    .en         (dpb_r_en),
    .busy        (dpb_r_busy),
// Gowin_DPB channel A receive
    .list_length(list_length_wire),
    .list_head_addr(list_head_addr_wire),
// Gowin_DPB channel B
    .i_b_clk_en (i_b_clk_en ),
    .i_b_data_en(i_b_data_en),
    .i_b_wr_en  (i_b_wr_en  ),
    .o_b_data   (o_b_data   ),
    .i_b_data   (i_b_data   ),
    .i_b_address(i_b_address),
//  HDMI_TX DATA
    .snake_map_arr  (snake_map_arr ) ,
    .hdmi_tx_en     (hdmi_tx_en    ) ,
    .game_over_flag (game_over_flag)
);

Gowin_DPB Gowin_DPB0(
    .douta          (o_a_data), //output [7:0] douta
    .clka           (clk), //input clka
    .ocea           (i_a_data_en), //input ocea
    .cea            (i_a_clk_en), //input cea
    .reseta         (1'b0), //input reseta
    .wrea           (i_a_wr_en), //input wrea
    .ada            (i_a_address), //input [10:0] ada
    .dina           (i_a_data), //input [7:0] dina

    .doutb          (o_b_data), //output [7:0] doutb
    .clkb           (clk), //input clkb
    .oceb           (i_b_data_en), //input oceb
    .ceb            (i_b_clk_en), //input ceb
    .resetb         (1'b0), //input resetb
    .wreb           (i_b_wr_en), //input wreb
    .adb            (i_b_address), //input [10:0] adb
    .dinb           (i_b_data) //input [7:0] dinb
);

endmodule