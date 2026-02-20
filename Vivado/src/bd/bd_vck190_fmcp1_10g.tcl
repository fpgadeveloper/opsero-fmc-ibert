
################################################################
# This is a generated script based on design: versal_ibert
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2025.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   if { [string compare $scripts_vivado_version $current_vivado_version] > 0 } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2042 -severity "ERROR" " This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Sourcing the script failed since it was created with a future version of Vivado."}

   } else {
     catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   }

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source versal_ibert_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcvc1902-vsva2197-2MP-e-S
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name versal_ibert

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:versal_cips:3.4\
xilinx.com:ip:prbs_generator_checker:1.0\
xilinx.com:ip:util_ds_buf:2.2\
xilinx.com:ip:gtwiz_versal:1.0\
xilinx.com:ip:bufg_gt:1.0\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set gt_refclk_refclkGTY_REFCLK_X1Y2 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 gt_refclk_refclkGTY_REFCLK_X1Y2 ]

  set Quad0_GT_Serial_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 Quad0_GT_Serial_0 ]

  set Quad1_GT_Serial_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 Quad1_GT_Serial_0 ]


  # Create ports

  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips:3.4 versal_cips_0 ]
  set_property -dict [list \
    CONFIG.BOOT_MODE {Custom} \
    CONFIG.CLOCK_MODE {Custom} \
    CONFIG.DDR_MEMORY_MODE {Custom} \
    CONFIG.DESIGN_MODE {0} \
    CONFIG.PS_PMC_CONFIG { \
      CLOCK_MODE {Custom} \
      DESIGN_MODE {0} \
      PMC_CRP_PL0_REF_CTRL_FREQMHZ {125} \
      PS_BOARD_INTERFACE {Custom} \
      PS_NUM_FABRIC_RESETS {0} \
      PS_USE_PMCPL_CLK0 {1} \
      SMON_ALARMS {Set_Alarms_On} \
      SMON_ENABLE_TEMP_AVERAGING {0} \
      SMON_TEMP_AVERAGING_SAMPLES {0} \
    } \
  ] $versal_cips_0


  # Create instance: bridge_refclkGTY_REFCLK_X1Y2, and set properties
  set bridge_refclkGTY_REFCLK_X1Y2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:prbs_generator_checker:1.0 bridge_refclkGTY_REFCLK_X1Y2 ]
  set_property -dict [list \
    CONFIG.GT_TYPE {GTY} \
    CONFIG.IP_LR0_SETTINGS {PRESET None RX_PAM_SEL NRZ TX_PAM_SEL NRZ TX_HD_EN 0 RX_HD_EN 0 RX_GRAY_BYP true TX_GRAY_BYP true RX_GRAY_LITTLEENDIAN true TX_GRAY_LITTLEENDIAN true RX_PRECODE_BYP true TX_PRECODE_BYP\
true RX_PRECODE_LITTLEENDIAN false TX_PRECODE_LITTLEENDIAN false INTERNAL_PRESET None GT_TYPE GTY GT_DIRECTION DUPLEX XPU_MODE 0 TX_LINE_RATE 10 TX_PLL_TYPE LCPLL TX_REFCLK_FREQUENCY 100 TX_ACTUAL_REFCLK_FREQUENCY\
100.000000000000 TX_FRACN_ENABLED false TX_FRACN_OVRD false TX_FRACN_NUMERATOR 0 TX_REFCLK_SOURCE R0 TX_DATA_ENCODING RAW TX_USER_DATA_WIDTH 32 TX_INT_DATA_WIDTH 32 TX_BUFFER_MODE 1 TX_BUFFER_BYPASS_MODE\
Fast_Sync TX_PIPM_ENABLE false TX_OUTCLK_SOURCE TXOUTCLKPMA TXPROGDIV_FREQ_ENABLE false TXPROGDIV_FREQ_SOURCE LCPLL TXPROGDIV_FREQ_VAL 312.500000 TX_DIFF_SWING_EMPH_MODE CUSTOM TX_64B66B_SCRAMBLER false\
TX_64B66B_ENCODER false TX_64B66B_CRC false TX_RATE_GROUP A RX_LINE_RATE 10 RX_PLL_TYPE LCPLL RX_REFCLK_FREQUENCY 100 RX_ACTUAL_REFCLK_FREQUENCY 100.000000000000 RX_FRACN_ENABLED false RX_FRACN_OVRD false\
RX_FRACN_NUMERATOR 0 RX_REFCLK_SOURCE R0 RX_DATA_DECODING RAW RX_USER_DATA_WIDTH 32 RX_INT_DATA_WIDTH 32 RX_BUFFER_MODE 1 RX_OUTCLK_SOURCE RXOUTCLKPMA RXPROGDIV_FREQ_ENABLE false RXPROGDIV_FREQ_SOURCE\
LCPLL RXPROGDIV_FREQ_VAL 312.500000 RXRECCLK_FREQ_ENABLE false RXRECCLK_FREQ_VAL 0 INS_LOSS_NYQ 20 RX_EQ_MODE AUTO RX_COUPLING AC RX_TERMINATION PROGRAMMABLE RX_RATE_GROUP A RX_TERMINATION_PROG_VALUE 800\
RX_PPM_OFFSET 0 RX_64B66B_DESCRAMBLER false RX_64B66B_DECODER false RX_64B66B_CRC false OOB_ENABLE false RX_COMMA_ALIGN_WORD 1 RX_COMMA_SHOW_REALIGN_ENABLE true PCIE_ENABLE false TX_LANE_DESKEW_HDMI_ENABLE\
false RX_COMMA_P_ENABLE false RX_COMMA_M_ENABLE false RX_COMMA_DOUBLE_ENABLE false RX_COMMA_P_VAL 0101111100 RX_COMMA_M_VAL 1010000011 RX_COMMA_MASK 0000000000 RX_SLIDE_MODE OFF RX_SSC_PPM 0 RX_CB_NUM_SEQ\
0 RX_CB_LEN_SEQ 1 RX_CB_MAX_SKEW 1 RX_CB_MAX_LEVEL 1 RX_CB_MASK 00000000 RX_CB_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000000000 RX_CB_K 00000000 RX_CB_DISP 00000000\
RX_CB_MASK_0_0 false RX_CB_VAL_0_0 00000000 RX_CB_K_0_0 false RX_CB_DISP_0_0 false RX_CB_MASK_0_1 false RX_CB_VAL_0_1 00000000 RX_CB_K_0_1 false RX_CB_DISP_0_1 false RX_CB_MASK_0_2 false RX_CB_VAL_0_2\
00000000 RX_CB_K_0_2 false RX_CB_DISP_0_2 false RX_CB_MASK_0_3 false RX_CB_VAL_0_3 00000000 RX_CB_K_0_3 false RX_CB_DISP_0_3 false RX_CB_MASK_1_0 false RX_CB_VAL_1_0 00000000 RX_CB_K_1_0 false RX_CB_DISP_1_0\
false RX_CB_MASK_1_1 false RX_CB_VAL_1_1 00000000 RX_CB_K_1_1 false RX_CB_DISP_1_1 false RX_CB_MASK_1_2 false RX_CB_VAL_1_2 00000000 RX_CB_K_1_2 false RX_CB_DISP_1_2 false RX_CB_MASK_1_3 false RX_CB_VAL_1_3\
00000000 RX_CB_K_1_3 false RX_CB_DISP_1_3 false RX_CC_NUM_SEQ 0 RX_CC_LEN_SEQ 1 RX_CC_PERIODICITY 5000 RX_CC_KEEP_IDLE DISABLE RX_CC_PRECEDENCE ENABLE RX_CC_REPEAT_WAIT 0 RX_CC_MASK 00000000 RX_CC_VAL\
00000000000000000000000000000000000000000000000000000000000000000000000000000000 RX_CC_K 00000000 RX_CC_DISP 00000000 RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00000000 RX_CC_K_0_0 false RX_CC_DISP_0_0 false\
RX_CC_MASK_0_1 false RX_CC_VAL_0_1 00000000 RX_CC_K_0_1 false RX_CC_DISP_0_1 false RX_CC_MASK_0_2 false RX_CC_VAL_0_2 00000000 RX_CC_K_0_2 false RX_CC_DISP_0_2 false RX_CC_MASK_0_3 false RX_CC_VAL_0_3\
00000000 RX_CC_K_0_3 false RX_CC_DISP_0_3 false RX_CC_MASK_1_0 false RX_CC_VAL_1_0 00000000 RX_CC_K_1_0 false RX_CC_DISP_1_0 false RX_CC_MASK_1_1 false RX_CC_VAL_1_1 00000000 RX_CC_K_1_1 false RX_CC_DISP_1_1\
false RX_CC_MASK_1_2 false RX_CC_VAL_1_2 00000000 RX_CC_K_1_2 false RX_CC_DISP_1_2 false RX_CC_MASK_1_3 false RX_CC_VAL_1_3 00000000 RX_CC_K_1_3 false RX_CC_DISP_1_3 false PCIE_USERCLK2_FREQ 250 PCIE_USERCLK_FREQ\
250 RX_JTOL_FC 5.9988002 RX_JTOL_LF_SLOPE -20 RX_BUFFER_BYPASS_MODE Fast_Sync RX_BUFFER_BYPASS_MODE_LANE MULTI RX_BUFFER_RESET_ON_CB_CHANGE ENABLE RX_BUFFER_RESET_ON_COMMAALIGN DISABLE RX_BUFFER_RESET_ON_RATE_CHANGE\
ENABLE TX_BUFFER_RESET_ON_RATE_CHANGE ENABLE RESET_SEQUENCE_INTERVAL 0 RX_COMMA_PRESET NONE RX_COMMA_VALID_ONLY 0} \
    CONFIG.IP_NO_OF_LANES {8} \
  ] $bridge_refclkGTY_REFCLK_X1Y2


  # Create instance: util_ds_buf_refclkGTY_REFCLK_X1Y2, and set properties
  set util_ds_buf_refclkGTY_REFCLK_X1Y2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.2 util_ds_buf_refclkGTY_REFCLK_X1Y2 ]
  set_property CONFIG.C_BUF_TYPE {IBUFDSGTE} $util_ds_buf_refclkGTY_REFCLK_X1Y2


  # Create instance: gtwiz_versal_refclkGTY_REFCLK_X1Y2, and set properties
  set gtwiz_versal_refclkGTY_REFCLK_X1Y2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:gtwiz_versal:1.0 gtwiz_versal_refclkGTY_REFCLK_X1Y2 ]
  set_property -dict [list \
    CONFIG.GT_TYPE {GTY} \
    CONFIG.INTF0_GT_SETTINGS(GT_DIRECTION) {DUPLEX} \
    CONFIG.INTF0_GT_SETTINGS(GT_TYPE) {GTY} \
    CONFIG.INTF0_GT_SETTINGS(LR0_SETTINGS) {PRESET None RX_PAM_SEL NRZ TX_PAM_SEL NRZ TX_HD_EN 0 RX_HD_EN 0 RX_GRAY_BYP true TX_GRAY_BYP true RX_GRAY_LITTLEENDIAN true TX_GRAY_LITTLEENDIAN true RX_PRECODE_BYP\
true TX_PRECODE_BYP true RX_PRECODE_LITTLEENDIAN false TX_PRECODE_LITTLEENDIAN false INTERNAL_PRESET None GT_TYPE GTY GT_DIRECTION DUPLEX XPU_MODE 0 TX_LINE_RATE 10 TX_PLL_TYPE LCPLL TX_REFCLK_FREQUENCY\
100 TX_ACTUAL_REFCLK_FREQUENCY 100.000000000000 TX_FRACN_ENABLED false TX_FRACN_OVRD false TX_FRACN_NUMERATOR 0 TX_REFCLK_SOURCE R0 TX_DATA_ENCODING RAW TX_USER_DATA_WIDTH 32 TX_INT_DATA_WIDTH 32 TX_BUFFER_MODE\
1 TX_BUFFER_BYPASS_MODE Fast_Sync TX_PIPM_ENABLE false TX_OUTCLK_SOURCE TXOUTCLKPMA TXPROGDIV_FREQ_ENABLE false TXPROGDIV_FREQ_SOURCE LCPLL TXPROGDIV_FREQ_VAL 312.500000 TX_DIFF_SWING_EMPH_MODE CUSTOM\
TX_64B66B_SCRAMBLER false TX_64B66B_ENCODER false TX_64B66B_CRC false TX_RATE_GROUP A RX_LINE_RATE 10 RX_PLL_TYPE LCPLL RX_REFCLK_FREQUENCY 100 RX_ACTUAL_REFCLK_FREQUENCY 100.000000000000 RX_FRACN_ENABLED\
false RX_FRACN_OVRD false RX_FRACN_NUMERATOR 0 RX_REFCLK_SOURCE R0 RX_DATA_DECODING RAW RX_USER_DATA_WIDTH 32 RX_INT_DATA_WIDTH 32 RX_BUFFER_MODE 1 RX_OUTCLK_SOURCE RXOUTCLKPMA RXPROGDIV_FREQ_ENABLE false\
RXPROGDIV_FREQ_SOURCE LCPLL RXPROGDIV_FREQ_VAL 312.500000 RXRECCLK_FREQ_ENABLE false RXRECCLK_FREQ_VAL 0 INS_LOSS_NYQ 20 RX_EQ_MODE AUTO RX_COUPLING AC RX_TERMINATION PROGRAMMABLE RX_RATE_GROUP A RX_TERMINATION_PROG_VALUE\
800 RX_PPM_OFFSET 0 RX_64B66B_DESCRAMBLER false RX_64B66B_DECODER false RX_64B66B_CRC false OOB_ENABLE false RX_COMMA_ALIGN_WORD 1 RX_COMMA_SHOW_REALIGN_ENABLE true PCIE_ENABLE false TX_LANE_DESKEW_HDMI_ENABLE\
false RX_COMMA_P_ENABLE false RX_COMMA_M_ENABLE false RX_COMMA_DOUBLE_ENABLE false RX_COMMA_P_VAL 0101111100 RX_COMMA_M_VAL 1010000011 RX_COMMA_MASK 0000000000 RX_SLIDE_MODE OFF RX_SSC_PPM 0 RX_CB_NUM_SEQ\
0 RX_CB_LEN_SEQ 1 RX_CB_MAX_SKEW 1 RX_CB_MAX_LEVEL 1 RX_CB_MASK 00000000 RX_CB_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000000000 RX_CB_K 00000000 RX_CB_DISP 00000000\
RX_CB_MASK_0_0 false RX_CB_VAL_0_0 00000000 RX_CB_K_0_0 false RX_CB_DISP_0_0 false RX_CB_MASK_0_1 false RX_CB_VAL_0_1 00000000 RX_CB_K_0_1 false RX_CB_DISP_0_1 false RX_CB_MASK_0_2 false RX_CB_VAL_0_2\
00000000 RX_CB_K_0_2 false RX_CB_DISP_0_2 false RX_CB_MASK_0_3 false RX_CB_VAL_0_3 00000000 RX_CB_K_0_3 false RX_CB_DISP_0_3 false RX_CB_MASK_1_0 false RX_CB_VAL_1_0 00000000 RX_CB_K_1_0 false RX_CB_DISP_1_0\
false RX_CB_MASK_1_1 false RX_CB_VAL_1_1 00000000 RX_CB_K_1_1 false RX_CB_DISP_1_1 false RX_CB_MASK_1_2 false RX_CB_VAL_1_2 00000000 RX_CB_K_1_2 false RX_CB_DISP_1_2 false RX_CB_MASK_1_3 false RX_CB_VAL_1_3\
00000000 RX_CB_K_1_3 false RX_CB_DISP_1_3 false RX_CC_NUM_SEQ 0 RX_CC_LEN_SEQ 1 RX_CC_PERIODICITY 5000 RX_CC_KEEP_IDLE DISABLE RX_CC_PRECEDENCE ENABLE RX_CC_REPEAT_WAIT 0 RX_CC_MASK 00000000 RX_CC_VAL\
00000000000000000000000000000000000000000000000000000000000000000000000000000000 RX_CC_K 00000000 RX_CC_DISP 00000000 RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00000000 RX_CC_K_0_0 false RX_CC_DISP_0_0 false\
RX_CC_MASK_0_1 false RX_CC_VAL_0_1 00000000 RX_CC_K_0_1 false RX_CC_DISP_0_1 false RX_CC_MASK_0_2 false RX_CC_VAL_0_2 00000000 RX_CC_K_0_2 false RX_CC_DISP_0_2 false RX_CC_MASK_0_3 false RX_CC_VAL_0_3\
00000000 RX_CC_K_0_3 false RX_CC_DISP_0_3 false RX_CC_MASK_1_0 false RX_CC_VAL_1_0 00000000 RX_CC_K_1_0 false RX_CC_DISP_1_0 false RX_CC_MASK_1_1 false RX_CC_VAL_1_1 00000000 RX_CC_K_1_1 false RX_CC_DISP_1_1\
false RX_CC_MASK_1_2 false RX_CC_VAL_1_2 00000000 RX_CC_K_1_2 false RX_CC_DISP_1_2 false RX_CC_MASK_1_3 false RX_CC_VAL_1_3 00000000 RX_CC_K_1_3 false RX_CC_DISP_1_3 false PCIE_USERCLK2_FREQ 250 PCIE_USERCLK_FREQ\
250 RX_JTOL_FC 5.9988002 RX_JTOL_LF_SLOPE -20 RX_BUFFER_BYPASS_MODE Fast_Sync RX_BUFFER_BYPASS_MODE_LANE MULTI RX_BUFFER_RESET_ON_CB_CHANGE ENABLE RX_BUFFER_RESET_ON_COMMAALIGN DISABLE RX_BUFFER_RESET_ON_RATE_CHANGE\
ENABLE TX_BUFFER_RESET_ON_RATE_CHANGE ENABLE RESET_SEQUENCE_INTERVAL 0 RX_COMMA_PRESET NONE RX_COMMA_VALID_ONLY 0} \
    CONFIG.INTF0_NO_OF_LANES {8} \
    CONFIG.INTF0_PARENTID {versal_ibert_bridge_refclkGTY_REFCLK_X1Y2_0} \
    CONFIG.INTF_PARENT_PIN_LIST {QUAD0_RX0 /bridge_refclkGTY_REFCLK_X1Y2/GT_RX0 QUAD0_RX1 /bridge_refclkGTY_REFCLK_X1Y2/GT_RX1 QUAD0_RX2 /bridge_refclkGTY_REFCLK_X1Y2/GT_RX2 QUAD0_RX3 /bridge_refclkGTY_REFCLK_X1Y2/GT_RX3\
QUAD1_RX0 /bridge_refclkGTY_REFCLK_X1Y2/GT_RX4 QUAD1_RX1 /bridge_refclkGTY_REFCLK_X1Y2/GT_RX5 QUAD1_RX2 /bridge_refclkGTY_REFCLK_X1Y2/GT_RX6 QUAD1_RX3 /bridge_refclkGTY_REFCLK_X1Y2/GT_RX7 QUAD0_TX0 /bridge_refclkGTY_REFCLK_X1Y2/GT_TX0\
QUAD0_TX1 /bridge_refclkGTY_REFCLK_X1Y2/GT_TX1 QUAD0_TX2 /bridge_refclkGTY_REFCLK_X1Y2/GT_TX2 QUAD0_TX3 /bridge_refclkGTY_REFCLK_X1Y2/GT_TX3 QUAD1_TX0 /bridge_refclkGTY_REFCLK_X1Y2/GT_TX4 QUAD1_TX1 /bridge_refclkGTY_REFCLK_X1Y2/GT_TX5\
QUAD1_TX2 /bridge_refclkGTY_REFCLK_X1Y2/GT_TX6 QUAD1_TX3 /bridge_refclkGTY_REFCLK_X1Y2/GT_TX7} \
    CONFIG.NO_OF_QUADS {2} \
    CONFIG.QUAD0_REFCLK_STRING {HSCLK0_LCPLLGTREFCLK0 refclk_PROT0_R0_100_MHz_unique1 HSCLK1_LCPLLGTREFCLK0 refclk_PROT0_R0_100_MHz_unique1} \
    CONFIG.QUAD1_PROT0_LANES {4} \
    CONFIG.QUAD1_REFCLK_STRING {HSCLK0_LCPLLGTREFCLK0 refclk_PROT0_R0_100_MHz_unique1 HSCLK1_LCPLLGTREFCLK0 refclk_PROT0_R0_100_MHz_unique1} \
  ] $gtwiz_versal_refclkGTY_REFCLK_X1Y2

  set_property -dict [list \
    CONFIG.INTF0_GT_SETTINGS.VALUE_MODE {auto} \
    CONFIG.INTF0_PARENTID.VALUE_MODE {auto} \
    CONFIG.INTF_PARENT_PIN_LIST.VALUE_MODE {auto} \
  ] $gtwiz_versal_refclkGTY_REFCLK_X1Y2


  # Create instance: bufg_gt_tx_refclkGTY_REFCLK_X1Y2, and set properties
  set bufg_gt_tx_refclkGTY_REFCLK_X1Y2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:bufg_gt:1.0 bufg_gt_tx_refclkGTY_REFCLK_X1Y2 ]

  # Create instance: bufg_gt_rx_refclkGTY_REFCLK_X1Y2, and set properties
  set bufg_gt_rx_refclkGTY_REFCLK_X1Y2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:bufg_gt:1.0 bufg_gt_rx_refclkGTY_REFCLK_X1Y2 ]

  # Create interface connections
  connect_bd_intf_net -intf_net CLK_IN_D_0_1 [get_bd_intf_ports gt_refclk_refclkGTY_REFCLK_X1Y2] [get_bd_intf_pins util_ds_buf_refclkGTY_REFCLK_X1Y2/CLK_IN_D]
  connect_bd_intf_net -intf_net bridge_refclkGTY_REFCLK_X1Y2_GT_RX0 [get_bd_intf_pins bridge_refclkGTY_REFCLK_X1Y2/GT_RX0] [get_bd_intf_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/INTF0_RX0_GT_IP_Interface]
  connect_bd_intf_net -intf_net bridge_refclkGTY_REFCLK_X1Y2_GT_RX1 [get_bd_intf_pins bridge_refclkGTY_REFCLK_X1Y2/GT_RX1] [get_bd_intf_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/INTF0_RX1_GT_IP_Interface]
  connect_bd_intf_net -intf_net bridge_refclkGTY_REFCLK_X1Y2_GT_RX2 [get_bd_intf_pins bridge_refclkGTY_REFCLK_X1Y2/GT_RX2] [get_bd_intf_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/INTF0_RX2_GT_IP_Interface]
  connect_bd_intf_net -intf_net bridge_refclkGTY_REFCLK_X1Y2_GT_RX3 [get_bd_intf_pins bridge_refclkGTY_REFCLK_X1Y2/GT_RX3] [get_bd_intf_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/INTF0_RX3_GT_IP_Interface]
  connect_bd_intf_net -intf_net bridge_refclkGTY_REFCLK_X1Y2_GT_RX4 [get_bd_intf_pins bridge_refclkGTY_REFCLK_X1Y2/GT_RX4] [get_bd_intf_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/INTF0_RX4_GT_IP_Interface]
  connect_bd_intf_net -intf_net bridge_refclkGTY_REFCLK_X1Y2_GT_RX5 [get_bd_intf_pins bridge_refclkGTY_REFCLK_X1Y2/GT_RX5] [get_bd_intf_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/INTF0_RX5_GT_IP_Interface]
  connect_bd_intf_net -intf_net bridge_refclkGTY_REFCLK_X1Y2_GT_RX6 [get_bd_intf_pins bridge_refclkGTY_REFCLK_X1Y2/GT_RX6] [get_bd_intf_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/INTF0_RX6_GT_IP_Interface]
  connect_bd_intf_net -intf_net bridge_refclkGTY_REFCLK_X1Y2_GT_RX7 [get_bd_intf_pins bridge_refclkGTY_REFCLK_X1Y2/GT_RX7] [get_bd_intf_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/INTF0_RX7_GT_IP_Interface]
  connect_bd_intf_net -intf_net bridge_refclkGTY_REFCLK_X1Y2_GT_TX0 [get_bd_intf_pins bridge_refclkGTY_REFCLK_X1Y2/GT_TX0] [get_bd_intf_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/INTF0_TX0_GT_IP_Interface]
  connect_bd_intf_net -intf_net bridge_refclkGTY_REFCLK_X1Y2_GT_TX1 [get_bd_intf_pins bridge_refclkGTY_REFCLK_X1Y2/GT_TX1] [get_bd_intf_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/INTF0_TX1_GT_IP_Interface]
  connect_bd_intf_net -intf_net bridge_refclkGTY_REFCLK_X1Y2_GT_TX2 [get_bd_intf_pins bridge_refclkGTY_REFCLK_X1Y2/GT_TX2] [get_bd_intf_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/INTF0_TX2_GT_IP_Interface]
  connect_bd_intf_net -intf_net bridge_refclkGTY_REFCLK_X1Y2_GT_TX3 [get_bd_intf_pins bridge_refclkGTY_REFCLK_X1Y2/GT_TX3] [get_bd_intf_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/INTF0_TX3_GT_IP_Interface]
  connect_bd_intf_net -intf_net bridge_refclkGTY_REFCLK_X1Y2_GT_TX4 [get_bd_intf_pins bridge_refclkGTY_REFCLK_X1Y2/GT_TX4] [get_bd_intf_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/INTF0_TX4_GT_IP_Interface]
  connect_bd_intf_net -intf_net bridge_refclkGTY_REFCLK_X1Y2_GT_TX5 [get_bd_intf_pins bridge_refclkGTY_REFCLK_X1Y2/GT_TX5] [get_bd_intf_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/INTF0_TX5_GT_IP_Interface]
  connect_bd_intf_net -intf_net bridge_refclkGTY_REFCLK_X1Y2_GT_TX6 [get_bd_intf_pins bridge_refclkGTY_REFCLK_X1Y2/GT_TX6] [get_bd_intf_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/INTF0_TX6_GT_IP_Interface]
  connect_bd_intf_net -intf_net bridge_refclkGTY_REFCLK_X1Y2_GT_TX7 [get_bd_intf_pins bridge_refclkGTY_REFCLK_X1Y2/GT_TX7] [get_bd_intf_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/INTF0_TX7_GT_IP_Interface]
  connect_bd_intf_net -intf_net gtwiz_versal_refclkGTY_REFCLK_X1Y2_Quad0_GT_Serial [get_bd_intf_ports Quad0_GT_Serial_0] [get_bd_intf_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/Quad0_GT_Serial]
  connect_bd_intf_net -intf_net gtwiz_versal_refclkGTY_REFCLK_X1Y2_Quad1_GT_Serial [get_bd_intf_ports Quad1_GT_Serial_0] [get_bd_intf_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/Quad1_GT_Serial]

  # Create port connections
  connect_bd_net -net bufg_gt_rx_refclkGTY_REFCLK_X1Y2_usrclk  [get_bd_pins bufg_gt_rx_refclkGTY_REFCLK_X1Y2/usrclk] \
  [get_bd_pins bridge_refclkGTY_REFCLK_X1Y2/gt_rxusrclk] \
  [get_bd_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/QUAD0_RX0_usrclk] \
  [get_bd_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/QUAD0_RX1_usrclk] \
  [get_bd_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/QUAD0_RX2_usrclk] \
  [get_bd_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/QUAD0_RX3_usrclk] \
  [get_bd_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/QUAD1_RX0_usrclk] \
  [get_bd_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/QUAD1_RX1_usrclk] \
  [get_bd_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/QUAD1_RX2_usrclk] \
  [get_bd_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/QUAD1_RX3_usrclk]
  connect_bd_net -net bufg_gt_tx_refclkGTY_REFCLK_X1Y2_usrclk  [get_bd_pins bufg_gt_tx_refclkGTY_REFCLK_X1Y2/usrclk] \
  [get_bd_pins bridge_refclkGTY_REFCLK_X1Y2/gt_txusrclk] \
  [get_bd_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/QUAD0_TX0_usrclk] \
  [get_bd_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/QUAD0_TX1_usrclk] \
  [get_bd_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/QUAD0_TX2_usrclk] \
  [get_bd_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/QUAD0_TX3_usrclk] \
  [get_bd_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/QUAD1_TX0_usrclk] \
  [get_bd_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/QUAD1_TX1_usrclk] \
  [get_bd_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/QUAD1_TX2_usrclk] \
  [get_bd_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/QUAD1_TX3_usrclk]
  connect_bd_net -net gtwiz_versal_refclkGTY_REFCLK_X1Y2_INTF0_TX_clr_out  [get_bd_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/INTF0_TX_clr_out] \
  [get_bd_pins bufg_gt_tx_refclkGTY_REFCLK_X1Y2/gt_bufgtclr] \
  [get_bd_pins bufg_gt_rx_refclkGTY_REFCLK_X1Y2/gt_bufgtclr]
  connect_bd_net -net gtwiz_versal_refclkGTY_REFCLK_X1Y2_INTF0_rst_rx_done_out  [get_bd_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/INTF0_rst_rx_done_out] \
  [get_bd_pins bridge_refclkGTY_REFCLK_X1Y2/rx_reset_in]
  connect_bd_net -net gtwiz_versal_refclkGTY_REFCLK_X1Y2_INTF0_rst_tx_done_out  [get_bd_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/INTF0_rst_tx_done_out] \
  [get_bd_pins bridge_refclkGTY_REFCLK_X1Y2/tx_reset_in]
  connect_bd_net -net gtwiz_versal_refclkGTY_REFCLK_X1Y2_QUAD0_RX0_outclk  [get_bd_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/QUAD0_RX0_outclk] \
  [get_bd_pins bufg_gt_rx_refclkGTY_REFCLK_X1Y2/outclk]
  connect_bd_net -net gtwiz_versal_refclkGTY_REFCLK_X1Y2_QUAD0_TX0_outclk  [get_bd_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/QUAD0_TX0_outclk] \
  [get_bd_pins bufg_gt_tx_refclkGTY_REFCLK_X1Y2/outclk]
  connect_bd_net -net util_ds_buf_refclkGTY_REFCLK_X1Y2_IBUF_OUT  [get_bd_pins util_ds_buf_refclkGTY_REFCLK_X1Y2/IBUF_OUT] \
  [get_bd_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/QUAD0_GTREFCLK0] \
  [get_bd_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/QUAD1_GTREFCLK0]
  connect_bd_net -net versal_cips_0_pl0_ref_clk  [get_bd_pins versal_cips_0/pl0_ref_clk] \
  [get_bd_pins bridge_refclkGTY_REFCLK_X1Y2/apb3clk] \
  [get_bd_pins gtwiz_versal_refclkGTY_REFCLK_X1Y2/gtwiz_freerun_clk]

  # Create address segments


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


