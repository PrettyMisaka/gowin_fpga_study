module GreedySnake_Top(
    input clk
);

/****************** dpb reg ********************/
reg i_a_clk_en, i_a_data_en, i_a_wr_en;
reg [7:0]   i_a_data;
wire [7:0]   o_a_data;
reg [10:0]  i_a_address;

reg i_b_clk_en, i_b_data_en, i_b_wr_en;
reg [7:0]   i_b_data;
wire [7:0]   o_b_data;
reg [10:0]  i_b_address;
/****************** snake reg ********************/
reg en, busy;
reg [1:0] forward;
reg [3:0] mode;
reg [7:0] snake_point_pos;


initial begin
    i_a_clk_en     <= 1;
    i_a_data_en    <= 1;
    i_a_wr_en      <= 0;
end

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
    .i_a_address    (i_a_address)
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