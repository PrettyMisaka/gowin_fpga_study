module ddr3_master(
    input clk,//27mhz
    input clk50m,

    input rst_n,

    input           i_cam_rgb888_pclk      ,
    input           i_cam_vsync            ,
    input           i_cam_de               ,
    input [23:0]    i_cam_data_rgb888      ,

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

    output logic        o_ddr3_cmd         ,
    output logic        o_ddr3_cmd_en      ,
    output logic        o_ddr3_addr        ,
    output logic [127:0]o_ddr3_wr_data     ,
    output logic        o_ddr3_wr_data_en  ,
    output logic        o_ddr3_wr_data_end ,
    input               i_ddr3_clk         ,
    input               i_ddr3_memory_clk  ,
    input               i_ddr3_half_mem_clk,
    input               i_ddr3_cmd_ready   ,
    input               i_ddr3_addr        ,
    input               i_ddr3_wr_data_rdy ,
    input [127:0]       i_ddr3_rd_data     ,
    input               i_ddr3_rd_data_de  ,
    input               i_ddr3_rd_data_end 
);
//----------------------------------
//将rgb565数据输入mjpeg
//----------------------------------
logic mjpeg_busy;
enum logic [7:0] {
    MAIN_IDLE , MAIN_WORKING , MAIN_
} main_state;
always@(posedge i_cam_rgb888_pclk or negedge rst_n)begin
    if(~rst_n)begin
        mjpeg_busy  <= 0;
        o_mjpeg_rst <= 0;
        main_state  <= MAIN_IDLE;
    end
    else begin
        case(main_state)
        MAIN_IDLE:begin
        end
        
        endcase
    end
end

endmodule