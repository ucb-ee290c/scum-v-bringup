/*
 * UART to TileLink Bridge
 * 
 * This module takes 16-byte TileLink packets from the STL UART client,
 * unpacks them into TileLink frame format, and feeds them to the
 * GenericSerializer for transmission to SCuM-V.
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

    // TODO: Implement packet unpacking and TileLink frame generation
    // For now, just tie off signals to prevent synthesis errors
    
    assign packet_ready = 1'b1;
    assign tl_in_valid = 1'b0;
    assign tl_in_bits_chanId = 3'h0;
    assign tl_in_bits_opcode = 3'h0;
    assign tl_in_bits_param = 3'h0;
    assign tl_in_bits_size = 8'h0;
    assign tl_in_bits_source = 8'h0;
    assign tl_in_bits_address = 64'h0;
    assign tl_in_bits_data = 64'h0;
    assign tl_in_bits_corrupt = 1'b0;
    assign tl_in_bits_union = 9'h0;
    assign tl_in_bits_last = 1'b1;

endmodule