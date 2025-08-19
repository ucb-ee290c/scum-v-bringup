/*
 * UART to TileLink Bridge
 *
 * Clean Mealy-style implementation with proper CDC.
 *
 * - Cross the 16-byte packet from sysclk -> tl_clk using a toggle-based
 *   valid/ready CDC synchronizer (see cdc_synchronizer).
 * - Unpack and present the TileLink frame entirely in the tl_clk domain.
 * - Perform the valid/ready handshake locally with GenericSerializer.
 *
 * This guarantees stable data while valid is asserted and removes any
 * dependency on sampling tl_clk in the sysclk domain. Since tl_clk is
 * always slower than sysclk, this design naturally tolerates rate differences.
 *
 * Packet format from tl_host.py struct.pack("<BBBBLQ", ...):
 *  Byte 0: Channel ID (0=Ch A, 3=Ch D)
 *  Byte 1: Packed opcode (opcode[2:0], param[6:4], corrupt[7])
 *  Byte 2: Size (log2 of transfer size)
 *  Byte 3: Union field (mask for Ch A, denied for Ch D)
 *  Bytes 4-7: Address (32-bit little endian)
 *  Bytes 8-15: Data (64-bit little endian)
 *
 * NOTE: tl_host.py sends 8-bit union; ASIC expects 9-bit union. We zero-extend.
 */

module uart_to_tilelink_bridge (
    input wire sysclk,
    input wire reset,
    input wire tl_clk,
    
    // Interface from STL UART client (sysclk domain)
    input wire packet_valid,
    output wire packet_ready,
    input wire [127:0] packet_data, // 16 bytes
    
    // Interface to GenericSerializer (tl_clk domain)
    output wire tl_ser_in_valid,
    input wire tl_ser_in_ready,
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

    // --------------------------------------------------------------------
    // CDC: move the 16-byte packet from sysclk -> tl_clk
    // --------------------------------------------------------------------
    wire [127:0] tl_pkt_data;   // tl_clk domain copy of the packet
    wire         tl_pkt_valid;  // tl_clk domain valid for the packet
    wire         tl_pkt_ready;  // tl_clk domain ready when consumed

    cdc_synchronizer #(
        .WIDTH(128)
    ) packet_cdc (
        .src_clk(sysclk),
        .dst_clk(tl_clk),
        .reset(reset),
        .src_data(packet_data),
        .src_valid(packet_valid),
        .src_ready(packet_ready),
        .dst_data(tl_pkt_data),
        .dst_valid(tl_pkt_valid),
        .dst_ready(tl_pkt_ready)
    );

    // --------------------------------------------------------------------
    // tl_clk domain: Mealy-style single-beat frame issue to GenericSerializer
    // --------------------------------------------------------------------
    // Unpack fields from the CDC'd packet. While tl_pkt_valid is asserted,
    // tl_pkt_data remains stable by construction of the CDC synchronizer.
    wire [7:0] channel_id;
    wire [7:0] opcode_packed;
    wire [7:0] size_field;
    wire [7:0] union_field;
    wire [31:0] address_field;
    wire [63:0] data_field;
    wire [2:0] opcode;
    wire [2:0] param;
    wire       corrupt;

    // Byte lanes (little endian in packet)
    assign channel_id   = tl_pkt_data[7:0];
    assign opcode_packed= tl_pkt_data[15:8];
    assign size_field   = tl_pkt_data[23:16];
    assign union_field  = tl_pkt_data[31:24];

    assign address_field = {tl_pkt_data[63:56],
                            tl_pkt_data[55:48],
                            tl_pkt_data[47:40],
                            tl_pkt_data[39:32]};

    assign data_field = {tl_pkt_data[127:120],
                         tl_pkt_data[119:112],
                         tl_pkt_data[111:104],
                         tl_pkt_data[103:96],
                         tl_pkt_data[95:88],
                         tl_pkt_data[87:80],
                         tl_pkt_data[79:72],
                         tl_pkt_data[71:64]};

    // opcode_packed layout: corrupt[7], param[6:4], unused[3], opcode[2:0]
    assign opcode  = opcode_packed[2:0];
    assign param   = opcode_packed[6:4];
    assign corrupt = opcode_packed[7];

    // Mealy handshake: valid mirrors tl_pkt_valid, ready mirrors serializer ready
    assign tl_ser_in_valid   = tl_pkt_valid;
    assign tl_pkt_ready      = tl_ser_in_ready & tl_ser_in_valid; // consume exactly when accepted

    // Drive serializer inputs directly from the unpacked fields
    assign tl_in_bits_chanId = channel_id[2:0];
    assign tl_in_bits_opcode = opcode;
    assign tl_in_bits_param  = param;
    assign tl_in_bits_size   = size_field;
    assign tl_in_bits_source = 8'h00; // Host source ID = 0
    assign tl_in_bits_address= {32'h00000000, address_field};
    assign tl_in_bits_data   = data_field;
    assign tl_in_bits_corrupt= corrupt;
    assign tl_in_bits_union  = {1'b0, union_field};
    assign tl_in_bits_last   = 1'b1;  // single-beat transactions

endmodule