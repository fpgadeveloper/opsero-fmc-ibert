# refclkGTY_REFCLK_X1Y2 : 10 Gbps with 100 MHz
set_property LOC GTY_QUAD_X1Y1 [get_cells versal_ibert_i/gtwiz_versal_refclkGTY_REFCLK_X1Y2/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst]

set_property LOC GTY_QUAD_X1Y2 [get_cells versal_ibert_i/gtwiz_versal_refclkGTY_REFCLK_X1Y2/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_1_inst/inst/quad_inst]

set_property LOC GTY_REFCLK_X1Y2 [get_cells  versal_ibert_i/util_ds_buf_refclkGTY_REFCLK_X1Y2/U0/USE_IBUFDS_GTE5.GEN_IBUFDS_GTE5[0].IBUFDS_GTE5_I]
create_clock -period 10.0 [get_ports gt_refclk_refclkGTY_REFCLK_X1Y2_clk_p[0]]


set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
