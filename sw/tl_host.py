import struct
import time

import serial


BINARY_LOCATION = r".\scum_firmware\build\firmware.bin"


DEBUG_CONTROLLER_BASE   =0x00000000
BOOT_SELECT_BASE        =0x00002000
ERROR_DEVICE_BASE       =0x00003000
BOOTROM_BASE            =0x00010000
TILE_RESET_SETTER       =0x00100000
CLINT_BASE              =0x02000000
PLIC_BASE               =0x0C000000
LBWIF_RAM_BASE          =0x10000000
UART_BASE               =0x1001a000
GPIO_BASE               =0x10012000
QSPI_BASE               =0x10040000
FLASH_BASE              =0x20000000
DTIM_BASE               =0x80000000



TL_CHANID_CH_A = 0
TL_CHANID_CH_D = 3
TL_OPCODE_A_PUTFULLDATA = 0
TL_OPCODE_A_PUTPARTIALDATA = 1
TL_OPCODE_A_GET = 4
TL_OPCODE_D_ACCESSACK = 0
TL_OPCODE_D_ACCESSACKDATA = 1



# prog_hex = [hex(w) for w in prog_int]

# print(prog_hex)

ser = serial.Serial("COM6", baudrate=2000000, timeout=5.0)


def TL_Get(addr, verbal=True):
    buffer = struct.pack("<BBBBLQ", TL_CHANID_CH_A, TL_OPCODE_A_GET, 3, 0b11111111, addr, 0x00)
    ser.write(buffer)
    if verbal:
        print("[TL Get] <address: {0:08X}, size: {1}>".format(addr, 4))
    # 1s timeout
    buffer = ser.read(16)
    chanid, opcode, size, denied, addr, data = struct.unpack("<BBBBLQ", buffer)
    if opcode == TL_OPCODE_D_ACCESSACKDATA:
        if verbal:
            print("[TL AccessAckData] <size: {0}, data: 0x{1:016X}, denied: {2}>".format(4, data, denied))
        return data
    print("<ERROR!>")
    return -1


def TL_PutFullData(addr, data, verbal=True):
    buffer = struct.pack("<BBBBLQ", TL_CHANID_CH_A, TL_OPCODE_A_PUTPARTIALDATA, 3, 0b11111111, addr, data)
    ser.write(buffer)
    if verbal:
        print("[TL PutFullData] <address: 0x{0:08X}, size: {1}, data: 0x{2:016X}>".format(addr, 8, data))

    buffer = ser.read(16)
    chanid, opcode, size, denied, addr, data = struct.unpack("<BBBBLQ", buffer)
    if opcode == TL_OPCODE_D_ACCESSACK:
        if verbal:
            print("[TL AccessAck]".format())
        return
    print("<ERROR!>")
    return -1


def flash_prog():
    
    with open(BINARY_LOCATION, "rb") as f:
        prog_bin = f.read()

    size = len(prog_bin)
    n_words = size // 4

    print("program_size:", size, "bytes")

    prog_int = struct.unpack("<"+"L"*n_words, prog_bin)

    # TileLink forces us to be double word aligned,
    # so we need to write two instructions at once
    ctr = 0
    prev_inst = 0
    aligned_addr = 0
    for addr, inst in enumerate(prog_int):
        if ctr == 0:
            ctr = 1
            prev_inst = inst
            aligned_addr = addr
            continue
        else:
            ctr = 0
            inst = (inst << 32) | (prev_inst)
            inst_addr = 0x80000000+aligned_addr*4
            print("{:.2f}%\t {} / {} - {:02X}".format((addr / n_words) * 100., addr, n_words, inst_addr))
            TL_PutFullData(inst_addr, inst, verbal=False)

    time.sleep(0.1)

    TL_PutFullData(CLINT_BASE, 1)
    

def memory_scan():
    for addr in range(0x80005000, 0x80100000, 4):
        
        if not addr % 0x100:
            print("ADDRESS:", hex(addr))
        
        TL_PutFullData(addr, 0xFFFFFFFF, verbal=False)
        assert TL_Get(addr, verbal=False) == 0xFFFFFFFF
        TL_PutFullData(addr, 0x00000000, verbal=False)
        assert TL_Get(addr, verbal=False) == 0x00000000

def getUARTregs():
    for addr in range(UART_BASE, UART_BASE+0x1C, 4):
        TL_Get(addr)

def getBasebandregs():
    for addr in range(0x8000, 0x8000+0x70, 4):
        TL_Get(addr)

def enableUARTTx():
    TL_PutFullData(UART_BASE+0x08, 0x01)
def sendUARTByte(data):
    TL_PutFullData(UART_BASE, data)
def sendUARTByteStream(data):
    for byte in data:
        while getTXFIFODepth() == 0:
            pass
        sendUARTByte(byte)
def sendHelloWorld():
    sendUARTByteStream(b"Hello World!")
def getTXCTRL():
    TL_Get(UART_BASE+0x0C)

def getTXFIFODepth():
    tx_ctrl = TL_Get(UART_BASE+0x0C)
    return ((tx_ctrl & 0x7) << 16) >> 16


def trigSoftwareInterrupt():
    TL_Get(CLINT_BASE)
    TL_PutFullData(CLINT_BASE, 1)
    time.sleep(1)
    TL_Get(CLINT_BASE)
    
def main():

    #getBasebandregs()
    #getUARTregs()
    #enableUARTTx()
    #sendHelloWorld()
    #getUARTregs()
    #TL_Get(0x4000)
    #TL_Get(0x8000A000)
    TL_PutFullData(0x8000A000, 0x0)
    TL_PutFullData(0x8000B000, 0x0)
    flash_prog()
    time.sleep(0.5) 
    
    #TL_PutFullData(CLINT_BASE, 1)
    #time.sleep(1)
    TL_Get(0x8020)
    TL_Get(0x8000A000)
    TL_Get(0x8000B000)
    
    #trigSoftwareInterrupt()

    #time.sleep(3)

    #trigSoftwareInterrupt()


    # while True:
    #     TL_Get(0x8020)
    #     time.sleep(1)
    
    #memory_scan()
    #getUARTregs()

    #TL_Get(0x8000B000)



main()
