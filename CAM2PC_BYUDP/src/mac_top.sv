`include "inc/rmii.svh"
`include "inc/udp_interface.svh"
`include "inc/inout_interface.svh"

module mac_top(
    input clk,
    input rst,

    rmii netrmii,
    
    input mdio_i,
    output logic mdio_o,
    output logic mdio_out_en,

    output logic mdc ,
    inout  mdio,
    
    input I_udp_tx_en,
    input [7:0] I_udp_data,
    input [15:0] I_udp_data_len,
    input [15:0] I_ipv4_sign,
    output logic O_mac_init_ready,
    output logic O_udp_busy,
    output logic O_udp_isLoadData,

    output logic phyrst,
    output logic init_down,

    output logic [5:0] led
);

logic clk1m, clk6m;//clk

logic [31:0] led_flash;
// logic en;
logic [15:0] ipv4_sign ;

logic smi_ready;

initial begin
    // led[3] = 0;
    led_flash = 0;
    ipv4_sign = 16'h0123;
end

assign phyrst = rst;
assign init_down = smi_ready;
assign O_mac_init_ready = smi_ready;
// assign led[4] = en;
// assign en = udp_port.I_udp_tx_en;
// assign led[5] = smi_ready;

mac #(
    .udp_my_port(16'd11451),
    .udp_port(16'd11451),
    .src_ip_adr({8'd192,8'd168,8'd15,8'd14}),
    .dst_ip_adr({8'd192,8'd168,8'd15,8'd15}),
    .mac_adr({8'h06,8'h00,8'hAA,8'hBB,8'h0C,8'hDD}),
    .mac_my_adr({8'he8,8'h6a,8'h64,8'hfa,8'hd1,8'h7b})
)mac0(
    .I_clk50m(netrmii.clk50m),
    .I_rst(phyrst),

    .I_en(I_udp_tx_en),
    .I_data(I_udp_data),
    // .I_dataLen(16'd222),
    .I_dataLen(I_udp_data_len),
    .I_ipv4sign(I_ipv4_sign),
    
    .O_txd(netrmii.txd),
    .O_txen(netrmii.txen),

    .O_busy(O_udp_busy),
    .O_isLoadData(O_udp_isLoadData)
);

always@(negedge O_udp_busy)begin
    ipv4_sign <= ipv4_sign + 16'd1;
end

always@(posedge netrmii.clk50m)begin
    if(led_flash == 32'd5_000_000)begin
        // led[3] <= ~led[3];
        led_flash <= 32'd0;
    end
    else begin
        led_flash <= led_flash + 32'd1;
    end
end

smi mac_smi(
    .clk1m(clk1m),
    .rst(rst),
    
    .phyrst(phyrst),
    .ready(smi_ready),

    .mdc(mdc),
//    .mdio(mdio),

    .mdio_i(mdio_i),
    .mdio_o(mdio_o),
    .mdio_out_en(mdio_out_en)
);

Gowin_rPLL_6M rpll_6m(
    .clkout(clk6m),
    .clkoutd(clk1m),
    .clkin(clk)
);

endmodule