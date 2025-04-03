/* 
 * Opsero Electronic Design Inc. Copyright 2024
 * 
******************************************************************************/

#include "i2c.h"
#include "xparameters.h"

#ifdef XPAR_XIIC_NUM_INSTANCES
#include "xiic.h"
#endif
#ifdef XPAR_XIICPS_NUM_INSTANCES
#include "xiicps.h"
#endif
#include "sleep.h"

#define IIC_MAX_INSTANCES 10

/************************** Variable Definitions *****************************/

u8 IicNumInstances = 0;
IicIntHandlerInfo IicIntHandlerInfoArray[IIC_MAX_INSTANCES];

/************************** Function Definitions *****************************/

#ifndef XPAR_XIIC_NUM_INSTANCES
/*
 * IIC Write function
 */
int IicWrite(u8 index,u8 addr,u8 *buf, u16 len)
{
	return IicPsWrite(index,addr,buf,len);
}

/*
 * IIC Read function
 */
int IicRead(u8 index,u8 addr, u8 *buf, u16 len)
{
	return IicPsRead(index,addr,buf,len);
}

/*
 * IIC Reset function
 */
int IicReset(u8 index)
{
	XIicPs_Reset((XIicPs *)IicIntHandlerInfoArray[index].Iic);
}

#endif

#ifndef XPAR_XIICPS_NUM_INSTANCES
/*
 * IIC Write function
 */
int IicWrite(u8 index,u8 addr,u8 *buf, u16 len)
{
	return IicAxiWrite(index,addr,buf,len);
}

/*
 * IIC Read function
 */
int IicRead(u8 index,u8 addr, u8 *buf, u16 len)
{
	return IicAxiRead(index,addr,buf,len);
}

/*
 * IIC Reset function
 */
int IicReset(u8 index)
{
	XIic_Reset((XIic *)IicIntHandlerInfoArray[index].Iic);
}

#endif

#if defined(XPAR_XIIC_NUM_INSTANCES) && defined(XPAR_XIICPS_NUM_INSTANCES)
/*
 * IIC Write function
 * Determines the IIC type (AXI or PS) and calls the appropriate function
 */
int IicWrite(u8 index,u8 addr,u8 *buf, u16 len)
{
	if(IicIntHandlerInfoArray[index].IicType == IIC_TYPE_AXI_IIC)
		return IicAxiWrite(index,addr,buf,len);
	else
		return IicPsWrite(index,addr,buf,len);
}

/*
 * IIC Read function
 * Determines the IIC type (AXI or PS) and calls the appropriate function
 */
int IicRead(u8 index,u8 addr, u8 *buf, u16 len)
{
	if(IicIntHandlerInfoArray[index].IicType == IIC_TYPE_AXI_IIC)
		return IicAxiRead(index,addr,buf,len);
	else
		return IicPsRead(index,addr,buf,len);
}

/*
 * IIC Reset function
 */
int IicReset(u8 index)
{
	if(IicIntHandlerInfoArray[index].IicType == IIC_TYPE_AXI_IIC)
		XIic_Reset((XIic *)IicIntHandlerInfoArray[index].Iic);
	else
		XIicPs_Reset((XIicPs *)IicIntHandlerInfoArray[index].Iic);
}

#endif

#ifdef XPAR_XIIC_NUM_INSTANCES
/*
 * Initialize IIC for AXI IIC
 */
