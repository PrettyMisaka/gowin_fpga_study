module ddr3_master_rd#(
    parameter UDP_FRAME_MAX_SIZE_B = 25'd1456//91*16
    )(
    input i_pclk84m ,
    input i_rst_n   ,

    input           i_en            ,
    input [23:0]    i_addr          ,
    input [7:0]     i_over_byte_len ,
    output logic    o_busy          ,
    output logic    o_error         ,

    input [127:0]   i_jpeg_rd_data  ,
    input           i_jpeg_rd_down  ,
    output logic    o_jpeg_rd_req   ,

//-------udp interface-----------//
    output logic               o_udp128_en                    ,
    output logic [127:0]       o_udp128_ddr3_udp_wrdata       ,
    output logic               o_udp128_udp_last_frame_flag   ,
    output logic [14:0]        o_udp128_mjpeg_frame_rank      ,
    output logic [15:0]        o_udp128_udp_jpeg_len          ,
    output logic [15:0]        o_udp128_udp_ipv4_sign         ,
    input                      i_udp128_ddr3_data_upd_req     ,
    input                      i_udp128_udp_frame_down        ,
    input                      i_udp128_busy                  
);
//---------------------------------//
logic i_en_bef, i_en_pos_flag;
assign i_en_pos_flag = (~i_en_bef)&i_en;
always@(i_pclk84m) i_en_bef <= i_en;
logic i_udp_busy_bef, i_udp_busy_neg_flag;
assign i_udp_busy_neg_flag = (~i_udp128_busy)&i_udp_busy_bef;
always@(i_pclk84m) i_udp_busy_bef <= i_udp128_busy;
//---------------------------------//
logic [24:0] jpeg_total_size_Byte;

logic [127:0] jpeg_rd_data0;
assign o_udp128_ddr3_udp_wrdata = jpeg_rd_data0;
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
    o_udp128_udp_ipv4_sign <= 15'd0;
end
always@(posedge i_pclk84m or negedge i_rst_n)begin
    if(~i_rst_n)begin
        state <= IDLE;
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
                jpeg_frame_end <= 1'd0;
                o_udp128_udp_last_frame_flag <= 1'd0;
                o_udp128_mjpeg_frame_rank <= 15'd0;
            end
            UDP_LOAD:begin
                o_udp128_en <= 1'd1;
                if(jpeg_total_size_Byte > UDP_FRAME_MAX_SIZE_B)begin
                    o_udp128_udp_jpeg_len <= UDP_FRAME_MAX_SIZE_B[15:0];
                    jpeg_total_size_Byte <= jpeg_total_size_Byte - UDP_FRAME_MAX_SIZE_B;
                    state <= DATA_TRANSFER;
                    o_udp128_udp_last_frame_flag <= 1'd0;
                end
                else begin
                    o_udp128_udp_jpeg_len <= jpeg_total_size_Byte;
                    state <= FINISH;
                    o_udp128_udp_last_frame_flag <= 1'd1;
                end
                o_udp128_mjpeg_frame_rank <= o_udp128_mjpeg_frame_rank + 15'd1;
                o_udp128_udp_ipv4_sign <= o_udp128_udp_ipv4_sign + 16'd1;
            end
            DATA_TRANSFER:begin
                o_udp128_en <= 1'd0;
                if(i_udp_busy_neg_flag) state <= UDP_LOAD;
            end
            FINISH:begin
                o_udp128_en <= 1'd0;
                if(i_udp_busy_neg_flag) state <= IDLE;
            end
        endcase
    end
end

logic jpeg_rd_frame_end;
logic o_jpeg_rd_req_val, o_jpeg_rd_req_bef, o_jpeg_rd_req_pos, o_jpeg_rd_req_ctrl;
assign o_jpeg_rd_req = o_jpeg_rd_req_pos;
assign o_jpeg_rd_req_pos = (~o_jpeg_rd_req_bef)&o_jpeg_rd_req_val;
assign o_jpeg_rd_req_ctrl = o_jpeg_rd_req_val&(~jpeg_rd_frame_end);
always@(i_pclk84m) o_jpeg_rd_req_bef <= o_jpeg_rd_req_val;

logic i_udp128_ddr3_data_upd_req_bef, i_udp128_ddr3_data_upd_req_neg, i_udp128_ddr3_data_upd_req_neg_state;
assign i_udp128_ddr3_data_upd_req_neg = (~i_udp128_ddr3_data_upd_req)&i_udp128_ddr3_data_upd_req_bef;
always@(i_pclk84m) i_udp128_ddr3_data_upd_req_bef <= i_udp128_ddr3_data_upd_req;

logic [24:0] jpeg_total_size_Byte_tmp;
always@(posedge i_pclk84m or negedge i_rst_n)begin
    if(~i_rst_n)begin
        jpeg_total_size_Byte_tmp <= 0;
        jpeg_rd_dataBuf_state <= 2'd0;
        o_jpeg_rd_req_val <= 1'd0;
        o_error <= 1'd0;
    end
    else begin
        if(i_udp128_ddr3_data_upd_req_neg) i_udp128_ddr3_data_upd_req_neg_state<=1'd1;
        if(state == IDLE)begin
            jpeg_total_size_Byte_tmp <= jpeg_total_size_Byte;
            jpeg_rd_dataBuf_state <= 2'd0;
            o_jpeg_rd_req_val <= 1'd0;
            i_udp128_ddr3_data_upd_req_neg_state<=1'd0;
            jpeg_rd_frame_end <= 1'd0;
        end
        else if(state == UDP_LOAD||state == DATA_TRANSFER||state == FINISH)begin
            if(o_jpeg_rd_req_val == 1'd0)begin
                if(i_udp128_ddr3_data_upd_req_neg_state)begin
                    case(jpeg_rd_dataBuf_state)
                        2'b00:begin
                            o_jpeg_rd_req_val <= 1'd1;
                        end
                        2'b10:begin
                            o_jpeg_rd_req_val <= 1'd1;
                            jpeg_rd_dataBuf_state <= 2'b00;
                        end
                        2'b11:begin
                            jpeg_rd_data0 <= jpeg_rd_data1;
                            o_jpeg_rd_req_val <= 1'd1;
                        end
                        default:
                            o_error<=1'd1;
                    endcase
                    i_udp128_ddr3_data_upd_req_neg_state <= 1'd0;
                end
                else begin
                    case(jpeg_rd_dataBuf_state)
                        2'b00:begin
                            o_jpeg_rd_req_val = 1'd1;
                        end
                        2'b10:begin
                            o_jpeg_rd_req_val = 1'd1;
                        end
                        2'b11:begin
                            o_jpeg_rd_req_val = 1'd0;
                        end
                        default:
                            o_error<=1'd1;
                    endcase
                end
            end
            if(o_jpeg_rd_req_ctrl == 1'd1 && i_jpeg_rd_down)begin
                if(jpeg_total_size_Byte_tmp >= 25'd16)
                    jpeg_total_size_Byte_tmp <= jpeg_total_size_Byte_tmp - 25'd16;
                else begin
                    jpeg_rd_frame_end <= 1'd1;
                end
                o_jpeg_rd_req_val <= 1'd0;
                case(jpeg_rd_dataBuf_state)
                    2'b00:begin
                        jpeg_rd_data0 <= i_jpeg_rd_data;
                        jpeg_rd_dataBuf_state <= 2'b10;
                    end
                    2'b10:begin
                        jpeg_rd_data1 <= i_jpeg_rd_data;
                        jpeg_rd_dataBuf_state <= 2'b11;
                    end
                    default:
                        o_error<=1'd1;
                endcase
            end
        end
    end
end
endmodule