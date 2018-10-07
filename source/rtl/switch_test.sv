// This is a test

module switch_test (
	input wire clk_125,
	input wire reset,

	input wire sw1,
	input wire sw2,
	input wire sw3,
	input wire sw0,

    output wire led0,
	output wire led1,
	output wire led2,
	output wire led3
	);

localparam max_count_50ms = 31250000;

wire reset_n;

assign reset_n = ~reset;

reg led0_ff;
reg led1_ff;
reg led2_ff;
reg led3_ff;

reg sw0_ff;
reg sw1_ff;
reg sw2_ff;
reg sw3_ff;

assign led0 = (sw0_ff) ? led0_ff : 1'b0;
assign led1 = (sw1_ff) ? led1_ff : 1'b0;
assign led2 = (sw2_ff) ? led2_ff : 1'b0;
assign led3 = (sw3_ff) ? led3_ff : 1'b0;

reg [31:0] counter;
reg count_50ms;

always @(posedge clk_125 or negedge reset_n) begin
    if (!reset_n) begin
        sw0_ff <= 1'b0;
        sw1_ff <= 1'b0;
        sw2_ff <= 1'b0;
        sw3_ff <= 1'b0;
    end
    else begin
        sw0_ff <= sw0;
        sw1_ff <= sw1;
        sw2_ff <= sw2;
        sw3_ff <= sw3;
    end
end


always @(posedge clk_125 or negedge reset_n) begin
    if (!reset_n) begin
        counter <= 1'b0;
        count_50ms <= 1'b0;
    end
    else begin
        counter <= counter + 1'b1;
        count_50ms <= 1'b0;
        if (counter == max_count_50ms) begin
            counter <= 1'b0;
            count_50ms <= 1'b1;
        end

    end
end

always @(posedge clk_125 or negedge reset_n) begin
    if (!reset_n) begin
        led0_ff <= 1'b0;
        led1_ff <= 1'b1;
        led2_ff <= 1'b0;
        led3_ff <= 1'b1;
    end
    else begin
        led0_ff <= led0_ff;
        led1_ff <= led1_ff;
        led2_ff <= led2_ff;
        led3_ff <= led3_ff;
        if(count_50ms) begin
            led0_ff <= ~led0_ff;
            led1_ff <= ~led1_ff;
            led2_ff <= ~led2_ff;
            led3_ff <= ~led3_ff;
        end
    end
end
endmodule