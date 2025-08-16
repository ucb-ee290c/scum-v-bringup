# scum-v-bringup

Various files for bringing up the Single-Chip Micro Mote V (SCμM-V)

## Documentation

[SCuM-V23 Specification (PDF Version)](https://github.com/ucb-ee290c/scum-v-bringup/raw/gh-pages/SCuM-V23.pdf)

[SCuM-V23 Specification (Web Version)](https://ucb-ee290c.github.io/scum-v-bringup/) (Disabled while the repository is Private)

Want to contribute to the documentation? Start here: [Contributing to the specification document](docs/README.md)

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
    - TileLinkTrafficAdapter-H723/
        - STM32H723ZG firmware for translating UART to the TSI bus.
    - scanchain/
        - **Not functional**. STM32F446RE firmware for translating UART to the analog scan chain bus. 
    - proxyFESVR/
        - **Not functional**. Fork of Franklin Huang's proxyFESVR library, modified to support SCuM-V. See the [README](sw/proxyFESVR/README.md) for more details.
    - tl_host.py
        - Python script for use with the STM32F446RE or STM32H723ZG to translate UART to SCuM's TSI bus. Default baud may differ; for the FPGA controller simulations and host simulators use 2,000,000 baud.
    - tl_host_sim.py
        - Simulation-oriented generator for `stl+` UART byte streams. Produces vector files used by `hw/scumv-controller/sim/scumv_controller_integration_tb.v`.

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
4. STM32 Nucleo-64 development board with STM32F446RE MCU _or_ Nucleo-144 development board with STM32H723ZG MCU
    - The STM32 board is used as a UART to TSI adapter to communicate with the digital portion of SCuM
    - [NUCLEO-F446RE](https://www.st.com/en/evaluation-tools/nucleo-f446re.html) _or_ [NUCLEO-H723ZG](https://www.st.com/en/evaluation-tools/nucleo-h723zg.html)

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
- External 3.5V supply (~120 mA current limit) <> PCB J1
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
- RESET     <>  GND  (active high)

**Serial TL Connection**

Serial TL connection between STM32 and SCuM-V. SCuM-V generates the clock in STL connection.

STM32F446RE:
- PA0 <> TL_OUT_READY [after shift down 3.3V to 1.8V]
- PA1 <> TL_OUT_VALID
- PA4 <> TL_OUT_DATA
- PB0 <> TL_IN_READY
- PC1 <> TL_IN_VALID [after shift down 3.3V to 1.8V]
- PC0 <> TL_IN_DATA [after shift down 3.3V to 1.8V]
- D10 <> TL_CLK
- BOOT_SEL <> Ground (tsi-boot)

STM32H723ZG:
- PA3 <>TL_OUT_READY
- PC0 <> TL_OUT_VALID
- PC3 <> TL_OUT_DATA
- PB1 <> TL_IN_READY
- PC2 <> TL_IN_VALID
- PF10 <>.TL_IN_DATA
- PD12 <> TL_CLK
- BOOT_SEL <> Ground (tsi-boot)

The level shifter from 3.3V TTL to 1.8V most commonly used is a simple voltage divider. When using the STM32 board as a TSI adapter, it is not necessary to shift up from 1.8V to 3.3V.

If using another level shifter, bandwidth should be >1 MHz and unidirectional shifting is acceptable.

**Clock Configuration**
- Clock input 0.85Vpp
    * Square Wave, 50% duty cycle
    * Offset: 0.425V
    * Frequency: 200kHz
- Clock <> J20, bypass 0
- dDebug <> J19 

## FPGA Setup & Simulation

### Programming the FPGA with the bitstream

This guide is based on and tested with Vivado 2022.1 on Windows. The steps should work for other versions of Vivado, but cannot be guaranteed. 

If you do run this on a different version of Vivado, please let us know if there are any issues or if your version is supported.

1. Open Vivado
2. In the TCL console and change the working directory to the `scum-v-bringup/hw/scanchain` directory. For example, if you cloned this repo to `C:\Projects\Repositories\scum-v-bringup`, then you would run the following command in the TCL console:

    ```bash
    cd C:/Projects/Repositories/scum-v-bringup/hw/scanchain
    ```
3. Generate the Vivado project by running the following command in the TCL console:

    ```bash
    source create_project.tcl
    ```

4. The Vivado project should now be open. Build the bitstream by running `Generate Bitstream` in the `Flow Navigator` panel.

5. Connect the Arty A7-100T to your computer via USB. The Arty A7-100T should show up as a USB device in the `Device Manager` on Windows or `lsusb` on Linux.

6. In the `Flow Navigator` panel, click on `Open Target` and select the Arty A7-100T as the device. Then `Program Device` The bitstream should now be flashed to the FPGA. You can verify that the bitstream has been flashed by seeing LED2 on the Arty A7-100T turn on (it is slaved to SCAN_CLK).

### Flashing the FPGA with the bitstream

This section is for downloading a program to the Arty A7-100T's QSPI flash device, which results in an FPGA bitstream configuration that persists between power-up/power-down cycles. It assumes you've setup the FPGA and built the bitstream as described in the previous section.

The following guide was used to configure the Vivado project to generate a `.bin` file that can be downloaded to the QSPI flash device on the Arty A7-100T:
https://digilent.com/reference/learn/programmable-logic/tutorials/arty-programming-guide/start

**Important**

For most new Arty A7-100T boards, the QSPI flash device that should be selected as a configuration memory device is `s25fl128sxxxxxx0-spi-x1_x2_x4`. However, some boards may have a different flash device.

### Making changes to the FPGA design
### Running the SCuM-V Controller simulation

- Testbench: `hw/scumv-controller/sim/scumv_controller_integration_tb.v`
- UART baud: 2,000,000
- Test vectors: generate with `sw/tl_host_sim.py` (see `hw/scumv-controller/sim/TEST_VECTORS_README.md`)
- Logging: TB mirrors console prints to `hw/scumv-controller/sim/scumv_controller_integration_tb.log`
- Flow control: TB models backpressure by deasserting TL input ready one of every four consumed bits

Working with Vivado and Git can be very painful. For this project, we've opted to use Vivado's Tcl scripting capabilities to generate the Vivado project.

This guide was used to setup the Vivado project to be generated by a Tcl script:
https://www.fpgadeveloper.com/2014/08/version-control-for-vivado-projects.html/

**However, this guide is old, and some changes are necessary for this project.**

1. In Vivado 2022.1, the project Tcl script can be generated opening the `Project Manager` in the `Flow Navigator` panel. Then, click `File > Project > Write Tcl...`
2. In the dialog, ensure `Copy sources to new project` is NOT checked. Then, click `OK`.
3. The Tcl script that is generated will be named `scanchain.tcl`, several edits need to be made.
    - Remove all lines related to of `*.dcp` files and the `utils_1` folder. Why would anyone want to track checkpoints?
    - Change all file links from `${origin_dir}/../../[path to file]` to `${origin_dir}/[path to file]`. 

## Writing to SCuM-V's ASC

Ensure **every** connection listed in the `Connections` section above was made correctly.

1. Make any modifications to the `client.py` script in the `hw/` folder then run:

    ```bash
    python client.py
    ```

## STM32 Setup

### Flashing the firmware

The STM32CubeIDE is needed to build and flash the firmware to the STM32 board. The IDE can be downloaded here: 
https://www.st.com/en/development-tools/stm32cubeide.html

## Building SCuM-V's firmware

### RISC-V Toolchain Setup - Windows

1. Install MSYS2 from https://www.msys2.org/

2. Install your choice distribution of RISC-V tools. This guide uses xpack from 

https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/

3. Set your path in the MSYS2 terminal to include the riscv toolchain
`export PATH=/c/riscv/xpack-riscv-none-elf-gcc-13.2.0-2/bin:$PATH`

### RISC-V Toolchain Setup - All other platforms

Reference the guide for the Baremetal-IDE here: https://ucb-bar.gitbook.io/chipyard/quickstart/setting-up-risc-v-toolchain


