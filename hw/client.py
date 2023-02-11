from enum import Enum
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

class SupplyPayload:
    '''
    First
    bgr_temp_ctrl[5]
    bgr_vref_ctrl[5]
    current_src_left_ctrl[5]
    current_src_right_ctrl[5]
    Last
    '''
    __slots__ = [
        'bgr_temp_ctrl', 'bgr_vref_ctrl', 'current_src_left_ctrl', 'current_src_right_ctrl'
    ]
    def to_bits(self) -> bytearray:
        supply_payload 

class OscillatorPayload:
    '''
    The oscillator scan chain payload is still not fully understood and does 
    not match the documentation
    # dbg_mux_sel_0, dbg_mux_sel_1
    # 0, 0 -> CPU_CLK
    # 0, 1 -> CPU_CLK
    # 1, 0 -> RTC_CLK
    # 1, 1 -> ADC_CLK
    '''
    class Clock(Enum):
        CPU_CLK = 0
        RTC_CLK = 1
        ADC_CLK = 2
    
    __slots__ = [
        'dbg_mux_sel_0', 'dbg_mux_sel_1', 'cpu_bypass', 'adc_bypass'
    ]
    def to_bits(self) -> int:
        osc_payload = (self.dbg_mux_sel_1 << 3) | (self.dbg_mux_sel_0 << 2) 
        osc_payload |=  (self.cpu_bypass << 5) | (self.adc_bypass << 4)
        return osc_payload


    def set_dbg_clock(self, clock: Clock):
        '''
        Set the mux to output the specified clock to the DBG_CLK_OUT pin
        '''
        if clock == self.Clock.CPU_CLK:
            self.dbg_mux_sel_0 = 0
            self.dbg_mux_sel_1 = 0
        elif clock == self.Clock.RTC_CLK:
            self.dbg_mux_sel_0 = 1
            self.dbg_mux_sel_1 = 0
        elif clock == self.Clock.ADC_CLK:
            self.dbg_mux_sel_0 = 1
            self.dbg_mux_sel_1 = 1
        else:
            raise ValueError('Invalid clock value')

class RFAnalogPayload:
    '''

    Register Name	Width	Bit
First
    tuning_trim_g0	8	8
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
Last
    '''
    __slots__ = [
        'tuning_trim_g0', 'vga_gain_ctrl_q', 'vga_gain_ctrl_i', 'current_dac_vga_i', 'current_dac_vga_q', 
        'bpf_i_chp0', 'bpf_i_chp1', 'bpf_i_chp2', 'bpf_i_chp3', 'bpf_i_chp4', 'bpf_i_chp5', 'bpf_i_clp0',
        'bpf_i_clp1', 'bpf_i_clp2', 'bpf_q_chp0', 'bpf_q_chp1', 'bpf_q_chp2', 'bpf_q_chp3', 'bpf_q_chp4',
        'bpf_q_chp5', 'bpf_q_clp0', 'bpf_q_clp1', 'bpf_q_clp2', 'vco_cap_coarse', 'vco_cap_med', 'vco_cap_mod',
        'vco_freq_reset', 'en_lna', 'en_mix_i', 'en_mix_q', 'en_tia_i', 'en_tia_q', 'en_buf_i', 'en_buf_q',
        'en_vga_i', 'en_vga_q', 'en_bpf_i', 'en_bpf_q', 'en_vco_lo', 'mux_dbg_in', 'mux_dbg_out'
    ]


s = serial.Serial('COM8', 115200)
def pkt_send(pkt:ScanChainPacket)->bool:
    pkt_bytes = pkt.to_bits()
    print(f"[TX] {str(pkt_bytes)}")
    s.write(pkt_bytes)
    resp = s.read(1)
    print(f"[RX] {str(resp)}")


OSC_ADDR = 1
RF_ADDR = 2
PWR_ADDR = 3

# Prepare a scan chain reset packet
reset_pkt = ScanChainPacket()
reset_pkt.reset = 1
reset_pkt.addr = 0      # Probably not needed
reset_pkt.payload = 0

# Prepare a packet to configure the oscillator/clocks subsystem
clk_pkt = ScanChainPacket()
clk_pkt.addr = OSC_ADDR
clk_pkt.reset = 0

payload = OscillatorPayload()
payload.set_dbg_clock(payload.Clock.CPU_CLK)
payload.adc_bypass = 0 
payload.cpu_bypass = 1
clk_pkt.payload = payload.to_bits()


#pkt_send(reset_pkt)
#sleep(2)
pkt_send(clk_pkt)
#sleep(5)
#pkt_send(clk_pkt)

# for i in range(54):
#     pkt = ScanChainPacket()
#     pkt.addr = 1
#     pkt.reset = 0
#     pkt.payload = 1<<i
#     pkt_send(pkt)
#     print(i)
#     sleep(2)

s.close()
