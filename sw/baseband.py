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
O_VCO_IDAC = 0x44
O_VCO_DIV_ENABLE = 0x1B

# Manual enable bytes (multiple 1-bit fields packed LSB-first)
O_EN_I = 0x4A  # bits: mix(0) buf(1) tia(2) vga(3) bpf(4)
O_EN_Q = 0x4B  # bits: mix(0) buf(1) tia(2) vga(3) bpf(4)
O_EN_G = 0x4C  # bits: rx1(0) rx2(1) vco_lo(2) ext_lo(3)

# Baseband command registers and constants
O_INST = 0x00
O_ADDITIONAL_DATA = 0x04
O_LUT_CMD = 0x50

BASEBAND_PRIMARY_CONFIG = 0x0
BASEBAND_CONFIG_RADIO_MODE = 0x0
BASEBAND_CONFIG_BLE_CHANNEL_INDEX = 0x4

BASEBAND_MODE_BLE = 0x0

LUT_VCO_CT_BLE = 0x1

COARSE_WIDTH = 10
MEDIUM_WIDTH = 6
CHANNEL0_INDEX = 0


def _bool_to_bit(v: bool | int) -> int:
    return 1 if bool(v) else 0


def _encode_instruction(primary: int, secondary: int, data: int) -> int:
    return ((primary & 0xF)
            | ((secondary & 0xF) << 4)
            | ((data & 0xFFFFFF) << 8))


def _lut_command(lut: int, address: int, value: int) -> int:
    return ((lut & 0xF)
            | ((address & 0x3F) << 4)
            | ((value & 0x3FFFFF) << 10))


def baseband_configure(host: TileLinkHost,
                       target: int,
                       value: int,
                       verbose: bool = True) -> None:
    host.write_address(BASEBAND_BASE + O_ADDITIONAL_DATA, value & 0xFFFFFFFF,
                       verbose=False)
    instruction = _encode_instruction(BASEBAND_PRIMARY_CONFIG, target, 0)
    host.write_address(BASEBAND_BASE + O_INST, instruction, verbose=False)
    if verbose:
        print(f"[BASEBAND CONFIG] target=0x{target:X}, value=0x{value:08X}")


def baseband_set_lut_entry(host: TileLinkHost,
                           lut: int,
                           address: int,
                           value: int,
                           verbose: bool = True) -> None:
    command = _lut_command(lut, address, value)
    host.write_address(BASEBAND_BASE + O_LUT_CMD, command, verbose=False)
    if verbose:
        print(f"[BASEBAND LUT] lut={lut}, addr={address}, value=0x{value:06X}")


def _pack_channel_tuning_value(coarse: int, medium: int) -> int:
    coarse_mask = (1 << COARSE_WIDTH) - 1
    medium_mask = (1 << MEDIUM_WIDTH) - 1
    packed_code = ((medium & medium_mask) << COARSE_WIDTH) | (coarse & coarse_mask)
    print(f"Packed code: 0b{packed_code:016b}")
    return packed_code


def _configure_ble_channel0(host: TileLinkHost, verbose: bool = True) -> None:
    baseband_configure(host, BASEBAND_CONFIG_RADIO_MODE, BASEBAND_MODE_BLE,
                       verbose=False)
    baseband_configure(host, BASEBAND_CONFIG_BLE_CHANNEL_INDEX, CHANNEL0_INDEX,
                       verbose=False)
    if verbose:
        print("[BASEBAND] BLE mode enabled, channel index set to 0")


def _program_channel0_tuning(host: TileLinkHost,
                             coarse: int,
                             medium: int,
                             verbose: bool = True) -> None:
    packed = _pack_channel_tuning_value(coarse, medium)
    baseband_set_lut_entry(host, LUT_VCO_CT_BLE, CHANNEL0_INDEX, packed,
                           verbose=False)
    if verbose:
        print(
            f"[VCO CT] channel=0 coarse={coarse} (0x{coarse:03X}) "
            f"medium={medium} (0x{medium:02X}) raw=0x{packed:04X}"
        )