int IicAxiInit(XIic *IicInstance, u16 DeviceId, INTC_TYPE *Intc, u16 VectorId, u8 *Index)
{
	int Status;
	XIic_Config *ConfigPtr;

	// Initialize IIC
	ConfigPtr = XIic_LookupConfig(DeviceId);
	if (ConfigPtr == NULL) {
		xil_printf("IicAxiInit: Failed IIC lookup config\n\r");
		return XST_FAILURE;
	}

	Status = XIic_CfgInitialize(IicInstance, ConfigPtr,
			ConfigPtr->BaseAddress);
	if (Status != XST_SUCCESS) {
		xil_printf("IicAxiInit: Failed IIC config initialize\n\r");
		return XST_FAILURE;
	}

	// Initialize the IIC interrupt handler info
	IicIntHandlerInfoArray[IicNumInstances].Iic = IicInstance;
	IicIntHandlerInfoArray[IicNumInstances].IicType = IIC_TYPE_AXI_IIC;
	IicIntHandlerInfoArray[IicNumInstances].ReceiveComplete = 0;
	IicIntHandlerInfoArray[IicNumInstances].TransmitComplete = 0;
	IicIntHandlerInfoArray[IicNumInstances].ErrorCount = 0;

	// Setup interrupt system
#ifdef XPAR_XSCUGIC_NUM_INSTANCES
	XScuGic_SetPriorityTriggerType(Intc, VectorId,	0xA0, 0x3);

	Status = XScuGic_Connect(Intc, VectorId,
				 (Xil_InterruptHandler)XIic_InterruptHandler,
				 IicInstance);
	if (Status != XST_SUCCESS) {
		return Status;
	}

	XScuGic_Enable(Intc, VectorId);
#endif
#ifdef XPAR_XINTC_NUM_INSTANCES
	Status = XIntc_Connect(Intc, VectorId,
				   (XInterruptHandler) XIic_InterruptHandler,
				   IicInstance);
	if (Status != XST_SUCCESS) {
		return Status;
	}

	Status = XIntc_Start(Intc, XIN_REAL_MODE);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	XIntc_Enable(Intc, VectorId);
#endif

	// Set the Handlers for transmit and reception.
	XIic_SetSendHandler(IicInstance,
			&IicIntHandlerInfoArray[IicNumInstances],(XIic_Handler) IicAxiSendHandler);
	XIic_SetRecvHandler(IicInstance,
			&IicIntHandlerInfoArray[IicNumInstances],(XIic_Handler) IicAxiRecvHandler);
	XIic_SetStatusHandler(IicInstance,
			&IicIntHandlerInfoArray[IicNumInstances],(XIic_StatusHandler) IicAxiStatusHandler);

	// Increment the number of IIC instances attached to the driver
	*Index = IicNumInstances;
	IicNumInstances++;

	return(XST_SUCCESS);
}

/*
 * AXI IIC Write function
 */
