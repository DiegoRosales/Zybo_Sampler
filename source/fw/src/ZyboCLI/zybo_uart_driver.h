#ifndef ZYBO_UART_DRIVER_H
#define ZYBO_UART_DRIVER_h

/* Dimensions the buffer into which input characters are placed. */
#define cmdMAX_INPUT_SIZE		100

/* Dimentions a buffer to be used by the UART driver, if the UART driver uses a
buffer at all. */
#define cmdQUEUE_LENGTH			25

/* DEL acts as a backspace. */
#define cmdASCII_DEL		( 0x7F )

/* Check if backspace is pressed */
#define cmdIS_BACKSPACE(myChar) ( (( myChar == '\b' ) || ( myChar == cmdASCII_DEL )) )

/* The maximum time to wait for the mutex that guards the UART to become
available. */
#define cmdMAX_MUTEX_WAIT		pdMS_TO_TICKS( 300 )

#ifndef configCLI_BAUD_RATE
	#define configCLI_BAUD_RATE	115200
#endif

#define mainUART_COMMAND_CONSOLE_STACK_SIZE	( configMINIMAL_STACK_SIZE * 300UL )
#define mainUART_COMMAND_CONSOLE_TASK_PRIORITY	( configMAX_PRIORITIES - 2 )

// If this flag is set to 1, the driver will ignore all non-character inputs
#define INPUT_IS_ASCII_ONLY 0

// If this flag is set to 1, if the user presses Return without typing anything, the last command will be executed
#define EXEC_LAST_CMD_ON_EMPTY_RETURN 0

#endif
