"""SerialTL interface for the SCuM-V baseband modem.

Provides thin helpers to read/modify/write (word-aligned) fields and
convenience functions to enable/disable common subsystems. This is a
scaffold — expand with additional fields as you bring up features.
"""

import argparse
from typing import Optional

import serial

from tl_host import TileLinkHost, BASEBAND_BASE

# Convenience: all offsets below are byte offsets from BASEBAND_BASE

# Simple 1-bit controls
O_DEBUG_ENABLE = 0x23
O_VCO_ENABLE = 0x1A
O_VCO_DIV_ENABLE = 0x1B

# Manual enable bytes (multiple 1-bit fields packed LSB-first)
O_EN_I = 0x4A  # bits: mix(0) buf(1) tia(2) vga(3) bpf(4)
O_EN_Q = 0x4B  # bits: mix(0) buf(1) tia(2) vga(3) bpf(4)
O_EN_G = 0x4C  # bits: rx1(0) rx2(1) vco_lo(2) ext_lo(3)


def _bool_to_bit(v: bool | int) -> int:
    return 1 if bool(v) else 0


def set_debug_enable(host: TileLinkHost, enabled: bool, verbose: bool = True) -> None:
    host.write_field_by_offset(BASEBAND_BASE, O_DEBUG_ENABLE, bit_index=0, width=1,
                               value=_bool_to_bit(enabled), verbose=verbose)


def set_vco_enable(host: TileLinkHost, enabled: bool, verbose: bool = True) -> None:
    host.write_field_by_offset(BASEBAND_BASE, O_VCO_ENABLE, bit_index=0, width=1,
                               value=_bool_to_bit(enabled), verbose=verbose)


def set_vco_div_enable(host: TileLinkHost, enabled: bool, verbose: bool = True) -> None:
    host.write_field_by_offset(BASEBAND_BASE, O_VCO_DIV_ENABLE, bit_index=0, width=1,
                               value=_bool_to_bit(enabled), verbose=verbose)


def set_enable_i_chain(host: TileLinkHost,
                       mix: Optional[bool] = None,
                       buf: Optional[bool] = None,
                       tia: Optional[bool] = None,
                       vga: Optional[bool] = None,
                       bpf: Optional[bool] = None,
                       verbose: bool = True) -> None:
    fields = [(0, mix, "EN_I_MIX"), (1, buf, "EN_I_BUF"), (2, tia, "EN_I_TIA"),
              (3, vga, "EN_I_VGA"), (4, bpf, "EN_I_BPF")]
    for bit, val, label in fields:
        if val is not None:
            host.write_field_by_offset(BASEBAND_BASE, O_EN_I, bit_index=bit, width=1,
                                       value=_bool_to_bit(val), verbose=verbose)


def set_enable_q_chain(host: TileLinkHost,
                       mix: Optional[bool] = None,
                       buf: Optional[bool] = None,
                       tia: Optional[bool] = None,
                       vga: Optional[bool] = None,
                       bpf: Optional[bool] = None,
                       verbose: bool = True) -> None:
    fields = [(0, mix, "EN_Q_MIX"), (1, buf, "EN_Q_BUF"), (2, tia, "EN_Q_TIA"),
              (3, vga, "EN_Q_VGA"), (4, bpf, "EN_Q_BPF")]
    for bit, val, label in fields:
        if val is not None:
            host.write_field_by_offset(BASEBAND_BASE, O_EN_Q, bit_index=bit, width=1,
                                       value=_bool_to_bit(val), verbose=verbose)


def set_enable_global(host: TileLinkHost,
                      rx1: Optional[bool] = None,
                      rx2: Optional[bool] = None,
                      vco_lo: Optional[bool] = None,
                      ext_lo: Optional[bool] = None,
                      verbose: bool = True) -> None:
    fields = [(0, rx1, "EN_RX1"), (1, rx2, "EN_RX2"), (2, vco_lo, "EN_VCO_LO"), (3, ext_lo, "EN_EXT_LO")]
    for bit, val, label in fields:
        if val is not None:
            host.write_field_by_offset(BASEBAND_BASE, O_EN_G, bit_index=bit, width=1,
                                       value=_bool_to_bit(val), verbose=verbose)


def _add_bool_flag(parser: argparse.ArgumentParser, name: str, help_text: str):
    parser.add_argument(f"--{name}", type=int, choices=[0, 1], help=help_text)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="SCUM-V baseband control (SerialTL)")
    parser.add_argument("-p", "--port", default="/dev/tty.usbmodem103", help="SerialTL bridge port")

    # Debug/VCO
    _add_bool_flag(parser, "debug_enable", "Enable (1)/disable (0) baseband debug")
    _add_bool_flag(parser, "vco_enable", "Enable (1)/disable (0) VCO")
    _add_bool_flag(parser, "vco_div_enable", "Enable (1)/disable (0) VCO divider")

    # I-chain
    for flag, desc in [
        ("i_mix", "Enable I mixer"),
        ("i_buf", "Enable I buffer"),
        ("i_tia", "Enable I TIA"),
        ("i_vga", "Enable I VGA"),
        ("i_bpf", "Enable I BPF"),
    ]:
        _add_bool_flag(parser, flag, f"{desc} (1 on / 0 off)")

    # Q-chain
    for flag, desc in [
        ("q_mix", "Enable Q mixer"),
        ("q_buf", "Enable Q buffer"),
        ("q_tia", "Enable Q TIA"),
        ("q_vga", "Enable Q VGA"),
        ("q_bpf", "Enable Q BPF"),
    ]:
        _add_bool_flag(parser, flag, f"{desc} (1 on / 0 off)")

    # Global enables
    for flag, desc in [
        ("rx1", "Enable RX1"),
        ("rx2", "Enable RX2"),
        ("vco_lo", "Enable VCO LO"),
        ("ext_lo", "Enable external LO"),
    ]:
        _add_bool_flag(parser, flag, f"{desc} (1 on / 0 off)")

    args = parser.parse_args()

    ser = serial.Serial(args.port, baudrate=2_000_000, timeout=2)
    host = TileLinkHost(ser)

    try:
        if args.debug_enable is not None:
            set_debug_enable(host, bool(args.debug_enable))
        if args.vco_enable is not None:
            set_vco_enable(host, bool(args.vco_enable))
        if args.vco_div_enable is not None:
            set_vco_div_enable(host, bool(args.vco_div_enable))

        set_enable_i_chain(
            host,
            mix=None if args.i_mix is None else bool(args.i_mix),
            buf=None if args.i_buf is None else bool(args.i_buf),
            tia=None if args.i_tia is None else bool(args.i_tia),
            vga=None if args.i_vga is None else bool(args.i_vga),
            bpf=None if args.i_bpf is None else bool(args.i_bpf),
        )
        set_enable_q_chain(
            host,
            mix=None if args.q_mix is None else bool(args.q_mix),
            buf=None if args.q_buf is None else bool(args.q_buf),
            tia=None if args.q_tia is None else bool(args.q_tia),
            vga=None if args.q_vga is None else bool(args.q_vga),
            bpf=None if args.q_bpf is None else bool(args.q_bpf),
        )
        set_enable_global(
            host,
            rx1=None if args.rx1 is None else bool(args.rx1),
            rx2=None if args.rx2 is None else bool(args.rx2),
            vco_lo=None if args.vco_lo is None else bool(args.vco_lo),
            ext_lo=None if args.ext_lo is None else bool(args.ext_lo),
        )
    finally:
        ser.close()
