module dpb_master_top#(
    parameter MJPEG_RST_DELAY_FRAME = 6'd30,
    parameter DDR3_CMD_DELAY_MAX = 8'd32
)(
    input clk,//27mhz
    input clk50m,

    input rst_n,

    input           i_cam_pclk             ,
    input           i_cam_rgb888_pclk      ,
    input           i_cam_vsync            ,
    input           i_cam_de               ,
    input [23:0]    i_cam_data_rgb888      ,

    output logic        o_mjpeg_clk        ,
    output logic        o_mjpeg_rst        ,
    output logic        o_mjpeg_de         ,
    output logic [23:0] o_mjpeg_data       ,
    input               i_mjpeg_de         ,
    input               i_mjpeg_down       ,
    input [7:0]         i_mjpeg_data       ,

//-------module interface-----------//
    output logic               o_udp128_en                    ,
    output logic [127:0]       o_udp128_ddr3_udp_wrdata       ,
    output logic               o_udp128_udp_last_frame_flag   ,
    output logic [14:0]        o_udp128_mjpeg_frame_rank      ,
    output logic [15:0]        o_udp128_udp_jpeg_len          ,
    output logic [15:0]        o_udp128_udp_ipv4_sign         ,
    input                      i_udp128_ddr3_data_upd_req     ,
    input                      i_udp128_udp_frame_down        ,
    input                      i_udp128_busy                  ,
//----------------dpb---------------//
    input        [127:0]        o_dpb_wr_a_rd_data     ,
    output logic [127:0]        o_dpb_wr_a_wr_data     ,
    output logic [10:0]         o_dpb_wr_a_addr        ,
    output logic                o_dpb_wr_a_clk         ,
    output logic                o_dpb_wr_a_cea         ,
    output logic                o_dpb_wr_a_ocea        ,
    output logic                o_dpb_wr_a_rst_n       ,
    output logic                o_dpb_wr_a_wr_en       ,
    
    input        [127:0]        o_dpb_wr_b_rd_data     ,
    output logic [127:0]        o_dpb_wr_b_wr_data     ,
    output logic [10:0]         o_dpb_wr_b_addr        ,
    output logic                o_dpb_wr_b_clk         ,
    output logic                o_dpb_wr_b_cea         ,
    output logic                o_dpb_wr_b_ocea        ,
    output logic                o_dpb_wr_b_rst_n       ,
    output logic                o_dpb_wr_b_wr_en       ,

    output logic                o_error
);
localparam DDR3_CMD_WR = 3'd0;
localparam DDR3_CMD_RD = 3'd1;
//----------------------------------
//cam data
//----------------------------------
logic cam_vsync_bef , cam_vsync_pos_flag , cam_new_frame;
logic cam_de_bef , cam_de_pos_flag ;
assign cam_vsync_pos_flag = (~cam_vsync_bef)&(i_cam_vsync);
assign cam_de_pos_flag = (~cam_de_bef)&(i_cam_de);
always@(posedge i_cam_pclk or negedge rst_n)begin
    if(~rst_n)begin
        cam_vsync_bef <= 1'd0;
        cam_de_bef <= 1'd0;
    end
    else begin
        cam_vsync_bef <= i_cam_vsync;
        cam_de_bef <= i_cam_de;
    end
end
//----------------------------------
//mjpeg
//----------------------------------
logic mjpeg_busy , mjpeg_data_de;
logic [5:0] mjpeg_delay_cnt;
logic mjpeg_delay_down;
assign o_mjpeg_clk = i_cam_pclk;
// assign o_mjpeg_clk = i_cam_rgb888_pclk;
assign o_mjpeg_de = (i_cam_rgb888_pclk&&i_cam_de&&mjpeg_data_de)?1'd1:1'd0;
// assign o_mjpeg_de = (i_cam_de&&mjpeg_data_de)?1'd1:1'd0;
assign o_mjpeg_data = i_cam_data_rgb888;
//----------------------------------
//cam data
//----------------------------------
enum logic [7:0] {
    MAIN_IDLE_HREFPOS , MAIN_MJPEG_DOWN
} state_main;
task task_rst();
    mjpeg_busy  <= 0;
    o_mjpeg_rst <= 0;
    state_main <= MAIN_IDLE_HREFPOS;
    cam_new_frame <= 1'd0;
    o_mjpeg_rst <= 0;
    mjpeg_data_de <= 1'd0;
    mjpeg_delay_cnt <= 6'd0;
    mjpeg_delay_down <= 1'd0;
