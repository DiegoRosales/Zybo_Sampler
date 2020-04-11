####################
## codec_unit RTL filelist
####################

set synthesis_file_list {
    ${core_root}/rtl/sampler_dma_top.sv
    ${core_root}/rtl/sampler_dma_registers.sv
    ${core_root}/rtl/sample_info_fetcher.sv
    ${core_root}/rtl/sample_dma_requester.sv
    ${core_root}/rtl/sample_dma_receiver.sv
    ${core_root}/rtl/axi_dma_bridge.sv
}