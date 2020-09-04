#include "xparameters.h"
#include "xgpio.h"
#include "AXI_SymbolCounter.h"
#include "platform.h"
#include <stdio.h>
#include "xil_printf.h"
#include "xil_types.h"
#include "xil_assert.h"
#include "xstatus.h"
#include "sleep.h"
#include "xuartps_hw.h"
/**************************** user definitions ********************************/
#define CHANNEL 1
//Processor base address redefinition
#define MODULE_BASE_ADDR XPAR_AXI_SYMBOLCOUNTER_0_S00_AXI_BASEADDR

//Processor registers' offset redefinition
#define UART_BASEADDR		XPAR_XUARTPS_0_BASEADDR
#define UART_CLOCK_HZ		XPAR_XUARTPS_0_CLOCK_HZ
#define INPUT_SIGNALS_REG_OFFSET 	AXI_SYMBOLCOUNTER_S00_AXI_SLV_REG0_OFFSET
#define INPUT_SYMBOL_REG_OFFSET 	AXI_SYMBOLCOUNTER_S00_AXI_SLV_REG1_OFFSET
#define OUTPUT_REG_OFFSET 			AXI_SYMBOLCOUNTER_S00_AXI_SLV_REG2_OFFSET
#define OUTPUT_SIGNALS_OFFSET 		AXI_SYMBOLCOUNTER_S00_AXI_SLV_REG3_OFFSET
#define OUTPUT_READY_COUNT(param) ((u32)param & (u32)(0x00000001))
#define OUTPUT_REG_COUNT(param) ((u32)param & (u32)(0x000000FF))
#define OUTPUT_REG_SYMBOL(param) (((u32)param & (u32)(0x00FF0000)) >> 16 )
/***************************** Main function *********************************/
int main(){
int status;
XGpio inputSignalsGpio, readyGpio;
u32 mode, reset, end_flag, symbolInput, input_signals;
u32 result, symbolOut, countOut, ready;

/* Initialize driver for the mode GPIOe */
status = XGpio_Initialize(&inputSignalsGpio, XPAR_AXI_GPIO_INPUT_SIGNALS_DEVICE_ID);
if (status != XST_SUCCESS) {
goto FAILURE;
} XGpio_SetDataDirection(&inputSignalsGpio, CHANNEL, 0xFF);

status = XGpio_Initialize(&readyGpio, XPAR_AXI_GPIO_READY_DEVICE_ID);
if (status != XST_SUCCESS) {
goto FAILURE;
} XGpio_SetDataDirection(&readyGpio, CHANNEL, 0xFF);

int iterator = 0;
u32 Timer = 1000;
char alphabet[256] = "abc "; //"abcdefghijklmnopqrstuvwxyz ";
char text[256] = "aaa"; //"lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore et dolore magna aliqua";

init_platform();
print("Starting... \n");

//force reset

symbolInput = alphabet[iterator];
input_signals = 0x01;
AXI_SYMBOLCOUNTER_mWriteReg(MODULE_BASE_ADDR, INPUT_SIGNALS_REG_OFFSET, input_signals);


//Read input signals from GPIO (switches)
//Bit 0 - local restart
//Bit 1 - start
//Bit 2 - mode (0 - alphabet, 1 - text)
//Bit 3 - end_flag (1 - end of transmission)

input_signals = XGpio_DiscreteRead(&inputSignalsGpio, CHANNEL);
XGpio_DiscreteWrite(&readyGpio, CHANNEL, (u32)0x00);

//Select start bit to 0
input_signals = input_signals & ~0x02;
AXI_SYMBOLCOUNTER_mWriteReg(MODULE_BASE_ADDR, INPUT_SIGNALS_REG_OFFSET, input_signals);

//Select start bit to 1
input_signals = input_signals | 0x02;
AXI_SYMBOLCOUNTER_mWriteReg(MODULE_BASE_ADDR, INPUT_SIGNALS_REG_OFFSET, input_signals);

usleep(Timer);

while(1){
	reset = input_signals & 0x01;
	mode = input_signals & 0x04;
	end_flag = input_signals & 0x08;

	ready = ((AXI_SYMBOLCOUNTER_mReadReg(MODULE_BASE_ADDR, OUTPUT_SIGNALS_OFFSET) & OUTPUT_READY_COUNT( (u32)0x01)));
	if(ready)
	{
		if (reset == 0)
		{

			//Select start bit to 0
			input_signals = input_signals & ~0x02;
			AXI_SYMBOLCOUNTER_mWriteReg(MODULE_BASE_ADDR, INPUT_SIGNALS_REG_OFFSET, input_signals);

			//Select start bit to 1
			input_signals = input_signals | 0x02;
			AXI_SYMBOLCOUNTER_mWriteReg(MODULE_BASE_ADDR, INPUT_SIGNALS_REG_OFFSET, input_signals);

			if(end_flag == 0)
			{
				if(mode == 0) //insert alphabet to processor memory
				{
					if(alphabet[iterator] != 0)
					{
						symbolInput = alphabet[iterator];
						iterator++;
					}
					else
					{
						input_signals = input_signals | 0x04;
						iterator = 0;
					}
				}
				else //mode == 1, input text
				{
					if(text[iterator] != 0)
					{
						symbolInput = text[iterator];
						iterator++;
					}
					else
					{
						input_signals = input_signals | 0x08;
						iterator = 0;
					}
				} //mode

			}
			else
			{
				//Get results
				result = AXI_SYMBOLCOUNTER_mReadReg(MODULE_BASE_ADDR, OUTPUT_REG_OFFSET);
				countOut = OUTPUT_REG_COUNT( result );
				symbolOut = OUTPUT_REG_SYMBOL( result );
				xil_printf("SYMBOL: '%c' OCCURENCES: %d\n", symbolOut, countOut);
				if(symbolOut == 0x00)
				{
					input_signals = (input_signals & ~0x08) | 0x01;
					xil_printf("SUM: %d\n", iterator);
				}
				iterator = iterator + countOut;
			} //end_flag

		}
		else
		{
			iterator = 0;
		}

	}

	AXI_SYMBOLCOUNTER_mWriteReg(MODULE_BASE_ADDR, INPUT_SYMBOL_REG_OFFSET, symbolInput);
	AXI_SYMBOLCOUNTER_mWriteReg(MODULE_BASE_ADDR, INPUT_SIGNALS_REG_OFFSET, input_signals);
}

cleanup_platform();
return 0;

/* Failure or end trap */
FAILURE:
	while(1);
}