endtask
initial task_rst();
always@(posedge i_cam_pclk or negedge rst_n)begin
    if(~rst_n)begin
        task_rst();
    end
    else begin
        if(cam_vsync_pos_flag == 1'd1)begin
            cam_new_frame <= 1'd1;
            mjpeg_data_de <= 1'd0;
            // o_mjpeg_rst <= 1'd0;
            if(mjpeg_delay_down == 1'd0)begin
                if(mjpeg_delay_cnt == MJPEG_RST_DELAY_FRAME)
                    mjpeg_delay_down <= 1'd1;
                else
                    mjpeg_delay_cnt <= mjpeg_delay_cnt + 6'd1;
            end
        end
        if(mjpeg_delay_down)begin
            case(state_main)
                MAIN_IDLE_HREFPOS:begin
                    if(cam_de_pos_flag)begin
                        cam_new_frame <= 1'd0;
                        if(mjpeg_busy == 0 && cam_new_frame )begin
                            mjpeg_data_de <= 1'd1;
                            mjpeg_busy <= 1'd1;
                            o_mjpeg_rst <= 1'd1;
                            state_main <= MAIN_MJPEG_DOWN;
                        end
                    end
                end
                MAIN_MJPEG_DOWN:begin
                    if(i_mjpeg_down)begin
                        state_main <= MAIN_IDLE_HREFPOS;
                        o_mjpeg_rst <= 1'd0;
                        mjpeg_busy <= 1'd0;
                    end
                end
            endcase
        end
        else begin
            if(cam_de_pos_flag)begin
                cam_new_frame <= 1'd0;
            end
        end
    end
end
logic rst_n_delay;
assign rst_n_delay = rst_n&mjpeg_delay_down;

wire        o_ddr3_master_wr_req         ;
wire        o_ddr3_master_wr_frame_down  ;
wire [7:0]  o_ddr3_master_wr_udp_rank    ;
wire [3:0]  o_ddr3_master_wr_buf_rank    ;
wire [6:0]  o_ddr3_master_wr_buf_128cnt  ;
wire [5:0]  o_ddr3_master_wr_buf_Bytecnt ;
wire        o_ddr3_master_wr_down        ;

dpb_master_cmd dpb_master_cmd0(
    .i_pclk        (i_cam_pclk  ),
    .i_rst_n       (rst_n_delay ),
    
    .o_dpb_wr_b_rd_data      (o_dpb_wr_b_rd_data     ),
    .o_dpb_wr_b_wr_data      (o_dpb_wr_b_wr_data     ),
    .o_dpb_wr_b_addr         (o_dpb_wr_b_addr        ),
    .o_dpb_wr_b_clk          (o_dpb_wr_b_clk         ),
    .o_dpb_wr_b_cea          (o_dpb_wr_b_cea         ),
    .o_dpb_wr_b_ocea         (o_dpb_wr_b_ocea        ),
    .o_dpb_wr_b_rst_n        (o_dpb_wr_b_rst_n       ),
    .o_dpb_wr_b_wr_en        (o_dpb_wr_b_wr_en       ),

//-------module interface-----------//
    .o_udp128_en                   (o_udp128_en                 ),
    .o_udp128_ddr3_udp_wrdata      (o_udp128_ddr3_udp_wrdata    ),
    .o_udp128_udp_last_frame_flag  (o_udp128_udp_last_frame_flag),
    .o_udp128_mjpeg_frame_rank     (o_udp128_mjpeg_frame_rank   ),
    .o_udp128_udp_jpeg_len         (o_udp128_udp_jpeg_len       ),
    .o_udp128_udp_ipv4_sign        (o_udp128_udp_ipv4_sign      ),
    .i_udp128_ddr3_data_upd_req    (i_udp128_ddr3_data_upd_req  ),
    .i_udp128_udp_frame_down       (i_udp128_udp_frame_down     ),
    .i_udp128_busy                 (i_udp128_busy               ),

    .o_ddr3_master_wr_req          (o_ddr3_master_wr_req          ),
    .o_ddr3_master_wr_frame_down   (o_ddr3_master_wr_frame_down   ),
    .o_ddr3_master_wr_udp_rank     (o_ddr3_master_wr_udp_rank     ),
    .o_ddr3_master_wr_buf_rank     (o_ddr3_master_wr_buf_rank     ),
    .o_ddr3_master_wr_buf_128cnt   (o_ddr3_master_wr_buf_128cnt   ),
    .o_ddr3_master_wr_buf_Bytecnt  (o_ddr3_master_wr_buf_Bytecnt  ),
    .o_ddr3_master_wr_down         (o_ddr3_master_wr_down         )
);

dpb_master_wr dpb_master_wr0(
    .i_pclk        (i_cam_pclk  ),
    .i_rst_n       (rst_n_delay ),
    
    .i_mjpeg_busy  (mjpeg_busy  ),
    .i_mjpeg_de    (i_mjpeg_de    ),
    .i_mjpeg_down  (i_mjpeg_down  ),
    .i_mjpeg_data  (i_mjpeg_data  ),
    
    .o_dpb_wr_a_rd_data    (o_dpb_wr_a_rd_data  ),
    .o_dpb_wr_a_wr_data    (o_dpb_wr_a_wr_data  ),
    .o_dpb_wr_a_addr       (o_dpb_wr_a_addr     ),
    .o_dpb_wr_a_clk        (o_dpb_wr_a_clk      ),
    .o_dpb_wr_a_cea        (o_dpb_wr_a_cea      ),
    .o_dpb_wr_a_ocea       (o_dpb_wr_a_ocea     ),
    .o_dpb_wr_a_rst_n      (o_dpb_wr_a_rst_n    ),
    .o_dpb_wr_a_wr_en      (o_dpb_wr_a_wr_en    ),

    .o_ddr3_master_wr_req          (o_ddr3_master_wr_req          ),
    .o_ddr3_master_wr_frame_down   (o_ddr3_master_wr_frame_down   ),
    .o_ddr3_master_wr_udp_rank     (o_ddr3_master_wr_udp_rank     ),
    .o_ddr3_master_wr_buf_rank     (o_ddr3_master_wr_buf_rank     ),
    .o_ddr3_master_wr_buf_128cnt   (o_ddr3_master_wr_buf_128cnt   ),
    .o_ddr3_master_wr_buf_Bytecnt  (o_ddr3_master_wr_buf_Bytecnt  ),
    .o_ddr3_master_wr_down         (o_ddr3_master_wr_down         )  
);

endmodule