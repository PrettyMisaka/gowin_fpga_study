module sdio_top_sim();

reg clk = 'd0;
always#1 clk = ~clk;

sdio_top sdio_top(
    .clk48mhz    (  clk     ),
    .rst_n       (  1'd1    )
);




endmodule
