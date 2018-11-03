// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.4.1 (win64) Build 2117270 Tue Jan 30 15:32:00 MST 2018
// Date        : Sat Oct 27 15:43:50 2018
// Host        : DESKTOP-AFP64EE running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               D:/FPGA/Xilinx/audio_sampler/source/generated_ips/codec_audio_clock_generator/codec_audio_clock_generator_sim_netlist.v
// Design      : codec_audio_clock_generator
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7z010iclg225-1L
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* NotValidForBitStream *)
module codec_audio_clock_generator
   (codec_mclk,
    reset,
    locked,
    clock_in_125);
  output codec_mclk;
  input reset;
  output locked;
  input clock_in_125;

  wire clock_in_125;
  wire codec_mclk;
  wire locked;
  wire reset;

  codec_audio_clock_generator_codec_audio_clock_generator_clk_wiz inst
       (.clock_in_125(clock_in_125),
        .codec_mclk(codec_mclk),
        .locked(locked),
        .reset(reset));
endmodule

(* ORIG_REF_NAME = "codec_audio_clock_generator_clk_wiz" *) 
module codec_audio_clock_generator_codec_audio_clock_generator_clk_wiz
   (codec_mclk,
    reset,
    locked,
    clock_in_125);
  output codec_mclk;
  input reset;
  output locked;
  input clock_in_125;

  wire clkfbout_buf_codec_audio_clock_generator;
  wire clkfbout_codec_audio_clock_generator;
  wire clock_in_125;
  wire clock_in_125_codec_audio_clock_generator;
  wire codec_mclk;
  wire codec_mclk_codec_audio_clock_generator;
  wire codec_mclk_codec_audio_clock_generator_en_clk;
  wire locked;
  wire reset;
  (* RTL_KEEP = "true" *) (* async_reg = "true" *) wire [7:0]seq_reg1;
  wire NLW_plle2_adv_inst_CLKOUT1_UNCONNECTED;
  wire NLW_plle2_adv_inst_CLKOUT2_UNCONNECTED;
  wire NLW_plle2_adv_inst_CLKOUT3_UNCONNECTED;
  wire NLW_plle2_adv_inst_CLKOUT4_UNCONNECTED;
  wire NLW_plle2_adv_inst_CLKOUT5_UNCONNECTED;
  wire NLW_plle2_adv_inst_DRDY_UNCONNECTED;
  wire [15:0]NLW_plle2_adv_inst_DO_UNCONNECTED;

  (* BOX_TYPE = "PRIMITIVE" *) 
  BUFG clkf_buf
       (.I(clkfbout_codec_audio_clock_generator),
        .O(clkfbout_buf_codec_audio_clock_generator));
  (* BOX_TYPE = "PRIMITIVE" *) 
  BUFG clkin1_bufg
       (.I(clock_in_125),
        .O(clock_in_125_codec_audio_clock_generator));
  (* BOX_TYPE = "PRIMITIVE" *) 
  (* XILINX_LEGACY_PRIM = "BUFGCE" *) 
  (* XILINX_TRANSFORM_PINMAP = "CE:CE0 I:I0" *) 
  BUFGCTRL #(
    .INIT_OUT(0),
    .PRESELECT_I0("TRUE"),
    .PRESELECT_I1("FALSE")) 
    clkout1_buf
       (.CE0(seq_reg1[7]),
        .CE1(1'b0),
        .I0(codec_mclk_codec_audio_clock_generator),
        .I1(1'b1),
        .IGNORE0(1'b0),
        .IGNORE1(1'b1),
        .O(codec_mclk),
        .S0(1'b1),
        .S1(1'b0));
  (* BOX_TYPE = "PRIMITIVE" *) 
  BUFH clkout1_buf_en
       (.I(codec_mclk_codec_audio_clock_generator),
        .O(codec_mclk_codec_audio_clock_generator_en_clk));
  (* BOX_TYPE = "PRIMITIVE" *) 
  PLLE2_ADV #(
    .BANDWIDTH("HIGH"),
    .CLKFBOUT_MULT(12),
    .CLKFBOUT_PHASE(0.000000),
    .CLKIN1_PERIOD(8.000000),
    .CLKIN2_PERIOD(0.000000),
    .CLKOUT0_DIVIDE(125),
    .CLKOUT0_DUTY_CYCLE(0.500000),
    .CLKOUT0_PHASE(0.000000),
    .CLKOUT1_DIVIDE(1),
    .CLKOUT1_DUTY_CYCLE(0.500000),
    .CLKOUT1_PHASE(0.000000),
    .CLKOUT2_DIVIDE(1),
    .CLKOUT2_DUTY_CYCLE(0.500000),
    .CLKOUT2_PHASE(0.000000),
    .CLKOUT3_DIVIDE(1),
    .CLKOUT3_DUTY_CYCLE(0.500000),
    .CLKOUT3_PHASE(0.000000),
    .CLKOUT4_DIVIDE(1),
    .CLKOUT4_DUTY_CYCLE(0.500000),
    .CLKOUT4_PHASE(0.000000),
    .CLKOUT5_DIVIDE(1),
    .CLKOUT5_DUTY_CYCLE(0.500000),
    .CLKOUT5_PHASE(0.000000),
    .COMPENSATION("BUF_IN"),
    .DIVCLK_DIVIDE(1),
    .IS_CLKINSEL_INVERTED(1'b0),
    .IS_PWRDWN_INVERTED(1'b0),
    .IS_RST_INVERTED(1'b0),
    .REF_JITTER1(0.010000),
    .REF_JITTER2(0.010000),
    .STARTUP_WAIT("FALSE")) 
    plle2_adv_inst
       (.CLKFBIN(clkfbout_buf_codec_audio_clock_generator),
        .CLKFBOUT(clkfbout_codec_audio_clock_generator),
        .CLKIN1(clock_in_125_codec_audio_clock_generator),
        .CLKIN2(1'b0),
        .CLKINSEL(1'b1),
        .CLKOUT0(codec_mclk_codec_audio_clock_generator),
        .CLKOUT1(NLW_plle2_adv_inst_CLKOUT1_UNCONNECTED),
        .CLKOUT2(NLW_plle2_adv_inst_CLKOUT2_UNCONNECTED),
        .CLKOUT3(NLW_plle2_adv_inst_CLKOUT3_UNCONNECTED),
        .CLKOUT4(NLW_plle2_adv_inst_CLKOUT4_UNCONNECTED),
        .CLKOUT5(NLW_plle2_adv_inst_CLKOUT5_UNCONNECTED),
        .DADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .DCLK(1'b0),
        .DEN(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .DO(NLW_plle2_adv_inst_DO_UNCONNECTED[15:0]),
        .DRDY(NLW_plle2_adv_inst_DRDY_UNCONNECTED),
        .DWE(1'b0),
        .LOCKED(locked),
        .PWRDWN(1'b0),
        .RST(reset));
  (* ASYNC_REG *) 
  FDCE #(
    .INIT(1'b0)) 
    \seq_reg1_reg[0] 
       (.C(codec_mclk_codec_audio_clock_generator_en_clk),
        .CE(1'b1),
        .CLR(reset),
        .D(locked),
        .Q(seq_reg1[0]));
  (* ASYNC_REG *) 
  FDCE #(
    .INIT(1'b0)) 
    \seq_reg1_reg[1] 
       (.C(codec_mclk_codec_audio_clock_generator_en_clk),
        .CE(1'b1),
        .CLR(reset),
        .D(seq_reg1[0]),
        .Q(seq_reg1[1]));
  (* ASYNC_REG *) 
  FDCE #(
    .INIT(1'b0)) 
    \seq_reg1_reg[2] 
       (.C(codec_mclk_codec_audio_clock_generator_en_clk),
        .CE(1'b1),
        .CLR(reset),
        .D(seq_reg1[1]),
        .Q(seq_reg1[2]));
  (* ASYNC_REG *) 
  FDCE #(
    .INIT(1'b0)) 
    \seq_reg1_reg[3] 
       (.C(codec_mclk_codec_audio_clock_generator_en_clk),
        .CE(1'b1),
        .CLR(reset),
        .D(seq_reg1[2]),
        .Q(seq_reg1[3]));
  (* ASYNC_REG *) 
  FDCE #(
    .INIT(1'b0)) 
    \seq_reg1_reg[4] 
       (.C(codec_mclk_codec_audio_clock_generator_en_clk),
        .CE(1'b1),
        .CLR(reset),
        .D(seq_reg1[3]),
        .Q(seq_reg1[4]));
  (* ASYNC_REG *) 
  FDCE #(
    .INIT(1'b0)) 
    \seq_reg1_reg[5] 
       (.C(codec_mclk_codec_audio_clock_generator_en_clk),
        .CE(1'b1),
        .CLR(reset),
        .D(seq_reg1[4]),
        .Q(seq_reg1[5]));
  (* ASYNC_REG *) 
  FDCE #(
    .INIT(1'b0)) 
    \seq_reg1_reg[6] 
       (.C(codec_mclk_codec_audio_clock_generator_en_clk),
        .CE(1'b1),
        .CLR(reset),
        .D(seq_reg1[5]),
        .Q(seq_reg1[6]));
  (* ASYNC_REG *) 
  FDCE #(
    .INIT(1'b0)) 
    \seq_reg1_reg[7] 
       (.C(codec_mclk_codec_audio_clock_generator_en_clk),
        .CE(1'b1),
        .CLR(reset),
        .D(seq_reg1[6]),
        .Q(seq_reg1[7]));
endmodule
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

endmodule
`endif