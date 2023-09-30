module mac#(
    parameter bit [31:0] ip_adr = 32'd0,
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
    MAC_UDP_MYPORT, MAC_UDP_PORT, MAC_UDP_LEN, MAC_UDP_CRC, MAC_UDP_DATA,
    MAC_CRC, MAC_END
} state_typedef;
state_typedef state;
    
 logic [15:0] byte_cnt;
 logic [7:0] bit_cnt;
 logic [7:0] buffer_data;
 logic isSaveFlag;
 logic [47:0] mac_adr_buf;

 task variableRST();
        state <= MAC_IDLE;
        O_busy <= 0;
        O_isLoadData <= 0;
        O_txd <= 0;
        O_txen <= 0;
        byte_cnt <= 0;
        buffer_data <= 0;
        bit_cnt <= 0;
        mac_adr_buf <= 0;
 endtask

 task updateTxd(
    input [7:0] data,
    output logic isSaveData
 );
    if(bit_cnt == 8'd0)begin
        buffer_data <= {2'bXX,data[7:2]};
        O_txd <= data[1:0];
        O_txen <= 1'b1;
        isSaveData <= 1;
    end
    else begin
        buffer_data <= {2'bXX,buffer_data[7:2]};
        isSaveData <= 0;
        O_txd <= buffer_data[1:0];
    end
    if(bit_cnt == 8'd3)begin
        bit_cnt <= 0;
    end
    else begin
        bit_cnt <= bit_cnt + 8'd1;
    end
 endtask

 initial begin
    variableRST();
 end

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
            updateTxd(
                .data(8'h55),
                .isSaveData(isSaveFlag)
            );
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
            updateTxd(
                .data(8'h55),
                .isSaveData(isSaveFlag)
            );
            if(isSaveFlag == 1'd1)begin
                state <= MAC_ADR;
                mac_adr_buf <= mac_adr;
            end
            else begin
                state <= MAC_FRAME;
            end
        end
        endcase
    end
end

endmodule