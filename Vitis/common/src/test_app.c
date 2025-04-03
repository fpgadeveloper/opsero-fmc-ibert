/*
 * IBERT Test application for the MCIO PCIe Host FMC
 * The purpose of this application is to configure the TX and RX redrivers
 * so that the IBERT test will actually function.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "xil_printf.h"
#include "xparameters.h"
#include "xrtcpsu.h"    /* RTCPSU device driver */
#include "xscugic.h"
#include "xiicps.h"
#include "i2c.h"
#include "sleep.h"
#include "board.h"
#include "ds320pr810.h"

// Peripherals

#define INTC_DEVICE_ID  XPAR_SCUGIC_SINGLE_DEVICE_ID

// Redriver I2C addresses
#define I2C_ADDR_RX_RDRV_CH_A 0x18
#define I2C_ADDR_RX_RDRV_CH_B 0x19
#define I2C_ADDR_TX_RDRV_CH_A 0x1A
#define I2C_ADDR_TX_RDRV_CH_B 0x1B

#define MAX_STR_LEN 32

XScuGic Intc;  /* The instance of the Interrupt Controller. */

u8 RdrvI2cId;
XIicPs RdrvI2c; // I2C device for the redrivers
DS320PR810 RxRdrv; // RX Redriver on MCIO PCIe Host FMC
DS320PR810 TxRdrv; // TX Redriver on MCIO PCIe Host FMC


void print_heading()
{
	xil_printf("====================================================\n\r");
	xil_printf("IBERT test for Opsero MCIO PCIe Host FMC v%s\n\r",VITIS_VERSION);
	xil_printf("====================================================\n\r");
}

int get_input_str(char *str)
{
	char input;
	int i;

	i = 0;

	while(1){
		// Get one character input
		input = getchar();

		// When user presses ENTER
		if(input == 13){
			str[i] = 0;
			xil_printf("\r\n");
			break;
		}
		// When user presses BACKSPACE
		if(input == 8){
			if(i>0){
				i--;
				xil_printf("%c",input);
			}
		}
		// When we receive DEL
		else if(input == 0x7F){
			if(i>0){
				i--;
				xil_printf("%c",input);
			}
		}
		else{
			str[i] = input;
			xil_printf("%c",input);
			i++;
		}
	}
	return(XST_SUCCESS);
}

int is_valid_ctle_index(const char *str) {
    char *endptr;
    int val = strtol(str, &endptr, 10);
    return (*endptr == '\0') && (val >= 0 && val <= 19);
}

int is_valid_flat_gain(const char *str) {
    int valid = (strcmp(str, "-6") == 0 || strcmp(str, "-4") == 0 ||
                 strcmp(str, "-2") == 0 || strcmp(str, "0") == 0 ||
                 strcmp(str, "2") == 0);
    return valid;
}

int set_eq_and_flat_gain(DS320PR810 *ds,int ctle_index,int flat_gain)
{
	int fg = (flat_gain + 6) / 2;
	// Set the eq index and flat gain on all channels
	for(u8 bank = 0; bank < 2; bank++) {
		for(u8 ch = 0; ch < 4; ch++) {
			ds320pr810_set_eq_and_flat_gain(ds, bank, ch, (u8)ctle_index, (u8)fg);
		}
	}
}

