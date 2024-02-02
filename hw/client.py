import argparse
from enum import Enum
from time import sleep

import serial

# Serial interface.
SERIAL_INTERFACE_BAUD_RATE = 115200


class Addr(Enum):
    """Address of the scan chain domain (set value as the address)."""
    RESET_ADDR = 0
    OSC_ADDR = 1
    RF_ADDR = 2
    PWR_ADDR = 3


class Clock(Enum):
    CPU_CLK = 0
    RTC_CLK = 1
    ADC_CLK = 2


class ScanChainPacket:
    """The format is {2"b0, reset, payload, addr}, where reset is 1 bit, payload is
    169 bits, and addr is 12 bits.
    """
    def __init__(self, addr: Addr, payload: int, reset: bool = False):
        # Check the type of addr.
        self.addr: int = addr.value
        self.payload = payload
        self.reset = reset

    def to_bits(self) -> bytearray:
        out = self.addr | (self.payload << 12) | (self.reset << (12 + 169))
        return out.to_bytes(23, byteorder="big")


class ScanChainPayload:
    """Parent class for payloads (payload should overwrite the _reg list)."""
    # List of tuples of register names and their widths in the order they
    # appear in the payload (FIRST SENT TO LAST SENT).
    _reg = [("first_reg_name", 8), ("last_reg_name", 8)]

    def __init__(self, payload: dict = None):
        # Create a dictionary of register names to their values.
        self.reg_vals = {r: 0 for r, _ in self._reg}
        if payload is not None:
            for reg_name, reg_val in payload.items():
                self.set_reg(reg_name, reg_val)

    def set_reg(self, reg_name, reg_val):
        """Set the value of a register."""
        if reg_name not in self.reg_vals:
            raise ValueError(f"Invalid register name: {reg_name}.")
        self.reg_vals[reg_name] = reg_val

    def create(self):
        """Create the payload from the register values."""
        payload = 0
        # Iterate through registers from the LSB to the MSB.
        curr_pos = 0
        for reg_name, reg_size in self._reg[::-1]:
            reg_val = self.reg_vals[reg_name]
            payload |= reg_val << curr_pos
            curr_pos += reg_size
        return payload


class SupplyPayload(ScanChainPayload):
    """
    First
        bgr_temp_ctrl[5]
        bgr_vref_ctrl[5]
        current_src_left_ctrl[5]
        current_src_right_ctrl[5]
    Last
    """
    _reg = [("bgr_temp_ctrl", 5), ("bgr_vref_ctrl", 5),
            ("current_src_left_ctrl", 5), ("current_src_right_ctrl", 5)]


class OscillatorPayload(ScanChainPayload):
    """The oscillator scan chain payload is still not fully understood and does 
    not match the documentation.
    # dbg_mux_sel_0, dbg_mux_sel_1
    # 0, 0 -> CPU_CLK
    # 0, 1 -> CPU_CLK
    # 1, 0 -> RTC_CLK
    # 1, 1 -> ADC_CLK
    
    First
        adc_tune_out[16]
        adc_reset[1]
        dig_tune_out[16]
        dig_reset[1]
        rtc_tune_out[16]
        rtc_reset[1]
        debug_mux_ctrl[2]
    Last
    """
    _reg = [
        ("?????", 1),
        ("adc_coarse_dac", 7),
        ("adc_fine_dac", 8),
        ("adc_reset", 1),
        ("dig_div_two", 1),
        ("????", 4),
        ("dig_col_decoder", 5),
        ("dig_row_decoder", 6),
        ("dig_reset", 1),
        ("???", 12),
        ("cpu_bypass", 1),
        ("adc_bypass", 1),
        ("dbg_mux_sel_1", 1),
        ("dbg_mux_sel_0", 1),
        ("??", 2),
        # ("all_bits", 10),
    ]

    def set_dbg_clock(self, clock: Clock):
        """Set the mux to output the specified clock to the DBG_CLK_OUT pin."""
        if clock == Clock.CPU_CLK:
            self.set_reg("dbg_mux_sel_0", 0)
            self.set_reg("dbg_mux_sel_1", 0)
        elif clock == Clock.RTC_CLK:
            self.set_reg("dbg_mux_sel_0", 1)
            self.set_reg("dbg_mux_sel_1", 0)
        elif clock == Clock.ADC_CLK:
            self.set_reg("dbg_mux_sel_0", 1)
            self.set_reg("dbg_mux_sel_1", 1)
        else:
            raise ValueError("Invalid clock value.")


