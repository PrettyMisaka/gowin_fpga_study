module ddr3_master_top#(
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
    output logic [63:0]         o_dpb_wr_a_rd_data     ,
    output logic [63:0]         o_dpb_wr_a_wr_data     ,
    output logic [9:0]          o_dpb_wr_a_addr        ,
    output logic                o_dpb_wr_a_clk         ,
    output logic                o_dpb_wr_a_cea         ,
    output logic                o_dpb_wr_a_ocea        ,
    output logic                o_dpb_wr_a_rst_n       ,
    output logic                o_dpb_wr_a_wr_en       ,
    
    output logic [63:0]         o_dpb_wr_b_rd_data     ,
    output logic [63:0]         o_dpb_wr_b_wr_data     ,
    output logic [9:0]          o_dpb_wr_b_addr        ,
    output logic                o_dpb_wr_b_clk         ,
    output logic                o_dpb_wr_b_cea         ,
    output logic                o_dpb_wr_b_ocea        ,
    output logic                o_dpb_wr_b_rst_n       ,
    output logic                o_dpb_wr_b_wr_en       ,

    output logic [63:0]         o_dpb_rd_a_rd_data     ,
    output logic [63:0]         o_dpb_rd_a_wr_data     ,
    output logic [9:0]          o_dpb_rd_a_addr        ,
    output logic                o_dpb_rd_a_clk         ,
    output logic                o_dpb_rd_a_cea         ,
    output logic                o_dpb_rd_a_ocea        ,
    output logic                o_dpb_rd_a_rst_n       ,
    output logic                o_dpb_rd_a_wr_en       ,
    
    output logic [63:0]         o_dpb_rd_b_rd_data     ,
    output logic [63:0]         o_dpb_rd_b_wr_data     ,
    output logic [9:0]          o_dpb_rd_b_addr        ,
    output logic                o_dpb_rd_b_clk         ,
    output logic                o_dpb_rd_b_cea         ,
    output logic                o_dpb_rd_b_ocea        ,
    output logic                o_dpb_rd_b_rst_n       ,
    output logic                o_dpb_rd_b_wr_en       ,

    output logic [2:0]  o_ddr3_cmd         ,
    output logic        o_ddr3_cmd_en      ,
    output logic [27:0] o_ddr3_addr        ,
    output logic [127:0]o_ddr3_wr_data     ,
    output logic        o_ddr3_wr_data_en  ,
    output logic        o_ddr3_wr_data_end ,
    output logic [15:0] o_ddr3_wr_mask     ,
    input               i_ddr3_clk         ,
    input               i_ddr3_memory_clk  ,
    input               i_ddr3_half_mem_clk,
    input               i_ddr3_cmd_ready   ,
    input               i_ddr3_wr_data_rdy ,
    input [127:0]       i_ddr3_rd_data     ,
    input               i_ddr3_rd_data_de  ,
    input               i_ddr3_rd_data_end ,

    output logic        o_ddr3_master_error
);
localparam DDR3_CMD_WR = 3'd0;
localparam DDR3_CMD_RD = 3'd1;
//----------------------------------
//addr
//----------------------------------
logic               addr_rank;
logic [ 2:0]        addr_bank;
logic [23:0]        addr_row_col;
assign addr_rank = 1'b0;
assign o_ddr3_addr = {addr_rank,addr_bank,addr_row_col};
assign o_ddr3_wr_mask = 16'd0;
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
struct {
    logic [23:0] addr;
    logic [2:0]  bank;
    logic [7:0]  byte_cnt;
} ddr3_mjpeg_wr_info, ddr3_jpeg_rd_info;
logic jpeg_rd_en, jpeg_rd_busy, jpeg_rd_err;
assign jpeg_rd_en = mjpeg_busy&1'd0;
logic [127:0] jpeg_rd_data;
logic jpeg_rd_down, jpeg_rd_req;
ddr3_master_rd ddr3_master_rd0(
    .i_pclk84m (i_cam_pclk  ),
    .i_rst_n   (rst_n_delay       ),
    
    .i_en            (jpeg_rd_en                ),
    .i_addr          (ddr3_jpeg_rd_info.addr    ),
    .i_over_byte_len (ddr3_jpeg_rd_info.byte_cnt),
    .o_busy          (jpeg_rd_busy              ),
    .o_error         (jpeg_rd_err               ),

    .i_jpeg_rd_data  (jpeg_rd_data  ),
    .i_jpeg_rd_down  (jpeg_rd_down  ),
    .o_jpeg_rd_req   (jpeg_rd_req   ),
    
    .o_udp128_en                    (o_udp128_en                    ),
    .o_udp128_ddr3_udp_wrdata       (o_udp128_ddr3_udp_wrdata       ),
    .o_udp128_udp_last_frame_flag   (o_udp128_udp_last_frame_flag   ),
    .o_udp128_mjpeg_frame_rank      (o_udp128_mjpeg_frame_rank      ),
    .o_udp128_udp_jpeg_len          (o_udp128_udp_jpeg_len          ),
    .o_udp128_udp_ipv4_sign         (o_udp128_udp_ipv4_sign         ),
    .i_udp128_ddr3_data_upd_req     (i_udp128_ddr3_data_upd_req     ),
    .i_udp128_udp_frame_down        (i_udp128_udp_frame_down        ),
    .i_udp128_busy                  (i_udp128_busy                  )
);

