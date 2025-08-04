/*
 * SCuM-V Controller UART Handler
 * 
 * This module acts as the central protocol multiplexer for the dual-mode
 * SCuM-V controller. It receives UART data from the host PC, detects the
 * protocol prefix ("asc+" or "stl+"), strips the prefix, and routes the
 * remaining data to the appropriate subsystem (ASC or STL).
 *
 * Protocol Format:
 * - ASC: "asc+" + 22-byte scan chain packet
 * - STL: "stl+" + 16-byte TileLink packet
 */

module scumvcontroller_uart_handler #(
    parameter CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE = 1_000_000
)(
    // Clock and reset
    input wire clk,
    input wire reset,
    
    // External UART interface
    input wire uart_rx,
    output wire uart_tx,
    
    // ASC subsystem FIFO interface
    output wire asc_data_valid,
    input wire asc_data_ready,
    output wire [7:0] asc_data_out,
    input wire asc_response_valid,
    output wire asc_response_ready,
    input wire [7:0] asc_response_data,
    
    // STL subsystem FIFO interface
    output wire stl_data_valid,
    input wire stl_data_ready,
    output wire [7:0] stl_data_out,
    input wire stl_response_valid,
    output wire stl_response_ready,
    input wire [7:0] stl_response_data,
    
    // Status and control
    output wire [1:0] active_mode, // 0=idle, 1=asc, 2=stl
    output wire [3:0] debug_state,
    output wire [7:0] debug_uart_data_in,
    output wire [7:0] debug_packet_count
);

    // Protocol detection states
    localparam STATE_IDLE = 4'h0;
    localparam STATE_PREFIX_1 = 4'h1; // Received first character
    localparam STATE_PREFIX_2 = 4'h2; // Received second character  
    localparam STATE_PREFIX_3 = 4'h3; // Received third character
    localparam STATE_ASC_MODE = 4'h4; // In ASC mode, forwarding data
    localparam STATE_STL_MODE = 4'h5; // In STL mode, forwarding data
    localparam STATE_ASC_MODE_FINAL = 4'h6; // Final cycle of ASC data forwarding
    localparam STATE_STL_MODE_FINAL = 4'h7; // Final cycle of STL data forwarding
    localparam STATE_ASC_RESPONSE = 4'h8; // Sending ASC response (1 byte)
    localparam STATE_STL_RESPONSE = 4'h9; // Sending STL response (16 bytes)
    localparam STATE_ASC_RESPONSE_FINAL = 4'hA; // Final cycle of ASC response
    localparam STATE_STL_RESPONSE_FINAL = 4'hB; // Final cycle of STL response
    localparam STATE_ERROR = 4'hF; // Error state
    
    // Protocol prefixes: "asc+" = {0x61, 0x73, 0x63, 0x2B}
    //                   "stl+" = {0x73, 0x74, 0x6C, 0x2B}
    localparam PREFIX_1_ASC = 8'h61; // 'a'
    localparam PREFIX_1_STL = 8'h73; // 's'
    localparam PREFIX_2_ASC = 8'h73; // 's' 
    localparam PREFIX_2_STL = 8'h74; // 't'
    localparam PREFIX_3_ASC = 8'h63; // 'c'
    localparam PREFIX_3_STL = 8'h6C; // 'l'
    localparam PREFIX_4_COMMON = 8'h2B; // '+'
    
    // Packet sizes
    localparam ASC_PACKET_SIZE = 22; // 22 bytes for ASC
    localparam STL_PACKET_SIZE = 16; // 16 bytes for STL
    localparam STL_RESPONSE_SIZE = 16; // 16 bytes for STL response
    
    // State registers
    reg [3:0] state, next_state;
    reg [7:0] prefix_buffer [0:3];
    reg [1:0] prefix_count;
    reg [7:0] packet_count;
    reg [7:0] response_count;
    reg [7:0] current_packet_size;
    reg protocol_detected; // 0=ASC, 1=STL
    reg final_packet_seen;
    
    // UART interface signals
    wire [7:0] uart_data_in;
    assign debug_uart_data_in = uart_data_in;
    assign debug_packet_count = packet_count;
    wire uart_data_in_valid;
    wire uart_data_in_ready;
    wire [7:0] uart_data_out;
    wire uart_data_out_valid;
    wire uart_data_out_ready;
    
    // Internal UART instance
    uart #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uart_inst (
        .clk(clk),
        .reset(reset),
        .data_in(uart_data_out),
        .data_in_valid(uart_data_out_valid),
        .data_in_ready(uart_data_out_ready),
        .data_out(uart_data_in),
        .data_out_valid(uart_data_in_valid),
        .data_out_ready(uart_data_in_ready),
        .serial_in(uart_rx),
        .serial_out(uart_tx)
    );
    
    // State machine
    always @(posedge clk) begin
        if (reset) begin
            state <= STATE_IDLE;
            prefix_count <= 0;
            packet_count <= 0;
            response_count <= 0;
            current_packet_size <= 0;
            protocol_detected <= 0;
            final_packet_seen <= 0;
        end else begin
            state <= next_state;
            
            // Handle prefix detection
            if (state >= STATE_IDLE && state <= STATE_PREFIX_3 && uart_data_in_valid) begin
                prefix_buffer[prefix_count] <= uart_data_in;
                if (state == STATE_PREFIX_3) begin
                    prefix_count <= 0;
                    if (uart_data_in == PREFIX_4_COMMON) begin
                        // Determine protocol based on collected prefix
                        if (prefix_buffer[0] == PREFIX_1_ASC && 
                            prefix_buffer[1] == PREFIX_2_ASC && 
                            prefix_buffer[2] == PREFIX_3_ASC) begin
                            protocol_detected <= 0; // ASC
                            current_packet_size <= ASC_PACKET_SIZE;
                        end else if (prefix_buffer[0] == PREFIX_1_STL && 
                                   prefix_buffer[1] == PREFIX_2_STL && 
                                   prefix_buffer[2] == PREFIX_3_STL) begin
                            protocol_detected <= 1; // STL
                            current_packet_size <= STL_PACKET_SIZE;
                        end
                    end
                end else begin
                    prefix_count <= prefix_count + 1;
                end
            end
            
            // Handle packet counting during data forwarding
            if ((state == STATE_ASC_MODE || state == STATE_STL_MODE || 
                 state == STATE_ASC_MODE_FINAL || state == STATE_STL_MODE_FINAL) && 
                uart_data_in_valid && 
                (((state == STATE_ASC_MODE || state == STATE_ASC_MODE_FINAL) && asc_data_ready) || 
                 ((state == STATE_STL_MODE || state == STATE_STL_MODE_FINAL) && stl_data_ready))) begin
                if (packet_count == current_packet_size - 1) begin
                    packet_count <= 0;
                    final_packet_seen <= 1;
                end else begin
                    packet_count <= packet_count + 1;
                    final_packet_seen <= 0;
                end
            end
            
            // Handle response counting
            if (state == STATE_STL_RESPONSE && stl_response_valid && uart_data_out_ready) begin
                if (response_count == STL_RESPONSE_SIZE) begin
                    response_count <= 0;
                    final_packet_seen <= 0;
                end else begin
                    response_count <= response_count + 1;
                end
            end else if (state == STATE_IDLE) begin
                packet_count <= 0;
                response_count <= 0;
                final_packet_seen <= 0;
            end
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        
        case (state)
            STATE_IDLE: begin
                if (uart_data_in_valid) begin
                    if (uart_data_in == PREFIX_1_ASC || uart_data_in == PREFIX_1_STL) begin
                        next_state = STATE_PREFIX_1;
                    end else begin
                        next_state = STATE_ERROR;
                    end
                end
            end
            
            STATE_PREFIX_1: begin
                if (uart_data_in_valid) begin
                    if ((prefix_buffer[0] == PREFIX_1_ASC && uart_data_in == PREFIX_2_ASC) ||
                        (prefix_buffer[0] == PREFIX_1_STL && uart_data_in == PREFIX_2_STL)) begin
                        next_state = STATE_PREFIX_2;
                    end else begin
                        next_state = STATE_ERROR;
                    end
                end
            end
            
            STATE_PREFIX_2: begin
                if (uart_data_in_valid) begin
                    if ((prefix_buffer[0] == PREFIX_1_ASC && prefix_buffer[1] == PREFIX_2_ASC && uart_data_in == PREFIX_3_ASC) ||
                        (prefix_buffer[0] == PREFIX_1_STL && prefix_buffer[1] == PREFIX_2_STL && uart_data_in == PREFIX_3_STL)) begin
                        next_state = STATE_PREFIX_3;
                    end else begin
                        next_state = STATE_ERROR;
                    end
                end
            end
            
            STATE_PREFIX_3: begin
                if (uart_data_in_valid) begin
                    if (uart_data_in == PREFIX_4_COMMON) begin
                        if (prefix_buffer[0] == PREFIX_1_ASC && prefix_buffer[1] == PREFIX_2_ASC && prefix_buffer[2] == PREFIX_3_ASC) begin
                            next_state = STATE_ASC_MODE;
                        end else if (prefix_buffer[0] == PREFIX_1_STL && prefix_buffer[1] == PREFIX_2_STL && prefix_buffer[2] == PREFIX_3_STL) begin
                            next_state = STATE_STL_MODE;
                        end
                    end else begin
                        next_state = STATE_ERROR;
                    end
                end
            end
            
            STATE_ASC_MODE: begin
                if (uart_data_in_valid && asc_data_ready && packet_count == current_packet_size) begin
                    next_state = STATE_ASC_MODE_FINAL;
                end
            end
            
            STATE_STL_MODE: begin
                if (final_packet_seen) begin
                    next_state = STATE_STL_RESPONSE;
                end
            end
            
            STATE_ASC_MODE_FINAL: begin
                if (uart_data_in_valid && asc_data_ready) begin
                    next_state = STATE_ASC_RESPONSE;
                end
            end
            
            STATE_STL_MODE_FINAL: begin
                if (uart_data_in_valid && stl_data_ready) begin
                    next_state = STATE_STL_RESPONSE;
                end
            end
            
            STATE_ASC_RESPONSE: begin
                if (asc_response_valid && uart_data_out_ready) begin
                    next_state = STATE_ASC_RESPONSE_FINAL;
                end
            end
            
            STATE_STL_RESPONSE: begin
                if (stl_response_valid && uart_data_out_ready && response_count == STL_RESPONSE_SIZE - 1) begin
                    next_state = STATE_STL_RESPONSE_FINAL;
                end
            end

            STATE_ASC_RESPONSE_FINAL: begin
                next_state = STATE_IDLE;
            end

            STATE_STL_RESPONSE_FINAL: begin
                next_state = STATE_IDLE;
            end
            
            STATE_ERROR: begin
                // Stay in error state until reset
                next_state = STATE_ERROR;
            end
            
            default: begin
                next_state = STATE_IDLE;
            end
        endcase
    end
    
    // Output assignments
    assign active_mode = (state == STATE_ASC_MODE || state == STATE_ASC_MODE_FINAL || 
                          state == STATE_ASC_RESPONSE || state == STATE_ASC_RESPONSE_FINAL) ? 2'b01 :
                        (state == STATE_STL_MODE || state == STATE_STL_MODE_FINAL || 
                          state == STATE_STL_RESPONSE || state == STATE_STL_RESPONSE_FINAL) ? 2'b10 :
                        2'b00;
    
    assign debug_state = state;
    
    // ASC subsystem connections
    assign asc_data_out = uart_data_in;
    assign asc_data_valid = (state == STATE_ASC_MODE || state == STATE_ASC_MODE_FINAL) ? uart_data_in_valid : 1'b0;
    assign asc_response_ready = (state == STATE_ASC_RESPONSE || state == STATE_ASC_RESPONSE_FINAL) ? uart_data_out_ready : 1'b0;
    
    // STL subsystem connections  
    assign stl_data_out = uart_data_in;
    assign stl_data_valid = (state == STATE_STL_MODE || state == STATE_STL_MODE_FINAL) ? uart_data_in_valid : 1'b0;
    assign stl_response_ready = (state == STATE_STL_RESPONSE || state == STATE_STL_RESPONSE_FINAL) ? uart_data_out_ready : 1'b0;
    
    // UART output mux
    assign uart_data_out = (state == STATE_ASC_RESPONSE || state == STATE_ASC_RESPONSE_FINAL) ? asc_response_data :
                          (state == STATE_STL_RESPONSE || state == STATE_STL_RESPONSE_FINAL) ? stl_response_data :
                          8'h00;
    
    assign uart_data_out_valid = (state == STATE_ASC_RESPONSE || state == STATE_ASC_RESPONSE_FINAL) ? asc_response_valid :
                                (state == STATE_STL_RESPONSE || state == STATE_STL_RESPONSE_FINAL) ? stl_response_valid :
                                1'b0;
    
    // UART input ready signal - ready when subsystem can accept data or during prefix detection
    assign uart_data_in_ready = (state == STATE_ASC_MODE || state == STATE_ASC_MODE_FINAL) ? asc_data_ready :
                               (state == STATE_STL_MODE || state == STATE_STL_MODE_FINAL) ? stl_data_ready :
                               (state >= STATE_IDLE && state <= STATE_PREFIX_3) ? 1'b1 :
                               1'b0;

endmodule