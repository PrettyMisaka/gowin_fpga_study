`include "inc/cam_interface.svh"
module cam_top(
	input                       clk,//27mhz 
	input                       rst_n,
	// input						rst_n_pwd,
	// input						rst_n_pll,
    cam_phy_interface_typedef cam_port,
	
    output logic cam_init_done,
    output logic vsync,
    output logic de,
	output logic half_cmos_clk,
    output logic [15:0] data_bgr565,
    output logic [23:0] data_bgr888,
	
	// inout                       cmos_scl,          //cmos i2c clock
	// inout                       cmos_sda 
    input scl_i,
    output logic scl_o,
    output logic scl_out_en,

    input sda_i,
    output logic sda_o,
    output logic sda_out_en
);
logic pll_lock, pll_reset;
assign pll_reset = ~rst_n;
logic rst_n_module;
assign rst_n_module = rst_n&pll_lock;
logic cmos_8_16bit_down;
logic i2c_init_down;
assign cam_init_done = i2c_init_down&cmos_8_16bit_down;
// assign cam_init_done = cmos_8_16bit_down;

assign cam_port.cmos_xclk = cmos_clk;
// assign cam_port.cmos_pwdn = 1'b0;
// assign cam_port.cmos_rst_n = 1'b1;
// assign cam_port.cmos_pwdn = ~rst_n_pwd;
// assign cam_port.cmos_rst_n = rst_n_pwd;
assign cam_port.cmos_pwdn = ~rst_n;
assign cam_port.cmos_rst_n = rst_n;

assign  vsync = cam_port.cmos_vsync;

logic [31:0] lut_data;
logic [9:0]  lut_index;

//I2C master controller
i2c_config i2c_config_m0(
	// .rst						(1'd0					  ),
	.rst                        (~rst_n_module            ),
	.clk                        (clk                      ),
	.clk_div_cnt                (16'd270                  ),
	.i2c_addr_2byte             (1'b1                     ),
	.lut_index                  (lut_index                ),
	.lut_dev_addr               (lut_data[31:24]          ),
	.lut_reg_addr               (lut_data[23:8]           ),
	.lut_reg_data               (lut_data[7:0]            ),
	.error                      (                         ),
	.done                       ( i2c_init_down   		  ),
	// .i2c_scl                    (cmos_scl         ),
	// .i2c_sda                    (cmos_sda         )

    .scl_i						(scl_i					  ),
    .scl_o						(scl_o					  ),
    .scl_out_en					(scl_out_en				  ),

    .sda_i						(sda_i					  ),
    .sda_o						(sda_o					  ),
    .sda_out_en					(sda_out_en				  )

);
//configure look-up table
lut_ov5640_rgb565_640_480_45 lut_ov5640_rgb565_640_480_45_0(
	.lut_index                  (lut_index                ),
	.lut_data                   (lut_data                 )
);
//CMOS sensor 8bit data is converted to 16bit data
my_cmos_8_16bit my_cmos_8_16bit_m0(
	.rst_n					(rst_n_module			  ),
	.i_pclk		          	(cam_port.cmos_pclk       ),
	.i_pdata		        (cam_port.cmos_db         ),
	.i_de			        (cam_port.cmos_href       ),
	.o_pdata_bgr888         ( data_bgr888       	  ),
	.o_pdata_bgr565         ( data_bgr565       	  ),
	.o_half_pclk	        ( half_cmos_clk     	  ),
	.o_de			        ( de			    	  ),
	.o_down					( cmos_8_16bit_down		  )
);
//generate the CMOS sensor clock and the SDRAM controller clock
cmos_pll cmos_pll_m0(
	.clkin                     (clk                      		),
	.clkout                    (cmos_clk 	              		),
	.reset					   (pll_reset						), //input reset
	.lock					   (pll_lock						) //input clkin
	);
endmodule