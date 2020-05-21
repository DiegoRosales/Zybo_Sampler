// Xilinx Includes
#include "xparameters.h"
#include "xil_printf.h"
#include "xil_io.h"

// Sampler DMA Includes
#include "sampler_dma_controller_regs.h"
#include "sampler_dma_controller_reg_utils.h"


uint32_t ulSamplerRegWr(uint32_t addr, uint32_t value, uint32_t check) {
    uint32_t readback  = 0;
    uint32_t ok        = 0;
    uint32_t full_addr = GET_SAMPLER_FULL_ADDR(addr);

    Xil_Out32(full_addr, value);

    if(check) {
        readback = Xil_In32(full_addr);
        ok       = (readback == value);
    }

    return ok;
}

uint32_t ulSamplerRegRd(uint32_t addr) {
    uint32_t readback  = 0;
    uint32_t full_addr = GET_SAMPLER_FULL_ADDR(addr);

    readback = Xil_In32(full_addr);

    return readback;
}

uint32_t ulGetDMAEngineHWVersion( void ) {
    return SAMPLER_CONTROL_REGISTER_ACCESS->SAMPLER_VER_REG.value;
}
