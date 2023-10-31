module ddr3_master_wr#(
    parameter UDP_FRAME_MAX_SIZE_128 = 7'd91//91*16
)(
    input i_pclk        ,
    input i_rst_n       ,
    
    input               i_mjpeg_busy       ,
    input               i_mjpeg_de         ,
    input               i_mjpeg_down       ,
    input [7:0]         i_mjpeg_data       ,
    
    input        [63:0]         o_dpb_wr_a_rd_data      ,
    output logic [63:0]         o_dpb_wr_a_wr_data      ,
    output logic [9:0]          o_dpb_wr_a_addr         ,
    output logic                o_dpb_wr_a_clk          ,
    output logic                o_dpb_wr_a_cea          ,
    output logic                o_dpb_wr_a_ocea         ,
    output logic                o_dpb_wr_a_rst_n        ,
    output logic                o_dpb_wr_a_wr_en        ,

    output logic        o_ddr3_master_wr_req            ,
    output logic        o_ddr3_master_wr_frame_down     ,
    output logic [1:0]  o_ddr3_master_wr_buf_rank       ,
    output logic [6:0]  o_ddr3_master_wr_buf_128cnt     ,
    output logic [5:0]  o_ddr3_master_wr_buf_Bytecnt    ,
    input               o_ddr3_master_wr_down             
);
assign o_dpb_wr_a_clk = i_pclk;
assign o_dpb_wr_a_cea  = 1'd1;
assign o_dpb_wr_a_ocea = 1'd1;
assign o_dpb_wr_a_rst_n = 1'd0;

logic [1:0] dpb_wr_rank_down, dpb_wr_rank_working;
logic [7:0] dpb_wr_addr_tmp;
assign o_ddr3_master_wr_buf_rank = dpb_wr_rank_down;
assign o_dpb_wr_a_addr = {dpb_wr_rank_working,dpb_wr_addr_tmp};

logic i_mjpeg_down_bef;
logic frame_end_state, frame_end_task_state;
always@(posedge i_pclk) i_mjpeg_down_bef <= i_mjpeg_down;

logic wr_data_tmp_updata_flag;

logic [127:0] wr_data_tmp;
logic [127:0] wr_data;
logic [7:0]   wr_data_byte_cnt;

enum logic[3:0] {
    MJPEG_WR_IDLE, MJPEG_WR_HALF1, MJPEG_WR_HALF2, MJPEG_WR_DOWN
} state_mjpeg_wr;
task taskRst();
    dpb_wr_rank_down    <= 2'd1;
    dpb_wr_rank_working <= 2'd0;
    dpb_wr_addr_tmp     <= 8'd0;
    frame_end_state     <= 1'd0;
    frame_end_task_state<= 1'd0;
    wr_data_byte_cnt    <= 8'd0;
    state_mjpeg_wr      <= MJPEG_WR_IDLE;

    o_ddr3_master_wr_req<= 1'd0;
    o_ddr3_master_wr_frame_down <= 1'd0;
    o_ddr3_master_wr_buf_128cnt     <= 7'd0;
    o_ddr3_master_wr_buf_Bytecnt    <= 6'd0;
endtask
initial taskRst();
always@(posedge i_pclk or negedge i_rst_n)begin
    if(~i_rst_n)begin
        taskRst();
    end
    else begin
        if(i_mjpeg_down_bef == 1'd1 && i_mjpeg_down== 1'd0) begin 
            frame_end_state     <= 1'd1;
            frame_end_task_state<= 1'd1;
        end
        if(i_mjpeg_busy&&i_mjpeg_de)begin
            wr_data_tmp <= {wr_data_tmp[119:0],i_mjpeg_data};
            if(wr_data_byte_cnt == 8'd15)
                wr_data_byte_cnt <= 8'd0;
            else
                wr_data_byte_cnt <= wr_data_byte_cnt + 8'd1;
            wr_data_tmp_updata_flag <= 1'd1;
        end
        else
            wr_data_tmp_updata_flag <= 1'd0;
        if(frame_end_state&&~frame_end_task_state&&state_mjpeg_wr ==MJPEG_WR_IDLE)
            frame_end_state<=1'd0;
        if(o_ddr3_master_wr_req&&o_ddr3_master_wr_down) o_ddr3_master_wr_req<=1'd0;
        // if(o_ddr3_master_wr_req) o_ddr3_master_wr_req<=1'd0;
        case(state_mjpeg_wr)
            MJPEG_WR_IDLE:begin
                if(wr_data_byte_cnt == 8'd0&&wr_data_tmp_updata_flag)begin
                    wr_data <= wr_data_tmp;
                    state_mjpeg_wr <= MJPEG_WR_HALF1;
                end
                else if(frame_end_task_state) begin
                    wr_data                 <= wr_data_tmp << ((8'd16 - wr_data_byte_cnt)<<3);
                    state_mjpeg_wr          <= MJPEG_WR_HALF1;
                    o_ddr3_master_wr_buf_Bytecnt    <= wr_data_byte_cnt;
                end
                o_ddr3_master_wr_frame_down <= 1'd0;
            end
            MJPEG_WR_HALF1:begin
                o_dpb_wr_a_wr_data  <= wr_data[127:64];
//                o_dpb_wr_a_addr     <= dpb_wr_addr_tmp;
                o_dpb_wr_a_wr_en    <= 1'd1;
                dpb_wr_addr_tmp     <= dpb_wr_addr_tmp + 8'd1;
                state_mjpeg_wr      <= MJPEG_WR_HALF2;
            end
            MJPEG_WR_HALF2:begin
                o_dpb_wr_a_wr_data  <= wr_data[63:0];
//                o_dpb_wr_a_addr     <= dpb_wr_addr_tmp;
                o_dpb_wr_a_wr_en    <= 1'd1;
                dpb_wr_addr_tmp     <= dpb_wr_addr_tmp + 8'd1;
                state_mjpeg_wr      <= MJPEG_WR_DOWN;
            end
            MJPEG_WR_DOWN:begin
                if(dpb_wr_addr_tmp[7:1] == UDP_FRAME_MAX_SIZE_128||frame_end_task_state)begin
                    dpb_wr_rank_working <= dpb_wr_rank_working + 2'd1;
                    dpb_wr_rank_down    <= dpb_wr_rank_working;
                    dpb_wr_addr_tmp     <= 8'd0;
                    wr_data_byte_cnt    <= 8'd0;

                    o_ddr3_master_wr_req        <= 1'd1;
                    o_ddr3_master_wr_buf_128cnt <= dpb_wr_addr_tmp[7:1];

                    if(frame_end_task_state)begin
                        frame_end_task_state        <= 1'd0;
                        o_ddr3_master_wr_frame_down <= 1'd1;
                    end
                end
                o_dpb_wr_a_wr_en    <= 1'd0;
                state_mjpeg_wr      <= MJPEG_WR_IDLE;
            end
        endcase
    end
end

endmodule