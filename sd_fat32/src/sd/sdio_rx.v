module sdio_rx(
    input   ctrl_clk    ,
    input   sdio_clk    ,
    input   rst_n       ,

    input   sdio_cmd_i  ,

    input               i_listen    ,
    input               i_rsp136en  ,
    output reg          o_de        ,
    output reg          o_crc7_down ,
    output reg [5:0]    o_cmd       ,
    output reg [31:0]   o_para      ,
    output reg [119:0]  o_cid       ,
    output reg          o_busy      
);

reg i_rsp136en_buf;
reg [6:0]   crc7_check;
reg crc7_en,crc7_clear;
wire [6:0]  crc7_o;

reg [3:0]   state;
reg [15:0]  bit_cnt;

localparam  
    IDLE    = 4'd0,
    LISTEN  = 4'd1,
    WORK    = 4'd2,
    DOWN    = 4'd3;

initial begin
    state   <= IDLE;
    o_de    <= 1'd0;
    o_cmd   <= 6'd0;
    o_para  <= 32'd0;
    o_cid   <= 120'd0;
    o_busy  <= 1'd0;
    crc7_en <= 1'd0;
    crc7_clear  <= 1'd0;
    o_crc7_down <= 1'd0;
end

always@(posedge ctrl_clk or negedge rst_n)begin
    if(~rst_n)begin
        state   <= IDLE;
        o_de    <= 1'd0;
        o_cmd   <= 6'd0;
        o_para  <= 32'd0;
        o_cid   <= 120'd0;
        o_busy  <= 1'd0;
        crc7_en <= 1'd0;
        crc7_clear <= 1'd0;
    end
    else begin
        case (state)
            IDLE:begin
                bit_cnt <= 16'd0;
                if(i_listen)begin
                    state <= LISTEN;
                end
                else begin
                    state <= IDLE;
                end
            end
            LISTEN:begin
                crc7_clear <= 1'd0;
                crc7_en     <= 1'd0;
                if(i_listen)begin
                    if(sdio_clk == 1'd0)begin
                        if(sdio_cmd_i == 1'd0 && bit_cnt == 'd0) begin
                            crc7_en     <= 1'd1;
                            bit_cnt <= bit_cnt + 16'd1;
                        end
                        else if(sdio_cmd_i == 1'd0 && bit_cnt == 'd1) begin
                            crc7_en     <= 1'd1;
                            bit_cnt <= bit_cnt+16'd1;
                            state   <= WORK;
                            o_busy  <= 1'd1;
                            i_rsp136en_buf  <= i_rsp136en;
                        end
                    end
                    else begin
                        state   <= LISTEN;
                    end
                end
                else begin
                    state   <= IDLE;
                end
                o_de    <= 1'd0;
            end
            WORK:begin
                crc7_clear <= 1'd0;
                if(bit_cnt < 'd40 && sdio_clk == 1'd0)
                    crc7_en     <= 1'd1;
                else
                    crc7_en     <= 1'd0;
                if(sdio_clk == 1'd0)begin
                    bit_cnt     <= bit_cnt + 16'd1;
                    if(bit_cnt >= 'd2 && bit_cnt < 'd8)begin
                        o_cmd <= {o_cmd[4:0],sdio_cmd_i};
                    end
                    else if(i_rsp136en_buf == 1'd0) begin
                        if(bit_cnt >= 'd8 && bit_cnt < 'd40)begin
                            o_para <= {o_para[30:0],sdio_cmd_i};
                        end
                        else if(bit_cnt >= 'd40 && bit_cnt < 'd47)begin
                            crc7_check <= {crc7_check[5:0],sdio_cmd_i};
                        end
                        else if(bit_cnt == 'd47)begin
                            if(crc7_check == crc7_o) o_crc7_down <= 1'd1;
                            else o_crc7_down <= 1'd0;
                            o_de    <= 1'd1;
                            state   <= DOWN;
                        end
                    end
                    else if(i_rsp136en_buf == 1'd1) begin
                        if(bit_cnt >= 'd8 && bit_cnt < 'd128)begin
                            o_cid <= {o_cid[118:0],sdio_cmd_i};
                        end
                        else if(bit_cnt >= 'd128 && bit_cnt < 'd135)begin
                            crc7_check <= {crc7_check[5:0],sdio_cmd_i};
                        end
                        else if(bit_cnt == 'd135)begin
                            if(crc7_check == crc7_o) o_crc7_down <= 1'd1;
                            else o_crc7_down <= 1'd0;
                            o_de    <= 1'd1;
                            state   <= DOWN;
                        end
                    end
                end
            end
            DOWN:begin
                state   <= LISTEN;
                o_busy  <= 1'd0;
                o_de    <= 1'd0;
                crc7_clear <= 1'd1;
            end
        endcase
    end
end

CRC7 CRC7_rx(
    .clk                (   ctrl_clk        ),
    .rst_n              (   rst_n           ),
    .clear              (   crc7_clear      ),
    .idata              (   sdio_cmd_i      ),
    .en                 (   crc7_en         ), 
    .crc                (   crc7_o          )
);

endmodule