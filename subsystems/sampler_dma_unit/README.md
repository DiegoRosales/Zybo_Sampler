# Sampler DMA Unit

On a high-level, this module takes the PCM samples that have been loaded into the PS System memory and forwards them to the next stage using an AXI Stream interface

Since this is meant to playback multiple audio samples at a time, the internal buffers need to be very small to avoid

1) Percivable latency (both when pressing and releasing keys)
2) Complex management logic since the Zynq FPGA is very small

The implementation is a slot-based mechanism, where the software configures one slot with the sample information (DMA Address, length, etc.) and the DMA engine proceeds to fetch the audio data based on that information like so.

```C
// User loads a library
FW      --> SYS_MEM // Load samples
// User presses a key
FW      --> DMA_U   // Configure Slot 0
SYS_MEM <-- DMA_U   // Request Sample of Slot 0
SYS_MEM --> DMA_U   // Receives Sample of Slot 0
SYS_MEM <-- DMA_U   // Request Sample of Slot 0
SYS_MEM --> DMA_U   // Receives Sample of Slot 0
// ...
// User presses a second key
FW      --> DMA_U   // Configure Slot 1
SYS_MEM <-- DMA_U   // Request Sample of Slot 0
SYS_MEM <-- DMA_U   // Request Sample of Slot 1
SYS_MEM --> DMA_U   // Receives Sample of Slot 0
SYS_MEM --> DMA_U   // Receives Sample of Slot 1
SYS_MEM <-- DMA_U   // Request Sample of Slot 0
SYS_MEM <-- DMA_U   // Request Sample of Slot 1
SYS_MEM --> DMA_U   // Receives Sample of Slot 0
SYS_MEM --> DMA_U   // Receives Sample of Slot 1
// User releases the first key
FW      --> DMA_U   // Release Slot 0
SYS_MEM <-- DMA_U   // Request Sample of Slot 1
SYS_MEM --> DMA_U   // Receives Sample of Slot 1
SYS_MEM <-- DMA_U   // Request Sample of Slot 1
SYS_MEM --> DMA_U   // Receives Sample of Slot 1
```

With this implementation, the maximum number of playback voices can increase without requiring an exponential amount of logic resources since all the sample information can be stored in BRAMs and each sample is received sequentially. The only bottleneck is the speed of the AXI DMA interface.

# Block diagram

```

                              +----------+
                              |   BRAM   |
                              +-----^----+
                                   ||
                                   ||Sample information written by SW
                                   ||(ej, start addr, length, etc.)
                                   ||
                       +-----------v------------+
                       |                        |
This block gets the    |  sample_info_fetcher   |
information from the   |                        |
BRAM and forwards it   |                        |
to the DMA requester   |                        |
                       |                        |
                       +------------^-----------+
                                   ||
                                   ||
                       +-----------v------------+
                       |                        |
Using that information |  sample_dma_requester  |
this block generates   |                        |
a DMA request to for   |                        |
the AXI DMA controller |                        |
                       |                        |
                       +------------^-----------+
                                   ||
                   +----------------|
                   |               ||
                   |               ||
                   |   +-----------v------------+
                   |   |                        |
                   |   |  AXI DMA Engine        |   AXI DMA interface
                   |   |                        +----------------------->
                   |   |            +-----------------------------------+
                   |   |            |           |
                   |   +------------------------+
                   |                |
                   +--------------+ |
                                  | |
                       +----------v-v-----------+
                       |                        |
This block receives    |  sample_dma_receiver   |
the audio stream from  |                        |
the DMA engine         |                        |
                       |                        |
                       |                        |
                       +------------------------+

```