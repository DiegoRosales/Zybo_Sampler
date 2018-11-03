
#include "codec_utils.h"

int CodecRd(int addr, int display, int debug) {
	int data_rd = 0;
	int status  = 0;

	// Step 0 - Check if there are no other transactions running. If there are none, clear all the Status bits
	status = RegRd(CODEC_I2C_CTRL_REG_ADDR, debug);
	if ((status & BUSY_BIT) != 0) {
		xil_printf("============\n\r");
		xil_printf("[ERROR] There is another transaction going on...\n\r");
		xil_printf("============\n\r");
		return 0xffffffff;
	}
	ClearStatusBits(debug);

	// Step 1 - Write the Address
	if (debug) xil_printf("-------------\n\r", addr);
	if (debug) xil_printf("Reading CODEC Register %02x\n\n\r", addr);
	if (debug) xil_printf("Writing the CODEC Address to register\n\r", addr);
	RegWr(CODEC_I2C_ADDR_REG_ADDR, addr, 1, debug);

	// Step 2 - Set the RD bit
	if (debug) xil_printf("Setting the RD bit...\n\r", addr);
	RegWr(CODEC_I2C_CTRL_REG_ADDR, RD_DATA_BIT, 0, debug);

	// Step 3 - Wait for the Busy bit to clear
	BusyBitIsClear(debug);

	WaitUntilDataIsAvailable(debug);

	// Step 4 - Read the data
	if (debug) xil_printf("Reading the Data from the Register...\n\r", addr);
	data_rd = RegRd(CODEC_I2C_RD_DATA_REG_ADDR, debug);
	if (display | debug) xil_printf("CODEC Register[%02x] = 0x%02x\n\r", addr, data_rd);
	if (debug) xil_printf("-------------\n\r", addr);
	return data_rd;
}

int CodecWr(int addr, int data, int check, int display, int debug) {
	int readback = 0;
	int ok       = 1;
	int status   = 0;
	
	// Step 0 - Check if there are no other transactions running. If there are none, clear all the Status bits
	status = RegRd(CODEC_I2C_CTRL_REG_ADDR, debug);
	if ((status & BUSY_BIT) != 0) {
		xil_printf("============\n\r");
		xil_printf("[ERROR] There is another transaction going on...\n\r");
		xil_printf("============\n\r");
		return 0xffffffff;
	}

	if (debug) xil_printf("===============\n\r", addr);
	ClearStatusBits(debug);
	if (debug | display)  xil_printf("CODEC Register[%02x] <---- 0x%02x\n\r", addr, data);

	// Step 1 - Write the Address
	if (debug) xil_printf("Writing the CODEC Address to the register\n\r");
	RegWr(CODEC_I2C_ADDR_REG_ADDR, addr, 0, debug);

	// Step 2 - Write the Data
	if (debug) xil_printf("Writing the CODEC Data to the register\n\r");
	RegWr(CODEC_I2C_WR_DATA_REG_ADDR, data, 0, debug);

	// Step 3 - Set the WR bit
	if (debug) xil_printf("Setting the WR bit...\n\r");

	RegWr(CODEC_I2C_CTRL_REG_ADDR, WR_DATA_BIT, 0, debug);

	// Step 4 - Wait for the Busy bit to clear
	if (debug) xil_printf("Waiting for the transfer to complete\n\r");
	BusyBitIsClear(debug);

	// Step 5 (optional) - Read back the data
	if (check) {
		if (debug) xil_printf("Performing Readback...\n\r");
		readback = CodecRd(addr, 1, debug);
		if (data == readback){
			if (debug | display) xil_printf("OK\n\r");
		} else {
			if (debug | display){
				xil_printf("Check ERROR!\n\r");
				xil_printf("Readback = 0x%02x\n\n\r", readback);
			}
		}
	}

	if (debug) xil_printf("===============\n\r", addr);
	return ok;
}

void ClearStatusBits(debug) {
	int status = 0;
	if (debug) xil_printf("Clearing the Status Bits...\n\r");

	status = RegRd(CODEC_I2C_CTRL_REG_ADDR, debug);
	RegWr(CODEC_I2C_CTRL_REG_ADDR, status, 0, debug);
	status = RegRd(CODEC_I2C_CTRL_REG_ADDR, debug);
	xil_printf("Done!\n\r");

}

void WaitUntilDataIsAvailable(int debug) {
	int data_is_available = 0;
	int missed_ack        = 0;
	int xfer_done         = 0;

	if (debug) xil_printf("Waiting for the valid data bit...\n\r");
	// Wait until the data_is_available bit is 1
	do {
		xfer_done         = RegRd(CODEC_I2C_CTRL_REG_ADDR, debug);
		data_is_available = (xfer_done >> 4) & 0x1;
		missed_ack        = (xfer_done >> 5) & 0x1;
		if (missed_ack) {
			xil_printf("====== MISSED ACK!!! ======\n\r");
		}
	} while (data_is_available == 0);
	if (debug) xil_printf("Got valid data. Clearing the bit...\n\r");
	// Clear that bit
	RegWr(CODEC_I2C_CTRL_REG_ADDR, 0x10, 0, debug);
	if (debug) xil_printf("Bit is clear!\n\r");
}

void BusyBitIsClear(int debug) {
	int busy      = 0;
	int xfer_done = 0;
	if (debug) xil_printf("Waiting for the transfer to complete...\n\r");
	do {
		xfer_done = RegRd(CODEC_I2C_CTRL_REG_ADDR, debug);
		busy      = (xfer_done >> 2) & 0x1;
	} while (busy == 1);
	if (debug) xil_printf("Busy Bit is Clear!\n\r");
}

void ControllerReset(int debug) {
	int reset_status = 0;
	RegWr(CODEC_I2C_CTRL_REG_ADDR, (1 << CONTROLLER_RESET_BIT), 0, debug);
	do {
		reset_status = RegRd(CODEC_I2C_CTRL_REG_ADDR, debug);
		reset_status = (reset_status >> CONTROLLER_RESET_BIT) & 0x1;
	} while (reset_status == 1);
}

void CodecInit(int debug) {
	int reg_value = 0;
	int readback  = 0;
	int check     = 0;
	// Configure the CODEC as Master
	xil_printf("Enabling the PM Registers\n\r");
	reg_value = CodecRd(POWER_MGMT_REG_ADDR, 1, debug);
	CodecWr(POWER_MGMT_REG_ADDR, 0x67, 1, 0, debug);
	readback = CodecRd(POWER_MGMT_REG_ADDR, 1, debug);
	if (readback != 0x67) {
		reg_value = CodecRd(POWER_MGMT_REG_ADDR, 1, debug);
		xil_printf("ERROR Setting the PM Registers\n\r");
	}
	else {
		xil_printf("Done\n\r");
	}
	

}