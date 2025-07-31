/*
 * Scanchain UART Client (Modified for FIFO Interface)
 * 
 * Implements a simple interface which allows scan commands to be issued via
 * FIFO interface from the UART handler. Maintains the same packet parsing
 * logic as the original UART version.
 * 
 * The wire format is: {2'b0, reset, payload, addr} (22 bytes total)
 * Response: 8'b1 if packet accepted, 8'b0 if rejected
 */
module scanchain_uart_client #(
    parameter CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE = 115_200, // Unused in FIFO mode, kept for compatibility
    parameter ADDR_BITS = 12,
    parameter PAYLOAD_BITS = 160
) (
    input clk,
    input reset,

    // FIFO interface from UART handler
    input data_valid,
    output data_ready,
    input [7:0] data_in,
    
    // FIFO interface to UART handler (response)
    output response_valid,
    input response_ready,
    output [7:0] response_data,

    // Interface to scanchain writer (unchanged)
    input write_ready,
    output reg write_valid,
    output reg [ADDR_BITS - 1:0] write_addr,
    output reg [PAYLOAD_BITS - 1:0] write_payload,
    output reg write_reset
);

// Response data register
reg [7:0] response_data_reg;
reg response_valid_reg;

/* The number of bits in the packet. We round to 8 bits as UART is byte sized */
localparam ADDR_OFFSET = 0;
localparam PAYLOAD_OFFSET = ADDR_BITS + ADDR_OFFSET;
localparam RESET_OFFSET = PAYLOAD_BITS + PAYLOAD_OFFSET;

localparam PACKET_BIT_SIZE = ((ADDR_BITS + PAYLOAD_BITS + 1 + 7) / 8) * 8;
localparam PACKET_BYTE_SIZE = PACKET_BIT_SIZE / 8;

localparam STATE_READ_PACKET    = 1'b0;
localparam STATE_WRITE_RESPONSE = 1'b1;

reg state;
reg next_state;
reg [PACKET_BIT_SIZE - 1 : 0] packet;
wire [PACKET_BIT_SIZE - 1 : 0] packet_next;
reg [$clog2(PACKET_BYTE_SIZE) - 1 : 0] bytes_counter;
/* Internal, for WRITE_RESPONSE: was the write accepted and dispatched? */
reg write_accepted;

wire will_capture_byte = state == STATE_READ_PACKET && data_valid && data_ready; 
wire will_capture_final_byte = will_capture_byte 
                                && bytes_counter == PACKET_BYTE_SIZE - 1;
wire will_transmit = state == STATE_WRITE_RESPONSE && response_ready;
/* Manage state */
always @(*) begin
    if (reset) begin
        next_state = STATE_READ_PACKET;
    end
    case (state)
        STATE_READ_PACKET: begin
            if (will_capture_final_byte) 
            begin
                /* We're going to capture our last byte this cycle, transition*/
                next_state = STATE_WRITE_RESPONSE;
            end
            else begin
                next_state = STATE_READ_PACKET;
            end
        end
        STATE_WRITE_RESPONSE: begin
            if (will_transmit) begin
                /* We're dispatching the response this cycle, go back to read */
                next_state = STATE_READ_PACKET;
            end
            else begin
                next_state = STATE_WRITE_RESPONSE;
            end
        end
    endcase
end

always @(posedge clk) begin
    state <= next_state;
end

/* Manage bytes_counter */
always @(posedge clk) begin
    if (reset) begin
        bytes_counter <= 0;
    end
    else if (state != next_state) begin
        /* Reset the counter on state transition */
        bytes_counter <= 0;
    end
    else if (will_capture_byte) begin
        /* We're capturing a byte */
        bytes_counter <= bytes_counter + 1;
    end
    else begin
        bytes_counter <= bytes_counter;
    end
end

/* FIFO ready signal - ready when in read packet state */
assign data_ready = (state == STATE_READ_PACKET);

/* Read in packet bytes */
always @(posedge clk) begin
    if (will_capture_byte) begin
        /* shift in the new byte */
        packet <= {packet[PACKET_BIT_SIZE - 1 - 8 : 0], data_in};
    end
    else begin
        packet <= packet;
    end
end

/* Drive write_accepted */
always @(posedge clk) begin
    if (state == STATE_READ_PACKET) begin
        if (will_capture_final_byte && write_ready) begin
            write_accepted <= 1;
        end
        else begin
            write_accepted <= 0;
        end
    end
    else begin
        write_accepted <= write_accepted;
    end
end

/* Drive all external write_xxx values */
always @(posedge clk) begin
    if (write_ready) begin
        /*
        We're allowed to change anything while ready, even if the output is
        invalid so long as we don't claim it's valid
        */
        write_addr <= packet[ADDR_BITS + ADDR_OFFSET - 1 : ADDR_OFFSET];
        write_payload <= 
            packet[PAYLOAD_BITS + PAYLOAD_OFFSET - 1 : PAYLOAD_OFFSET];
        write_reset <= packet[RESET_OFFSET];
        write_valid <= write_accepted;
    end
    else begin
        write_addr <= write_addr;
        write_payload <= write_payload;
        write_valid <= 0;
    end
end

/* 
 * Drive response FIFO
 * Send ASCII '1' (0x31) if accepted, ASCII '0' (0x30) if rejected
 */
always @(posedge clk) begin
    if (reset) begin
        response_data_reg <= 8'h00;
        response_valid_reg <= 1'b0;
    end
    else if (state == STATE_READ_PACKET && next_state == STATE_WRITE_RESPONSE) begin
        // Transition to response state - prepare response data
        response_data_reg <= write_accepted ? 8'h31 : 8'h30; // ASCII '1' or '0'
        response_valid_reg <= 1'b1;
    end
    else if (will_transmit) begin
        // Response consumed, clear valid
        response_valid_reg <= 1'b0;
    end
end

// Response interface assignments
assign response_data = response_data_reg;
assign response_valid = response_valid_reg;

endmodule