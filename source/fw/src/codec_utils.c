
//////////////////////////////////////////////
// Codec Uitilities
//////////////////////////////////////////////
// This section contains some useful functions
// to read and write registers from the CODEC
// as well as some initialization routines
//////////////////////////////////////////////

#include "codec_utils.h"

int CodecRd(int addr, int display, int debug) {
	int data_rd = 0;
	int status  = 0;

	// Step 0 - Check if there are no other transactions running. If there are none, clear all the Status bits
	if ( CONTROL_REGISTER_ACCESS->CODEC_I2C_CTRL_REG.field.controller_busy_reg ) {
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
	CONTROL_REGISTER_ACCESS->CODEC_I2C_ADDR_REG.value = addr;

	// Step 2 - Set the RD bit
	if (debug) xil_printf("Setting the RD bit...\n\r", addr);
	CONTROL_REGISTER_ACCESS->CODEC_I2C_CTRL_REG.field.codec_i2c_data_rd_reg = 1;

	// Step 3 - Wait for the Busy bit to clear
	BusyBitIsClear(debug);

	WaitUntilDataIsAvailable(debug);

	// Step 4 - Read the data
	if (debug) xil_printf("Reading the Data from the Register...\n\r", addr);
	data_rd = CONTROL_REGISTER_ACCESS->CODEC_I2C_RD_DATA_REG.value;

	if (display | debug) xil_printf("CODEC Register[%02x] = 0x%02x\n\r", addr, data_rd);
	if (debug) xil_printf("-------------\n\r", addr);
	return data_rd;
}

int CodecWr(int addr, int data, int check, int display, int debug) {
	int readback = 0;
	int error    = 0;
	
	// Step 0 - Check if there are no other transactions running. If there are none, clear all the Status bits
	if ( CONTROL_REGISTER_ACCESS->CODEC_I2C_CTRL_REG.field.controller_busy_reg ) {
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
	CONTROL_REGISTER_ACCESS->CODEC_I2C_ADDR_REG.value = addr;

	// Step 2 - Write the Data
	if (debug) xil_printf("Writing the CODEC Data to the register\n\r");
	CONTROL_REGISTER_ACCESS->CODEC_I2C_WR_DATA_REG.value = data;

	// Step 3 - Set the WR bit
	if (debug) xil_printf("Setting the WR bit...\n\r");
	CONTROL_REGISTER_ACCESS->CODEC_I2C_CTRL_REG.field.codec_i2c_data_wr_reg = 1;

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
			error = 1;
		}
	}

	if (debug) xil_printf("===============\n\r", addr);
	return error;
}

void ClearStatusBits(int debug) {
	int status = 0;
	if (debug) xil_printf("Clearing the Status Bits...\n\r");
	// Read the status register
	status = CONTROL_REGISTER_ACCESS->CODEC_I2C_CTRL_REG.value;
	// Write back the same value to clear the bits
	CONTROL_REGISTER_ACCESS->CODEC_I2C_CTRL_REG.value = status;
	if (debug) xil_printf("Done!\n\r");

}

void WaitUntilDataIsAvailable(int debug) {
	int data_is_available = 0;
	int missed_ack        = 0;
	CODEC_I2C_CTRL_REG_t xfer_done;

	if (debug) xil_printf("Waiting for the valid data bit...\n\r");
	// Wait until the data_is_available bit is 1
	do {
		xfer_done         = CONTROL_REGISTER_ACCESS->CODEC_I2C_CTRL_REG;
		data_is_available = xfer_done.field.data_in_valid_reg;
		missed_ack        = xfer_done.field.missed_ack_reg;
		if (missed_ack) {
			xil_printf("====== MISSED ACK!!! ======\n\r");
		}
	} while (data_is_available == 0);
	if (debug) xil_printf("Got valid data. Clearing the bit...\n\r");
	// Clear that bit
	CONTROL_REGISTER_ACCESS->CODEC_I2C_CTRL_REG.value = 0x10;
	if (debug) xil_printf("Bit is clear!\n\r");
}

