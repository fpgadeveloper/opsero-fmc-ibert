# Minimum I/O required by Quad SFP28 FMC

# TX DISABLE
set_property PACKAGE_PIN AV22 [get_ports {dout_0[0]}]; # LA03_P
set_property PACKAGE_PIN BG21 [get_ports {dout_0[1]}]; # LA12_P
set_property PACKAGE_PIN AY23 [get_ports {dout_0[2]}]; # LA15_N
set_property PACKAGE_PIN BC16 [get_ports {dout_0[3]}]; # LA17_CC_N

# LEDs
set_property PACKAGE_PIN BC23 [get_ports {dout_0[4]}]; # LA01_CC_P
set_property PACKAGE_PIN BD22 [get_ports {dout_0[5]}]; # LA01_CC_N
set_property PACKAGE_PIN BF24 [get_ports {dout_0[6]}]; # LA05_P
set_property PACKAGE_PIN BG23 [get_ports {dout_0[7]}]; # LA05_N
set_property PACKAGE_PIN BF21 [get_ports {dout_0[8]}]; # LA16_P
set_property PACKAGE_PIN BG20 [get_ports {dout_0[9]}]; # LA16_N
set_property PACKAGE_PIN BE21 [get_ports {dout_0[10]}]; # LA13_P
set_property PACKAGE_PIN BE20 [get_ports {dout_0[11]}]; # LA13_N

# IOSTANDARDS
set_property IOSTANDARD LVCMOS15 [get_ports dout_0*]
