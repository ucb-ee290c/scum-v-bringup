/*
 * SerialTL Subsystem
 * 
 * This module encapsulates all STL-related functionality, including the
 * STL UART client, UART-to-TileLink bridge, TileLink-to-UART bridge,
 * and the ASIC-provided GenericSerializer/GenericDeserializer modules.
 * It provides a clean FIFO-based interface to the UART handler.
 */

module serialtl_subsystem #(
    parameter CLOCK_FREQ = 100_000_000
)(
    input wire clk,
    input wire reset,
    
    // FIFO interface from UART handler
    input wire data_valid,
    output wire data_ready,
    input wire [7:0] data_in,
    
    // FIFO interface to UART handler (response)
    output wire response_valid,
    input wire response_ready,
    output wire [7:0] response_data,
    
    // SerialTL interface to SCuM-V
    input wire tl_clk,
    input wire tl_in_valid,
    output wire tl_in_ready,
    input wire tl_in_data,
    output wire tl_out_valid,
    input wire tl_out_ready,
    output wire tl_out_data
);

    // Internal packet interface signals
    wire [127:0] packet_data; // 16 bytes
    wire packet_valid;
    wire packet_ready;
    wire [127:0] tl_response_data; // 16 bytes
    wire tl_response_valid;
    wire tl_response_ready;
    
    // TileLink serializer/deserializer interface signals
    wire tl_ser_in_ready;
    wire tl_ser_in_valid;
    wire [2:0] tl_ser_in_bits_chanId;
    wire [2:0] tl_ser_in_bits_opcode;
    wire [2:0] tl_ser_in_bits_param;
    wire [7:0] tl_ser_in_bits_size;
    wire [7:0] tl_ser_in_bits_source;
    wire [63:0] tl_ser_in_bits_address;
    wire [63:0] tl_ser_in_bits_data;
    wire tl_ser_in_bits_corrupt;
    wire [8:0] tl_ser_in_bits_union;
    wire tl_ser_in_bits_last;
    wire tl_ser_out_ready;
    wire tl_ser_out_valid;
    wire tl_ser_out_bits;
    
    wire tl_deser_in_ready;
    wire tl_deser_in_valid;
    wire tl_deser_in_bits;
    wire tl_deser_out_ready;
    wire tl_deser_out_valid;
    wire [2:0] tl_deser_out_bits_chanId;
    wire [2:0] tl_deser_out_bits_opcode;
    wire [2:0] tl_deser_out_bits_param;
    wire [7:0] tl_deser_out_bits_size;
    wire [7:0] tl_deser_out_bits_source;
    wire [63:0] tl_deser_out_bits_address;
    wire [63:0] tl_deser_out_bits_data;
    wire tl_deser_out_bits_corrupt;
    wire [8:0] tl_deser_out_bits_union;

    // STL UART Client - handles byte-level FIFO interface
    stl_uart_client stl_client (
        .clk(clk),
        .reset(reset),
        
        // Interface from UART handler
        .data_valid(data_valid),
        .data_ready(data_ready),
        .data_in(data_in),
        
        // Interface to UART handler (response)
        .response_valid(response_valid),
        .response_ready(response_ready),
        .response_data(response_data),
        
        // Interface to UART-to-TileLink bridge
        .packet_valid(packet_valid),
        .packet_ready(packet_ready),
        .packet_data(packet_data),
        
        // Interface from TileLink-to-UART bridge
        .tl_response_valid(tl_response_valid),
        .tl_response_ready(tl_response_ready),
        .tl_response_data(tl_response_data)
    );

    // UART to TileLink Bridge - unpacks 16-byte packets to TileLink frames
    uart_to_tilelink_bridge uart_to_tl (
        .clk(clk),
        .reset(reset),
        
        // Interface from STL UART client
        .packet_valid(packet_valid),
        .packet_ready(packet_ready),
        .packet_data(packet_data),
        
        // Interface to GenericSerializer
        .tl_in_valid(tl_ser_in_valid),
        .tl_in_ready(tl_ser_in_ready),
        .tl_in_bits_chanId(tl_ser_in_bits_chanId),
        .tl_in_bits_opcode(tl_ser_in_bits_opcode),
        .tl_in_bits_param(tl_ser_in_bits_param),
        .tl_in_bits_size(tl_ser_in_bits_size),
        .tl_in_bits_source(tl_ser_in_bits_source),
        .tl_in_bits_address(tl_ser_in_bits_address),
        .tl_in_bits_data(tl_ser_in_bits_data),
        .tl_in_bits_corrupt(tl_ser_in_bits_corrupt),
        .tl_in_bits_union(tl_ser_in_bits_union),
        .tl_in_bits_last(tl_ser_in_bits_last)
    );

    // GenericSerializer - ASIC-provided module for TileLink serialization
    GenericSerializer tl_serializer (
        .clock(tl_clk),
        .reset(reset),
        
        // Input from UART-to-TileLink bridge
        .io_in_ready(tl_ser_in_ready),
        .io_in_valid(tl_ser_in_valid),
        .io_in_bits_chanId(tl_ser_in_bits_chanId),
        .io_in_bits_opcode(tl_ser_in_bits_opcode),
        .io_in_bits_param(tl_ser_in_bits_param),
        .io_in_bits_size(tl_ser_in_bits_size),
        .io_in_bits_source(tl_ser_in_bits_source),
        .io_in_bits_address(tl_ser_in_bits_address),
        .io_in_bits_data(tl_ser_in_bits_data),
        .io_in_bits_corrupt(tl_ser_in_bits_corrupt),
        .io_in_bits_union(tl_ser_in_bits_union),
        .io_in_bits_last(tl_ser_in_bits_last),
        
        // Output to SerialTL interface
        .io_out_ready(tl_out_ready),
        .io_out_valid(tl_out_valid),
        .io_out_bits(tl_out_data)
    );

    // GenericDeserializer - ASIC-provided module for TileLink deserialization
    GenericDeserializer tl_deserializer (
        .clock(tl_clk),
        .reset(reset),
        
        // Input from SerialTL interface
        .io_in_ready(tl_in_ready),
        .io_in_valid(tl_in_valid),
        .io_in_bits(tl_in_data),
        
        // Output to TileLink-to-UART bridge
        .io_out_ready(tl_deser_out_ready),
        .io_out_valid(tl_deser_out_valid),
        .io_out_bits_chanId(tl_deser_out_bits_chanId),
        .io_out_bits_opcode(tl_deser_out_bits_opcode),
        .io_out_bits_param(tl_deser_out_bits_param),
        .io_out_bits_size(tl_deser_out_bits_size),
        .io_out_bits_source(tl_deser_out_bits_source),
        .io_out_bits_address(tl_deser_out_bits_address),
        .io_out_bits_data(tl_deser_out_bits_data),
        .io_out_bits_corrupt(tl_deser_out_bits_corrupt),
        .io_out_bits_union(tl_deser_out_bits_union)
    );

    // TileLink to UART Bridge - packs TileLink frames to 16-byte packets
    tilelink_to_uart_bridge tl_to_uart (
        .clk(clk),
        .reset(reset),
        
        // Interface from GenericDeserializer
        .tl_out_valid(tl_deser_out_valid),
        .tl_out_ready(tl_deser_out_ready),
        .tl_out_bits_chanId(tl_deser_out_bits_chanId),
        .tl_out_bits_opcode(tl_deser_out_bits_opcode),
        .tl_out_bits_param(tl_deser_out_bits_param),
        .tl_out_bits_size(tl_deser_out_bits_size),
        .tl_out_bits_source(tl_deser_out_bits_source),
        .tl_out_bits_address(tl_deser_out_bits_address),
        .tl_out_bits_data(tl_deser_out_bits_data),
        .tl_out_bits_corrupt(tl_deser_out_bits_corrupt),
        .tl_out_bits_union(tl_deser_out_bits_union),
        
        // Interface to STL UART client
        .response_valid(tl_response_valid),
        .response_ready(tl_response_ready),
        .response_data(tl_response_data)
    );

endmodule