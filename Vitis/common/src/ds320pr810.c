/*
 * Opsero Electronic Design Inc. Copyright 2025
 *
 * A simple driver for the DS320PR810 Linear Redriver
 */

#include "xstatus.h"
#include "xil_printf.h"
#include "sleep.h"
#include "ds320pr810.h"
#include "i2c.h"

#define NUM_CHANNELS 4
#define EQ_INDEX_MAX 19
#define FLAT_GAIN_LEVELS 5
#define MUTE_ENABLE 0x01
#define MUTE_DISABLE 0x00
#define POWERDOWN_ENABLE 0x01
#define POWERDOWN_DISABLE 0x00

// Lookup table for EQ index encoding (Table 3-1 from programming guide)
static const u8 eq_control_table[EQ_INDEX_MAX + 1] = {
		(0 << 3) + (0) + (1 << 7),
		(1 << 3) + (0) + (1 << 7),
		(3 << 3) + (0) + (1 << 7),
		(0 << 3) + (0),
		(0 << 3) + (0),
		(0 << 3) + (0),
		(1 << 3) + (0),
		(2 << 3) + (0),
		(3 << 3) + (0),
		(4 << 3) + (0),
		(5 << 3) + (1),
		(6 << 3) + (1),
		(8 << 3) + (1),
		(10 << 3) + (1),
		(10 << 3) + (2),
		(11 << 3) + (3),
		(12 << 3) + (4),
		(13 << 3) + (5),
		(14 << 3) + (6),
		(15 << 3) + (7),
};

// Lookup table for EQ level encoding (Table 3-1 from programming guide)
static const u8 eq_gain_table[EQ_INDEX_MAX + 1] = {
		(0 << 3),
		(0 << 3),
		(0 << 3),
		(0 << 3),
		(0 << 3),
		(1 << 3),
		(1 << 3),
		(1 << 3),
		(3 << 3),
		(3 << 3),
		(7 << 3),
		(7 << 3),
		(7 << 3),
		(7 << 3),
		(15 << 3),
		(15 << 3),
		(15 << 3),
		(15 << 3),
		(15 << 3),
		(15 << 3),
};

// Flat gain -6dB, -4dB, -2dB, 0dB and 2dB (Table 4-1 from programming guide)
static const u8 flat_gain_table[FLAT_GAIN_LEVELS] = {
		0x00, 0x01, 0x03, 0x05, 0x07
};

static const u8 ch_reg_base_table[NUM_CHANNELS] = {
		DS320PR810_CH0_REG_BASE,
		DS320PR810_CH1_REG_BASE,
		DS320PR810_CH2_REG_BASE,
		DS320PR810_CH3_REG_BASE
};

// Set the equalization index (0-19) and flat gain (-6dB, -4dB, -2dB, 0dB, 2dB)
int ds320pr810_set_eq_and_flat_gain(DS320PR810 *ds, u8 bank, u8 ch, u8 eq_index, u8 flat_gain)
{
	if (eq_index > EQ_INDEX_MAX) {
		xil_printf("ds320pr810_set_eq_and_flat_gain: EQ level out of range: %d\n", eq_index);
		return XST_FAILURE;
	}
	if (flat_gain > FLAT_GAIN_LEVELS) {
		xil_printf("ds320pr810_set_eq_and_flat_gain: EQ level out of range: %d\n", flat_gain);
		return XST_FAILURE;
	}
	u8 data = eq_control_table[eq_index];
	u8 ch_base_reg = ch_reg_base_table[ch];
	int status;
	// Set EQ_CONTROL register
	status = ds320pr810_write(ds, bank, ch_base_reg+DS320PR810_OFFSET_EQ_CONTROL, data);
	if(status == XST_FAILURE) {
		xil_printf("ds320pr810_set_eq_and_flat_gain: Failed to set EQ_CONTROL register\n\r");
		return(XST_FAILURE);
	}
	// Set EQ_FLAT_GAIN_CONTROL register
	data = eq_gain_table[eq_index] | flat_gain_table[flat_gain];
	status = ds320pr810_write(ds, bank, ch_base_reg+DS320PR810_OFFSET_EQ_FLAT_GAIN_CONTROL, data);
	if(status == XST_FAILURE) {
		xil_printf("ds320pr810_set_eq_and_flat_gain: Failed to set EQ_FLAT_GAIN_CONTROL register\n\r");
		return(XST_FAILURE);
	}
	return(XST_SUCCESS);
}