void BusyBitIsClear(int debug) {
	if (debug) xil_printf("Waiting for the transfer to complete...\n\r");

	// Do nothing while the controller is busy
	while( CONTROL_REGISTER_ACCESS->CODEC_I2C_CTRL_REG.field.controller_busy_reg );

	if (debug) xil_printf("Busy Bit is Clear!\n\r");
}

void ControllerReset(int debug) {
	xil_printf("Resetting the controller...\n\r");
	// Write the reset value	
	CONTROL_REGISTER_ACCESS->CODEC_I2C_CTRL_REG.field.controller_reset_reg = 1;
	// Do nothing while the controller is in reset
	while ( CONTROL_REGISTER_ACCESS->CODEC_I2C_CTRL_REG.field.controller_reset_reg );
	xil_printf("DONE\n\r");
}

void CodecReset(int debug) {
	xil_printf("Resetting the CODEC...\n\r");
	CodecWr(SW_RESET_REG_ADDR, 0x0, 0, 1, debug);
	for (int i = 0; i < 1000000 ; i++);
	CodecWr(SW_RESET_REG_ADDR, 0x1, 0, 1, debug);
	for (int i = 0; i < 1000000 ; i++);
	xil_printf("Done\n\n\r");
}

void CodecInit(int debug) {
	int readback  = 0;
	int check     = 0;

	CODEC_REGISTERS_t codec_registers;





	// Reset the CODEC
	CodecReset(debug);

	///////////////////////////////
	// Set the PM Registers
	///////////////////////////////
	xil_printf("Enabling the PM Registers...\n\r");
	codec_registers.POWER_MANAGEMENT.value = CodecRd(POWER_MGMT_REG_ADDR, 0, debug);

	// PM Settings
	codec_registers.POWER_MANAGEMENT.value        = 0x0ff; // Initialize all powered OFF
	codec_registers.POWER_MANAGEMENT.field.DAC    = 0; // Power UP
	codec_registers.POWER_MANAGEMENT.field.CLKOUT = 0; // Power UP
	codec_registers.POWER_MANAGEMENT.field.PWROFF = 0; // Power UP
	
	check = CodecWr(POWER_MGMT_REG_ADDR, codec_registers.POWER_MANAGEMENT.value, 1, 0, debug);
	if (check) {
		CodecRd(POWER_MGMT_REG_ADDR, 1, debug);
		xil_printf("[ERROR] Setting the PM Registers\n\n\r");
	}
	else {
		xil_printf("Done\n\n\r");
	}



	for (int i = 0; i < 1000 ; i++);

	///////////////////////////////////
	// Configure the CODEC as Master
	///////////////////////////////////
	xil_printf("Setting the CODEC as master...\n\r");
	CodecRd(DIGITAL_AUDIO_IF_REG_ADDR, 0, debug);

	// Digital audio IF Settings
	codec_registers.DIGITAL_AUDIO_IF.value        = 0;   // Initialize
	codec_registers.DIGITAL_AUDIO_IF.field.Format = 0x3; // DSP Serial Mode
	codec_registers.DIGITAL_AUDIO_IF.field.LRP    = 0x1; // DSP Submode 2
	codec_registers.DIGITAL_AUDIO_IF.field.MS     = 0x1; // Master Mode
	check = CodecWr(DIGITAL_AUDIO_IF_REG_ADDR, codec_registers.DIGITAL_AUDIO_IF.value, 1, 0, debug);
	if (check) {
		CodecRd(DIGITAL_AUDIO_IF_REG_ADDR, 1, debug);
		xil_printf("[ERROR] Setting the CODEC as Master\n\n\r");
	}
	else {
		xil_printf("Done\n\n\r");
	}	

	for (int i = 0; i < 1000 ; i++);


	///////////////////////////////////
	// Configure the USB Mode
	///////////////////////////////////
	xil_printf("Setting USB Mode...\n\r");
	CodecRd(SAMPLING_RATE_REG_ADDR, 0, debug);

	// Sampling Rate settings
	codec_registers.SAMPLING_RATE.value     = 0; // Initialize
	codec_registers.SAMPLING_RATE.field.USB = 1; // Set the sampling rate in USB Mode (256*fs)

	check = CodecWr(SAMPLING_RATE_REG_ADDR, codec_registers.SAMPLING_RATE.value, 1, 0, debug);
	if (check) {
		CodecRd(SAMPLING_RATE_REG_ADDR, 1, debug);
		xil_printf("[ERROR] Setting USB Mode...\n\n\r");
	}
	else {
		xil_printf("Done\n\n\r");
	}	

	///////////////////////////////////
	// Configure Analog Audio Path
	///////////////////////////////////
	xil_printf("Setting the Analog Audio Path...\n\r");
	CodecRd(ANALOG_AUDIO_PATH_REG_ADDR, 0, debug);

	// Analog Audio Path Settings
	codec_registers.ANALOG_AUDIO_PATH.value        = 0;   // Initialize
	codec_registers.ANALOG_AUDIO_PATH.field.DACSEL = 0x1; // Select the DAC as the output

	check = CodecWr(ANALOG_AUDIO_PATH_REG_ADDR, codec_registers.ANALOG_AUDIO_PATH.value, 1, 0, debug);
	if (check) {
		CodecRd(ANALOG_AUDIO_PATH_REG_ADDR, 1, debug);
		xil_printf("[ERROR] Setting the Analog Audio Path...\n\n\r");
	}
	else {
		xil_printf("Done\n\n\r");
	}


	///////////////////////////////////
	// Unmute
	///////////////////////////////////
	xil_printf("Removing the Mute...\n\r");

	// Initialize the value with the default settinfs
	codec_registers.DIGITAL_AUDIO_PATH.value = CodecRd(DIGITAL_AUDIO_PATH_REG_ADDR, 0, debug);

	// Digital Audio Path Settings
	codec_registers.DIGITAL_AUDIO_PATH.field.DACMU = 0;

	check = CodecWr(DIGITAL_AUDIO_PATH_REG_ADDR, codec_registers.DIGITAL_AUDIO_PATH.value, 1, 0, debug);
	if (check) {
		CodecRd(DIGITAL_AUDIO_PATH_REG_ADDR, 1, debug);
		xil_printf("[ERROR] Removing the Mute...\n\n\r");
	}
	else {
		xil_printf("Done\n\n\r");
	}	

	// Wait a little bit according to the spec
	for (int i = 0; i < 1000000 ; i++);

	///////////////////////////////////
	// Enable the digital core
	///////////////////////////////////
	xil_printf("Enabling the Digital Core...\n\r");
	CodecRd(ACTIVE_REG_ADDR, 0, debug);

	// Active register settings
	codec_registers.ACTIVE.value        = 0;   // Initialize
	codec_registers.ACTIVE.field.Active = 0x1; // Activate the digital core

	check = CodecWr(ACTIVE_REG_ADDR, codec_registers.ACTIVE.value, 1, 0, debug);
	if (check) {
		CodecRd(ACTIVE_REG_ADDR, 1, debug);
		xil_printf("[ERROR] Setting the CODEC as Master\n\n\r");
	}
	else {
		xil_printf("Done\n\n\r");
	}	

	// Wait a little bit according to the spec
	for (int i = 0; i < 10000000 ; i++);
	
	///////////////////////////////////
	// Enable the output
	///////////////////////////////////
	xil_printf("Enabling the Output...\n\r");
	CodecRd(POWER_MGMT_REG_ADDR, 0, debug);

	// PM Settings
	codec_registers.POWER_MANAGEMENT.field.Out = 0x0; // Power ON the output

	check = CodecWr(POWER_MGMT_REG_ADDR, codec_registers.POWER_MANAGEMENT.value, 1, 0, debug);
	if (check) {
		CodecRd(POWER_MGMT_REG_ADDR, 1, debug);
		xil_printf("ERROR Setting the Output Enable\n\r");
	}
	else {
		xil_printf("Done\n\r");
	}

}
