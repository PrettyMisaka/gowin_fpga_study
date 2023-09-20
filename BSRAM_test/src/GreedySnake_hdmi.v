module GreedySnake_hdmi(
	input              I_pxl_clk   ,//pixel clock
    input              I_en        ,
    input              I_rst_n     ,//low active 
    
    input [15:0] snake_map_arr_0   ,
    input [15:0] snake_map_arr_1   ,
    input [15:0] snake_map_arr_2   ,
    input [15:0] snake_map_arr_3   ,
    input [15:0] snake_map_arr_4   ,
    input [15:0] snake_map_arr_5   ,
    input [15:0] snake_map_arr_6   ,
    input [15:0] snake_map_arr_7   ,
    input [15:0] snake_map_arr_8   ,
    input [15:0] snake_map_arr_9   ,
    input [15:0] snake_map_arr_10  ,
    input [15:0] snake_map_arr_11  ,
    input [15:0] snake_map_arr_12  ,
    input [15:0] snake_map_arr_13  ,
    input [15:0] snake_map_arr_14  ,
    input [15:0] snake_map_arr_15  ,

    output reg         O_busy      ,
    output reg         O_de        ,   
    output reg         O_hs        ,//������
    output reg         O_vs        ,
    output reg [23:0]  O_color     
);

localparam 
    HDMI_IDLE   = 4'd0,
    HDMI_JUDGE  = 4'd1,
    HDMI_FINISH = 4'd2;
localparam SNAKE_HSVS_STEP_CNT = 11'd30;

reg  [3:0]   state;

reg  [15:0] snake_map_arr_tmp;
reg  [15:0]  x_list;
reg  [3:0]   x_cnt;
reg  [3:0]   y_cnt;

wire [11:0]  O_h_cnt ;
wire [11:0]  O_v_cnt ;
reg  [11:0]  hs_cmp  ;
reg  [11:0]  vs_cmp  ;

wire  O_de_delay   ;
wire  O_hs_delay   ;
wire  O_vs_delay   ;
wire  O_busy_before, O_busy_after ;

initial begin
    state  <= HDMI_IDLE;
    x_list <= 16'd1; 
    x_cnt  <= 0;
    y_cnt  <= 0;
end

