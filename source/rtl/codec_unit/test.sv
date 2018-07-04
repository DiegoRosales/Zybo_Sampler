i2s_controller i2s_controller_inst (
   // Input Ports - Single Bit
   .clk        (clk),     
   .data_wr    (data_wr), 
   .reset      (reset),   
   // Input Ports - Busses
   .data[47:0] (data[47:0]),
   // Output Ports - Single Bit
   .busy       (busy),    
   .i2s_bclk   (i2s_bclk),
   .i2s_data   (i2s_data),
   .i2s_wclk   (i2s_wclk)
   // Output Ports - Busses
   // InOut Ports - Single Bit
   // InOut Ports - Busses
);
