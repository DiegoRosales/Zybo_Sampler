/*
 * main.c
 *
 *  Created on: 23/09/2018
 *      Author: diego
 */
//#include <stdbool.h>
#ifndef MAIN_PROGRAM_H
#define MAIN_PROGRAM_H

//send data over UART
#include "xil_printf.h"
#include "xparameters.h" 
#include "xgpio.h"

#include "reg_utils.h"
#include "codec_utils.h"
#include "dma_utils.h"
#include "intc/intc.h"
#include "FreeRTOS.h"
#include "task.h"
#include "FreeRTOS_MemAlloc.h"
#include "nco.h"

// Interrupt ID of the GPIO
// This parameter is taken from the "xparameters.h" 
// that is generated with the BSP information (which comes from Vivado)
#define GPIO_INT_ID XPAR_FABRIC_GPIO_0_VEC_ID

int main_program();

void gpio_interrupt_handler();
void enable_gpio_interrupts();

#endif
