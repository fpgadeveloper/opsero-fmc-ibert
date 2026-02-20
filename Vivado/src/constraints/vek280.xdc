# refclkGTYP_REFCLK_X1Y6 : 10 Gbps with 100 MHz
set_property LOC GTYP_QUAD_X1Y3 [get_cells versal_ibert_i/gtwiz_versal_refclkGTYP_REFCLK_X1Y6/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst]

set_property LOC GTYP_REFCLK_X1Y6 [get_cells  versal_ibert_i/util_ds_buf_refclkGTYP_REFCLK_X1Y6/U0/USE_IBUFDS_GTE5.GEN_IBUFDS_GTE5[0].IBUFDS_GTE5_I]
create_clock -period 10.0 [get_ports gt_refclk_refclkGTYP_REFCLK_X1Y6_clk_p[0]]

# refclkGTYP_REFCLK_X1Y8 : 10 Gbps with 100 MHz
set_property LOC GTYP_QUAD_X1Y4 [get_cells versal_ibert_i/gtwiz_versal_refclkGTYP_REFCLK_X1Y8/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst]

set_property LOC GTYP_REFCLK_X1Y8 [get_cells versal_ibert_i/util_ds_buf_refclkGTYP_REFCLK_X1Y8/U0/USE_IBUFDS_GTE5.GEN_IBUFDS_GTE5[0].IBUFDS_GTE5_I]
create_clock -period 10.0 [get_ports gt_refclk_refclkGTYP_REFCLK_X1Y8_clk_p[0]]


set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
