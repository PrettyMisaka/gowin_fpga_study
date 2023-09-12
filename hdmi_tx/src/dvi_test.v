module dvi_test (
    input clk,
    input en,
    output wire busy,
    output wire pll_lock,
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

reg [23:0] color = WHITE;
reg [2:0] color_cnt;
initial color_cnt = 3'd0;

reg  busy_before;
wire busy_falling_flag;
assign busy_falling_flag = busy_before&(~busy);
// wire hdmi_en;
// assign hdmi_en = ~en;

wire pxl_clk;
wire serial_clk;
wire O_de, O_hs, O_vs;
wire rst;
assign rst = 1;

always@(negedge busy)begin
    // if(busy_falling_flag) begin
        color_cnt <= color_cnt + 3'd1;
    // end
    // busy_before <= busy;
    case(color_cnt)
        3'd0: begin color <= WHITE	    ;  end
        3'd1: begin color <= YELLOW	    ;  end
        3'd2: begin color <= CYAN	    ;  end
        3'd3: begin color <= GREEN	    ;  end
        3'd4: begin color <= MAGENTA	;  end
        3'd5: begin color <= RED		;  end
        3'd6: begin color <= BLUE	    ;  end
        3'd7: begin color <= BLACK	    ;  end
    endcase
end

my_testpattern my_testpattern0(
    .I_pxl_clk   (pxl_clk            ),//pixel clock
    .I_rst_n     (rst                ),//low active 
    .I_en        (en                 ),             //800x600    //1024x768   //1280x720    
    .I_h_total   (12'd1650           ),//hor total time  // 12'd1056  // 12'd1344  // 12'd1650  
    .I_h_sync    (12'd40             ),//hor sync time   // 12'd128   // 12'd136   // 12'd40    
    .I_h_bporch  (12'd220            ),//hor back porch  // 12'd88    // 12'd160   // 12'd220   
    .I_h_res     (12'd1280           ),//hor resolution  // 12'd800   // 12'd1024  // 12'd1280  
    .I_v_total   (12'd750            ),//ver total time  // 12'd628   // 12'd806   // 12'd750    
    .I_v_sync    (12'd5              ),//ver sync time   // 12'd4     // 12'd6     // 12'd5     
    .I_v_bporch  (12'd20             ),//ver back porch  // 12'd23    // 12'd29    // 12'd20    
    .I_v_res     (12'd720            ),//ver resolution  // 12'd600   // 12'd768   // 12'd720  
    .O_busy      (busy               ),
    .O_de        (O_de               ),   
    .O_hs        (O_hs               ),//������
    .O_vs        (O_vs               ) 
);

DVI_TX_Top your_instance_name(
    .I_rst_n            (rst        ), //input I_rst_n
    .I_serial_clk       (serial_clk ), //input I_serial_clk
    .I_rgb_clk          (pxl_clk    ), //input I_rgb_clk
    .I_rgb_vs           (O_vs   ), //input I_rgb_vs
    .I_rgb_hs           (O_hs   ), //input I_rgb_hs
    .I_rgb_de           (O_de   ), //input I_rgb_de
    .I_rgb_r            (color[7:0]    ), //input [7:0] I_rgb_r
    .I_rgb_g            (color[15:8]   ), //input [7:0] I_rgb_g
    .I_rgb_b            (color[23:16]  ), //input [7:0] I_rgb_b
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