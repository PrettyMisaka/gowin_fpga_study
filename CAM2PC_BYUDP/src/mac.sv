module mac#(
    parameter bit [31:0] src_ip_adr = 32'd0,
    parameter bit [31:0] dst_ip_adr = 32'd0,
    parameter bit [15:0] udp_my_port = 16'd0,
    parameter bit [15:0] udp_port = 16'd0,
    parameter bit [47:0] mac_adr = 48'd0,
    parameter bit [47:0] mac_my_adr = 48'd0
)(
    input I_clk50m,
    input I_rst,
    input I_en,
    input I_de,//此时I_data数据线上的数据是否有效
    input [7:0]  I_data,
    input [15:0] I_dataLen,
    input [15:0] I_ipv4sign,
    
    output logic O_head_down,
    output logic [1:0] O_txd,
    output logic O_txen,
    output logic O_busy,
    output logic O_isLoadData,
    output logic O_1Byte_pass
);

typedef enum logic [7:0] { 
    MAC_IDLE, MAC_SYNC, MAC_FRAME, MAC_ADR, MAC_MYADR, MAC_LEN,
    MAC_IPV4_VHS, MAC_IPV4_TOTALLEN, MAC_IPV4_SIGN, MAC_IPV4_4BYTE,
    MAC_IPV4_CHECKSUM, MAC_IPV4_SRCIP, MAC_IPV4_DSTIP,
    MAC_UDP_PORT, MAC_UDP_LENCRC, MAC_UDP_DATA,
    MAC_CRC, MAC_END
} state_typedef;
state_typedef state;

logic last_bit_flag;
logic last_o_txen_state;
assign O_1Byte_pass = last_bit_flag;
assign O_head_down = (state == MAC_UDP_DATA || state == MAC_CRC || state == MAC_END )?1'd1:1'd0;
    
 logic [15:0] byte_cnt;
 logic [7:0] bit_cnt;
 logic [7:0] buffer_data;
 logic isSaveFlag;
 logic tx_en;
 logic [47:0] mac_adr_buf;

 logic [15:0] total_len;
 logic [15:0] I_udpLen;
 assign total_len = I_udpLen + 16'd20;
 assign I_udpLen = I_dataLen + 16'd8;

/*********** crc logic************/
 logic [31:0] crc_data_buf;
 logic crc_en, crc_rst;
 logic [31:0] crc_out;
 logic crc_forcr_en;

