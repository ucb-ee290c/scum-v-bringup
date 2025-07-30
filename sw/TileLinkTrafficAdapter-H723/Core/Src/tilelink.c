/*
 * tilelink.c
 *
 *  Created on: Sep 9, 2022
 *      Author: TK
 */

#include "tilelink.h"


void TL_update(TileLinkController *tl) {
  if (tl->tx_pending) {
    // Check if receiver is ready before sending the current bit
    if (tl->tl_in_ready_prev_state == 1) {
      // Send the current bit (no setup cycle - start with real data immediately)
      HAL_GPIO_WritePin(TL_IN_DATA_GPIO_Port, TL_IN_DATA_Pin, tl->tx_frame.buffer[tl->tx_bit_offset]);
      HAL_GPIO_WritePin(TL_IN_VALID_GPIO_Port, TL_IN_VALID_Pin, 1);

      // Increment offset after sending the bit
      tl->tx_bit_offset += 1;

      // Check if we've sent all bits - but keep VALID high for one more cycle
      if (tl->tx_bit_offset == TL_SERDES_TOTAL_SIZE) {
        // Don't drop VALID yet - FPGA needs one full cycle to capture the last bit
        tl->tx_bit_offset++; // Go to 165 to mark "termination cycle"
      } else if (tl->tx_bit_offset > TL_SERDES_TOTAL_SIZE) {
        // NOW it's safe to drop VALID - FPGA has captured all 164 bits
        HAL_GPIO_WritePin(TL_IN_VALID_GPIO_Port, TL_IN_VALID_Pin, 0);
        tl->tx_pending = 0;
        tl->tx_finished = 1;
      }
    }
    // If receiver not ready, don't do anything - wait for next cycle
  }

  else if (tl->rx_pending) {
    if (tl->rx_finished) {
      HAL_GPIO_WritePin(TL_OUT_READY_GPIO_Port, TL_OUT_READY_Pin, 0);
      tl->rx_pending = 0;
    }
    HAL_GPIO_WritePin(TL_OUT_READY_GPIO_Port, TL_OUT_READY_Pin, 1);
    if (HAL_GPIO_ReadPin(TL_OUT_VALID_GPIO_Port, TL_OUT_VALID_Pin) == GPIO_PIN_SET) {
      tl->rx_frame.buffer[tl->rx_bit_offset] = HAL_GPIO_ReadPin(TL_OUT_DATA_GPIO_Port, TL_OUT_DATA_Pin);

      tl->rx_bit_offset += 1;

      if (tl->rx_bit_offset == TL_SERDES_TOTAL_SIZE) {
        tl->rx_finished = 1;
      }
    }
  }
}

void TL_serialize(TileLinkFrame *frame) {
  for (uint16_t i=0; i<TL_SERDES_LAST_SIZE; i+=1) {
    frame->buffer[i+TL_SERDES_LAST_OFFSET] = (frame->last >> i) & 0b1;
  }
  for (uint16_t i=0; i<TL_SERDES_UNION_SIZE; i+=1) {
    frame->buffer[i+TL_SERDES_UNION_OFFSET] = (frame->tl_union >> i) & 0b1;
  }
  for (uint16_t i=0; i<TL_SERDES_CORRUPT_SIZE; i+=1) {
    frame->buffer[i+TL_SERDES_CORRUPT_OFFSET] = (frame->corrupt >> i) & 0b1;
  }
  for (uint16_t i=0; i<TL_SERDES_DATA_SIZE; i+=1) {
    frame->buffer[i+TL_SERDES_DATA_OFFSET] = (frame->data >> i) & 0b1;
  }
  for (uint16_t i=0; i<TL_SERDES_ADDRESS_SIZE; i+=1) {
    frame->buffer[i+TL_SERDES_ADDRESS_OFFSET] = (frame->address >> i) & 0b1;
  }
  for (uint16_t i=0; i<TL_SERDES_SOURCE_SIZE; i+=1) {
    frame->buffer[i+TL_SERDES_SOURCE_OFFSET] = (frame->source >> i) & 0b1;
  }
  for (uint16_t i=0; i<TL_SERDES_SIZE_SIZE; i+=1) {
    frame->buffer[i+TL_SERDES_SIZE_OFFSET] = (frame->size >> i) & 0b1;
  }
  for (uint16_t i=0; i<TL_SERDES_PARAM_SIZE; i+=1) {
    frame->buffer[i+TL_SERDES_PARAM_OFFSET] = (frame->param >> i) & 0b1;
  }
  for (uint16_t i=0; i<TL_SERDES_OPCODE_SIZE; i+=1) {
    frame->buffer[i+TL_SERDES_OPCODE_OFFSET] = (frame->opcode >> i) & 0b1;
  }
  for (uint16_t i=0; i<TL_SERDES_CHANID_SIZE; i+=1) {
    frame->buffer[i+TL_SERDES_CHANID_OFFSET] = (frame->chanid >> i) & 0b1;
  }
}

