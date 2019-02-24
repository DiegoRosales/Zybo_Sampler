////////////////////////////////////////////////////////
// Sampler Driver
////////////////////////////////////////////////////////
// Xilinx Includes
#include "xil_io.h"

//information about AXI peripherals
#include "xparameters.h"

#include "sampler.h"

int SamplerRegWr(int addr, int value, int check) {
	int readback  = 0;
	int ok        = 0;
	int full_addr = SAMPLER_BASE_ADDR + (addr*4);

	Xil_Out32(full_addr, value);

	if(check) {
		readback = Xil_In32(full_addr);
		ok       = (readback == value);
	}

	return ok;
}

int SamplerRegRd(int addr) {
	int readback  = 0;
	int full_addr = SAMPLER_BASE_ADDR + (addr*4);

	readback = Xil_In32(full_addr);

	return readback;
}