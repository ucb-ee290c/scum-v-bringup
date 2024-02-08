import argparse
from abc import ABC, abstractmethod
from enum import Enum
from time import sleep

import serial

# Serial interface.
SERIAL_INTERFACE_BAUD_RATE = 115200

# Scan chain packet constants.
NUM_RESET_BITS = 1
NUM_PAYLOAD_BITS = 160
NUM_ADDRESS_BITS = 12


class Address(Enum):
    """Address of the scan chain domain (set value as the address)."""
    RESET_ADDRESS = 0
    OSCILLATOR_ADDRESS = 1
    RF_ADDRESS = 2
    SUPPLY_ADDRESS = 3
    RADAR_ADDRESS = 4
    SENSOR_ADC_ADDRESS = 5


class ScanChainPacket:
    """The format is {3'b0, reset, payload, address}, where reset is 1 bit,
    payload is 160 bits, and address is 12 bits.
    """
    def __init__(self,
                 address: Address,
                 payload: int,
                 reset: bool = False) -> None:
        # Check the type of address.
        self.address: int = address.value
        self.payload = payload
        self.reset = reset

    def to_bits(self) -> bytearray:
        bits = self.address | (self.payload << NUM_ADDRESS_BITS) | (
            self.reset << (NUM_ADDRESS_BITS + NUM_PAYLOAD_BITS))
        num_bytes = (NUM_RESET_BITS + NUM_ADDRESS_BITS + NUM_PAYLOAD_BITS +
                     7) // 8
        return bits.to_bytes(num_bytes, byteorder="big")


class ScanChainPayload(ABC):
    """Interface for scan chain payloads."""
    def __init__(self, payload: dict[str, int] = None) -> None:
        # Create a dictionary of register names to their values.
        self.register_values = {r: 0 for r, _ in self.registers}
        if payload is not None:
            for register_name, register_value in payload.items():
                self.set_register(register_name, register_value)

    @property
    @abstractmethod
    def registers(self) -> list[tuple[str, int]]:
        """Returns a list of tuples of register names and their widths in the
        order that they appear in the payload (first sent to last sent).

        Example:
            return [("first_register", 8), ("last_register", 8)]
        """

    def set_register(self, register_name: str, register_value: int) -> None:
        """Set the value of a register."""
        if register_name not in self.register_values:
            raise ValueError(f"Invalid register name: {register_name}.")
        self.register_values[register_name] = register_value

    def create(self) -> int:
        """Create the payload from the register values."""
        payload = 0
        # Iterate through registers from the LSB to the MSB.
        bit_position = 0
        for register_name, reg_size in self.registers[::-1]:
            register_value = self.register_values[register_name]
            payload |= register_value << bit_position
            bit_position += reg_size
        return payload


class OscillatorPayload(ScanChainPayload):
    """
    First
        adc_tune_out[16]
        adc_reset[1]
        dig_tune_out[16]
        dig_reset[1]
        clk_mux_sel[2]
    Last
    """
    @property
    def registers(self) -> list[tuple[str, int]]:
        """Returns a list of tuples of register names and their widths in the
        order that they appear in the payload (first sent to last sent).
        """
        return [
            ("analog_coarse_dac", 12),
            ("analog_fine_dac", 4),
            ("analog_reset", 1),
            ("dig_tune_unused", 10),
            ("dig_current_dac", 6),
            ("dig_reset", 1),
            ("clk_mux_sel_1", 1),
            ("clk_mux_sel_0", 1),
        ]


