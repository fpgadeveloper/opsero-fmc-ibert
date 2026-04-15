#------------------------------------------
# Constraints for Opsero MCIO PCIe FMC
#------------------------------------------

# Channel A SSD PCIe reset (perst_n_a)
set_property PACKAGE_PIN BD23 [get_ports {perst_n_a[0]}]; # LA00_CC_P
set_property IOSTANDARD LVCMOS15 [get_ports {perst_n_a[0]}]

# Channel B SSD PCIe reset (perst_n_b)
set_property PACKAGE_PIN AU21 [get_ports {perst_n_b[0]}]; # LA04_P
set_property IOSTANDARD LVCMOS15 [get_ports {perst_n_b[0]}]

# Channel A SSD Present (cprsnt_n_a, not connected in the Vivado design)
# set_property PACKAGE_PIN BD24 [get_ports {cprsnt_n_a[0]}]; # LA00_CC_N
# set_property IOSTANDARD LVCMOS15 [get_ports {cprsnt_n_a[0]}]

# Channel B SSD Present (cprsnt_n_b, not connected in the Vivado design)
# set_property PACKAGE_PIN AV21 [get_ports {cprsnt_n_b[0]}]; # LA04_N
# set_property IOSTANDARD LVCMOS15 [get_ports {cprsnt_n_b[0]}]

# Host mode (HOST_MODE_N) and Local clocks select (LOCAL_CLKS_N)
set_property PACKAGE_PIN AU23 [get_ports local_clks_n]; # LA14_N
set_property IOSTANDARD LVCMOS15 [get_ports local_clks_n];
set_property PACKAGE_PIN AU24 [get_ports host_mode_n];  # LA14_P
set_property IOSTANDARD LVCMOS15 [get_ports host_mode_n];

# # MCIOA I2C signals
# set_property PACKAGE_PIN BG21 [get_ports mcioa_i2c_scl_io]; # LA12_P
# set_property PACKAGE_PIN BF22 [get_ports mcioa_i2c_sda_io]; # LA12_N
# set_property IOSTANDARD LVCMOS15 [get_ports mcioa_i2c_*]
# set_property SLEW SLOW [get_ports mcioa_i2c_*]
# set_property DRIVE 4 [get_ports mcioa_i2c_*]

# # MCIOB I2C signals
# set_property PACKAGE_PIN BF23 [get_ports mciob_i2c_scl_io]; # LA11_P
# set_property PACKAGE_PIN BE22 [get_ports mciob_i2c_sda_io]; # LA11_N
# set_property IOSTANDARD LVCMOS15 [get_ports mciob_i2c_*]
# set_property SLEW SLOW [get_ports mciob_i2c_*]
# set_property DRIVE 4 [get_ports mciob_i2c_*]

# RDRV I2C signals
set_property PACKAGE_PIN AY22 [get_ports rdrv_i2c_scl_io]; # LA15_P
set_property PACKAGE_PIN AY23 [get_ports rdrv_i2c_sda_io]; # LA15_N
set_property IOSTANDARD LVCMOS15 [get_ports rdrv_i2c_*]
set_property SLEW SLOW [get_ports rdrv_i2c_*]
set_property DRIVE 4 [get_ports rdrv_i2c_*]

