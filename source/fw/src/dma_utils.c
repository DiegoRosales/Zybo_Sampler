///////////////////////////////
// DMA Utilities          
///////////////////////////////

#include "dma_utils.h"


// Create the array of the audio data
static volatile audio_data_t __AUDIO_SECTION__ input_stream_audio_data[INPUT_STREAM_SAMPLE_BUFFER_SIZE];

// Create the array of the audio data
static volatile audio_data_t __AUDIO_SECTION__ output_stream_audio_data[OUTPUT_STREAM_SAMPLE_BUFFER_SIZE];

// Create the descriptor of the input stream
static volatile dma_descriptor_t __AUDIO_SECTION__ input_stream_dma_descriptor;

// Create the descriptor of the output stream
static volatile dma_descriptor_t __AUDIO_SECTION__ output_stream_dma_descriptor;

// Create the DMA engine instance
static volatile XAxiDma audio_dma_engine;

// Set the DMA Configuration
static volatile XAxiDma_Config *audio_dma_engine_configuration;

// Audio Structure
extern const audio_structure_t audio_structure = {
    // Input Stream
    &input_stream_audio_data,
    INPUT_STREAM_SAMPLE_BUFFER_SIZE,
    &input_stream_dma_descriptor,
    // Output Stream
    &output_stream_audio_data,
    OUTPUT_STREAM_SAMPLE_BUFFER_SIZE,
    &output_stream_dma_descriptor,
    // DMA Engine
    &audio_dma_engine,
    &audio_dma_engine_configuration
};

int InitDMA_engine(XAxiDma *dma_engine, XAxiDma_Config *dma_engine_configuration) {
    xil_printf("Initializing DMA engine!!\n\r");

    int init_status;
    // Initialize the configuration
    dma_engine_configuration = XAxiDma_LookupConfigBaseAddr(DMA_ENGINE_BASE_ADDR);

    // Initialize the engine
    init_status = XAxiDma_CfgInitialize(dma_engine, dma_engine_configuration);

    // Check for errors
    if (init_status) {
        xil_printf("There was an error with the DMA Engine initialization! Error code = %d\n\r", init_status);
    } else {
        xil_printf("DMA Engine initialization was successful!\n\r");
    }
    return init_status;
}


// Start the stream DMA
// We need
// - The address of the buffer
// - The size of the transfer
// - A pointer to the descriptor to configure the circular buffer
// - A pointer to the instance of the DMA engine
// - The direction of the stream (1 = Upstream, 0 = Downstream)
void StartDMA(uint32_t buffer_stream_addr, uint32_t burst_size, dma_descriptor_t *dma_descriptor, XAxiDma *dma_engine, int direction) {
    xil_printf("\n\r==========================\n\r");
    xil_printf("Starting DMA!!\n\r");
    if (direction) {
        xil_printf("Direction = Upstream\n\r");
    } else {
        xil_printf("Direction = Downstream\n\r");
    }

    UINTPTR engine_base_addr;

    //////////
    // Configure the Input Stream descriptor
    //////////

    // To create a circular buffer, the pointer of the next DMA descriptor should be itself
    xil_printf("Descriptor Address = %x\n\r", dma_descriptor);
    dma_descriptor->NXTDESC     = dma_descriptor;
    dma_descriptor->NXTDESC_MSB = 0;

    // Configure the address of the actual data stream
    xil_printf("Buffer Address = %x\n\r", buffer_stream_addr);
    dma_descriptor->BUFFER_ADDRESS     = buffer_stream_addr;
    dma_descriptor->BUFFER_ADDRESS_MSB = 0;

    // Configure the size of the transfer
    // Since the buffer consists on only 1 descriptor, it is both start and end of frame
    dma_descriptor->CONTROL = 0; // Initialize
    dma_descriptor->CONTROL |= (burst_size & 0x3ffffff);
    dma_descriptor->CONTROL |= (1 << 26); // End of Frame
    dma_descriptor->CONTROL |= (1 << 27); // Start of Frame

    /////////
    // Configure the DMA registers
    /////////
    if (direction) {
        // Upstream (S2MM)
        engine_base_addr = dma_engine->RegBase + 0x30;
    } else {
        // Downstream (MM2S)
        engine_base_addr = dma_engine->RegBase;
    }

    xil_printf("Engine Address = %x\n\r", engine_base_addr);

    // Step 1 - Configure the descriptor pointer
    XAxiDma_WriteReg(engine_base_addr, 0x8, dma_descriptor);
    XAxiDma_WriteReg(engine_base_addr, 0xc, 0);

    // Step 2 - Start the DMA Engine
    XAxiDma_WriteReg(engine_base_addr, 0x0, (   1 << 0  | // Start bit
                                                0 << 4  | // Cyclic bit
                                                7 << 12 | // Interrupt on completion   
                                                1 << 23   // Interrupt theshold
                                            ));

    // Step 3 - Configure the tail descriptor pointer to trigger the DMA
    XAxiDma_WriteReg(engine_base_addr, 0x10, dma_descriptor);
    XAxiDma_WriteReg(engine_base_addr, 0x14, 0);
    xil_printf("Status = %x\n\r", XAxiDma_ReadReg(engine_base_addr, 0x4));
    xil_printf("==========================\n\r");

}

void DMA_interrupt_handler(void * IntParams) {
    xil_printf("\n\r==========================\n\r");
    xil_printf("DMA Interrupt!!\n\r");
    xil_printf("==========================\n\r");
}