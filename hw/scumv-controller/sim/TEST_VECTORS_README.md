# STL Test Vectors for RTL Simulation

## Generated Files (placed in this folder)

- `stl_read_1pkt.bin`: Single STL Get
- `stl_write_1pkt.bin`: Single STL PutFullData
- `stl_mixed_5pkts.bin`: Mixed small set for smoke-testing
- `stl_flash_20pkts.bin`: Short flash-like sequence
- `stl_flash_stress_4096pkts.bin`: Large stress sequence (batched)

All vectors are a concatenation of `"stl+"` (4 bytes) + 16-byte TileLink payloads.

## How to generate vectors

Use `sw/tl_host_sim.py` to generate files directly:

```bash
# Single packet examples
python sw/tl_host_sim.py --test-read 0x10020000 -o hw/scumv-controller/sim/stl_read_1pkt.bin
python sw/tl_host_sim.py --test-write 0x10020000 0x12345678 -o hw/scumv-controller/sim/stl_write_1pkt.bin

# Mixed set (example script may produce this during development)
python sw/tl_host_sim.py --generate-test-vectors -o hw/scumv-controller/sim/stl_mixed_5pkts.bin

# Flash-like streams
python sw/tl_host_sim.py --generate-flash-vectors --num-words 20 \
  --base-addr 0x80000000 --data-mode addr -o hw/scumv-controller/sim/stl_flash_20pkts.bin

python sw/tl_host_sim.py --generate-flash-vectors --num-words 4096 \
  --base-addr 0x80000000 --data-mode seq --start-data 0 \
  -o hw/scumv-controller/sim/stl_flash_stress_4096pkts.bin
```

Notes:
- Default simulated serial rate is 2,000,000 baud. The simulator only writes files; it does not require a serial port.
- Data patterns: `--data-mode addr` mirrors address; `--data-mode seq` increments from `--start-data`.

## Packet Format

Each STL command follows this format:
```
Bytes 0-3:   "stl+" (0x73, 0x74, 0x6C, 0x2B)
Bytes 4-19:  TileLink packet (16 bytes, little endian)
```

Example (single read):
```
00000000  73 74 6c 2b 00 04 02 ff  00 00 02 10 00 00 00 00  |stl+............|
00000010  00 00 00 00                                       |....|
```

## Using in Vivado Simulation

1. Testbench: `hw/scumv-controller/sim/scumv_controller_integration_tb.v`
2. Point the TB to a vector file by setting parameter `TEST_VECTOR_FILE`.
3. The TB runs UART at 2,000,000 baud and sends packets in batched, back-to-back fashion.
4. TB logs are mirrored to `scumv_controller_integration_tb.log` in this directory.

## Additional TB behaviors

- Backpressure model: TL input ready is deasserted one out of every four consumed bits to stress flow control.
- UART handshake is modeled to ensure byte-accurate transfers with minimal inter-byte gaps (configurable).