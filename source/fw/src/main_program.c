///////////////////////////////////
// Main Program
///////////////////////////////////

//send data over UART
#include "main_program.h"

// Global Variables
// Interrupt Controller
INTC intc;
const int IntParams = 0;
XGpio gpio;
// Interrupt Vector Table
const ivt_t ivt[] = {
	(ivt_t) {
		GPIO_INT_ID, //u8 id;
		(XInterruptHandler)gpio_interrupt_handler,  //XInterruptHandler handler;
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
	while (1)
	{
		//xil_printf("=========== %d ==========\n\r", iteration);
		//CodecRd(ACTIVE_REG_ADDR, display, debug);
		//for (int i = 0; i < 90000000; i++);

		//xil_printf("=========== %d ==========\n\r", iteration);
		//CodecRd(LEFT_CHANN_INPUT_VOL_REG_ADDR, display, debug);
		//for (int i = 0; i < 90000000; i++);

		//xil_printf("=========== %d ==========\n\r", iteration);
		//CodecRd(DIGITAL_AUDIO_PATH_REG_ADDR, display, debug);
		//for (int i = 0; i < 90000000; i++);
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

	xil_printf("Interrupt on Channel %d\n\r", (status & 0x3));

	if (chan2_int) {
		button = XGpio_DiscreteRead(&gpio, 2);
		if (button) {
			xil_printf("Buttons pressed - %x\n\r", button);
			if (button <= 4) {
				CodecRd(button, 1, 0);
			} else {
				xil_printf("%c[2J",27);
				xil_printf("RESET BUTTON PRESSED - %x\n\r", button);
			}
		} else {
			xil_printf("Buttons released\n\r");
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
