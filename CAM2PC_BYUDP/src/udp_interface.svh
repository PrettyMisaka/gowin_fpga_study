`ifndef UDP_INTERFACE
`define UDP_INTERFACE
interface udp_interface(
    input I_udp_tx_en,
    input [7:0] I_udp_data,
    input [15:0] I_udp_data_len,
    input [15:0] I_ipv4_sign,
    output logic O_mac_init_ready,
    output logic O_udp_busy,
    output logic O_udp_isLoadData
);
endinterface //rmii
`endif //RMII_INTERFACE