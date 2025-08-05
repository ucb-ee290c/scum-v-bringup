# SCuM-V Controller Dual-Mode FPGA Design Specification

## 1. Overview

The SCuM-V Controller is a dual-mode FPGA implementation that provides UART-based access to both the Analog Scan Chain (ASC) and Serial TileLink (STL) interfaces of the SCuM-V chip. This design enables a single FPGA to handle both analog configuration and digital debugging/programming functionality.

### 1.1 System Requirements

- **Dual Interface Support**: Handle both ASC and STL protocols
- **Protocol Multiplexing**: Route commands based on 4-byte prefixes ("asc+" or "stl+")
- **Compatibility**: Maintain compatibility with existing Python host scripts (`hw/client.py` and `sw/tl_host.py`)
- **Performance**: Support baud rates up to 115.2kbaud (configurable)
- **ASIC Compliance**: Use identical GenericSerializer/GenericDeserializer modules as SCuM-V24B
- **Clean Architecture**: Hierarchical design with well-defined FIFO interfaces

## 2. System Architecture

### 2.1 High-Level Block Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           SCuM-V Controller FPGA                       │
│                                                                         │
│  ┌──────────┐   UART   ┌─────────────────────────────────────────────┐   │
│  │   Host   │◄────────►│        scumvcontroller_uart_handler        │   │
│  │    PC    │          │        (Protocol Multiplexer)              │   │
│  └──────────┘          │     ┌─────────────┐  ┌─────────────┐       │   │
│                        │     │  Incoming   │  │  Outgoing   │       │   │
│                        │     │    FIFOs    │  │    FIFOs    │       │   │
│                        │     │(Flow Ctrl)  │  │(Flow Ctrl)  │       │   │
│                        │     └─────────────┘  └─────────────┘       │   │
│                        └─────────────┬─────────────┬─────────────────┘   │
│                                      │             │                     │
│                               FIFO   │             │   FIFO              │
│                            Interface │             │ Interface           │
│                                      ▼             ▼                     │
│              ┌─────────────────────────────┐   ┌──────────────────────┐  │
│              │    scanchain_subsystem      │   │  serialtl_subsystem  │  │
│              │  ┌─────────────────────────┐│   │┌────────────────────┐│  │
│              │  │ scanchain_uart_client   ││   ││  stl_uart_client   ││  │
│              │  │     (modified)          ││   ││                    ││  │
│              │  └─────────────────────────┘│   │└────────────────────┘│  │
│              │  ┌─────────────────────────┐│   │┌────────────────────┐│  │
│              │  │   scanchain_writer      ││   ││uart_to_tilelink_   ││  │
│              │  │     (existing)          ││   ││      bridge        ││  │
│              │  └─────────────────────────┘│   │└────────────────────┘│  │
│              └─────────────┬───────────────┘   │┌────────────────────┐│  │
│                            │                   ││ GenericSerializer  ││  │
│                            ▼                   ││    (ASIC module)   ││  │
│                    ┌───────────────┐           │└────────────────────┘│  │
│                    │   SCuM-V      │           │┌────────────────────┐│  │
│                    │  Scan Chain   │           ││GenericDeserializer││  │
│                    │               │           ││    (ASIC module)   ││  │
│                    └───────────────┘           │└────────────────────┘│  │
│                                                │┌────────────────────┐│  │
│                                                ││tilelink_to_uart_   ││  │
│                                                ││      bridge        ││  │
│                                                │└────────────────────┘│  │
│                                                └──────────┬───────────┘  │
│                                                           │              │
│                                                           ▼              │
│                                                   ┌──────────────┐       │
│                                                   │    SCuM-V    │       │
│                                                   │  SerialTL    │       │
│                                                   │   Interface  │       │
│                                                   └──────────────┘       │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Implemented Module Hierarchy

```
a7top
├── scumvcontroller_uart_handler
│   └── uart (internal UART instance)
├── scanchain_subsystem
│   ├── scanchain_uart_client (modified for FIFO interface)
│   └── scanchain_writer (existing, unchanged)
├── serialtl_subsystem
│   ├── stl_uart_client
│   ├── uart_to_tilelink_bridge
│   ├── GenericSerializer (ASIC-provided)
│   ├── GenericDeserializer (ASIC-provided)
│   └── tilelink_to_uart_bridge
└── button_parser (existing, unchanged)
```

