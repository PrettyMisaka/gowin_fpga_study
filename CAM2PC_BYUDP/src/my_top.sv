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
logic [5:0] led_tmp;
initial begin
    led_tmp <= 6'b111111;
end
assign led[3:0] = led_tmp[3:0];
// assign led[4] = ~cam_port.cmos_href;
// assign led[5] = ;\
initial led <= 6'b111111;

logic vsync_bef;
logic [7:0] frame_cnt;
logic [7:0] frame_cnt_save;
logic [31:0] delay_1s_cnt_27mhz;
initial begin
    frame_cnt <= 6'd0;
    delay_1s_cnt_27mhz <= 32'd0;
end
always@(posedge cam_port.cmos_pclk) begin 
    vsync_bef <= cam_port.cmos_vsync;
    if(delay_1s_cnt_27mhz == 32'd84000000 - 32'd1 )begin
        delay_1s_cnt_27mhz <= 1'd0;
        frame_cnt <= 8'd0;
        frame_cnt_save <= frame_cnt;
    end
    else begin
        delay_1s_cnt_27mhz <= delay_1s_cnt_27mhz + 1'd1;
    end
    if(vsync_bef == 0 && cam_port.cmos_vsync == 1'd1) begin
        frame_cnt <= frame_cnt + 8'd1;
        led[5] <= ~led[5]; 
    end
end
logic clk50m;
assign clk50m = netrmii.clk50m;

struct {
    logic cam;
    logic mjpeg;
    logic ddr3;
    logic mac;
    logic ddr3_master;
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
// logic rst_n_pwd;
cam_top cam_top0(
	.clk        (clk        ),//27mhz 
	.rst_n      (rst.cam    ),
    // .rst_n_pwd  (rst_n_pwd  ),
    // .rst_n_pll  (1'd1       ),
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
    logic I_udp_tx_en , I_udp_tx_de;
    logic [7:0] I_udp_data;
    logic [15:0] I_udp_data_len;
    logic [15:0] I_ipv4_sign;
    logic O_head_down;
    logic O_mac_init_ready;
    logic O_udp_busy;
    logic O_udp_isLoadData , O_1Byte_pass;
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
    .I_udp_tx_de        (udp_port.I_udp_tx_de      ),
    .I_udp_data         (udp_port.I_udp_data       ),
    .I_udp_data_len     (udp_port.I_udp_data_len   ),
    .I_ipv4_sign        (udp_port.I_ipv4_sign      ),
    .O_head_down        (udp_port.O_head_down      ),
    .O_mac_init_ready   (udp_port.O_mac_init_ready ),
    .O_udp_busy         (udp_port.O_udp_busy       ),
    .O_udp_isLoadData   (udp_port.O_udp_isLoadData ), 
    .O_1Byte_pass       (udp_port.O_1Byte_pass     ), 

    .phyrst   (phyrst       ),
    .init_down(mac_init_down),
    
    .mdio_i(mac_inout.in),
    .mdio_o(mac_inout.out),
    .mdio_out_en(mac_inout.out_en)
);

logic               i_en;
logic [127:0]       i_ddr3_udp_wrdata      ; 
logic               i_udp_last_frame_flag  ; 
logic [14:0]        i_mjpeg_frame_rank     ; 
logic [15:0]        i_udp_jpeg_len         ; 
logic               i_udp_writing_head     ; 
logic [15:0]        i_udp_ipv4_sign        ; 
logic               o_ddr3_data_upd_req;
logic               o_udp_frame_down   ;
logic               o_busy             ;
udp_128bit_send udp_128bit_send0(
    .i_udp_clk50m   (clk50m),
    .i_rst_n        (1'd1  ),
    .i_en           (i_en  ),

//-------module interface-----------//
    .i_ddr3_udp_wrdata      (i_ddr3_udp_wrdata    ),
    .i_udp_last_frame_flag  (i_udp_last_frame_flag),
    .i_mjpeg_frame_rank     (i_mjpeg_frame_rank   ),
    .i_udp_jpeg_len         (i_udp_jpeg_len       ),
    // .i_udp_writing_head     (i_udp_writing_head   ),
    .i_udp_ipv4_sign        (i_udp_ipv4_sign      ),

    .o_ddr3_data_upd_req    (o_ddr3_data_upd_req  ),
    .o_udp_frame_down       (o_udp_frame_down     ),
    .o_busy                 (o_busy               ),

//-------udp interface---------------//
    .o_udp_tx_en      (udp_port.I_udp_tx_en       ),
    .o_udp_tx_de      (udp_port.I_udp_tx_de       ),
    .o_udp_data       (udp_port.I_udp_data        ),
    .o_udp_data_len   (udp_port.I_udp_data_len    ),
    .o_ipv4_sign      (udp_port.I_ipv4_sign       ),
    .i_udp_head_down  (udp_port.O_head_down       ),
    .i_udp_busy       (udp_port.O_udp_busy        ),
    .i_udp_isLoadData (udp_port.O_udp_isLoadData  ),
    .i_1Byte_pass     (udp_port.O_1Byte_pass      )
);

logic rst_mjpeg, mjpeg_clk, mjpeg_de, mjpeg_down, mjpeg_de_o;
logic [23:0] mjpeg_data_in;
logic [7:0] mjpeg_data_out;
MJPEG_Encoder_Top MJPEG_Encoder0(
    .clk        (mjpeg_clk              ), //input clk
    .rstn       (rst_mjpeg              ), //input rstn
    .DE         (mjpeg_de               ), //input DE
    .data_in    (mjpeg_data_in          ), //input [23:0] data_in
    .img_out    (mjpeg_data_out         ), //output [7:0] img_out
    .img_valid  (mjpeg_de_o             ), //output img_valid
    .img_done   (mjpeg_down             ) //output img_done
);
logic mjpeg_down_bef;
always@(posedge cam_port.cmos_pclk) begin 
    if(mjpeg_down_bef == 0 && mjpeg_down == 1'd1) begin
        led[4] <= ~led[4]; 
    end
    mjpeg_down_bef <= mjpeg_down;
end

logic memory_clk_400m, DDR_pll_lock;
wire half_memory_clk;
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
    .clk                (cam_port.cmos_pclk     ),
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
logic [31:0] delay_cnt;
enum logic[7:0] {
    IDLE, MAC_INIT, MAC2CAM_DELAY , CAM_INIT, INIT_DOWN,STATE_END
} state;

inout_typedef sda_mdio_inout;
inout_typedef scl_mdc_inout;

logic init_down , cam_init_cancel;
assign cam_init_cancel = 1'd0;
assign init_down = cam_user.cam_init_done & init_calib_complete & mac_init_down;
assign sda_mdio = sda_mdio_inout.out_en ? sda_mdio_inout.out : 1'bz ;
assign sda_mdio_inout.in = sda_mdio;

assign scl_mdc = scl_mdc_inout.out_en ? scl_mdc_inout.out : 1'bz ;
assign scl_mdc_inout.in = scl_mdc;

assign mac_inout.in = sda_mdio_inout.in;
assign cam_inout.in = sda_mdio_inout.in;
assign sda_mdio_inout.out = (state == IDLE || state == MAC_INIT) ? mac_inout.out  : (cam_init_cancel ? 1'd1 : cam_inout.out);
assign sda_mdio_inout.out_en = (state == IDLE || state == MAC_INIT) ? mac_inout.out_en  : (cam_init_cancel ? 1'd1 : cam_inout.out_en);

assign cam_scl_inout.in = scl_mdc_inout.in;
assign scl_mdc_inout.out = (state == IDLE || state == MAC_INIT) ? mac_mdc  : (cam_init_cancel ? 1'd1: cam_scl_inout.out);
assign scl_mdc_inout.out_en = (state == IDLE || state == MAC_INIT) ? 1'd1  : (cam_init_cancel ? 1'd1: cam_scl_inout.out_en);
// assign scl_mdc  = mac_mdc  ;
// assign sda_mdio = mac_mdio ;
// assign scl_mdc  = (state == IDLE || state == MAC_INIT) ? mac_mdc  : cmos_scl;
// assign sda_mdio = (state == IDLE || state == MAC_INIT) ? mac_mdio : cmos_sda;
// assign scl_mdc  = (state == IDLE || state == CAM_INIT) ? cmos_scl : mac_mdc ;
// assign sda_mdio = (state == IDLE || state == CAM_INIT) ? cmos_sda : mac_mdio;
task task_init_reg();
    state <= IDLE;
    delay_cnt<= 32'd0;
    rst.mac  <= 1'd0;
    rst.ddr3 <= 1'd0;
    rst.cam  <= 1'd0;
    rst.ddr3_master <= 1'd0;
    // rst_n_pwd<= 1'd1;
    led_tmp <= 6'b111111;
endtask //automatic
initial task_init_reg();
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        task_init_reg();
    end
    else begin
        case (state)
            IDLE:begin
                state <= MAC_INIT;
                rst.ddr3 <= 1'd1;
                // rst_n_pwd<= 1'd1;
                led_tmp <= led_tmp << 1;
            end
            MAC_INIT:begin
                rst.mac <= 1'd1;
                delay_cnt <= 32'd0;
                if(mac_init_down) begin
                    state <= CAM_INIT;
                    led_tmp <= led_tmp << 1;
                end
            end
            CAM_INIT:begin
                rst.cam <= 1'd1;
                if(cam_user.cam_init_done) begin
                    state <= INIT_DOWN;
                    led_tmp <= led_tmp << 1;
                end
            end
            INIT_DOWN:begin
                if(init_down) begin
                    state <= STATE_END;
                    led_tmp <= led_tmp << 1;
                    rst.ddr3_master <= 1'd1;
                end
            end
            STATE_END:begin
                rst.mjpeg = 1'd1;
            end
        endcase
    end
end

ddr3_master ddr3_master0(
    .clk                (clk   ),//27mhz
    .clk50m             (clk50m),
    .rst_n              (rst_n ),

    .i_cam_pclk         (cam_port.cmos_pclk     ),
    .i_cam_rgb888_pclk  (cam_user.half_cmos_clk ),
    .i_cam_vsync        (cam_user.vsync         ),
    .i_cam_de           (cam_user.de            ),
    .i_cam_data_rgb888  (cam_user.data_bgr888   ),

    .o_mjpeg_clk        (mjpeg_clk              ),
    .o_mjpeg_rst        (rst_mjpeg              ),
    .o_mjpeg_de         (mjpeg_de               ),
    .o_mjpeg_data       (mjpeg_data_in          ),
    .i_mjpeg_de         (mjpeg_de_o             ),
    .i_mjpeg_down       (mjpeg_down             ),
    .i_mjpeg_data       (mjpeg_data_out         ),

//-------module interface-----------//
    .o_udp128_en                   (i_en                 ),
    .o_udp128_ddr3_udp_wrdata      (i_ddr3_udp_wrdata    ),
    .o_udp128_udp_last_frame_flag  (i_udp_last_frame_flag),
    .o_udp128_mjpeg_frame_rank     (i_mjpeg_frame_rank   ),
    .o_udp128_udp_jpeg_len         (i_udp_jpeg_len       ),
    .o_udp128_udp_ipv4_sign        (i_udp_ipv4_sign      ),
    .i_udp128_ddr3_data_upd_req    (o_ddr3_data_upd_req  ),
    .i_udp128_udp_frame_down       (o_udp_frame_down     ),
    .i_udp128_busy                 (o_busy               ),

    .o_ddr3_cmd         (cmd            ),
    .o_ddr3_cmd_en      (cmd_en         ),
    .o_ddr3_addr        (addr           ),
    .o_ddr3_wr_data     (wr_data        ),
    .o_ddr3_wr_data_en  (wr_data_en     ),
    .o_ddr3_wr_data_end (wr_data_end    ),
    .o_ddr3_wr_mask     (wr_data_mask   ),
    .i_ddr3_clk         (clk50m         ),
    .i_ddr3_memory_clk  (memory_clk_400m),
    .i_ddr3_half_mem_clk(half_memory_clk),
    .i_ddr3_cmd_ready   (cmd_ready      ),
    .i_ddr3_wr_data_rdy (wr_data_rdy    ),
    .i_ddr3_rd_data     (rd_data        ),
    .i_ddr3_rd_data_de  (rd_data_valid  ),
    .i_ddr3_rd_data_end (rd_data_end    )
);

endmodule