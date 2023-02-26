# Proxy FESVR
A proxy FESVR (frontend server) that works on any Linux and Windows PC backend, designed for bringup chips directly through TSI adapters, without any large FPGA cores in the middle. 

Current structure is main -> fesvr -> tsi -> driver lib, where fesvr and tsi class are polymorphic abstract classes. See main.cpp, fesvr.h, tsi.h for more details. All functions are commented and is self-explanatory. 

## Demos/Labs
 - OsciBear, see readme under osci folder.

## General Notes
 - After cloning, use `git submodule update --init --recursive` to init the rs232 submodule.

 ### Linux / MacOS

- To build the project make sure you have cmake installed.
    ```
    sudo apt-get install cmake
    ```
- Make a folder to contain the build artifacts (CMake-generated Makefile, binaries, etc)
    ```
    mkdir out
    ```
- Generate build artifacts
    ```
    cd out && cmake ..
    ```
- From now on, to build the project all you need is to run `make` and run the app
    ```
    make
    ./fesvr
    ```

### Windows

Visual Studio 2017+ supports CMake, where you can simply open the `src/` folder in Visual Studio and it will recognize and setup the CMake project.

A full guide to Visual Studio's CMake functionality can be found here: https://learn.microsoft.com/en-us/cpp/build/cmake-projects-in-visual-studio?view=msvc-170

However, it's generally as simple as opening the folder, waiting a moment for the cache to generate, then  under the green play button "Select Startup Item" select "fesvr.exe" and then click the green play button to run the project.

## Hardware Implementations
Different hardware implementations require different driver code, and may have different capabilities. Currently we have an TLAdapter on FPGA and microcontroller. 

### UART-TSI Drivers
Uses the TSI Adapter on either FPGA or microcontroller. Current revision only supports FPGA, but will adapt the PyFTDI script written already to support microcontroller (mainly byte and bit alignment differences). All UART drivers will use the UART library https://github.com/FlorianBauer/rs232 at 3M baud, the maximum common baud supported by Windows and Linux. Submodule is already included, please `git submodule update --init --recursive`.

### Ethernet-TSI Drivers (Future)
No hardware has been developed yet, but to improve bandwidth to 25-100Mbps down the road we can extend support to talk to the FPGA/microcontroller through ethernet. On the reciever, we will run FreeRTOS+TCP stack that supports POSIX style sockets; on the host, we can also write drivers through POSIX socket and port to windows through Cygwin. 

### PCIe-TSI Drivers (Future)
This is nowhere near our roadmap as large data transfers between the PC and DUT are not very critical. But we looked into this option as well, UCSD has an open source driver https://github.com/KastnerRG/riffa, which has known support on AC701, a board with artix 7 200T chip & a PCIe 4x 2.0 port. 

## Relation with the original FESVR
Much of this support will remain only for TSI initially, but once we can talk to TSI, we can talk to any peripheral MMIO ports by talking to the adapter's physical or virtual TL bus directly. Decision choice remains using C++ since we want high portability and potential backwards compatibility with the original actual FESVR code. We will try to be compatible with the original FESVR, but that infrastructure is so large it will take sometime to sort out how to make the port. The priority remains to be about lightweight bringup of chips. 