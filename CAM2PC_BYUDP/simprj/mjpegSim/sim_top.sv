`timescale 1ps / 1ps
module sim_top();

logic pxl_clk;
logic rst;
logic hdmi_en;

always #1 pxl_clk = ~pxl_clk;

initial begin
    pxl_clk <= 1'd0;
    rst <= 1'd0;
    hdmi_en <= 1'd0;
#4
    rst <= 1'd1;
#4
    hdmi_en <= 1'd1;
end

logic O_de;

my_testpattern my_testpattern0(
    .I_pxl_clk   (pxl_clk            ),//pixel clock
    .I_rst_n     (rst                ),//low active 
    .I_en        (hdmi_en               ),             //800x600    //1024x768   //1280x720    
    .I_h_total   (12'd1200           ),//hor total time  // 12'd1056  // 12'd1344  // 12'd1650  
    .I_h_sync    (12'd10             ),//hor sync time   // 12'd128   // 12'd136   // 12'd40    
    .I_h_bporch  (12'd16             ),//hor back porch  // 12'd88    // 12'd160   // 12'd220   
    .I_h_res     (12'd1024           ),//hor resolution  // 12'd800   // 12'd1024  // 12'd1280  
    .I_v_total   (12'd806            ),//ver total time  // 12'd628   // 12'd806   // 12'd750    
    .I_v_sync    (12'd6              ),//ver sync time   // 12'd4     // 12'd6     // 12'd5     
    .I_v_bporch  (12'd29             ),//ver back porch  // 12'd23    // 12'd29    // 12'd20    
    .I_v_res     (12'd768            ),//ver resolution  // 12'd600   // 12'd768   // 12'd720  
    .O_busy      (busy               ),
    .O_de        (O_de               ),   
    .O_hs        (O_hs               ),//������
    .O_vs        (O_vs               ) 
);


MJPEG_Encoder_Top MJPEG_Encoder0(
    .clk        (pxl_clk                ), //input clk
    .rstn       (rst                    ), //input rstn
    .DE         (O_de               ), //input DE
    .data_in    (24'd0          ), //input [23:0] data_in
    .img_out    (         ), //output [7:0] img_out
    .img_valid  (             ), //output img_valid
    .img_done   (             ) //output img_done
);

endmodule

