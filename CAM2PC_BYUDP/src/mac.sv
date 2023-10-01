module mac#(
    parameter bit [31:0] ip_adr = 32'd0,
    parameter bit [47:0] udp_my_port = 16'd0,
    parameter bit [47:0] udp_port = 16'd0,
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

 task variableRST();
    state <= MAC_IDLE;
    O_busy <= 0;
    O_isLoadData <= 0;
    byte_cnt <= 0;
    buffer_data <= 0;
    bit_cnt <= 0;
    mac_adr_buf <= 0;
    tx_en <= 0;
 endtask

 initial begin
    variableRST();
 end

 task bufPush(
    input [7:0] target_state,
    input [47:0] buf_val,
    input [15:0] target_cnt
 );
    tx_en <= 1;
    buffer_data <= mac_adr_buf[8:0];
    if(isSaveFlag == 1'd1)begin
        if(byte_cnt == target_cnt - 16'd1)begin
            byte_cnt <= 0;
            state <= target_state;
            mac_adr_buf <= {mac_my_adr[7:0],  mac_my_adr[15:8], mac_my_adr[23:16],
                            mac_my_adr[31:24],mac_my_adr[39:32],mac_my_adr[47:40]};
        end
        else begin
            mac_adr_buf <= mac_adr_buf >> 8;
            byte_cnt <= byte_cnt + 16'd1;
        end
    end
 endtask

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
            tx_en <= 1;
            buffer_data <= mac_adr_buf[8:0];
            if(isSaveFlag == 1'd1)begin
                if(byte_cnt == 16'd5)begin
                    byte_cnt <= 0;
                    state <= MAC_MYADR;
                    mac_adr_buf <= {mac_my_adr[7:0],  mac_my_adr[15:8], mac_my_adr[23:16],
                                    mac_my_adr[31:24],mac_my_adr[39:32],mac_my_adr[47:40]};
                end
                else begin
                    mac_adr_buf <= mac_adr_buf >> 8;
                    byte_cnt <= byte_cnt + 16'd1;
                    state <= MAC_ADR;
                end
            end
        end
        MAC_MYADR:begin
            tx_en <= 1;
            buffer_data <= mac_adr_buf[8:0];
            if(isSaveFlag == 1'd1)begin
                if(byte_cnt == 16'd5)begin
                    byte_cnt <= 0;
                    state <= MAC_LEN;
                    mac_adr_buf <= {32'h0,8'h00,8'h08}
                end
                else begin
                    mac_adr_buf <= mac_adr_buf >> 8;
                    byte_cnt <= byte_cnt + 16'd1;
                    state <= MAC_MYADR;
                end
            end
        end
        MAC_LEN:begin
            tx_en <= 1;
            buffer_data <= mac_adr_buf[8:0];
            if(isSaveFlag == 1'd1)begin
                if(byte_cnt == 16'd2 - 16'd1)begin
                    byte_cnt <= 0;
                    state <= MAC_UDP_PORT;
                    mac_adr_buf <= {16'h00,udp_port[15:8],udp_port[7:0],
                                        udp_my_port[15:8],udp_my_port[7:0]}
                end
                else begin
                    mac_adr_buf <= mac_adr_buf >> 8;
                    byte_cnt <= byte_cnt + 16'd1;
                    state <= MAC_LEN;
                end
            end
        end
        MAC_UDP_PORT:begin
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

endmodule