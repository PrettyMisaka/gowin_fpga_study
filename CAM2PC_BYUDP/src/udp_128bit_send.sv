module udp_128bit_send(
    input       i_udp_clk50m,
    input       i_rst_n,
    input       i_en,

//-------module interface-----------//
    input [127:0]       i_ddr3_udp_wrdata       ,
    input               i_udp_last_frame_flag   ,
    input [14:0]        i_mjpeg_frame_rank      ,
    input [15:0]        i_udp_jpeg_len          ,
    // input               i_udp_writing_head      ,
    input [15:0]        i_udp_ipv4_sign         ,

    output logic        o_ddr3_data_upd_req     ,
    output logic        o_udp_frame_down        ,
    output logic        o_busy                  ,
    output logic [3:0]  o_state                 ,
    output logic [6:0]  o_req_128_rank          ,

//-------udp interface---------------//
    output logic        o_udp_tx_en      ,
    output logic        o_udp_tx_de      ,
    output logic [7:0]  o_udp_data       ,
    output logic [15:0] o_udp_data_len   ,
    output logic [15:0] o_ipv4_sign      ,
    input               i_udp_head_down  ,
    input               i_udp_busy       ,
    input               i_udp_isLoadData ,
    input               i_1Byte_pass     
);
enum logic[3:0] {
    IDLE, HEAD_DOWN, SIGN_BYTE_2, WAIT_BYTE_LOAD, WORKING, FINISH
} state;
assign o_state = state;
//------------------
//delay logic
//------------------
//------------o_ddr3_data_upd_req
logic i_udp_last_frame_buf;
logic [2:0] o_ddr3_data_upd_req_delay_buf;
logic o_ddr3_data_upd_req_delay_val;
logic [2:0] o_udp_frame_down_buf;
logic o_udp_frame_down_val;
assign o_ddr3_data_upd_req = o_ddr3_data_upd_req_delay_buf[1]|o_ddr3_data_upd_req_delay_buf[0]|o_ddr3_data_upd_req_delay_val;
assign o_udp_frame_down = o_udp_frame_down_buf[2]|o_udp_frame_down_buf[1]|
                            o_udp_frame_down_buf[0]|o_udp_frame_down_val;
//------------i_udp_head_down
logic i_udp_head_down_bef, i_udp_head_down_pos_flag;
assign i_udp_head_down_pos_flag = (~i_udp_head_down_bef)&i_udp_head_down;
always@(posedge i_udp_clk50m or negedge i_rst_n)begin
    if(~i_rst_n)begin
        o_ddr3_data_upd_req_delay_buf <= 3'd0;
        i_udp_head_down_bef           <= 1'd0;
        o_udp_frame_down_buf <= 3'd0;
    end
    else begin
        o_ddr3_data_upd_req_delay_buf <= {o_ddr3_data_upd_req_delay_buf[1:0],o_ddr3_data_upd_req_delay_val};
        i_udp_head_down_bef <= i_udp_head_down;
        o_udp_frame_down_buf <= {o_udp_frame_down_buf[1:0],o_udp_frame_down_val};
    end
end
//------------------
//
//------------------
logic [127:0] wrdata_buf;
logic [4:0] wrdata_byte_cnt;
logic [5:0] udp_data_byte_cnt;
logic [15:0] udp_jpeg_len;
logic [15:0] udp_jpeg_data_cnt;
assign o_udp_data_len = i_udp_jpeg_len + 16'd2;
assign o_ipv4_sign = i_udp_ipv4_sign;
assign o_udp_data = wrdata_buf[127:120];
logic [15:0] delay_cnt50m;
logic delay_en;
logic [31:0] delay_1s_cnt_27mhz;
logic [7:0] frame_down_req_cnt;
logic [7:0] frame_down_req_cnt_save;
task task_rst();
    state <= IDLE;
    o_udp_tx_en <= 1'd0;
    o_udp_tx_de <= 1'd0;

    wrdata_byte_cnt <= 5'd0;
    udp_jpeg_len <= 16'd0;
    udp_jpeg_data_cnt <= 16'd0;

    o_udp_tx_de <= 1'd0;
    o_ddr3_data_upd_req_delay_val <= 1'd0;
    o_busy <= 1'd0;
    o_udp_frame_down_val <= 1'd0;

    delay_cnt50m <= 0;
    delay_en <= 0;
