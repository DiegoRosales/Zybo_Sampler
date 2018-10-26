
#include "codec_utils.h"

int CodecRd(int addr, int display, int debug) {
	int data_rd   = 0;

	// Step 1 - Write the Address
	if (debug) xil_printf("Reading CODEC Registet %02x\n\r", addr);
	if (debug) xil_printf("Writing the CODEC Address to register\n\r", addr);
	RegWr(CODEC_I2C_ADDR_REG_ADDR, addr, 1, debug);

	// Step 2 - Set the RD bit
	if (debug) xil_printf("Setting the RD bit...\n\r", addr);
	RegWr(CODEC_I2C_CTRL_REG_ADDR, RD_DATA_BIT, 0, debug);

	// Step 3 - Wait for the Busy bit to clear
	if (debug) xil_printf("Waiting for the transfer to complete\n\r", addr);
	BusyBitIsClear(debug);

	WaitUntilDataIsAvailable(debug);

	for(int i = 0; i < 100; i++);

	// Step 4 - Read the data
	data_rd = RegRd(CODEC_I2C_RD_DATA_REG_ADDR, debug);
	if (display | debug) xil_printf("CODEC Register[%02x] = 0x%02x\n\r", addr, data_rd);

	return data_rd;
}

int CodecWr(int addr, int data, int check, int display, int debug) {
	int readback = 0;
	int ok       = 1;

	// Step 1 - Write the Address
	if (debug) xil_printf("Reading CODEC Registet %02x\n\r", addr);
	if (debug) xil_printf("Writing the CODEC Address to register\n\r", addr);
	RegWr(CODEC_I2C_ADDR_REG_ADDR, addr, 0, debug);

	// Step 2 - Write the Data
	if (debug | display)  xil_printf("CODEC Register[%02x] <---- 0x%02x\n\r", addr, data);
	RegWr(CODEC_I2C_WR_DATA_REG_ADDR, data, 0, debug);

	// Step 3 - Set the WR bit
	if (debug) xil_printf("Setting the WR bit...\n\r", addr);

	RegWr(CODEC_I2C_CTRL_REG_ADDR, WR_DATA_BIT, 0, debug);

	// Step 4 - Wait for the Busy bit to clear
	if (debug) xil_printf("Waiting for the transfer to complete\n\r", addr);
	BusyBitIsClear(debug);

	// Step 5 (optional) - Read back the data
	if (check) {
		readback = CodecRd(addr, 1, debug);
		if (data == readback){
			if (debug | display) xil_printf("OK\n\r", addr, readback);
		} else {
			if (debug | display){
				xil_printf("Readback - ERROR\n\r");
				xil_printf("Readback = 0x%02x\n\n\r", readback);
			}
		}
	}

	return ok;
}

void WaitUntilDataIsAvailable(int debug) {
	int data_is_available = 0;
	int xfer_done         = 0;

	// Wait until the data_is_available bit is 1
	do {
		xfer_done         = RegRd(CODEC_I2C_CTRL_REG_ADDR, debug);
		data_is_available = (xfer_done >> 4) & 0x1;
	} while (data_is_available == 0);
	//xil_printf("xfer_done = 0x%08x\n\t", xfer_done);
	// Clear that bit
	RegWr(CODEC_I2C_CTRL_REG_ADDR, 0x10, 0, debug);
}

void BusyBitIsClear(int debug) {
	int busy      = 0;
	int xfer_done = 0;
	do {
		xfer_done = RegRd(CODEC_I2C_CTRL_REG_ADDR, debug);
		busy      = (xfer_done >> 2) & 0x1;
	} while (busy == 1);
}

void ControllerReset(int debug) {
	int reset_status = 0;
	RegWr(CODEC_I2C_CTRL_REG_ADDR, (1 << CONTROLLER_RESET_BIT), 0, debug);
	do {
		reset_status = RegRd(CODEC_I2C_CTRL_REG_ADDR, debug);
		reset_status = (reset_status >> CONTROLLER_RESET_BIT) & 0x1;
	} while (reset_status == 1);
}