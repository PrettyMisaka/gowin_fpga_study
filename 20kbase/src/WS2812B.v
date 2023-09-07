module WS2812B(
    input Clock,
    input rst,
    input en,
    input [7:0]Red,
    input [7:0]Green,
    input [7:0]Blue,
    output busy,
    output WS2812B_IO
);

// parameter Clock_frequency = 27_000_000;
parameter 0_4us_cnt = 11;
parameter 0_85us_cnt = 23;

reg [7:0]Red_date;
reg [7:0]Green_date;
reg [7:0]Blue_date;

reg [3:0]date_cnt;
reg [2:0]state;

localparam
    WS2812B_IDLE     = 3'b000,
    WS2812B_GREEN    = 3'b001,
    WS2812B_RED      = 3'b010,
    WS2812B_BLUE     = 3'b011,
    WS2812B_FINISH   = 3'b100;

always@(posedge clk or negedge rst) begin
    if (!rst) begin
        state <= WS2812B_IDLE;
        busy <= 0;
        WS2812B_IO <= 0;
    end
    else begin
        case(state)
            WS2812B_IDLE:begin
                if(en) begin
                    state <= WS2812B_GREEN;
                    busy <= 1;
                    Red_date   <= Red   ;
                    Green_date <= Green ;
                    Blue_date  <= Blue  ;
                end
                else begin
                    state <= WS2812B_IDLE;
                    busy <= 0;
                end
            end
            TX_START:begin
                // uart_txd <= 0;
                if(clk_cnt == BPS_CNT - 1) begin
                    state <= TX_DATA;
                    bit_cnt <= bit_cnt + 1;
                end
            end
            TX_DATA:begin
                if(clk_cnt == BPS_CNT - 1) begin
                    bit_cnt <= bit_cnt + 1;
                    if( bit_cnt == 9) begin
                        state <= TX_FINISH;
                    end
                end
                case(bit_cnt)
                1: uart_txd <= 0;
                2: uart_txd <= tx_data[0] ;
                3: uart_txd <= tx_data[1] ;
                4: uart_txd <= tx_data[2] ;
                5: uart_txd <= tx_data[3] ;
                6: uart_txd <= tx_data[4] ;
                7: uart_txd <= tx_data[5] ;
                8: uart_txd <= tx_data[6] ;
                9: uart_txd <= tx_data[7] ;
                endcase
            end
            TX_FINISH: begin
                uart_txd <= 1;
                if(clk_cnt == BPS_CNT - 1) begin
                    state <= TX_IDLE;
                    uart_tx_busy <= 0;

                end
            end
        endcase
    end        
end


endmodule