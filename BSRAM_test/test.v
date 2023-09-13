module test(
    input clk
);

parameter ADDRESS_STEP_N = 11'd3;

localparam 
    BSRAM_IDLE      = 4'd0 ,
    BSRAM_WRITE     = 4'd1 ,
    BSRAM_READ      = 4'd2 ,
    BSRAM_FINISH    = 4'd3 ;
localparam NULL_ADDRESS = 11'd0;

reg i_a_clk_en, i_a_data_en, i_a_wr_en;
reg [7:0]   i_a_date;
reg [7:0]   o_a_date;
reg [10:0]  i_a_address;

reg [10:0]   list_head_addr;

reg [3:0] state;
reg [3:0] step_cnt;
reg [7:0] wr_cnt;

initial begin
    list_head_addr <= 11'd3;
    i_a_clk_en     <= 1;
    i_a_data_en    <= 1;
    i_a_wr_en      <= 0;
    state          <= BSRAM_IDLE;
    step_cnt       <= 0;
    wr_cnt         <= 0;
end

always @(posedge clk) begin
    case(state)
        BSRAM_IDLE:begin
            i_a_wr_en <= 0;
            state <= BSRAM_WRITE;
            step_cnt       <= 0;
            wr_cnt         <= 0;
        end
        BSRAM_WRITE:begin
        end
    endcase
end

Gowin_DPB your_instance_name(
    .douta          (o_a_date), //output [7:0] douta
    .clka           (clk), //input clka
    .ocea           (i_a_data_en), //input ocea
    .cea            (i_a_clk_en), //input cea
    .reseta         (0), //input reseta
    .wrea           (i_a_wr_en), //input wrea
    .ada            (ada_i), //input [10:0] ada
    .dina           (i_a_date), //input [7:0] dina
    // .doutb          (doutb_o), //output [7:0] doutb
    // .clkb           (clkb_i), //input clkb
    // .oceb           (oceb_i), //input oceb
    // .ceb            (ceb_i), //input ceb
    // .resetb         (resetb_i), //input resetb
    // .wreb           (wreb_i), //input wreb
    // .adb            (adb_i), //input [10:0] adb
    // .dinb           (dinb_i) //input [7:0] dinb
);

endmodule