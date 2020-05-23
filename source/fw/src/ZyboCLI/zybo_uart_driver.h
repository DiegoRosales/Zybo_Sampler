#ifndef ZYBO_UART_DRIVER_H
#define ZYBO_UART_DRIVER_h

/* Dimensions the buffer into which input characters are placed. */
#define cmdMAX_INPUT_SIZE		100

/* Dimentions a buffer to be used by the UART driver, if the UART driver uses a
buffer at all. */
#define cmdQUEUE_LENGTH			25

/* Escape Characters */
#define cmdASCII_BACKSPACE           ( 0x08 ) /* DEL acts as a backspace. */
#define cmdASCII_DEL                 ( 0x7F )
#define cmdASCII_ESC                 ( 0x1B )
#define cmdASCII_CTRL_SEQ_INTRODUCER ( '[' )
#define cmdANSI_ESC_UP               ( (const char *) "\033[A" )
#define cmdANSI_ESC_DOWN             ( (const char *) "\033[B" )
#define cmdANSI_ESC_RIGHT            ( (const char *) "\033[1C" )
#define cmdANSI_ESC_LEFT             ( (const char *) "\033[1D" )
#define cmdANSI_ESC_RIGHT_FMT        ( (const char *) "\033[%dC" ) /* To be used with sprintf */
#define cmdANSI_ESC_LEFT_FMT         ( (const char *) "\033[%dD" ) /* To be used with sprintf */
#define cmdANSI_ESC_SAVE_CURSOR      ( (const char *) "\033[s" )
#define cmdANSI_ESC_RESTORE_CURSOR   ( (const char *) "\033[u" )
#define cmdANSI_ESC_ERASE_LINE       ( (const char *) "\033[K" ) /* Erase line from cursor position */

/* Escape Commands */
#define cmdSEND_ESC_CMD(PORT, ESC_CMD)  vSerialPutString( PORT, ( signed char * )  ESC_CMD, ( unsigned short ) strlen( ESC_CMD ) )
#define cmdERASE_LINE_FROM_CURSOR(PORT) cmdSEND_ESC_CMD(PORT, cmdANSI_ESC_ERASE_LINE)
#define cmdSAVE_CURSOR(PORT)            cmdSEND_ESC_CMD(PORT, cmdANSI_ESC_SAVE_CURSOR)
#define cmdRESTORE_CURSOR(PORT)         cmdSEND_ESC_CMD(PORT, cmdANSI_ESC_RESTORE_CURSOR)
#define cmdMOVE_CURSOR_RIGHT(PORT, POS) {      \
	char tmpEsc[5] = {0, 0, 0, 0, 0};            \
	sprintf(tmpEsc, cmdANSI_ESC_RIGHT_FMT, POS); \
	cmdSEND_ESC_CMD(PORT, tmpEsc);               \
} 
#define cmdMOVE_CURSOR_LEFT(PORT, POS)  {     \
	char tmpEsc[5] = {0, 0, 0, 0, 0};           \
	sprintf(tmpEsc, cmdANSI_ESC_LEFT_FMT, POS); \
	cmdSEND_ESC_CMD(PORT, tmpEsc);              \
}

/* Check if backspace is pressed */
#define cmdIS_BACKSPACE(myChar) ( ( myChar == cmdASCII_BACKSPACE ) )
#define cmdIS_DEL(myChar)       ( ( myChar == cmdASCII_DEL ) )
#define cmdIS_ESCAPE(myChar)    ( ( myChar == cmdASCII_ESC ) )

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

void vUARTCommandConsoleStart( configSTACK_DEPTH_TYPE usStackSize, UBaseType_t uxPriority );

#endif
