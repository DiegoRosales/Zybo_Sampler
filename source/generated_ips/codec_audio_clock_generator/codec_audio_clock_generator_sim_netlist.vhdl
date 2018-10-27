-- Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2017.4.1 (win64) Build 2117270 Tue Jan 30 15:32:00 MST 2018
-- Date        : Sat Oct 27 15:43:50 2018
-- Host        : DESKTOP-AFP64EE running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode funcsim
--               D:/FPGA/Xilinx/audio_sampler/source/generated_ips/codec_audio_clock_generator/codec_audio_clock_generator_sim_netlist.vhdl
-- Design      : codec_audio_clock_generator
-- Purpose     : This VHDL netlist is a functional simulation representation of the design and should not be modified or
--               synthesized. This netlist cannot be used for SDF annotated simulation.
-- Device      : xc7z010iclg225-1L
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity codec_audio_clock_generator_codec_audio_clock_generator_clk_wiz is
  port (
    codec_mclk : out STD_LOGIC;
    reset : in STD_LOGIC;
    locked : out STD_LOGIC;
    clock_in_125 : in STD_LOGIC
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of codec_audio_clock_generator_codec_audio_clock_generator_clk_wiz : entity is "codec_audio_clock_generator_clk_wiz";
end codec_audio_clock_generator_codec_audio_clock_generator_clk_wiz;

architecture STRUCTURE of codec_audio_clock_generator_codec_audio_clock_generator_clk_wiz is
  signal clkfbout_buf_codec_audio_clock_generator : STD_LOGIC;
  signal clkfbout_codec_audio_clock_generator : STD_LOGIC;
  signal clock_in_125_codec_audio_clock_generator : STD_LOGIC;
  signal codec_mclk_codec_audio_clock_generator : STD_LOGIC;
  signal codec_mclk_codec_audio_clock_generator_en_clk : STD_LOGIC;
  signal \^locked\ : STD_LOGIC;
  signal seq_reg1 : STD_LOGIC_VECTOR ( 7 downto 0 );
  attribute RTL_KEEP : string;
  attribute RTL_KEEP of seq_reg1 : signal is "true";
  attribute async_reg : string;
  attribute async_reg of seq_reg1 : signal is "true";
  signal NLW_plle2_adv_inst_CLKOUT1_UNCONNECTED : STD_LOGIC;
  signal NLW_plle2_adv_inst_CLKOUT2_UNCONNECTED : STD_LOGIC;
  signal NLW_plle2_adv_inst_CLKOUT3_UNCONNECTED : STD_LOGIC;
  signal NLW_plle2_adv_inst_CLKOUT4_UNCONNECTED : STD_LOGIC;
  signal NLW_plle2_adv_inst_CLKOUT5_UNCONNECTED : STD_LOGIC;
  signal NLW_plle2_adv_inst_DRDY_UNCONNECTED : STD_LOGIC;
  signal NLW_plle2_adv_inst_DO_UNCONNECTED : STD_LOGIC_VECTOR ( 15 downto 0 );
  attribute BOX_TYPE : string;
  attribute BOX_TYPE of clkf_buf : label is "PRIMITIVE";
  attribute BOX_TYPE of clkin1_bufg : label is "PRIMITIVE";
  attribute BOX_TYPE of clkout1_buf : label is "PRIMITIVE";
  attribute XILINX_LEGACY_PRIM : string;
  attribute XILINX_LEGACY_PRIM of clkout1_buf : label is "BUFGCE";
  attribute XILINX_TRANSFORM_PINMAP : string;
  attribute XILINX_TRANSFORM_PINMAP of clkout1_buf : label is "CE:CE0 I:I0";
  attribute BOX_TYPE of clkout1_buf_en : label is "PRIMITIVE";
  attribute BOX_TYPE of plle2_adv_inst : label is "PRIMITIVE";
  attribute ASYNC_REG_boolean : boolean;
  attribute ASYNC_REG_boolean of \seq_reg1_reg[0]\ : label is std.standard.true;
  attribute ASYNC_REG_boolean of \seq_reg1_reg[1]\ : label is std.standard.true;
  attribute ASYNC_REG_boolean of \seq_reg1_reg[2]\ : label is std.standard.true;
  attribute ASYNC_REG_boolean of \seq_reg1_reg[3]\ : label is std.standard.true;
  attribute ASYNC_REG_boolean of \seq_reg1_reg[4]\ : label is std.standard.true;
  attribute ASYNC_REG_boolean of \seq_reg1_reg[5]\ : label is std.standard.true;
  attribute ASYNC_REG_boolean of \seq_reg1_reg[6]\ : label is std.standard.true;
  attribute ASYNC_REG_boolean of \seq_reg1_reg[7]\ : label is std.standard.true;
begin
  locked <= \^locked\;
clkf_buf: unisim.vcomponents.BUFG
     port map (
      I => clkfbout_codec_audio_clock_generator,
      O => clkfbout_buf_codec_audio_clock_generator
    );
clkin1_bufg: unisim.vcomponents.BUFG
     port map (
      I => clock_in_125,
      O => clock_in_125_codec_audio_clock_generator
    );
clkout1_buf: unisim.vcomponents.BUFGCTRL
    generic map(
      INIT_OUT => 0,
      PRESELECT_I0 => true,
      PRESELECT_I1 => false
    )
        port map (
      CE0 => seq_reg1(7),
      CE1 => '0',
      I0 => codec_mclk_codec_audio_clock_generator,
      I1 => '1',
      IGNORE0 => '0',
      IGNORE1 => '1',
      O => codec_mclk,
      S0 => '1',
      S1 => '0'
    );
clkout1_buf_en: unisim.vcomponents.BUFH
     port map (
      I => codec_mclk_codec_audio_clock_generator,
      O => codec_mclk_codec_audio_clock_generator_en_clk
    );
plle2_adv_inst: unisim.vcomponents.PLLE2_ADV
    generic map(
      BANDWIDTH => "HIGH",
      CLKFBOUT_MULT => 12,
      CLKFBOUT_PHASE => 0.000000,
      CLKIN1_PERIOD => 8.000000,
      CLKIN2_PERIOD => 0.000000,
      CLKOUT0_DIVIDE => 125,
      CLKOUT0_DUTY_CYCLE => 0.500000,
      CLKOUT0_PHASE => 0.000000,
      CLKOUT1_DIVIDE => 1,
      CLKOUT1_DUTY_CYCLE => 0.500000,
      CLKOUT1_PHASE => 0.000000,
      CLKOUT2_DIVIDE => 1,
      CLKOUT2_DUTY_CYCLE => 0.500000,
      CLKOUT2_PHASE => 0.000000,
      CLKOUT3_DIVIDE => 1,
      CLKOUT3_DUTY_CYCLE => 0.500000,
      CLKOUT3_PHASE => 0.000000,
      CLKOUT4_DIVIDE => 1,
      CLKOUT4_DUTY_CYCLE => 0.500000,
      CLKOUT4_PHASE => 0.000000,
      CLKOUT5_DIVIDE => 1,
      CLKOUT5_DUTY_CYCLE => 0.500000,
      CLKOUT5_PHASE => 0.000000,
      COMPENSATION => "BUF_IN",
      DIVCLK_DIVIDE => 1,
      IS_CLKINSEL_INVERTED => '0',
      IS_PWRDWN_INVERTED => '0',
      IS_RST_INVERTED => '0',
      REF_JITTER1 => 0.010000,
      REF_JITTER2 => 0.010000,
      STARTUP_WAIT => "FALSE"
    )
        port map (
      CLKFBIN => clkfbout_buf_codec_audio_clock_generator,
      CLKFBOUT => clkfbout_codec_audio_clock_generator,
      CLKIN1 => clock_in_125_codec_audio_clock_generator,
      CLKIN2 => '0',
      CLKINSEL => '1',
      CLKOUT0 => codec_mclk_codec_audio_clock_generator,
      CLKOUT1 => NLW_plle2_adv_inst_CLKOUT1_UNCONNECTED,
      CLKOUT2 => NLW_plle2_adv_inst_CLKOUT2_UNCONNECTED,
      CLKOUT3 => NLW_plle2_adv_inst_CLKOUT3_UNCONNECTED,
      CLKOUT4 => NLW_plle2_adv_inst_CLKOUT4_UNCONNECTED,
      CLKOUT5 => NLW_plle2_adv_inst_CLKOUT5_UNCONNECTED,
      DADDR(6 downto 0) => B"0000000",
      DCLK => '0',
      DEN => '0',
      DI(15 downto 0) => B"0000000000000000",
      DO(15 downto 0) => NLW_plle2_adv_inst_DO_UNCONNECTED(15 downto 0),
      DRDY => NLW_plle2_adv_inst_DRDY_UNCONNECTED,
      DWE => '0',
      LOCKED => \^locked\,
      PWRDWN => '0',
      RST => reset
    );
\seq_reg1_reg[0]\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
        port map (
      C => codec_mclk_codec_audio_clock_generator_en_clk,
      CE => '1',
      CLR => reset,
      D => \^locked\,
      Q => seq_reg1(0)
    );
\seq_reg1_reg[1]\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
        port map (
      C => codec_mclk_codec_audio_clock_generator_en_clk,
      CE => '1',
      CLR => reset,
      D => seq_reg1(0),
      Q => seq_reg1(1)
    );
\seq_reg1_reg[2]\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
        port map (
      C => codec_mclk_codec_audio_clock_generator_en_clk,
      CE => '1',
      CLR => reset,
      D => seq_reg1(1),
      Q => seq_reg1(2)
    );
\seq_reg1_reg[3]\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
        port map (
      C => codec_mclk_codec_audio_clock_generator_en_clk,
      CE => '1',
      CLR => reset,
      D => seq_reg1(2),
      Q => seq_reg1(3)
    );
\seq_reg1_reg[4]\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
        port map (
      C => codec_mclk_codec_audio_clock_generator_en_clk,
      CE => '1',
      CLR => reset,
      D => seq_reg1(3),
      Q => seq_reg1(4)
    );
\seq_reg1_reg[5]\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
        port map (
      C => codec_mclk_codec_audio_clock_generator_en_clk,
      CE => '1',
      CLR => reset,
      D => seq_reg1(4),
      Q => seq_reg1(5)
    );
\seq_reg1_reg[6]\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
        port map (
      C => codec_mclk_codec_audio_clock_generator_en_clk,
      CE => '1',
      CLR => reset,
      D => seq_reg1(5),
      Q => seq_reg1(6)
    );
\seq_reg1_reg[7]\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
        port map (
      C => codec_mclk_codec_audio_clock_generator_en_clk,
      CE => '1',
      CLR => reset,
      D => seq_reg1(6),
      Q => seq_reg1(7)
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity codec_audio_clock_generator is
  port (
    codec_mclk : out STD_LOGIC;
    reset : in STD_LOGIC;
    locked : out STD_LOGIC;
    clock_in_125 : in STD_LOGIC
  );
  attribute NotValidForBitStream : boolean;
  attribute NotValidForBitStream of codec_audio_clock_generator : entity is true;
end codec_audio_clock_generator;

architecture STRUCTURE of codec_audio_clock_generator is
begin
inst: entity work.codec_audio_clock_generator_codec_audio_clock_generator_clk_wiz
     port map (
      clock_in_125 => clock_in_125,
      codec_mclk => codec_mclk,
      locked => locked,
      reset => reset
    );
end STRUCTURE;
