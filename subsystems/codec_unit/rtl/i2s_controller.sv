module i2s_controller(
  input wire clk,
  input wire reset_n,

  input wire [47:0] data,
  input wire data_wr,

  output wire data_rd,

  output wire i2s_bclk,
  output wire i2s_wclk,
  output wire i2s_data
  );

reg [47:0] data_reg;

reg wclk_current;
wire wclk_next;

reg [5:0] count_current;
wire [5:0] count_next;

reg data_rd_reg;

// Internal assignments
assign count_next = count_current + 1'b1;

// Outputs
assign i2s_wclk = wclk_current;
assign i2s_data = data_reg[0];
assign i2s_bclk = clk;
assign data_rd = data_rd_reg;

// Counter logic
always @ (posedge clk or negedge reset_n)
begin
  if (reset_n == 1'b0) begin
    count_current <= 6'b000000;
  end
  else if (clk == 1'b1) begin
    count_current <= count_current + 1;
    if (count_next == 48) begin
      count_current <= 6'b000000;
    end //if (count_next <= 48) begin
  end //if (clk == 1'b1) begin
end

// WCLK logic
always @ (posedge clk or negedge reset_n)
begin
  if (reset_n == 1'b0) begin
    wclk_current <= 1'b0;
  end
  else if (clk == 1'b1) begin
    wclk_current <= wclk_current;
    if (count_current == 47) begin
      wclk_current <= 1'b0;
    end
    else if (count_current == 23) begin
      wclk_current <= 1'b1;
    end //if (count_current == 0) begin
  end //if (clk == 1'b1) begin
end

// Data logic
always @ (posedge clk or negedge reset_n)
begin
  if (reset_n == 1'b0) begin
    data_reg <= 0;
  end
  else if (clk == 1'b1) begin
    data_reg <= {data_reg[0], data_reg[47:1]};
    if (count_current == 47) begin
      data_reg <= data;
    end
  end //if (clk == 1'b1) begin
end

// Data rd logic
always @ (posedge clk or negedge reset_n)
begin
  if (clk == 1'b1) begin
    if (reset_n == 1'b0) begin
      data_rd_reg <= 1'b0;
    end
    else begin
      data_rd_reg <= 1'b0;
      if (count_current == 46) begin
        data_rd_reg <= 1'b1;
      end
    end //if (reset_n == 1'b0) begin
  end //if (clk == 1'b1) begin
end

/*begin
  if (clk == 1'b1) begin
    if (reset_n == 1'b0) begin
      output_data <= 48'h000000000000;
      count_current <= 5'h00;
      busy_reg <= 1'b1;
    end
    else begin
      count_current <= count_next;
      busy_reg <= 1'b0;
      if (data_wr == 1'b1) begin
        output_data <= data;
        count_current <= 5'h00;
        busy_reg <= 1'b1;
      end
      else begin
        if (count_current != 5'b11111) begin
          output_data <= output_data >> 1;//{output_data[0], output_data[47:1]};
          if (count_current )
          busy_reg <= 1'b1;
        end //if (count_current != 5'b11111) begin
      end //if (data_wr == 1'b1) begin
    end //if (reset_n == 1'b0) begin
  end //if (clk == 1'b1) begin
end*/

endmodule
