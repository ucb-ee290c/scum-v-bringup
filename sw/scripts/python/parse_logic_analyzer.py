import argparse
import csv

# TileLink Channel IDs
TL_CHANID_CH_A = 0
TL_CHANID_CH_D = 3

# TileLink Opcodes
TL_OPCODE_A_PUTFULLDATA = 0
TL_OPCODE_A_GET = 4
TL_OPCODE_D_ACCESSACK = 0
TL_OPCODE_D_ACCESSACKDATA = 1

# SERDES constants from tilelink.h
TL_SERDES_LAST_SIZE       = 1
TL_SERDES_LAST_OFFSET     = 0
TL_SERDES_UNION_SIZE      = 9
TL_SERDES_UNION_OFFSET    = TL_SERDES_LAST_OFFSET + TL_SERDES_LAST_SIZE
TL_SERDES_CORRUPT_SIZE    = 1
TL_SERDES_CORRUPT_OFFSET  = TL_SERDES_UNION_OFFSET + TL_SERDES_UNION_SIZE
TL_SERDES_DATA_SIZE       = 64
TL_SERDES_DATA_OFFSET     = TL_SERDES_CORRUPT_OFFSET + TL_SERDES_CORRUPT_SIZE
TL_SERDES_ADDRESS_SIZE    = 64
TL_SERDES_ADDRESS_OFFSET  = TL_SERDES_DATA_OFFSET + TL_SERDES_DATA_SIZE
TL_SERDES_SOURCE_SIZE     = 8
TL_SERDES_SOURCE_OFFSET   = TL_SERDES_ADDRESS_OFFSET + TL_SERDES_ADDRESS_SIZE
TL_SERDES_SIZE_SIZE       = 8
TL_SERDES_SIZE_OFFSET     = TL_SERDES_SOURCE_OFFSET + TL_SERDES_SOURCE_SIZE
TL_SERDES_PARAM_SIZE      = 3
TL_SERDES_PARAM_OFFSET    = TL_SERDES_SIZE_OFFSET + TL_SERDES_SIZE_SIZE
TL_SERDES_OPCODE_SIZE     = 3
TL_SERDES_OPCODE_OFFSET   = TL_SERDES_PARAM_OFFSET + TL_SERDES_PARAM_SIZE
TL_SERDES_CHANID_SIZE     = 3
TL_SERDES_CHANID_OFFSET   = TL_SERDES_OPCODE_OFFSET + TL_SERDES_OPCODE_SIZE
TL_SERDES_TOTAL_SIZE      = TL_SERDES_CHANID_OFFSET + TL_SERDES_CHANID_SIZE


def bits_to_int(bits):
    """Converts a list of bits (0s and 1s) to an integer."""
    val = 0
    for bit in reversed(bits):
        val = (val << 1) | bit
    return val

def get_opcode_name(chanid: int, opcode: int) -> str:
    """Returns the human-readable name for TileLink opcodes."""
    if chanid == TL_CHANID_CH_A:
        if opcode == TL_OPCODE_A_PUTFULLDATA:
            return "PutFullData"
        elif opcode == TL_OPCODE_A_GET:
            return "Get"
        else:
            return f"Unknown Ch A opcode {opcode}"
    elif chanid == TL_CHANID_CH_D:
        if opcode == TL_OPCODE_D_ACCESSACK:
            return "AccessAck"
        elif opcode == TL_OPCODE_D_ACCESSACKDATA:
            return "AccessAckData"
        else:
            return f"Unknown Ch D opcode {opcode}"
    else:
        return f"Unknown channel {chanid}"

