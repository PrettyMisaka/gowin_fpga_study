module GreedySnake_Top(
    input clk,
    input rst,
    input key_x_up,
    input key_x_down,
    input key_y_up,
    input key_y_down,
    // input [7:0] snake_point_pos
    output wire O_busy,
    output O_tmds_clk_p_o,
    output O_tmds_clk_n_o,
    output [2:0]O_tmds_data_p_o,
    output [2:0]O_tmds_data_n_o
);

localparam	WHITE	= {8'd255 , 8'd255 , 8'd255 };//{B,G,R}
localparam	YELLOW	= {8'd0   , 8'd255 , 8'd255 };
localparam	CYAN	= {8'd255 , 8'd255 , 8'd0   };
localparam	GREEN	= {8'd0   , 8'd255 , 8'd0   };
localparam	MAGENTA	= {8'd255 , 8'd0   , 8'd255 };
localparam	RED		= {8'd0   , 8'd0   , 8'd255 };
localparam	BLUE	= {8'd255 , 8'd0   , 8'd0   };
localparam	BLACK	= {8'd0   , 8'd0   , 8'd0   };

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
wire en;
wire GreedySnake_dpb_w_busy;
wire [1:0] forward;
wire [3:0] mode;
wire [7:0] snake_point_pos;
/*******************************/
reg dpb_r_en = 0;
/******************** CHAN A AND B WIRE ********************/
wire [10:0] list_length_wire;
wire [10:0] list_head_addr_wire;
/***************CHAN B AND HDMI_TX*************/
wire [15:0] snake_map_arr_0 ;
wire [15:0] snake_map_arr_1 ;
wire [15:0] snake_map_arr_2 ;
wire [15:0] snake_map_arr_3 ;
wire [15:0] snake_map_arr_4 ;
wire [15:0] snake_map_arr_5 ;
wire [15:0] snake_map_arr_6 ;
wire [15:0] snake_map_arr_7 ;
wire [15:0] snake_map_arr_8 ;
wire [15:0] snake_map_arr_9 ;
wire [15:0] snake_map_arr_10;
wire [15:0] snake_map_arr_11;
wire [15:0] snake_map_arr_12;
wire [15:0] snake_map_arr_13;
wire [15:0] snake_map_arr_14;
wire [15:0] snake_map_arr_15;
wire hdmi_tx_en;
assign hdmi_tx_en = 1;
wire game_over_flag;
/**************** hdmi show **********************/
wire [23:0]O_color;
// assign O_color = 24'hff00ff;
wire O_de, O_hs, O_vs;
wire pxl_clk, serial_clk;
/**************** GreedySnake_dpb_w_busy driver GreedySnake_dpb_r0 ********************/
reg GreedySnake_dpb_w_busy_bef;
wire GreedySnake_dpb_w_busy_fall_flag = (~GreedySnake_dpb_w_busy)&&GreedySnake_dpb_w_busy_bef;
always@(posedge clk or negedge rst)begin
    if(!rst)begin
        GreedySnake_dpb_w_busy_bef <= 0;
        dpb_r_en <= 0;
    end
    else begin
        GreedySnake_dpb_w_busy_bef <= GreedySnake_dpb_w_busy;
        if(GreedySnake_dpb_w_busy_fall_flag)begin
            dpb_r_en <= 1;
        end
        else begin
            dpb_r_en <= 0;
        end
    end
end

/*******************************************************/
GreedySnake_dpb_w GreedySnake_dpb_w0(
    .clk            (clk),
    .en             (en),
    .rst            (1'b1),
    .forward        (forward),
    .mode           (mode),
    .snake_point_pos(snake_point_pos),
    .busy           (GreedySnake_dpb_w_busy),
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
    .clk            (clk),
    .en             (dpb_r_en),
    .busy           (dpb_r_busy),
    .snake_point_pos(snake_point_pos),
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
//  HDMI_TX DATAsnake_map_arr_0 ,
    .snake_map_arr_0 (snake_map_arr_0 ),
    .snake_map_arr_1 (snake_map_arr_1 ),
    .snake_map_arr_2 (snake_map_arr_2 ),
    .snake_map_arr_3 (snake_map_arr_3 ),
    .snake_map_arr_4 (snake_map_arr_4 ),
    .snake_map_arr_5 (snake_map_arr_5 ),
    .snake_map_arr_6 (snake_map_arr_6 ),
    .snake_map_arr_7 (snake_map_arr_7 ),
    .snake_map_arr_8 (snake_map_arr_8 ),
    .snake_map_arr_9 (snake_map_arr_9 ),
    .snake_map_arr_10(snake_map_arr_10),
    .snake_map_arr_11(snake_map_arr_11),
    .snake_map_arr_12(snake_map_arr_12),
    .snake_map_arr_13(snake_map_arr_13),
    .snake_map_arr_14(snake_map_arr_14),
    .snake_map_arr_15(snake_map_arr_15),
    // .hdmi_tx_en     (hdmi_tx_en    ) ,
    .game_over_flag (game_over_flag)
);

GreedySnake_key_ctrl GreedySnake_key_ctrl0(
    .clk(clk),
    .rst(rst),
    .i_key_x_up  (key_x_up  ),
    .i_key_x_down(key_x_down),
    .i_key_y_up  (key_y_up  ),
    .i_key_y_down(key_y_down),

    .en(en),
    .led(O_busy),
    .forward(forward),
    .mode(mode)
);
defparam GreedySnake_key_ctrl0.CLK_1S_DELAY_CNT = 32'd27_000_000;

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

GreedySnake_hdmi GreedySnake_hdmi0(
	.I_pxl_clk(pxl_clk     )   ,//pixel clock
    .I_en     (hdmi_tx_en  )   ,
    .I_rst_n  (rst         )   ,//low active 
                                   
    .snake_map_arr_0 ( snake_map_arr_0  )  ,
    .snake_map_arr_1 ( snake_map_arr_1  )  ,
    .snake_map_arr_2 ( snake_map_arr_2  )  ,
    .snake_map_arr_3 ( snake_map_arr_3  )  ,
    .snake_map_arr_4 ( snake_map_arr_4  )  ,
    .snake_map_arr_5 ( snake_map_arr_5  )  ,
    .snake_map_arr_6 ( snake_map_arr_6  )  ,
    .snake_map_arr_7 ( snake_map_arr_7  )  ,
    .snake_map_arr_8 ( snake_map_arr_8  )  ,
    .snake_map_arr_9 ( snake_map_arr_9  )  ,
    .snake_map_arr_10( snake_map_arr_10 )  ,
    .snake_map_arr_11( snake_map_arr_11 )  ,
    .snake_map_arr_12( snake_map_arr_12 )  ,
    .snake_map_arr_13( snake_map_arr_13 )  ,
    .snake_map_arr_14( snake_map_arr_14 )  ,
    .snake_map_arr_15( snake_map_arr_15 )  ,
                        
    // .O_busy (O_busy )     ,
    .O_de   (O_de   )     ,   
    .O_hs   (O_hs   )     ,//������
    .O_vs   (O_vs   )     ,
    .O_color(O_color)     
);
// reg [23:0] color = WHITE;
// reg [2:0] color_cnt;
// reg [31:0]cnt;
// assign O_color = color;
// always@(posedge clk) begin
//     if(cnt == 32'd27_000_000)begin
//         // hdmi_en <= 1;
//         cnt <= cnt + 32'd0;
//         color_cnt <= color_cnt + 3'd1;
//     end
//     else begin
//         // hdmi_en <= 0;
//         cnt <= cnt + 32'd1;
//     end
// end
// always@(posedge pxl_clk)begin
//     case(color_cnt)
//         3'd0: begin color <= WHITE	    ;  end
//         3'd1: begin color <= YELLOW	    ;  end
//         3'd2: begin color <= CYAN	    ;  end
//         3'd3: begin color <= GREEN	    ;  end
//         3'd4: begin color <= MAGENTA	;  end
//         3'd5: begin color <= RED		;  end
//         3'd6: begin color <= BLUE	    ;  end
//         3'd7: begin color <= BLACK	    ;  end
//     endcase
// end

// GreedySnake_hdmi_clk GreedySnake_hdmi_clk0(
// 	.I_pxl_clk   (pxl_clk            ),//pixel clock
//     .I_en        (hdmi_tx_en         ),
//     .I_rst_n     (rst                ),//low active 
//     .I_h_total   (12'd1650           ),//hor total time  // 12'd1056  // 12'd1344  // 12'd1650   
//     .I_h_sync    (12'd40             ),//hor sync time   // 12'd128   // 12'd136   // 12'd40     
//     .I_h_bporch  (12'd220            ),//hor back porch  // 12'd88    // 12'd160   // 12'd220    
//     .I_h_res     (12'd1280           ),//hor resolution  // 12'd800   // 12'd1024  // 12'd1280   
//     .I_v_total   (12'd750            ),//ver total time  // 12'd628   // 12'd806   // 12'd750     
//     .I_v_sync    (12'd5              ),//ver sync time   // 12'd4     // 12'd6     // 12'd5       
//     .I_v_bporch  (12'd20             ),//ver back porch  // 12'd23    // 12'd29    // 12'd20       
//     .I_v_res     (12'd720            ),//ver resolution  // 12'd600   // 12'd768   // 12'd720     
//     .O_de        (O_de               ),   
//     .O_hs        (O_hs               ),//������
//     .O_vs        (O_vs               )
// );


DVI_TX_Top DVI_TX_Top0(
    .I_rst_n            (rst           ), //input I_rst_n
    .I_serial_clk       (serial_clk    ), //input I_serial_clk
    .I_rgb_clk          (pxl_clk       ), //input I_rgb_clk
    .I_rgb_vs           (O_vs          ), //input I_rgb_vs
    .I_rgb_hs           (O_hs          ), //input I_rgb_hs
    .I_rgb_de           (O_de          ), //input I_rgb_de
    .I_rgb_r            (O_color[7:0]  ), //input [7:0] I_rgb_r
    .I_rgb_g            (O_color[15:8] ), //input [7:0] I_rgb_g
    .I_rgb_b            (O_color[23:16]), //input [7:0] I_rgb_b
    .O_tmds_clk_p       (O_tmds_clk_p_o), //output O_tmds_clk_p
    .O_tmds_clk_n       (O_tmds_clk_n_o), //output O_tmds_clk_n
    .O_tmds_data_p      (O_tmds_data_p_o), //output [2:0] O_tmds_data_p
    .O_tmds_data_n      (O_tmds_data_n_o) //output [2:0] O_tmds_data_n
);


Gowin_rPLL rpll0(
    .clkout(serial_clk  ), //output clkout
    .lock(pll_lock      ), //output lock
    .clkin(clk          ) //input clkin
);

Gowin_CLKDIV clkdiv0(
    .clkout(pxl_clk     ), //output clkout
    .hclkin(serial_clk  ), //input hclkin
    .resetn(rst         ) //input resetn
);

endmodule