class RfAnalogPayload(ScanChainPayload):
    """
        Register Name       Width   Bit
    First
        vga_gain_ctrl_q     10      10
        vga_gain_ctrl_i     10      10
        current_dac_vga_i   6       6
        current_dac_vga_q   6       6
        bpf_i_chp0          4       4
        bpf_i_chp1          4       4
        bpf_i_chp2          4       4
        bpf_i_chp3          4       4
        bpf_i_chp4          4       4
        bpf_i_chp5          4       4
        bpf_i_clp0          4       4
        bpf_i_clp1          4       4
        bpf_i_clp2          4       4
        bpf_q_chp0          4       4
        bpf_q_chp1          4       4
        bpf_q_chp2          4       4
        bpf_q_chp3          4       4
        bpf_q_chp4          4       4
        bpf_q_chp5          4       4
        bpf_q_clp0          4       4
        bpf_q_clp1          4       4
        bpf_q_clp2          4       4
        vco_cap_coarse      10      10
        vco_cap_med         6       6
        vco_cap_mod         8       8
        vco_freq_reset      1       1
        en_mix_i            1       1
        en_mix_q            1       1
        en_tia_i            1       1
        en_tia_q            1       1
        en_buf_i            1       1
        en_buf_q            1       1
        en_vga_i            1       1
        en_vga_q            1       1
        en_bpf_i            1       1
        en_bpf_q            1       1
        en_vco_lo           1       1
        mux_dbg_in          10      10
        mux_dbg_out         10      10
    Last
    """
    @property
    def registers(self) -> list[tuple[str, int]]:
        """Returns a list of tuples of register names and their widths in the
        order that they appear in the payload (first sent to last sent).
        """
        return [
            ("vga_gain_ctrl_q", 10),
            ("vga_gain_ctrl_i", 10),
            ("current_dac_vga_i", 6),
            ("current_dac_vga_q", 6),
            ("bpf_i_chp0", 4),
            ("bpf_i_chp1", 4),
            ("bpf_i_chp2", 4),
            ("bpf_i_chp3", 4),
            ("bpf_i_chp4", 4),
            ("bpf_i_chp5", 4),
            ("bpf_i_clp0", 4),
            ("bpf_i_clp1", 4),
            ("bpf_i_clp2", 4),
            ("bpf_q_chp0", 4),
            ("bpf_q_chp1", 4),
            ("bpf_q_chp2", 4),
            ("bpf_q_chp3", 4),
            ("bpf_q_chp4", 4),
            ("bpf_q_chp5", 4),
            ("bpf_q_clp0", 4),
            ("bpf_q_clp1", 4),
            ("bpf_q_clp2", 4),
            ("vco_cap_coarse", 10),
            ("vco_cap_med", 6),
            ("vco_cap_mod", 8),
            ("vco_freq_reset", 1),
            ("en_mix_i", 1),
            ("en_mix_q", 1),
            ("en_tia_i", 1),
            ("en_tia_q", 1),
            ("en_buf_i", 1),
            ("en_buf_q", 1),
            ("en_vga_i", 1),
            ("en_vga_q", 1),
            ("en_bpf_i", 1),
            ("en_bpf_q", 1),
            ("en_vco_lo", 1),
            ("mux_dbg_in", 10),
            ("mux_dbg_out", 10),
        ]


class SupplyPayload(ScanChainPayload):
    """
    First
        bgr_temp_ctrl[5]
        bgr_vref_ctrl[5]
        current_src_left_ctrl[5]
        current_src_right_ctrl[5]
        clkOvrd[1]
    Last
    """
    @property
    def registers(self) -> list[tuple[str, int]]:
        """Returns a list of tuples of register names and their widths in the
        order that they appear in the payload (first sent to last sent).
        """
        return [
            ("bgr_temp_ctrl", 5),
            ("bgr_vref_ctrl", 5),
            ("current_src_left_ctrl", 5),
            ("current_src_right_ctrl", 5),
            ("clkOvrd", 1),
        ]


class RadarPayload(ScanChainPayload):
    """
    First
        rampGenerator_clk_MuxSel[1]
        rampGenerator_enable[1]
        rampGenerator_frequencyStepStart[8]
        rampGenerator_numFrequencySteps[8]
        rampGenerator_numCyclesPerFrequency[24]
        rampGenerator_numIdleCycles[32]
        rampGenerator_rst[1]
        vco_capTuning[5]
        vco_enable[1]
        vco_divEnable[1]
        pa_enable[1]
        pa_bypass[1]
    Last
    """
    @property
    def registers(self) -> list[tuple[str, int]]:
        """Returns a list of tuples of register names and their widths in the
        order that they appear in the payload (first sent to last sent).
        """
        return [
            ("rampGenerator_clk_MuxSel", 1),
            ("rampGenerator_enable", 1),
            ("rampGenerator_frequencyStepStart", 8),
            ("rampGenerator_numFrequencySteps", 8),
            ("rampGenerator_numCyclesPerFrequency", 24),
            ("rampGenerator_numIdleCycles", 32),
            ("rampGenerator_rst", 1),
            ("vco_capTuning", 5),
            ("vco_enable", 1),
            ("vco_divEnable", 1),
            ("pa_enable", 1),
            ("pa_bypass", 1),
        ]


class SensorAdcPayload(ScanChainPayload):
    """
    First
        tuning[32]
    Last
    """
    @property
    def registers(self) -> list[tuple[str, int]]:
        """Returns a list of tuples of register names and their widths in the
        order that they appear in the payload (first sent to last sent).
        """
        return [
            ("tuning", 32),
        ]


class SerialInterface:
    """Serial interface to the FPGA."""
    def __init__(self, port: str) -> None:
        self.serial = serial.Serial(args.port,
                                    baudrate=SERIAL_INTERFACE_BAUD_RATE)

    def send_packet(self, packet: ScanChainPacket) -> None:
        """Send a packet over the serial interface."""
        packet_bytes = packet.to_bits()
        print(f"[TX] {packet_bytes}")
        self.serial.write(packet_bytes)
        response = self.serial.read(1)
        print(f"[RX] {response}")


# Scan chain reset packet.
reset_packet = ScanChainPacket(Address.RESET_ADDRESS, payload=0, reset=True)