initial begin
    ddr3_mjpeg_wr_info.addr <= 0;
    ddr3_mjpeg_wr_info.bank <= 3'd1;
    ddr3_jpeg_rd_info.addr <= 0;
    ddr3_jpeg_rd_info.bank <= 3'd0;

    ddr3_mjpeg_wr_req_down <= 1'd0;
end
logic ddr3_jpeg_rd_req;
assign ddr3_jpeg_rd_req = jpeg_rd_req;
logic ddr3_mjpeg_wr_req_bef, ddr3_mjpeg_wr_req_pos_flag, ddr3_mjpeg_wr_req_state;
logic ddr3_jpeg_rd_req_bef, ddr3_jpeg_rd_req_pos_flag, ddr3_jpeg_rd_req_state;
logic mjped_frame_updata_state;
assign ddr3_mjpeg_wr_req_pos_flag = (~ddr3_mjpeg_wr_req_bef)&o_udp128_ddr3_udp_wrdata_req;
assign ddr3_jpeg_rd_req_pos_flag = (~ddr3_jpeg_rd_req_bef)&ddr3_jpeg_rd_req;
always@(posedge i_cam_pclk)begin
    ddr3_mjpeg_wr_req_bef <= o_udp128_ddr3_udp_wrdata_req;
    ddr3_jpeg_rd_req_bef <= ddr3_jpeg_rd_req;
end
enum logic[3:0] {
    DDR3_REQ_IDLE, 
    DDR3_HANDLE_RD_REQ, DDR3_HANDLE_RD_REQ_DOWN,
    DDR3_HANDLE_WR_REQ, DDR3_HANDLE_WR_REQ_DWON
} state_ddr3dispatch;
logic [23:0] jpeg_rd_addr_tmp;
logic ddr3_cmd_rd_send_state;
logic [7:0] ddr3_cmd_delay_cnt;
initial begin
    ddr3_cmd_rd_send_state <= 1'd0;
    o_ddr3_cmd_en <= 1'd0;
    ddr3_cmd_delay_cnt <= 8'd0;
