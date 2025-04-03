################################################################
# Block design build script for Versal designs
################################################################

# CHECKING IF PROJECT EXISTS
if { [get_projects -quiet] eq "" } {
   puts "ERROR: Please open or create a project!"
   return 1
}

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

#create_bd_design $block_name

current_bd_design $block_name

set parentCell [get_bd_cells /]

# Get object for parentCell
set parentObj [get_bd_cells $parentCell]
if { $parentObj == "" } {
   puts "ERROR: Unable to find parent cell <$parentCell>!"
   return
}

# Make sure parentObj is hier blk
set parentType [get_property TYPE $parentObj]
if { $parentType ne "hier" } {
   puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."
   return
}

# Save current instance; Restore later
set oldCurInst [current_bd_instance .]

# Set parent object as current
current_bd_instance $parentObj

# Logic for the MCIO PCIe Host FMC

# Create constant HIGH for the PCIe resets (active low)
set const_perst_n_a [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_perst_n_a ]
set_property -dict [list CONFIG.CONST_VAL {1} CONFIG.CONST_WIDTH {1}] $const_perst_n_a
create_bd_port -dir O perst_n_a
connect_bd_net [get_bd_pins const_perst_n_a/dout] [get_bd_ports perst_n_a]

set const_perst_n_b [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_perst_n_b ]
set_property -dict [list CONFIG.CONST_VAL {1} CONFIG.CONST_WIDTH {1}] $const_perst_n_b
create_bd_port -dir O perst_n_b
connect_bd_net [get_bd_pins const_perst_n_b/dout] [get_bd_ports perst_n_b]

# Configure CIPS using automation feature  
apply_bd_automation -rule xilinx.com:bd_rule:cips -config { \
  board_preset {Yes} \
  boot_config {Custom} \
  configure_noc {Add new AXI NoC} \
  debug_config {JTAG} \
  design_flow {Full System} \
  mc_type {LPDDR} \
  num_mc_ddr {None} \
  num_mc_lpddr {1} \
  pl_clocks {None} \
  pl_resets {None} \
}  [get_bd_cells versal_cips_0]

