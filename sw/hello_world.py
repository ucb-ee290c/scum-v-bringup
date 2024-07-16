from tl_host import TileLinkHost
import argparse
import serial

# Serial interface.
SERIAL_INTERFACE_BAUD_RATE = 2000000
SERIAL_INTERFACE_TIMEOUT = 2  # seconds


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Script for the TileLink host.")
    parser.add_argument("-p", "--port", default="COM4")
    args = parser.parse_args()

    serial = serial.Serial(args.port,
                           baudrate=SERIAL_INTERFACE_BAUD_RATE,
                           timeout=SERIAL_INTERFACE_TIMEOUT)
 
    tl_host = TileLinkHost(serial)
    tl_host.read_uart_registers()
    tl_host.enable_uart_tx()
    tl_host.send_hello_world()
    tl_host.read_uart_registers()