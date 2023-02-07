import serial
import ctypes
from time import sleep

class ScanChainPacket:
    __slots__ = [
        'addr', 'payload', 'reset'
    ]
    
    def to_bits(self) -> bytearray:
        addr_i = self.addr #int.from_bytes(self.addr, order='little')
        payload_i = self.payload #int.from_bytes(self.payload, byteorder='little')
        reset_i = self.reset#int.from_bytes(self.reset, byteorder='little')
        result_i = addr_i | payload_i << 12 | reset_i << (12 + 169)
        return result_i.to_bytes(23, byteorder='big')


s = serial.Serial('COM8', 115200)
def pkt_send(pkt:ScanChainPacket)->bool:
    pkt_bytes = pkt.to_bits()
    print(f"[TX] {str(pkt_bytes)}")
    s.write(pkt_bytes)
    resp = s.read(1)
    print(f"[RX] {str(resp)}")

reset_pkt = ScanChainPacket()
reset_pkt.reset = 1
reset_pkt.addr = 0 #probably not needed but yolo
reset_pkt.payload = 0


# osc_payload = 9480 << 37 #reset value idk
# osc_payload |= 0b10 << 3 #MUX_CLK_OUT := RTC clk? 
# osc_payload |= 0b1 << 6 #CPU clock := external
# osc_payload = 0xffff_ffff_ffff_ffff
osc_payload = 0b1100

clk_pkt = ScanChainPacket()
clk_pkt.addr = 1
clk_pkt.reset = 0
clk_pkt.payload = osc_payload #0b1111_1010_1010_1010#bytearray(b'\x41\xff')

# pkt_send(reset_pkt)
# sleep(2)
pkt_send(clk_pkt)

# for i in range(54):
#     pkt = ScanChainPacket()
#     pkt.addr = 1
#     pkt.reset = 0
#     pkt.payload = 1<<i
#     pkt_send(pkt)
#     print(i)
#     sleep(2)

s.close()
