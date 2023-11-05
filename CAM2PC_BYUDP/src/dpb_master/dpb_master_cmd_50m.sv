module dpb_master_cmd_50m(
    input i_pclk        ,
    input i_clk50m         ,
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
    input  [6:0]               i_udp_req_128_rank             ,
    input  [3:0]               i_udp_state                  
);
// localparam DDR3_CMD_WR = 3'd0;
// localparam DDR3_CMD_RD = 3'd1;
struct {
    logic               state                        ;
    logic               o_udp128_udp_last_frame_flag ;
    logic [14:0]        o_udp128_mjpeg_frame_rank    ;
    logic [15:0]        o_udp128_udp_jpeg_len        ;
    logic [3:0]         o_ddr3_master_wr_buf_rank_buf;
} frame_buf;

assign o_dpb_wr_b_wr_data = 128'd0;

assign o_dpb_wr_b_clk   = i_clk50m;
assign o_dpb_wr_b_cea   = 1'd1;
assign o_dpb_wr_b_ocea  = 1'd1;
assign o_dpb_wr_b_rst_n = ~i_rst_n;
assign o_dpb_wr_b_wr_en = 1'd0;
assign o_udp128_ddr3_udp_wrdata = o_dpb_wr_b_rd_data;

logic rd_head_en;
logic [7:0] rd_delay_cnt;
logic [7:0] frame_rank_check;

logic [6:0] dpb_wr_addr_tmp;
logic [3:0] dpb_frame_tail_p;
logic [3:0] dpb_frame_head_p;
logic [3:0] dpb_frame_rank;

logic [31:0] head_sign;
logic [127:0] rd_data_bef;

assign dpb_frame_tail_p = o_ddr3_master_wr_buf_rank;
assign o_dpb_wr_b_addr = {dpb_frame_head_p,dpb_wr_addr_tmp};
assign dpb_wr_addr_tmp = (rd_head_en==1'd1)?7'd0:i_udp_req_128_rank;
enum logic[2:0] {  
    IDLE, HEAD_RD, FRAME_DOWN, SEND_AGAIN, FINISH
} state;

task taskRst();
    o_udp128_udp_ipv4_sign <= 16'd0;
    state <= IDLE;
    dpb_frame_head_p <= 4'd0;
    rd_head_en <= 1'd0;
    rd_delay_cnt <= 8'd0;
    o_udp128_en <= 1'd0;
    head_sign <= 32'd0;
    frame_rank_check <= 8'hff;
endtask
initial taskRst();
always@(posedge i_clk50m or negedge i_rst_n)begin
    if(~i_rst_n)begin
        taskRst();
    end
    else begin
        case(state)
        IDLE:begin
            // rd_data_bef <= o_dpb_wr_b_rd_data;
            // if(o_dpb_wr_b_rd_data[31:0] == head_sign&&(o_dpb_wr_b_rd_data[119:112]==8'd0||o_dpb_wr_b_rd_data[119:112] == frame_rank_check||frame_rank_check==8'hff))begin
            if(o_dpb_wr_b_rd_data[31:0] == head_sign&&~i_udp128_busy)begin
                head_sign <= head_sign + 32'd1;
                state <= HEAD_RD;
                frame_rank_check <= o_dpb_wr_b_rd_data[119:112] + 8'd1;
            end
            else begin
                state <= IDLE;
            end
            rd_head_en <= 1'd1;
            rd_delay_cnt <= 8'd0;
            o_udp128_en <= 1'd0;
        end
        HEAD_RD:begin
            if(rd_delay_cnt == 8'd0)begin
                o_udp128_udp_last_frame_flag <= o_dpb_wr_b_rd_data[127];
                o_udp128_mjpeg_frame_rank <= o_dpb_wr_b_rd_data[126:112];
                if(o_dpb_wr_b_rd_data[127])
                    o_udp128_udp_jpeg_len <=({8'd0,o_dpb_wr_b_rd_data[112:104] - 8'd1}<<4)+{8'd0,o_dpb_wr_b_rd_data[103:96]};
                else
                    o_udp128_udp_jpeg_len <=({8'd0,o_dpb_wr_b_rd_data[112:104]}<<4)+{8'd0,o_dpb_wr_b_rd_data[103:96]};
                // o_udp128_en <= 1'd1;
                o_udp128_udp_ipv4_sign <= o_udp128_udp_ipv4_sign + 16'd2;
            end
            if(rd_delay_cnt == 8'd2)begin
                rd_head_en <= 1'd0;
                state <= FRAME_DOWN;
                rd_delay_cnt <= 8'd0;
                o_udp128_en <= 1'd1;
            end
            else begin
                rd_delay_cnt <= rd_delay_cnt + 8'd1;
            end
        end
        FRAME_DOWN:begin
            if(i_udp_state == 4'd3)
                o_udp128_en <= 1'd0;
            if(~i_udp128_busy)begin
                dpb_frame_head_p <= dpb_frame_head_p + 4'd1;
                rd_head_en <= 1'd1;
                state <= IDLE;
            end
            else begin
                rd_head_en <= 1'd0;
            end
            rd_head_en <= 1'd0;
        end
        endcase
    end
end

endmodule