def deserialize_frame(bits):
    """Deserializes a list of 164 bits into a TileLink frame dictionary."""
    if len(bits) != TL_SERDES_TOTAL_SIZE:
        raise ValueError(f"Expected {TL_SERDES_TOTAL_SIZE} bits, but got {len(bits)}")

    # Slice the bitstream according to offsets from tilelink.h
    last_bits     = bits[TL_SERDES_LAST_OFFSET:TL_SERDES_LAST_OFFSET+TL_SERDES_LAST_SIZE]
    union_bits    = bits[TL_SERDES_UNION_OFFSET:TL_SERDES_UNION_OFFSET+TL_SERDES_UNION_SIZE]
    corrupt_bits  = bits[TL_SERDES_CORRUPT_OFFSET:TL_SERDES_CORRUPT_OFFSET+TL_SERDES_CORRUPT_SIZE]
    data_bits     = bits[TL_SERDES_DATA_OFFSET:TL_SERDES_DATA_OFFSET+TL_SERDES_DATA_SIZE]
    address_bits  = bits[TL_SERDES_ADDRESS_OFFSET:TL_SERDES_ADDRESS_OFFSET+TL_SERDES_ADDRESS_SIZE]
    source_bits   = bits[TL_SERDES_SOURCE_OFFSET:TL_SERDES_SOURCE_OFFSET+TL_SERDES_SOURCE_SIZE]
    size_bits     = bits[TL_SERDES_SIZE_OFFSET:TL_SERDES_SIZE_OFFSET+TL_SERDES_SIZE_SIZE]
    param_bits    = bits[TL_SERDES_PARAM_OFFSET:TL_SERDES_PARAM_OFFSET+TL_SERDES_PARAM_SIZE]
    opcode_bits   = bits[TL_SERDES_OPCODE_OFFSET:TL_SERDES_OPCODE_OFFSET+TL_SERDES_OPCODE_SIZE]
    chanid_bits   = bits[TL_SERDES_CHANID_OFFSET:TL_SERDES_CHANID_OFFSET+TL_SERDES_CHANID_SIZE]

    # Convert bit lists to integers
    return {
        'chanid':   bits_to_int(chanid_bits),
        'opcode':   bits_to_int(opcode_bits),
        'param':    bits_to_int(param_bits),
        'size':     bits_to_int(size_bits),
        'source':   bits_to_int(source_bits),
        'address':  bits_to_int(address_bits),
        'data':     bits_to_int(data_bits),
        'corrupt':  bits_to_int(corrupt_bits),
        'tl_union': bits_to_int(union_bits),
        'last':     bits_to_int(last_bits),
    }

def print_frame(frame, direction):
    """Pretty-prints a deserialized TileLink frame."""
    print(f"--- Decoded {direction} Frame ---")
    chanid = frame['chanid']
    opcode = frame['opcode']
    
    print(f"  Channel ID: {chanid}")
    print(f"  Opcode:     {opcode} ({get_opcode_name(chanid, opcode)})")
    print(f"  Param:      {frame['param']}")
    print(f"  Size:       {frame['size']} (2^{frame['size']} bytes)")
    print(f"  Source:     {frame['source']}")
    print(f"  Address:    0x{frame['address']:08X}")
    print(f"  Data:       0x{frame['data']:016X}")
    print(f"  Corrupt:    {bool(frame['corrupt'])}")

    if chanid == TL_CHANID_CH_A:
        mask = frame['tl_union'] & 0xF
        print(f"  Mask:       0b{mask:04b}")
    elif chanid == TL_CHANID_CH_D:
        denied = bool(frame['tl_union'] & 0b1)
        print(f"  Denied:     {denied}")
    print(f"  Last:       {bool(frame['last'])}")
    print("-" * (len(direction) + 25))


