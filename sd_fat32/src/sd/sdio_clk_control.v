module sdio_clk_control(
    input       rst_n       ,
    input       clk48mhz    ,
    input       clk_mod     ,
    output wire ctrl_clk    ,
    output wire sdio_clk        
);

reg sdio_clk200khz, sdio_clk24mhz;
reg clk400khz;
reg [5:0] clk400khz_cnt;

assign ctrl_clk = (clk_mod == 1'd0) ? clk400khz : clk48mhz;
assign sdio_clk = (clk_mod == 1'd0) ? sdio_clk200khz : sdio_clk24mhz;
initial begin
    sdio_clk200khz  <= 1'd0;
    sdio_clk24mhz   <= 1'd0;
    clk400khz       <= 1'd0;
    clk400khz_cnt   <= 6'd0;
end

always@(posedge clk48mhz or negedge rst_n)begin
    if(~rst_n) begin
        clk400khz <= 1'd0;
        clk400khz_cnt  <= 6'd0;
    end
    else begin
        if(clk400khz_cnt == 6'd59) begin
            clk400khz_cnt   <= 6'd0;
            clk400khz       <= ~clk400khz;
        end
        else begin
            clk400khz_cnt   <= clk400khz_cnt + 6'd1;
            clk400khz       <= clk400khz;
        end
    end
end

always@(posedge clk400khz or negedge rst_n)begin
    if(~rst_n)
        sdio_clk200khz <= 1'd0;
    else
        sdio_clk200khz <= ~sdio_clk200khz;
end

always@(posedge clk48mhz or negedge rst_n)begin
    if(~rst_n)
        sdio_clk24mhz <= 1'd0;
    else
        sdio_clk24mhz <= ~sdio_clk24mhz;
end

endmodule