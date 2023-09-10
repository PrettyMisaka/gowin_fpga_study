module dvi_test (
    input clk,
    input en,
    input rst,
    output reg busy,
    output wire pll_lock,
    output O_tmds_clk_p_o,
    output O_tmds_clk_n_o,
    output [2:0]O_tmds_data_p_o,
    output [2:0]O_tmds_data_n_o
);

parameter HS_CNT_MAX = 16'd1920;
parameter VS_CNT_MAX = 16'd1080;

localparam 
    DVI_IDLE        = 3'd0,
    DVI_TX_HS_BEGIN = 3'd1,
    DVI_TX_HS       = 3'd2,
    DVI_TX_HS_END   = 3'd3,
    DVI_FINISH      = 3'd4;
    
reg vs,hs,de;
reg [7:0]red;
reg [7:0]green;
reg [7:0]blue;
reg [2:0]state;
reg [15:0]hs_cnt;
reg [15:0]vs_cnt;

wire clk_5,clk_div5;

initial begin
    de = 0;
    vs = 0;
    hs = 0;
    red = 8'd255;
    green = 8'd255;
    blue = 8'd255;
    state = DVI_IDLE;
    hs_cnt = 16'd0;
    vs_cnt = 16'd0;
end

always@(posedge clk_div5) begin
    case (state)
        DVI_IDLE: begin
            if (en) begin
                busy <= 1;
                state <= DVI_TX_HS_BEGIN;
                de <= 0;
                vs <= 1;
                vs_cnt <= 0;
            end
            else begin
                busy <= 0;
                de <= 0;
                vs <= 0;
                hs <= 0;
                red = 8'b11111111;
            end
        end
        DVI_TX_HS_BEGIN: begin
            de <= 1;
            hs <= 1;
            hs_cnt <= 0;
            state <= DVI_TX_HS;
        end
        DVI_TX_HS: begin
            hs_cnt <= hs_cnt + 16'd1;
            if(hs_cnt == HS_CNT_MAX) begin
                state <= DVI_TX_HS_END;
            end
        end
        DVI_TX_HS_END: begin
            de <= 0;
            hs <= 0;
            vs_cnt <= vs_cnt + 16'd1;
            if(vs_cnt == VS_CNT_MAX) begin
                state <= DVI_FINISH;
            end
            else begin
                state <= DVI_TX_HS_BEGIN;
            end
        end
        DVI_FINISH: begin
            busy <= 0;
            vs_cnt <= 0;
            state <= DVI_IDLE;
        end
    endcase
end

DVI_TX_Top your_instance_name(
    .I_rst_n(rst), //input I_rst_n
    .I_serial_clk(clk_5), //input I_serial_clk
    .I_rgb_clk(clk), //input I_rgb_clk
    .I_rgb_vs(vs), //input I_rgb_vs
    .I_rgb_hs(hs), //input I_rgb_hs
    .I_rgb_de(de), //input I_rgb_de
    .I_rgb_r(red), //input [7:0] I_rgb_r
    .I_rgb_g(green), //input [7:0] I_rgb_g
    .I_rgb_b(blue), //input [7:0] I_rgb_b
    .O_tmds_clk_p(O_tmds_clk_p_o), //output O_tmds_clk_p
    .O_tmds_clk_n(O_tmds_clk_n_o), //output O_tmds_clk_n
    .O_tmds_data_p(O_tmds_data_p_o), //output [2:0] O_tmds_data_p
    .O_tmds_data_n(O_tmds_data_n_o) //output [2:0] O_tmds_data_n
);


Gowin_rPLL rpll0(
    .clkout(clk_5), //output clkout
    .lock(pll_lock), //output lock
    .clkin(clk) //input clkin
);

Gowin_CLKDIV clkdiv0(
    .clkout(clk_div5), //output clkout
    .hclkin(clk), //input hclkin
    .resetn(1) //input resetn
);

endmodule