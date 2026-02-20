# QSFP slot 0: QSFP I/O and User LEDs
set_property PACKAGE_PIN AU21 [get_ports {dout_0[0]}]; # LA04_P
set_property PACKAGE_PIN AV21 [get_ports {dout_1[0]}]; # LA04_N
set_property PACKAGE_PIN BF23 [get_ports {dout_1[1]}]; # LA11_P
set_property PACKAGE_PIN BC25 [get_ports {dout_1[2]}]; # LA07_P
set_property PACKAGE_PIN BD25 [get_ports {dout_0[1]}]; # LA07_N

# QSFP slot 1: QSFP I/O and User LEDs
set_property PACKAGE_PIN AY22 [get_ports {dout_0[2]}]; # LA15_P
set_property PACKAGE_PIN AY23 [get_ports {dout_1[3]}]; # LA15_N
set_property PACKAGE_PIN BE22 [get_ports {dout_1[4]}]; # LA11_N
set_property PACKAGE_PIN BC22 [get_ports {dout_1[5]}]; # LA08_P
set_property PACKAGE_PIN BC21 [get_ports {dout_0[3]}]; # LA08_N

# QSFP I/O IOSTANDARDs
set_property IOSTANDARD LVCMOS15 [get_ports dout_0*]
set_property IOSTANDARD LVCMOS15 [get_ports dout_1*]