## 3. Communication Protocols

### 3.1 UART Command Format

All commands from the host PC follow this format:

```
[PREFIX][PAYLOAD]
```

- **PREFIX**: 4-byte string identifier
  - `"asc+"` (0x61, 0x73, 0x63, 0x2B) for Analog Scan Chain
  - `"stl+"` (0x73, 0x74, 0x6C, 0x2B) for Serial TileLink
- **PAYLOAD**: Protocol-specific data

### 3.2 ASC Protocol Specification

#### 3.2.1 ASC Command Format
```
Prefix: "asc+" (4 bytes)
Payload: Scan Chain Packet (22 bytes)

Total ASC Command: 26 bytes
```

#### 3.2.2 ASC Packet Structure
The 22-byte payload contains a scan chain packet with the following bit layout:
```
Bit Position: [172:0] (173 bits total, padded to 176 bits = 22 bytes)
┌────┬─────┬─────────────────────────────────────┬─────────────┐
│ 3  │  1  │              160                   │     12      │
├────┼─────┼─────────────────────────────────────┼─────────────┤
│ 0  │Reset│           Payload                  │   Address   │
└────┴─────┴─────────────────────────────────────┴─────────────┘
```

- **Address [11:0]**: Scan chain domain address (0-5)
- **Payload [159:0]**: Domain-specific configuration data
- **Reset [0]**: Reset flag for the domain
- **Reserved [2:0]**: Must be 0

#### 3.2.3 ASC Response Format
```
Response: 1 byte
- 0x01: Command accepted and processed successfully
- 0x00: Command rejected or processing failed
```

### 3.3 STL Protocol Specification

#### 3.3.1 STL Command Format
```
Prefix: "stl+" (4 bytes)
Payload: TileLink Packet (16 bytes)

Total STL Command: 20 bytes
```

#### 3.3.2 TileLink Packet Structure
The 16-byte payload contains a TileLink transaction:
```
Byte Offset:  0    1    2    3    4    5    6    7    8    9   10   11   12   13   14   15
           ┌────┬────┬────┬────┬─────────────┬─────────────────────────────────────────────┐
           │ChID│Opc │Size│Mask│   Address   │                   Data                      │
           └────┴────┴────┴────┴─────────────┴─────────────────────────────────────────────┘
```

Fields (Little Endian):
- **Channel ID [7:0]**: TileLink channel (0=A, 3=D)
- **Opcode [7:0]**: Packed field containing opcode[2:0], param[2:0], corrupt[0], reserved[1:0]
- **Size [7:0]**: Log2 of transfer size
- **Union [7:0]**: Mask (Ch A) or Denied flag (Ch D)
- **Address [31:0]**: Memory address (little endian)
- **Data [63:0]**: Data payload (little endian)

#### 3.3.3 STL Response Format
For STL commands, responses depend on the transaction type:
- **Write (PutFullData)**: Returns AccessAck packet (16 bytes)
- **Read (Get)**: Returns AccessAckData packet (16 bytes)

## 4. Hardware Interface Specifications

### 4.1 External Interfaces (a7top.v)

#### 4.1.1 UART Interface
```verilog
// Primary communication with host PC
input  wire UART_TXD_IN,  // Data from host PC
output wire UART_RXD_IN   // Data to host PC
```

#### 4.1.2 ASC Interface
```verilog
// Analog Scan Chain signals to SCuM-V
output wire SCAN_CLK,     // Scan chain clock (1kHz)
output wire SCAN_EN,      // Scan chain enable (active low)
output wire SCAN_IN,      // Serial data to scan chain
output wire SCAN_RESET    // Scan chain reset
```

#### 4.1.3 SerialTL Interface
```verilog
// SerialTL interface to SCuM-V (clock domain crossing required)
input  wire TL_CLK,        // TileLink clock from SCuM-V
input  wire TL_IN_VALID,   // Valid signal for data going to SCuM-V
output wire TL_IN_READY,   // Ready signal for data going to SCuM-V
input  wire TL_IN_DATA,    // Serial data going to SCuM-V
output wire TL_OUT_VALID,  // Valid signal for data coming from SCuM-V
input  wire TL_OUT_READY,  // Ready signal for data coming from SCuM-V
output wire TL_OUT_DATA    // Serial data coming from SCuM-V
```

### 4.2 Internal FIFO Interfaces