endtask
initial task_rst();
always@(posedge i_udp_clk50m or negedge i_rst_n)begin
    if(~i_rst_n)begin
        task_rst();
    end
    else begin
        if(delay_en)begin
            if(delay_cnt50m == 16'd50) delay_cnt50m <= delay_cnt50m;
            else delay_cnt50m <= delay_cnt50m + 16'd1;
        end
        if(delay_1s_cnt_27mhz == 32'd50000000 - 32'd1 )begin
            delay_1s_cnt_27mhz <= 1'd0;
            frame_down_req_cnt          <= 1'd0;
            frame_down_req_cnt_save <= frame_down_req_cnt;
        end
        else begin
            delay_1s_cnt_27mhz <= delay_1s_cnt_27mhz + 1'd1;
        end
        case (state)
            IDLE:begin
                if(i_en)begin
                    state <= HEAD_DOWN;
                    o_udp_tx_en <= 1'd1;
                    o_busy <= 1'd1;
                    // i_udp_last_frame_buf <= i_udp_last_frame_flag;
                    delay_en <= 1'd1;
                    delay_cnt50m <= 0;
                end
                    o_udp_tx_de <= 1'd1;
                    o_ddr3_data_upd_req_delay_val <= 1'd0;
                    o_udp_frame_down_val <= 1'd0;
            end 
            HEAD_DOWN:begin
                    // wrdata_buf <= {i_udp_last_frame_flag,i_mjpeg_frame_rank,112'd0};
                if(i_udp_head_down)begin
                    wrdata_buf <= {i_udp_last_frame_flag,i_mjpeg_frame_rank,112'd0};
                    state <= SIGN_BYTE_2;
                    o_udp_tx_de <= 1'd1;
                    o_udp_tx_en <= 1'd0;
                    if(i_udp_last_frame_flag)
                        frame_down_req_cnt <= frame_down_req_cnt + 8'd1;
                end
                else begin
                    o_udp_tx_de <= 1'd1;
                    o_udp_tx_en <= 1'd1;
                end
                if(delay_cnt50m == 16'd50&&i_udp_busy == 1'd0) state <= FINISH;
                delay_en <= 1'd1;
            end
            SIGN_BYTE_2:begin
                if(i_udp_head_down && i_udp_isLoadData)begin
                    wrdata_buf <= {wrdata_buf[119:0],8'd0};
                    wrdata_byte_cnt <= 5'd0;
                    state <= WAIT_BYTE_LOAD;
                    o_ddr3_data_upd_req_delay_val <= 1'd0;
                    udp_jpeg_len <= i_udp_jpeg_len;
                    udp_jpeg_data_cnt <= 16'd0;
                end
                o_req_128_rank <= 1'd1;
            end
            WAIT_BYTE_LOAD:begin
                if(i_udp_head_down && i_udp_isLoadData)begin
                    if(wrdata_byte_cnt == 5'd0)begin
                        wrdata_buf <= i_ddr3_udp_wrdata;
                        o_ddr3_data_upd_req_delay_val <= 1'd1;
                        o_req_128_rank <= o_req_128_rank + 7'd1;
                    end
                    else begin
                        wrdata_buf <= {wrdata_buf[119:0],8'd0};
                        o_ddr3_data_upd_req_delay_val <= 1'd0;
                    end
                    if(wrdata_byte_cnt == 5'd15)begin
                        wrdata_byte_cnt <= 5'd0;
                    end
                    else begin
                        wrdata_byte_cnt <= wrdata_byte_cnt + 5'd1;
                    end
                    if(udp_jpeg_data_cnt == udp_jpeg_len - 16'd1)begin
                        state <= FINISH;
                        o_udp_frame_down_val <= 1'd1;
                    end
                    else
                        udp_jpeg_data_cnt <= udp_jpeg_data_cnt + 16'd1;
                end
                if(i_udp_busy == 1'd0)begin
                    o_busy <= 1'd0;
                    state <= IDLE;
                    o_ddr3_data_upd_req_delay_val <= 1'd0;
                end
            end
            FINISH:begin
                if(i_udp_busy == 1'd0)begin
                    o_busy <= 1'd0;
                    state <= IDLE;
                end
                o_ddr3_data_upd_req_delay_val <= 1'd0;
                delay_cnt50m <= 0;
                delay_en <= 0;
            end
        endcase
    end
end

endmodule