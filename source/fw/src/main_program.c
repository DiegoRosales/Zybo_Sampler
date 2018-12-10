///////////////////////////////////
// Main Program
///////////////////////////////////

//send data over UART
#include "main_program.h"

// Global Variables
const audio_structure_t audio_structure;
// Interrupt Controller
INTC intc;
const int IntParams = 0;
XGpio gpio;
// Interrupt Vector Table
const ivt_t ivt[] = {
	// GPIO Interrupt
	(ivt_t) {
		GPIO_INT_ID, //u8 id;
		(XInterruptHandler)gpio_interrupt_handler,  //XInterruptHandler handler;
		&IntParams,//void *pvCallbackRef;
		0x0,//u8 priority; //not used for microblaze, set to 0
		0x3//0x3//u8 trigType; //not used for microblaze, set to 0
	},
	// DMA Interrupt
	(ivt_t) {
		DMA_DOWNSTREAM_INT_ID, //u8 id;
		(XInterruptHandler)DMA_interrupt_handler,  //XInterruptHandler handler;
		&IntParams,//void *pvCallbackRef;
		0x0,//u8 priority; //not used for microblaze, set to 0
		0x3//0x3//u8 trigType; //not used for microblaze, set to 0
	},
	// DMA Interrupt
	(ivt_t) {
		DMA_UPSTREAM_INT_ID, //u8 id;
		(XInterruptHandler)DMA_interrupt_handler,  //XInterruptHandler handler;
		&IntParams,//void *pvCallbackRef;
		0x0,//u8 priority; //not used for microblaze, set to 0
		0x3//0x3//u8 trigType; //not used for microblaze, set to 0
	}		
};

int main_program()
{
	xil_printf("%c[2J",27);
	xil_printf("Hello From Main Program\n\r");
	int iteration = 0;
	int check     = 1;
	int display   = 1;
	int debug     = 0;

	XGpio_Initialize(&gpio, 0);
	enable_gpio_interrupts();
	XGpio_InterruptClear(&gpio, 0xffffffff);
	XGpio_InterruptEnable(&gpio, 0xffffffff);
	XGpio_InterruptGlobalEnable(&gpio);
	CodecInit(0);
	InitDMA_engine(audio_structure.audio_dma_engine_addr, audio_structure.audio_dma_engine_cfg_addr);
	StartDMA(audio_structure.input_stream_buffer_addr,  128, audio_structure.input_stream_dma_desc_addr,  audio_structure.audio_dma_engine_addr, 1); // Start upstream DMA
	StartDMA(audio_structure.output_stream_buffer_addr, 128, audio_structure.output_stream_dma_desc_addr, audio_structure.audio_dma_engine_addr, 0); // Start downstream DMA

	while (1)
	{
	}
}

void gpio_interrupt_handler(void *IntParams){
	int status    = 0;
	int chan1_int = 0;
	int chan2_int = 0;
	int button    = 0;
	int sw        = 0;

	status    = XGpio_InterruptGetStatus(&gpio);
	chan1_int = status & 0x1;        // Bit 0
	chan2_int = (status >> 1) & 0x1; // Bit 1

	//xil_printf("Interrupt on Channel %d\n\r", (status & 0x3));

	if (chan2_int) {
		button = XGpio_DiscreteRead(&gpio, 2);
		sw     = (XGpio_DiscreteRead(&gpio, 1) >> 1) & 0x7;
		if (button) {
			xil_printf("%c[2J",27);
			xil_printf("Buttons pressed\n\r", button);
			xil_printf("Button = %x\n\r", button);
			switch (button)
			{
				case 1:
					switch (sw)
					{
						case 0:
							xil_printf("Misc Register 0 - %x\n\r", button);
							RegRd(MISC_DATA_0_REG_ADDR, 1);
							break;
						case 1:
							xil_printf("Misc Register 1 - %x\n\r", button);
							RegRd(MISC_DATA_1_REG_ADDR, 1);		
							break;
						default:
							break;
					}					
					break;
				case 2:
					xil_printf("Switch Value = %x\n\r", sw);
					switch (sw)
					{
						case 0:
							xil_printf("Reading RIGHT_CHANN_INPUT_VOL_REG_ADDR (0x1)\n\r");
							CodecRd(RIGHT_CHANN_INPUT_VOL_REG_ADDR, 1, 0);
							break;
						case 1:
							xil_printf("Reading DIGITAL_AUDIO_IF_REG_ADDR (0x7)\n\r");
							CodecRd(DIGITAL_AUDIO_IF_REG_ADDR, 1, 0);
							break;
						case 2:
							xil_printf("Initializing the CODEC\n\r");
							CodecInit(0);
							break;

						default:
							xil_printf("Misc Register 1 - %x\n\r", button);
							RegRd(MISC_DATA_1_REG_ADDR, 1);
							break;
					}					
					break;
				case 4:
					xil_printf("SOFT RESET - %x\n\r", button);
					ControllerReset(1);
					break;
				case 8:
					xil_printf("RESET BUTTON PRESSED - %x\n\r", button);
					break;									
				default:
					break;
			}
		} 
		else {
			xil_printf("\n\r=============\n\r");
			xil_printf("Buttons released\n\r");
			xil_printf("Button = %x\n\r", button);
			xil_printf("=============\n\r");
		}
		
	} else {
		xil_printf("INTERRUPT!!\n\r");
	}

	XGpio_InterruptClear(&gpio, 0xffffffff);

}

void enable_gpio_interrupts() {
	xil_printf("Enabling Interrupts...\n\r");
	int Status;
	Status = fnInitInterruptController(&intc);
	if(Status != XST_SUCCESS) {
		xil_printf("Error initializing interrupts");
		return;
	}

	fnEnableInterrupts(&intc, &ivt[0], sizeof(ivt)/sizeof(ivt[0]));
	xil_printf("Done\n\n\r");
}

