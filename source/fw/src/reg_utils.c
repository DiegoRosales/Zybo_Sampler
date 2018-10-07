#include "reg_utils.h"

int RegWr(int addr, int value, int check, int display) {
	int readback  = 0;
	int ok        = 0;
	int full_addr = REGISTERS_BAR + (addr*4);

	if(display) {
		xil_printf("REG[0x%02x] <--- 0x%08x\n\r", addr, value);
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

int RegRd(int addr, int display) {
	int readback  = 0;
	int full_addr = REGISTERS_BAR + (addr*4);

	readback = Xil_In32(full_addr);
	if (display) {
		xil_printf("REG[0x%02x] = 0x%08x\n\n\r", (addr*4), readback);
	}

	return readback;
}