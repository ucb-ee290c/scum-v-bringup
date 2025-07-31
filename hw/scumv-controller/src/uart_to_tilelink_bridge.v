/*
 * UART to TileLink Bridge
 * 
 * This module receives 16-byte TileLink packets from the STL UART client,
 * unpacks them according to the tl_host.py format, and generates TileLink
 * frame signals for the GenericSerializer module.
 * 
 * Packet format from tl_host.py struct.pack("<BBBBLQ", ...):
 * Byte 0: Channel ID (0=Ch A, 3=Ch D)
 * Byte 1: Packed opcode (opcode[2:0], param[6:4], corrupt[7])
 * Byte 2: Size (log2 of transfer size)
 * Byte 3: Union field (mask for Ch A, denied for Ch D)
 * Bytes 4-7: Address (32-bit little endian)
 * Bytes 8-15: Data (64-bit little endian)
 * 
 * NOTE: Potential inconsistency - tl_host.py sends 8-bit union field,
 * but FPGA interface expects 9-bit tl_in_bits_union. Zero-extending.
 */

module uart_to_tilelink_bridge (
    input wire clk,
    input wire reset,
    
    // Interface from STL UART client
    input wire packet_valid,
    output wire packet_ready,
    input wire [127:0] packet_data, // 16 bytes
    
    // Interface to GenericSerializer
    output wire tl_in_valid,
    input wire tl_in_ready,
    output wire [2:0] tl_in_bits_chanId,
    output wire [2:0] tl_in_bits_opcode,
    output wire [2:0] tl_in_bits_param,
    output wire [7:0] tl_in_bits_size,
    output wire [7:0] tl_in_bits_source,
    output wire [63:0] tl_in_bits_address,
    output wire [63:0] tl_in_bits_data,
    output wire tl_in_bits_corrupt,
    output wire [8:0] tl_in_bits_union,
    output wire tl_in_bits_last
);

    // State machine for packet processing
    localparam STATE_IDLE = 1'b0;
    localparam STATE_FRAME_READY = 1'b1;
    
    reg state, next_state;
    
    // Packet unpacking registers
    reg [127:0] packet_buffer;
    reg frame_valid_reg;
    
    // Unpacked fields
    wire [7:0] channel_id;
    wire [7:0] opcode_packed;
    wire [7:0] size_field;
    wire [7:0] union_field;
    wire [31:0] address_field;
    wire [63:0] data_field;
    
    // Opcode field unpacking (from tl_host.py)
    wire [2:0] opcode;
    wire [2:0] param;
    wire corrupt;
    
    // State machine
    always @(posedge clk) begin
        if (reset) begin
            state <= STATE_IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        
        case (state)
            STATE_IDLE: begin
                if (packet_valid) begin
                    next_state = STATE_FRAME_READY;
                end
            end
            
            STATE_FRAME_READY: begin
                if (tl_in_ready) begin
                    next_state = STATE_IDLE;
                end
            end
        endcase
    end
    
    // Packet buffer and unpacking
    always @(posedge clk) begin
        if (reset) begin
            packet_buffer <= 128'h0;
            frame_valid_reg <= 1'b0;
        end else if (state == STATE_IDLE && packet_valid) begin
            // Capture incoming packet
            packet_buffer <= packet_data;
            frame_valid_reg <= 1'b1;
        end else if (state == STATE_FRAME_READY && tl_in_ready) begin
            // Frame consumed, clear valid
            frame_valid_reg <= 1'b0;
        end
    end
    
    // Unpack packet fields (little endian format)
    // Note: packet_buffer[7:0] is the first byte (channel_id)
    assign channel_id = packet_buffer[7:0];           // Byte 0
    assign opcode_packed = packet_buffer[15:8];       // Byte 1
    assign size_field = packet_buffer[23:16];         // Byte 2
    assign union_field = packet_buffer[31:24];        // Byte 3
    
    // Address: bytes 4-7 (little endian)
    assign address_field = {packet_buffer[63:56],     // Byte 7 (MSB)
                           packet_buffer[55:48],     // Byte 6
                           packet_buffer[47:40],     // Byte 5
                           packet_buffer[39:32]};    // Byte 4 (LSB)
    
    // Data: bytes 8-15 (little endian)
    assign data_field = {packet_buffer[127:120],      // Byte 15 (MSB)
                        packet_buffer[119:112],       // Byte 14
                        packet_buffer[111:104],       // Byte 13
                        packet_buffer[103:96],        // Byte 12
                        packet_buffer[95:88],         // Byte 11
                        packet_buffer[87:80],         // Byte 10
                        packet_buffer[79:72],         // Byte 9
                        packet_buffer[71:64]};        // Byte 8 (LSB)
    
    // Unpack opcode field (from tl_host.py opcode_packed format)
    // Bit layout: corrupt[7], param[6:4], unused[3], opcode[2:0]
    assign opcode = opcode_packed[2:0];               // Bits [2:0]
    assign param = opcode_packed[6:4];                // Bits [6:4]
    assign corrupt = opcode_packed[7];                // Bit [7]
    
    // Output assignments
    assign packet_ready = (state == STATE_IDLE);
    
    assign tl_in_valid = frame_valid_reg;
    assign tl_in_bits_chanId = channel_id[2:0];       // Only 3 bits for channel ID
    assign tl_in_bits_opcode = opcode;
    assign tl_in_bits_param = param;
    assign tl_in_bits_size = size_field;
    assign tl_in_bits_source = 8'h00;                 // Source is always 0 for host transactions
    assign tl_in_bits_address = {32'h00000000, address_field}; // Extend 32-bit to 64-bit
    assign tl_in_bits_data = data_field;
    assign tl_in_bits_corrupt = corrupt;
    assign tl_in_bits_union = {1'b0, union_field};    // Zero-extend 8-bit to 9-bit
    assign tl_in_bits_last = 1'b1;                    // Always last for single-beat transactions

endmodule