module rmii_txd(
    input I_clk50m,
    input I_txen,
    input [7:0] I_data,
    output logic [1:0] O_txd,
    output logic O_txen,
    output logic isSaveData
);
 logic [7:0] bit_cnt;
 logic [7:0] buffer_data;
 logic working;
 logic I_txen_bef;
 logic I_txen_flag;

 initial begin
    bit_cnt <= 0;
    working <= 0;
    O_txen  <= 0;
    O_txd   <= 0;
 end
 assign I_txen_flag = (~I_txen_bef)&I_txen;

 always@(posedge I_clk50m)begin
    I_txen_bef <= I_txen;
    if(I_txen_flag)begin
        working <= 1'd1;
    end
    if(working||I_txen_flag)begin
        if(bit_cnt == 8'd0)begin
            buffer_data <= {2'bXX,I_data[7:2]};
            O_txd <= I_data[1:0];
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
            if(I_txen == 1'd0)
                working <= 1'd0;
        end
        else begin
            bit_cnt <= bit_cnt + 8'd1;
        end
    end
    else begin
        bit_cnt <= 0;
        O_txen  <= 0;
    end
 end

endmodule