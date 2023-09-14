module test(
    input clk
);

parameter ADDRESS_STEP_N = 11'd64;

localparam 
    BSRAM_IDLE      = 4'd0 ,
    BSRAM_WRITE     = 4'd1 ,
    BSRAM_READ      = 4'd2 ,
    BSRAM_FINISH    = 4'd3 ;
localparam NULL_ADDRESS = 11'd0;

reg i_a_clk_en, i_a_data_en, i_a_wr_en;
reg  [7:0]   i_a_data;
wire [7:0]   o_a_data;
reg  [10:0]  i_a_address;
reg  [7:0]   dpb_a_data;

reg i_b_clk_en, i_b_data_en, i_b_wr_en;
reg [7:0]   i_b_data;
wire [7:0]   o_b_data;
reg [10:0]  i_b_address;

reg [10:0]   list_head_addr;
reg [10:0]   list_next_addr;
reg [10:0]   list_now_addr;

reg [3:0]  state;
reg [3:0]  step_cnt;
reg [10:0] wr_cnt;

initial begin
    list_head_addr <= 11'd4;
    list_now_addr  <= 11'd4;
    list_next_addr <= 11'd0;
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
            i_a_wr_en <= 1;
            case(step_cnt)
                4'd0:begin
                    i_a_address <= list_now_addr;
                    i_a_data <=  wr_cnt[7:0];
                    step_cnt <= step_cnt + 4'd1;
                end
                4'd1:begin
                    step_cnt <= step_cnt + 4'd1;
                    i_a_address <= list_now_addr + step_cnt;
                    i_a_data <=  wr_cnt[7:0];
                end
                4'd2:begin
                    step_cnt <= step_cnt + 4'd1;
                    i_a_address <= list_now_addr + step_cnt;
                    i_a_data <=  (list_now_addr + ADDRESS_STEP_N) >> 8;
                end
                4'd3:begin
                    step_cnt <= 4'd0;
                    i_a_address <= list_now_addr + step_cnt;
                    if(wr_cnt == 11'd10 - 11'd1)begin
                        state <= BSRAM_READ;
                        list_now_addr <= list_head_addr;
                        i_a_data <= NULL_ADDRESS;
                    end
                    else begin
                        state <= BSRAM_WRITE;
                        wr_cnt <= wr_cnt + 11'd1;
                        list_now_addr <= list_now_addr + ADDRESS_STEP_N;
                        i_a_data <= list_now_addr[7:0] + ADDRESS_STEP_N;
                    end
                end
            endcase
        end
        BSRAM_READ:begin
            i_a_wr_en <= 0;
            case(step_cnt)
                4'd0:begin
                    step_cnt <= step_cnt + 4'd1;
                    i_a_address <= list_now_addr;
                    // dpb_a_data <= o_a_data;
                end
                4'd1:begin
                    step_cnt <= step_cnt + 4'd1;
                    i_a_address <= list_now_addr + step_cnt;
                    // dpb_a_data <= o_a_data;
                end
                4'd2:begin
                    step_cnt <= step_cnt + 4'd1;
                    i_a_address <= list_now_addr + step_cnt;
                    // dpb_a_data <= o_a_data;
                end
                4'd3:begin
                    step_cnt <= step_cnt + 4'd1;
                    i_a_address <= list_now_addr + step_cnt;
                    dpb_a_data <= o_a_data;
                end
                4'd4:begin
                    step_cnt <= step_cnt + 4'd1;
                    i_a_address <= NULL_ADDRESS;
                    // i_a_address <= list_now_addr + step_cnt;
                    dpb_a_data <= o_a_data;
                end
                4'd5:begin
                    step_cnt <= step_cnt + 4'd1;
                    i_a_address <= NULL_ADDRESS;
                    // i_a_address <= list_now_addr + step_cnt;
                    dpb_a_data <= o_a_data;
                    list_next_addr <= {o_a_data[2:0],8'd0};
                end
                4'd6:begin
                    step_cnt <= 4'd0;
                    i_a_address <= NULL_ADDRESS;
                    dpb_a_data <= o_a_data;
                    list_next_addr <= list_next_addr + o_a_data;
                    list_now_addr <= list_next_addr + o_a_data;
                    if((list_next_addr + o_a_data) == NULL_ADDRESS)begin
                        state <= BSRAM_FINISH;
                    end
                end

            endcase
        end
    endcase
end

Gowin_DPB your_instance_name(
    .douta          (o_a_data), //output [7:0] douta
    .clka           (clk), //input clka
    .ocea           (i_a_data_en), //input ocea
    .cea            (i_a_clk_en), //input cea
    .reseta         (1'b0), //input reseta
    .wrea           (i_a_wr_en), //input wrea
    .ada            (i_a_address), //input [10:0] ada
    .dina           (i_a_data), //input [7:0] dina

    .doutb          (o_b_data), //output [7:0] doutb
    .clkb           (clk), //input clkb
    .oceb           (i_b_data_en), //input oceb
    .ceb            (i_b_clk_en), //input ceb
    .resetb         (1'b0), //input resetb
    .wreb           (i_b_wr_en), //input wreb
    .adb            (i_b_address), //input [10:0] adb
    .dinb           (i_b_data) //input [7:0] dinb
);

endmodule