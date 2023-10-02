`include "rmii.svh"

module top(
    input clk,
    input rst,
    input en_key,

    rmii netrmii,
    output logic phyrst,

    output logic [5:0] led
);

logic [31:0] led_flash;
logic en;
logic [15:0] ipv4_sign ;

assign phyrst = 1;
assign led[4] = en;
assign en = ~en_key;
initial begin
    led[3] = 0;
    led_flash = 0;
    ipv4_sign = 16'h0123;
end

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
    .I_en(en),
    .I_data(8'haa),
    .I_dataLen(16'd222),
    .I_ipv4sign(16'd328),
    
    .O_txd(netrmii.txd),
    .O_txen(netrmii.txen),
    .O_busy(led[0]),
    .O_isLoadData(led[1])
);

always@(negedge led[0])begin
    ipv4_sign <= ipv4_sign + 16'd1;
end

always@(posedge netrmii.clk50m)begin
    if(led_flash == 32'd5_000_000)begin
        led[3] <= ~led[3];
        led_flash <= 32'd0;
    end
    else begin
        led_flash <= led_flash + 32'd1;
    end
end

endmodule