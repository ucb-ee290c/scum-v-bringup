
#include "scum_system.h"
#include "scum_hal.h"

volatile enum DEBUG_STATUS debug_status = NONE;

typedef struct plic_context_control
{
  uint32_t priority_threshold;
  uint32_t claim_complete;
} plic_context_control_t __attribute__ ((aligned (0x1000)));


uint32_t *const plic_enables      =               (uint32_t* const) 0xc002000; // Context [0..15871], sources bitmap registers [0..31]
uint32_t *const plic_priorities   =               (uint32_t* const) 0xc000000; // priorities [0..1023]
plic_context_control_t *const plic_ctx_controls = (plic_context_control_t* const) 0xc200000; // Priority threshold & claim / complete for context [0..15871]

void plic_set_bit(uint32_t* const target, uint32_t index)
{
  uint32_t reg_index = index >> 5;
  uint32_t bit_index = index & 0x1F;
  *target |= (1 << bit_index);
}

void plic_enable_for_hart(uint32_t hart_id, uint32_t irq_id) {
  uint32_t* base = plic_enables + 32 * hart_id;
  plic_set_bit(base, irq_id);
}

void plic_set_priority(uint32_t irq_id, uint32_t priority) {
  plic_priorities[irq_id] = priority;
}

uint32_t plic_claim_irq(uint32_t hart_id) {
  return plic_ctx_controls[hart_id].claim_complete;
}

void plic_complete_irq(uint32_t hart_id, uint32_t irq_id){
  plic_ctx_controls[hart_id].claim_complete = irq_id;
}


inline void print_fcsr()
{
  uint64_t fcsr_val = 0;
  char str[128];
  asm volatile("csrr %0, fcsr" : "=r"(fcsr_val));
  sprintf(str, "fcsr = %lx\r\n", fcsr_val); 
  HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
  asm volatile("csrr %0, misa" : "=r"(fcsr_val));
  sprintf(str, "ISA extension = %lx\r\n", fcsr_val); 
  HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
  asm volatile("csrr %0, marchid" : "=r"(fcsr_val));
  sprintf(str, "Architecture ID = %lx\r\n", fcsr_val); 
  HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
}


void enable_fpu(void) {
    uint64_t mstatus;
    asm volatile("csrr %0, mstatus" : "=r"(mstatus));
    mstatus |= (1 << 13); // Set the FS field of mstatus register to Initial (0b01)
    asm volatile("csrw mstatus, %0" ::"r"(mstatus));
    // Clear the fcsr register
    asm volatile("csrci fcsr, %0" :: "i"(0));
    // Zero out all FPU registers
    asm volatile("fmv.w.x ft0, x0");
    asm volatile("fmv.w.x ft1, x0");
    asm volatile("fmv.w.x ft2, x0");
    asm volatile("fmv.w.x ft3, x0");
    asm volatile("fmv.w.x ft4, x0");
    asm volatile("fmv.w.x ft5, x0");
    asm volatile("fmv.w.x ft6, x0");
    asm volatile("fmv.w.x ft7, x0");
    asm volatile("fmv.w.x fs0, x0");
    asm volatile("fmv.w.x fs1, x0");
    asm volatile("fmv.w.x fa0, x0");
    asm volatile("fmv.w.x fa1, x0");
    asm volatile("fmv.w.x fa2, x0");
    asm volatile("fmv.w.x fa3, x0");
    asm volatile("fmv.w.x fa4, x0");
    asm volatile("fmv.w.x fa5, x0");
    asm volatile("fmv.w.x fa6, x0");
    asm volatile("fmv.w.x fa7, x0");
    asm volatile("fmv.w.x fs2, x0");
    asm volatile("fmv.w.x fs3, x0");
    asm volatile("fmv.w.x fs4, x0");
    asm volatile("fmv.w.x fs5, x0");
    asm volatile("fmv.w.x fs6, x0");
    asm volatile("fmv.w.x fs7, x0");
    asm volatile("fmv.w.x fs8, x0");
    asm volatile("fmv.w.x fs9, x0");
    asm volatile("fmv.w.x fs10, x0");
    asm volatile("fmv.w.x fs11, x0");
    asm volatile("fmv.w.x ft8, x0");
    asm volatile("fmv.w.x ft9, x0");
    asm volatile("fmv.w.x ft10, x0");
    asm volatile("fmv.w.x ft11, x0");
}


void system_init(void) {
  // Store the word 0x1 at address 0x8020   
  asm("li t1, 0x8020");
  asm("li t0, 0x1");
  asm("sw t0, 0(t1)");
  //enable_fpu();

  plic_set_bit(plic_enables, 5);
  plic_set_bit(plic_enables, 6);
  plic_set_bit(plic_enables, 7);
  plic_set_bit(plic_enables, 8);
  plic_set_bit(plic_enables, 9);
}


/**/
void UserSoftware_IRQn_Handler() {}
void SupervisorSoftware_IRQn_Handler() {}
void HypervisorSoftware_IRQn_Handler() {}
void MachineSoftware_IRQn_Handler() {}
void UserTimer_IRQn_Handler() {}
void SupervisorTimer_IRQn_Handler() {}
void HypervisorTimer_IRQn_Handler() {}
void MachineTimer_IRQn_Handler() {}
void UserExternal_IRQn_Handler() {}
void SupervisorExternal_IRQn_Handler() {}
void HypervisorExternal_IRQn_Handler() {}

void MachineExternal_IRQn_Handler() {
  uint32_t m_cause;
  char str[16];
  sprintf(str, "interrupt: %x\n", m_cause);
  //HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
}


void trap_handler(void) {  
  uint32_t m_cause;
  asm volatile("csrr %0, mcause" : "=r"(m_cause));

  char str[128];
  sprintf(str, "\nintr mcause: %x\n", m_cause);
  HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);

  uint8_t is_interrupt = READ_BITS(m_cause, 0x80000000) ? 1 : 0;

  if (is_interrupt) {
    if (m_cause == 0x80000003) {
      // machine software interrupt
      CLINT->MSIP = 0;
    }
    if (m_cause == 0x80000007) {
      // machine timer interrupt
      CLINT->MTIMECMP = 0xFFFFFFFFFFFFFFFF;
    }
    if (m_cause == 0x8000000B) {
      // machine external interrupt
      
    }
    
    uint32_t irqSource = plic_claim_irq(0);
  
    sprintf(str, "src: %d\n", irqSource);
    HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
  
    if (irqSource == TX_FINISH) {
      sprintf(str, "TX Finished\n");
      debug_status = DEBUG_TX_FINISH;
    }
    if (irqSource == TX_ERROR) {
      sprintf(str, "TX Error: %u\n", baseband_txerror_message());
      debug_status = DEBUG_TX_FAIL;
    }
    if (irqSource == RX_FINISH) {
      sprintf(str, "** RX Finish\n");
      debug_status = DEBUG_RX_FINISH;
    }
    if (irqSource == RX_START) {
      sprintf(str, "** RX Start\n");
    }
    if (irqSource == RX_ERROR) {
      sprintf(str, "** RX Error: %u\n", baseband_rxerror_message());
      debug_status = DEBUG_RX_FAIL;
    }

    HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
    plic_complete_irq(0, irqSource);
  }
}