/*************** checksum ****************/
 logic [17:0] checksum;
 logic [15:0] checksum_16b;

 task variableRST();
    state <= MAC_IDLE;
    O_busy <= 0;
    byte_cnt <= 0;
    buffer_data <= 0;
    bit_cnt <= 0;
    mac_adr_buf <= 0;
    tx_en <= 0;
    O_txen<= 0;
    last_o_txen_state <= 0;

    crc_rst <= 0;
    crc_forcr_en <= 0;
 endtask

 initial begin
    variableRST();
    crc_data_buf <= 0;
    crc_en <= 0;
 end

 task bufPush(
    input state_typedef target_state,
    input [47:0] buf_val,
    input [15:0] target_cnt
 );
    buffer_data <= mac_adr_buf[7:0];
    if(isSaveFlag == 1'd1)begin
        if(byte_cnt == target_cnt - 16'd1)begin
            byte_cnt <= 0;
            state <= target_state;
            mac_adr_buf <= buf_val;
        end
        else begin
            mac_adr_buf <= mac_adr_buf >> 8;
            byte_cnt <= byte_cnt + 16'd1;
        end
    end
    // if(byte_cnt == 16'd2&&state == ) tx_en <= 0;
 endtask

assign O_isLoadData = (state == MAC_UDP_DATA)?isSaveFlag:1'd0;

always_ff@(posedge I_clk50m or negedge I_rst)begin
    if(!I_rst)begin
        variableRST();
    end
    else begin
        case(state)
        MAC_IDLE:begin
            if(I_en)begin
                O_busy <= 1;
                state <= MAC_SYNC;
            end
            else begin
                variableRST();
            end
        end
        MAC_SYNC:begin
            O_txen <= tx_en;
            tx_en <= 1;
            buffer_data <= 8'b01010101;
            if(isSaveFlag == 1'd1)begin
                if(byte_cnt == 16'd6)begin
                    byte_cnt <= 0;
                    state <= MAC_FRAME;
                end
                else begin
                    byte_cnt <= byte_cnt + 16'd1;
                    state <= MAC_SYNC;
                end
            end
            last_o_txen_state <= O_txen;
        end
        MAC_FRAME:begin
            tx_en <= 1;
            buffer_data <= 8'b11010101;
            if(isSaveFlag == 1'd1)begin
                crc_rst <= 1;
                state <= MAC_ADR;
                mac_adr_buf <= {mac_my_adr[7:0],  mac_my_adr[15:8], mac_my_adr[23:16],
                                    mac_my_adr[31:24],mac_my_adr[39:32],mac_my_adr[47:40]};
            end
            else begin
                state <= MAC_FRAME;
            end
        end
        MAC_ADR:begin
            bufPush(
                .target_state(MAC_MYADR),
                .target_cnt(16'd6),
                .buf_val({mac_adr[7:0],  mac_adr[15:8], mac_adr[23:16],
                                mac_adr[31:24],mac_adr[39:32],mac_adr[47:40]})
            );
            // tx_en <= 1;
            // buffer_data <= mac_adr_buf[8:0];
            // if(isSaveFlag == 1'd1)begin
            //     if(byte_cnt == 16'd5)begin
            //         byte_cnt <= 0;
            //         state <= MAC_MYADR;
            //         mac_adr_buf <= {mac_my_adr[7:0],  mac_my_adr[15:8], mac_my_adr[23:16],
            //                         mac_my_adr[31:24],mac_my_adr[39:32],mac_my_adr[47:40]};
            //     end
            //     else begin
            //         mac_adr_buf <= mac_adr_buf >> 8;
            //         byte_cnt <= byte_cnt + 16'd1;
            //         state <= MAC_ADR;
            //     end
            // end
        end
        MAC_MYADR:begin
            bufPush(
                .target_state(MAC_LEN),
                .target_cnt(16'd6),
                .buf_val({32'h0,8'h00,8'h08})
            );
            // tx_en <= 1;
            // buffer_data <= mac_adr_buf[8:0];
            // if(isSaveFlag == 1'd1)begin
            //     if(byte_cnt == 16'd5)begin
            //         byte_cnt <= 0;
            //         state <= MAC_LEN;
            //         mac_adr_buf <= {32'h0,8'h00,8'h08};
            //     end
            //     else begin
            //         mac_adr_buf <= mac_adr_buf >> 8;
            //         byte_cnt <= byte_cnt + 16'd1;
            //         state <= MAC_MYADR;
            //     end
            // end
        end
        MAC_LEN:begin
            bufPush(
                .target_state(MAC_IPV4_VHS),
                .target_cnt(16'd2),
                .buf_val({16'h00,16'h00,8'h00,8'h45})
            );
            // tx_en <= 1;
            // buffer_data <= mac_adr_buf[8:0];
            // if(isSaveFlag == 1'd1)begin
            //     if(byte_cnt == 16'd2 - 16'd1)begin
            //         byte_cnt <= 0;
            //         state <= MAC_UDP_PORT;
            //         mac_adr_buf <= {16'h00,udp_port[15:8],udp_port[7:0],
            //                             udp_my_port[15:8],udp_my_port[7:0]};
            //     end
            //     else begin
            //         mac_adr_buf <= mac_adr_buf >> 8;
            //         byte_cnt <= byte_cnt + 16'd1;
            //         state <= MAC_LEN;
            //     end
            // end
        end
        MAC_IPV4_VHS:begin
            bufPush(
                .target_state(MAC_IPV4_TOTALLEN),
                .target_cnt(16'd2),
                .buf_val({16'h00,16'h00,total_len[7:0],total_len[15:8]})
            );
            checksum <= 18'h4500 + 18'h8011/*4011 4000*/ + {2'd0,total_len} + {2'd0,I_ipv4sign} + {2'd0,src_ip_adr[31:16]+src_ip_adr[15:0]} + {2'd0,dst_ip_adr[31:16]+dst_ip_adr[15:0]};
        end
        MAC_IPV4_TOTALLEN:begin
            bufPush(
                .target_state(MAC_IPV4_SIGN),
                .target_cnt(16'd2),
                .buf_val({16'h00,16'h00,I_ipv4sign[7:0],I_ipv4sign[15:8]})
            );
            if(checksum[17:16] != 2'd0)begin
                checksum <= {2'd0,checksum[15:0]+{14'd0,checksum[17:16]}};
            end
        end
        MAC_IPV4_SIGN:begin
            bufPush(
                .target_state(MAC_IPV4_4BYTE),
                .target_cnt(16'd2),
                .buf_val({16'h00,16'h1140,8'h00,8'h40})
            );
            checksum_16b <= 16'hffff - checksum[15:0];
        end
        MAC_IPV4_4BYTE:begin
            bufPush(
                .target_state(MAC_IPV4_CHECKSUM),
                .target_cnt(16'd4),
                .buf_val({32'h00,checksum_16b[7:0],checksum_16b[15:8]})
            );
        end
        MAC_IPV4_CHECKSUM:begin
            bufPush(
                .target_state(MAC_IPV4_SRCIP),
                .target_cnt(16'd2),
                .buf_val({16'h00,src_ip_adr[7:0],src_ip_adr[15:8],
                                        src_ip_adr[23:16],src_ip_adr[31:24]})
            );
        end
        MAC_IPV4_SRCIP:begin
            bufPush(
                .target_state(MAC_IPV4_DSTIP),
                .target_cnt(16'd4),
                .buf_val({16'h00,dst_ip_adr[7:0],dst_ip_adr[15:8],
                                        dst_ip_adr[23:16],dst_ip_adr[31:24]})
            );
        end
        MAC_IPV4_DSTIP:begin
            bufPush(
                .target_state(MAC_UDP_PORT),
                .target_cnt(16'd4),
                .buf_val({16'h00,udp_port[7:0],udp_port[15:8],
                                        udp_my_port[7:0],udp_my_port[15:8]})
            );
        end
        MAC_UDP_PORT:begin
            bufPush(
                .target_state(MAC_UDP_LENCRC),
                .target_cnt(16'd4),
                .buf_val({16'h00,16'h00,I_udpLen[7:0],I_udpLen[15:8]})
            );
        end
        MAC_UDP_LENCRC:begin
            bufPush(
                .target_state(MAC_UDP_DATA),
                .target_cnt(16'd4),
                .buf_val(48'h00)
            );
        end
        MAC_UDP_DATA:begin
            tx_en <= 1;
            buffer_data <= I_data;
            if(last_bit_flag == 1'd1)begin
                O_txen <= I_de;
                last_o_txen_state <= O_txen;
            end
            if(isSaveFlag == 1'd1)begin
                if(byte_cnt == I_dataLen - 16'd1)begin
                    byte_cnt <= 0;
                    state <= MAC_CRC;
                    mac_adr_buf <= 48'd0;
                    crc_forcr_en <= 1;
                end
                else begin
                    if(last_o_txen_state)begin
                        byte_cnt <= byte_cnt + 16'd1;
                    end
                    else  byte_cnt <= byte_cnt;
                end
            end
        end
        MAC_CRC:begin
            crc_forcr_en <= 0;
            case(byte_cnt)
            16'd0:begin buffer_data <= mac_adr_buf[31:24]; end
            16'd1:begin buffer_data <= mac_adr_buf[23:16]; end
            16'd2:begin buffer_data <= mac_adr_buf[15:8];  end
            16'd3:begin buffer_data <= mac_adr_buf[7:0];   end
            endcase
            if(byte_cnt == 16'd0)begin
                mac_adr_buf <= {16'd0,
                        {crc_out[24], crc_out[25], crc_out[26], crc_out[27], crc_out[28], crc_out[29], crc_out[30], crc_out[31]},
                        {crc_out[16], crc_out[17], crc_out[18], crc_out[19], crc_out[20], crc_out[21], crc_out[22], crc_out[23]},
                        {crc_out[ 8], crc_out[ 9], crc_out[10], crc_out[11], crc_out[12], crc_out[13], crc_out[14], crc_out[15]},
                        {crc_out[ 0], crc_out[ 1], crc_out[ 2], crc_out[ 3], crc_out[ 4], crc_out[ 5], crc_out[ 6], crc_out[ 7]}};
            end
            if(isSaveFlag == 1'd1)begin
                if(byte_cnt == 16'd4 - 16'd1)begin
                    byte_cnt <= 0;
                    state <= MAC_END;
                    tx_en <= 0;
                end
                else begin
                    // mac_adr_buf <= mac_adr_buf >> 8;
                    byte_cnt <= byte_cnt + 16'd1;
                end
            end
        end
        MAC_END:begin
            byte_cnt <= byte_cnt + 16'd1;
            if(byte_cnt == 16'd3 - 16'd1)begin
                O_txen <= 0;
            end
            if(byte_cnt == 16'd48 - 16'd1)begin
                state <= MAC_IDLE;
                variableRST();
            end
        end
        endcase
    end
end

rmii_txd rmii_txd0(
    .I_clk50m(I_clk50m),
    .I_txen(tx_en),
    .I_data(buffer_data),
    .O_txd(O_txd),
    .isSaveData(isSaveFlag),
    .last_bit(last_bit_flag)
);

logic [1:0] crc_byte_cnt;//4byte 1circle
logic crc_en_tip;

always@(posedge I_clk50m or negedge crc_rst)begin
    if(~crc_rst) begin
        crc_data_buf <= 32'd0;
        crc_byte_cnt <= 32'd0;
        crc_en_tip <= 0;
    end
    else begin
        if(isSaveFlag == 1'd1)begin
            case(crc_byte_cnt)
                2'd0:begin
                    crc_data_buf <= {buffer_data,24'd0};
                end
                2'd1:begin
                    crc_data_buf[23:16] <= buffer_data;
                end
                2'd2:begin
                    crc_data_buf[15:8] <= buffer_data;
                end
                2'd3:begin
                    crc_data_buf[7:0] <= buffer_data;
                end
            endcase
            crc_byte_cnt <= crc_byte_cnt + 1'd1;
        end
        if(crc_byte_cnt == 2'd3)
            crc_en_tip <= 1;
        else
            crc_en_tip <= 0;
        if(crc_en_tip&&crc_byte_cnt == 2'd0)
            crc_en <= 1;
        else
            crc_en <= 0;
        if(crc_forcr_en == 1)
            crc_byte_cnt <= 0;
    end
end

logic crc_en_wire;
assign crc_en_wire = crc_en|crc_forcr_en;

// crc32 crc_tx(
//     .clk(I_clk50m),
//     .rst(crc_rst),
//     .en(crc_en_wire),
//     .data_in(crc_data_buf),
//     .crc_out(crc_out)
// );

crc8 crc_tx(
    .clk(I_clk50m),
    .rst(crc_rst),
    .en(isSaveFlag),
    .data_in(buffer_data),
    .crc_out(crc_out)
);

endmodule
/*
module crc32 (
    input clk,
    input rst,
    input en,
    input [7:0] data_in,
    output reg [31:0] crc_out
);

reg [31:0] crc;
reg [31:0] crc_next;
integer i;
// reg [31:0] data;

reg en_bef;
wire en_flag;
assign en_flag = (~en_bef)&en;

always @ (posedge clk or negedge rst) begin
    if(!rst)begin
        crc_next <= 0;
        en_bef <= 0;
    end
    else begin
        en_bef <= en;
        if(en_flag)begin
            crc_next = crc ^ data_in;
            for (i = 0; i < 32; i = i + 1) begin
                if (crc_next[31] == 1'b1) begin
                    crc = crc_next ^ 32'h04C11DB7;
                end else begin
                    crc = crc_next;
                end
                crc_next = crc << 1;
            end
        end
    end
end

always @ (posedge clk or negedge rst) begin
    if(!rst)begin
        crc <= 32'hFFFFFFFF;
        // data <= 32'h00000000;
    end
end

// always @ (posedge clk) begin
//     if(en_flag)
//         data <= data_in;
// en

assign crc_out = ~crc;

endmodule
*/
// module crc (Clk, Reset, data_in, Enable, Crc,CrcNext);
module crc8(
    input clk,
    input rst,
    input en,
    input [31:0] data_in,
    output wire [31:0] crc_out
);
 
reg [31:0] Crc;
wire [31:0] CrcNext;
wire [7:0] Data;
 
assign Data={data_in[0],data_in[1],data_in[2],data_in[3],data_in[4],data_in[5],data_in[6],data_in[7]};
 
assign CrcNext[0] = Crc[24] ^ Crc[30] ^ Data[0] ^ Data[6];
assign CrcNext[1] = Crc[24] ^ Crc[25] ^ Crc[30] ^ Crc[31] ^ Data[0] ^ Data[1] ^ Data[6] ^ Data[7];
assign CrcNext[2] = Crc[24] ^ Crc[25] ^ Crc[26] ^ Crc[30] ^ Crc[31] ^ Data[0] ^ Data[1] ^ Data[2] ^ Data[6] ^ Data[7];
assign CrcNext[3] = Crc[25] ^ Crc[26] ^ Crc[27] ^ Crc[31] ^ Data[1] ^ Data[2] ^ Data[3] ^ Data[7];
assign CrcNext[4] = Crc[24] ^ Crc[26] ^ Crc[27] ^ Crc[28] ^ Crc[30] ^ Data[0] ^ Data[2] ^ Data[3] ^ Data[4] ^ Data[6];
assign CrcNext[5] = Crc[24] ^ Crc[25] ^ Crc[27] ^ Crc[28] ^ Crc[29] ^ Crc[30] ^ Crc[31] ^ Data[0] ^ Data[1] ^ Data[3] ^ Data[4] ^ Data[5] ^ Data[6] ^ Data[7];
assign CrcNext[6] = Crc[25] ^ Crc[26] ^ Crc[28] ^ Crc[29] ^ Crc[30] ^ Crc[31] ^ Data[1] ^ Data[2] ^ Data[4] ^ Data[5] ^ Data[6] ^ Data[7];
assign CrcNext[7] = Crc[24] ^ Crc[26] ^ Crc[27] ^ Crc[29] ^ Crc[31] ^ Data[0] ^ Data[2] ^ Data[3] ^ Data[5] ^ Data[7];
assign CrcNext[8] = Crc[0] ^ Crc[24] ^ Crc[25] ^ Crc[27] ^ Crc[28] ^ Data[0] ^ Data[1] ^ Data[3] ^ Data[4];
assign CrcNext[9] = Crc[1] ^ Crc[25] ^ Crc[26] ^ Crc[28] ^ Crc[29] ^ Data[1] ^ Data[2] ^ Data[4] ^ Data[5];
assign CrcNext[10] = Crc[2] ^ Crc[24] ^ Crc[26] ^ Crc[27] ^ Crc[29] ^ Data[0] ^ Data[2] ^ Data[3] ^ Data[5];
assign CrcNext[11] = Crc[3] ^ Crc[24] ^ Crc[25] ^ Crc[27] ^ Crc[28] ^ Data[0] ^ Data[1] ^ Data[3] ^ Data[4];
assign CrcNext[12] = Crc[4] ^ Crc[24] ^ Crc[25] ^ Crc[26] ^ Crc[28] ^ Crc[29] ^ Crc[30] ^ Data[0] ^ Data[1] ^ Data[2] ^ Data[4] ^ Data[5] ^ Data[6];
assign CrcNext[13] = Crc[5] ^ Crc[25] ^ Crc[26] ^ Crc[27] ^ Crc[29] ^ Crc[30] ^ Crc[31] ^ Data[1] ^ Data[2] ^ Data[3] ^ Data[5] ^ Data[6] ^ Data[7];
assign CrcNext[14] = Crc[6] ^ Crc[26] ^ Crc[27] ^ Crc[28] ^ Crc[30] ^ Crc[31] ^ Data[2] ^ Data[3] ^ Data[4] ^ Data[6] ^ Data[7];
assign CrcNext[15] =  Crc[7] ^ Crc[27] ^ Crc[28] ^ Crc[29] ^ Crc[31] ^ Data[3] ^ Data[4] ^ Data[5] ^ Data[7];
assign CrcNext[16] = Crc[8] ^ Crc[24] ^ Crc[28] ^ Crc[29] ^ Data[0] ^ Data[4] ^ Data[5];
assign CrcNext[17] = Crc[9] ^ Crc[25] ^ Crc[29] ^ Crc[30] ^ Data[1] ^ Data[5] ^ Data[6];
assign CrcNext[18] = Crc[10] ^ Crc[26] ^ Crc[30] ^ Crc[31] ^ Data[2] ^ Data[6] ^ Data[7];
assign CrcNext[19] = Crc[11] ^ Crc[27] ^ Crc[31] ^ Data[3] ^ Data[7];
assign CrcNext[20] = Crc[12] ^ Crc[28] ^ Data[4];
assign CrcNext[21] = Crc[13] ^ Crc[29] ^ Data[5];
assign CrcNext[22] = Crc[14] ^ Crc[24] ^ Data[0];
assign CrcNext[23] = Crc[15] ^ Crc[24] ^ Crc[25] ^ Crc[30] ^ Data[0] ^ Data[1] ^ Data[6];
assign CrcNext[24] = Crc[16] ^ Crc[25] ^ Crc[26] ^ Crc[31] ^ Data[1] ^ Data[2] ^ Data[7];
assign CrcNext[25] = Crc[17] ^ Crc[26] ^ Crc[27] ^ Data[2] ^ Data[3];
assign CrcNext[26] = Crc[18] ^ Crc[24] ^ Crc[27] ^ Crc[28] ^ Crc[30] ^ Data[0] ^ Data[3] ^ Data[4] ^ Data[6];
assign CrcNext[27] = Crc[19] ^ Crc[25] ^ Crc[28] ^ Crc[29] ^ Crc[31] ^ Data[1] ^ Data[4] ^ Data[5] ^ Data[7];
assign CrcNext[28] = Crc[20] ^ Crc[26] ^ Crc[29] ^ Crc[30] ^ Data[2] ^ Data[5] ^ Data[6];
assign CrcNext[29] = Crc[21] ^ Crc[27] ^ Crc[30] ^ Crc[31] ^ Data[3] ^ Data[6] ^ Data[7];
assign CrcNext[30] = Crc[22] ^ Crc[28] ^ Crc[31] ^ Data[4] ^ Data[7];
assign CrcNext[31] = Crc[23] ^ Crc[29] ^ Data[5];
 
reg en_bef;
wire en_flag;
assign en_flag = (~en_bef)&en;
assign crc_out = ~Crc;

always @ (posedge clk or negedge rst) begin
    if (!rst) begin
        Crc <={32{1'b1}};
        en_bef <= 0;
    end
    else begin
        en_bef <= en;
        if(en_flag)
            Crc <=CrcNext;
    end
 end
endmodule