`include "inc/config.svh"
module my_top(
    input                       clk,
	input                       rst_n,

    output logic                phyrst,
    output logic [5:0]          led,

    inout logic                 scl_mdc,
    inout logic                 sda_mdio,

    cam_phy_interface_typedef   cam_port,
    ddr3_phy_interface_typedef  ddr3_port,
    rmii                        netrmii
);
initial begin
    led <= 6'b111111;
end
logic clk50m;
assign clk50m = netrmii.clk50m;

struct {
    logic cam;
    logic mjpeg;
    logic ddr3;
    logic mac;
} rst;
initial rst = '{default:1'd0};

struct {
    logic cam_init_done;
    logic vsync;
    logic de;
	logic half_cmos_clk;
    logic [15:0] data_bgr565;
    logic [23:0] data_bgr888;
} cam_user;

typedef struct{
    logic out_en;
    logic out;
    logic in;
} inout_typedef;

wire cmos_scl, cmos_sda;
inout_typedef cam_inout;
inout_typedef cam_scl_inout;
cam_top cam_top0(
	.clk        (clk        ),//27mhz 
	.rst_n      (rst.cam    ),
    .cam_port   (cam_port   ),
	
    .cam_init_done  (cam_user.cam_init_done),
    .vsync          (cam_user.vsync        ),
    .de             (cam_user.de           ),
	.half_cmos_clk  (cam_user.half_cmos_clk),
    .data_bgr565    (cam_user.data_bgr565  ),
    .data_bgr888    (cam_user.data_bgr888  ),
    
	// .cmos_scl       (cmos_scl              ),          //cmos i2c clock
	// .cmos_sda       (cmos_sda              ) 

    .scl_i			(cam_scl_inout.in	    ),
    .scl_o			(cam_scl_inout.out	    ),
    .scl_out_en		(cam_scl_inout.out_en   ),

    .sda_i			(cam_inout.in		   ),
    .sda_o			(cam_inout.out		   ),
    .sda_out_en		(cam_inout.out_en	   )
);

struct {
    logic I_udp_tx_en;
    logic [7:0] I_udp_data;
    logic [15:0] I_udp_data_len;
    logic [15:0] I_ipv4_sign;
    logic O_mac_init_ready;
    logic O_udp_busy;
    logic O_udp_isLoadData;
} udp_port;

logic mac_init_down;
wire mac_mdc, mac_mdio;
// logic mac_mdio_i, mac_mdio_o, mac_out_en;
inout_typedef mac_inout;
// assign mac_mdio = mdio_out_en ? mac_mdio_o : mac_mdio_i;
mac_top mac_top0(
    .clk      (clk          ),
    .rst      (rst.mac      ),

    .netrmii  (netrmii      ),

    .mdc_o (mac_mdc ),//wire
    // .mdio(mac_mdio),//wire
    
    .I_udp_tx_en        (udp_port.I_udp_tx_en      ),
    .I_udp_data         (udp_port.I_udp_data       ),
    .I_udp_data_len     (udp_port.I_udp_data_len   ),
    .I_ipv4_sign        (udp_port.I_ipv4_sign      ),
    .O_mac_init_ready   (udp_port.O_mac_init_ready ),
    .O_udp_busy         (udp_port.O_udp_busy       ),
    .O_udp_isLoadData   (udp_port.O_udp_isLoadData ),  

    .phyrst   (phyrst       ),
    .init_down(mac_init_down),
    
    .mdio_i(mac_inout.in),
    .mdio_o(mac_inout.out),
    .mdio_out_en(mac_inout.out_en)
);

MJPEG_Encoder_Top MJPEG_Encoder0(
    .clk        (cam_user.half_cmos_clk ), //input clk
    .rstn       (rst.mjpeg              ), //input rstn
    .DE         (cam_user.de            ), //input DE
    .data_in    (cam_user.data_bgr888   ), //input [23:0] data_in
    .img_out    (img_out_o              ), //output [7:0] img_out
    .img_valid  (img_valid_o            ), //output img_valid
    .img_done   (img_done_o             ) //output img_done
);

logic memory_clk_400m, DDR_pll_lock, half_memory_clk;
logic init_calib_complete;

logic cmd_ready , cmd_en;
logic [2:0] cmd;
logic [27:0] addr;

logic wr_data_rdy, wr_data_en, wr_data_end;
logic [127:0] wr_data;
logic [15:0] wr_data_mask;

logic [127:0] rd_data;
logic rd_data_valid, rd_data_end;

DDR3MI DDR3_Memory_Interface_Top_inst 
(
    .clk                (clk50m                 ),
    .memory_clk         (memory_clk_400m        ),
    .pll_lock           (DDR_pll_lock           ),
    .rst_n              (rst.ddr3               ), //rst_n
    .app_burst_number   (6'd7                   ),
    .cmd_ready          (cmd_ready              ),
    .cmd                (cmd                    ),
    .cmd_en             (cmd_en                 ),
    .addr               (addr                   ),
    .wr_data_rdy        (wr_data_rdy            ),
    .wr_data            (wr_data                ),
    .wr_data_en         (wr_data_en             ),
    .wr_data_end        (wr_data_end            ),
    .wr_data_mask       (wr_data_mask           ),
    .rd_data            (rd_data                ),
    .rd_data_valid      (rd_data_valid          ),
    .rd_data_end        (rd_data_end            ),
    .sr_req             (1'b0                   ),
    .ref_req            (1'b0                   ),
    .sr_ack             (                       ),
    .ref_ack            (                       ),
    .init_calib_complete(init_calib_complete    ),
    .clk_out            (half_memory_clk        ),
    .burst              (1'b1                   ),
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
	.clkout                    (memory_clk_400m 	       ),
	.lock 					   (DDR_pll_lock 			   )
	);

typedef struct{
    logic isempty;
    logic [2:0] addr;
    logic [13:0] row_addr_end;
    logic [9:0]  col_addr_end;
} jpeg_bank_data_typedef;
jpeg_bank_data_typedef jpeg_now, jpeg_wr;
initial begin
    jpeg_now = '{isempty:1'd0,addr:3'd0,default:0};
    jpeg_wr =  '{isempty:1'd0,addr:3'd1,default:0};
end

enum logic[7:0] {
    IDLE, MAC_INIT, CAM_INIT, INIT_DOWN,STATE_END
} state;

inout_typedef sda_mdio_inout;
inout_typedef scl_mdc_inout;

logic init_down;
assign init_down = cam_user.cam_init_done & init_calib_complete & mac_init_down;
assign sda_mdio = sda_mdio_inout.out_en ? sda_mdio_inout.out : 1'bz ;
assign sda_mdio_inout.in = sda_mdio;

assign scl_mdc = scl_mdc_inout.out_en ? scl_mdc_inout.out : 1'bz ;
assign scl_mdc_inout.in = scl_mdc;

assign mac_inout.in = sda_mdio_inout.in;
assign cam_inout.in = sda_mdio_inout.in;
assign sda_mdio_inout.out  = (state == IDLE || state == MAC_INIT) ? mac_inout.out  : cam_inout.out;
assign sda_mdio_inout.out_en  = (state == IDLE || state == MAC_INIT) ? mac_inout.out_en  : cam_inout.out_en;

assign cam_scl_inout.in = scl_mdc_inout.in;
assign scl_mdc_inout.out  = (state == IDLE || state == MAC_INIT) ? mac_mdc  : cam_scl_inout.out;
assign scl_mdc_inout.out_en  = (state == IDLE || state == MAC_INIT) ? 1'd1  : cam_scl_inout.out_en;
// assign scl_mdc  = mac_mdc  ;
// assign sda_mdio = mac_mdio ;
// assign scl_mdc  = (state == IDLE || state == MAC_INIT) ? mac_mdc  : cmos_scl;
// assign sda_mdio = (state == IDLE || state == MAC_INIT) ? mac_mdio : cmos_sda;
// assign scl_mdc  = (state == IDLE || state == CAM_INIT) ? cmos_scl : mac_mdc ;
// assign sda_mdio = (state == IDLE || state == CAM_INIT) ? cmos_sda : mac_mdio;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        state <= IDLE;
        rst.mac  <= 1'd0;
        rst.ddr3 <= 1'd0;
        rst.cam  <= 1'd0;
        led <= 6'b111111;
    end
    else begin
        case (state)
            IDLE:begin
                state <= MAC_INIT;
                rst.ddr3 <= 1'd1;
                led <= led << 1;
            end
            MAC_INIT:begin
                rst.mac <= 1'd1;
                if(mac_init_down) begin
                    state <= CAM_INIT;
                    led <= led << 1;
                end
            end
            CAM_INIT:begin
                rst.cam <= 1'd1;
                if(cam_user.cam_init_done) begin
                    state <= INIT_DOWN;
                    led <= led << 1;
                end
            end
            INIT_DOWN:begin
                if(init_down) begin
                    state <= STATE_END;
                    led <= led << 1;
                end
            end
            STATE_END:begin
                rst.mjpeg = 1'd1;
            end
        endcase
    end
end

endmodule