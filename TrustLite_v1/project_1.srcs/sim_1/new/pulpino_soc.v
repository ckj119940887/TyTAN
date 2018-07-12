`timescale 1ns / 1ps

/*
    测试 pulpino_top
    添加自定义的时钟和复位，不使用fpga中的
*/

module pulpino_soc();
 parameter USE_ZERO_RISCY = 1;
 parameter RISCY_RV32F = 0;
 parameter ZERO_RV32M = 0;
 parameter ZERO_RV32E = 0;
 
 reg fetch_enable_i = 1'b1;
 reg clk=1;
 reg rst_n=0;
 
 always #5 clk = ~clk;
 always #10 rst_n = 1;

  // PULP SoC
  pulpino_top
  #(
    .USE_ZERO_RISCY    ( USE_ZERO_RISCY ),
    .RISCY_RV32F       ( RISCY_RV32F    ),
    .ZERO_RV32M        ( ZERO_RV32M     ),
    .ZERO_RV32E        ( ZERO_RV32E     )
  )
  pulpino_i
  (
    .clk               ( clk               ),
    .rst_n             ( rst_n             ),

    .clk_sel_i         ( 1'b0              ),
    .clk_standalone_i  ( 1'b0              ),

    .testmode_i        ( 1'b1              ),
    .fetch_enable_i    ( fetch_enable_i    ),
    .scan_enable_i     ( 1'b0              ),

    
    .spi_clk_i         ( spi_clk_i         ),
    .spi_cs_i          ( spi_cs_i          ),
    .spi_mode_o        ( spi_mode_o        ),
    .spi_sdo0_o        ( spi_sdo0_o        ),
    .spi_sdo1_o        ( spi_sdo1_o        ),
    .spi_sdo2_o        ( spi_sdo2_o        ),
    .spi_sdo3_o        ( spi_sdo3_o        ),
    .spi_sdi0_i        ( spi_sdi0_i        ),
    .spi_sdi1_i        ( spi_sdi1_i        ),
    .spi_sdi2_i        ( spi_sdi2_i        ),
    .spi_sdi3_i        ( spi_sdi3_i        ),

    .spi_master_clk_o  ( spi_master_clk_o  ),
    .spi_master_csn0_o ( spi_master_csn0_o ),
    .spi_master_csn1_o ( spi_master_csn1_o ),
    .spi_master_csn2_o ( spi_master_csn2_o ),
    .spi_master_csn3_o ( spi_master_csn3_o ),
    .spi_master_mode_o ( spi_master_mode_o ),
    .spi_master_sdo0_o ( spi_master_sdo0_o ),
    .spi_master_sdo1_o ( spi_master_sdo1_o ),
    .spi_master_sdo2_o ( spi_master_sdo2_o ),
    .spi_master_sdo3_o ( spi_master_sdo3_o ),
    .spi_master_sdi0_i ( spi_master_sdi0_i ),
    .spi_master_sdi1_i ( spi_master_sdi1_i ),
    .spi_master_sdi2_i ( spi_master_sdi2_i ),
    .spi_master_sdi3_i ( spi_master_sdi3_i ),

    .uart_tx           ( uart_tx           ), // output
    .uart_rx           ( uart_rx           ), // input
    .uart_rts          ( uart_rts          ), // output
    .uart_dtr          ( uart_dtr          ), // output
    .uart_cts          ( uart_cts          ), // input
    .uart_dsr          ( uart_dsr          ), // input

    .scl_pad_i         ( scl_i             ),
    .scl_pad_o         ( scl_o             ),
    .scl_padoen_o      ( scl_oen_o         ),
    .sda_pad_i         ( sda_i             ),
    .sda_pad_o         ( sda_o             ),
    .sda_padoen_o      ( sda_oen_o         ),

    .gpio_in           ( gpio_in           ),
    .gpio_out          ( gpio_out          ),
    .gpio_dir          ( gpio_dir          ),
    .gpio_padcfg       (                   ),

    .tck_i             ( tck_i             ),
    .trstn_i           ( trstn_i           ),
    .tms_i             ( tms_i             ),
    .tdi_i             ( tdi_i             ),
    .tdo_o             ( tdo_o             ),
    
    
    .pad_cfg_o         (                   ),
    .pad_mux_o         (                   )
   
    
  );




endmodule
