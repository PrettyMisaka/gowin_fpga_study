module WS2812B(
    input Clock,
    input rst,
    input wire en,
    input wire[7:0]Red,
    input wire[7:0]Green,
    input wire[7:0]Blue,
    output reg busy,
    output wire WS2812B_IO
);

// parameter Clock_frequency = 27_000_000;
// parameter 0_4us_cnt = 11;
// parameter 0_85us_cnt = 23;

reg [7:0]Red_date;
reg [7:0]Green_date;
reg [7:0]Blue_date;

reg bit;
wire bit_busy;
reg bit_en;

reg [7:0]bit_cnt;

localparam
    WS2812B_IDLE     = 3'b000,
    WS2812B_GREEN    = 3'b001,
    WS2812B_RED      = 3'b010,
    WS2812B_BLUE     = 3'b011,
    WS2812B_FINISH   = 3'b100;

reg [3:0]date_cnt;
reg [2:0]state = WS2812B_IDLE;

always@(posedge Clock or negedge rst) begin
    if (!rst) begin
        state <= WS2812B_IDLE;
        busy <= 0;
        bit_en <= 0;
    end
    else begin
        case(state)
            WS2812B_IDLE:begin
                if(en) begin
                    state <= WS2812B_GREEN;
                    busy <= 1;
                    Red_date   <= {Red[0],Red[1],Red[2],Red[3],Red[4],Red[5],Red[6],Red[7]};
                    Green_date <= ({Green[0],Green[1],Green[2],Green[3],Green[4],Green[5],Green[6],Green[7]}>>1);
                    Blue_date  <= {Blue[0],Blue[1],Blue[2],Blue[3],Blue[4],Blue[5],Blue[6],Blue[7]};
                    bit <= Green[7];
                    bit_en <= 1;
                    bit_cnt <= 1;
                end
                else begin
                    state <= WS2812B_IDLE;
                    busy <= 0;
                    bit_en <= 0;
                    bit_cnt <= 0;
                end
            end
            WS2812B_GREEN:begin
                if(bit_busy == 0)begin
                    Green_date <= Green_date >> 1;
                    if(bit_cnt == 8)begin
                        state <= WS2812B_RED;
                        bit_cnt <= 1;
                        bit <= Red_date[0];
                        Red_date <= Red_date >> 1;
                    end
                    else begin
                        bit_cnt <= bit_cnt + 1;
                        bit <= Green_date[0];
                    end
                end
            end
            WS2812B_RED:begin
                if(bit_busy == 0)begin
                    Red_date <= Red_date >> 1;
                    if(bit_cnt == 8)begin
                        state <= WS2812B_BLUE;
                        bit_cnt <= 1;
                        bit <= Blue_date[0];
                        Blue_date <= Blue_date >> 1;
                    end
                    else begin
                        bit_cnt <= bit_cnt + 1;
                        bit <= Red_date[0];
                    end
                end
            end
            WS2812B_BLUE:begin
                if(bit_busy == 0)begin
                    Blue_date <= Blue_date >> 1;
                    if(bit_cnt == 8)begin
                        state <= WS2812B_FINISH;
                        bit_cnt <= 0;
                        bit_en <= 0;
                    end
                    else begin
                        bit_cnt <= bit_cnt + 1;
                        bit <= Blue_date[0];
                    end
                end
            end
            WS2812B_FINISH:begin
                if(bit_busy == 0)begin
                    state <= WS2812B_IDLE;
                    busy <= 0;
                    bit_en <= 0;
                    bit_cnt <= 0;
                end
            end
        endcase
    end        
end

WS2812B_bit WS2812B_bit1(
    .Clock_27mhz(Clock),
    .rst(1),
    .bit(bit),
    .en(bit_en),
    .busy(bit_busy),
    .WS2812B_IO(WS2812B_IO)
);

endmodule