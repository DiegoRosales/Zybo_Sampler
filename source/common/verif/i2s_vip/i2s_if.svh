// I2S Interface definition for Verification

interface i2s_if(input ac_mclk);

  logic ac_bclk;
  logic ac_pblrc;
  logic ac_pbdat;
  logic ac_recdat;
  logic ac_reclrc;
  logic ac_muten;

endinterface //i2s_if