########################################
## Physical constraints
########################################

## Bad board design - the pin used for this clock is meant for the 'N' side of a differential clock
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets codec_i2s_bclk_IBUF]

## Synchronizers
set_property ASYNC_REG 1 [get_cells -hierarchical "*data_sync_out*"]