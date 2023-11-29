module sdio_tx_sim();

reg clk,clk400khz;
reg clk_mod;
reg rst_n;
wire sdio_clk;
wire ctrl_clk;
always#1 clk = ~clk;
always#60 clk400khz = ~clk400khz;
sdio_clk_control sdio_clk_control0(
    .rst_n       (rst_n       ),
    .clk48mhz    (clk         ),
    .clk_mod     (clk_mod     ),
    .ctrl_clk    (ctrl_clk    ),
    .sdio_clk    (sdio_clk    )
);

reg sdio_cmd_i;
reg i_en;
reg [5:0]   i_cmd;
reg [31:0]  i_para;

initial begin
    clk     = 0;
    clk400khz = 0;
    rst_n   = 0;
    i_en    = 0;
    clk_mod = 1;
    #2 rst_n = 'd1;
    #4 
        i_en = 1'd1;
        i_cmd = 6'd0;
        i_para = 0;
    #4
        i_en = 0;
    #200 
        i_en = 1'd1;
        clk_mod = 0;
end

sdio_tx sdio_tx0(
    .ctrl_clk(ctrl_clk),    
    .sdio_clk(sdio_clk),    
    .rst_n   (rst_n   ),    

    .sdio_cmd_i  (sdio_cmd_i  ),
    .sdio_cmd_o  (sdio_cmd_o  ),
    .sdio_cmd_oen(sdio_cmd_oen),

    .i_en    (i_en    ),
    .i_cmd   (i_cmd   ),
    .i_para  (i_para  )
);

sdio_rx sdio_rx0(
    .ctrl_clk (ctrl_clk)  ,
    .sdio_clk (sdio_clk)  ,
    .rst_n    (rst_n   )  ,

    .sdio_cmd_i (sdio_cmd_o  ) ,

    .i_listen    (1'd1),
    .i_rsp136en  (1'd0)   
);

endmodule

