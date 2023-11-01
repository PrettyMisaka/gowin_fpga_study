module dpb_master_cmd(
    input i_pclk        ,
    input i_rst_n       ,
    
    input        [127:0]        o_dpb_wr_b_rd_data      ,
    output logic [127:0]        o_dpb_wr_b_wr_data      ,
    output logic [10:0]         o_dpb_wr_b_addr         ,
    output logic                o_dpb_wr_b_clk          ,
    output logic                o_dpb_wr_b_cea          ,
    output logic                o_dpb_wr_b_ocea         ,
    output logic                o_dpb_wr_b_rst_n        ,
    output logic                o_dpb_wr_b_wr_en        ,

    input               o_ddr3_master_wr_req            ,
    input               o_ddr3_master_wr_frame_down     ,
    input        [7:0]  o_ddr3_master_wr_udp_rank       ,
    input        [3:0]  o_ddr3_master_wr_buf_rank       ,
    input        [6:0]  o_ddr3_master_wr_buf_128cnt     ,
    input        [5:0]  o_ddr3_master_wr_buf_Bytecnt    ,
    output  logic       o_ddr3_master_wr_down           ,
    
//-------module interface-----------//
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
// localparam DDR3_CMD_WR = 3'd0;
// localparam DDR3_CMD_RD = 3'd1;

struct {
    logic [23:0] addr;
    logic [2:0]  bank;
    logic [5:0]  byte_cnt;
} ddr3_mjpeg_wr_info, ddr3_jpeg_rd_info;

logic               addr_rank;
logic [ 2:0]        addr_bank;
logic [23:0]        addr_row_col;
assign addr_rank = 1'b0;

assign o_dpb_wr_b_clk   = i_pclk;
assign o_dpb_wr_b_cea   = 1'd1;
assign o_dpb_wr_b_ocea  = 1'd1;
assign o_dpb_wr_b_rst_n = 1'd0;
assign o_dpb_wr_b_wr_en = 1'd0;
assign o_udp128_ddr3_udp_wrdata = o_dpb_wr_b_rd_data;

logic [6:0] dpb_wr_addr_tmp;
logic [7:0] dpb_wr_128_cnt;
assign o_dpb_wr_b_addr = {o_ddr3_master_wr_buf_rank,dpb_wr_addr_tmp};
enum logic[3:0] {
    DDR3_REQ_IDLE, 
    DDR3_HANDLE_RD_REQ_WORK, DDR3_HANDLE_RD_REQ_DOWN,
    DDR3_HANDLE_WR_REQ_WORK, DDR3_HANDLE_WR_REQ_DOWN
} state;

logic o_ddr3_master_wr_req_bef, o_ddr3_master_wr_req_state;
logic o_ddr3_master_wr_frame_down_bef, o_ddr3_master_wr_frame_down_state;
logic i_udp128_udp_frame_down_bef, i_udp128_ddr3_data_upd_req_bef;
logic [3:0] o_udp128_en_buf;
logic o_udp128_en_val;
assign o_udp128_en = o_udp128_en_buf[3]|o_udp128_en_buf[2]|o_udp128_en_buf[1]|o_udp128_en_buf[0]|o_udp128_en_val;
always@(posedge i_pclk)begin
    o_ddr3_master_wr_req_bef        <= o_ddr3_master_wr_req;
    o_ddr3_master_wr_frame_down_bef <= o_ddr3_master_wr_frame_down;
    i_udp128_udp_frame_down_bef     <= i_udp128_udp_frame_down;
    i_udp128_ddr3_data_upd_req_bef  <= i_udp128_ddr3_data_upd_req;
    o_udp128_en_buf <= {o_udp128_en_buf[2:0],o_udp128_en_val};
end

task taskRst();
    ddr3_mjpeg_wr_info.addr <= 0;
    ddr3_mjpeg_wr_info.bank <= 3'd1;
    ddr3_jpeg_rd_info.addr  <= 0;
    ddr3_jpeg_rd_info.bank  <= 3'd0;

    o_ddr3_master_wr_down       <=1'd0;
    o_ddr3_master_wr_req_state  <=  1'd0;
    
    dpb_wr_addr_tmp   <= 10'd0;
    dpb_wr_128_cnt      <= 8'd0;

    o_udp128_en_val <= 1'd0;
    o_udp128_udp_ipv4_sign <= 16'd0;

    state <= DDR3_REQ_IDLE;
endtask
initial taskRst();
always@(posedge i_pclk or negedge i_rst_n)begin
    if(~i_rst_n)begin
        taskRst();
    end
    else begin
        if((~o_ddr3_master_wr_req_bef)&&o_ddr3_master_wr_req) o_ddr3_master_wr_req_state<= 1'd1;
        if((~o_ddr3_master_wr_frame_down)&&o_ddr3_master_wr_frame_down_bef) o_ddr3_master_wr_frame_down_state<= 1'd1;
        if(o_ddr3_master_wr_frame_down_state&&state == DDR3_REQ_IDLE&&o_ddr3_master_wr_down)begin
            o_ddr3_master_wr_frame_down_state <= 1'd0;
            dpb_wr_addr_tmp   <= 7'd0;
        end
        case (state)
            DDR3_REQ_IDLE:begin
                if(o_ddr3_master_wr_req_state == 1'd1) begin
                    state <= DDR3_HANDLE_WR_REQ_WORK;
                    dpb_wr_addr_tmp   <= 7'd0;
                    o_ddr3_master_wr_req_state <= 1'd0;
                    o_udp128_mjpeg_frame_rank <= {7'd0,o_ddr3_master_wr_udp_rank};
                    o_udp128_udp_jpeg_len <= {9'd0,o_ddr3_master_wr_buf_128cnt}<<4+{10'd0,o_ddr3_master_wr_buf_Bytecnt};
                    o_udp128_en_val <= 1'd1;
                    if(o_ddr3_master_wr_frame_down_state)o_udp128_udp_last_frame_flag<=1'd1;
                    else o_ddr3_master_wr_frame_down_state <= 1'd0;
                end
                o_ddr3_master_wr_down       <=1'd0;
                state                   <= DDR3_REQ_IDLE;
            end
            DDR3_HANDLE_WR_REQ_WORK:begin
                if((~i_udp128_ddr3_data_upd_req_bef)&&i_udp128_ddr3_data_upd_req)
                    dpb_wr_addr_tmp <= dpb_wr_addr_tmp + 7'd1;
                if((~i_udp128_udp_frame_down_bef)&&i_udp128_udp_frame_down)begin
                    state <= DDR3_HANDLE_WR_REQ_DOWN;
                    o_udp128_en_val <= 1'd0;
                end
            end
            DDR3_HANDLE_WR_REQ_DOWN:begin
                dpb_wr_addr_tmp         <= 7'd0;
                o_ddr3_master_wr_down   <= 1'd1;
                state                   <= DDR3_REQ_IDLE;
            end
        endcase
    end
end

endmodule