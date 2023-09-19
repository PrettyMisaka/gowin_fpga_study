module GreedySnake_key_ctrl(
    input clk,
    input rst,
    input key_x_up,
    input key_x_down,
    input key_y_up,
    input key_y_down,

    output reg en,
    output wire [1:0]forward,
    output reg [3:0] mode
);

parameter CLK_1S_DELAY_CNT = 32'd27_000_000;

localparam
    FORWARD_X_UP    = 2'b00,
    FORWARD_X_DOWN  = 2'b01,
    FORWARD_Y_UP    = 2'b10,
    FORWARD_Y_DOWN  = 2'b11;
localparam
    MODE_UPDATE_POS     = 4'd1,
    MODE_RESET_SNAKE    = 4'd0;

reg [31:0]  clk_cnt;
reg [1:0]   last_forward_reg;
reg [1:0]   i_forward;

wire [1:0]last_forward_wire;
assign last_forward_wire = last_forward_reg;
assign forward = i_forward;

initial begin
    clk_cnt <= 0;
    last_forward_reg <= FORWARD_X_UP;
    i_forward <= FORWARD_X_UP;
end


always@(posedge clk or negedge rst)begin
    if(!rst)begin
        i_forward <= FORWARD_X_UP;
    end
    else begin
        case(last_forward_wire)
        FORWARD_X_UP:begin
            if(key_y_up)begin
                i_forward <= FORWARD_Y_UP;
            end
            else if(key_y_down)begin
                i_forward <= FORWARD_Y_DOWN;
            end
            else if(key_x_up | key_x_down)begin
                i_forward <= FORWARD_X_UP;
            end
        end
        FORWARD_X_DOWN:begin
            if(key_y_up)begin
                i_forward <= FORWARD_Y_UP;
            end
            else if(key_y_down)begin
                i_forward <= FORWARD_Y_DOWN;
            end
            else if(key_x_up | key_x_down)begin
                i_forward <= FORWARD_X_DOWN;
            end
        end
        FORWARD_Y_UP:begin
            if(key_x_up)begin
                i_forward <= FORWARD_X_UP;
            end
            else if(key_x_down)begin
                i_forward <= FORWARD_X_DOWN;
            end
            else if(key_y_up | key_y_down)begin
                i_forward <= FORWARD_Y_UP;
            end
        end
        FORWARD_Y_DOWN:begin
            if(key_x_up)begin
                i_forward <= FORWARD_X_UP;
            end
            else if(key_x_down)begin
                i_forward <= FORWARD_X_DOWN;
            end
            else if(key_y_up | key_y_down)begin
                i_forward <= FORWARD_Y_DOWN;
            end
        end
        endcase
    end
end

reg rst_before;
wire rst_up_flag;
assign rst_up_flag = rst&&(!rst_before);

always@(posedge clk or negedge rst)begin
    rst_before <= rst;
    if(!rst)begin
        last_forward_reg <= FORWARD_X_UP;
        clk_cnt <= 32'd0;
        en <= 0;
        mode <= MODE_RESET_SNAKE;
    end
    else begin
        if(clk_cnt == CLK_1S_DELAY_CNT - 32'd1)begin
            clk_cnt <= 32'd0;
            en <= 1;
            last_forward_reg <= forward;
            mode <= MODE_UPDATE_POS;
        end
        else begin
            if(rst_up_flag)begin
                en <= 1;
                mode <= MODE_RESET_SNAKE;
            end
            else begin
                en <= 0;
                mode <= MODE_UPDATE_POS;
            end
            clk_cnt <= clk_cnt + 32'd1;
            last_forward_reg <= last_forward_reg;
        end
    end
end

endmodule
