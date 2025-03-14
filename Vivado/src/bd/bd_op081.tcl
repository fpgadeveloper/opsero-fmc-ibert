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

# Create constant LOW for the minimum I/Os of Quad SFP28 FMC
set const_low [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_low ]
set_property -dict [list CONFIG.CONST_VAL {0} CONFIG.CONST_WIDTH {12}] $const_low
make_bd_pins_external  [get_bd_pins const_low/dout]

save_bd_design
