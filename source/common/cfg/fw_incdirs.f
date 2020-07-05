####################
## Sampler DMA Unit Firmware include directories
####################

## Include Directories
set common_incdir {
    FreeRTOS-Plus-CLI
    FreeRTOS-Plus-FAT/include
    ZyboCLI
    ZyboSD
    nco
    jsmn
    sampler/include
}

## Pointers to make a softlink
set fwdir {
    {common ${core_root}/fw/src}
}