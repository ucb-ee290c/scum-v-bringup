# scum-v-bringup
Various files for bringing up the EE290C Spring '21 variant

## Hardware Setup

For the revision 1 Universal PCB (SCuM-V PCB), the level shifters are not functional, so all connections should be made at the white headers.

Power Jumpers
- Reg_1V6 <> VBATT
- Reg_1V8 <> VDD_IO
- LDO_VDD_AON <> VDD_AON
- BG_V_REF  <> BG_V_REF_EXT
- I_REF <> I_REF_EXT
- LDO_VDD_A_RF <> VDD_A_RF


External 0.85V Supply (50 mA current limit) <> VDD_D 

FPGA          PCB
- SCAN_EN   <>  GPIO_PA1
- SCAN_IN   <>  SCAN_IN
- SCAN_CLK  <>  SCAN_CLK
- SCAN_RESET<>  GPIO_PA2

Other connections

- SCAN_SEL  <>  +1.8V
- RESET     <>  GND
