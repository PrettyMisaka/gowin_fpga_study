module GreedySnake_dpb_w(
    input clk,
    input en,
    input rst,
    input [1:0] forward,
    input [3:0] mode,
    input [7:0] snake_point_pos,
    output reg busy,
// Gowin_DPB channel A
    output reg i_a_clk_en,
    output reg i_a_data_en,
    output reg i_a_wr_en,
    input       [7:0]   o_a_data,
    output reg  [7:0]   i_a_data,
    output reg  [10:0]  i_a_address,
// Gowin_DPB channel B DATA
    output wire [10:0] list_length_wire,
    output wire [10:0] list_head_addr_wire
);

parameter ADDRESS_STEP_N = 11'd4;

localparam 
    BSRAM_IDLE                  = 4'd0 ,
    BSRAM_UPDATE_POS_CMP        = 4'd1 ,
    BSRAM_UPDATE_POS_ADD_RD     = 4'd2 ,
    BSRAM_UPDATE_POS_UPD_RD     = 4'd3 ,
    BSRAM_UPDATE_POS_UPD_CL     = 4'd4 ,
    BSRAM_UPDATE_POS_WRT        = 4'd5 ,
    BSRAM_RESET_SNAKE           = 4'd6 ,
    BSRAM_FINISH                = 4'd7 ;
localparam
    FORWARD_X_UP    = 2'b00,
    FORWARD_X_DOWN  = 2'b01,
    FORWARD_Y_UP    = 2'b10,
    FORWARD_Y_DOWN  = 2'b11;
localparam NULL_ADDRESS = 11'd0;
localparam HEAD_ADDRESS = 11'd4;
localparam
    MODE_UPDATE_POS     = 4'd1,
    MODE_RESET_SNAKE    = 4'd0;
localparam HEAD_POSITION_XY = 8'h44;

reg [10:0]   list_head_addr;
reg [10:0]   list_tmp0_addr;
reg [10:0]   list_tmp1_addr;
reg [10:0]   list_now_addr;
reg [10:0]   list_length;

reg [3:0]  state;
reg [3:0]  step_cnt;
reg [10:0] wr_cnt;

reg [1:0]  i_forward;
reg [7:0]  snake_head_pos;
reg [7:0]  snake_next_head_pos;

assign list_length_wire = list_length;
assign list_head_addr_wire = list_head_addr;

initial begin
    list_head_addr <= HEAD_ADDRESS;
    list_now_addr  <= HEAD_ADDRESS;
    list_tmp0_addr <= 11'd0;
    list_tmp1_addr <= 11'd0;
    state          <= BSRAM_IDLE;
    step_cnt       <= 0;
    wr_cnt         <= 0;
    i_a_clk_en     <= 1;
    i_a_data_en    <= 1;
    i_a_wr_en      <= 0;
end

