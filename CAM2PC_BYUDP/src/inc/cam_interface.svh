`ifndef CAM_INTERFACE
`define CAM_INTERFACE

interface cam_user_interface_typedef(
    output logic cam_init_done,
    output logic vsync,
    output logic de,
	output logic half_cmos_clk,
    output logic [15:0] data_bgr565,
    output logic [23:0] data_bgr888
);
endinterface //rmii

interface cam_phy_interface_typedef(
	// inout                       cmos_scl,          //cmos i2c clock
	// inout                       cmos_sda,          //cmos i2c data
	input                       cmos_vsync,        //cmos vsync
	input                       cmos_href,         //cmos hsync refrence,data valid
	input                       cmos_pclk,         //cmos pxiel clock
    output                      cmos_xclk,         //cmos externl clock 
	input   [7:0]               cmos_db,           //cmos data
	output                      cmos_rst_n,        //cmos reset 
	output                      cmos_pwdn         //cmos power down
);
endinterface 

`endif //RMII_INTERFACE