#### 4.2.1 UART Handler Flow Control Architecture

The UART handler implements internal FIFOs to manage flow control between the UART interface (high baud rate) and the TileLink interface (slower TL_CLK). This is critical because:

- **TL_CLK Timing**: The TileLink clock runs much slower than UART baud rate (typically 200kHz vs 1Mbaud+)
- **Burst Handling**: Complete TileLink packets (16 bytes) must be buffered before processing
- **Bidirectional Flow**: Both incoming (UART→subsystem) and outgoing (subsystem→UART) FIFOs are required

```
UART Handler Internal Architecture:
┌─────────────────────────────────────────────────────────────────┐
│                    scumvcontroller_uart_handler                 │
│                                                                 │
│  UART RX ──► Incoming ──► Protocol ──► ASC/STL ──► Subsystems   │
│             FIFO (128B)  Detection    Mux                       │
│                                                                 │
│  UART TX ◄── Outgoing ◄── Response ◄── ASC/STL ◄── Subsystems   │
│             FIFO (128B)  Mux        Demux                       │
└─────────────────────────────────────────────────────────────────┘
```

**FIFO Specifications:**
- **Incoming FIFO**: 128-byte depth, buffers UART data before protocol processing
- **Outgoing FIFO**: 128-byte depth, buffers subsystem responses before UART transmission
- **Flow Control**: Prevents data loss during clock domain differences
- **Protocol Isolation**: Each subsystem sees consistent data flow regardless of UART timing

#### 4.2.2 Standard FIFO Interface
All subsystem interfaces follow this standard pattern:
```verilog
// Input data stream
input  wire       data_valid,     // Data available from source
output wire       data_ready,     // Ready to accept data
input  wire [7:0] data_in,        // Input data byte

// Output response stream  
output wire       response_valid, // Response data available
input  wire       response_ready, // Sink ready for response
output wire [7:0] response_data   // Response data byte
```

#### 4.2.2 UART Handler Interface
```verilog
module scumvcontroller_uart_handler (
    // Clock and reset
    input  wire       clk,
    input  wire       reset,
    
    // External UART
    input  wire       uart_rx,
    output wire       uart_tx,
    
    // ASC subsystem FIFO interface
    output wire       asc_data_valid,
    input  wire       asc_data_ready,
    output wire [7:0] asc_data_out,
    input  wire       asc_response_valid,
    output wire       asc_response_ready,
    input  wire [7:0] asc_response_data,
    
    // STL subsystem FIFO interface
    output wire       stl_data_valid,
    input  wire       stl_data_ready,
    output wire [7:0] stl_data_out,
    input  wire       stl_response_valid,
    output wire       stl_response_ready,
    input  wire [7:0] stl_response_data,
    
    // Status and control
    output wire [1:0] active_mode,   // 0=idle, 1=asc, 2=stl
    output wire [3:0] debug_state    // Internal state for debugging
);
```

#### 4.2.3 Subsystem Interfaces
```verilog
// Scanchain Subsystem
module scanchain_subsystem (
    input  wire       clk, reset,
    // Standard FIFO interface (input)
    input  wire       data_valid,
    output wire       data_ready,
    input  wire [7:0] data_in,
    // Standard FIFO interface (output) 
    output wire       response_valid,
    input  wire       response_ready,
    output wire [7:0] response_data,
    // Hardware interface
    output wire       scan_clk, scan_en, scan_in, scan_reset
);

// SerialTL Subsystem  
module serialtl_subsystem (
    input  wire       clk, reset,
    // Standard FIFO interface (input)
    input  wire       data_valid,
    output wire       data_ready, 
    input  wire [7:0] data_in,
    // Standard FIFO interface (output)
    output wire       response_valid,
    input  wire       response_ready,
    output wire [7:0] response_data,
    // SerialTL hardware interface
    input  wire       tl_clk, tl_in_valid, tl_in_data,
    output wire       tl_in_ready, tl_out_valid, tl_out_data,
    input  wire       tl_out_ready
);
```

## 5. Data Flow Diagrams