class RFAnalogPayload(ScanChainPayload):
    """
        Register Name	Width	Bit
    First
        tuning_trim_g0	8	8
        # TIA GAIN CTR probably top bit of vga_gain_ctrl.
        vga_gain_ctrl_q	10	10
        vga_gain_ctrl_i	10	10
        current_dac_vga_i	6	6
        current_dac_vga_q	6	6
        bpf_i_chp0	4	4
        bpf_i_chp1	4	4
        bpf_i_chp2	4	4
        bpf_i_chp3	4	4
        bpf_i_chp4	4	4
        bpf_i_chp5	4	4
        bpf_i_clp0	4	4
        bpf_i_clp1	4	4
        bpf_i_clp2	4	4
        bpf_q_chp0	4	4
        bpf_q_chp1	4	4
        bpf_q_chp2	4	4
        bpf_q_chp3	4	4
        bpf_q_chp4	4	4
        bpf_q_chp5	4	4
        bpf_q_clp0	4	4
        bpf_q_clp1	4	4
        bpf_q_clp2	4	4
        vco_cap_coarse	10	10
        vco_cap_med	6	6
        vco_cap_mod	8	8
        vco_freq_reset	1	1
        en_lna	1	1
        en_mix_i	1	1
        en_mix_q	1	1
        en_tia_i	1	1
        en_tia_q	1	1
        en_buf_i	1	1
        en_buf_q	1	1
        en_vga_i	1	1
        en_vga_q	1	1
        en_bpf_i	1	1
        en_bpf_q	1	1
        en_vco_lo	1	1
        mux_dbg_in	10	10
        mux_dbg_out	10	10
    Last (bits 9-0)
    """

    _reg = [("tuning_trim_g0", 8), ("vga_gain_ctrl_q", 10),
            ("vga_gain_ctrl_i", 10), ("current_dac_vga_i", 6),
            ("current_dac_vga_q", 6), ("bpf_i_chp0", 4), ("bpf_i_chp1", 4),
            ("bpf_i_chp2", 4), ("bpf_i_chp3", 4), ("bpf_i_chp4", 4),
            ("bpf_i_chp5", 4), ("bpf_i_clp0", 4), ("bpf_i_clp1", 4),
            ("bpf_i_clp2", 4), ("bpf_q_chp0", 4), ("bpf_q_chp1", 4),
            ("bpf_q_chp2", 4), ("bpf_q_chp3", 4), ("bpf_q_chp4", 4),
            ("bpf_q_chp5", 4), ("bpf_q_clp0", 4), ("bpf_q_clp1", 4),
            ("bpf_q_clp2", 4), ("vco_cap_coarse", 10), ("vco_cap_med", 6),
            ("vco_cap_mod", 8), ("vco_freq_reset", 1), ("en_lna", 1),
            ("en_mix_i", 1), ("en_mix_q", 1), ("en_tia_i", 1), ("en_tia_q", 1),
            ("en_buf_i", 1), ("en_buf_q", 1), ("en_vga_i", 1), ("en_vga_q", 1),
            ("en_bpf_i", 1), ("en_bpf_q", 1), ("en_vco_lo", 1),
            ("mux_dbg_in", 10), ("mux_dbg_out", 10)]


class SerialInterface:
    """Serial interface to the FPGA."""
    def __init__(self, port: str):
        self.serial = serial.Serial(args.port,
                                    baudrate=SERIAL_INTERFACE_BAUD_RATE)

    def send_packet(self, packet: ScanChainPacket) -> None:
        """Send a packet over the serial interface."""
        packet_bytes = packet.to_bits()
        print(f"[TX] {packet_bytes}")
        self.serial.write(packet_bytes)
        response = self.serial.read(1)
        print(f"[RX] {response}")


# Prepare a scan chain reset packet.
reset_pkt = ScanChainPacket(Addr.RESET_ADDR, 0, True)

# Prepare a packet to configure the oscillator/clocks subsystem.
osc_payload = OscillatorPayload({
    "cpu_bypass": 0,
    "adc_bypass": 0,
    "dig_div_two": 1,
    "adc_fine_dac": 0b01000000,
    "adc_coarse_dac": 0b0010000,  # 0b0001111 gets close to 32 MHz.
    "dig_col_decoder": 0b10110,
    "dig_row_decoder": 0b000001,
})
osc_payload.set_dbg_clock(Clock.CPU_CLK)
clk_pkt = ScanChainPacket(Addr.OSC_ADDR, osc_payload.create())

