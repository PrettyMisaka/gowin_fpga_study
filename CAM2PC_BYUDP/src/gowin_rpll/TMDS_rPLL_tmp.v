//Copyright (C)2014-2023 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: V1.9.8.11 Education
//Part Number: GW2A-LV18PG256C8/I7
//Device: GW2A-18
//Device Version: C
//Created Time: Mon Oct 09 21:20:00 2023

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    TMDS_rPLL your_instance_name(
        .clkout(clkout_o), //output clkout
        .lock(lock_o), //output lock
        .clkin(clkin_i) //input clkin
    );

//--------Copy end-------------------