# Scan chain oscillator packet.
oscillator_payload = OscillatorPayload({
    "analog_coarse_dac": 0b001001010000,
    "analog_fine_dac": 0b1000,
    "dig_current_dac": 0b000000,
    "clk_mux_sel_1": 0,
    "clk_mux_sel_0": 0,
})
oscillator_packet = ScanChainPacket(Address.OSCILLATOR_ADDRESS,
                                    oscillator_payload.create())

# Scan chain supply packet.
supply_payload = SupplyPayload({
    "bgr_vref_ctrl": 0b00011,
})
supply_packet = ScanChainPacket(Address.SUPPLY_ADDRESS,
                                supply_payload.create())

# Scan chain RF packet.
rf_high_payload_reset = RfAnalogPayload({
    "vco_cap_coarse": 0,  # 10 bits
    "vco_cap_med": 0,  # 6 bits
    "vco_cap_mod": 0,  # 8 bits
    "en_vco_lo": 1,
    "vco_freq_reset": 1
})

# Scan chain RF packet.
rf_high_payload = RfAnalogPayload({
    "vco_cap_coarse": 0,  # 10 bits
    "vco_cap_med": 0,  # 6 bits
    "vco_cap_mod": 0,  # 8 bits
    "en_vco_lo": 0,
    "vco_freq_reset": 0
})

rf_low_payload = RfAnalogPayload({
    "vco_cap_coarse": 2**10 - 1,
    "vco_cap_med": 2**6 - 1,
    "vco_cap_mod": 2**8 - 1,
    "en_vco_lo": 0,
})
rf_post_tia_payload = RfAnalogPayload({
    "mux_dbg_in": 0,
    "mux_dbg_out": 0b11,
    "en_tia_i": 0,
    "en_tia_q": 0,
    "vco_cap_coarse": 760,
    "vco_cap_med": 2**6 // 2,
    "vco_cap_mod": 2**8 // 2,
    "en_vco_lo": 0,
})
# mux_dbg_in:
#   Bit 0: After TIA I
#   Bit 1: After TIA Q
#   Bit 2: After BPF I
#   Bit 3: After VGA I
#   Bit 4: After BPF Q
#   Bit 5: After VGA Q
rf_debug_adc_payload = RfAnalogPayload({
    "mux_dbg_in": 0b001000,
    "mux_dbg_out": 0b00000,
    "en_bpf_i": 1,
    "en_bpf_q": 1,
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
rf_high_packet = ScanChainPacket(Address.RF_ADDRESS, rf_high_payload.create())
rf_low_packet = ScanChainPacket(Address.RF_ADDRESS, rf_low_payload.create())
rf_post_tia_packet = ScanChainPacket(Address.RF_ADDRESS,
                                     rf_post_tia_payload.create())
rf_debug_adc_packet = ScanChainPacket(Address.RF_ADDRESS,
                                      rf_debug_adc_payload.create())
rf_high_packet_reset = ScanChainPacket(Address.RF_ADDRESS,
                                       rf_high_payload_reset.create())

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Script for the scan chain client.")
    parser.add_argument("-p",
                        "--port",
                        default="/dev/tty.usbserial-210319B585BD1")
    args = parser.parse_args()

    serial_interface = SerialInterface(args.port)

    # Send packets.
    serial_interface.send_packet(reset_packet)
    sleep(2)
    serial_interface.send_packet(oscillator_packet)
    sleep(2)
    serial_interface.send_packet(supply_packet)

    # input("Press Enter to enable LO at highest frequency")
    # serial_interface.send_packet(rf_high_packet_reset)

    # sleep(2)
    # rf_high_payload.set_register("vco_cap_coarse", 300)
    # pkt = ScanChainPacket(Address.RF_ADDRESS, rf_high_payload.create())
    # serial_interface.send_packet(pkt)

    # input("Press enter to begin sweep.")

    # for i in range(300, 1024, 50):
    #     for j in range(0, 64, 10):
    #         print(i)
    #         print(j)
    #         rf_high_payload.set_register("vco_cap_coarse", i)
    #         rf_high_payload.set_register("vco_cap_med", j)
    #         pkt = ScanChainPacket(Address.RF_ADDRESS, rf_high_payload.create())
    #         serial_interface.send_packet(pkt)
    #         input("Go")

    # input("Press Enter to set LO to lowest frequency.")
    # serial_interface.send_packet(rf_low_packet)

    # sleep(2)
    # serial_interface.send_packet(rf_debug_adc_packet)

    # # Sweep through mux_dbg_out for RF.
    # for i in range(10):
    #     print(i)
    #     rf_post_tia_payload.set_register("mux_dbg_out", 0b1 << i)
    #     pkt = ScanChainPacket(Address.RF_ADDRESS, rf_post_tia_payload.create())
    #     serial_interface.send_packet(pkt)
    #     sleep(2)