void TL_deserialize(TileLinkFrame *frame) {
  frame->chanid = 0;
  frame->opcode = 0;
  frame->param = 0;
  frame->size = 0;
  frame->source = 0;
  frame->address = 0;
  frame->data = 0;
  frame->corrupt = 0;
  frame->tl_union = 0;
  frame->last = 0;

  for (uint16_t i=0; i<TL_SERDES_LAST_SIZE; i+=1) {
    frame->last |= ((frame->buffer[i+TL_SERDES_LAST_OFFSET] & 0b1) << i);
  }
  for (uint16_t i=0; i<TL_SERDES_UNION_SIZE; i+=1) {
    frame->tl_union |= ((frame->buffer[i+TL_SERDES_UNION_OFFSET] & 0b1) << i);
  }
  for (uint16_t i=0; i<TL_SERDES_CORRUPT_SIZE; i+=1) {
    frame->corrupt |= ((frame->buffer[i+TL_SERDES_CORRUPT_OFFSET] & 0b1) << i);
  }
  for (uint16_t i=0; i<TL_SERDES_DATA_SIZE; i+=1) {
    frame->data |= ((uint64_t)(frame->buffer[i+TL_SERDES_DATA_OFFSET] & 0b1) << i);
  }
  for (uint16_t i=0; i<TL_SERDES_ADDRESS_SIZE; i+=1) {
    frame->address |= ((uint64_t)(frame->buffer[i+TL_SERDES_ADDRESS_OFFSET] & 0b1) << i);
  }
  for (uint16_t i=0; i<TL_SERDES_SOURCE_SIZE; i+=1) {
    frame->source |= ((frame->buffer[i+TL_SERDES_SOURCE_OFFSET] & 0b1) << i);
  }
  for (uint16_t i=0; i<TL_SERDES_SIZE_SIZE; i+=1) {
    frame->size |= ((frame->buffer[i+TL_SERDES_SIZE_OFFSET] & 0b1) << i);
  }
  for (uint16_t i=0; i<TL_SERDES_PARAM_SIZE; i+=1) {
    frame->param |= ((frame->buffer[i+TL_SERDES_PARAM_OFFSET] & 0b1) << i);
  }
  for (uint16_t i=0; i<TL_SERDES_OPCODE_SIZE; i+=1) {
    frame->opcode |= ((frame->buffer[i+TL_SERDES_OPCODE_OFFSET] & 0b1) << i);
  }
  for (uint16_t i=0; i<TL_SERDES_CHANID_SIZE; i+=1) {
    frame->chanid |= ((frame->buffer[i+TL_SERDES_CHANID_OFFSET] & 0b1) << i);
  }
}

void TL_transmit(TileLinkController *tl) {
  TL_serialize(&tl->tx_frame);

  // Ensure clean start: explicitly set signals to known state
  HAL_GPIO_WritePin(TL_IN_VALID_GPIO_Port, TL_IN_VALID_Pin, 0);
  HAL_GPIO_WritePin(TL_IN_DATA_GPIO_Port, TL_IN_DATA_Pin, 0);
  HAL_GPIO_WritePin(TL_OUT_READY_GPIO_Port, TL_OUT_READY_Pin, 0);

  // reset state
  tl->tx_entry = 0;
  tl->tx_bit_offset = 0;
  tl->rx_bit_offset = 0;
  tl->tx_finished = 0;
  tl->rx_finished = 0;
  tl->tx_timeout_counter = 0;
  tl->tx_timed_out = 0;

  // enable TX RX
  tl->rx_pending = 1;
  tl->tx_pending = 1;
}


void TL_GET(TileLinkController *tl, uint32_t address) {
  tl->tx_frame.chanid  = 0;
  tl->tx_frame.opcode  = TL_CH_A_OPCODE_GET;  // get
  tl->tx_frame.param   = 0;
  tl->tx_frame.size    = 2;  // 2^2 = 4 bytes
  tl->tx_frame.source  = 0;
  tl->tx_frame.address = (uint64_t)address;  // Cast to 64-bit, upper 32 bits will be 0
  tl->tx_frame.data    = 0x0000000000000000;
  tl->tx_frame.corrupt = 0;
  tl->tx_frame.tl_union    = 0b00001111;  // mask = 0xF for full 32-bit access
  tl->tx_frame.last    = 1;
}

void TL_PUTFULLDATA(TileLinkController *tl, uint32_t address, uint64_t data) {
  tl->tx_frame.chanid  = 0;
  tl->tx_frame.opcode  = TL_CH_A_OPCODE_PUTFULLDATA;  // putfulldata
  tl->tx_frame.param   = 0;
  tl->tx_frame.size    = 2;  // 2^2 = 4 bytes
  tl->tx_frame.source  = 0;
  tl->tx_frame.address = (uint64_t)address;  // Cast to 64-bit, upper 32 bits will be 0
  tl->tx_frame.data    = data;
  tl->tx_frame.corrupt = 0;
  tl->tx_frame.tl_union    = 0b00001111;  // mask = 0xF for full 32-bit access
  tl->tx_frame.last    = 1;
}