def detect_columns(header_row):
    """
    Auto-detects column names from the CSV header using a list of known aliases.
    Returns a dictionary of detected column names.
    Raises ValueError if a required column cannot be found.
    """
    # Canonical names and their possible aliases in the CSV header
    COLUMN_ALIASES = {
        'clk': ['TL_CLK'],
        'in_valid': ['TL_IN_VALID', 'TL_IN_VAL'],
        'in_ready': ['TL_IN_READY', 'TL_IN_RDY'],
        'in_data': ['TL_IN_DATA'],
        'out_valid': ['TL_OUT_VALID', 'TL_OUT_VAL'],
        'out_ready': ['TL_OUT_READY', 'TL_OUT_RDY'],
        'out_data': ['TL_OUT_DATA'],
    }

    # Normalize the actual header for case-insensitive matching
    # Maps a lowercase, stripped header name to its original form
    header_map = {h.strip().lower(): h.strip() for h in header_row}

    detected_cols = {}
    missing = []

    for canonical, aliases in COLUMN_ALIASES.items():
        found_alias = None
        for alias in aliases:
            if alias.lower() in header_map:
                found_alias = header_map[alias.lower()]
                break
        
        if found_alias:
            detected_cols[canonical] = found_alias
        else:
            missing.append(f"'{canonical}' (e.g. {', '.join(aliases)})")

    if missing:
        raise ValueError(
            f"Could not automatically detect the following required columns: {', '.join(missing)}.\n"
            f"Please check the CSV file header. Available columns: {header_row}"
        )

    return detected_cols


def parse_transactions(data_rows, clk_col, valid_col, ready_col, data_col):
    """
    Parses a list of CSV rows and yields lists of bits for each transaction.
    A transaction is defined by VALID and READY being high on a rising CLK edge.
    """
    bits = []
    prev_clk = 0
    for row in data_rows:
        # Saleae CSVs can have non-numeric values for time, handle this
        try:
            clk = int(float(row[clk_col]))
            valid = int(float(row[valid_col]))
            ready = int(float(row[ready_col]))
            data = int(float(row[data_col]))
        except (ValueError, TypeError):
            continue

        is_rising_edge = (clk == 1 and prev_clk == 0)

        if is_rising_edge and valid and ready:
            bits.append(data)
            if len(bits) == TL_SERDES_TOTAL_SIZE:
                yield bits
                bits = []
        
        prev_clk = clk
    
    if bits:
        print(f"Warning: Incomplete final frame, got {len(bits)}/{TL_SERDES_TOTAL_SIZE} bits.")

def main():
    """Main entry point for the script."""
    parser = argparse.ArgumentParser(
        description="Parse TileLink frames from a Saleae Logic Analyzer CSV export.\n"
                    "This script automatically detects the required signal columns based on common names.",
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument(
        "csv_file",
        help="Path to the digital.csv file."
    )
    args = parser.parse_args()

    try:
        with open(args.csv_file, 'r', newline='') as f:
            reader = csv.DictReader(f)
            # Auto-detect column names from the header
            cols = detect_columns(reader.fieldnames)
            # Read all data into memory so we can iterate over it twice
            data_rows = list(reader)

    except FileNotFoundError:
        print(f"Error: File not found at '{args.csv_file}'")
        print("Please ensure you have exported 'digital.csv' from your logic analyzer and placed it in the correct path.")
        return
    except ValueError as e:
        print(f"Error: {e}")
        return

    print(f"Successfully detected all required columns: {list(cols.values())}")
    
    print(f"\nParsing IN transactions (STM32 -> FPGA) from {args.csv_file}...")
    found_in = False
    for bits in parse_transactions(data_rows, cols['clk'], cols['in_valid'], cols['in_ready'], cols['in_data']):
        frame = deserialize_frame(bits)
        print_frame(frame, "IN")
        found_in = True
    if not found_in:
        print("No IN transactions found.")

    print(f"\nParsing OUT transactions (FPGA -> STM32) from {args.csv_file}...")
    found_out = False
    for bits in parse_transactions(data_rows, cols['clk'], cols['out_valid'], cols['out_ready'], cols['out_data']):
        frame = deserialize_frame(bits)
        print_frame(frame, "OUT")
        found_out = True
    if not found_out:
        print("No OUT transactions found.")

if __name__ == "__main__":
    main() 