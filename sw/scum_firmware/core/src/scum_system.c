
#include "scum_system.h"
#include "scum_hal.h"
#include "main.h"

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
  enable_fpu();
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


// void __attribute__ ((interrupt)) trap_handler(void) {  
void trap_handler() {
  uint32_t m_cause;
  asm volatile("csrr %0, mcause" : "=r"(m_cause));

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
  
    char str[128];
    /*
    sprintf(str, "intr %d\n", irqSource);
    HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
  
    if (irqSource == 6) {
      sprintf(str, "** RX Error Message: %u\n", baseband_rxerror_message());
    }
    if (irqSource == 7) {
      sprintf(str, "** RX Start\n");
    }
    if (irqSource == 8) {
      sprintf(str, "** Bytes Read: %u\n", baseband_rxfinish_message());
    }
    if (irqSource == 9) {
      sprintf(str, "TX Operation Failed. Error message: %u\n", baseband_txerror_message());
    }
    if (irqSource == 10) {
      sprintf(str, "TX Operation Finished. Check above for any errors.\n");
    }

    HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
    */
    plic_complete_irq(0, irqSource);

    // HAL_GPIO_writePin(GPIOA, GPIO_PIN_0, 1);
    // sprintf(str, "mcause: %x\n", m_cause);
  }
}

