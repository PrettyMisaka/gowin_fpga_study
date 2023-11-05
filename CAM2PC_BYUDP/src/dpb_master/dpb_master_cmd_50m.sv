module dpb_master_cmd_50m(
    input i_pclk        ,
    input i_50m         ,
    input i_rst_n       ,
    
    input        [127:0]        o_dpb_wr_b_rd_data      ,
    output logic [127:0]        o_dpb_wr_b_wr_data      ,
    output logic [10:0]         o_dpb_wr_b_addr         ,
    output logic                o_dpb_wr_b_clk          ,
    output logic                o_dpb_wr_b_cea          ,
    output logic                o_dpb_wr_b_ocea         ,
    output logic                o_dpb_wr_b_rst_n        ,
    output logic                o_dpb_wr_b_wr_en        ,

    // input               o_ddr3_master_wr_req            ,
    // input               o_ddr3_master_wr_frame_down     ,
    // input        [7:0]  o_ddr3_master_wr_udp_rank       ,
    input        [3:0]  o_ddr3_master_wr_buf_rank       ,
    // input        [6:0]  o_ddr3_master_wr_buf_128cnt     ,
    // input        [5:0]  o_ddr3_master_wr_buf_Bytecnt    ,
    // output  logic       o_ddr3_master_wr_down           ,
    
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
    input  [6:0]               i_udp_req_128_rank             
);
// localparam DDR3_CMD_WR = 3'd0;
// localparam DDR3_CMD_RD = 3'd1;
struct {
    logic               state                        ;
    logic               o_udp128_udp_last_frame_flag ;
    logic [14:0]        o_udp128_mjpeg_frame_rank    ;
    logic [15:0]        o_udp128_udp_jpeg_len        ;
    logic [3:0]         o_ddr3_master_wr_buf_rank_buf;
} last_frame_buf;

assign o_dpb_wr_b_wr_data = 128'd0;

logic               addr_rank;
logic [ 2:0]        addr_bank;
logic [23:0]        addr_row_col;
assign addr_rank = 1'b0;

assign o_dpb_wr_b_clk   = i_pclk;
assign o_dpb_wr_b_cea   = 1'd1;
assign o_dpb_wr_b_ocea  = 1'd1;
assign o_dpb_wr_b_rst_n = ~i_rst_n;
assign o_dpb_wr_b_wr_en = 1'd0;
assign o_udp128_ddr3_udp_wrdata = o_dpb_wr_b_rd_data;

logic [6:0] dpb_wr_addr_tmp;
logic [7:0] dpb_wr_128_cnt;
logic [3:0] o_ddr3_master_wr_buf_rank_buf;
assign o_dpb_wr_b_addr = {o_ddr3_master_wr_buf_rank_buf,dpb_wr_addr_tmp};
assign dpb_wr_addr_tmp = i_udp_req_128_rank;
localparam DDR3_REQ_IDLE = 2'd0, 
    DDR3_HANDLE_WR_REQ_WORK = 2'd1, DDR3_HANDLE_WR_REQ_DOWN = 2'd2;
logic [2:0] state;

