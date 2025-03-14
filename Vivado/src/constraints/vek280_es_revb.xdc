# refclkGTYP_REFCLK_X1Y6 : 100 MHz
set_property LOC GTYP_QUAD_X1Y3 [get_cells versal_ibert_i/gt_quad_base/inst/quad_inst]

set_property LOC GTYP_REFCLK_X1Y6 [get_cells  versal_ibert_i/util_ds_buf/U0/USE_IBUFDS_GTE5.GEN_IBUFDS_GTE5[0].IBUFDS_GTE5_I]
create_clock -period 10.0 [get_ports bridge_refclkGTYP_REFCLK_X1Y6_diff_gt_ref_clock_clk_p[0]]

# refclkGTYP_REFCLK_X1Y8 : 100 MHz
set_property LOC GTYP_QUAD_X1Y4 [get_cells versal_ibert_i/gt_quad_base_1/inst/quad_inst]

set_property LOC GTYP_REFCLK_X1Y8 [get_cells versal_ibert_i/util_ds_buf_1/U0/USE_IBUFDS_GTE5.GEN_IBUFDS_GTE5[0].IBUFDS_GTE5_I]
create_clock -period 10.0 [get_ports bridge_refclkGTYP_REFCLK_X1Y8_diff_gt_ref_clock_clk_p[0]]


set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

