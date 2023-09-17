module GreedySnake_dpb_r(
    input clk,
    input en,
    output reg busy,
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
    output reg [15:0] snake_map_arr [0:15],
    output reg hdmi_tx_en,
    output reg game_over_flag
);

parameter ADDRESS_STEP_N = 11'd4;
parameter HDMI_TX_EN_DELAY_CLK = 4'd5;

localparam DATA_BEGIN_ADDRESS = 11'd4;
localparam NULL_ADDRESS = 11'd0;
localparam
    SNAKE_DPB_CHANB_IDLE    = 4'd0,
    SNAKE_DPB_CHANB_CL_CACHE= 4'd4,
    SNAKE_DPB_CHANB_GETHEAD = 4'd1,
    SNAKE_DPB_CHANB_RD_WR   = 4'd2,
    SNAKE_DPB_CHANB_OUT     = 4'd3,
    SNAKE_DPB_CHANB_FINISH  = 4'd5;

reg [10:0] list_now_addr;

reg [3:0]  state;
reg [3:0]  step_cnt;
reg [10:0] wr_cnt;

reg [7:0]  snake_head_pos;
reg [7:0]  snake_body_pos_x;
reg [7:0]  snake_body_pos_y;

initial begin
    list_now_addr  <= HEAD_ADDRESS;
    list_tmp0_addr <= 11'd0;
    list_tmp1_addr <= 11'd0;
    state          <= SNAKE_DPB_CHANB_IDLE;
    step_cnt       <= 0;
    wr_cnt         <= 0;
    i_a_clk_en     <= 1;
    i_a_data_en    <= 1;
    i_a_wr_en      <= 0;
    hdmi_tx_en     <= 0;
    busy           <= 0;
    game_over_flag <= 0;
    snake_map_arr  <= '{8'h00, 8'h00, 8'h00, 8'h00,
                        8'h00, 8'h00, 8'h00, 8'h00,
                        8'h00, 8'h00, 8'h00, 8'h00,
                        8'h00, 8'h00, 8'h00, 8'h00};
end

always@(posedge clk)begin
    case(state)
    SNAKE_DPB_CHANB_IDLE:begin
        step_cnt       <= 0;
        wr_cnt         <= 0;
        hdmi_tx_en     <= 0;
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
        snake_map_arr  <= '{8'h00, 8'h00, 8'h00, 8'h00,
                            8'h00, 8'h00, 8'h00, 8'h00,
                            8'h00, 8'h00, 8'h00, 8'h00,
                            8'h00, 8'h00, 8'h00, 8'h00};
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
                end
                4'd4:begin
                    step_cnt <= 4'd0;
                    list_now_addr <= list_now_addr + ADDRESS_STEP_N;
                    wr_cnt <= wr_cnt + 11'd1;
                    snake_map_arr[snake_body_pos_y] <= snake_map_arr[snake_body_pos_y]|(16'd1<<snake_body_pos_x)
                    if(wr_cnt == list_length - 1)begin
                        state <= SNAKE_DPB_CHANB_OUT;
                    end
                    else begin
                        state <= SNAKE_DPB_CHANB_RD_WR;
                    end
                end
            endcase
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
        state <= SNAKE_DPB_CHANB_IDLE;
    end
    endcase
end

endmodule
