# Codec Controller Unit

On a high-level this unit has 3 functions

1) Provide the CODEC a Master Clock
2) Forward the PCM data from the input AXI Stream interface to the CODEC using the I2S protocol
3) Provide an AXI bridge to access the internal registers of the CODEC