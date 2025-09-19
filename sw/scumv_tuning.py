"""Interactive SCμM-V sweep helper.

Write SCUMVTuning registers over the TileLink host so you can sweep CPU and ADC
oscillator codes directly from SerialTL.
"""

import argparse
import sys
from typing import Optional

import serial

from tl_host import TileLinkHost

SCUMVTUNING_BASE = 0xA000
SCUMVTUNING_ADC_TUNE_OUT_COARSE = SCUMVTUNING_BASE + 0x00
SCUMVTUNING_DIG_WORD_ADDR = SCUMVTUNING_BASE + 0x04
SCUMVTUNING_ADC_RESET = SCUMVTUNING_BASE + 0x06
SCUMVTUNING_DIG_RESET = SCUMVTUNING_BASE + 0x07
SCUMVTUNING_DIG_TUNE_OUT = SCUMVTUNING_BASE + 0x04

DIG_TUNE_SHIFT = 0
DIG_TUNE_WIDTH = 6
ADC_RESET_SHIFT = 16
DIG_RESET_SHIFT = 24

ADC_COARSE_WIDTH = 9
CPU_TUNE_WIDTH = 6

SERIAL_INTERFACE_BAUD_RATE = 2000000
SERIAL_INTERFACE_TIMEOUT = 2  # seconds


def _prompt_step(current: int, label: str, width: int) -> Optional[int]:
    """Prompt for the next action; Enter increments, r resets, q quits."""
    command = input(
        f"[{label}] value=0b{current:0{width}b} (0x{current:X}, {current}). "
        "Press Enter to increment, 'r' to reset, 'q' to quit: "
    ).strip().lower()

    if command in {"q", "quit"}:
        return None
    if command in {"r", "reset"}:
        return 0
    return current + 1


def _update_field(host: TileLinkHost,
                  word_addr: int,
                  shift: int,
                  width: int,
                  value: int,
                  label: str) -> None:
    """Read-modify-write a 32-bit word-aligned field with logging."""
    mask = ((1 << width) - 1) << shift
    sanitized = value & ((1 << width) - 1)
    current_word = host.read_address(word_addr, verbose=False) & 0xFFFFFFFF
    print(f"{label}: read  0x{current_word:08X} @0x{word_addr:04X}")
    new_word = (current_word & ~mask) | (sanitized << shift)
    print(f"{label}: write 0x{new_word:08X} @0x{word_addr:04X}")
    host.write_address(word_addr, new_word, verbose=False)


def sweep_cpu_clock(host: TileLinkHost, start_value: int = 0) -> None:
    """Interactively sweep the digital oscillator bits (6-bit field)."""
    mask = (1 << CPU_TUNE_WIDTH) - 1
    value = start_value & mask

    print("Entering CPU clock sweep mode. Use Ctrl+C or 'q' to exit.")
    while True:
        _update_field(host,
                      SCUMVTUNING_DIG_WORD_ADDR,
                      DIG_TUNE_SHIFT,
                      DIG_TUNE_WIDTH,
                      value,
                      label="DIG_TUNE")
        next_value = _prompt_step(value, "CPU", CPU_TUNE_WIDTH)
        if next_value is None:
            break
        value = next_value & mask


def sweep_adc_clock(host: TileLinkHost, start_value: int = 0) -> None:
    """Interactively sweep the ADC coarse oscillator bits (9-bit field)."""
    mask = (1 << ADC_COARSE_WIDTH) - 1
    value = start_value & mask

    print("Entering ADC clock sweep mode. Use Ctrl+C or 'q' to exit.")
    while True:
        host.write_address(SCUMVTUNING_ADC_TUNE_OUT_COARSE, value, verbose=False)
        next_value = _prompt_step(value, "ADC", ADC_COARSE_WIDTH)
        if next_value is None:
            break
        value = next_value & mask


def set_clk_dig_rst(host: TileLinkHost, value: bool) -> None:
    """Assert or deassert the digital clock reset bit."""
    _update_field(host,
                  SCUMVTUNING_DIG_WORD_ADDR,
                  DIG_RESET_SHIFT,
                  1,
                  1 if value else 0,
                  label="DIG_RST")


def set_clk_adc_rst(host: TileLinkHost, value: bool) -> None:
    """Assert or deassert the ADC clock reset bit."""
    _update_field(host,
                  SCUMVTUNING_DIG_WORD_ADDR,
                  ADC_RESET_SHIFT,
                  1,
                  1 if value else 0,
                  label="ADC_RST")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="SCUM-V sweep utility")
    parser.add_argument("-p", "--port", default="COM6",
                        help="Serial port connected to the TileLink bridge")
    parser.add_argument("--sweep_cpu_clock", action="store_true",
                        help="Run the CPU oscillator sweep loop")
    parser.add_argument("--sweep_adc_clock", action="store_true",
                        help="Run the ADC oscillator sweep loop")
    parser.add_argument("--cpu_start", type=int, default=0,
                        help="Initial value for the CPU tuning register")
    parser.add_argument("--adc_start", type=int, default=0,
                        help="Initial value for the ADC coarse register")

    args = parser.parse_args()

    if not args.sweep_cpu_clock and not args.sweep_adc_clock:
        print("No sweep selected. Use --sweep_cpu_clock and/or --sweep_adc_clock.")
        sys.exit(0)

    try:
        serial_port = serial.Serial(
            args.port,
            baudrate=SERIAL_INTERFACE_BAUD_RATE,
            timeout=SERIAL_INTERFACE_TIMEOUT,
        )
    except serial.SerialException as err:
        print(f"Failed to open serial port {args.port}: {err}")
        sys.exit(1)

    host = TileLinkHost(serial_port)

    try:
        if args.sweep_cpu_clock:
            set_clk_dig_rst(host, value=True)
            sweep_cpu_clock(host, args.cpu_start)
        if args.sweep_adc_clock:
            set_clk_adc_rst(host, value=True)
            sweep_adc_clock(host, args.adc_start)
    except KeyboardInterrupt:
        print("\nExiting tuning utility (keyboard interrupt).")
    finally:
        serial_port.close()
