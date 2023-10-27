module ddr3_master_rd#(
    parameter UDP_FRAME_MAX_SIZE_B = 25'd1456
    )(
    input i_pclk84m,
    input i_rst_n,

    input           i_en,
    input [23:0]    i_addr,
    input [7:0]     i_over_byte_len,
    output logic    o_busy,

    input [127:0]   i_jpeg_rd_data,
    input           i_jpeg_rd_down,
    output logic    o_jpeg_rd_req,

//-------udp interface-----------//
    output logic               o_udp128_en                    ,
    output logic [127:0]       o_udp128_ddr3_udp_wrdata       ,
    output logic               o_udp128_udp_last_frame_flag   ,
    output logic [14:0]        o_udp128_mjpeg_frame_rank      ,
    output logic [15:0]        o_udp128_udp_jpeg_len          ,
    output logic [15:0]        o_udp128_udp_ipv4_sign         ,
    input                      i_udp128_ddr3_data_upd_req     ,
    input                      i_udp128_udp_frame_down        ,
    input                      i_udp128_busy                  ,
);
//---------------------------------//
logic i_en_bef, i_en_pos_flag;
assign i_en_pos_flag = (~i_en_bef)&i_en;
always@(i_pclk84m) i_en_bef <= i_en;
//---------------------------------//
logic [24:0] jpeg_total_size_Byte;

logic [127:0] jpeg_rd_data0;
logic [127:0] jpeg_rd_data1;
logic [1:0] jpeg_rd_dataBuf_state;

logic jpeg_frame_end;
enum logic[3:0] {
    IDLE, UDP_LOAD, DATA_TRANSFER, FINISH
} state;
initial begin
    state <= IDLE;
    jpeg_rd_dataBuf_state <= 2'd0;
    jpeg_frame_end <= 1'd0;
end
always@(posedge i_pclk84m or negedge i_rst_n)begin
    if(~i_rst_n)begin
        state <= IDLE;
        jpeg_rd_dataBuf_state <= 2'd0;
        jpeg_frame_end <= 1'd0;
    end
    else begin
        case (state)
            IDLE: begin
                if(i_en_pos_flag)begin
                    state <= UDP_LOAD;
                    jpeg_total_size_Byte <= {jpeg_total_size_Byte<<1} + {17'd0,i_over_byte_len}; 
                end
                o_udp128_en <= 1'd0;
                jpeg_rd_dataBuf_state <= 2'd0;
                jpeg_frame_end <= 1'd0;
            end
            UDP_LOAD:begin
                o_udp128_en <= 1'd1;
                if(jpeg_total_size_Byte > UDP_FRAME_MAX_SIZE_B)begin
                    o_udp128_udp_jpeg_len <= 16'd1456;
                    jpeg_total_size_Byte <= jpeg_total_size_Byte - UDP_FRAME_MAX_SIZE_B;
                end
                else begin
                    o_udp128_udp_jpeg_len <= jpeg_total_size_Byte;
                end
            end
        endcase
    end
end

endmodule