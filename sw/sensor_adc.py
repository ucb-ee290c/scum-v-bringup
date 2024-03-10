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
ADC_DATA = ADC_BASE + 0x04
ADC_TUNING0 = ADC_BASE + 0x08
ADC_CHOP_CLK_DIV_1 = ADC_BASE + 0x0C
ADC_CHOP_CLK_DIV_2 = ADC_BASE + 0x10
ADC_CHOP_CLK_EN = ADC_BASE + 0x14
ADC_DSP_CONTROL = ADC_BASE + 0x18

# Serial interface.
SERIAL_INTERFACE_BAUD_RATE = 2000000
SERIAL_INTERFACE_TIMEOUT = 2  # seconds

def get_status0_reg(host: TileLinkHost) -> (int, int):
    # status0<5:0> is COUNTER N
    # status0<11:6> is COUNTER P
    status0 = host.read_address(ADC_STATUS0, False)
    counter_n = status0 & 0b111111
    counter_p = (status0 >> 6) & 0b111111
    return counter_n, counter_p
    
def print_status0_reg(host: TileLinkHost) -> None:
    counter_n, counter_p = get_status0_reg(host)
    print(f"counter_n = {counter_n}")
    print(f"counter_p = {counter_p}")

def log_status0_reg(host: TileLinkHost) -> None:
    fname = "log_status0_reg.txt"
    log_length = 100
    cnarr = np.zeros(log_length)
    cparr = np.zeros(log_length)
    i = 0
    while i < log_length:
        counter_n, counter_p = get_status0_reg(host)
        print(f"counter_n = {counter_n}")
        print(f"counter_p = {counter_p}")
        cnarr[i] = counter_n
        cparr[i] = counter_p
        time.sleep(0.01)
        i += 1
    np.savetxt(fname, np.column_stack((cnarr, cparr)), fmt='%d')

def get_data(host: TileLinkHost) -> int:
    data = host.read_address(ADC_DATA, True)
    return data

def print_data(host: TileLinkHost) -> None:
    data = get_data(host)
    print(f"data = {data}")

def log_data(host: TileLinkHost) -> None:
    """Log the data from the ADC"""
    fname = "log_data.txt"
    log_length = 5000
    arr = np.zeros(log_length)
    i = 0
    last_counter_n = 0
    last_counter_p = 0
    rep_count = 0
    while i < log_length:
        (counter_n, counter_p) = get_status0_reg(host)
        if (counter_n == last_counter_n) or (counter_p == last_counter_p):
            rep_count += 1
            if rep_count > 100:
                print("repeated counter values, aborting")
                return
        else:
            rep_count = 0
        data = get_data(host)
        print(f"data = {data}")
        arr[i] = data
        time.sleep(0.01)
        i += 1
        last_counter_n = counter_n
        last_counter_p = counter_p
    np.savetxt(fname, arr, fmt='%d')
    

def config_sensor_adc(host: TileLinkHost) -> None:
    """Configure the Sensor ADC."""

    # Kick the IDAC for oscillator startup
    # print("Kicking the IDAC for oscillator startup")
    # host.write_address(ADC_TUNING0, 0b00000000, True)
    # host.write_address(ADC_TUNING0, 0b11111111, True)
    # host.write_address(ADC_TUNING0, 0b00000000, True)
    # host.write_address(ADC_TUNING0, 0b11111111, True)
    # host.write_address(ADC_TUNING0, 0b00000000, True)
    # host.write_address(ADC_TUNING0, 0b11111111, True)
    # host.write_address(ADC_TUNING0, 0b00000000, True)
    # host.write_address(ADC_TUNING0, 0b11111111, True)
    # host.write_address(ADC_TUNING0, 0b00000000, True)
    # host.write_address(ADC_TUNING0, 0b11111111, True)
    # host.write_address(ADC_TUNING0, 0b00000000, True)
    # host.write_address(ADC_TUNING0, 0b11111111, True)
    # host.write_address(ADC_TUNING0, 0b00000000, True)
    # host.write_address(ADC_TUNING0, 0b11111111, True)
    # host.write_address(ADC_TUNING0, 0b00000000, True)
    # host.write_address(ADC_TUNING0, 0b11111111, True)
    # host.write_address(ADC_TUNING0, 0b00000000, True)
    # host.write_address(ADC_TUNING0, 0b11111111, True)
    # host.write_address(ADC_TUNING0, 0b00000000, True)
    # host.write_address(ADC_TUNING0, 0b11111111, True)

    # Read the status0 registers to make sure the IDAC is running
    print("Verify status registers show oscillator activity")
    print_status0_reg(host)
    print_status0_reg(host)
    print_status0_reg(host)

    # sim based idac 
    #idac_val = 0b001010
    idac_val = 0b010000
    bias_p = 0
    bias_n = 0
    adc_tuning = bias_p << 7 | bias_n << 6 | idac_val
    host.write_address(ADC_TUNING0, adc_tuning, True)

    print("Verify status registers after new IDAC config")
    print_status0_reg(host)
    print_status0_reg(host)
    print_status0_reg(host)

    chop_clk_div_1 = 16
    chop_clk_div_2 = 16
    host.write_address(ADC_CHOP_CLK_DIV_1, chop_clk_div_1, True)
    host.write_address(ADC_CHOP_CLK_DIV_2, chop_clk_div_2, True)
    
    chop_clk_en_1 = 0
    chop_clk_en_2 = 0
    adc_chop_clk_en = chop_clk_en_2 << 1 | chop_clk_en_1
    host.write_address(ADC_CHOP_CLK_EN, adc_chop_clk_en, True)

    dsp_dechop_en = 0
    dsp_chop_clk_sel = 0
    dsp_dechop_clk_delay = 0
    adc_dsp_ctrl = dsp_dechop_clk_delay << 2 | dsp_chop_clk_sel << 1 | dsp_dechop_en
    host.write_address(ADC_DSP_CONTROL, adc_dsp_ctrl, True)

    return None

def run_sensor_adc_test(host: TileLinkHost) -> None:
    """Run the Sensor ADC test."""
    config_sensor_adc(host)
    # prompt - ok to proceed?
    rsp = input("Ready to proceed? (y/n): ")
    if rsp != "y":
        print("Aborting test")
        return None
    print("Starting test")
    print("Logging data")
    log_data(host)
    #log_status0_reg(host)


if __name__ == "__main__":
    '''
    Example usage:
    python sensor_adc.py -p /dev/tty.usbmodem103 -t template
    or, for Windows
    python sensor_adc.py -p COM4 -t power_test
    '''
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
    if(args.target == "template"):
        # Run the TileLink based tests
        run_sensor_adc_test(tl_host)
    else:
        # Flash the binary and trigger the software interrupt
        # i.e. bootload
        tl_host.flash_binary(binary_path)
        time.sleep(0.02)
        tl_host.trigger_software_interrupt() 
