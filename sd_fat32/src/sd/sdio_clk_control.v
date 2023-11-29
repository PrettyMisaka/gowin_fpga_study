module sdio_clk_control(
    input clk,
    input rst_n,
    output reg sdio_clk
);

initial sdio_clk <= 1'd0;

always@(posedge clk or negedge rst_n)begin
    if(~rst_n)
        sdio_clk <= 1'd0;
    else
        sdio_clk <= ~sdio_clk;
end

endmodule