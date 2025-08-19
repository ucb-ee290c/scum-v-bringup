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

# ----------------------------------------------------------------------------
# TL timing terms used below (for finding the right numbers in datasheet/PCB):
#
# - Tco_min / Tco_max (Clock-to-Output of external device)
#     Time from the active TL_CLK edge at the external device to when it drives
#     its outputs valid at the pins. Applies to signals the external device
#     drives into the FPGA: TL_IN_DATA, TL_IN_VALID, TL_OUT_READY.
#     Source: SCuM-V timing tables for the TL interface.
#
# - tSU (Setup time at external device)
#     Time that signals driven by the FPGA (TL_OUT_DATA, TL_OUT_VALID, TL_IN_READY)
#     must be stable BEFORE the external device’s capturing TL_CLK edge.
#     Source: SCuM-V input timing requirements (setup time).
#
# - tH (Hold time at external device)
#     Time that those same FPGA-driven signals must remain stable AFTER the
#     external device’s capturing TL_CLK edge.
#     Source: SCuM-V input timing requirements (hold time).
#
# - board_min / board_max (PCB propagation + skew between devices)
#     The difference in propagation between TL_CLK and the data/control net,
#     including trace delay and any length mismatch. Use layout data if
#     available; a first-order FR-4 estimate is ~150–170 ps/inch (6–7 ps/mm).
#
# How these feed the constraints:
#   Inputs TO FPGA (external drives):
#     set_input_delay -max = Tco_max + board_max
#     set_input_delay -min = Tco_min + board_min
#
#   Outputs FROM FPGA (external captures):
#     set_output_delay -max = tSU + board_max
#     set_output_delay -min = -tH + board_min   ; note the minus sign for hold
#
# Edge/polarity assumptions:
#   Constraints below assume the external device launches and captures on the
#   rising edge of TL_CLK. If the device uses the falling edge for launch or
#   capture, add -clock_fall to the corresponding input/output delay commands.
#
# Where to get values:
#   - SCuM-V datasheet: Tco_min/max for TL outputs; tSU/tH for TL inputs.
#   - PCB/layout: length and skew between TL_CLK and each TL signal pair.
#
# Additional margin knobs:
#   - set_clock_uncertainty can be used to budget for jitter/skew beyond the
#     nominal numbers above. Tune per measurement or system budget.
# ----------------------------------------------------------------------------

# ============================================================================
# TL bus I/O timing constraints (source-synchronous to TL_CLK)
# NOTE: Placeholder numbers chosen conservatively; replace with measured/spec
#       values from SCuM-V datasheet and PCB estimates when available.
#       Inputs (to FPGA):  -max = Tco_max + board_max,  -min = Tco_min + board_min
#       Outputs (from FPGA): -max = tSU + board_max,    -min = -tH + board_min
# ============================================================================

# Inputs to FPGA relative to tl_clk_pin: TL_IN_DATA, TL_IN_VALID, TL_OUT_READY
set_input_delay  -clock [get_clocks tl_clk_pin] -max 3.500 [get_ports {TL_IN_DATA TL_IN_VALID TL_OUT_READY}]
set_input_delay  -clock [get_clocks tl_clk_pin] -min 0.000 [get_ports {TL_IN_DATA TL_IN_VALID TL_OUT_READY}] -add_delay

# Outputs from FPGA relative to tl_clk_pin: TL_OUT_DATA, TL_OUT_VALID, TL_IN_READY
set_output_delay -clock [get_clocks tl_clk_pin] -max 2.500 [get_ports {TL_OUT_DATA TL_OUT_VALID TL_IN_READY}]
set_output_delay -clock [get_clocks tl_clk_pin] -min -0.500 [get_ports {TL_OUT_DATA TL_OUT_VALID TL_IN_READY}] -add_delay

# Optional margin for clock uncertainty (tune if desired)
set_clock_uncertainty -setup 0.200 [get_clocks tl_clk_pin]
set_clock_uncertainty -hold  0.100 [get_clocks tl_clk_pin]

# ============================================================================
# Mark truly asynchronous or non-timed external interfaces as false paths
# (silences warnings for signals not intended to be timed to a created clock)
# ============================================================================

# Asynchronous inputs (debounced/synchronized in logic)
set_false_path -from [get_ports {RESET BUTTON_0}]

# Host UART is asynchronous to sys_clk
set_false_path -from [get_ports UART_TXD_IN]
set_false_path -to   [get_ports UART_RXD_IN]

# Scan chain control and board LEDs are not timed to an external synchronous requirement
set_false_path -to [get_ports {SCAN_CLK SCAN_EN SCAN_IN SCAN_RESET CHIP_RESET}]
set_false_path -to [get_ports {led[*]}]