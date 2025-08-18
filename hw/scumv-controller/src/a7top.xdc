set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports CLK100MHZ]
set_property -dict {PACKAGE_PIN C2 IOSTANDARD LVCMOS33} [get_ports RESET]
set_property -dict {PACKAGE_PIN D9 IOSTANDARD LVCMOS33} [get_ports BUTTON_0]
set_property -dict {PACKAGE_PIN D10 IOSTANDARD LVCMOS33} [get_ports UART_RXD_IN]
set_property -dict {PACKAGE_PIN A9 IOSTANDARD LVCMOS33} [get_ports UART_TXD_IN]
set_property -dict {PACKAGE_PIN G13 IOSTANDARD LVCMOS33} [get_ports SCAN_CLK]
set_property -dict {PACKAGE_PIN B11 IOSTANDARD LVCMOS33} [get_ports SCAN_EN]
set_property -dict {PACKAGE_PIN A11 IOSTANDARD LVCMOS33} [get_ports SCAN_IN]
set_property -dict {PACKAGE_PIN D12 IOSTANDARD LVCMOS33} [get_ports SCAN_RESET]
set_property -dict {PACKAGE_PIN D13 IOSTANDARD LVCMOS33} [get_ports CHIP_RESET]
set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS33} [get_ports TL_IN_VALID]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports TL_IN_READY]
set_property -dict {PACKAGE_PIN T11 IOSTANDARD LVCMOS33} [get_ports TL_IN_DATA]
set_property -dict {PACKAGE_PIN R12 IOSTANDARD LVCMOS33} [get_ports TL_OUT_VALID]
set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS33} [get_ports TL_OUT_READY]
set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS33} [get_ports TL_OUT_DATA]
set_property -dict {PACKAGE_PIN P17 IOSTANDARD LVCMOS33} [get_ports TL_CLK]
set_property -dict {PACKAGE_PIN H5 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN J5 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN T9 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS33} [get_ports {led[3]}]
# Source: https://github.com/Digilent/digilent-xdc/blob/master/Arty-A7-100-Master.xdc

# Clock signal
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports CLK100MHZ]

# set_property -dict { PACKAGE_PIN A8    IOSTANDARD LVCMOS33 } [get_ports { CLK_SWITCH }]; #IO_L12N_T1_MRCC_16 Sch=sw[0]

# Buttons

# USB-UART Interface

# Pmod Header JA
# set_property -dict { PACKAGE_PIN B18   IOSTANDARD LVCMOS33 } [get_ports { CPU_CLK }]; #IO_L10P_T1_AD11P_15 Sch=ja[8]

## ChipKit Outer Digital Header
#set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { TL_CLK  }]; #IO_L16P_T2_CSI_B_14 Sch=ck_io[0]

# 10 MHz clock constraint on the TL_CLK pin
create_clock -period 100.000 -name tl_clk_pin -waveform {0.000 5.000} -add [get_ports TL_CLK]

# Clock groups - declare sys_clk_pin and tl_clk_pin as asynchronous
set_clock_groups -asynchronous -group [get_clocks sys_clk_pin] -group [get_clocks tl_clk_pin]


#set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { ck_io7  }]; #IO_L15N_T2_DQS_DOUT_CSO_B_14 Sch=ck_io[7]
#set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports { ck_io8  }]; #IO_L11P_T1_SRCC_14 Sch=ck_io[8]
#set_property -dict { PACKAGE_PIN M16   IOSTANDARD LVCMOS33 } [get_ports { ck_io9  }]; #IO_L10P_T1_D14_14 Sch=ck_io[9]
#set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports { ck_io10 }]; #IO_L18N_T2_A11_D27_14 Sch=ck_io[10]
#set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports { ck_io11 }]; #IO_L17N_T2_A13_D29_14 Sch=ck_io[11]
#set_property -dict { PACKAGE_PIN R17   IOSTANDARD LVCMOS33 } [get_ports { ck_io12 }]; #IO_L12N_T1_MRCC_14 Sch=ck_io[12]


# LEDS

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]

set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets CLK100MHZ_IBUF_BUFG]