logic o_ddr3_master_wr_req_bef, o_ddr3_master_wr_req_state;
logic o_ddr3_master_wr_frame_down_bef, o_ddr3_master_wr_frame_down_state;
logic i_udp128_udp_frame_down_bef, i_udp128_ddr3_data_upd_req_bef;
logic [15:0] o_udp128_en_buf;
logic o_udp128_en_val;
assign o_udp128_en = (o_udp128_en_buf>16'd0||o_udp128_en_val)?1'd1:1'd0;
initial begin
    o_udp128_en_buf <= 16'd0;
    {o_ddr3_master_wr_req_bef,o_ddr3_master_wr_req_state,o_ddr3_master_wr_frame_down_bef,o_ddr3_master_wr_frame_down_state}<=4'd0;
    i_udp128_udp_frame_down_bef     <= 1'd0;
    i_udp128_ddr3_data_upd_req_bef  <= 1'd0;
end
always@(posedge i_pclk)begin
    o_ddr3_master_wr_req_bef        <= o_ddr3_master_wr_req;
    o_ddr3_master_wr_frame_down_bef <= o_ddr3_master_wr_frame_down;
    i_udp128_udp_frame_down_bef     <= i_udp128_busy;
    i_udp128_ddr3_data_upd_req_bef  <= i_udp128_ddr3_data_upd_req;
    o_udp128_en_buf <= {o_udp128_en_buf[14:0],o_udp128_en_val};
end
logic [15:0] delay_cnt84m;
logic delay_en;
logic [31:0] delay_1s_cnt_27mhz;
logic [7:0] frame_down_req_cnt;
logic [7:0] frame_down_req_cnt_save;
task taskRst();
    o_ddr3_master_wr_down       <=1'd0;
    o_ddr3_master_wr_req_state  <=  1'd0;
    
    // dpb_wr_addr_tmp   <= 7'd1;
    dpb_wr_128_cnt      <= 8'd0;

    o_udp128_en_val <= 1'd0;
    o_udp128_udp_ipv4_sign <= 16'd0;

    // state <= DDR3_REQ_IDLE;
    state <= 3'd0;
    delay_en <= 1'd0;
    delay_cnt84m <= 16'd0;
    o_udp128_udp_last_frame_flag <= 1'd0;

    last_frame_buf.state <= 1'd0;
endtask
initial taskRst();
always@(posedge i_pclk or negedge i_rst_n)begin
    if(~i_rst_n)begin
        taskRst();
    end
    else begin
        // if((o_ddr3_master_wr_req_bef == 1'd0)&&o_ddr3_master_wr_req == 1'd1) o_ddr3_master_wr_req_state<= 1'd1;
        if((o_ddr3_master_wr_frame_down == 1'd1)&&o_ddr3_master_wr_frame_down_bef == 1'd0) o_ddr3_master_wr_frame_down_state<= 1'd1;
        if(o_ddr3_master_wr_frame_down_state&&(state == 3'd0)&&o_ddr3_master_wr_down)begin
            o_ddr3_master_wr_frame_down_state <= 1'd0;
            // dpb_wr_addr_tmp   <= 7'd1;
        end
        if(delay_en)begin
            if(delay_cnt84m == 16'd40) delay_cnt84m <= delay_cnt84m;
            else delay_cnt84m <= delay_cnt84m + 16'd1;
        end
        if(delay_1s_cnt_27mhz == 32'd84000000 - 32'd1 )begin
            delay_1s_cnt_27mhz <= 1'd0;
            frame_down_req_cnt          <= 1'd0;
            frame_down_req_cnt_save <= frame_down_req_cnt;
        end
        else begin
            delay_1s_cnt_27mhz <= delay_1s_cnt_27mhz + 1'd1;
        end
        if(o_ddr3_master_wr_frame_down&&o_ddr3_master_wr_req&&state!=3'd0&&(~last_frame_buf.state))begin
            last_frame_buf.state <= 1'd1;
            last_frame_buf.o_ddr3_master_wr_buf_rank_buf <=  o_ddr3_master_wr_buf_rank;
            last_frame_buf.o_udp128_udp_last_frame_flag  <=  o_ddr3_master_wr_frame_down             ;
            last_frame_buf.o_udp128_mjpeg_frame_rank     <=  {7'd0,o_ddr3_master_wr_udp_rank}        ;
            last_frame_buf.o_udp128_udp_jpeg_len         <=  ({9'd0,o_ddr3_master_wr_buf_128cnt - 7'd1}<<4)+{10'd0,o_ddr3_master_wr_buf_Bytecnt};
            frame_down_req_cnt <= frame_down_req_cnt + 8'd1;
        end
        case (state)
            3'd0:begin
                if(o_ddr3_master_wr_req == 1'd1&&(i_udp128_busy == 1'd0)) begin
                    state <= 3'd1;
                    delay_en <= 1'd1;
                    // dpb_wr_addr_tmp   <= 7'd1;
                    // o_ddr3_master_wr_req_state <= 1'd0;
                    o_udp128_mjpeg_frame_rank <= {7'd0,o_ddr3_master_wr_udp_rank};
                    o_udp128_en_val <= 1'd1;
                    // if(o_ddr3_master_wr_frame_down_state) o_udp128_udp_last_frame_flag<=1'd1;
                    // else o_ddr3_master_wr_frame_down_state <= 1'd0;
                    if(o_ddr3_master_wr_frame_down) begin
                        o_udp128_udp_last_frame_flag<=1'd1;
                        frame_down_req_cnt <= frame_down_req_cnt + 8'd1;
                        o_udp128_udp_jpeg_len <= {9'd0,o_ddr3_master_wr_buf_128cnt - 7'd1}<<4+{10'd0,o_ddr3_master_wr_buf_Bytecnt};
                    end
                    else begin
                        o_udp128_udp_last_frame_flag <= 1'd0;
                        o_udp128_udp_jpeg_len <= {9'd0,o_ddr3_master_wr_buf_128cnt}<<4+{10'd0,o_ddr3_master_wr_buf_Bytecnt};
                    end
                    o_ddr3_master_wr_buf_rank_buf <= o_ddr3_master_wr_buf_rank;
                end
                else if(last_frame_buf.state&&(i_udp128_busy == 1'd0))begin
                    state <= 3'd1;
                    delay_en <= 1'd1;
                    last_frame_buf.state <= 1'd0;
                    // dpb_wr_addr_tmp   <= 7'd1;
                    o_udp128_en_val <= 1'd1;
                    if(last_frame_buf.o_udp128_udp_last_frame_flag) o_udp128_udp_last_frame_flag<=1'd1;
                    else o_udp128_udp_last_frame_flag <= 1'd0;
                    o_udp128_mjpeg_frame_rank<=last_frame_buf.o_udp128_mjpeg_frame_rank;
                    o_udp128_udp_jpeg_len<=last_frame_buf.o_udp128_udp_jpeg_len;
                    o_ddr3_master_wr_buf_rank_buf<=last_frame_buf.o_ddr3_master_wr_buf_rank_buf;
                end
                else begin
                    delay_en <= 1'd0;
                    o_udp128_en_val <= 1'd0;
                    state                   <= 3'd0;
                end
                delay_cnt84m <= 16'd0;
                o_ddr3_master_wr_down       <=1'd0;
            end
            3'd1:begin
                // if(o_ddr3_master_wr_frame_down) o_udp128_udp_last_frame_flag<=1'd1;
                o_udp128_en_val <= 1'd0;
                // if(updata_pos)begin
                // if((i_udp128_ddr3_data_upd_req_bef == 1'd0)&&(i_udp128_ddr3_data_upd_req == 1'd1))begin
                    // dpb_wr_addr_tmp <= dpb_wr_addr_tmp + 7'd1;
//                    updata_pos <= 1'd0;
                // end
                if((delay_cnt84m == 16'd40&&~i_udp128_busy))begin
                    state <= 3'd2;
                    delay_en <= 1'd0;
                    delay_cnt84m <= 16'd0;
                end
                else begin
                    state <= 3'd1;
                end
            end
            3'd2:begin
                // dpb_wr_addr_tmp         <= 7'd1;
                o_ddr3_master_wr_down   <= 1'd1;
                state                   <= 3'd0;
                o_udp128_udp_last_frame_flag <= 1'd0;
                delay_cnt84m <= 16'd0;
                delay_en <= 1'd0;
            end
            default:begin
                state                   <= 3'd0;
            end
        endcase
    end
end

endmodule