### 5.1 ASC Command Flow
```
Host PC → UART Handler → Scanchain Subsystem → SCuM-V ASC
  26B       FIFO           FIFO Interface        Hardware
"asc+"    Interface                              Signals
+22B        ↓                  ↓                    ↓
Packet   Prefix Strip      ASC Client         Scan Writer
            ↓              & Response            ↓
         22B Data             ↓               SCAN_CLK
                           1B Status          SCAN_EN
                              ↑               SCAN_IN
                         FIFO Response       SCAN_RESET
                              ↑                 ↑
Host PC ← UART Handler ← Scanchain Subsystem ←┘
  1B         ↑              ↑
Status    UART TX       Response FIFO
```

### 5.2 STL Command Flow
```
Host PC → UART Handler → SerialTL Subsystem → SCuM-V SerialTL
  20B       FIFO           FIFO Interface        Hardware
"stl+"    Interface                              Interface
+16B        ↓                  ↓                    ↓
Packet   Prefix Strip      STL Client         TL Serializer
            ↓              & Buffering            ↓
         16B Data             ↓               TL_OUT_DATA
                         TL Bridge             TL_OUT_VALID
                              ↓               TL_OUT_READY
                         TL Frame                 ↓
                                              TL_CLK Domain

Response Path:
SCuM-V SerialTL → TL Deserializer → TL Bridge → STL Client → UART Handler → Host PC
    Hardware          TL_CLK           FPGA_CLK    FIFO        FIFO         16B
    Interface         Domain           Domain      Interface   Interface    Response
       ↓                ↓                ↓          ↓           ↓
   TL_IN_DATA      TL Frame        16B Packet   Response    UART TX
   TL_IN_VALID     Struct          Buffer       FIFO
   TL_IN_READY
```

### 5.3 Protocol Detection State Machine
```
                    ┌─────────────┐
                    │    IDLE     │◄─── Reset/Complete
                    └──────┬──────┘
                           │ UART byte
                    ┌──────▼──────┐
                    │ PREFIX_1    │ 'a' or 's'
                    └──────┬──────┘
                           │ 's'/'t'
                    ┌──────▼──────┐
                    │ PREFIX_2    │
                    └──────┬──────┘
                           │ 'c'/'l'
                    ┌──────▼──────┐
                    │ PREFIX_3    │
                    └──────┬──────┘
                           │ '+'
                    ┌──────▼──────┐
                    │  Determine  │
                    │  Protocol   │
                    └──┬───────┬──┘
                 "asc+"│       │"stl+"
              ┌────────▼─┐   ┌─▼────────┐
              │ASC_MODE  │   │STL_MODE  │
              │22 bytes  │   │16 bytes  │
              └────────┬─┘   └─┬────────┘
                       │       │
              ┌────────▼─┐   ┌─▼────────┐
              │ASC_RESP  │   │STL_RESP  │
              │1 byte    │   │16 bytes  │
              └──────────┘   └──────────┘
```

## 6. Implementation Status and Guidelines

### 6.1 Implementation Complete ✅

#### 6.1.1 Core Infrastructure (Completed)
- **`a7top.v`**: Top-level integration with clean hierarchical structure
- **`scumvcontroller_uart_handler.v`**: Protocol multiplexer with prefix detection state machine
- **`scanchain_subsystem.v`**: ASC subsystem wrapper with FIFO interfaces  
- **`serialtl_subsystem.v`**: STL subsystem wrapper integrating all STL components

#### 6.1.2 STL Implementation (Completed)
- **`stl_uart_client.v`**: STL packet buffering with 4-state FSM (IDLE→RECEIVING→PACKET_READY→RESPONSE)
- **`uart_to_tilelink_bridge.v`**: 16-byte packet to TileLink frame conversion with proper `tl_host.py` format handling
- **`tilelink_to_uart_bridge.v`**: TileLink frame to 16-byte packet conversion with little-endian byte ordering

#### 6.1.3 ASC Implementation (Completed)
- **`scanchain_uart_client.v`**: Modified to use FIFO interface instead of direct UART, maintains original packet parsing logic

#### 6.1.4 Test Infrastructure (Completed)
- **`tl_host_sim.py`**: Modified version of `tl_host.py` that generates UART byte streams to files for RTL simulation
- **`scumv_controller_integration_tb.v`**: Comprehensive integration testbench with TileLink echo and inspection functionality
- **TileLink Echo Architecture**: TL_OUT → GenericDeserializer (inspection) → GenericSerializer → TL_IN
- **Packet Validation**: Complete packet field inspection with content-based assertions
- **Test Vectors**: Generated binary files with real STL command sequences for simulation validation

