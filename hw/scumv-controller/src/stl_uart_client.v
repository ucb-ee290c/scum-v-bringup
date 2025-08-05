/*
 * STL UART Client
 * 
 * This module receives 16-byte TileLink packets from the UART handler,
 * buffers them into complete packets, and interfaces with the UART-to-TileLink bridge.
 * It also handles responses from the TileLink-to-UART bridge and streams them back
 * to the UART handler byte-by-byte.
 */

module stl_uart_client #(
    parameter CLOCK_FREQ = 100_000_000,
    parameter PACKET_SIZE = 16
)(
    input wire clk,
    input wire reset,
    
    // Interface from UART handler
    input wire data_valid,
    output wire data_ready,
    input wire [7:0] data_in,
    
    // Interface to UART handler (response)
    output wire response_valid,
    input wire response_ready,
    output wire [7:0] response_data,
    
    // Interface to UART-to-TileLink bridge
    output reg packet_valid,
    input wire packet_ready,
    output wire [127:0] packet_data, // 16 bytes = 128 bits
    
    // Interface from TileLink-to-UART bridge
    input wire tl_response_valid,
    output wire tl_response_ready,
    input wire [127:0] tl_response_data, // 16 bytes = 128 bits
    output wire [4:0] debug_byte_count,
    output wire [1:0] debug_state
);

    // Simplified Mealy FSM states
    localparam STATE_IDLE = 2'b00;     // Wait for first data byte
    localparam STATE_RECEIVE = 2'b01;  // Receive packet bytes, forward when complete
    localparam STATE_RESPOND = 2'b10;  // Stream response bytes back
    
    reg [1:0] state;
    assign debug_state = state;
    
    // Data storage registers
    reg [127:0] packet_buffer;
    reg [127:0] response_buffer;
    reg [4:0] byte_count; // Unified counter for both receive and response
    assign debug_byte_count = byte_count;
    
    // Mealy FSM: sequential logic for state transitions and data storage
    always @(posedge clk) begin
        if (reset) begin
            state <= STATE_IDLE;
            byte_count <= 0;
            packet_buffer <= 128'h0;
            response_buffer <= 128'h0;
            packet_valid <= 1'b0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    if (data_valid && data_ready) begin
                        state <= STATE_RECEIVE;
                        packet_buffer <= {120'h0, data_in}; // Store first byte
                        byte_count <= 1;
                    end
                end
                
                STATE_RECEIVE: begin
                    if (data_valid && data_ready) begin
                        packet_buffer <= {data_in, packet_buffer[127:8]}; // Shift in new byte (LSB first)
                        if (byte_count == PACKET_SIZE - 1) begin
                            // Packet complete, check if bridge is ready
                            if (packet_ready) begin
                                state <= STATE_RESPOND;
                                byte_count <= 0;
                                packet_valid <= 1'b1;
                            end else begin
                                byte_count <= byte_count + 1;
                            end
                        end else begin
                            byte_count <= byte_count + 1;
                        end
                    end else if (byte_count == PACKET_SIZE && packet_ready) begin
                        // Packet was completed last cycle, bridge now ready
                        packet_valid <= 1'b1;
                        state <= STATE_RESPOND;
                        byte_count <= 0;
                    end
                end
                
                STATE_RESPOND: begin
                    packet_valid <= 1'b0;
                    if (tl_response_valid && byte_count == 0) begin
                        // Capture response packet
                        response_buffer <= tl_response_data;
                        byte_count <= 1;
                    end else if (byte_count > 0 && response_ready) begin
                        // Stream out bytes
                        response_buffer <= {8'h00, response_buffer[127:8]}; // Shift right
                        if (byte_count == PACKET_SIZE) begin
                            // Last byte transmitted
                            state <= STATE_IDLE;
                            byte_count <= 0;
                        end else begin
                            byte_count <= byte_count + 1;
                        end
                    end
                end
                
                default: begin
                    state <= STATE_IDLE;
                    byte_count <= 0;
                end
            endcase
        end
    end
    
    // Mealy FSM: combinational outputs based on state and inputs
    assign data_ready = (state == STATE_IDLE) || (state == STATE_RECEIVE);
    

    assign packet_data = packet_buffer;
    
    assign response_valid = (state == STATE_RESPOND && byte_count > 0);
    assign response_data = response_buffer[7:0]; // LSB first
    
    assign tl_response_ready = (state == STATE_RESPOND && byte_count == 0);


endmodule