localparam	WHITE	= { 8'd255 , 8'd255 , 8'd255 };//{B,G,R}
localparam	YELLOW	= { 8'd0   , 8'd255 , 8'd255 };
localparam	CYAN	= { 8'd255 , 8'd255 , 8'd0   };
localparam	GREEN	= { 8'd0   , 8'd255 , 8'd0   };
localparam	MAGENTA	= { 8'd255 , 8'd0   , 8'd255 };
localparam	RED		= { 8'd0   , 8'd0   , 8'd255 };
localparam	BLUE	= { 8'd255 , 8'd0   , 8'd0   };
localparam	BLACK	= { 8'd0   , 8'd0   , 8'd0   };
localparam	GRAY	= { 8'd100 , 8'd100 , 8'd100 };

localparam  POINT_COLOR = WHITE;
localparam  SNAKE_COLOR = BLACK;
localparam  BACKG_COLOR = GRAY ;

always@(posedge I_pxl_clk)begin
    O_de   <= O_de_delay  ; 
    O_hs   <= O_hs_delay  ; 
    O_vs   <= O_vs_delay  ; 
end

always@(posedge I_pxl_clk or negedge I_rst_n)begin
    if(!I_rst_n)begin
        state <= HDMI_IDLE;
    end
    else begin
        case (state)
            HDMI_IDLE: begin
                if(I_en)begin
                    x_list <= 16'd1; 
                    x_cnt  <= 0;
                    y_cnt  <= 0;
                    state  <= HDMI_JUDGE;
                    vs_cmp <= 12'd60 + SNAKE_HSVS_STEP_CNT;
                    hs_cmp <= 12'd160 + SNAKE_HSVS_STEP_CNT;
                    O_busy <= 1;
                end
                else begin
                    state <= HDMI_IDLE;
                    O_busy <= 0;
                end
            end
            HDMI_JUDGE:begin
                if(O_h_cnt == 12'd800)begin
                    if(O_v_cnt == 12'd60 ) begin
                        y_cnt <= y_cnt + 4'd1;
                    end
                    else if(O_v_cnt == 12'd540 ) begin
                        vs_cmp <= 12'd60 + SNAKE_HSVS_STEP_CNT;
                    end
                    else if(O_v_cnt == vs_cmp ) begin
                        y_cnt <= y_cnt + 4'd1;
                        vs_cmp<= vs_cmp+ SNAKE_HSVS_STEP_CNT;
                    end
                    else begin
                        y_cnt <= y_cnt;
                    end
                    if(O_v_cnt == 12'd600 ) begin
                        state <= HDMI_FINISH;
                    end
                end
            end
        endcase
    end
end

always@(posedge I_pxl_clk)begin
    case(y_cnt):
        4'd0 : begin snake_map_arr_tmp <= snake_map_arr_0 ; end
        4'd1 : begin snake_map_arr_tmp <= snake_map_arr_1 ; end
        4'd2 : begin snake_map_arr_tmp <= snake_map_arr_2 ; end
        4'd3 : begin snake_map_arr_tmp <= snake_map_arr_3 ; end
        4'd4 : begin snake_map_arr_tmp <= snake_map_arr_4 ; end
        4'd5 : begin snake_map_arr_tmp <= snake_map_arr_5 ; end
        4'd6 : begin snake_map_arr_tmp <= snake_map_arr_6 ; end
        4'd7 : begin snake_map_arr_tmp <= snake_map_arr_7 ; end
        4'd8 : begin snake_map_arr_tmp <= snake_map_arr_8 ; end
        4'd9 : begin snake_map_arr_tmp <= snake_map_arr_9 ; end
        4'd10: begin snake_map_arr_tmp <= snake_map_arr_10; end
        4'd11: begin snake_map_arr_tmp <= snake_map_arr_11; end
        4'd12: begin snake_map_arr_tmp <= snake_map_arr_12; end
        4'd13: begin snake_map_arr_tmp <= snake_map_arr_13; end
        4'd14: begin snake_map_arr_tmp <= snake_map_arr_14; end
        4'd15: begin snake_map_arr_tmp <= snake_map_arr_15; end
    endcase
end

GreedySnake_hdmi_clk GreedySnake_hdmi_clk0(
	.I_pxl_clk   (pxl_clk            ),//pixel clock
    .I_en        (I_en               ),
    .I_rst_n     (I_rst_n            ),//low active 
    .I_h_total   (12'd1056           ),//hor total time  // 12'd1056  // 12'd1344  // 12'd1650   
    .I_h_sync    (12'd128            ),//hor sync time   // 12'd128   // 12'd136   // 12'd40     
    .I_h_bporch  (12'd88             ),//hor back porch  // 12'd88    // 12'd160   // 12'd220    
    .I_h_res     (12'd800            ),//hor resolution  // 12'd800   // 12'd1024  // 12'd1280   
    .I_v_total   (12'd628            ),//ver total time  // 12'd628   // 12'd806   // 12'd750     
    .I_v_sync    (12'd4              ),//ver sync time   // 12'd4     // 12'd6     // 12'd5       
    .I_v_bporch  (12'd23             ),//ver back porch  // 12'd23    // 12'd29    // 12'd20       
    .I_v_res     (12'd600            ),//ver resolution  // 12'd600   // 12'd768   // 12'd720     
    .O_h_cnt     (O_h_cnt            ),
    .O_v_cnt     (O_v_cnt            ),
    .O_busy      (O_busy_after       ),
    .O_de        (O_de_delay         ),   
    .O_hs        (O_hs_delay         ),//������
    .O_vs        (O_vs_delay         )
);

endmodule