module sdio_top(
    input       clk48mhz    ,
    input       rst_n       ,

    output wire sdio_clk    ,
    inout       sdio_cmd    ,
    inout [3:0] sdio_data
);


wire clk_mod, ctrl_clk;
assign clk_mod = 1'd0;
sdio_clk_control sdio_clk_control0(
    .rst_n          (  rst_n     ),
    .clk48mhz       (  clk48mhz  ),
    .clk_mod        (  clk_mod   ),
    .ctrl_clk       (  ctrl_clk  ),
    .sdio_clk       (  sdio_clk  )    
);


wire sdio_cmd_o, sdio_cmd_oen, sdio_cmd_i;
wire tx_en, tx_busy;
wire [5:0]      tx_cmd   ;
wire [31:0]     tx_para  ;
sdio_tx sdio_tx0(
    .ctrl_clk           (   ctrl_clk        ),    
    .sdio_clk           (   sdio_clk        ),    
    .rst_n              (   rst_n           ),    

    .sdio_cmd_o         (   sdio_cmd_o      ),
    .sdio_cmd_oen       (   sdio_cmd_oen    ),

    .i_en               (   tx_en           ),
    .i_cmd              (   tx_cmd          ),
    .i_para             (   tx_para         ),
    .o_busy             (   tx_busy         )
);

wire rx_listen, rx_rsp136en;
wire rx_de, rx_crc7_down, rx_busy;
wire [5:0]    rx_cmd       ;
wire [31:0]   rx_para      ;
wire [119:0]  rx_cid       ;
sdio_rx sdio_rx0(
    .ctrl_clk           (   ctrl_clk        ),    
    .sdio_clk           (   sdio_clk        ),    
    .rst_n              (   rst_n           ),  

    .sdio_cmd_i         (   sdio_cmd_i      ),

    .i_listen           (   rx_listen       ),
    .i_rsp136en         (   rx_rsp136en     ),
    .o_de               (   rx_de           ),
    .o_crc7_down        (   rx_crc7_down    ),
    .o_cmd              (   rx_cmd          ),
    .o_para             (   rx_para         ),
    .o_cid              (   rx_cid          ),
    .o_busy             (   rx_busy         )
);

wire init_down;
sdio_init sdio_init0(
    .ctrl_clk           (   ctrl_clk        ),    
    .sdio_clk           (   sdio_clk        ),    
    .rst_n              (   rst_n           ),  

    .o_tx_en            (   tx_en           ),
    .o_tx_cmd           (   tx_cmd          ),
    .o_tx_para          (   tx_para         ),
    .i_tx_busy          (   tx_busy         ),  

    .o_rx_listen        (   rx_listen       ),
    .o_rx_rsp136en      (   rx_rsp136en     ),
    .i_rx_de            (   rx_de           ),
    .i_rx_crc7_down     (   rx_crc7_down    ),
    .i_rx_cmd           (   rx_cmd          ),
    .i_rx_para          (   rx_para         ),
    .i_rx_cid           (   rx_cid          ),
    .i_rx_busy          (   rx_busy         ),

    .init_down          (   init_down       )       
);

assign sdio_cmd_i = sdio_cmd;
assign sdio_cmd = (sdio_cmd_oen == 1'd1)?sdio_cmd_o:1'bz;



endmodule