module GreedySnake_dpb_r(
    input clk,
    input en,
    output reg busy,
    output reg [7:0] snake_point_pos,
    output reg snake_point_pos_exit,
    input [7:0] I_clk_cnt,
// Gowin_DPB channel A receive
    input [10:0] list_length,
    input [10:0] list_head_addr,
// Gowin_DPB channel B
    output reg i_b_clk_en,
    output reg i_b_data_en,
    output reg i_b_wr_en,
    input       [7:0]   o_b_data,
    output reg  [7:0]   i_b_data,
    output reg  [10:0]  i_b_address,
//  HDMI_TX DATA
    output wire [15:0] snake_map_arr_0 ,
    output wire [15:0] snake_map_arr_1 ,
    output wire [15:0] snake_map_arr_2 ,
    output wire [15:0] snake_map_arr_3 ,
    output wire [15:0] snake_map_arr_4 ,
    output wire [15:0] snake_map_arr_5 ,
    output wire [15:0] snake_map_arr_6 ,
    output wire [15:0] snake_map_arr_7 ,
    output wire [15:0] snake_map_arr_8 ,
    output wire [15:0] snake_map_arr_9 ,
    output wire [15:0] snake_map_arr_10,
    output wire [15:0] snake_map_arr_11,
    output wire [15:0] snake_map_arr_12,
    output wire [15:0] snake_map_arr_13,
    output wire [15:0] snake_map_arr_14,
    output wire [15:0] snake_map_arr_15,
    output reg hdmi_tx_en,
    output reg game_over_flag
);

parameter ADDRESS_STEP_N = 11'd4;
parameter HDMI_TX_EN_DELAY_CLK = 4'd5;
parameter DATA_BEGIN_ADDRESS = 11'd4;

localparam HEAD_ADDRESS = 11'd4;
localparam NULL_ADDRESS = 11'd0;
localparam
    SNAKE_DPB_CHANB_IDLE    = 4'd0,
    SNAKE_DPB_CHANB_CL_CACHE= 4'd4,
    SNAKE_DPB_CHANB_GETHEAD = 4'd1,
    SNAKE_DPB_CHANB_RD_WR   = 4'd2,
    SNAKE_DPB_CHANB_OUT     = 4'd3,
    SNAKE_DPB_CHANB_FINISH  = 4'd5,
    SNAKE_UPD_POINT_POS     = 4'd6;

reg [10:0] list_now_addr;

reg [3:0]  state;
reg [3:0]  step_cnt;
reg [10:0] wr_cnt;

reg [7:0]  snake_head_pos;
reg [7:0]  snake_body_pos_x;
reg [7:0]  snake_body_pos_y;

reg [15:0] snake_map_arr [0:15];

reg [7:0] clk_cnt = 8'd0;
reg [7:0] pos_cnt = 8'd0;

assign snake_map_arr_0  = snake_map_arr[0 ];
assign snake_map_arr_1  = snake_map_arr[1 ];
assign snake_map_arr_2  = snake_map_arr[2 ];
assign snake_map_arr_3  = snake_map_arr[3 ];
assign snake_map_arr_4  = snake_map_arr[4 ];
assign snake_map_arr_5  = snake_map_arr[5 ];
assign snake_map_arr_6  = snake_map_arr[6 ];
assign snake_map_arr_7  = snake_map_arr[7 ];
assign snake_map_arr_8  = snake_map_arr[8 ];
assign snake_map_arr_9  = snake_map_arr[9 ];
assign snake_map_arr_10 = snake_map_arr[10];
assign snake_map_arr_11 = snake_map_arr[11];
assign snake_map_arr_12 = snake_map_arr[12];
assign snake_map_arr_13 = snake_map_arr[13];
assign snake_map_arr_14 = snake_map_arr[14];
assign snake_map_arr_15 = snake_map_arr[15];

initial begin
    clk_cnt <= 0;
    pos_cnt <= 0;
    snake_point_pos <= 8'hff;
    snake_point_pos_exit <= 1'd1;
    list_now_addr  <= HEAD_ADDRESS;
    state          <= SNAKE_DPB_CHANB_IDLE;
    step_cnt       <= 0;
    wr_cnt         <= 0;
    i_b_clk_en     <= 1;
    i_b_data_en    <= 1;
    i_b_wr_en      <= 0;
    hdmi_tx_en     <= 1;
    busy           <= 0;
    game_over_flag <= 0;
    snake_map_arr[0 ] <= 8'h00;
    snake_map_arr[1 ] <= 8'h00;
    snake_map_arr[2 ] <= 8'h00;
    snake_map_arr[3 ] <= 8'h00;
    snake_map_arr[4 ] <= 8'h00;
    snake_map_arr[5 ] <= 8'h00;
    snake_map_arr[6 ] <= 8'h00;
    snake_map_arr[7 ] <= 8'h00;
    snake_map_arr[8 ] <= 8'h00;
    snake_map_arr[9 ] <= 8'h00;
    snake_map_arr[10] <= 8'h00;
    snake_map_arr[11] <= 8'h00;
    snake_map_arr[12] <= 8'h00;
    snake_map_arr[13] <= 8'h00;
    snake_map_arr[14] <= 8'h00;
    snake_map_arr[15] <= 8'h00;
end