int main()
{
	XScuGic_Config *IntcConfig;
	int Status;
    char str[MAX_STR_LEN];
    int tx_ctle_index = 3;
    int tx_flat_gain = 0;
    int rx_ctle_index = 3;
    int rx_flat_gain = 0;
    int txrx = 0;

	// Setup getchar to return char without waiting for ENTER
	setvbuf(stdin, NULL, _IONBF, 0);

	/*
	 * Initialize the interrupt controller
	 * The init functions of the I2C driver will setup and
	 * enable their respective interrupts later.
	 */
	IntcConfig = XScuGic_LookupConfig(INTC_DEVICE_ID);
	if (NULL == IntcConfig) {
		return XST_FAILURE;
	}
	Status = XScuGic_CfgInitialize(&Intc, IntcConfig, IntcConfig->CpuBaseAddress);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	// Initialize exceptions
	Xil_ExceptionInit();
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_IRQ_INT,
			(Xil_ExceptionHandler)XScuGic_DeviceInterruptHandler,
			INTC_DEVICE_ID);
	// Enable exceptions for interrupts
	Xil_ExceptionEnableMask(XIL_EXCEPTION_IRQ);
	Xil_ExceptionEnable();

	/*
	 * Initialize the IIC for communication with FMC
	 */
	Status = IicPsInit(&RdrvI2c,XPAR_VERSAL_CIPS_0_PSPMC_0_PSV_I2C_0_DEVICE_ID,&Intc,XPAR_XIICPS_0_INTR,&RdrvI2cId);
	if (Status != XST_SUCCESS) {
		xil_printf("Failed to initialize the RdrvI2c\n\r");
		return XST_FAILURE;
	}

	/*
	 * Initialize the Redrivers on the MCIO PCIe Host FMC
	 */
	ds320pr810_init(&RxRdrv,RdrvI2cId,I2C_ADDR_RX_RDRV_CH_A,I2C_ADDR_RX_RDRV_CH_B);
	ds320pr810_init(&TxRdrv,RdrvI2cId,I2C_ADDR_TX_RDRV_CH_A,I2C_ADDR_TX_RDRV_CH_B);

	// Test communication with the redrivers
	Status = ds320pr810_check_device_id(&RxRdrv);
	if(Status != XST_SUCCESS) {
		xil_printf("general_tests: ERROR: Failed to confirm RX Redriver device IDs\n\r");
		return XST_FAILURE;
	}
	Status = ds320pr810_check_device_id(&TxRdrv);
	if(Status != XST_SUCCESS) {
		xil_printf("general_tests: ERROR: Failed to confirm TX Redriver device IDs\n\r");
		return XST_FAILURE;
	}

    while (1) {
    	print_heading();
        xil_printf("  (1) Set TX CTLE index [%2d]    (3) Set TX Flat gain [%2d dB]\n\r",tx_ctle_index,tx_flat_gain);
        xil_printf("  (2) Set RX CTLE index [%2d]    (4) Set RX Flat gain [%2d dB]\n\r",rx_ctle_index,rx_flat_gain);
        xil_printf("Type option and press ENTER: ");

        get_input_str(str);

        if (strlen(str) == 0) {
            // Refresh menu
            continue;
        }

        if ((str[0] == 'q') || (str[0] == 'Q')) {
            break;
        }

        if ((str[0] == '1') || (str[0] == '2')) {
        	txrx = (str[0] == '1') ? 0:1;
            xil_printf("Enter %s CTLE index (0-19): ",txrx ? "RX":"TX");
            get_input_str(str);
            if (is_valid_ctle_index(str)) {
                if(txrx) {
                    rx_ctle_index = atoi(str);
                    xil_printf("CTLE index set to %d\n\r", rx_ctle_index);
                	set_eq_and_flat_gain(&RxRdrv,rx_ctle_index,rx_flat_gain);
                }
                else {
                    tx_ctle_index = atoi(str);
                    xil_printf("CTLE index set to %d\n\r", tx_ctle_index);
                	set_eq_and_flat_gain(&TxRdrv,tx_ctle_index,tx_flat_gain);
                }
            } else {
                xil_printf("Invalid CTLE index. Must be 0-19.\n\r");
            }
        } else if ((str[0] == '3') || (str[0] == '4')) {
        	txrx = (str[0] == '3') ? 0:1;
            xil_printf("Enter %s Flat gain (-6, -4, -2, 0, 2): ",txrx ? "RX":"TX");
            get_input_str(str);
            if (is_valid_flat_gain(str)) {
                if(txrx) {
                    rx_flat_gain = atoi(str);
                    xil_printf("Flat gain set to %d dB\n\r", rx_flat_gain);
                	set_eq_and_flat_gain(&RxRdrv,rx_ctle_index,rx_flat_gain);
                }
                else {
                    tx_flat_gain = atoi(str);
                    xil_printf("Flat gain set to %d dB\n\r", tx_flat_gain);
                	set_eq_and_flat_gain(&TxRdrv,tx_ctle_index,tx_flat_gain);
                }
            } else {
                xil_printf("Invalid Flat gain. Must be one of: -6, -4, -2, 0, 2.\n\r");
            }
        } else {
            xil_printf("Invalid option.\n\r");
        }
    }

	xil_printf("End of the program\n\r");
	return 0;
}

