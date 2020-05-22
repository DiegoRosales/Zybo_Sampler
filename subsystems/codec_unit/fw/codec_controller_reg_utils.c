//////////////////////////////////////////////////////////////
// Utilities to read/write registers from de CODEC Controller
//////////////////////////////////////////////////////////////

// Xilinx Includes
#include "xparameters.h"
#include "xil_printf.h"
#include "xil_io.h"

// CODEC Includes
#include "codec_controller_control_regs.h"
#include "codec_controller_reg_utils.h"

uint32_t ulCodecCtrlRegWr(uint32_t addr, uint32_t value, uint32_t check, uint32_t display) {
	uint32_t readback  = 0;
	uint32_t ok        = 0;
	uint32_t full_addr = CODEC_CONTROLLER_REGISTERS_BAR + (addr*4);

	if(display) {
		xil_printf("CODEC_CTRL_REG[0x%02x] <--- 0x%08x\n\r", addr, value);
		if (!check) {
			xil_printf("\n\r");
		}
	}

	Xil_Out32(full_addr, value);

	if(check) {
		readback = Xil_In32(full_addr);
		ok       = (readback == value);
		if (display) {
			if (ok) {
				xil_printf("Readback - OK\n\n\r");
			} else {
				xil_printf("Readback - ERROR\n\r");
				xil_printf("Readback = 0x%08x\n\n\r", readback);
			}
		}
	}

	return ok;
}

uint32_t ulCodecCtrlRegRd(uint32_t addr, uint32_t display) {
	uint32_t readback  = 0;
	uint32_t full_addr = CODEC_CONTROLLER_REGISTERS_BAR + (addr*4);

	readback = Xil_In32(full_addr);
	if (display) {
		xil_printf("CODEC_CTRL_REG[0x%02x] = 0x%08x\n\n\r", (addr*4), readback);
	}

	return readback;
}
