/*
 * Opsero Electronic Design Inc. Copyright 2025
 *
  * A simple driver for the DS320PR810 Linear Redriver
 */

#ifndef DS320PR810_H_
#define DS320PR810_H_

#include "xil_types.h"
#include "board.h"

#define SIZEOF_ARRAY(x) sizeof(x)/sizeof(x[0])

#define DS320PR810_BANK_0 0
#define DS320PR810_BANK_1 1

// Share registers
#define DS320PR810_REG_GENERAL       0xE2
#define DS320PR810_REG_EEPROM_STATUS 0xE3
#define DS320PR810_REG_DEVICE_ID0    0xF0
#define DS320PR810_REG_DEVICE_ID1    0xF1

// Channel registers (bases and offsets)
#define DS320PR810_CH0_REG_BASE      0x00
#define DS320PR810_CH1_REG_BASE      0x20
#define DS320PR810_CH2_REG_BASE      0x40
#define DS320PR810_CH3_REG_BASE      0x60
#define DS320PR810_OFFSET_RX_DETECT_STATUS     0x00
#define DS320PR810_OFFSET_EQ_CONTROL           0x01
#define DS320PR810_OFFSET_MUTE_EQ_CONTROL      0x02
#define DS320PR810_OFFSET_EQ_FLAT_GAIN_CONTROL 0x03
#define DS320PR810_OFFSET_RX_DETECT_CONTROL    0x04
#define DS320PR810_OFFSET_PD_OVERRIDE          0x05
#define DS320PR810_OFFSET_BIAS                 0x06

// Flat gain values
#define DS320PR810_FLAT_GAIN_MINUS_6DB 0
#define DS320PR810_FLAT_GAIN_MINUS_4DB 1
#define DS320PR810_FLAT_GAIN_MINUS_2DB 2
#define DS320PR810_FLAT_GAIN_0DB 3
#define DS320PR810_FLAT_GAIN_PLUS_2DB 4

typedef struct {
	u8 iic_id;
	u8 addr_bank_0;
	u8 addr_bank_1;
} DS320PR810;

int ds320pr810_set_eq_and_flat_gain(DS320PR810 *ds, u8 bank, u8 ch, u8 eq_index, u8 flat_gain);
int ds320pr810_check_device_id(DS320PR810 *ds320pr810);
int ds320pr810_init(DS320PR810 *ds320pr810,u8 iic_id,u8 addr_bank_0,u8 addr_bank_1);
int ds320pr810_write(DS320PR810 *ds320pr810, u8 bank, u8 reg, uint8_t data);
int ds320pr810_read(DS320PR810 *ds320pr810, u8 bank, u8 reg, uint8_t *data);

#endif /* DS320PR810_H_ */
