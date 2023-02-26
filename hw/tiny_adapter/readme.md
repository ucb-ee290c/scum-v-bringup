# Uart-TSI Converter
A simple serial to serial converter, from uart packets to TSI. 

## Default configuration
- TSI width of 123 bits
- No DRAM backing on the physical chip, software must handle DRAM queries from the chip.
- Chiptop configured for cmod 35t FPGA
- 10MHz TSI, 3MBaud UART

## Customization
To change the TSI width for a different chip, simply go to `./TinyAdapter.srcs/sources_1/chiptop` and modify the parameter `WIDTH`, you must also modify the proxyFESVR's TSI parameters to match the chip. 

Any other deviation from this default scope will result in the need of clock and ILA reconfiguration on chiptop, proxyFESVR software change, and possible emergence of other bugs. 

## Pin Mapping
See `./TinyAdapter.srcs/constrs_1/new/cmod35.xdc` for the pinout.

## Packet Format
There are no headers or frame preambles, just consecutive completely serial TSI packets rounded up to the nearest byte so uart can transmit. Both transmits LSBit first. 

## Reset Mechanism
When all the TSI bits are high, reset the testchip first for 0.5s, then reset itself for 0.5s. The computer should send at least two TSI packets worth of 1s to guarentee reset when FPGA or chip is in an unknown state. No mechanism of informing computer successful completion of reset currently for simplicity, this can fail sometimes, just rerun the reset. 

Edge case: if the memory bus is frozen, say TL_OUT_RD is low for a long time, nothing wil be able to reset if shiftReg is waiting for that to clear. To clear this edge case, there must be a separate detector that detects the amount of continuous all high UART packets to trigger the reset regardless of the state of the TL_OUT. For now this case is ignored, but it may happen. 

## Timeout Mechanism
No hardware timeouts are present for sake of simplicity. Implementing this in software. Should host detect no response after a certain TSI query, they should timeout and reset everything. 