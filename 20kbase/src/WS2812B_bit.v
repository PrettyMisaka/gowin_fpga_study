module WS2812B_bit(
    input Clock_27mhz,
    input rst,
    input bit,
    input en,
    output busy,
    output WS2812B_IO
);

parameter 0_4US_CNT = 11 ;
parameter 0_85US_CNT = 23 ;

localparam
    BIT_IDLE     = 2'b0,
    BIT_H        = 2'b1;
    BIT_L        = 2'b1;

reg [1:0]state;
reg bit_reg;
reg [4:0]clock_cnt;

always@(posedge clk or negedge rst) begin
    if (!rst) begin
        state <= BIT_IDLE;
        busy <= 0;
        WS2812B_IO <= 0;
        clock_cnt <= 0;
    end
    else begin
        case(state)
            BIT_IDLE:begin
                if(en) begin
                    state <= BIT_H;
                    busy <= 1;
                    bit_reg <= bit;
                    clock_cnt <= 0;
                    WS2812B_IO <= 1;
                end
                else
                    busy <= 0;
                    WS2812B_IO <= 0;
            end
            BIT_H:begin
                clock_cnt <= clock_cnt + 1;
                WS2812B_IO <= 1;
                if(bit_reg)
                    if(clock_cnt == 0_85US_CNT) begin
                        state <= BIT_L;
                        clock_cnt <= 0;
                    end
                    else
                        state <= BIT_H;
                else
                    if(clock_cnt == 0_4US_CNT) begin
                        state <= BIT_L;
                        clock_cnt <= 0;
                    end
                    else
                        state <= BIT_H;
            end
            BIT_L:begin
                WS2812B_IO <= 0;
                clock_cnt <= clock_cnt + 1;
                if(bit_reg)
                    if(clock_cnt == 0_4US_CNT - 1)
                        busy <= 0;
                    if(clock_cnt == 0_4US_CNT) begin
                        if(en)begin
                            state <= BIT_H;
                            busy <= 1;
                            bit_reg <= bit;
                            clock_cnt <= 0;
                            WS2812B_IO <= 1;
                        end
                        else begin
                            state <= BIT_IDLE;
                            WS2812B_IO <= 1;
                        end
                    end
                    else
                        state <= BIT_L;
                else
                    if(clock_cnt == 0_85US_CNT - 1)
                        busy <= 0;
                    if(clock_cnt == 0_85US_CNT) begin
                        if(en)begin
                            state <= BIT_H;
                            busy <= 1;
                            bit_reg <= bit;
                            clock_cnt <= 0;
                            WS2812B_IO <= 1;
                        end
                        else begin
                            state <= BIT_IDLE;
                            WS2812B_IO <= 1;
                        end
                    end
                    else
                        state <= BIT_L;
            end
        endcase
    end
end

endmodule