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
    output wire packet_valid,
    input wire packet_ready,
    output wire [127:0] packet_data, // 16 bytes = 128 bits
    
    // Interface from TileLink-to-UART bridge
    input wire tl_response_valid,
    output wire tl_response_ready,
    input wire [127:0] tl_response_data, // 16 bytes = 128 bits
    output wire [4:0] debug_byte_count,
    output wire [1:0] debug_state
);

    // State machine for packet assembly
    localparam STATE_IDLE = 2'b00;
    localparam STATE_RECEIVING = 2'b01;  
    localparam STATE_PACKET_READY = 2'b10;
    localparam STATE_RESPONSE = 2'b11;
    
    reg [1:0] state, next_state;
    assign debug_state = state;
    
    // Packet assembly registers
    reg [127:0] packet_buffer;
    reg [4:0] byte_count; // 0 to 15 for 16 bytes
    assign debug_byte_count = byte_count;
    
    // Response streaming registers
    reg [127:0] response_buffer;
    reg [4:0] response_byte_count; // 0 to 15 for 16 bytes
    reg response_active;
    
    // Packet interface registers
    reg packet_valid_reg;
    reg tl_response_ready_reg;
    
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
                if (data_valid) begin
                    next_state = STATE_RECEIVING;
                end
            end
            
            STATE_RECEIVING: begin
                if (byte_count == PACKET_SIZE) begin
                    next_state = STATE_PACKET_READY;
                end
            end
            
            STATE_PACKET_READY: begin
                if (packet_ready) begin
                    next_state = STATE_RESPONSE;
                end
            end
            
            STATE_RESPONSE: begin
                if (response_active && (response_byte_count == (PACKET_SIZE - 1)) && response_ready) begin
                    next_state = STATE_IDLE;
                end else if (tl_response_valid && !response_active) begin
                    // Start response streaming
                    next_state = STATE_RESPONSE;
                end
            end
        endcase
    end
    
    // Byte counter for packet assembly
    always @(posedge clk) begin
        if (reset) begin
            byte_count <= 0;
        end else if (state == STATE_IDLE && data_valid && data_ready) begin
            byte_count <= 1;
        end else if (state == STATE_RECEIVING && data_valid && data_ready) begin
            byte_count <= byte_count + 1;
        end else if (state == STATE_RESPONSE) begin
            byte_count <= 0;
        end
    end
    
    // Packet buffer assembly
    always @(posedge clk) begin
        if (reset) begin
            packet_buffer <= 128'h0;
        end else if (state == STATE_RECEIVING && data_valid && data_ready) begin
            // Shift in new byte (LSB first)
            packet_buffer <= {data_in, packet_buffer[127:8]};
        end
    end
    
    // Packet valid generation
    always @(posedge clk) begin
        if (reset) begin
            packet_valid_reg <= 1'b0;
        end else if (state == STATE_PACKET_READY) begin
            packet_valid_reg <= 1'b1;
        end else if (packet_ready) begin
            packet_valid_reg <= 1'b0;
        end
    end
    
    // Response handling
    always @(posedge clk) begin
        if (reset) begin
            response_buffer <= 128'h0;
            response_active <= 1'b0;
            response_byte_count <= 0;
            tl_response_ready_reg <= 1'b1;
        end else if (state == STATE_RESPONSE) begin
            if (tl_response_valid && !response_active) begin
                // Capture response packet
                response_buffer <= tl_response_data;
                response_active <= 1'b1;
                response_byte_count <= 0;
                tl_response_ready_reg <= 1'b0; // Don't accept new responses while streaming
            end else if (response_active && response_ready) begin
                // Stream out next byte
                response_buffer <= {8'h00, response_buffer[127:8]}; // Shift right
                if (response_byte_count == PACKET_SIZE - 1) begin
                    // Last byte transmitted
                    response_active <= 1'b0;
                    tl_response_ready_reg <= 1'b1; // Ready for next response
                end else begin
                    response_byte_count <= response_byte_count + 1;
                end
            end
        end else if (state == STATE_IDLE) begin
            response_active <= 1'b0;
            response_byte_count <= 0;
            tl_response_ready_reg <= 1'b1;
        end
    end
    
    // Output assignments
    assign data_ready = (state == STATE_IDLE) || (state == STATE_RECEIVING);
    
    assign packet_valid = packet_valid_reg;
    assign packet_data = packet_buffer;
    
    assign response_valid = response_active;
    assign response_data = response_buffer[7:0]; // LSB first
    
    assign tl_response_ready = tl_response_ready_reg;

endmodule