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

# UART initialization constants (matching C firmware defaults)
UART_BAUDRATE_DEFAULT = 115200
UART_MODE_RX = 0x01
UART_MODE_TX = 0x02  
UART_MODE_TX_RX = 0x03
UART_STOPBITS_DEFAULT = 0
SYS_CLK_FREQ_DEFAULT = 1000000


def isWindows() -> bool:
    """Returns whether running on Windows."""
    return os.name == "nt"


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


class TileLinkHost:
    """Interface to the TileLink bus."""
    def __init__(self, serial: serial.Serial) -> None:
        self.serial = serial

    def _read_exactly(self, num_bytes: int) -> bytes:
        """Reads exactly num_bytes or returns fewer if timeout occurs."""
        buffer = bytearray()
        while len(buffer) < num_bytes:
            chunk = self.serial.read(num_bytes - len(buffer))
            if not chunk:
                break
            buffer.extend(chunk)
        return bytes(buffer)

    def read_address(self, address: int, verbose: bool = True) -> int:
        """Reads the data at the given address."""
        # Pack opcode and other fields into a single byte as the firmware expects
        opcode_packed = TL_OPCODE_A_GET & 0b111
        tl_packet = struct.pack("<BBBBLQ", TL_CHANID_CH_A, opcode_packed, 2, 0b11111111, address, 0x00)
        
        # Add STL prefix before the TileLink packet
        stl_prefix = b"stl+"
        full_command = stl_prefix + tl_packet
        
        # if verbose:
        #     print(f"[TL Get] <address: {address:08X}, size: 4>")
        #     print_tilelink_packet(tl_packet, "TX")
        #     print(f"[STL Command] Full command: {' '.join([f'{b:02X}' for b in full_command])}")
        self.serial.write(full_command)

        buffer = self._read_exactly(16)
        # print_tilelink_packet(buffer, "RX")
        
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

    def write_address(self,
                      address: int,
                      data: int,
                      verbose: bool = True) -> None:
        """Writes the data to the given address."""
        # Pack opcode and other fields into a single byte as the firmware expects
        opcode_packed = TL_OPCODE_A_PUTFULLDATA & 0b111
        tl_packet = struct.pack("<BBBBLQ", TL_CHANID_CH_A, opcode_packed, 2, 0b11111111, address, data)
        
        # Add STL prefix before the TileLink packet
        stl_prefix = b"stl+"
        full_command = stl_prefix + tl_packet
        
        # if verbose:
        #     print(f"[TL PutFullData] <address: 0x{address:08X}, size: 4, "
        #           f"data: 0x{data:016X}>")
        #     print_tilelink_packet(tl_packet, "TX")
        #     print(f"[STL Command] Full command: {' '.join([f'{b:02X}' for b in full_command])}")
        self.serial.write(full_command)

        buffer = self._read_exactly(16)
        # print_tilelink_packet(buffer, "RX")
        
        # Unpack the response, decoding the packed opcode byte
        chanid, opcode_packed, size, _, _, _ = struct.unpack(
            "<BBBBLQ", buffer)
        opcode = opcode_packed & 0b111
        
        if opcode == TL_OPCODE_D_ACCESSACK:
            if verbose:
                print("[TL AccessAck]")
            return
        print("[TL PutFullData] <ERROR!>")

    def flash_binary(self, binary_path: str, batch_size: int = 256) -> None:
        """Flashes the given binary to the chip.

        Uses batched writes and a single bulk read of acks per batch to reduce
        Python/pyserial overhead substantially.
        """
        with open(binary_path, "rb") as f:
            binary = f.read()

        binary_size = len(binary)
        print(f"Binary size: {binary_size} bytes")
        if binary_size % 4 != 0:
            raise ValueError("Binary size must be a multiple of 4.")

        num_words = binary_size // 4
        words = struct.unpack("<" + "L" * num_words, binary)

        # Clear any stale data
        try:
            self.serial.reset_input_buffer()
        except Exception:
            pass

        last_reported_percent = -1
        for base in range(0, num_words, batch_size):
            count = min(batch_size, num_words - base)

            # Build one large buffer with many back-to-back packets
            send_buffer = bytearray()
            for i in range(count):
                address = DTIM_BASE + (base + i) * 4
                data_word = words[base + i]
                # Prefix per packet and then TL packet
                send_buffer.extend(b"stl+")
                send_buffer.extend(struct.pack(
                    "<BBBBLQ",
                    TL_CHANID_CH_A,
                    TL_OPCODE_A_PUTFULLDATA & 0b111,
                    2,
                    0b11111111,
                    address,
                    data_word,
                ))
            # Single write syscall
            self.serial.write(send_buffer)

            # Bulk read of acks (16 bytes per response)
            expected = 16 * count
            received = self._read_exactly(expected)
            if len(received) != expected:
                print(f"ERROR: Expected {expected} bytes, received {len(received)}")
                exit()
                

            # Throttled progress: update when percentage changes
            percent = int(((base + count) / num_words) * 100)
            if percent != last_reported_percent:
                print(f"{percent}%\t{base + count} / {num_words}")
                last_reported_percent = percent

        time.sleep(0.01)
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

    def read_baseband_registers(self) -> None:
        """Reads baseband registers."""
        for address in range(BASEBAND_BASE, BASEBAND_BASE + 0x70, 4):
            self.read_address(address)

    def uart_transmit(self, data: bytes) -> None:
        """Transmit a bytestream over UART like HAL_UART_transmit.

        Busy-waits on TXDATA.FULL and writes one byte at a time to TXDATA.
        """
        UART_TXDATA_OFFSET = 0x00
        UART_TXDATA_FULL_MSK = 0x1 << 31

        for byte in data:
            while self.read_address(UART_BASE + UART_TXDATA_OFFSET, verbose=False) & UART_TXDATA_FULL_MSK:
                pass
            self.write_address(UART_BASE + UART_TXDATA_OFFSET, byte & 0xFF, verbose=False)

    def trigger_software_interrupt(self) -> None:
        """Triggers a software interrupt."""
        self.read_address(CLINT_BASE)
        self.write_address(CLINT_BASE, 1)
        time.sleep(1)
        self.read_address(CLINT_BASE)

    def uart_init(self, baudrate: int = UART_BAUDRATE_DEFAULT, mode: int = UART_MODE_TX_RX, stopbits: int = UART_STOPBITS_DEFAULT, sys_clk_freq: int = SYS_CLK_FREQ_DEFAULT) -> None:
        """Initializes UART with specified parameters.
        
        This function replicates the behavior of HAL_UART_init() from the C firmware.
        
        Args:
            baudrate: UART baud rate (default: 921600)
            mode: UART mode - 0x01=RX, 0x02=TX, 0x03=TX_RX (default: 0x03)
            stopbits: Stop bits configuration (default: 0)
            sys_clk_freq: System clock frequency (default: 200000000)
            
        Example:
            # Initialize with defaults (matches C firmware)
            tl_host.uart_init()
            
            # Initialize with custom baud rate
            tl_host.uart_init(baudrate=115200)
        """
        # Register offsets from UART_TypeDef structure
        UART_TXCTRL_OFFSET = 0x08
        UART_RXCTRL_OFFSET = 0x0C
        UART_DIV_OFFSET = 0x18
        
        # Bit field masks and positions
        UART_RXCTRL_RXEN_MSK = 0x1
        UART_TXCTRL_TXEN_MSK = 0x1
        UART_TXCTRL_NSTOP_MSK = 0x2
        
        # Mode flags
        UART_MODE_RX = 0x01
        UART_MODE_TX = 0x02
        
        # Clear RX and TX enable bits
        rxctrl = self.read_address(UART_BASE + UART_RXCTRL_OFFSET, verbose=False)
        txctrl = self.read_address(UART_BASE + UART_TXCTRL_OFFSET, verbose=False)
        
        # Clear enable bits
        rxctrl &= ~UART_RXCTRL_RXEN_MSK
        txctrl &= ~UART_TXCTRL_TXEN_MSK
        
        self.write_address(UART_BASE + UART_RXCTRL_OFFSET, rxctrl, verbose=False)
        self.write_address(UART_BASE + UART_TXCTRL_OFFSET, txctrl, verbose=False)
        
        # Set RX enable if mode includes RX
        if mode & UART_MODE_RX:
            rxctrl |= UART_RXCTRL_RXEN_MSK
            self.write_address(UART_BASE + UART_RXCTRL_OFFSET, rxctrl, verbose=False)
        
        # Set TX enable if mode includes TX  
        if mode & UART_MODE_TX:
            txctrl |= UART_TXCTRL_TXEN_MSK
            self.write_address(UART_BASE + UART_TXCTRL_OFFSET, txctrl, verbose=False)

    # ------------------------------
    # Word-aligned field RMW helpers
    # ------------------------------
    def write_field_word_aligned(self,
                                 word_addr: int,
                                 shift: int,
                                 width: int,
                                 value: int,
                                 verbose: bool = True) -> None:
        """Read-modify-write a 32-bit word-aligned register field.

        Args:
            word_addr: Absolute 32-bit-aligned address of the containing word.
            shift: Bit shift of the field inside the 32-bit word.
            width: Field width in bits (1..32).
            value: New value to program into the field.
            label: Optional label to include in logs.
            verbose: If True, print read and write words.
        """
        mask = ((1 << width) - 1) << shift
        sanitized = value & ((1 << width) - 1)
        current_word = self.read_address(word_addr, verbose=False) & 0xFFFFFFFF
        new_word = (current_word & ~mask) | (sanitized << shift)
        if verbose:
            print(f"RMW @0x{word_addr:08X}: read=0x{current_word:08X} -> write=0x{new_word:08X}")
        self.write_address(word_addr, new_word, verbose=False)

    def write_field_by_offset(self,
                              base_addr: int,
                              byte_offset: int,
                              bit_index: int,
                              width: int,
                              value: int,
                              verbose: bool = True) -> None:
        """RMW using a byte offset and bit index within that byte.

        Computes the containing 32-bit word and shifts accordingly.
        """
        word_addr = base_addr + (byte_offset & ~0x3)
        intra_byte = (byte_offset & 0x3) * 8
        shift = intra_byte + bit_index
        self.write_field_word_aligned(word_addr, shift, width, value, verbose=verbose)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Script for the TileLink host.")
    parser.add_argument("-p", "--port", default="COM6")
    parser.add_argument("-t", "--target", default="scumvtuning_test")
    parser.add_argument("--baud", type=int, default=SERIAL_INTERFACE_BAUD_RATE)
    parser.add_argument("--batch", type=int, default=1, help="Number of words per write batch during flashing")
    args = parser.parse_args()

    serial = serial.Serial(args.port,
                           baudrate=args.baud,
                           timeout=SERIAL_INTERFACE_TIMEOUT)
    if isWindows():
        # Increase Windows COM buffers if supported to better absorb batched traffic
        try:
            if hasattr(serial, "set_buffer_size"):
                serial.set_buffer_size(rx_size=1 << 20, tx_size=1 << 20)
        except Exception:
            pass
        binary_path = rf".\scum_firmware\build\{args.target}.bin"
    else:
        binary_path = f"./scum_firmware/build/{args.target}.bin"

    tl_host = TileLinkHost(serial)
    time.sleep(0.1)
    tl_host.flash_binary(binary_path, batch_size=args.batch)
    # time.sleep(0.02)
    # tl_host.trigger_software_interrupt()
