

#ifndef DMA_UTILS_H
#define DMA_UTILS_H

#include "xparameters.h" 
#include "xil_printf.h"
#include "xil_io.h"

#include "xaxidma.h"

#define __AUDIO_SECTION__ __attribute__((section (".audio_section")))


// Base address of the DDR RAM memory
#define DDR_BASE_ADDR XPAR_PS7_DDR_0_S_AXI_BASEADDR

// Base address of the DMA engine for configuration
#define DMA_ENGINE_BASE_ADDR ((UINTPTR)XPAR_AXI_DMA_0_BASEADDR)

// Interrupt ID
#define DMA_DOWNSTREAM_INT_ID XPAR_FABRIC_AXIDMA_0_MM2S_INTROUT_VEC_ID
#define DMA_UPSTREAM_INT_ID XPAR_FABRIC_AXIDMA_0_S2MM_INTROUT_VEC_ID

//////////////////////////////////////////////////////////////
// INPUT STREAM
//////////////////////////////////////////////////////////////

// Size of the memory region of the input stream in "samples"
// The lower the buffer size, the lower the latency, but performance requirements increase
#define INPUT_STREAM_SAMPLE_BUFFER_SIZE 512 // 512 Samples


//////////////////////////////////////////////////////////////
// OUTPUT STREAM
//////////////////////////////////////////////////////////////

// Size of the memory region of the output stream in "samples"
// The lower the buffer size, the lower the latency, but performance requirements increase
#define OUTPUT_STREAM_SAMPLE_BUFFER_SIZE 512 // 512 Samples

// Audio Data structure
typedef struct {
    uint32_t left_channel;
    uint32_t right_channel;
} audio_data_t;

// Descriptor data structure
typedef struct {
    uint32_t NXTDESC;            // 0x00 // Next Descriptor Pointer
    uint32_t NXTDESC_MSB;        // 0x04 // Upper 32 bits of Next Descriptor Pointer
    uint32_t BUFFER_ADDRESS;     // 0x08 // Buffer Address
    uint32_t BUFFER_ADDRESS_MSB; // 0x0c // Upper 32 bits of Buffer Address
    uint32_t RESERVED_1;         // 0x10 // N/A
    uint32_t RESERVED_2;         // 0x14 // N/A
    uint32_t CONTROL;            // 0x18 // Control
    uint32_t STATUS;             // 0x1c // Status
    uint32_t APP0;               // 0x20 // User Application Field 0
    uint32_t APP1;               // 0x24 // User Application Field 1
    uint32_t APP2;               // 0x28 // User Application Field 2
    uint32_t APP3;               // 0x2c // User Application Field 3
    uint32_t APP4;               // 0x30 // User Application Field 4
    uint32_t RESERVED_3;         // 0x34 // Filler to allign 16-dw
    uint32_t RESERVED_4;         // 0x38 // Filler to allign 16-dw
    uint32_t RESERVED_5;         // 0x3c // Filler to allign 16-dw
} dma_descriptor_t;

typedef struct {
    // Input Stream
    uint32_t input_stream_buffer_addr;
    uint32_t input_stream_buffer_size;
    uint32_t input_stream_dma_desc_addr;
    // Output Stream
    uint32_t output_stream_buffer_addr;
    uint32_t output_stream_buffer_size;
    uint32_t output_stream_dma_desc_addr;
    // DMA Engine
    uint32_t audio_dma_engine_addr;
    uint32_t *audio_dma_engine_cfg_addr;
    
} audio_structure_t;



int InitDMA_engine(XAxiDma *dma_engine, XAxiDma_Config *dma_engine_configuration);
void StartDMA(uint32_t buffer_stream_addr, uint32_t burst_size, dma_descriptor_t *dma_descriptor, XAxiDma *dma_engine, int direction);
void DMA_interrupt_handler(void * IntParams);

#endif // DMA_UTILS_H