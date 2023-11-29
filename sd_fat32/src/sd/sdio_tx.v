module sdio_tx(
    input   clk         ,
    input   sdio_clk    ,
    input   rst_n       ,

    input   sdio_cmd_i  ,
    output  reg sdio_cmd_o  ,
    output  reg sdio_cmd_oen,

    input           i_en    ,
    input [5:0]     i_cmd   ,
    input [31:0]    i_para  ,
    output  reg     o_busy  
);

localparam  
    IDLE = 4'd0,
    WORK = 4'd1,
    DOWN = 4'd2;

reg crc7_en,crc7_clear;

reg [3:0]   state;
reg [15:0]  bit_cnt;
reg [5:0]   cmd_buf;
reg [31:0]  para_buf;

wire [6:0]   crc7_o;
reg [6:0]   crc7_buf;

initial begin
    state   <= IDLE;
    o_busy  <= 1'd0;
    bit_cnt <= 16'd0;

    sdio_cmd_o  <= 1'd1;
    sdio_cmd_oen<= 1'd0;

    crc7_en     <= 1'd0;
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        state       <= IDLE;
        sdio_cmd_o  <= 1'd1;
        bit_cnt     <= 16'd0;
        
        crc7_en     <= 1'd0;
    end
    else begin
        case (state)
            IDLE:begin
                if(i_en && sdio_clk == 1'd1)begin
                    o_busy      <= 1'd1;
                    sdio_cmd_o  <= 1'd0;
                    bit_cnt     <= bit_cnt + 16'd1;
                    state       <= WORK;
                    cmd_buf     <= i_cmd;
                    para_buf    <= i_para;
                    crc7_en     <= 1'd1;
                end
                else begin
                    o_busy      <= 1'd0;
                    sdio_cmd_o  <= 1'd1;
                    bit_cnt     <= 16'd0;
                    state       <= IDLE;
                    crc7_en     <= 1'd0;
                end
                crc7_clear  <= 1'd0;
            end
            WORK:begin
                bit_cnt     <= bit_cnt + 16'd1;
                if(bit_cnt[15:1] <= 15'd39 && bit_cnt[0] == 1'd0)
                    crc7_en     <= 1'd1;
                else
                    crc7_en     <= 1'd0;
                if(bit_cnt[0] == 1'd0)begin
                    if(bit_cnt[15:1] == 15'd1)begin//传输标志
                        sdio_cmd_o  <= 1'd1;
                    end
                    else if(15'd1 < bit_cnt[15:1]  && bit_cnt[15:1] <= 15'd7)begin//命令
                        sdio_cmd_o  <= cmd_buf[5];
                        cmd_buf     <= {cmd_buf[4:0],1'd0};
                    end
                    else if(15'd7 < bit_cnt[15:1]  && bit_cnt[15:1] <= 15'd39)begin
                        sdio_cmd_o  <= para_buf[31];
                        para_buf    <= {para_buf[30:0],1'd0};
                    end
                    else if(bit_cnt[15:1] == 15'd40)begin
                        sdio_cmd_o  <= crc7_o[6];
                        crc7_buf    <= {crc7_o[5:0],1'd0};
                    end
                    else if(15'd40 < bit_cnt[15:1]  && bit_cnt[15:1] <= 15'd46)begin
                        sdio_cmd_o  <= crc7_buf[6];
                        crc7_buf    <= {crc7_buf[5:0],1'd0};
                        crc7_clear  <= 1'd0;
                    end
                    else if(15'd46 < bit_cnt[15:1])begin
                        sdio_cmd_o  <= 1'd1;
                        state       <= DOWN;
                        crc7_clear  <= 1'd1;
                    end
                end
            end
            DOWN:begin
                state <= IDLE;
                crc7_clear  <= 1'd0;
            end
        endcase
    end
end

CRC7 CRC70(
    .clk                (   clk             ),
    .rst_n              (   rst_n           ),
    .clear              (   crc7_clear      ),
    .idata              (   sdio_cmd_o      ),
    .en                 (   crc7_en         ), 
    .crc                (   crc7_o          )
);

endmodule

module CRC7(
    input           clk,
    input           rst_n,
    input           clear,
    input           idata,
    input           en, 
    output[6:0]     crc
);
//polynomial : x^7 + x^3 + 1

reg[6:0]    crc_reg;

assign      crc = crc_reg;
always@(posedge clk or negedge rst_n)
begin
    if( rst_n == 1'b0 )
        crc_reg <= 'd0;
    else if( en == 1'b1)        
        begin
            crc_reg[0]  <= crc_reg[6] ^ idata;
            crc_reg[1]  <= crc_reg[0];
            crc_reg[2]  <= crc_reg[1];
            crc_reg[3]  <= crc_reg[2] ^ (crc_reg[6] ^ idata);
            crc_reg[4]  <= crc_reg[3];
            crc_reg[5]  <= crc_reg[4];
            crc_reg[6]  <= crc_reg[5];
        end
    else if( clear == 1'b1)
        crc_reg <= 'd0;
    else
        crc_reg <= crc_reg;
end


endmodule