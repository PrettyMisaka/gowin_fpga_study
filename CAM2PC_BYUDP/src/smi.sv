`include "inc/inout_interface.svh"
module smi(
    input clk1m,
    input rst,
    
    output logic phyrst,
    output logic ready,

    // output logic mdc,
    // inout logic mdio,
    
    // input mdc_i,
    output logic mdc_o,
    // output logic mdc_out_en,


    input mdio_i,
    output logic mdio_o,
    output logic mdio_out_en
);

logic rphyrst;

logic phy_rdy;
logic SMI_trg;
logic SMI_ack;
logic SMI_ready;
logic SMI_rw;
logic [4:0] SMI_adr;
logic [15:0] SMI_data;
logic [15:0] SMI_wdata;

byte SMI_status;

assign mdc_o = clk1m;
// assign mdc = clk1m;
assign ready = phy_rdy;

always_ff@(posedge clk1m or negedge rst)begin
    if(rst == 1'b0)begin
        phy_rdy <= 1'b0;
        rphyrst <= 1'b0;
        SMI_trg <= 1'b0;
        SMI_adr <= 5'd1;
        SMI_rw <= 1'b1;
        SMI_status <= 0;
    end else begin
        rphyrst <= 1'b1;
        if(phy_rdy == 1'b0)begin
            SMI_trg <= 1'b1;
            if(SMI_ack && SMI_ready)begin
                case(SMI_status)
                    0:begin
                        SMI_adr <= 5'd31;
                        SMI_wdata <= 16'h7;
                        SMI_rw <= 1'b0;

                        SMI_status <= 1;
                    end
                    1:begin
                        SMI_adr <= 5'd16;
                        SMI_wdata <= 16'hFFE;

                        SMI_status <= 2;
                    end
                    2:begin
                        SMI_rw <= 1'b1;

                        SMI_status <= 3;
                    end
                    3:begin
                        SMI_adr <= 5'd31;
                        SMI_wdata <= 16'h0;
                        SMI_rw <= 1'b0;

                        SMI_status <= 4;
                    end
                    4:begin
                        SMI_adr <= 5'd1;
                        SMI_rw <= 1'b1;

                        SMI_status <= 5;
                    end
                    5:begin
                        if(SMI_data[2])begin
                            phy_rdy <= 1'b1;
                            SMI_trg <= 1'b0;
                        end
                    end
                endcase
            end
        end
    end
end

SMI_ct ct(
    .clk(clk1m), .rst(rphyrst), .rw(SMI_rw), .trg(SMI_trg), .ready(SMI_ready), .ack(SMI_ack),
    .phy_adr(5'd1), .reg_adr(SMI_adr),
    .data(SMI_wdata),
    .smi_data(SMI_data),
    // .mdio(mdio),
    .mdio_i(mdio_i),
    .mdio_o(mdio_o),
    .mdio_out_en(mdio_out_en)
);

endmodule


//1 = read, 0 = write
module SMI_ct(
    input clk, rst, rw, trg,
    [4:0] phy_adr, reg_adr,
    [15:0] data,
    output logic ready, ack,
    logic [15:0] smi_data,
    // inout logic mdio,

    input mdio_i,
    output logic mdio_o,
    output logic mdio_out_en
);

    byte ct;
    reg rmdio;

    reg [31:0] tx_data;
    reg [15:0] rx_data;

    logic mdio;

    assign mdio_out_en = ~rmdio;
    assign mdio = rmdio ? mdio_i : mdio_o;

    // assign mdio = rmdio?1'bZ:1'b0;

    always_comb begin
        smi_data <= rx_data;
    end

    always_ff@(posedge clk or negedge rst)begin
        if(rst == 1'b0)begin
            ct <= 0;
            ready <= 1'b0;
            ack <= 1'b0;

            rmdio <= 1'b1;
        end else begin
            ct <= ct + 8'd1;
            if(ct == 0 && trg == 1'b0)ct<=0;
            if(ct == 0 && trg == 1'b1)begin
                ready <= 1'b0;
                ack <= 1'b0;
            end

            if(ct == 64)begin
                ready <= 1'b1;
            end

            if(trg == 1'b1 && ready == 1'b1)begin
                ready <= 1'b0;
            end

            rmdio <= 1'b1;

            if(ct == 4 && trg == 1'b1)begin
                tx_data <= {2'b01, rw?2'b10:2'b01, phy_adr, reg_adr, rw?2'b11:2'b10, rw?16'hFFFF:data};
            end

            if(ct>31)begin
                rmdio <= tx_data[31];
                tx_data <= {tx_data[30:0], 1'b1};
            end

            if(ct == 48 && mdio == 1'b0)begin
                ack <= 1'b1;
            end
            
            if(ct>48)begin
                rx_data <= {rx_data[14:0], mdio};
            end
        end
    end
endmodule