#### 6.1.5 Remaining Tasks
- **Constraint File**: Add SerialTL pin constraints for TL_CLK, TL_IN_*, TL_OUT_* (Priority: Medium)
- **Hardware Validation**: Test with actual SCuM-V hardware (Priority: High)

### 6.2 Design Principles

1. **Clean Hierarchy**: Three-level architecture (top → subsystem → implementation)
2. **Standard Interfaces**: All subsystems use identical FIFO interfaces
3. **Protocol Fidelity**: STL implementation uses unmodified ASIC serializer/deserializer
4. **Separation of Concerns**: Protocol detection separate from protocol implementation
5. **Reusability**: Maximum reuse of existing scanchain modules

### 6.3 Clocking Strategy

- **System Clock (FPGA_CLK)**: 100MHz for all FPGA logic
- **UART Clock**: Derived from system clock (115.2kbaud default, configurable)
- **Scan Clock**: 1kHz generated from system clock (existing implementation)
- **TileLink Clock (TL_CLK)**: External clock from SCuM-V, requires clock domain crossing

### 6.4 Reset and Error Handling

- **Global Reset**: Active-high reset (inverted from RESET button)
- **Subsystem Isolation**: Each subsystem handles its own reset domain
- **Protocol Errors**: UART handler enters ERROR state on invalid prefixes
- **Timeout Handling**: Each subsystem responsible for internal timeouts

### 6.5 Interface Standards

#### 6.5.1 FIFO Interface Convention
All internal interfaces follow the standard ready/valid handshake:
```verilog
// Producer → Consumer
output wire       data_valid,     // Data is valid and available
input  wire       data_ready,     // Consumer ready to accept data  
output wire [7:0] data_out,       // Data payload

// Consumer → Producer (for responses)
input  wire       response_valid, // Response data is valid
output wire       response_ready, // Producer ready for response
input  wire [7:0] response_data   // Response payload
```

#### 6.5.2 Debug and Status Outputs
- **LED[0]**: System reset status (n_reset)
- **LED[1]**: ASC mode active (active_mode[0])
- **LED[2]**: STL mode active (active_mode[1])  
- **LED[3]**: TileLink input valid (TL_IN_VALID)

## 7. Next Implementation Steps

### 7.1 Priority Order

1. **Modify `scanchain_uart_client.v`** 
   - Replace direct UART interface with FIFO interface
   - Maintain existing packet parsing and response generation logic
   - Test ASC functionality with modified interface

2. **Implement `stl_uart_client.v`**
   - 16-byte packet buffering using internal FIFOs
   - Byte-to-packet and packet-to-byte conversion
   - Flow control between UART handler and TileLink bridges

3. **Implement `uart_to_tilelink_bridge.v`**
   - Unpack 16-byte packets according to `tl_host.py` format
   - Generate proper TileLink frame signals for GenericSerializer
   - Handle little-endian byte ordering correctly

4. **Implement `tilelink_to_uart_bridge.v`**
   - Pack TileLink frames into 16-byte packets for `tl_host.py`
   - Handle response buffering and flow control
   - Maintain correct byte ordering

5. **Add Constraint File Updates**
   - Pin assignments for TL_CLK, TL_IN_VALID, TL_IN_READY, TL_IN_DATA
   - Pin assignments for TL_OUT_VALID, TL_OUT_READY, TL_OUT_DATA
   - Timing constraints for clock domain crossing

### 7.2 Testbench Architecture

#### 7.2.1 TileLink Echo and Inspection System

