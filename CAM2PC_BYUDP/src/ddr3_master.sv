module ddr3_master(
    input clk,//27mhz
    input clk50m,
    input rst_n,
    ddr3_phy_interface_typedef ddr3_port,

);

logic memory_clk, DDR_pll_lock, half_memory_clk;
logic init_calib_complete;

DDR3MI DDR3_Memory_Interface_Top_inst 
(
    .clk                (clk50m             ),
    .memory_clk         (memory_clk         ),
    .pll_lock           (DDR_pll_lock       ),
    .rst_n              (rst_n              ), //rst_n
    .app_burst_number   (app_burst_number   ),
    .cmd_ready          (cmd_ready          ),
    .cmd                (cmd                ),
    .cmd_en             (cmd_en             ),
    .addr               (addr               ),
    .wr_data_rdy        (wr_data_rdy        ),
    .wr_data            (wr_data            ),
    .wr_data_en         (wr_data_en         ),
    .wr_data_end        (wr_data_end        ),
    .wr_data_mask       (wr_data_mask       ),
    .rd_data            (rd_data            ),
    .rd_data_valid      (rd_data_valid      ),
    .rd_data_end        (rd_data_end        ),
    .sr_req             (1'b0               ),
    .ref_req            (1'b0               ),
    .sr_ack             (                   ),
    .ref_ack            (                   ),
    .init_calib_complete(init_calib_complete),
    .clk_out            (half_memory_clk    ),
    .burst              (1'b1               ),
    // mem interface
    .ddr_rst            (                           ),
    .O_ddr_addr         (ddr3_port.ddr_addr         ),
    .O_ddr_ba           (ddr3_port.ddr_bank         ),
    .O_ddr_cs_n         (ddr3_port.ddr_cs           ),
    .O_ddr_ras_n        (ddr3_port.ddr_ras          ),
    .O_ddr_cas_n        (ddr3_port.ddr_cas          ),
    .O_ddr_we_n         (ddr3_port.ddr_we           ),
    .O_ddr_clk          (ddr3_port.ddr_ck           ),
    .O_ddr_clk_n        (ddr3_port.ddr_ck_n         ),
    .O_ddr_cke          (ddr3_port.ddr_cke          ),
    .O_ddr_odt          (ddr3_port.ddr_odt          ),
    .O_ddr_reset_n      (ddr3_port.ddr_reset_n      ),
    .O_ddr_dqm          (ddr3_port.ddr_dm           ),
    .IO_ddr_dq          (ddr3_port.ddr_dq           ),
    .IO_ddr_dqs         (ddr3_port.ddr_dqs          ),
    .IO_ddr_dqs_n       (ddr3_port.ddr_dqs_n        )
);

mem_pll mem_pll_m0(
	.clkin                     (clk                        ),
	.clkout                    (memory_clk 	              		),
	.lock 					   (DDR_pll_lock 						)
	);

typedef struct{
    logic isempty;
    logic [2:0] addr;
    logic [13:0] row_addr_end;
    logic [9:0]  col_addr_end;
} jpeg_bank_data_typedef;
jpeg_bank_data_typedef jpeg_now, jpeg_wr;
jpeg_now = '{isempty:1'd0,addr:3'd0,default:0};
jpeg_wr =  '{isempty:1'd0,addr:3'd1,default:0};

endmodule