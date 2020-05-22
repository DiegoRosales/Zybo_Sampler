
//////////////////////////////////////////////
// Codec Uitilities
//////////////////////////////////////////////
// This section contains some useful functions
// to read and write registers from the CODEC
// as well as some initialization routines
//////////////////////////////////////////////

// Xilinx Includes
#include "xil_printf.h"
#include "xparameters.h"

// CODEC Includes
#include "codec_controller_control_regs.h"
#include "SSM2603_codec_registers.h"
#include "codec_controller_reg_utils.h"
#include "codec_controller_utils.h"

uint32_t ulCodecRd(uint32_t addr, uint32_t display, uint32_t debug) {
	uint32_t data_rd = 0;

	// Step 0 - Check if there are no other transactions running. If there are none, clear all the Status bits
	if ( CODEC_CONTROL_REGISTER_ACCESS->CODEC_I2C_CTRL_REG.field.controller_busy_reg ) {
		xil_printf("============\n\r");
		xil_printf("[ERROR] There is another transaction going on...\n\r");
		xil_printf("============\n\r");
		return 0xffffffff;
	}

	vClearStatusBits(debug);

	// Step 1 - Write the Address
	if (debug) xil_printf("-------------\n\r", addr);
	if (debug) xil_printf("Reading CODEC Register %02x\n\n\r", addr);
	if (debug) xil_printf("Writing the CODEC Address to register\n\r", addr);
	CODEC_CONTROL_REGISTER_ACCESS->CODEC_I2C_ADDR_REG.value = addr;

	// Step 2 - Set the RD bit
	if (debug) xil_printf("Setting the RD bit...\n\r", addr);
	CODEC_CONTROL_REGISTER_ACCESS->CODEC_I2C_CTRL_REG.field.codec_i2c_data_rd_reg = 1;

	// Step 3 - Wait for the Busy bit to clear
	vBusyBitIsClear(debug);

	vWaitUntilDataIsAvailable(debug);

	// Step 4 - Read the data
	if (debug) xil_printf("Reading the Data from the Register...\n\r", addr);
	data_rd = CODEC_CONTROL_REGISTER_ACCESS->CODEC_I2C_RD_DATA_REG.value;

	if (display | debug) xil_printf("CODEC Register[%02x] = 0x%02x\n\r", addr, data_rd);
	if (debug) xil_printf("-------------\n\r", addr);
	return data_rd;
}

