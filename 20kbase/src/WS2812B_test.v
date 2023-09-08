module WS2812B_test(
    input Clock,
    input rst,
    output wire WS2812B_IO
);

reg en = 1;

reg [7:0]Red_date;
reg [7:0]Green_date;
reg [7:0]Blue_date;

wire busy;
reg [3:0]color_cnt;

initial begin
    en = 1;
    Red_date = 8'b1111_1111;
    Green_date = 8'b1111_1111;
    Blue_date = 8'b1111_1111;
    color_cnt = 0;
end

always@(negedge busy) begin
    color_cnt <= color_cnt + 1;
    case(color_cnt)
        4'd0:begin
            Red_date <= 8'b1111_1111;
            Green_date <= 8'b1111_1111;
            Blue_date <= 8'b1111_1111;
        end
        4'd1:begin
            Red_date <= 8'b0000_0000;
            Green_date <= 8'b0000_0000;
            Blue_date <= 8'b1111_1111;
        end
        4'd2:begin
            Red_date <= 8'b0000_0000;
            Green_date <= 8'b1111_1111;
            Blue_date <= 8'b0000_0000;
        end
        4'd3:begin
            Red_date <= 8'b1111_1111;
            Green_date <= 8'b0000_0000;
            Blue_date <= 8'b0000_0000;
        end
        4'd4:begin
            Red_date <= 8'b0000_0000;
            Green_date <= 8'b0000_0000;
            Blue_date <= 8'b0000_0000;
            color_cnt <= 0;
        end
    endcase
end

WS2812B WS2812B0(
    .Clock(Clock),
    .rst(rst),
    .en(en),
    .Red(Red_date),
    .Green(Green_date),
    .Blue(Blue_date),
    .busy(busy),
    .WS2812B_IO(WS2812B_IO)
);


endmodule