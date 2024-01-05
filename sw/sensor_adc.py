import argparse
import os
import struct
import time

import serial

from tl_host import TileLinkHost
from tl_host import isWindows 

import numpy as np

ADC_BASE = 0xB000
ADC_STATUS0 = ADC_BASE + 0x00
ADC_DATA0 = ADC_BASE + 0x04
ADC_TUNING0 = ADC_BASE + 0x08

# Serial interface.
SERIAL_INTERFACE_BAUD_RATE = 2000000
SERIAL_INTERFACE_TIMEOUT = 2  # seconds

def get_status0(host: TileLinkHost) -> (int, int):
    # status0<5:0> is COUNTER N
    # status0<11:6> is COUNTER P
    status0 = host.read_address(ADC_STATUS0, True)
    counter_n = status0 & 0b111111
    counter_p = (status0 >> 6) & 0b111111
    return counter_n, counter_p
    
def print_status0(host: TileLinkHost) -> None:
    counter_n, counter_p = get_status0(host)
    print(f"counter_n = {counter_n}")
    print(f"counter_p = {counter_p}")

def log_status0(host: TileLinkHost) -> None:
    fname = "log_status0.txt"
    log_length = 10000
    cnarr = np.zeros(log_length)
    cparr = np.zeros(log_length)
    i = 0
    while i < log_length:
        counter_n, counter_p = get_status0(host)
        print(f"counter_n = {counter_n}")
        print(f"counter_p = {counter_p}")
        cnarr[i] = counter_n
        cparr[i] = counter_p
        time.sleep(0.01)
        i += 1
    np.savetxt(fname, np.column_stack((cnarr, cparr)), fmt='%d')
    

def config_sensor_adc(host: TileLinkHost) -> None:
    """Configure the Sensor ADC."""
    host.write_address(ADC_TUNING0, 0b00000000, True)
    host.write_address(ADC_TUNING0, 0b11111111, True)
    host.write_address(ADC_TUNING0, 0b00000000, True)
    host.write_address(ADC_TUNING0, 0b11111111, True)
    host.write_address(ADC_TUNING0, 0b00000000, True)
    host.write_address(ADC_TUNING0, 0b11111111, True)

    log_status0(host)

    return None

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
    config_sensor_adc(tl_host)