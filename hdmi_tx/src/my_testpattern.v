module my_testpattern(
	input              I_pxl_clk   ,//pixel clock
    input              I_en        ,
    input              I_rst_n     ,//low active 
    input      [11:0]  I_h_total   ,//hor total time  // 12'd1056  // 12'd1344  // 12'd1650   
    input      [11:0]  I_h_sync    ,//hor sync time   // 12'd128   // 12'd136   // 12'd40     
    input      [11:0]  I_h_bporch  ,//hor back porch  // 12'd88    // 12'd160   // 12'd220    
    input      [11:0]  I_h_res     ,//hor resolution  // 12'd800   // 12'd1024  // 12'd1280   
    input      [11:0]  I_v_total   ,//ver total time  // 12'd628   // 12'd806   // 12'd750     
    input      [11:0]  I_v_sync    ,//ver sync time   // 12'd4     // 12'd6     // 12'd5       
    input      [11:0]  I_v_bporch  ,//ver back porch  // 12'd23    // 12'd29    // 12'd20       
    input      [11:0]  I_v_res     ,//ver resolution  // 12'd600   // 12'd768   // 12'd720     
    output reg         O_busy      ,
    output reg         O_de        ,   
    output reg         O_hs        ,//������
    output reg         O_vs        
);

localparam
    HDMI_IDLE       = 4'd0,
    HDMI_VS_SYNC    = 4'd1,
    HDMI_VS_BPORCH  = 4'd2,
    HDMI_HS_SYNC    = 4'd3,
    HDMI_HS_BPORCH  = 4'd4,
    HDMI_HS_RES     = 4'd5,
    HDMI_HS_END     = 4'd6,
    HDMI_FINISH     = 4'd7;

reg  [11:0]   v_cnt     ;
reg  [11:0]   h_cnt     ;

reg  [3:0]    state;
initial begin
    state <= HDMI_IDLE;
    v_cnt <= 0;
    h_cnt <= 0;
    O_busy <= 0;
end

always@(posedge I_pxl_clk or negedge I_rst_n) begin
	if(!I_rst_n) begin
        state <= HDMI_IDLE;
        v_cnt <= 0;
        h_cnt <= 0;
        O_de  <= 0;
        O_hs  <= 0;
        O_vs  <= 0;
    end
    else begin

        O_vs <= ((v_cnt>=12'd0) & (v_cnt<=(I_v_sync-1'b1))) ;
        O_hs <= ((h_cnt>=12'd0) & (h_cnt<=(I_h_sync-1'b1))) ;
        O_de <= ((h_cnt>=(I_h_sync+I_h_bporch))&(h_cnt<=(I_h_sync+I_h_bporch+I_h_res-1'b1)))&
                ((v_cnt>=(I_v_sync+I_v_bporch))&(v_cnt<=(I_v_sync+I_v_bporch+I_v_res-1'b1))) ;

        case(state)
            HDMI_IDLE:begin
                if(I_en)begin
                    state <= HDMI_HS_SYNC;
                    O_busy <= 1;
                    h_cnt <= h_cnt + 12'd1;
                end
                else begin
                    state <= HDMI_IDLE;
                    O_busy <= 0;
                    h_cnt <= 0;
                end
                v_cnt <= 0;
            end
            HDMI_HS_SYNC:begin
                h_cnt <= h_cnt + 12'd1;
                if(h_cnt == I_h_sync - 12'd1) begin
                    state <= HDMI_HS_BPORCH;
                end
            end
            HDMI_HS_BPORCH:begin
                h_cnt <= h_cnt + 12'd1;
                if(h_cnt == I_h_sync + I_h_bporch - 12'd1) begin
                    state <= HDMI_HS_RES;
                end
            end
            HDMI_HS_RES:begin
                h_cnt <= h_cnt + 12'd1;
                if(h_cnt == I_h_sync + I_h_bporch + I_v_res - 12'd1) begin
                    state <= HDMI_HS_END;
                end
            end
            HDMI_HS_END:begin
                h_cnt <= h_cnt + 12'd1;
                if(h_cnt == I_h_total - 12'd1) begin
                    h_cnt <= 0;
                    if(v_cnt == I_v_total - 12'd1) begin
                        state <= HDMI_FINISH;
                        v_cnt <= 12'd0;
                    end
                    else begin
                        state <= HDMI_HS_SYNC;
                        v_cnt <= v_cnt + 12'd1;
                    end
                end
            end
            HDMI_FINISH:begin
                state <= HDMI_IDLE;
                O_busy <= 0;
                h_cnt <= 0;
            end
        endcase
    end
end



endmodule