always@(posedge clk)begin
    i_b_clk_en     <= 1;
    i_b_data_en    <= 1;
    i_b_data       <= 8'd0;
    if(state == SNAKE_DPB_CHANB_FINISH)begin
        clk_cnt <= 0;
    end
    else if (state == SNAKE_UPD_POINT_POS)begin
        clk_cnt <= clk_cnt;
    end
    else begin
        clk_cnt <= clk_cnt + 8'd1;
    end
    case(state)
    SNAKE_DPB_CHANB_IDLE:begin
        step_cnt       <= 0;
        wr_cnt         <= 0;
        hdmi_tx_en     <= 1;
        if(en)begin
            state <= SNAKE_DPB_CHANB_CL_CACHE;
            busy <= 1;
        end
        else begin
            state <= SNAKE_DPB_CHANB_IDLE;
            busy <= 0;
        end
    end
    SNAKE_DPB_CHANB_CL_CACHE:begin
        snake_map_arr[0 ] <= 8'h00;
        snake_map_arr[1 ] <= 8'h00;
        snake_map_arr[2 ] <= 8'h00;
        snake_map_arr[3 ] <= 8'h00;
        snake_map_arr[4 ] <= 8'h00;
        snake_map_arr[5 ] <= 8'h00;
        snake_map_arr[6 ] <= 8'h00;
        snake_map_arr[7 ] <= 8'h00;
        snake_map_arr[8 ] <= 8'h00;
        snake_map_arr[9 ] <= 8'h00;
        snake_map_arr[10] <= 8'h00;
        snake_map_arr[11] <= 8'h00;
        snake_map_arr[12] <= 8'h00;
        snake_map_arr[13] <= 8'h00;
        snake_map_arr[14] <= 8'h00;
        snake_map_arr[15] <= 8'h00;
        snake_point_pos_exit <= 1'd1;
        state <= SNAKE_DPB_CHANB_GETHEAD;
        step_cnt       <= 0;
        wr_cnt         <= 0;
        game_over_flag <= 0;
    end
    SNAKE_DPB_CHANB_GETHEAD:begin
            i_b_wr_en <= 0;
            case(step_cnt)
                4'd0:begin
                    step_cnt <= step_cnt + 4'd1;
                    i_b_address <= list_head_addr;
                end
                4'd1:begin
                    step_cnt <= step_cnt + 4'd1;
                end
                4'd2:begin
                    step_cnt <= step_cnt + 4'd1;
                end
                4'd3:begin
                    step_cnt <= 4'd0;
                    snake_head_pos <= o_b_data;
                    state <= SNAKE_DPB_CHANB_RD_WR;
                    list_now_addr <= DATA_BEGIN_ADDRESS;
                    wr_cnt <= 0;
                end
            endcase
    end
    SNAKE_DPB_CHANB_RD_WR:begin
            i_b_wr_en <= 0;
            case(step_cnt)
                4'd0:begin
                    i_b_address <= list_now_addr;
                    step_cnt <= step_cnt + 4'd1;
                end
                4'd1:begin
                    step_cnt <= step_cnt + 4'd1;
                end
                4'd2:begin
                    step_cnt <= step_cnt + 4'd1;
                end
                4'd3:begin
                    step_cnt <= step_cnt + 4'd1;
                    snake_body_pos_x <= o_b_data >> 4;
                    snake_body_pos_y <= o_b_data & 8'h0f;
                    if(list_now_addr != list_head_addr && o_b_data == snake_head_pos)begin
                        game_over_flag <= 1;
                    end
                    if(snake_point_pos == o_b_data)begin
                        snake_point_pos_exit <= 0;
                    end
                end
                4'd4:begin
                    step_cnt <= 4'd0;
                    list_now_addr <= list_now_addr + ADDRESS_STEP_N;
                    wr_cnt <= wr_cnt + 11'd1;
                    snake_map_arr[snake_body_pos_y] <= snake_map_arr[snake_body_pos_y]|(16'd1<<snake_body_pos_x);
                    if(wr_cnt == list_length - 1)begin
                        if(snake_point_pos_exit == 0)begin//果实被吃
                            clk_cnt <= I_clk_cnt;
                            state <= SNAKE_UPD_POINT_POS;
                            pos_cnt <= 0;
                        end
                        else begin
                            state <= SNAKE_DPB_CHANB_OUT;
                        end
                    end
                    else begin
                        state <= SNAKE_DPB_CHANB_RD_WR;
                    end
                end
            endcase
    end
    SNAKE_UPD_POINT_POS:begin
        pos_cnt <= pos_cnt + 8'd1;
        if(~(snake_map_arr[pos_cnt&8'h0f]&(8'd1<<pos_cnt[7:4])))begin
            clk_cnt <= clk_cnt - 8'd1;
        end
        if(clk_cnt == 8'd0)begin
            state <= SNAKE_DPB_CHANB_OUT;
            snake_point_pos_exit <= 1'd1;
            snake_point_pos <= pos_cnt;
        end
        else begin
            state <= SNAKE_UPD_POINT_POS;
        end
    end
    SNAKE_DPB_CHANB_OUT:begin
        hdmi_tx_en <= 1;
        if(step_cnt == HDMI_TX_EN_DELAY_CLK)begin
            step_cnt <= 4'd0;
            state <= SNAKE_DPB_CHANB_FINISH;
        end
        else begin
            step_cnt <= step_cnt + 4'd1;
        end
    end
    SNAKE_DPB_CHANB_FINISH:begin
        busy <= 0;
        hdmi_tx_en <= 1;
        state <= SNAKE_DPB_CHANB_IDLE;
    end
    endcase
end

endmodule
