#!/usr/bin/env python3
"""
TileLink Host Simulator

Modified version of tl_host.py that can write UART byte streams to files
for RTL simulation testing instead of sending to actual serial port.

Usage:
    python tl_host_sim.py --generate-test-vectors
    python tl_host_sim.py --test-read 0x10020000
    python tl_host_sim.py --test-write 0x10020000 0x12345678
"""

import argparse
import os
import struct
import time
from typing import List, Optional

# Import constants from original tl_host.py
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
UART_BASE = 0x10020000
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


class SimulatedSerial:
    """Simulated serial interface that writes to files instead of actual serial port."""
    
    def __init__(self, output_file: str):
        self.output_file = output_file
        self.tx_data = []  # Store transmitted data
        self.rx_data = []  # Store expected response data
        
    def write(self, data: bytes) -> None:
        """Write data to the simulated serial port (store in tx_data)."""
        self.tx_data.extend(data)
        print(f"[SIM TX] {len(data)} bytes: {' '.join([f'{b:02X}' for b in data])}")
        
    def read(self, size: int) -> bytes:
        """Read data from simulated serial port (return mock response)."""
        # For simulation, we'll generate appropriate mock responses
        if size == 16:
            # Generate a mock TileLink response
            mock_response = self._generate_mock_response()
            print(f"[SIM RX] {len(mock_response)} bytes: {' '.join([f'{b:02X}' for b in mock_response])}")
            return mock_response
        return b'\x00' * size
    
    def _generate_mock_response(self) -> bytes:
        """Generate a mock TileLink response packet."""
        # Mock AccessAckData response for reads
        chanid = TL_CHANID_CH_D
        opcode_packed = TL_OPCODE_D_ACCESSACKDATA & 0b111
        size = 2
        denied = 0
        address = 0x10020000  # Mock address
        data = 0x0123456789ABCDEF  # Mock data
        
        return struct.pack("<BBBBLQ", chanid, opcode_packed, size, denied, address, data)
    
    def save_tx_stream(self) -> None:
        """Save transmitted data stream to file."""
        with open(self.output_file, 'wb') as f:
            f.write(bytes(self.tx_data))
        print(f"[SIM] Saved {len(self.tx_data)} TX bytes to {self.output_file}")


def print_tilelink_packet(buffer: bytes, direction: str = "RX") -> None:
    """Prints detailed information about a TileLink packet."""
    if len(buffer) != 16:
        print(f"[TL {direction} Packet] ERROR: Invalid packet size {len(buffer)} bytes")
        return
    
    # Unpack the packet using names that reflect the C-firmware's packing
    chanid, opcode_packed, size, union_field, address, data = struct.unpack("<BBBBLQ", buffer)
    
    # Print raw bytes
    hex_bytes = ' '.join([f'{b:02X}' for b in buffer])
    print(f"[TL {direction} Packet] Raw bytes: {hex_bytes}")
    
    # Decode the packed opcode byte from the C firmware
    opcode = opcode_packed & 0b111
    param = (opcode_packed >> 4) & 0b111
    corrupt = (opcode_packed >> 7) & 0b1

    # Print decoded fields
    print(f"[TL {direction} Packet] Decoded:")
    print(f"  Channel ID: {chanid}")
    print(f"  Opcode: {opcode} ({get_opcode_name(chanid, opcode)})")
    print(f"  Param: {param}")
    print(f"  Size: {size} (2^{size} = {2**size if size < 10 else 'invalid'} bytes)")
    
    # The 4th byte (union_field) means different things on different channels
    if chanid == TL_CHANID_CH_A:
        print(f"  Mask: 0b{union_field:08b}")
    elif chanid == TL_CHANID_CH_D:
        print(f"  Denied: {bool(union_field)}")

    print(f"  Corrupt: {bool(corrupt)}")
    print(f"  Address: 0x{address:08X}")
    print(f"  Data: 0x{data:016X}")


def get_opcode_name(chanid: int, opcode: int) -> str:
    """Returns the human-readable name for TileLink opcodes."""
    if chanid == TL_CHANID_CH_A:
        if opcode == TL_OPCODE_A_PUTFULLDATA:
            return "PutFullData"
        elif opcode == TL_OPCODE_A_GET:
            return "Get"
        else:
            return f"Unknown Ch A opcode {opcode}"
    elif chanid == TL_CHANID_CH_D:
        if opcode == TL_OPCODE_D_ACCESSACK:
            return "AccessAck"
        elif opcode == TL_OPCODE_D_ACCESSACKDATA:
            return "AccessAckData"
        else:
            return f"Unknown Ch D opcode {opcode}"
    else:
        return f"Unknown channel {chanid}"


