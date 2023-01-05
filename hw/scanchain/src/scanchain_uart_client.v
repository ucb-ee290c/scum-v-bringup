/*
Implements a very simple interface which allows scan commands to be issued over
UART.
The wire format is essentially just
    {2'b0, reset, payload, addr}. 
If the packet was accepted, 8'b1 is sent back. Otherwise, 8'b0 is sent.
*/
module scanchain_uart_client #(
    parameter CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE = 115_200,
    parameter ADDR_BITS = 12,
    parameter PAYLOAD_BITS = 169
) (
    input clk,
    input reset,

    input uart_rx,
    output uart_tx,

    input write_ready,
    output reg write_valid,
    output reg [ADDR_BITS - 1:0] write_addr,
    output reg [PAYLOAD_BITS - 1:0] write_payload,
    output reg write_reset
);

reg [7 : 0] uart_data_in;
reg uart_data_in_valid;
wire uart_data_in_ready;

wire [7 : 0] uart_data_out;
wire uart_data_out_valid;
wire uart_data_out_ready;

uart #(
    .CLOCK_FREQ(CLOCK_FREQ),
    .BAUD_RATE(BAUD_RATE)
) uart (
    .clk(clk),
    .reset(reset),

    .data_in(uart_data_in),
    .data_in_valid(uart_data_in_valid),
    .data_in_ready(uart_data_in_ready),

    .data_out(uart_data_out),
    .data_out_valid(uart_data_out_valid),
    .data_out_ready(uart_data_out_ready),

    .serial_in(uart_rx),
    .serial_out(uart_tx)
);

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

wire will_capture_byte = state == STATE_READ_PACKET && uart_data_out_valid; 
wire will_capture_final_byte = will_capture_byte 
                                && bytes_counter == PACKET_BYTE_SIZE - 1;
wire will_transmit = state == STATE_WRITE_RESPONSE && uart_data_in_ready;
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

/* Read in packet bytes */
assign uart_data_out_ready = 1;
always @(posedge clk) begin
    if (will_capture_byte) begin
        /* shift in the new byte */
        packet <= {packet[PACKET_BIT_SIZE - 1 - 8 : 0], uart_data_out};
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
Drive TX
*/
always @(posedge clk) begin
    if (will_transmit) begin
        /* 
        This path will only be taken once because next_state always is READ
        after will_transmit
        */
        uart_data_in <= {7'b0, write_accepted};
        uart_data_in_valid <= 1;
    end
    else begin
        uart_data_in <= 'bx;
        uart_data_in_valid <= 0;
    end
end

endmodule