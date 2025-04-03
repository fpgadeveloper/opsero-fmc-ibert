#------------------------------------------
# Constraints for Opsero MCIO PCIe Host FMC
#------------------------------------------

# Channel A SSD PCIe reset (perst_n_a)
set_property PACKAGE_PIN AV30 [get_ports {perst_n_a[0]}]; # LA00_CC_P
set_property IOSTANDARD LVCMOS15 [get_ports {perst_n_a[0]}]

# Channel B SSD PCIe reset (perst_n_b)
set_property PACKAGE_PIN BA31 [get_ports {perst_n_b[0]}]; # LA04_P
set_property IOSTANDARD LVCMOS15 [get_ports {perst_n_b[0]}]

# Channel A SSD Present (cprsnt_n_a, not connected in the design)
# set_property PACKAGE_PIN AW30 [get_ports {cprsnt_n_a[0]}]; # LA00_CC_N
# set_property IOSTANDARD LVCMOS15 [get_ports {cprsnt_n_a[0]}]

# Channel B SSD Present (cprsnt_n_b, not connected in the design)
# set_property PACKAGE_PIN BB31 [get_ports {cprsnt_n_b[0]}]; # LA04_N
# set_property IOSTANDARD LVCMOS15 [get_ports {cprsnt_n_b[0]}]

# # MCIOA I2C signals
# set_property PACKAGE_PIN AP32 [get_ports mcioa_i2c_scl_io]; # LA12_P
# set_property PACKAGE_PIN AR32 [get_ports mcioa_i2c_sda_io]; # LA12_N
# set_property IOSTANDARD LVCMOS15 [get_ports mcioa_i2c_*]
# set_property SLEW SLOW [get_ports mcioa_i2c_*]
# set_property DRIVE 4 [get_ports mcioa_i2c_*]

# # MCIOB I2C signals
# set_property PACKAGE_PIN BB34 [get_ports mciob_i2c_scl_io]; # LA11_P
# set_property PACKAGE_PIN BB35 [get_ports mciob_i2c_sda_io]; # LA11_N
# set_property IOSTANDARD LVCMOS15 [get_ports mciob_i2c_*]
# set_property SLEW SLOW [get_ports mciob_i2c_*]
# set_property DRIVE 4 [get_ports mciob_i2c_*]

# RDRV I2C signals
set_property PACKAGE_PIN AT32 [get_ports rdrv_i2c_scl_io]; # LA15_P
set_property PACKAGE_PIN AU31 [get_ports rdrv_i2c_sda_io]; # LA15_N
set_property IOSTANDARD LVCMOS15 [get_ports rdrv_i2c_*]
set_property SLEW SLOW [get_ports rdrv_i2c_*]
set_property DRIVE 4 [get_ports rdrv_i2c_*]