# Enable PS I2C0 and connect it to EMIO
set_property CONFIG.PS_PMC_CONFIG { \
  CLOCK_MODE {Custom} \
  DDR_MEMORY_MODE {Connectivity to DDR via NOC} \
  DEBUG_MODE {JTAG} \
  DESIGN_MODE {1} \
  DEVICE_INTEGRITY_MODE {Sysmon temperature voltage and external IO monitoring} \
  PMC_CRP_PL0_REF_CTRL_FREQMHZ {125} \
  PMC_GPIO0_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 0 .. 25}}} \
  PMC_GPIO1_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 26 .. 51}}} \
  PMC_I2CPMC_PERIPHERAL {{ENABLE 0} {IO {EMIO}}} \
  PMC_MIO12 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
  PMC_MIO37 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA high} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
  PMC_OSPI_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 0 .. 11}} {MODE Single}} \
  PMC_REF_CLK_FREQMHZ {33.3333} \
  PMC_SD1 {{CD_ENABLE 1} {CD_IO {PMC_MIO 28}} {POW_ENABLE 1} {POW_IO {PMC_MIO 51}} {RESET_ENABLE 0} {RESET_IO {PMC_MIO 12}} {WP_ENABLE 0} {WP_IO {PMC_MIO 1}}} \
  PMC_SD1_PERIPHERAL {{CLK_100_SDR_OTAP_DLY 0x3} {CLK_200_SDR_OTAP_DLY 0x2} {CLK_50_DDR_ITAP_DLY 0x36} {CLK_50_DDR_OTAP_DLY 0x3} {CLK_50_SDR_ITAP_DLY 0x2C} {CLK_50_SDR_OTAP_DLY 0x4} {ENABLE 1} {IO {PMC_MIO 26 .. 36}}} \
  PMC_SD1_SLOT_TYPE {SD 3.0} \
  PMC_USE_PMC_NOC_AXI0 {1} \
  PS_BOARD_INTERFACE {Custom} \
  PS_ENET0_MDIO {{ENABLE 1} {IO {PS_MIO 24 .. 25}}} \
  PS_ENET0_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 0 .. 11}}} \
  PS_GEN_IPI0_ENABLE {1} \
  PS_GEN_IPI0_MASTER {A72} \
  PS_GEN_IPI1_ENABLE {1} \
  PS_GEN_IPI2_ENABLE {1} \
  PS_GEN_IPI3_ENABLE {1} \
  PS_GEN_IPI4_ENABLE {1} \
  PS_GEN_IPI5_ENABLE {1} \
  PS_GEN_IPI6_ENABLE {1} \
  PS_HSDP_EGRESS_TRAFFIC {JTAG} \
  PS_HSDP_INGRESS_TRAFFIC {JTAG} \
  PS_HSDP_MODE {NONE} \
  PS_I2C0_PERIPHERAL {{ENABLE 1} {IO EMIO}} \
  PS_I2C1_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 44 .. 45}}} \
  PS_I2CSYSMON_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 39 .. 40}}} \
  PS_MIO7 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
  PS_MIO9 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
  PS_NUM_FABRIC_RESETS {0} \
  PS_PCIE_EP_RESET1_IO {PS_MIO 18} \
  PS_PCIE_EP_RESET2_IO {PS_MIO 19} \
  PS_PCIE_RESET {ENABLE 1} \
  PS_UART0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 42 .. 43}}} \
  PS_USB3_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 13 .. 25}}} \
  PS_USE_FPD_CCI_NOC {1} \
  PS_USE_FPD_CCI_NOC0 {1} \
  PS_USE_NOC_LPD_AXI0 {1} \
  PS_USE_PMCPL_CLK0 {1} \
  PS_USE_PMCPL_CLK1 {0} \
  PS_USE_PMCPL_CLK2 {0} \
  PS_USE_PMCPL_CLK3 {0} \
  SMON_ALARMS {Set_Alarms_On} \
  SMON_ENABLE_TEMP_AVERAGING {0} \
  SMON_INTERFACE_TO_USE {I2C} \
  SMON_PMBUS_ADDRESS {0x18} \
  SMON_TEMP_AVERAGING_SAMPLES {0} \
} [get_bd_cells versal_cips_0]

# pl0_ref_clk will have been disconnected after the automation feature, so we re-connect it here
delete_bd_objs [get_bd_nets versal_cips_0_pl0_ref_clk]
connect_bd_net [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_pins bridge_refclkGTYP_REFCLK_X1Y8/apb3clk]
connect_bd_net [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_pins gt_quad_base_1/apb3clk]
connect_bd_net [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_pins bridge_refclkGTYP_REFCLK_X1Y6/apb3clk]
connect_bd_net [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_pins gt_quad_base/apb3clk]

set_property -dict [list CONFIG.APB3_CLK_FREQUENCY.VALUE_MODE MANUAL] [get_bd_cells gt_quad_base]
set_property CONFIG.APB3_CLK_FREQUENCY {124.999878} [get_bd_cells gt_quad_base]
set_property -dict [list CONFIG.APB3_CLK_FREQUENCY.VALUE_MODE MANUAL] [get_bd_cells gt_quad_base_1]
set_property CONFIG.APB3_CLK_FREQUENCY {124.999878} [get_bd_cells gt_quad_base_1]

#connect_bd_net [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_pins bridge_refclkGTYP_REFCLK_X1Y6/apb3clk]

# Create Redriver I2C port and connect it to PMC I2C
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 rdrv_i2c
connect_bd_intf_net [get_bd_intf_ports rdrv_i2c] [get_bd_intf_pins versal_cips_0/I2C0]

save_bd_design
