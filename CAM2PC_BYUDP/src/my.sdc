//Copyright (C)2014-2023 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: V1.9.9 Beta-5
//Created Time: 2023-10-20 14:47:15
create_clock -name memory_clk_400m -period 2.5 -waveform {0 1.25} [get_nets {memory_clk_400m}]
create_clock -name clk1 -period 1000 -waveform {0 500} [get_ports {scl_mdc}]
create_clock -name clk50 -period 20 -waveform {0 10} [get_ports {netrmii_clk50m}]
# create_clock -name clk -period 37.037 -waveform {0 18.518} [get_ports {clk}] -add
create_clock -name clk       -period 37.037 [get_ports {clk}] -add
create_clock -name cam_port_cmos_pclk -period 10 -waveform {0 5} [get_ports {cam_port_cmos_pclk}] -add
create_clock -name cam_port_cmos_vsync -period 1000 -waveform {0 500} [get_ports {cam_port_cmos_vsync}] -add
set_false_path -from [get_clocks {clk1}] -to [get_clocks {clk50}] 
set_false_path -from [get_clocks {clk50}] -to [get_clocks {clk1}] 
report_timing -hold -from_clock [get_clocks {clk}] -to_clock [get_clocks {clk}] -max_paths 25 -max_common_paths 1
report_timing -setup -from_clock [get_clocks {clk}] -to_clock [get_clocks {clk}] -max_paths 25 -max_common_paths 1