/*
 * Check that the device ID matches with expected
 */
int ds320pr810_check_device_id(DS320PR810 *ds320pr810)
{
	uint8_t data;
	int status = XST_SUCCESS;
	// Check channel A device ID
	ds320pr810_read(ds320pr810, DS320PR810_BANK_0, DS320PR810_REG_DEVICE_ID0, &data);
	if(data != 0x16) {
		xil_printf("ds320pr810_check_device_id: ChA Read 0x%02X, expected 0x%02X\n\r",data,0x16);
		status = XST_FAILURE;
	}
	ds320pr810_read(ds320pr810, DS320PR810_BANK_0, DS320PR810_REG_DEVICE_ID1, &data);
	if(data != 0x29) {
		xil_printf("ChA Read 0x%02X, expected 0x%02X\n\r",data,0x29);
		status = XST_FAILURE;
	}
	// Check channel B device ID
	ds320pr810_read(ds320pr810, DS320PR810_BANK_1, DS320PR810_REG_DEVICE_ID0, &data);
	if(data != 0x17) {
		xil_printf("ChB Read 0x%02X, expected 0x%02X\n\r",data,0x17);
		status = XST_FAILURE;
	}
	ds320pr810_read(ds320pr810, DS320PR810_BANK_1, DS320PR810_REG_DEVICE_ID1, &data);
	if(data != 0x29) {
		xil_printf("ChB Read 0x%02X, expected 0x%02X\n\r",data,0x29);
		status = XST_FAILURE;
	}
	return(status);
}

/*
 * Initialize the DS320PR810 driver with a pointer to the I2C instance.
 * The function is also provided with the I2C addresses of channel A and channel B.
 */

int ds320pr810_init(DS320PR810 *ds320pr810,u8 iic_id,u8 addr_bank_0,u8 addr_bank_1)
{
	// Copy the IIC identifier (index) that connects to the DS320PR810
	ds320pr810->iic_id = iic_id;
	// Copy the ChA and ChB addresses
	ds320pr810->addr_bank_0 = addr_bank_0;
	ds320pr810->addr_bank_1 = addr_bank_1;

	return XST_SUCCESS;
}

// Write to the DS320PR810
int ds320pr810_write(DS320PR810 *ds320pr810, u8 bank, u8 reg, uint8_t data)
{
	int Status;
	// Determine the I2C address
	u8 i2c_addr;
	if(bank == DS320PR810_BANK_0)
		i2c_addr = ds320pr810->addr_bank_0;
	else
		i2c_addr = ds320pr810->addr_bank_1;
	// Write to DS320PR810 register
	uint8_t buf[10];
	buf[0] = reg;
	buf[1] = data;
	Status = IicWrite(ds320pr810->iic_id,i2c_addr,buf,2);
	if (Status != XST_SUCCESS) {
		xil_printf("ERROR: ds320pr810_write failed\n\r");
	}
	return Status;
}

// Read from a register of the DS320PR810
int ds320pr810_read(DS320PR810 *ds320pr810, u8 bank, u8 reg, uint8_t *data)
{
	int Status;
	uint8_t buf[10];
	// Determine the I2C address
	u8 i2c_addr;
	if(bank == DS320PR810_BANK_0)
		i2c_addr = ds320pr810->addr_bank_0;
	else
		i2c_addr = ds320pr810->addr_bank_1;
	// Write the address of the register to read
	buf[0] = reg;
	Status = IicWrite(ds320pr810->iic_id,i2c_addr,buf,1);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	// Read the DS320PR810 register
	Status = IicRead(ds320pr810->iic_id,i2c_addr,buf,1);
	if (Status != XST_SUCCESS) {
		xil_printf("ERROR: ds320pr810_read failed to read\n\r");
		return(Status);
	}
	*data = buf[0];
	return Status;
}
