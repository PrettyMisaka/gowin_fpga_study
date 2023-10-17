`include "inc/cam_interface.svh"
module cam_top(
	input                       clk,//27mhz 
	input                       rst_n,
    cam_phy_interface_typedef cam_port,
	
    output logic cam_init_done,
    output logic vsync,
    output logic de,
	output logic half_cmos_clk,
    output logic [15:0] data_bgr565,
    output logic [23:0] data_bgr888,
	
	inout                       cmos_scl,          //cmos i2c clock
	inout                       cmos_sda 
);

assign cam_port.cmos_xclk = cmos_clk;
assign cam_port.cmos_pwdn = 1'b0;
assign cam_port.cmos_rst_n = 1'b1;

assign  vsync = cam_port.cmos_vsync;

logic [31:0] lut_data;

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
	.done                       ( cam_init_done   ),
	.i2c_scl                    (cmos_scl         ),
	.i2c_sda                    (cmos_sda         )
);
//configure look-up table
lut_ov5640_rgb565_1024_768 lut_ov5640_rgb565_1024_768_m0(
	.lut_index                  (lut_index                ),
	.lut_data                   (lut_data                 )
);
//CMOS sensor 8bit data is converted to 16bit data
my_cmos_8_16bit my_cmos_8_16bit_m0(
	.i_pclk		          	(cam_port.cmos_pclk       ),
	.i_pdata		        (cam_port.cmos_db         ),
	.i_de			        (cam_port.cmos_href       ),
	.o_pdata_bgr888         ( data_bgr888       	  ),
	.o_pdata_bgr565         ( data_bgr565       	  ),
	.o_half_pclk	        ( half_cmos_clk     	  ),
	.o_de			        ( de			    	  )
);
//generate the CMOS sensor clock and the SDRAM controller clock
cmos_pll cmos_pll_m0(
	.clkin                     (clk                      		),
	.clkout                    (cmos_clk 	              		)
	);
endmodule