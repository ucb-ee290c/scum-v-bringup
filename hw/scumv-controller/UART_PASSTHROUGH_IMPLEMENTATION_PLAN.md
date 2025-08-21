# DUT UART Passthrough and REPL Implementation Plan

## 0. Goals
- Add a third, bi-directional data path that bridges the FPGA to the DUT (SCuM-V) UART.
- Use a 4-byte prefix `"uar+"` for both directions so host can demultiplex FPGA→host traffic.
- Preserve existing ASC (`"asc+"`) and STL (`"stl+"`) functionality and bootloading reliability.
- Provide a session-based Python REPL/CLI that can:
  - `tl_read [addr]`, `tl_write [addr] [data]`
  - `uart_write [bytes]`
  - `uart_listen` (asynchronous, prints UART bytes from DUT)
  - `bootload [target]`
  - `run [function_name]`

## 1. Protocol and Framing
- Prefixes (host→FPGA commands and FPGA→host responses): `"asc+"`, `"stl+"`, `"uar+"`.
- DUT UART framing (both directions):
  - `"uar+"` + `LEN` (1 byte, 1..255; 0 reserved) + `DATA[LEN]`.
  - FPGA may coalesce or fragment the DUT UART stream. Frames are emitted when:
    - LEN reaches a high-watermark (≤ 255), or
    - idle timeout expires (default 1 ms) since last DUT byte.
- Interleaving: `uar+` frames may interleave with `stl+` and `asc+` responses; host must demux by prefix.

## 2. HDL Changes
### 2.1 Top-Level (`a7top.v`)
- New external ports:
  - `input  DUT_UART_TXD_IN`  // TX from DUT into FPGA
  - `output DUT_UART_RXD_OUT` // RX from FPGA to DUT
- Instantiate `dut_uart_subsystem` and wire to `scumvcontroller_uart_handler`.

### 2.2 `dut_uart_subsystem.v`
- Purpose: Convert standard ready/valid FIFO byte streams to/from a dedicated UART instance.
- Interface:
  - Ingress (host→DUT): `data_valid/data_ready/data_in[7:0]`.
  - Egress (DUT→host): `response_valid/response_ready/response_data[7:0]`.
  - Physical: `dut_uart_txd_in` (from DUT), `dut_uart_rxd_out` (to DUT).
- Internals:
  - Instantiate a second `uart` (reuse existing `uart.v`).
  - Small TX/RX FIFOs (≥128 bytes) to decouple from handler.
  - Parameterizable baud divisor (compile-time initially; see §5 for runtime config option).

### 2.3 `scumvcontroller_uart_handler.v`
- RX path (host→FPGA):
  - Extend prefix detector to recognize `"uar+"`.
  - After `"uar+"`, read `LEN` then push `LEN` raw bytes into `uar_data_*` stream (host→DUT).
- TX path (FPGA→host):
  - Add a coalescing buffer for bytes coming from `uar_response_*` (DUT→host).
  - Emit frames as `"uar+"` + `LEN` + `DATA` using high-watermark and idle-timeout policy.
- Scheduler for outgoing responses:
  - Priority: Complete any in-progress emission. Give STL responses non-starvation priority to preserve bootloader timing. Otherwise round-robin among ASC/STL/UAR when data is pending.
- Status/Debug:
  - Export counters (optional): emitted UAR frames, dropped bytes (should remain zero), idle-timeouts taken.

### 2.4 Sizing and Timing
- FIFOs: 128–256 bytes for each direction in handler and subsystem.
- Idle-timeout: default 1 ms at FPGA `clk` domain; parameterizable.
- Baud rate: initial DUT UART baud divisor set at synthesis (e.g., 115200). See §5 for runtime configuration option.

## 3. Testbench Updates
- Extend `scumv_controller_integration_tb.v`:
  1) Drive `dut_uart_txd_in` with patterns:
     - Single byte, short bursts (LEN < 16), long bursts (LEN > 128), bursts with idle gaps.
     - Check UART handler emits correct `uar+` frames (LEN, payload, coalescing on watermark/timeout).
  2) Send `"uar+" + LEN + DATA` on host model and verify `dut_uart_rxd_out` outputs each DATA byte.
  3) Interleave with STL Get/Put commands and verify no corruption and correct demux at host.
  4) Assertions:
     - No dropped bytes; LEN ∈ [1,255]; frames emitted on idle.
     - STL responses remain correct while UAR traffic is active.