class TileLinkHostSim:
    """TileLink Host Simulator for generating test vectors."""
    
    def __init__(self, output_file: str):
        self.serial = SimulatedSerial(output_file)
        
    def read_address(self, address: int, verbose: bool = True) -> int:
        """Simulate reading data at the given address."""
        # Pack opcode and other fields into a single byte as the firmware expects
        opcode_packed = TL_OPCODE_A_GET & 0b111
        
        # Add STL prefix before the TileLink packet
        stl_prefix = b"stl+"
        tl_packet = struct.pack("<BBBBLQ", TL_CHANID_CH_A, opcode_packed, 2, 0b11111111, address, 0x00)
        full_command = stl_prefix + tl_packet
        
        if verbose:
            print(f"[TL Get] <address: {address:08X}, size: 4>")
            print_tilelink_packet(tl_packet, "TX")
            print(f"[STL Command] Full command: {' '.join([f'{b:02X}' for b in full_command])}")
        
        self.serial.write(full_command)
        
        buffer = self.serial.read(16)
        if verbose:
            print_tilelink_packet(buffer, "RX")
        
        # Unpack the response, decoding the packed opcode byte
        chanid, opcode_packed, size, union_field, address, data = struct.unpack(
            "<BBBBLQ", buffer)
        opcode = opcode_packed & 0b111
        
        if opcode == TL_OPCODE_D_ACCESSACKDATA:
            if verbose:
                # The 4th byte is the 'denied' flag on a D channel response
                denied = bool(union_field)
                print(f"[TL AccessAckData] <size: 4, data: 0x{data:016X}, "
                      f"denied: {denied}>")
            return data
        print("[TL Get] <ERROR!>")
        return -1

    def write_address(self, address: int, data: int, verbose: bool = True) -> None:
        """Simulate writing data to the given address."""
        # Pack opcode and other fields into a single byte as the firmware expects
        opcode_packed = TL_OPCODE_A_PUTFULLDATA & 0b111
        
        # Add STL prefix before the TileLink packet
        stl_prefix = b"stl+"
        tl_packet = struct.pack("<BBBBLQ", TL_CHANID_CH_A, opcode_packed, 2, 0b11111111, address, data)
        full_command = stl_prefix + tl_packet
        
        if verbose:
            print(f"[TL PutFullData] <address: 0x{address:08X}, size: 4, "
                  f"data: 0x{data:016X}>")
            print_tilelink_packet(tl_packet, "TX")
            print(f"[STL Command] Full command: {' '.join([f'{b:02X}' for b in full_command])}")
        
        self.serial.write(full_command)
        
        buffer = self.serial.read(16)
        if verbose:
            print_tilelink_packet(buffer, "RX")
        
        # Unpack the response, decoding the packed opcode byte
        chanid, opcode_packed, size, _, _, _ = struct.unpack(
            "<BBBBLQ", buffer)
        opcode = opcode_packed & 0b111
        
        if opcode == TL_OPCODE_D_ACCESSACK:
            if verbose:
                print("[TL AccessAck]")
            return
        print("[TL PutFullData] <ERROR!>")
    
    def generate_test_sequence(self) -> None:
        """Generate a comprehensive test sequence."""
        print("[SIM] Generating comprehensive test sequence...")
        
        # Test 1: Read UART base register
        self.read_address(UART_BASE, verbose=True)
        
        # Test 2: Write to UART base
        self.write_address(UART_BASE, 0x12345678, verbose=True)
        
        # Test 3: Read from GPIO base
        self.read_address(GPIO_BASE, verbose=True)
        
        # Test 4: Write to GPIO base  
        self.write_address(GPIO_BASE, 0xABCDEF00, verbose=True)
        
        # Test 5: Read from DTIM base
        self.read_address(DTIM_BASE, verbose=True)
        
        print(f"[SIM] Test sequence complete. Generated {len(self.serial.tx_data)} bytes.")

    def save_test_vectors(self) -> None:
        """Save the test vectors to file."""
        self.serial.save_tx_stream()


def main():
    parser = argparse.ArgumentParser(description="TileLink Host Simulator for RTL testing")
    parser.add_argument("--output", "-o", default="tl_test_vectors.bin", 
                       help="Output file for UART byte stream")
    parser.add_argument("--generate-test-vectors", action="store_true",
                       help="Generate comprehensive test vector sequence")
    parser.add_argument("--test-read", type=lambda x: int(x, 0), 
                       help="Test single read from address (hex format: 0x12345678)")
    parser.add_argument("--test-write", nargs=2, metavar=('ADDR', 'DATA'),
                       type=lambda x: int(x, 0),
                       help="Test single write to address with data (hex format)")
    
    args = parser.parse_args()
    
    tl_sim = TileLinkHostSim(args.output)
    
    if args.generate_test_vectors:
        tl_sim.generate_test_sequence()
    elif args.test_read is not None:
        tl_sim.read_address(args.test_read)
    elif args.test_write is not None:
        address, data = args.test_write
        tl_sim.write_address(address, data)
    else:
        print("No action specified. Use --help for options.")
        return
    
    tl_sim.save_test_vectors()
    print(f"[SIM] Test vectors saved to {args.output}")


if __name__ == "__main__":
    main()