/*
 * main.c
 *
 *  Created on: 23/09/2018
 *      Author: diego
 */
//#include <stdbool.h>

//send data over UART
#include "xil_printf.h"

#include "reg_utils.h"
#include "codec_utils.h"

int main_program()
{
	xil_printf("%c[2J",27);
	xil_printf("Hello From Main Program\n\r");
	int iteration = 0;
	int check     = 1;
	int debug     = 0;
	while (1)
	{
		xil_printf("=========== %d ==========\n\r", iteration);
		CodecRd(POWER_MGMT_REG_ADDR, check, debug);
		for (int i = 0; i < 90000000; i++);

//		CodecRd(LEFT_CHANN_INPUT_VOL_REG_ADDR, check, debug);
//		for (int i = 0; i < 90000000; i++);
//		xil_printf("----\n\r");
//
//		CodecRd(POWER_MGMT_REG_ADDR, check, debug);
//		for (int i = 0; i < 90000000; i++);
//		xil_printf("----\n\r");
//
//		CodecRd(LEFT_CHANN_OUTPUT_VOL_REG_ADDR, check, debug);
//		for (int i = 0; i < 90000000; i++);
//		xil_printf("----\n\r");
//
//		CodecRd(LEFT_CHANN_OUTPUT_VOL_REG_ADDR, check, debug);
//		for (int i = 0; i < 90000000; i++);
//		xil_printf("----\n\r");
//
//		CodecRd(ANALOG_AUDIO_PATH_REG_ADDR, check, debug);
//		for (int i = 0; i < 90000000; i++);		
	}
}