int IicAxiWrite(u8 index,u8 addr,u8 *buf, u16 len)
{
	int Status;
	IicIntHandlerInfo *Info = &IicIntHandlerInfoArray[index];
	XIic *IicInstance = (XIic *)Info->Iic;

	// Set the Slave address.
	Status = XIic_SetAddress(IicInstance, XII_ADDR_TO_SEND_TYPE,addr);
	if (Status != XST_SUCCESS) {
		xil_printf("IicWrite: Failed to set address\n\r");
		return XST_FAILURE;
	}

	// Set the defaults.
	Info->TransmitComplete = 1;
	IicInstance->Stats.TxErrors = 0;

	/*
	 * Start the IIC device.
	 */
	Status = XIic_Start(IicInstance);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Send the Data.
	 */
	Status = XIic_MasterSend(IicInstance, buf, len);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Wait till the transmission is completed.
	 */
	for(int i = 0; i<1000; i++){
		if (((Info->TransmitComplete == 0) != 0) && (XIic_IsIicBusy(IicInstance) == FALSE))
			break;
		usleep(100);
	}

	/*
	 * Stop the IIC device.
	 */
	Status = XIic_Stop(IicInstance);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

/*
 * AXI IIC Read function
 */
int IicAxiRead(u8 index,u8 addr, u8 *buf, u16 len)
{
	int Status;
	volatile int timeout;
	IicIntHandlerInfo *Info = &IicIntHandlerInfoArray[index];
	XIic *IicInstance = (XIic *)Info->Iic;

	// Set the Slave address.
	Status = XIic_SetAddress(IicInstance, XII_ADDR_TO_SEND_TYPE,addr);
	if (Status != XST_SUCCESS) {
		xil_printf("IicWrite: Failed to set address\n\r");
		return XST_FAILURE;
	}

	// Set the Defaults.
	Info->ReceiveComplete = 1;

	// Start the IIC device.
	Status = XIic_Start(IicInstance);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	// Receive the Data.
	Status = XIic_MasterRecv(IicInstance, buf, len);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	// Wait till all the data is received.
	timeout = 1000000;
	while ((timeout) && (((Info->ReceiveComplete == 0) == 0) || (XIic_IsIicBusy(IicInstance) == TRUE))) {
		timeout--;
	}

	// If it timed out
	if(timeout == 0){
		return XST_FAILURE;
	}

	// Stop the IIC device.
	Status = XIic_Stop(IicInstance);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

/*
 * AXI IIC Send interrupt handler - called when I2C transmission is complete
 */
void IicAxiSendHandler(IicIntHandlerInfo *Info)
{
	Info->TransmitComplete = 0;
}

/*
 * IIC Receive interrupt handler - called when I2C reception is complete
 */
void IicAxiRecvHandler(IicIntHandlerInfo *Info)
{
	Info->ReceiveComplete = 0;
}

/*
 * IIC Status interrupt handler - not being used
 */
void IicAxiStatusHandler(IicIntHandlerInfo *Info, int Event)
{

}

#endif

#ifdef XPAR_XIICPS_NUM_INSTANCES
/*
 * Initialize IIC for PS IIC
 */
int IicPsInit(XIicPs *IicInstance, u16 DeviceId, INTC_TYPE *Intc, u16 VectorId, u8 *Index)
{
	XIicPs_Config *ConfigPtr;	/* Pointer to configuration data */
	int Status;

	// Initialize the IIC driver
	ConfigPtr = XIicPs_LookupConfig(DeviceId);
	if (ConfigPtr == NULL) {
		return XST_FAILURE;
	}

	Status = XIicPs_CfgInitialize(IicInstance, ConfigPtr,
					ConfigPtr->BaseAddress);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	XIicPs_SetStatusHandler(IicInstance,
			(void *)&IicIntHandlerInfoArray[IicNumInstances],
			(XIicPs_IntrHandler)IicPsInterruptHandler);

	// Set the IIC serial clock rate.
	XIicPs_SetSClk(IicInstance, IIC_SCLK_RATE);

	// Initialize the IIC interrupt handler info
	IicIntHandlerInfoArray[IicNumInstances].Iic = IicInstance;
	IicIntHandlerInfoArray[IicNumInstances].IicType = IIC_TYPE_PS_IIC;
	IicIntHandlerInfoArray[IicNumInstances].ReceiveComplete = 0;
	IicIntHandlerInfoArray[IicNumInstances].TransmitComplete = 0;
	IicIntHandlerInfoArray[IicNumInstances].ErrorCount = 0;

#ifdef XPAR_XSCUGIC_NUM_INSTANCES
	Status = XScuGic_Connect(Intc, VectorId,
	    (Xil_InterruptHandler)XIicPs_MasterInterruptHandler,
	    (void *)IicInstance);
	if (Status != XST_SUCCESS) {
	  return Status;
	}
	XScuGic_Enable(Intc, VectorId);
#endif
#ifdef XPAR_XINTC_NUM_INSTANCES
	Status = XIntc_Connect(Intc, VectorId,
				   (XInterruptHandler) XIic_InterruptHandler,
				   IicInstance);
	if (Status != XST_SUCCESS) {
		return Status;
	}

	Status = XIntc_Start(Intc, XIN_REAL_MODE);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	XIntc_Enable(Intc, VectorId);
#endif

	// Increment the number of IIC instances attached to the driver
	*Index = IicNumInstances;
	IicNumInstances++;

	return(XST_SUCCESS);
}

/*
 * IIC PS Interrupt handler
 */
void IicPsInterruptHandler(IicIntHandlerInfo *Info, u32 Event)
{
	// All of the data transfer has been finished.
	if (0 != (Event & XIICPS_EVENT_COMPLETE_RECV)){
		Info->ReceiveComplete = TRUE;
	} else if (0 != (Event & XIICPS_EVENT_COMPLETE_SEND)) {
		Info->TransmitComplete = TRUE;
	} else if (0 == (Event & XIICPS_EVENT_SLAVE_RDY)){
		/*
		 * If it is other interrupt but not slave ready interrupt, it is
		 * an error.
		 * Data was received with an error.
		 */
		Info->ErrorCount++;
	}
}

/*
 * PS IIC write function
 */
int IicPsWrite(u8 index, u8 addr, u8 *buf,u16 len)
{
	IicIntHandlerInfo *Info = &IicIntHandlerInfoArray[index];
	XIicPs *IicInstance = (XIicPs *)Info->Iic;
	Info->TransmitComplete = FALSE;

	XIicPs_MasterSend(IicInstance, buf,len, addr);
	while (Info->TransmitComplete == FALSE) {
		if (0 != Info->ErrorCount) {
			Info->ErrorCount = 0;
			while (XIicPs_BusIsBusy(IicInstance));
			return XST_FAILURE;
		}
	}

	 // Wait until bus is idle to start another transfer.
	while (XIicPs_BusIsBusy(IicInstance));
	Info->ReceiveComplete = FALSE;

	return XST_SUCCESS;
}

/*
 * PS IIC read function
 */
int IicPsRead(u8 index, u8 addr, u8 *buf,u16 len)
{
	IicIntHandlerInfo *Info = &IicIntHandlerInfoArray[index];
	XIicPs *IicInstance = (XIicPs *)Info->Iic;
	Info->ReceiveComplete = FALSE;

	// Receive the data
	XIicPs_MasterRecv(IicInstance, buf,len, addr);
	while (Info->ReceiveComplete == FALSE) {
		if (0 != Info->ErrorCount) {
			Info->ErrorCount = 0;
			while (XIicPs_BusIsBusy(IicInstance));
			return XST_FAILURE;
		}
	}
	// Wait until bus is idle to start another transfer.
	while (XIicPs_BusIsBusy(IicInstance));
	return XST_SUCCESS;
}

#endif

