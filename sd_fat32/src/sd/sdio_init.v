module sdio_init(
    input ctrl_clk    ,
    input sdio_clk    ,
    input rst_n       ,

    output reg          o_tx_en     ,
    output wire [5:0]   o_tx_cmd    ,
    output wire [31:0]  o_tx_para   ,
    input               i_tx_busy   ,  

    output reg          o_rx_listen     ,
    output reg          o_rx_rsp136en   ,
    input               i_rx_de         ,
    input               i_rx_crc7_down  ,
    input      [5:0]    i_rx_cmd        ,
    input      [31:0]   i_rx_para       ,
    input      [119:0]  i_rx_cid        ,
    input               i_rx_busy       ,

    output reg          init_down       
);
initial begin
    o_tx_en         <= 'd0;
    o_rx_listen     <= 'd0;
    o_rx_rsp136en   <= 'd0;

    init_down       <= 'd0;
end

reg [37:0] cmd_para_reg;
assign o_tx_cmd = cmd_para_reg[37:32];
assign o_tx_para = cmd_para_reg[31:0];

reg [7:0] state;
reg [31:0] delay_cnt;

reg rsq_state;

localparam 
    INIT_IDLE           = 8'd0,
    INIT_DELAY10MS      = 8'd1,//等待10ms
    INIT_CMD0           = 8'd2,//初始化命令 同时保持 sddat3 信号为高电平
    INIT_CMD8           = 8'd3,//鉴别 SD1.X 和 SD2.0
    INIT_ACMD41         = 8'd4,//区分出卡的三种类型：SD 1.X卡、SD 2.0 非大容量卡、SDHC 2.0 大容量卡
    INIT_CMD2           = 8'd5,//获取CID寄存器
    INIT_CMD3           = 8'd6,//要求card指定一个RCA
    INIT_CMD7           = 8'd7,//选中卡 
    INIT_CMD16          = 8'd8,//设置 block length 一般512B
    INIT_DOWN           = 8'd9;

initial begin
    state       <= INIT_IDLE;
    rsq_state   <= 'd0;
end

always@(posedge ctrl_clk or negedge rst_n)begin
    if(~rst_n)begin
        state       <= INIT_IDLE;
        init_down   <= 1'd0;
        o_rx_listen <= 'd0;
        o_rx_rsp136en   <= 'd0;
        rsq_state   <= 'd0;
    end
    else begin
        if(i_rx_de) rsq_state   <= 'd1;
        case(state)
            INIT_IDLE:begin
                state       <= INIT_DELAY10MS;
                delay_cnt   <= 'd0;
                o_tx_en     <= 'd0;
                init_down   <= 1'd0;
            end
            INIT_DELAY10MS:begin
                // if(delay_cnt == 'd4000)begin
                if(delay_cnt == 'd10)begin
                    delay_cnt   <= 'd0;
                    state       <= INIT_CMD0;

                    cmd_para_reg<= {6'd0,32'd0};
                    o_tx_en     <= 'd1;
                end
                else begin
                    delay_cnt   <= delay_cnt + 'd1;
                    state       <= INIT_DELAY10MS;
                end
            end
            INIT_CMD0:begin
                if(delay_cnt == 'd10)begin
                    if(i_tx_busy == 1'd0) begin
                        delay_cnt   <= 'd0;
                        state       <= INIT_CMD8;

                        cmd_para_reg<= {6'd8,32'h000001AA};
                        o_tx_en     <= 'd1;
                        o_rx_listen <= 'd0;
                    end
                    else begin
                        delay_cnt   <= delay_cnt;
                        state       <= INIT_CMD0;
                    end
                end
                else begin
                    delay_cnt   <= delay_cnt + 'd1;
                    state       <= INIT_CMD0;
                    o_tx_en     <= 'd0;
                end
            end
            INIT_CMD8:begin
                if(rsq_state)begin
                    state       <= INIT_ACMD41;
                    delay_cnt   <= 'd0;
                    o_rx_listen <= 'd0;
                end
                else begin
                    if(delay_cnt == 'd10)begin
                        if(i_tx_busy == 1'd0) begin
                            delay_cnt   <= delay_cnt + 'd1;

                            o_rx_listen <= 'd1;
                            o_rx_rsp136en   <= 'd0;
                        end
                        else begin
                            delay_cnt   <= delay_cnt;
                        end
                        state       <= INIT_CMD8;
                    end
                    else if(delay_cnt == 'd100)begin
                        state       <= INIT_ACMD41;
                        delay_cnt   <= 'd0;
                        o_rx_listen <= 'd0;
                    end
                    else begin
                        delay_cnt   <= delay_cnt + 'd1;
                        state       <= INIT_CMD8;
                        o_tx_en     <= 'd0;
                    end
                end
            end
        endcase
    end
end



endmodule