## 4. Python Host REPL/CLI
### 4.1 Design
- New script `sw/repl.py` (minimal dependencies; standard library only) that:
  - Opens serial port and starts a background reader thread.
  - Reader thread demuxes by 4-byte prefix:
    - `stl+`: read 16 bytes; print decoded AccessAck/AccessAckData; deliver to pending TL requests.
    - `asc+`: read 1 byte; print status.
    - `uar+`: read LEN (1 byte) + DATA; if `uart_listen` is enabled, print bytes to console.
  - Foreground REPL built with `cmd.Cmd` (`cmd` module): commands:
    - `tl_read <addr>`
    - `tl_write <addr> <data>`
    - `bootload <target>` (uses `TileLinkHost.flash_binary` in a non-blocking or blocking mode but coexists with demux thread)
    - `uart_write <hex|ascii>` (accept `0x..`/`hex:` or `str:` prefixes to disambiguate)
    - `uart_listen [on|off]`
    - `run <function_name> [args...]` (dispatch to whitelisted helper functions in the script)
  - Error handling: timeouts, partial frames, unknown prefixes → warn and resync (seek next 4-byte prefix window).

### 4.2 Interop with existing `tl_host.py`
- Reuse `TileLinkHost` by refactoring read path to allow interleaved traffic:
  - Replace fixed `read_exactly(16)` with a demux layer that discards/queues any `uar+` frames to a thread-safe queue for the REPL while awaiting STL response.
- Alternatively, implement TL commands natively in `repl.py` using the same frame packers as `tl_host.py`.

### 4.3 UX Notes
- Pretty-print TL packets (reuse `print_tilelink_packet`).
- `uart_listen` prints as `UART RX: <hex/ascii>`; provide a toggle for hex/ascii view.
- Command history and tab completion can be added later (`readline`/`prompt_toolkit` optional).

## 5. Optional Runtime Config (Phase 2)
- Add a `uar+` control message subtype for setting DUT UART baud divisor:
  - `"uar+" 0xFF <divisor_le32>` → set baud divisor atomically in `dut_uart_subsystem`.
- Add `uar+` 0xFE to query stats/counters.
- These control opcodes would be interpreted by the handler and not forwarded to the DUT.

## 6. Risks and Mitigations
- Interleaving with STL bootloader responses:
  - Mitigation: priority scheduler that finishes in-flight frames and gives STL non-starvation priority. Demux on host prevents misalignment.
- Throughput overhead of 1-byte length framing:
  - Acceptable for debug. For higher throughput, increase coalescing watermark.
- Windows serial buffering:
  - The REPL sets large RX/TX buffers when available (like in `tl_host.py`).

## 7. Work Breakdown
1) HDL
   - [ ] Add ports and instantiate `dut_uart_subsystem` in `a7top.v`.
   - [ ] Implement `dut_uart_subsystem.v` (reuse `uart.v`, add FIFOs).
   - [ ] Extend `scumvcontroller_uart_handler.v` (prefix, framing, scheduler, idle timer).
   - [ ] Hook into constraints (`a7top.xdc`) for DUT UART pins.
2) Testbench
   - [ ] Extend integration TB with stimulus, checkers, and assertions.
3) Host
   - [ ] Implement `sw/repl.py` REPL and demux thread.
   - [ ] Optionally refactor `tl_host.py` read path to cooperate with REPL demux.
4) Docs
   - [x] Update spec with `uar+` protocol.
   - [x] Add this implementation plan.

## 8. Acceptance Criteria
- On hardware, `uart_write` transmits data observable on the DUT UART RX pin; `uart_listen` displays bytes sent by the DUT UART TX pin.
- Bootload (`bootload ble_loopback`) remains reliable at target baud with UAR traffic idle or active.
- Integration TB passes with no assertions and shows correct interleaving of STL and UAR traffic. 