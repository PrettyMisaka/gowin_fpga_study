module ddr3_master(
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

    output              o_udp_tx_en        ,
    output              o_udp_tx_de        ,
    output [7:0]        o_udp_data         ,
    output [15:0]       o_udp_datalen      ,
    output [15:0]       o_ipv4_sign        ,
    input               i_udp_tx_clk       ,
    input               i_udp_busy         ,
    input               i_udp_isLoadData   ,
    input               i_udp_1Byte_pass   ,

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
    input               i_ddr3_rd_data_end 
);
//----------------------------------
//addr
//----------------------------------
logic               addr_rank;
logic [ 2:0]        addr_bank;
logic [13:0]        addr_row;
logic [ 9:0]        addr_col;
assign addr_rank = 1'b0;
assign o_ddr3_addr = {addr_rank,addr_bank,addr_row,addr_col};
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
assign o_mjpeg_clk = i_cam_pclk;
assign o_mjpeg_de = (i_cam_rgb888_pclk&&i_cam_de&&mjpeg_data_de)?1'd1:1'd0;
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
endtask
always@(posedge i_cam_pclk or negedge rst_n)begin
    if(~rst_n)begin
        task_rst();
    end
    else begin
        if(cam_vsync_pos_flag == 1'd1)begin
            cam_new_frame <= 1'd1;
            mjpeg_data_de <= 1'd0;
            // o_mjpeg_rst <= 1'd0;
        end
        case(state_main)
            MAIN_IDLE_HREFPOS:begin
                if(cam_de_pos_flag)begin
                    cam_new_frame <= 1'd0;
                    if(mjpeg_busy == 0 && cam_new_frame)begin
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
end

logic [127:0] mjpeg_out_data_buf;
logic [6:0] ddr3_in_wrdata_cnt;
initial begin
    mjpeg_out_data_buf <= 0;
    ddr3_in_wrdata_cnt <= 0;
end
always@(posedge i_cam_pclk or negedge rst_n)begin
    if(~rst_n)begin
        mjpeg_out_data_buf <= 0;
        ddr3_in_wrdata_cnt <= 0;
    end
    else begin
        if(mjpeg_busy)begin
            if(i_mjpeg_de)begin
                mjpeg_out_data_buf <= {mjpeg_out_data_buf[119:0],i_mjpeg_data};
                ddr3_in_wrdata_cnt <= ddr3_in_wrdata_cnt + 7'd1;
            end
        end
        else begin
            mjpeg_out_data_buf <= 0;
            ddr3_in_wrdata_cnt <= 0;
        end
    end
end

endmodule