sup_payload = SupplyPayload({"bgr_vref_ctrl": 0b00011})
sup_pkt = ScanChainPacket(Addr.PWR_ADDR, sup_payload.create())

rf_low_payload = RFAnalogPayload({
    "vco_cap_coarse": 0,
    "vco_cap_med": 0,
    "vco_cap_mod": 0,
})
rf_high_payload = RFAnalogPayload({
    "vco_cap_coarse": 2**10 - 1,
    "vco_cap_med": 2**6 - 1,
    "vco_cap_mod": 2**8 - 1,
})
rf_mid_payload = RFAnalogPayload({
    "vco_cap_coarse": 760,
    "vco_cap_med": 2**6 // 2,
    "vco_cap_mod": 2**8 // 2,
})
rf_post_tia_payload = RFAnalogPayload({
    "mux_dbg_in": 0,
    "mux_dbg_out": 0b11,
    "en_tia_i": 0,
    "en_tia_q": 0,
    # Testing if tia_gain_ctrl_i is in vga_gain_ctrl_i.
    # "vga_gain_ctrl_q": 1 << 9,
    # "vga_gain_ctrl_i": 1 << 9,
    "vco_cap_coarse": 760,
    "vco_cap_med": 2**6 // 2,
    "vco_cap_mod": 2**8 // 2,
})

# Mux DBG In.
# Bit 0: After TIA I
# Bit 1: After TIA Q
# Bit 2: After BPF I
# Bit 3: After VGA I
# Bit 4: After BPF Q
# Bit 5: After VGA Q
rf_dbg_adc_payload = RFAnalogPayload({
    "mux_dbg_in": 0b001000,
    "mux_dbg_out": 0b00000,
    "en_bpf_i": 1,  # Does nothing.
    "en_bpf_q": 1,  # Does nothing.
    "en_vga_i": 0,
    "en_vga_q": 0,
    "bpf_q_clp0": 0b0000,  # Maximum corner.
    "bpf_q_clp1": 0b0000,  # Maximum corner.
    "bpf_q_clp2": 0b0000,  # Maximum corner.
    "bpf_q_chp0": 0b0000,  # Minimum corner.
    "bpf_q_chp1": 0b0000,  # Minimum corner.
    "bpf_q_chp2": 0b0000,  # Minimum corner.
    "bpf_q_chp3": 0b0000,  # Minimum corner.
    "bpf_q_chp4": 0b0000,  # Minimum corner.
    "bpf_q_chp5": 0b0000,  # Minimum corner.
})

rf_pkt_high = ScanChainPacket(Addr.RF_ADDR, rf_high_payload.create())
rf_pkt_low = ScanChainPacket(Addr.RF_ADDR, rf_low_payload.create())
rf_pkt_mid = ScanChainPacket(Addr.RF_ADDR, rf_mid_payload.create())
rf_post_tia_pkt = ScanChainPacket(Addr.RF_ADDR, rf_post_tia_payload.create())
rf_dbg_adc_pkt = ScanChainPacket(Addr.RF_ADDR, rf_dbg_adc_payload.create())

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Script for the scan chain client.")
    parser.add_argument("-p",
                        "--port",
                        default="/dev/tty.usbserial-210319B585BD1")
    args = parser.parse_args()

    serial_interface = SerialInterface(args.port)

    # Send packets.
    serial_interface.send_packet(reset_pkt)
    sleep(2)
    serial_interface.send_packet(clk_pkt)
    sleep(2)
    serial_interface.send_packet(sup_pkt)
    # sleep(2)
    # serial_interface.send_packet(rf_dbg_adc_pkt)

    # Sweep through the mux_dbg_out.
    # for i in range(0, 10):
    #     print(i)
    #     rf_post_tia_payload.set_reg("mux_dbg_out", 0b1 << i)
    #     pkt = ScanChainPacket(Addr.RF_ADDR, rf_post_tia_payload.create())
    #     serial_interface.send_packet(pkt)
    #     sleep(2)

    # Sweep through the mux_dbg_out.
    # for i in range(0, 5):
    #     print(i)
    #     osc_payload.set_reg("all_bits", 0b11 << i)
    #     pkt = ScanChainPacket(Addr.PWR_ADDR, osc_payload.create())
    #     serial_interface.send_packet(pkt)
    #     sleep(2)
