`include "cam_interface.svh"
module cam_top(
	input                       clk,//27mhz 
	input                       rst_n,
    cam_phy_interface_typedef cam_port,
    cam_user_interface_typedef cam_user
);

assign cam_port.cmos_xclk = cam_port.cmos_clk;
assign cam_port.cmos_pwdn = 1'b0;
assign cam_port.cmos_rst_n = 1'b1;

assign cam_user.vsync = cam_port.cmos_vsync;

//I2C master controller
i2c_config i2c_config_m0(
	.rst                        (~rst_n                   ),
	.clk                        (clk                      ),
	.clk_div_cnt                (16'd270                  ),
	.i2c_addr_2byte             (1'b1                     ),
	.lut_index                  (lut_index                ),
	.lut_dev_addr               (lut_data[31:24]          ),
	.lut_reg_addr               (lut_data[23:8]           ),
	.lut_reg_data               (lut_data[7:0]            ),
	.error                      (                         ),
	.done                       (cam_user.cam_init_done   ),
	.i2c_scl                    (cam_port.cmos_scl        ),
	.i2c_sda                    (cam_port.cmos_sda        )
);
//configure look-up table
lut_ov5640_rgb565_1024_768 lut_ov5640_rgb565_1024_768_m0(
	.lut_index                  (lut_index                ),
	.lut_data                   (lut_data                 )
);
//CMOS sensor 8bit data is converted to 16bit data
cmos_8_16bit cmos_8_16bit_m0(
	.rst                        (~rst_n                   ),
	.pclk                       (cam_port.cmos_pclk       ),
	.pdata_i                    (cam_port.cmos_db         ),
	.de_i                       (cam_port.cmos_href       ),
	.pdata_o                    (cmos_16bit_data          ),
	.hblank                     (cmos_16bit_wr            ),
	.de_o                       (cmos_16bit_clk           )
);
//generate the CMOS sensor clock and the SDRAM controller clock
cmos_pll cmos_pll_m0(
	.clkin                     (clk                      		),
	.clkout                    (cmos_clk 	              		)
	);
endmodule