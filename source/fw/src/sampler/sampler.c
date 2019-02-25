////////////////////////////////////////////////////////
// Sampler Driver
////////////////////////////////////////////////////////
// Xilinx Includes
#include "xil_io.h"

//information about AXI peripherals
#include "xparameters.h"

#include "sampler.h"

uint32_t SamplerRegWr(uint32_t addr, uint32_t value, uint32_t check) {
	uint32_t readback  = 0;
	uint32_t ok        = 0;
	uint32_t full_addr = SAMPLER_BASE_ADDR + (addr*4);

	Xil_Out32(full_addr, value);

	if(check) {
		readback = Xil_In32(full_addr);
		ok       = (readback == value);
	}

	return ok;
}

uint32_t SamplerRegRd(uint32_t addr) {
	uint32_t readback  = 0;
	uint32_t full_addr = SAMPLER_BASE_ADDR + (addr*4);

	readback = Xil_In32(full_addr);

	return readback;
}

uint32_t get_sampler_version( void ) {
	return SAMPLER_CONTROL_REGISTER_ACCESS->SAMPLER_VER_REG_REG.value;
}