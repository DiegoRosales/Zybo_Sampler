////////////////////////////////////////////////////////
// Sampler Driver
////////////////////////////////////////////////////////
// Xilinx Includes
#include "xil_io.h"

//information about AXI peripherals
#include "xparameters.h"

#include "sampler.h"

static uint32_t        sampler_voices[MAX_VOICES];
static SAMPLER_VOICE_t sampler_voices_information[MAX_VOICES];

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

// This function will return the number
// of the voice slot available to start the playback
uint32_t get_available_voice_slot( void ) {
	for ( int i = 0 ; i < MAX_VOICES ; i++ ) {
		if ( sampler_voices[ i ] == 0 ) {
			sampler_voices[ i ] = 1;
			return i; // Return the slot number
		}
	}
	return 0xffffffff; // Return bad data
}

uint32_t get_sampler_version( void ) {
	return SAMPLER_CONTROL_REGISTER_ACCESS->SAMPLER_VER_REG.value;
}

// This function will trigger the playback of a voice based on the voice information
uint32_t start_voice_playback( uint32_t sample_addr, uint32_t sample_size ) {
	uint32_t voice_slot = 0;

	// Step 1 - Get a voice slot
	voice_slot = get_available_voice_slot();

	// Step 2 - Load the voice information data structure
	sampler_voices_information[voice_slot].voice_start_addr = sample_addr;
	sampler_voices_information[voice_slot].voice_start_addr = sample_size;

	// Step 3 - Write the voice information address to the register with the slot number
	SAMPLER_DMA_REGISTER_ACCESS->sampler_dma[voice_slot].dma_addr.value    = &sampler_voices_information[voice_slot];
	
	// Step 4 - Start the DMA
	SAMPLER_DMA_REGISTER_ACCESS->sampler_dma[voice_slot].dma_control.field.stop  = 0;
	SAMPLER_DMA_REGISTER_ACCESS->sampler_dma[voice_slot].dma_control.field.start = 1;

	return voice_slot;
}

// This function will stop the playback of the voice
uint32_t stop_voice_playback( uint32_t voice_slot ) {
	// Stop the DMA
	SAMPLER_DMA_REGISTER_ACCESS->sampler_dma[voice_slot].dma_control.field.start = 0;
	SAMPLER_DMA_REGISTER_ACCESS->sampler_dma[voice_slot].dma_control.field.stop  = 1;

	// Release the voice slot
	sampler_voices [ voice_slot ] = 0;
	return 0;
}