/*
 * TileLink to UART Bridge
 * 
 * This module receives TileLink frames from the GenericDeserializer,
 * packs them into 16-byte packets matching tl_host.py format, and sends
 * them back to the STL UART client for transmission to the host.
 * 
 * Response packet format (same as tl_host.py struct.pack("<BBBBLQ", ...)):
 * Byte 0: Channel ID (typically 3 for Channel D responses)
 * Byte 1: Packed opcode (opcode[2:0], param[6:4], corrupt[7])
 * Byte 2: Size (log2 of transfer size)
 * Byte 3: Union field (denied flag for Ch D, mask for Ch A)
 * Bytes 4-7: Address (32-bit little endian)
 * Bytes 8-15: Data (64-bit little endian)
 * 
 * NOTE: Same inconsistencies as uart_to_tilelink_bridge - 9-bit union
 * truncated to 8 bits, 64-bit address truncated to 32 bits.
 */

module tilelink_to_uart_bridge (
    input wire clk,
    input wire reset,
    input wire tl_clk,
    
    // Interface from GenericDeserializer
    input wire tl_out_valid,
    output wire tl_out_ready,
    input wire [2:0] tl_out_bits_chanId,
    input wire [2:0] tl_out_bits_opcode,
    input wire [2:0] tl_out_bits_param,
    input wire [7:0] tl_out_bits_size,
    input wire [7:0] tl_out_bits_source,
    input wire [63:0] tl_out_bits_address,
    input wire [63:0] tl_out_bits_data,
    input wire tl_out_bits_corrupt,
    input wire [8:0] tl_out_bits_union,
    
    // Interface to STL UART client
    output wire response_valid,
    input wire response_ready,
    output wire [127:0] response_data // 16 bytes
);

    // State machine for response packing
    localparam STATE_IDLE = 2'b00;
    localparam STATE_RESPONSE_READY = 2'b01;
    localparam STATE_RESPONSE_DOWNTIME = 2'b10;
    
    reg [1:0] state, next_state;
    
    // Response packing registers
    reg [127:0] response_buffer;
    reg response_valid_reg;
    
    // Packed fields
    wire [7:0] opcode_packed;
    wire [31:0] address_truncated;
    wire [7:0] union_truncated;

    reg tl_clk_buf; 
    
    // State machine
    always @(posedge clk) begin
        if (reset) begin
            state <= STATE_IDLE;
        end else begin
            state <= next_state;
        end
        tl_clk_buf <= tl_clk;
    end
    reg tl_clk_posedge;
    // Next state logic
    always @(*) begin
        next_state = state;
        tl_clk_posedge = tl_clk && !tl_clk_buf;
        case (state)
            STATE_IDLE: begin
                if (tl_out_valid) begin
                    next_state = STATE_RESPONSE_READY;
                end
            end
            
            STATE_RESPONSE_READY: begin
                if (response_ready) begin
                    next_state = STATE_RESPONSE_DOWNTIME;
                end
            end
            
            STATE_RESPONSE_DOWNTIME: begin
                if (tl_clk_posedge) begin
                    next_state = STATE_IDLE;
                end
            end
        endcase
    end
    
    // Pack opcode field to match tl_host.py format
    // Bit layout: corrupt[7], param[6:4], unused[3], opcode[2:0]
    assign opcode_packed = {tl_out_bits_corrupt,           // Bit [7]
                           tl_out_bits_param,              // Bits [6:4]
                           1'b0,                           // Bit [3] (unused)
                           tl_out_bits_opcode};            // Bits [2:0]
    
    // Truncate wider fields to match tl_host.py packet size
    assign address_truncated = tl_out_bits_address[31:0];  // 64-bit -> 32-bit
    assign union_truncated = tl_out_bits_union[7:0];       // 9-bit -> 8-bit
    
    // Response buffer packing and management
    always @(posedge clk) begin
        if (reset) begin
            response_buffer <= 128'h0;
            response_valid_reg <= 1'b0;
        end else if (state == STATE_IDLE && tl_out_valid) begin
            // Pack TileLink frame into 16-byte response packet (little endian)
            response_buffer <= {
                // Bytes 15-8: Data (64-bit little endian)
                tl_out_bits_data[63:56],   // Byte 15 (MSB)
                tl_out_bits_data[55:48],   // Byte 14
                tl_out_bits_data[47:40],   // Byte 13
                tl_out_bits_data[39:32],   // Byte 12
                tl_out_bits_data[31:24],   // Byte 11
                tl_out_bits_data[23:16],   // Byte 10
                tl_out_bits_data[15:8],    // Byte 9
                tl_out_bits_data[7:0],     // Byte 8 (LSB)
                
                // Bytes 7-4: Address (32-bit little endian)
                address_truncated[31:24],  // Byte 7 (MSB)
                address_truncated[23:16],  // Byte 6
                address_truncated[15:8],   // Byte 5
                address_truncated[7:0],    // Byte 4 (LSB)
                
                // Byte 3: Union field (denied/mask)
                union_truncated,           // Byte 3
                
                // Byte 2: Size
                tl_out_bits_size,          // Byte 2
                
                // Byte 1: Packed opcode
                opcode_packed,             // Byte 1
                
                // Byte 0: Channel ID
                {5'b00000, tl_out_bits_chanId} // Byte 0 (extend 3-bit to 8-bit)
            };
            response_valid_reg <= 1'b1;
        end else if (state == STATE_RESPONSE_READY && response_ready) begin
            // Response consumed, clear valid and transition to downtime
            response_valid_reg <= 1'b0;
        end
    end
    
    // Output assignments
    assign tl_out_ready = (state == STATE_IDLE) | (state == STATE_RESPONSE_DOWNTIME);
    assign response_valid = response_valid_reg;
    assign response_data = response_buffer;

endmodule