uint32_t ulCodecWr(uint32_t addr, uint32_t data, uint32_t check, uint32_t display, uint32_t debug) {
	uint32_t readback = 0;
	uint32_t error    = 0;
	
	// Step 0 - Check if there are no other transactions running. If there are none, clear all the Status bits
	if ( CODEC_CONTROL_REGISTER_ACCESS->CODEC_I2C_CTRL_REG.field.controller_busy_reg ) {
		xil_printf("============\n\r");
		xil_printf("[ERROR] There is another transaction going on...\n\r");
		xil_printf("============\n\r");
		return 0xffffffff;
	}

	if (debug) xil_printf("===============\n\r", addr);
	vClearStatusBits(debug);
	if (debug | display)  xil_printf("CODEC Register[%02x] <---- 0x%02x\n\r", addr, data);

	// Step 1 - Write the Address
	if (debug) xil_printf("Writing the CODEC Address to the register\n\r");
	CODEC_CONTROL_REGISTER_ACCESS->CODEC_I2C_ADDR_REG.value = addr;

	// Step 2 - Write the Data
	if (debug) xil_printf("Writing the CODEC Data to the register\n\r");
	CODEC_CONTROL_REGISTER_ACCESS->CODEC_I2C_WR_DATA_REG.value = data;

	// Step 3 - Set the WR bit
	if (debug) xil_printf("Setting the WR bit...\n\r");
	CODEC_CONTROL_REGISTER_ACCESS->CODEC_I2C_CTRL_REG.field.codec_i2c_data_wr_reg = 1;

	// Step 4 - Wait for the Busy bit to clear
	if (debug) xil_printf("Waiting for the transfer to complete\n\r");
	vBusyBitIsClear(debug);

	// Step 5 (optional) - Read back the data
	if (check) {
		if (debug) xil_printf("Performing Readback...\n\r");
		readback = ulCodecRd(addr, 1, debug);
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

void vClearStatusBits(uint32_t debug) {
	uint32_t status = 0;
	if (debug) xil_printf("Clearing the Status Bits...\n\r");
	// Read the status register
	status = CODEC_CONTROL_REGISTER_ACCESS->CODEC_I2C_CTRL_REG.value;
	// Write back the same value to clear the bits
	CODEC_CONTROL_REGISTER_ACCESS->CODEC_I2C_CTRL_REG.value = status;
	if (debug) xil_printf("Done!\n\r");

}

void vWaitUntilDataIsAvailable(uint32_t debug) {
	uint32_t data_is_available = 0;
	uint32_t missed_ack        = 0;
	CODEC_I2C_CTRL_REG_t xfer_done;

	if (debug) xil_printf("Waiting for the valid data bit...\n\r");
	// Wait until the data_is_available bit is 1
	do {
		xfer_done         = CODEC_CONTROL_REGISTER_ACCESS->CODEC_I2C_CTRL_REG;
		data_is_available = xfer_done.field.data_in_valid_reg;
		missed_ack        = xfer_done.field.missed_ack_reg;
		if (missed_ack) {
			xil_printf("====== MISSED ACK!!! ======\n\r");
		}
	} while (data_is_available == 0);
	if (debug) xil_printf("Got valid data. Clearing the bit...\n\r");
	// Clear that bit
	CODEC_CONTROL_REGISTER_ACCESS->CODEC_I2C_CTRL_REG.value = 0x10;
	if (debug) xil_printf("Bit is clear!\n\r");
}

void vBusyBitIsClear(uint32_t debug) {
	if (debug) xil_printf("Waiting for the transfer to complete...\n\r");

	// Do nothing while the controller is busy
	while( CODEC_CONTROL_REGISTER_ACCESS->CODEC_I2C_CTRL_REG.field.controller_busy_reg );

	if (debug) xil_printf("Busy Bit is Clear!\n\r");
}

void vControllerReset(uint32_t debug) {
	xil_printf("Resetting the controller...\n\r");
	// Write the reset value	
	CODEC_CONTROL_REGISTER_ACCESS->CODEC_I2C_CTRL_REG.field.controller_reset_reg = 1;
	// Do nothing while the controller is in reset
	while ( CODEC_CONTROL_REGISTER_ACCESS->CODEC_I2C_CTRL_REG.field.controller_reset_reg );
	xil_printf("DONE\n\r");
}

void vCodecReset(uint32_t debug) {
	xil_printf("Resetting the CODEC...\n\r");
	ulCodecWr(SW_RESET_REG_ADDR, 0x0, 0, 1, debug);
	for (uint32_t i = 0; i < 1000000 ; i++);
	ulCodecWr(SW_RESET_REG_ADDR, 0x1, 0, 1, debug);
	for (uint32_t i = 0; i < 1000000 ; i++);
	xil_printf("Done\n\n\r");
}

// Set the Volume in dB
uint32_t ulSetOutputVolume(uint32_t volume) {
	LEFT_CHAN_DAC_VOL_t  left_volume;
	RIGHT_CHAN_DAC_VOL_t right_volume;

	left_volume.field.LHPVOL   = DB_TO_INT_OUT(volume); // Set the volume
	left_volume.field.LRHPBOTH = 1; // Adjust left and right at the same time

	// Write the Volume
	ulCodecWr(LEFT_CHANN_OUTPUT_VOL_REG_ADDR, left_volume.value, 0, 1, 0);
	// Read the volume of the other channel to see if it was set
	right_volume.value = ulCodecRd(RIGHT_CHANN_OUTPUT_VOL_REG_ADDR, 1, 0);

	// Check the values
	if (left_volume.field.LHPVOL == right_volume.field.RHPVOL) {
		return 0;
	} else {
		return 0xff;
	}

}

// Set the Volume in dB
uint32_t ulSetInputVolume(uint32_t volume) {
	LEFT_CHAN_ADC_IN_VOL_t  left_volume;
	RIGHT_CHAN_ADC_IN_VOL_t right_volume;

	left_volume.field.LINVOL   = volume;//DB_TO_INT(volume); // Set the volume
	left_volume.field.LINMUTE  = 0; // Disable Mute
	left_volume.field.LRINBOTH = 1; // Adjust left and right at the same time

	ulCodecRd(RIGHT_CHANN_INPUT_VOL_REG_ADDR, 1, 0);
	// Write the Volume
	ulCodecWr(LEFT_CHANN_INPUT_VOL_REG_ADDR, left_volume.value, 0, 1, 0);
	// Read the volume of the other channel to see if it was set
	right_volume.value = ulCodecRd(RIGHT_CHANN_INPUT_VOL_REG_ADDR, 1, 0);

	// Check the values
	if (left_volume.field.LINVOL == right_volume.field.RINVOL) {
		return 0;
	} else {
		return 0xff;
	}

}

void vCodecInit(uint32_t debug) {
	uint32_t check     = 0;

	CODEC_REGISTERS_t codec_registers;

	// Reset the CODEC
	vCodecReset(debug);

	///////////////////////////////
	// Set the PM Registers
	///////////////////////////////
	xil_printf("Enabling the PM Registers...\n\r");
	codec_registers.POWER_MANAGEMENT.value = ulCodecRd(POWER_MGMT_REG_ADDR, 0, debug);

	// PM Settings
	codec_registers.POWER_MANAGEMENT.value        = 0x0ff; // Initialize all powered OFF
	codec_registers.POWER_MANAGEMENT.field.PWROFF = 0; // Power UP the Chip
	codec_registers.POWER_MANAGEMENT.field.DAC    = 0; // Power UP the DAC
	codec_registers.POWER_MANAGEMENT.field.ADC    = 0; // Power UP the ADC
	codec_registers.POWER_MANAGEMENT.field.LINEIN = 0; // Power UP the Line Input
	codec_registers.POWER_MANAGEMENT.field.CLKOUT = 0; // Power UP the Clock Output to the FPGA
	
	check = ulCodecWr(POWER_MGMT_REG_ADDR, codec_registers.POWER_MANAGEMENT.value, 1, 0, debug);
	if (check) {
		ulCodecRd(POWER_MGMT_REG_ADDR, 1, debug);
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
	ulCodecRd(DIGITAL_AUDIO_IF_REG_ADDR, 0, debug);

	// Digital audio IF Settings
	codec_registers.DIGITAL_AUDIO_IF.value        = 0;   // Initialize
	codec_registers.DIGITAL_AUDIO_IF.field.Format = 0x3; // DSP Serial Mode
	codec_registers.DIGITAL_AUDIO_IF.field.LRP    = 0x1; // DSP Submode 2
	codec_registers.DIGITAL_AUDIO_IF.field.MS     = 0x1; // Master Mode
	check = ulCodecWr(DIGITAL_AUDIO_IF_REG_ADDR, codec_registers.DIGITAL_AUDIO_IF.value, 1, 0, debug);
	if (check) {
		ulCodecRd(DIGITAL_AUDIO_IF_REG_ADDR, 1, debug);
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
	ulCodecRd(SAMPLING_RATE_REG_ADDR, 0, debug);

	// Sampling Rate settings
	codec_registers.SAMPLING_RATE.value      = 0;   // Initialize
	codec_registers.SAMPLING_RATE.field.USB  = 1;   // Set the sampling rate in USB Mode (256*fs)
	codec_registers.SAMPLING_RATE.field.SR   = 0x8; // Set the sampling rate to 44.118KHz
	codec_registers.SAMPLING_RATE.field.BOSR = 1;   // Set the sampling rate to 44.118KHz

	check = ulCodecWr(SAMPLING_RATE_REG_ADDR, codec_registers.SAMPLING_RATE.value, 1, 0, debug);
	if (check) {
		ulCodecRd(SAMPLING_RATE_REG_ADDR, 1, debug);
		xil_printf("[ERROR] Setting USB Mode...\n\n\r");
	}
	else {
		xil_printf("Done\n\n\r");
	}	

	///////////////////////////////////
	// Configure Analog Audio Path
	///////////////////////////////////
	xil_printf("Setting the Analog Audio Path...\n\r");
	ulCodecRd(ANALOG_AUDIO_PATH_REG_ADDR, 0, debug);

	// Analog Audio Path Settings
	codec_registers.ANALOG_AUDIO_PATH.value        = 0;   // Initialize
	codec_registers.ANALOG_AUDIO_PATH.field.DACSEL = 0x1; // Select the DAC as the output
	codec_registers.ANALOG_AUDIO_PATH.field.Bypass = 0x0; // Mix the input with the output

	check = ulCodecWr(ANALOG_AUDIO_PATH_REG_ADDR, codec_registers.ANALOG_AUDIO_PATH.value, 1, 0, debug);
	if (check) {
		ulCodecRd(ANALOG_AUDIO_PATH_REG_ADDR, 1, debug);
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
	codec_registers.DIGITAL_AUDIO_PATH.value = ulCodecRd(DIGITAL_AUDIO_PATH_REG_ADDR, 0, debug);

	// Digital Audio Path Settings
	codec_registers.DIGITAL_AUDIO_PATH.field.DACMU  = 0;
	codec_registers.DIGITAL_AUDIO_PATH.field.ADCHPF = 1;

	check = ulCodecWr(DIGITAL_AUDIO_PATH_REG_ADDR, codec_registers.DIGITAL_AUDIO_PATH.value, 1, 0, debug);
	if (check) {
		ulCodecRd(DIGITAL_AUDIO_PATH_REG_ADDR, 1, debug);
		xil_printf("[ERROR] Removing the Mute...\n\n\r");
	}
	else {
		xil_printf("Done\n\n\r");
	}	

	///////////////////////////////////
	// Set the volume
	///////////////////////////////////
	xil_printf("Setting the output volume...\n\r");

	check = ulSetOutputVolume(-15);

	if (check) {
		xil_printf("[ERROR] Setting the output volume...\n\n\r");
	}
	else {
		xil_printf("Done\n\n\r");
	}		

	///////////////////////////////////
	// Set the volume
	///////////////////////////////////
	xil_printf("Setting the input volume...\n\r");

	check = ulSetInputVolume(0x17); // 0 dB

	if (check) {
		xil_printf("[ERROR] Setting the input volume...\n\n\r");
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
	ulCodecRd(ACTIVE_REG_ADDR, 0, debug);

	// Active register settings
	codec_registers.ACTIVE.value        = 0;   // Initialize
	codec_registers.ACTIVE.field.Active = 0x1; // Activate the digital core

	check = ulCodecWr(ACTIVE_REG_ADDR, codec_registers.ACTIVE.value, 1, 0, debug);
	if (check) {
		ulCodecRd(ACTIVE_REG_ADDR, 1, debug);
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
	ulCodecRd(POWER_MGMT_REG_ADDR, 0, debug);

	// PM Settings
	codec_registers.POWER_MANAGEMENT.field.Out = 0x0; // Power ON the output

	check = ulCodecWr(POWER_MGMT_REG_ADDR, codec_registers.POWER_MANAGEMENT.value, 1, 0, debug);
	if (check) {
		ulCodecRd(POWER_MGMT_REG_ADDR, 1, debug);
		xil_printf("ERROR Setting the Output Enable\n\r");
	}
	else {
		xil_printf("Done\n\r");
	}

}
