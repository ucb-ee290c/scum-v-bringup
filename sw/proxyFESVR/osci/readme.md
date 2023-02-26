# OsciBear Bringup Lab Demo
Goals: To let students quickly understand...

1. the approaches to bringup past tapeout chips
2. how hardware and software interacts during bringup
3. what better design ideas there are for future iterations
4. *the importance of leaving a good specification*

## Reading Resources
There are other ways of bringing up the chip, such as using XIP or JTAG interface. The TSI interface currently is the most stable one and has never failed us. It is a serial interface that talks to the on chip memory subsystem bus directly, conforming Tilelink spec. You do not need to understand the underlying hardware to get this lab going, but if needed, please read bringup class [lab 2](https://github.com/ucberkeley-ee290c/fa22/tree/main/labs/lab2-tsi-flow). 
 - OsciBear spec
 - Chipyard Section 8.2 Communicating with the dut
 - [SiFive's](https://static.dev.sifive.com/FE310-G000.pdf)/Yufeng's GPIO Documentation

## Physical Setup
Upload TinyAdapter's `./osci/chiptop.bit` using vivado. BTN0 is a reset button for FPGA, which will light up `led[0]` when FPGA itself is being resetted. The reset through an all high TSI packet will reset both the FPGA and dut. Staff should have already physically setup the board. 
### Pin Mapping and Wiring Instructions
You need to connect all the cmod 35t pmod pins (the black rectangle 10 pin module) to OsciBear board and level shift it correctly. Use caution, or you will burn a board or burn a chip. cmod35t uses 3v3 IO and OsciBear uses 1v8 IO.
 - 8 signal pins corresponding to CLK10MHZ, TL_OUT_RDY, TL_OUT_VAL, TL_OUT_DAT, TL_IN_RDY, TL_IN_VAL, TL_IN_DAT, RST in order. The FPGA does not need to observe TL_CLK since it is generating the CLK, and the dut will phase lock according to it. See how the pins are mapped using TinyAdapter's XDC file if you need to modify it. Use the level shifter board between these signals. 
 - Use cmod35t's 3v3 pins to connect to both the level shifters and OsciBear board, there is a pin right above the 3v3 led. 
 - Connect the 1v8 pin back to the level shifter as a voltage reference. 
 - Jumper wire GPIO_0 and GPIO_1 pins to D4 and D5 led at top of the board to see a visual.

## Excercises
Write out all programs in order as commented in `main.cpp` in fesvr. Compile by running `make clean` and `make all` in `./src` then run `./fesvr`. Sometimes the FPGA or chip might not reset properly, Ctrl-C and rerun the program if that is the case. 

## 1: Memory Contents
Start by playing with the MMIO perpipherals of OsciBear using TSI interface. 
1. Read out the OsciBear bootrom at `BOOTROM_BASE` using TSI commands alone, what are the first four words of bootrom in hex? 
2. Probe the scratchpad beginning at `DTIM_BASE`, and see how big it is by looping through reads in 0x100 increments until the program halts. How many KBs is the scratchpad? (Comment out this program after completing.)

## 2: La Campanella
Using host, write a program to toggle the GPIO_0 at `GPIO_BASE` pin high. Observe that the led connected to GPIO_0 is lit up. Then use the sleep function on host to make GPIO_0 flash on and off at a ~1 second interval for 3 seconds, leave it on. (On, off, on).

## 3: La Campanile
Now you will upload an actual prewritten program `firmware.bin` to host. There are still some scaffolding code so please bear with us. 

### Setting up RPC (Remote Procedure Call)
To make evaluating test suites easier and allow program handoffs between host and the dut, we designate an pre-agreed memory location `DTIM_RET` to show that our code has completed running, `DTIM_RET=0x80004000` for `firmware.bin`. 

In your host code
1. write 0 to DTIM_RET. 
2. Upload the program using `fesvr.loadelf`
3. Run the program using `fesvr.run`, make sure it has begun running by checking the value displayed on terminal is `0x0`. If not, you need to reset the chip with a grounded MSEL to indicate we are booting through TSI. 
4. Poll `DTIM_RET` every second to check if program has completed running. 

## 4: "Not for the faint of heart"
### Part 1
Writing your own campanile program using the [HAL](https://github.com/ucberkeley-ee290c/HAL/blob/main/firmware/README.md) library, this time, flash both `GPIO_0` and `GPIO_1` pins high or low in the same second. 

### Part 2
Test both UART_TX and SPI functionality through whatever means you think is best. Are both working? If any of it is not working, is it fixable? How do we not mess up again? 

## Acknowledgements
This revised lab is built upon fall 22 bringup lab 2, less in depth in theory but much more hand on. 