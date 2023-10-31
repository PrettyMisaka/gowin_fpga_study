module ddr3_master_cmd(
    input i_pclk        ,
    input i_rst_n       ,
    
    input        [63:0]         o_dpb_wr_b_rd_data      ,
    output logic [63:0]         o_dpb_wr_b_wr_data      ,
    output logic [9:0]          o_dpb_wr_b_addr         ,
    output logic                o_dpb_wr_b_clk          ,
    output logic                o_dpb_wr_b_cea          ,
    output logic                o_dpb_wr_b_ocea         ,
    output logic                o_dpb_wr_b_rst_n        ,
    output logic                o_dpb_wr_b_wr_en        ,

    input               o_ddr3_master_wr_req            ,
    input               o_ddr3_master_wr_frame_down     ,
    input        [1:0]  o_ddr3_master_wr_buf_rank       ,
    input        [6:0]  o_ddr3_master_wr_buf_128cnt     ,
    input        [5:0]  o_ddr3_master_wr_buf_Bytecnt    ,
    output  logic       o_ddr3_master_wr_down           ,
    
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
localparam DDR3_CMD_WR = 3'd0;
localparam DDR3_CMD_RD = 3'd1;

struct {
    logic [23:0] addr;
    logic [2:0]  bank;
    logic [5:0]  byte_cnt;
} ddr3_mjpeg_wr_info, ddr3_jpeg_rd_info;

logic               addr_rank;
logic [ 2:0]        addr_bank;
logic [23:0]        addr_row_col;
assign addr_rank = 1'b0;
assign o_ddr3_addr = {addr_rank,addr_bank,addr_row_col};
assign o_ddr3_wr_mask = 16'd0;

assign o_dpb_wr_a_clk   = i_pclk;
assign o_dpb_wr_a_cea   = 1'd1;
assign o_dpb_wr_a_ocea  = 1'd1;
assign o_dpb_wr_a_rst_n = 1'd0;
assign o_dpb_wr_b_wr_en = 1'd0;

logic [7:0] dpb_wr_addr_tmp;
logic [10:0] dpb_wr_addr_tmpx4;
logic [7:0] dpb_wr_128_cnt;
logic dpb_wr_addr_tmp_flag;
assign dpb_wr_addr_tmp_flag = (dpb_wr_addr_tmpx4[2:0]==3'b000)?1'b1:1'b0;
assign o_dpb_wr_b_addr = {o_ddr3_master_wr_buf_rank,dpb_wr_addr_tmp};
assign dpb_wr_addr_tmp = dpb_wr_addr_tmpx4[10:3];
enum logic[3:0] {
    DDR3_REQ_IDLE, 
    DDR3_HANDLE_RD_REQ_WORK, DDR3_HANDLE_RD_REQ_DOWN,
    DDR3_HANDLE_WR_REQ_WORK, DDR3_HANDLE_WR_REQ_DOWN
} state;

logic o_ddr3_master_wr_req_bef, o_ddr3_master_wr_req_state;
logic o_ddr3_master_wr_frame_down_bef, o_ddr3_master_wr_frame_down_state;
always@(posedge i_pclk)begin
    o_ddr3_master_wr_req_bef        <= o_ddr3_master_wr_req;
    o_ddr3_master_wr_frame_down_bef <= o_ddr3_master_wr_frame_down;
end

task taskRst();
    ddr3_mjpeg_wr_info.addr <= 0;
    ddr3_mjpeg_wr_info.bank <= 3'd1;
    ddr3_jpeg_rd_info.addr  <= 0;
    ddr3_jpeg_rd_info.bank  <= 3'd0;

    o_ddr3_master_wr_down       <=1'd0;
    o_ddr3_master_wr_req_state  <=  1'd0;
    o_ddr3_cmd_en               <= 1'd0;
    
    dpb_wr_addr_tmpx4   <= 10'd0;
    dpb_wr_128_cnt      <= 8'd0;

    state <= DDR3_REQ_IDLE;
endtask
initial taskRst();
always@(posedge i_pclk or negedge i_rst_n)begin
    if(~i_rst_n)begin
        taskRst();
    end
    else begin
        if(~o_ddr3_master_wr_req_bef&&o_ddr3_master_wr_req) o_ddr3_master_wr_req_state<= 1'd1;
        if(~o_ddr3_master_wr_frame_down&&o_ddr3_master_wr_frame_down_bef) o_ddr3_master_wr_frame_down_state<= 1'd1;
        if(o_ddr3_master_wr_frame_down_state&&state == DDR3_REQ_IDLE&&o_ddr3_master_wr_down)begin
            ddr3_jpeg_rd_info <= ddr3_mjpeg_wr_info;
            ddr3_mjpeg_wr_info.addr <= 0;
            ddr3_mjpeg_wr_info.bank <= ddr3_mjpeg_wr_info.bank + 3'd1;
            o_ddr3_master_wr_frame_down_state <= 1'd0;
        end
        case (state)
            DDR3_REQ_IDLE:begin
                if(i_ddr3_cmd_ready == 1'd1) begin
//                    if(ddr3_jpeg_rd_req_state == 1'd1&&ddr3_cmd_rd_send_state==1'd0) begin
//                        state <= DDR3_HANDLE_RD_REQ_START;
//                    end
                    if(o_ddr3_master_wr_req_state == 1'd1&&i_ddr3_wr_data_rdy)begin
                        state <= DDR3_HANDLE_WR_REQ_WORK;
                        dpb_wr_addr_tmpx4   <= 10'd0;
                        o_ddr3_cmd_en       <= 1'd0;
                        o_ddr3_cmd          <= DDR3_CMD_WR;
                        o_ddr3_master_wr_req_state <= 1'd0;
                    end
                end
                else begin
                    o_ddr3_cmd_en <= 1'd0;
                end
                o_ddr3_master_wr_down       <=1'd0;
            end
            DDR3_HANDLE_WR_REQ_WORK:begin
                dpb_wr_addr_tmpx4 <= dpb_wr_addr_tmpx4 + 10'd1;
                if(dpb_wr_addr_tmp == 8'd3&&dpb_wr_addr_tmp_flag)
                    o_ddr3_cmd_en <= 1'd1;
                else
                    o_ddr3_cmd_en <= 1'd0;
                if(dpb_wr_addr_tmp >= 8'd3&&dpb_wr_addr_tmp <= {o_ddr3_master_wr_buf_128cnt,1'd0})begin
                    if(dpb_wr_addr_tmp[0] == 1'd1)begin
                        addr_bank   <= ddr3_mjpeg_wr_info.bank;
                        addr_row_col <= ddr3_mjpeg_wr_info.addr;
                        ddr3_mjpeg_wr_info.addr <= ddr3_mjpeg_wr_info.addr + 24'h8;
                        ddr3_mjpeg_wr_info.byte_cnt <= o_ddr3_master_wr_buf_Bytecnt;

                        o_ddr3_wr_data <= { o_dpb_wr_b_rd_data ,o_ddr3_wr_data[63:0]};
                        o_ddr3_wr_data_en  <= 1'd0;
                        o_ddr3_wr_data_end <= 1'd0;
                    end
                    else begin
                        if(dpb_wr_addr_tmp_flag)begin
                            o_ddr3_wr_data <= { o_ddr3_wr_data[127:64], o_dpb_wr_b_rd_data};
                            o_ddr3_wr_data_en  <= 1'd1;
                            o_ddr3_wr_data_end <= 1'd1;
                        end
                        else begin
                            o_ddr3_wr_data_en  <= 1'd0;
                            o_ddr3_wr_data_end <= 1'd0;
                        end
                    end
                    if(dpb_wr_addr_tmp == {o_ddr3_master_wr_buf_128cnt,1'd0})begin
                        state <= DDR3_HANDLE_WR_REQ_DOWN;
                    end
                end
            end
            DDR3_HANDLE_WR_REQ_DOWN:begin
                dpb_wr_addr_tmpx4         <= 8'd0;
                o_ddr3_wr_data_en       <= 1'd0;
                o_ddr3_wr_data_end      <= 1'd0;
                o_ddr3_master_wr_down   <= 1'd1;
                state                   <= DDR3_REQ_IDLE;
            end
        endcase
    end
end

endmodule