The integration testbench implements a sophisticated TileLink echo and inspection system for comprehensive validation:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Integration Testbench Architecture                   │
│                                                                         │
│  ┌──────────────┐    UART     ┌─────────────────────────────────────┐   │
│  │ Test Vector  │ ────────────►│            a7top DUT               │   │
│  │ Generator    │              │                                     │   │
│  └──────────────┘              │  ┌─────────────────────────────────┐│   │
│                                 │  │      serialtl_subsystem        ││   │
│  ┌──────────────┐              │  └──────────┬──────────────────────┘│   │
│  │ UART Response│◄─────────────│             │                       │   │
│  │   Capture    │              └─────────────┼───────────────────────┘   │
│  └──────────────┘                            │                           │
│                                               │ TL_OUT                    │
│  ┌─────────────────────────────────────────────┼─────────────────────────┐ │
│  │              TileLink Echo & Inspection     ▼                         │ │
│  │                                                                       │ │
│  │  TL_OUT ──► GenericDeserializer ──► GenericSerializer ──► TL_IN      │ │
│  │                       │                                               │ │
│  │                       ▼                                               │ │
│  │              ┌─────────────────┐                                      │ │
│  │              │ Packet Inspector│                                      │ │
│  │              │  & Validator    │                                      │ │
│  │              │                 │                                      │ │
│  │              │ - Display all   │                                      │ │
│  │              │   packet fields │                                      │ │
│  │              │ - Content       │                                      │ │
│  │              │   assertions    │                                      │ │
│  │              │ - Pass/fail     │                                      │ │
│  │              │   tracking      │                                      │ │
│  │              └─────────────────┘                                      │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Key Features:**
- **Realistic Echo**: Deserialize → re-serialize path provides proper timing behavior
- **Complete Inspection**: All TileLink packet fields captured and displayed
- **Content Validation**: Assertions verify packet field validity (size, channel, opcode)
- **Pass/Fail Criteria**: Comprehensive validation including UART responses, packet counts, and assertion results

#### 7.2.2 Validation Methodology

The testbench provides multi-level validation:

1. **UART Level**: Verifies byte-level communication and response capture
2. **TileLink Level**: Validates packet structure and content correctness  
3. **Echo Level**: Confirms commands are properly echoed back via TL_IN
4. **System Level**: Overall pass/fail based on all validation criteria

**Assertion Strategy:**
- Content-based assertions only (no timing assumptions)
- Field range validation (size ≤ 0x06, channel ≤ 0x2, opcode ≤ 0x6)
- Packet count tracking for echo verification
- Graceful error reporting with detailed failure information

#### 7.2.3 Verification Strategy

#### 7.2.3.1 Module-Level Testing
- **UART Handler**: Test prefix detection state machine with various input sequences
- **ASC Subsystem**: Validate against existing `hw/client.py` without modifications
- **STL Bridges**: Unit tests for packet ↔ TileLink frame conversion
- **Clock Domain Crossing**: Verify TL_CLK ↔ FPGA_CLK data transfer

#### 7.2.2 System-Level Testing  
- **Protocol Switching**: Send alternating "asc+" and "stl+" commands
- **Error Handling**: Test invalid prefixes, incomplete packets, timeouts
- **End-to-End**: Full transactions through both ASC and STL paths
- **Performance**: Verify throughput and latency requirements

#### 7.2.3 Hardware Validation
- **SCuM-V Integration**: Test with actual SCuM-V24B hardware
- **Host Compatibility**: Validate with unmodified `hw/client.py` and `sw/tl_host.py`
- **LED Indicators**: Verify debug outputs match expected system state

### 7.3 Key Design Decisions Made

1. **Three-Level Hierarchy**: Clean separation between top-level, subsystem, and implementation
2. **Standard FIFO Interfaces**: Consistent ready/valid handshake throughout
3. **Protocol Isolation**: Each subsystem independent and testable
4. **Prefix-Based Routing**: Simple and reliable protocol detection
5. **ASIC Module Reuse**: Exact GenericSerializer/Deserializer from SCuM-V24B

### 7.4 Resource Estimates

Based on similar FPGA implementations:
- **LUTs**: ~2000-3000 (small fraction of Artix-7 100T)
- **FFs**: ~1500-2500 (small fraction of Artix-7 100T)  
- **Block RAM**: 2-4 blocks for FIFOs and buffering
- **Clock Domains**: 2 (FPGA_CLK @ 100MHz, TL_CLK from SCuM-V)

### 7.5 Critical Success Factors

1. **Protocol Compatibility**: Must work with existing Python scripts unchanged
2. **Timing Closure**: Meet timing requirements across clock domains
3. **Error Recovery**: Graceful handling of malformed packets and errors
4. **Resource Efficiency**: Fit comfortably within Artix-7 100T constraints
5. **Maintainability**: Clear, well-documented code for future modifications

---

## 8. Conclusion

This design specification provides a complete blueprint for implementing the dual-mode SCuM-V controller. The hierarchical architecture with standardized FIFO interfaces ensures clean modularity while maintaining compatibility with existing host software. The implementation skeleton is complete and ready for detailed module development following the specified priority order.