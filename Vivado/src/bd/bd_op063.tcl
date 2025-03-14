################################################################
# Block design for OP063, OP073 and XM107
################################################################

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

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

# DO NOTHING
# The OP063, OP073 and XM107 boards do not require any extra I/O for the IBERT test.
# We have added this file as a placeholder, in case we would like to add something to
# the design at some point in the future.