end
always@(posedge i_cam_pclk or negedge rst_n_delay)begin
// always@(posedge i_ddr3_memory_clk or negedge rst_n_delay)begin
    if(~rst_n_delay)begin
        state_ddr3dispatch <= DDR3_REQ_IDLE;
        ddr3_mjpeg_wr_req_state <= 1'd0;
        ddr3_jpeg_rd_req_state <= 1'd0;
        mjped_frame_updata_state <= 1'd0;
        ddr3_cmd_rd_send_state <= 1'd0;
        o_ddr3_cmd_en <= 1'd0;
        jpeg_rd_addr_tmp <= 24'd0;
        ddr3_cmd_delay_cnt <= 8'd0;
    end
    else begin
        if(ddr3_cmd_delay_cnt < DDR3_CMD_DELAY_MAX)
            ddr3_cmd_delay_cnt <= ddr3_cmd_delay_cnt + 8'd1;
        if(ddr3_mjpeg_wr_req_pos_flag) ddr3_mjpeg_wr_req_state = 1'd1;
        if(ddr3_jpeg_rd_req_pos_flag) ddr3_jpeg_rd_req_state = 1'd1;
        if(mjped_frame_updata_flag) 
            mjped_frame_updata_state <= 1'd1;
        if(mjped_frame_updata_state&&state_ddr3dispatch == DDR3_REQ_IDLE) begin
            ddr3_jpeg_rd_info <= ddr3_mjpeg_wr_info;
            ddr3_mjpeg_wr_info.addr <= 0;
            ddr3_mjpeg_wr_info.bank <= ddr3_mjpeg_wr_info.bank + 3'd1;
            jpeg_rd_addr_tmp <= 24'd0;
            mjped_frame_updata_state <= 1'd0;
        end
        if(ddr3_cmd_rd_send_state == 1'd1)begin
            if(i_ddr3_rd_data_de&&i_ddr3_rd_data_end)begin
                jpeg_rd_data <= i_ddr3_rd_data;
                jpeg_rd_addr_tmp <= jpeg_rd_addr_tmp + 24'h8;
                jpeg_rd_down <= 1'd1;
                ddr3_cmd_rd_send_state <= 1'd0;
            end
        end
        case (state_ddr3dispatch)
            DDR3_REQ_IDLE: begin
                // if(i_ddr3_cmd_ready == 1'd1&&ddr3_cmd_delay_cnt == DDR3_CMD_DELAY_MAX) begin
                if(i_ddr3_cmd_ready == 1'd1) begin
                    if(ddr3_jpeg_rd_req_state == 1'd1&&ddr3_cmd_rd_send_state==1'd0) begin
                        state_ddr3dispatch <= DDR3_HANDLE_RD_REQ;
                    end
                    else if(ddr3_mjpeg_wr_req_state == 1'd1&&i_ddr3_wr_data_rdy)begin
                        state_ddr3dispatch <= DDR3_HANDLE_WR_REQ;
                    end
                end
                ddr3_mjpeg_wr_req_down <= 1'd0;
                jpeg_rd_down <= 1'd0;
                o_ddr3_cmd_en <= 1'd0;
            end
            DDR3_HANDLE_RD_REQ:begin
                o_ddr3_cmd_en <= 1'd1;
                o_ddr3_cmd <= DDR3_CMD_RD;
                addr_row_col <= jpeg_rd_addr_tmp;
                addr_bank <= ddr3_jpeg_rd_info.bank;

                jpeg_rd_down <= 1'd0;
                state_ddr3dispatch <= DDR3_HANDLE_RD_REQ_DOWN;
                ddr3_cmd_rd_send_state <= 1'd1;
                ddr3_cmd_delay_cnt <= 8'd0;
            end
            DDR3_HANDLE_RD_REQ_DOWN:begin
                o_ddr3_cmd_en <= 1'd0;
                state_ddr3dispatch <= DDR3_REQ_IDLE;
            end
            DDR3_HANDLE_WR_REQ:begin
                if(ddr3_mjpeg_wr_req_state == 1'd1&&i_ddr3_wr_data_rdy == 1'd0)begin
                    state_ddr3dispatch <= DDR3_REQ_IDLE;
                end
                else begin
                    state_ddr3dispatch <= DDR3_HANDLE_WR_REQ_DWON;
                    addr_row_col <= ddr3_mjpeg_wr_info.addr;
                    addr_bank <= ddr3_mjpeg_wr_info.bank;
                    ddr3_mjpeg_wr_req_down <= 1'd0;

                    o_ddr3_cmd_en <= 1'd1;
                    o_ddr3_cmd <= DDR3_CMD_WR;
                    o_ddr3_wr_data     <= o_udp128_ddr3_udp_wrdata0;
                    o_ddr3_wr_data_en  <= 1'd1;
                    o_ddr3_wr_data_end <= 1'd1;
                    ddr3_cmd_delay_cnt <= 8'd0;
                end
            end
            DDR3_HANDLE_WR_REQ_DWON:begin
                o_ddr3_cmd_en <= 1'd0;
                if(o_udp128_ddr3_udp_wrdata_end && o_udp128_ddr3_udp_wrdata_fullsign == 2'b10)begin
                    ddr3_mjpeg_wr_info.byte_cnt <= mjpeg_out_data_buf128_byte_cnt;
                    // ddr3_mjpeg_wr_info.addr <= ddr3_mjpeg_wr_info.addr + {16'd0,mjpeg_out_data_buf128_byte_cnt};
                end
                else
                    ddr3_mjpeg_wr_info.addr <= ddr3_mjpeg_wr_info.addr + 24'h8;
                state_ddr3dispatch <= DDR3_REQ_IDLE;
                ddr3_mjpeg_wr_req_down <= 1'd1;

                o_ddr3_wr_data     <= o_udp128_ddr3_udp_wrdata0;
                o_ddr3_wr_data_en  <= 1'd0;
                o_ddr3_wr_data_end <= 1'd0;
            end
        endcase
    end
end

endmodule