module WS2812B_bit(
    input Clock_27mhz,
    input rst,
    input bit,
    input en,
    output reg busy,
    output reg WS2812B_IO
);

parameter CNT04US = 5'd11 ;
parameter CNT085US = 5'd23 ;

localparam
    BIT_IDLE     = 2'b00,
    BIT_H        = 2'b01,
    BIT_L        = 2'b10;

reg [1:0]state = BIT_IDLE;
reg bit_reg;
reg [4:0]clock_cnt;

always@(posedge Clock_27mhz or negedge rst) begin
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
                    WS2812B_IO <= 0;
                end
                else
                begin
                    busy <= 0;
                    WS2812B_IO <= 0;
                end
            end
            BIT_H:begin
                clock_cnt <= clock_cnt + 1;
                WS2812B_IO <= 1;
                if(bit_reg)
                    if(clock_cnt == CNT085US - 1) begin
                        state <= BIT_L;
                        clock_cnt <= 0;
                    end
                    else
                        state <= BIT_H;
                else
                    if(clock_cnt == CNT04US - 1) begin
                        state <= BIT_L;
                        clock_cnt <= 0;
                    end
                    else
                        state <= BIT_H;
            end
            BIT_L:begin
                WS2812B_IO <= 0;
                clock_cnt <= clock_cnt + 1;
                if(bit_reg)begin
                    if(clock_cnt == CNT04US - 2)
                        busy <= 0;
                    else
                        busy <= 1;
                    if(clock_cnt == CNT04US - 1) begin
                        if(en)begin
                            state <= BIT_H;
                            busy <= 1;
                            bit_reg <= bit;
                            clock_cnt <= 0;
                            WS2812B_IO <= 0;
                        end
                        else begin
                            state <= BIT_IDLE;
                            WS2812B_IO <= 0;
                            busy <= 0;
                        end
                    end
                    else begin
                        state <= BIT_L;
                    end
                end
                else begin
                    if(clock_cnt == CNT085US - 2)
                        busy <= 0;
                    else
                        busy <= 1;
                    if(clock_cnt == CNT085US - 1) begin
                        if(en)begin
                            state <= BIT_H;
                            busy <= 1;
                            bit_reg <= bit;
                            clock_cnt <= 0;
                            WS2812B_IO <= 0;
                        end
                        else begin
                            state <= BIT_IDLE;
                            WS2812B_IO <= 0;
                            busy <= 0;
                        end
                    end
                    else begin
                        state <= BIT_L;
                    end
                end
            end
        endcase
    end
end

endmodule