always @(posedge clk) begin
    if(rst)begin
        i_a_clk_en     <= 1;
        i_a_data_en    <= 1;
    end
    case(state)
        BSRAM_IDLE:begin
            i_a_wr_en   <= 0;
            step_cnt    <= 0;
            wr_cnt      <= 0;
            list_tmp0_addr <= 11'd0;
            list_tmp1_addr <= 11'd0;
            if(en)begin
                case(mode)
                    MODE_UPDATE_POS:begin
                        state <= BSRAM_UPDATE_POS_CMP;
                        i_forward <= forward;
                        list_now_addr <= list_head_addr;
                        busy <= 1;
                    end
                    MODE_RESET_SNAKE:begin
                        state <= BSRAM_RESET_SNAKE;
                        wr_cnt <= 11'd0;
                        list_length <= 11'd0;
                        list_head_addr <= HEAD_ADDRESS;
                        list_now_addr  <= HEAD_ADDRESS;
                        snake_head_pos <= HEAD_POSITION_XY;
                        busy <= 1;
                    end
                    default: begin
                        state <= BSRAM_IDLE;
                    end
                endcase
            end
            else begin
                state <= BSRAM_IDLE;
                busy <= 0;
            end
        end
        BSRAM_UPDATE_POS_CMP:begin
            i_a_wr_en <= 0;
            case(step_cnt)
                4'd0:begin
                    step_cnt <= step_cnt + 4'd1;
                    i_a_address <= list_now_addr;
                end
                4'd1:begin
                    step_cnt <= step_cnt + 4'd1;
                    i_a_address <= list_now_addr + step_cnt;
                end
                4'd2:begin
                    step_cnt <= step_cnt + 4'd1;
                    i_a_address <= list_now_addr + step_cnt;
                end
                4'd3:begin
                    step_cnt <= step_cnt + 4'd1;
                    i_a_address <= list_now_addr + step_cnt;
                    // o_a_data position val
                    snake_head_pos <= o_a_data;
                end
                4'd4:begin
                    step_cnt <= step_cnt + 4'd1;
                    i_a_address <= NULL_ADDRESS;
                    case(i_forward)
                        FORWARD_X_UP:begin
                            snake_next_head_pos <= snake_head_pos + 8'b00010000;
                        end
                        FORWARD_X_DOWN:begin
                            snake_next_head_pos <= snake_head_pos - 8'b00010000;
                        end
                        FORWARD_Y_UP:begin
                            snake_next_head_pos <= snake_head_pos + 8'b00000001;
                        end
                        FORWARD_Y_DOWN:begin
                            snake_next_head_pos <= snake_head_pos - 8'b00000001;
                        end
                    endcase
                end
                4'd5:begin
                    step_cnt <= step_cnt + 4'd1;
                    i_a_address <= NULL_ADDRESS;
                    list_now_addr <= {o_a_data[2:0],8'd0};
                end
                4'd6:begin
                    step_cnt <= 4'd0;
                    i_a_address <= NULL_ADDRESS;
                    list_now_addr <= list_now_addr + o_a_data;
                    if(snake_next_head_pos == snake_point_pos)begin
                        state <= BSRAM_UPDATE_POS_ADD_RD;
                    end
                    else begin
                        state <= BSRAM_UPDATE_POS_UPD_RD;
                    end
                end
            endcase
        end
        BSRAM_UPDATE_POS_ADD_RD:begin
            list_length <= list_length + 11'd1;
            list_tmp0_addr <= (list_length + 11'd1)<<2;
            state <= BSRAM_UPDATE_POS_WRT;
        end
        BSRAM_UPDATE_POS_UPD_RD:begin
            i_a_wr_en <= 0;
            case(step_cnt)
                4'd0:begin
                    step_cnt <= step_cnt + 4'd1;
                    i_a_address <= list_now_addr;
                    // last address
                    list_tmp0_addr <= list_now_addr;
                    // last last address
                    list_tmp1_addr <= list_tmp0_addr;
                end
                4'd1:begin
                    step_cnt <= step_cnt + 4'd1;
                    i_a_address <= list_now_addr + step_cnt;
                end
                4'd2:begin
                    step_cnt <= step_cnt + 4'd1;
                    i_a_address <= list_now_addr + step_cnt;
                end
                4'd3:begin
                    step_cnt <= step_cnt + 4'd1;
                    i_a_address <= list_now_addr + step_cnt;
                end
                4'd4:begin
                    step_cnt <= step_cnt + 4'd1;
                    i_a_address <= NULL_ADDRESS;
                end
                4'd5:begin
                    step_cnt <= step_cnt + 4'd1;
                    i_a_address <= NULL_ADDRESS;
                    list_now_addr <= {o_a_data[2:0],8'd0};
                end
                4'd6:begin
                    step_cnt <= 4'd0;
                    i_a_address <= NULL_ADDRESS;
                    list_now_addr <= list_now_addr + o_a_data;
                    if((list_now_addr + o_a_data) == NULL_ADDRESS)begin
                        state <= BSRAM_UPDATE_POS_UPD_CL;
                    end
                end
            endcase
        end
        BSRAM_UPDATE_POS_UPD_CL:begin
            i_a_wr_en <= 1;
            case(step_cnt)
                4'd0:begin
                    i_a_address <= list_tmp1_addr;
                    step_cnt <= step_cnt + 4'd1;
                    // i_a_data <=  snake_next_head_pos;
                end
                4'd1:begin
                    step_cnt <= step_cnt + 4'd1;
                    i_a_address <= list_tmp1_addr + step_cnt;
                    i_a_data <=  8'd0;
                end
                4'd2:begin
                    step_cnt <= step_cnt + 4'd1;
                    i_a_address <= list_tmp1_addr + step_cnt;
                    i_a_data <=  NULL_ADDRESS >> 8;
                end
                4'd3:begin
                    step_cnt <= 4'd0;
                    i_a_address <= list_tmp1_addr + step_cnt;
                    state <= BSRAM_UPDATE_POS_WRT;
                    i_a_data <= NULL_ADDRESS;
                end
            endcase
        end
        BSRAM_UPDATE_POS_WRT:begin
            i_a_wr_en <= 1;
            case(step_cnt)
                4'd0:begin
                    i_a_address <= list_tmp0_addr;
                    i_a_data <=  snake_next_head_pos;
                    step_cnt <= step_cnt + 4'd1;
                end
                4'd1:begin
                    step_cnt <= step_cnt + 4'd1;
                    i_a_address <= list_tmp0_addr + step_cnt;
                    i_a_data <=  8'd0;
                end
                4'd2:begin
                    step_cnt <= step_cnt + 4'd1;
                    i_a_address <= list_tmp0_addr + step_cnt;
                    i_a_data <=  {5'd0,list_head_addr[10:8]};
                end
                4'd3:begin
                    step_cnt <= 4'd0;
                    i_a_address <= list_tmp0_addr + step_cnt;
                    state <= BSRAM_FINISH;
                    list_head_addr <= list_tmp0_addr;
                    i_a_data <= list_head_addr[7:0];
                end
            endcase
        end
        BSRAM_RESET_SNAKE:begin
            i_a_wr_en <= 1;
            case(step_cnt)
                4'd0:begin
                    list_length <= list_length + 11'd1;
                    i_a_address <= list_now_addr;
                    i_a_data <=  snake_head_pos - {wr_cnt[3:0],4'd0};
                    step_cnt <= step_cnt + 4'd1;
                end
                4'd1:begin
                    step_cnt <= step_cnt + 4'd1;
                    i_a_address <= list_now_addr + step_cnt;
                    i_a_data <=  8'd0;
                end
                4'd2:begin
                    step_cnt <= step_cnt + 4'd1;
                    i_a_address <= list_now_addr + step_cnt;
                    if(wr_cnt == 11'd2)begin
                        i_a_data <= NULL_ADDRESS;
                    end
                    else begin
                        i_a_data <= (list_now_addr + ADDRESS_STEP_N) >> 8;
                    end
                end
                4'd3:begin
                    step_cnt <= 4'd0;
                    i_a_address <= list_now_addr + step_cnt;
                    if(wr_cnt == 11'd2)begin
                        state <= BSRAM_FINISH;
                        list_now_addr <= list_head_addr;
                        i_a_data <= NULL_ADDRESS;
                    end
                    else begin
                        state <= BSRAM_RESET_SNAKE;
                        wr_cnt <= wr_cnt + 11'd1;
                        list_now_addr <= list_now_addr + ADDRESS_STEP_N;
                        i_a_data <= list_now_addr[7:0] + ADDRESS_STEP_N[7:0];
                    end
                end
            endcase
        end
        BSRAM_FINISH:begin
            i_a_wr_en <= 0;
            busy <= 0;
            state <= BSRAM_IDLE;
        end
    endcase
end


endmodule