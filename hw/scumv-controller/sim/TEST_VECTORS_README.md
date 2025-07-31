# STL Test Vectors for RTL Simulation

## Generated Files

### 1. `sim_input.bin` (100 bytes)
Comprehensive test sequence with 5 STL transactions:
- Read from UART_BASE (0x10020000)
- Write to UART_BASE (0x10020000, data=0x12345678)  
- Read from GPIO_BASE (0x10012000)
- Write to GPIO_BASE (0x10012000, data=0xABCDEF00)
- Read from DTIM_BASE (0x80000000)

### 2. `single_read_test.bin` (20 bytes)
Single STL read transaction:
```
"stl+" + TileLink Get packet for address 0x10020000
```

### 3. `single_write_test.bin` (20 bytes)  
Single STL write transaction:
```
"stl+" + TileLink PutFullData packet for address 0x10020000, data=0x12345678
```

## Packet Format Analysis

Each STL command follows this format:
```
Bytes 0-3:   "stl+" (0x73, 0x74, 0x6C, 0x2B)
Bytes 4-19:  TileLink packet (16 bytes, little endian format)
```

### Example: Single Read Test
```
00000000  73 74 6c 2b 00 04 02 ff  00 00 02 10 00 00 00 00  |stl+............|
00000010  00 00 00 00                                       |....|
```

Breakdown:
- `73 74 6c 2b`: "stl+" prefix
- `00`: Channel ID (0 = Channel A)
- `04`: Opcode (4 = Get operation)  
- `02`: Size (2 = log2(4) for 4-byte transfer)
- `ff`: Mask (0xFF = all bytes enabled)
- `00 00 02 10`: Address 0x10020000 (little endian)
- `00 00 00 00 00 00 00 00`: Data field (unused for reads)

### Example: Single Write Test
```
00000000  73 74 6c 2b 00 00 02 ff  00 00 02 10 78 56 34 12  |stl+........xV4.|
00000010  00 00 00 00                                       |....|
```

Breakdown:
- `73 74 6c 2b`: "stl+" prefix
- `00`: Channel ID (0 = Channel A)
- `00`: Opcode (0 = PutFullData operation)
- `02`: Size (2 = log2(4) for 4-byte transfer)
- `ff`: Mask (0xFF = all bytes enabled)
- `00 00 02 10`: Address 0x10020000 (little endian)
- `78 56 34 12 00 00 00 00`: Data 0x12345678 (little endian, zero-extended to 64-bit)

## Using in Vivado Simulation

1. **Set up testbench**: Use `scumv_controller_integration_tb.v`
2. **File parameter**: The testbench looks for `sim_input.bin` by default
3. **Change test file**: Modify `TEST_VECTOR_FILE` parameter to use different test vectors
4. **Expected behavior**:
   - UART handler should detect "stl+" prefix
   - LED[2] should go high (STL mode active)
   - STL subsystem should process TileLink packets
   - Responses should be generated (though mocked in this test)

## Verification Points

- [ ] UART receives all bytes correctly
- [ ] Prefix detection works ("stl+" vs other patterns)
- [ ] STL mode activation (LED[2] = 1)
- [ ] Packet unpacking in uart_to_tilelink_bridge
- [ ] TileLink frame generation
- [ ] State machine transitions
- [ ] Response path (if TileLink mock is added)

## Next Steps

1. Run simulation with single test first: `single_read_test.bin`
2. Verify basic functionality works
3. Move to comprehensive test: `sim_input.bin`
4. Add TileLink response mocking if needed
5. Verify response packet format matches tl_host.py expectations