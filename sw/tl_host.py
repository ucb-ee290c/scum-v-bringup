import argparse
import os
import struct
import time

import serial

# Memory map addresses.
DEBUG_CONTROLLER_BASE = 0x00000000
BOOT_SELECT_BASE = 0x00002000
ERROR_DEVICE_BASE = 0x00003000
BASEBAND_BASE = 0x00008000
BOOTROM_BASE = 0x00010000
TILE_RESET_CTRL_BASE = 0x00100000
CLINT_BASE = 0x02000000
PLIC_BASE = 0x0C000000
LBWIF_RAM_BASE = 0x10000000
UART_BASE = 0x54000000
GPIO_BASE = 0x10012000
QSPI_BASE = 0x10040000
FLASH_BASE = 0x20000000
DTIM_BASE = 0x80000000

# TileLink.
TL_CHANID_CH_A = 0
TL_CHANID_CH_D = 3
TL_OPCODE_A_PUTFULLDATA = 0
TL_OPCODE_A_GET = 4
TL_OPCODE_D_ACCESSACK = 0
TL_OPCODE_D_ACCESSACKDATA = 1

# Serial interface.
SERIAL_INTERFACE_BAUD_RATE = 2000000
SERIAL_INTERFACE_TIMEOUT = 2  # seconds


def isWindows() -> bool:
    """Returns whether running on Windows."""
    return os.name == "nt"


class TileLinkHost:
    """Interface to the TileLink bus."""
    def __init__(self, serial: serial.Serial) -> None:
        self.serial = serial

    def read_address(self, address: int, verbose: bool = True) -> int:
        """Reads the data at the given address."""
        buffer = struct.pack("<BBBBLL", TL_CHANID_CH_A, TL_OPCODE_A_GET, 2,
                             0b11111111, address, 0x00)
        if verbose:
            print(f"[TL Get] <address: {address:08X}, size: 4>")
        self.serial.write(buffer)

        buffer = self.serial.read(16)
        print(buffer)
        chanid, opcode, size, denied, address, data = struct.unpack(
            "<BBBBLQ", buffer)
        if opcode == TL_OPCODE_D_ACCESSACKDATA:
            if verbose:
                print(f"[TL AccessAckData] <size: 4, data: 0x{data:016X}, "
                      f"denied: {denied}>")
            return data
        print("[TL Get] <ERROR!>")
        return -1

    def write_address(self,
                      address: int,
                      data: int,
                      verbose: bool = True) -> None:
        """Writes the data to the given address."""
        buffer = struct.pack("<BBBBLL", TL_CHANID_CH_A,
                             TL_OPCODE_A_PUTFULLDATA, 2, 0b11111111, address,
                             data)
        if verbose:
            print(f"[TL PutFullData] <address: 0x{address:08X}, size: 4, "
                  f"data: 0x{data:016X}>")
        self.serial.write(buffer)

        buffer = self.serial.read(16)
        chanid, opcode, size, denied, address, data = struct.unpack(
            "<BBBBLQ", buffer)
        if opcode == TL_OPCODE_D_ACCESSACK:
            if verbose:
                print("[TL AccessAck]")
            return
        print("[TL PutFullData] <ERROR!>")

    def flash_binary(self, binary_path: str) -> None:
        """Flashes the given binary to the chip."""
        with open(binary_path, "rb") as f:
            binary = f.read()

        binary_size = len(binary)
        print(f"Binary size: {binary_size} bytes")
        if binary_size % 4 != 0:
            raise ValueError("Binary size must be a multiple of 4.")

        num_words = binary_size // 4
        words = struct.unpack("<" + "L" * num_words, binary)
        for address, instruction in enumerate(words):
            print(f"{(address / num_words) * 100:.2f}%\t"
                  f"{address} / {num_words}")
            self.write_address(DTIM_BASE + address * 4,
                               instruction,
                               verbose=False)

        time.sleep(0.1)
        self.write_address(CLINT_BASE, 1)

    def memory_scan(self) -> None:
        """Scans through memory addresses."""
        for address in range(0x80005000, 0x80100000, 4):
            if address % 0x100 == 0:
                print(f"Address: 0x{address:08X}")

            for data in (0xFFFFFFFF, 0x00000000):
                self.write_address(address, data, verbose=False)
                if self.read_address(address, verbose=False) != data:
                    raise ValueError(f"Incorrect memory readback at address "
                                     f"0x{address:008X}.")

    def read_uart_registers(self) -> None:
        """Reads UART registers."""
        for address in range(UART_BASE, UART_BASE + 0x1C, 4):
            self.read_address(address)

    def read_baseband_registers(self) -> None:
        """Reads baseband registers."""
        for address in range(BASEBAND_BASE, BASEBAND_BASE + 0x70, 4):
            self.read_address(address)

    def enable_uart_tx(self) -> None:
        """Enables UART TX."""
        self.write_address(UART_BASE + 0x08, 0x01)

    def send_uart_byte(self, data: bytes) -> None:
        """Sends a byte over UART."""
        self.write_address(UART_BASE, data)

    def send_uart_bytestream(self, data: bytes) -> None:
        """Sends a bytestream over UART."""
        for byte in data:
            while self.get_tx_fifo_depth() == 0:
                pass
            self.send_uart_byte(byte)

    def send_hello_world(self) -> None:
        """Sends 'Hello World' over UART."""
        self.send_uart_bytestream(b"Hello World!")

    def get_tx_fifo_depth(self) -> None:
        """Returns the TX FIFO depth."""
        tx_control = self.read_address(UART_BASE + 0x0C)
        return tx_control & 0x7

    def trigger_software_interrupt(self) -> None:
        """Triggers a software interrupt."""
        self.read_address(CLINT_BASE)
        self.write_address(CLINT_BASE, 1)
        time.sleep(1)
        self.read_address(CLINT_BASE)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Script for the TileLink host.")
    parser.add_argument("-p", "--port", default="/dev/tty.usbmodem103")
    parser.add_argument("-t", "--target", default="template")
    args = parser.parse_args()

    serial = serial.Serial(args.port,
                           baudrate=SERIAL_INTERFACE_BAUD_RATE,
                           timeout=SERIAL_INTERFACE_TIMEOUT)
    if isWindows():
        binary_path = rf".\scum_firmware\build\{args.target}.bin"
    else:
        binary_path = f"./scum_firmware/build/{args.target}.bin"

    tl_host = TileLinkHost(serial)
    tl_host.read_uart_registers()
    tl_host.enable_uart_tx()
    # tl_host.send_hello_world()
    tl_host.read_uart_registers()
    time.sleep(0.1)
    tl_host.flash_binary(binary_path)
    time.sleep(0.02)
    tl_host.trigger_software_interrupt()
