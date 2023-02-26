# scum-v-bringup
Various files for bringing up the EE290C Spring '21 variant

## Project Structure

- hw/
    - scanchain/
        - Vivado project for the bitstream to be used on an Arty A7-100T to translate UART from UART to SCuM's analog scan chain. 
    - tiny_adapter/
        - **Not functional**. Vivado project for the bitstream to be used on a CMOD A7 to translate from UART to SCuM's TSI bus.
    - scanchain/
        - Vivado project for the STM32F446RE analog scan chain adapter.
    - client.py
        - Python script for use with the Arty A7-100T to translate UART to SCuM's analog scan chain.

- sw/
    - scum_firmware/
        - RISC-V firmware to be loaded onto the SCuM-V.
    - TileLinkTrafficAdapter-F446/
        - STM32F446RE firmware for translating UART to the TSI bus.
    - scanchain/
        - **Not functional**. STM32F446RE firmware for translating UART to the analog scan chain bus. 
    - proxyFESVR/
        - **Not functional**. Fork of Franklin Huang's proxyFESVR library, modified to support SCuM-V. See the [README](sw/proxyFESVR/README.md) for more details.
    - tl_host.py
        - Python script for use with the STM32F446RE to translate UART to SCuM's TSI bus.

## Hardware Setup

### Equipment needed:

1. SCuM-V Universal PCB 
    - [Schematic/Layout for Rev. 1](https://uc-berkeley-9.365.altium.com/designs/3D0D350B-0F0E-4E78-9462-98D18BF7F627)
    - [Schematic/Layout for Rev. 3](https://uc-berkeley-9.365.altium.com/designs/57925AD0-466D-477E-A70E-7C0E4B06D00B)
2. Arty A7-35T or Art A7-100T FPGA Board (to program the Analog Scan Chain)
    - The Arty A7-35T is unfortunately retired by Digilent, but the A7-100T is still available
    - [Arty A7-100T](https://digilent.com/shop/arty-a7-100t-artix-7-fpga-development-board/)
3. 2x 3.3V to 1.8V Level Shifter (1x for Analog Scan Chain 1x for TSI)
    - A breadboarded voltage divider circuit for level shifting will work
    - [Digilent PMOD Level Shifter](https://digilent.com/shop/pmod-lvlshft-logic-level-shifter/)
4. STM32 Nucleo-64 development board with STM32F446RE MCU
    - The STM32 board is used as a UART to TSI adapter to communicate with the digital portion of SCuM
    - [NUCLEO-F446RE](https://www.st.com/en/evaluation-tools/nucleo-f446re.html)
    

### Connections

For the revision 1 Universal PCB (SCuM-V PCB), the level shifters on-board are not functional, so all connections should be made at the white headers.

**Power Jumpers**
- Reg_1V6 <> VBATT
- Reg_1V8 <> VDD_IO
- LDO_VDD_AON <> VDD_AON
- BG_V_REF  <> BG_V_REF_EXT
- I_REF <> I_REF_EXT
- LDO_VDD_A_RF <> VDD_A_RF

**Power supplies**
- External 3.5V supply (~80 mA current limit) <> PCB J1
- External 0.85V Supply (50 mA current limit) <> SCuM's VDD_D 
- Both supply grounds to J5

Why is an external supply needed for VDD_D? SCuM-V22's on-chip LDO for the digital domain cannot
source the required current for the entire digital block.

**FPGA <> PCB connections**

A level shifter from 3.3V to 1.8V is needed for each signal here.
- SCAN_EN   <>  GPIO_PA1
- SCAN_IN   <>  SCAN_IN
- SCAN_CLK  <>  SCAN_CLK
- SCAN_RESET<>  GPIO_PA2

**Other connections**

- SCAN_SEL  <>  +1.8V
- RESET     <>  GND

## FPGA Setup

### Flashing the bitstream

This guide is based on and tested with Vivado 2022.1 on Windows. The steps should work for other versions of Vivado, but cannot be guaranteed. 

If you do run this on a different version of Vivado, please let us know if there are any issues or if your version is supported.

1. Open Vivado
2. In the TCL console and change the working directory to the `scum-v-bringup/hw/scanchain` directory. For example, if you cloned this repo to `C:\Projects\Repositories\scum-v-bringup`, then you would run the following command in the TCL console:

    ```
    cd C:/Projects/Repositories/scum-v-bringup/hw/scanchain
    ```
3. Generate the Vivado project by running the following command in the TCL console:

    ```
    source create_project.tcl
    ```

4. The Vivado project should now be open. Build the bitstream by running `Generate Bitstream` in the `Flow Navigator` panel.

5. Connect the Arty A7-100T to your computer via USB. The Arty A7-100T should show up as a USB device in the `Device Manager` on Windows or `lsusb` on Linux.

6. In the `Flow Navigator` panel, click on `Open Target` and select the Arty A7-100T as the device. Then `Program Device` The bitstream should now be flashed to the FPGA. You can verify that the bitstream has been flashed by seeing LED2 on the Arty A7-100T turn on (it is slaved to SCAN_CLK).

## Writing to SCuM-V's ASC

Ensure **every** connection listed in the `Connections` section above was made correctly.

1. Make any modifications to the `client.py` script in the `hw/` folder then run:

    ```
    python client.py
    ```
    
## STM32 Setup

### Flashing the firmware

The STM32CubeIDE is needed to build and flash the firmware to the STM32 board. The IDE can be downloaded here: 
https://www.st.com/en/development-tools/stm32cubeide.html