def _prompt_step(label: str, current: int, width: int) -> Optional[int]:
    command = input(
        f"[{label}] value=0b{current:0{width}b} (0x{current:X}, {current}). "
        "Enter=inc, 'r'=reset, 'q'=quit, or type next value: "
    ).strip()

    if not command:
        return (current + 1) & ((1 << width) - 1)

    lowered = command.lower()
    if lowered in {"q", "quit"}:
        return None
    if lowered in {"r", "reset"}:
        return 0

    try:
        return int(command, 0)
    except ValueError:
        print(f"Unrecognized entry '{command}', keeping previous value.")
        return current


def _prompt_step_both(coarse: int, medium: int) -> Optional[tuple[int, int]]:
    """Prompt for both coarse and medium values.
    
    Returns:
        Tuple of (coarse, medium) or None to quit.
        Enter increments medium first, then coarse on overflow.
    """
    command = input(
        f"[VCO both] coarse={coarse} (0x{coarse:03X}), medium={medium} (0x{medium:02X}). "
        "Enter=inc, 'r'=reset, 'q'=quit, or type 'coarse, medium': "
    ).strip()

    coarse_mask = (1 << COARSE_WIDTH) - 1
    medium_mask = (1 << MEDIUM_WIDTH) - 1

    if not command:
        # Increment medium first, then coarse on overflow
        new_medium = (medium + 1) & medium_mask
        new_coarse = coarse
        if new_medium == 0:  # Medium wrapped, increment coarse
            new_coarse = (coarse + 1) & coarse_mask
        return (new_coarse, new_medium)

    lowered = command.lower()
    if lowered in {"q", "quit"}:
        return None
    if lowered in {"r", "reset"}:
        return (0, 0)

    # Try parsing "coarse, medium" format
    if "," in command:
        try:
            parts = command.split(",")
            if len(parts) == 2:
                new_coarse = int(parts[0].strip(), 0) & coarse_mask
                new_medium = int(parts[1].strip(), 0) & medium_mask
                return (new_coarse, new_medium)
        except ValueError:
            pass

    print(f"Unrecognized entry '{command}', keeping previous values.")
    return (coarse, medium)


def sweep_vco_idac(host: TileLinkHost,
                   idac_start: int) -> None:
    _configure_ble_channel0(host, verbose=True)
    idac_mask = (1 << 6) - 1
    idac = idac_start & idac_mask

    print("Entering VCO IDAC sweep. Ctrl+C or 'q' to exit.")
    while True:
        set_vco_idac(host, idac, verbose=False)
        next_value = _prompt_step("VCO idac", idac, 6)
        if next_value is None:
            break
        idac = next_value & idac_mask


def sweep_channel0_coarse(host: TileLinkHost,
                          coarse_start: int,
                          medium_hold: int) -> None:
    _configure_ble_channel0(host, verbose=True)
    coarse_mask = (1 << COARSE_WIDTH) - 1
    coarse = coarse_start & coarse_mask
    medium = medium_hold & ((1 << MEDIUM_WIDTH) - 1)

    print("Entering BLE channel 0 VCO coarse sweep. Ctrl+C or 'q' to exit.")
    while True:
        _program_channel0_tuning(host, coarse, medium)
        next_value = _prompt_step("VCO coarse", coarse, COARSE_WIDTH)
        if next_value is None:
            break
        coarse = next_value & coarse_mask


def sweep_channel0_medium(host: TileLinkHost,
                          medium_start: int,
                          coarse_hold: int) -> None:
    _configure_ble_channel0(host, verbose=False)
    medium_mask = (1 << MEDIUM_WIDTH) - 1
    medium = medium_start & medium_mask
    coarse = coarse_hold & ((1 << COARSE_WIDTH) - 1)

    print("Entering BLE channel 0 VCO medium sweep. Ctrl+C or 'q' to exit.")
    while True:
        _program_channel0_tuning(host, coarse, medium)
        next_value = _prompt_step("VCO medium", medium, MEDIUM_WIDTH)
        if next_value is None:
            break
        medium = next_value & medium_mask

