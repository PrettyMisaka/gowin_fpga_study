module mac#(
    parameter bit [31:0] ip_adr = 32'd0,
    parameter bit [15:0] udp_my_port = 16'd0,
    parameter bit [15:0] udp_port = 16'd0,
    parameter bit [47:0] mac_adr = 48'd0,
    parameter bit [47:0] mac_my_adr = 48'd0
)(
    input I_clk50m,
    input I_rst,
    input I_en,
    input [7:0]  I_data,
    input [15:0] I_udpLen,
    
    output logic [1:0] O_txd,
    output logic O_txen,
    output logic O_busy,
    output logic O_isLoadData
);

typedef enum logic [7:0] { 
    MAC_IDLE, MAC_SYNC, MAC_FRAME, MAC_ADR, MAC_MYADR, MAC_LEN,
    MAC_UDP_PORT, MAC_UDP_LENCRC, MAC_UDP_DATA,
    MAC_CRC, MAC_END
} state_typedef;
state_typedef state;
    
 logic [15:0] byte_cnt;
 logic [7:0] bit_cnt;
 logic [7:0] buffer_data;
 logic isSaveFlag;
 logic tx_en;
 logic [47:0] mac_adr_buf;

/*********** crc logic************/
 logic [31:0] crc_data_buf;
 logic crc_en, crc_rst;
 logic [31:0] crc_out;
 logic crc_forcr_en;

 task variableRST();
    state <= MAC_IDLE;
    O_busy <= 0;
    byte_cnt <= 0;
    buffer_data <= 0;
    bit_cnt <= 0;
    mac_adr_buf <= 0;
    tx_en <= 0;

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
                crc_rst <= 1;
            end
            else begin
                variableRST();
            end
        end
        MAC_SYNC:begin
            tx_en <= 1;
            buffer_data <= 8'b10101010;
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
        end
        MAC_FRAME:begin
            tx_en <= 1;
            buffer_data <= 8'b10101011;
            if(isSaveFlag == 1'd1)begin
                state <= MAC_ADR;
                mac_adr_buf <= {mac_adr[7:0],  mac_adr[15:8], mac_adr[23:16],
                                mac_adr[31:24],mac_adr[39:32],mac_adr[47:40]};
            end
            else begin
                state <= MAC_FRAME;
            end
        end
        MAC_ADR:begin
            bufPush(
                .target_state(MAC_MYADR),
                .target_cnt(16'd6),
                .buf_val({mac_my_adr[7:0],  mac_my_adr[15:8], mac_my_adr[23:16],
                                    mac_my_adr[31:24],mac_my_adr[39:32],mac_my_adr[47:40]})
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
                .target_state(MAC_UDP_PORT),
                .target_cnt(16'd2),
                .buf_val({16'h00,udp_port[15:8],udp_port[7:0],
                                        udp_my_port[15:8],udp_my_port[7:0]})
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
        MAC_UDP_PORT:begin
            bufPush(
                .target_state(MAC_UDP_LENCRC),
                .target_cnt(16'd2),
                .buf_val({16'h00,16'h00,I_udpLen[15:8],I_udpLen[7:0]})
            );
        end
        MAC_UDP_LENCRC:begin
            bufPush(
                .target_state(MAC_UDP_DATA),
                .target_cnt(16'd6),
                .buf_val(48'h00)
            );
        end
        MAC_UDP_DATA:begin
            tx_en <= 1;
            buffer_data <= I_data;
            if(isSaveFlag == 1'd1)begin
                if(byte_cnt == I_udpLen - 16'd9)begin
                    byte_cnt <= 0;
                    state <= MAC_CRC;
                    mac_adr_buf <= 48'd0;
                    crc_forcr_en <= 1;
                end
                else begin
                    byte_cnt <= byte_cnt + 16'd1;
                end
            end
        end
        MAC_CRC:begin
            crc_forcr_en <= 0;
            case(byte_cnt)
            16'd0:begin buffer_data <= crc_out[31:24]; end
            16'd1:begin buffer_data <= crc_out[23:16]; end
            16'd2:begin buffer_data <= crc_out[15:8]; end
            16'd3:begin buffer_data <= crc_out[7:0]; end
            endcase
            if(isSaveFlag == 1'd1)begin
                if(byte_cnt == 16'd4 - 16'd1)begin
                    byte_cnt <= 0;
                    state <= MAC_END;
                    tx_en <= 0;
                end
                else begin
                    mac_adr_buf <= mac_adr_buf >> 8;
                    byte_cnt <= byte_cnt + 16'd1;
                end
            end
        end
        MAC_END:begin
            variableRST();
            state <= MAC_IDLE;
        end
        endcase
    end
end

rmii_txd rmii_txd0(
    .I_clk50m(I_clk50m),
    .I_txen(tx_en),
    .I_data(buffer_data),
    .O_txd(O_txd),
    .O_txen(O_txen),
    .isSaveData(isSaveFlag)
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

crc32 crc_tx(
    .clk(I_clk50m),
    .rst(crc_rst),
    .en(crc_en_wire),
    .data_in(crc_data_buf),
    .crc_out(crc_out)
);

endmodule

module crc32 (
    input clk,
    input rst,
    input en,
    input [31:0] data_in,
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
// end

assign crc_out = ~crc;

endmodule