def sweep_channel0_both(host: TileLinkHost,
                        coarse_start: int,
                        medium_start: int) -> None:
    """Sweep both coarse and medium VCO codes for BLE channel 0.
    
    Increment behavior: medium increments first, then coarse when medium overflows.
    """
    _configure_ble_channel0(host, verbose=True)
    coarse_mask = (1 << COARSE_WIDTH) - 1
    medium_mask = (1 << MEDIUM_WIDTH) - 1
    coarse = coarse_start & coarse_mask
    medium = medium_start & medium_mask

    print("Entering BLE channel 0 VCO both sweep. Ctrl+C or 'q' to exit.")
    while True:
        _program_channel0_tuning(host, coarse, medium)
        next_values = _prompt_step_both(coarse, medium)
        if next_values is None:
            break
        coarse, medium = next_values


def set_debug_enable(host: TileLinkHost, enabled: bool, verbose: bool = True) -> None:
    host.write_field_by_offset(BASEBAND_BASE, O_DEBUG_ENABLE, bit_index=0, width=1,
                               value=_bool_to_bit(enabled), verbose=verbose)


def set_vco_enable(host: TileLinkHost, enabled: bool, verbose: bool = True) -> None:
    host.write_field_by_offset(BASEBAND_BASE, O_VCO_ENABLE, bit_index=0, width=1,
                               value=_bool_to_bit(enabled), verbose=verbose)

def set_vco_idac(host: TileLinkHost, idac: int, verbose: bool = True) -> None:
    host.write_field_by_offset(BASEBAND_BASE, O_VCO_IDAC, bit_index=0, width=6,
                               value=idac, verbose=verbose)


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
    parser.add_argument("-p", "--port", default="COM6", help="SerialTL bridge port")

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

    parser.add_argument("--sweep_ct_coarse", action="store_true",
                        help="Interactively sweep BLE channel 0 VCO coarse bits")
    parser.add_argument("--sweep_ct_medium", action="store_true",
                        help="Interactively sweep BLE channel 0 VCO medium bits")
    parser.add_argument("--sweep_ct_both", action="store_true",
                        help="Interactively sweep BLE channel 0 VCO both coarse and medium bits")
    parser.add_argument("--ct_coarse_start", type=int, default=0,
                        help="Initial coarse value (10-bit) when sweeping")
    parser.add_argument("--ct_medium_start", type=int, default=0,
                        help="Initial medium value (6-bit) when sweeping")
    parser.add_argument("--ct_medium_hold", type=int, default=None,
                        help="Medium bits to hold during coarse sweep (default: ct_medium_start)")
    parser.add_argument("--ct_coarse_hold", type=int, default=None,
                        help="Coarse bits to hold during medium sweep (default: ct_coarse_start)")
    parser.add_argument("--sweep_vco_idac", action="store_true",
                        help="Interactively sweep VCO IDAC bits")
    parser.add_argument("--vco_idac_start", type=int, default=0,
                        help="Initial IDAC value (6-bit) when sweeping")

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

        coarse_hold = args.ct_coarse_hold if args.ct_coarse_hold is not None else args.ct_coarse_start
        medium_hold = args.ct_medium_hold if args.ct_medium_hold is not None else args.ct_medium_start

        if args.sweep_ct_coarse:
            sweep_channel0_coarse(host, args.ct_coarse_start, medium_hold)
        if args.sweep_ct_medium:
            sweep_channel0_medium(host, args.ct_medium_start, coarse_hold)
        if args.sweep_ct_both:
            sweep_channel0_both(host, args.ct_coarse_start, args.ct_medium_start)
        if args.sweep_vco_idac:
            sweep_vco_idac(host, args.vco_idac_start)
    except KeyboardInterrupt:
        print("\nExiting baseband control (keyboard interrupt).")
    finally:
        ser.close()
