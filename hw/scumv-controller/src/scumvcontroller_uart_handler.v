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

    // Simplified Mealy FSM states
    localparam STATE_IDLE = 3'h0;        // Wait for data, check first prefix character
    localparam STATE_PREFIX = 3'h1;      // Collect 4-character prefix
    localparam STATE_FORWARD_ASC = 3'h2; // Forward 22 bytes ASC data
    localparam STATE_FORWARD_STL = 3'h3; // Forward 16 bytes STL data
    localparam STATE_RESPOND_ASC = 3'h4; // Send 1 byte ASC response
    localparam STATE_RESPOND_STL = 3'h5; // Send 16 bytes STL response
    
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
    reg [2:0] state;
    reg [7:0] prefix_buffer [0:3];
    reg [7:0] counter; // Unified counter for prefix, packet, and response bytes
    reg protocol_detected; // 0=ASC, 1=STL
    reg incoming_fifo_rd_en_prev; // Track previous cycle FIFO read for valid data
    reg outgoing_fifo_rd_en_prev; // Track previous cycle FIFO read for valid data
    
    // UART interface signals (direct from UART module)
    wire [7:0] uart_rx_data;
    wire uart_rx_data_valid;
    wire uart_rx_data_ready;
    wire [7:0] uart_tx_data;
    wire uart_tx_data_valid;
    wire uart_tx_data_ready;
    
    // Incoming FIFO signals (UART RX -> Protocol Processing)
    wire [7:0] fifo_to_fsm_data;        // Data from incoming FIFO to FSM
    assign debug_uart_data_in = fifo_to_fsm_data;
    assign debug_packet_count = counter;
    reg incoming_fifo_rd_en;            // Explicit FIFO read enable
    wire incoming_fifo_full;
    wire incoming_fifo_empty;
    
    // Outgoing FIFO signals (Response -> UART TX)
    wire [7:0] fsm_to_fifo_data;        // Data from FSM to outgoing FIFO
    wire fsm_to_fifo_valid;             // FSM has response data to send
    wire outgoing_fifo_wr_en;           // Explicit FIFO write enable
    wire outgoing_fifo_full;
    wire outgoing_fifo_empty;
    wire outgoing_fifo_rd_en;
    
    // Internal UART instance
    uart #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uart_inst (
        .clk(clk),
        .reset(reset),
        .data_in(uart_tx_data),
        .data_in_valid(outgoing_fifo_rd_en_prev),
        .data_in_ready(uart_tx_data_ready),
        .data_out(uart_rx_data),
        .data_out_valid(uart_rx_data_valid),
        .data_out_ready(uart_rx_data_ready),
        .serial_in(uart_rx),
        .serial_out(uart_tx)
    );
    
    // Incoming FIFO (UART RX -> Protocol Processing)
    // Buffers incoming UART data for protocol detection and forwarding
    fifo #(
        .WIDTH(8),
        .DEPTH(128)
    ) incoming_fifo (
        .clk(clk),
        .rst(reset),
        .wr_en(uart_rx_data_valid && uart_rx_data_ready),
        .din(uart_rx_data),
        .full(incoming_fifo_full),
        .rd_en(incoming_fifo_rd_en),
        .dout(fifo_to_fsm_data),
        .empty(incoming_fifo_empty)
    );
    
    // Outgoing FIFO (Response -> UART TX)  
    // Buffers response data before UART transmission
    fifo #(
        .WIDTH(8),
        .DEPTH(128)
    ) outgoing_fifo (
        .clk(clk),
        .rst(reset),
        .wr_en(outgoing_fifo_wr_en),
        .din(fsm_to_fifo_data),
        .full(outgoing_fifo_full),
        .rd_en(outgoing_fifo_rd_en),
        .dout(uart_tx_data),
        .empty(outgoing_fifo_empty)
    );
    
    // FIFO control signals - explicit handshaking
    assign uart_rx_data_ready = !incoming_fifo_full;           // UART can write when FIFO has space
    assign outgoing_fifo_wr_en = fsm_to_fifo_valid && !outgoing_fifo_full; // Write when both valid and ready
    assign uart_tx_data_valid = !outgoing_fifo_empty;          // UART sends when FIFO has data
    assign outgoing_fifo_rd_en = uart_tx_data_ready && !outgoing_fifo_empty && !outgoing_fifo_rd_en_prev;
    // Sequential logic - state transitions and data storage
    always @(posedge clk) begin
        if (reset) begin
            state <= STATE_IDLE;
            counter <= 0;
            protocol_detected <= 0;
            incoming_fifo_rd_en_prev <= 0;
            outgoing_fifo_rd_en_prev <= 0;
        end else begin
            incoming_fifo_rd_en_prev <= incoming_fifo_rd_en;
            outgoing_fifo_rd_en_prev <= outgoing_fifo_rd_en;
            
            // Mealy FSM: actions on state transitions
            case (state)
                STATE_IDLE: begin
                    if (incoming_fifo_rd_en && (fifo_to_fsm_data == PREFIX_1_ASC || fifo_to_fsm_data == PREFIX_1_STL)) begin
                        state <= STATE_PREFIX;
                        prefix_buffer[0] <= fifo_to_fsm_data;
                        counter <= 1;
                    end
                end
                
                STATE_PREFIX: begin
                    if (incoming_fifo_rd_en_prev) begin // Data is valid this cycle
                        prefix_buffer[counter] <= fifo_to_fsm_data;
                        if (counter == 3 && fifo_to_fsm_data == PREFIX_4_COMMON) begin
                            // Complete prefix received, determine protocol
                            if (prefix_buffer[0] == PREFIX_1_ASC && prefix_buffer[1] == PREFIX_2_ASC && prefix_buffer[2] == PREFIX_3_ASC) begin
                                state <= STATE_FORWARD_ASC;
                                protocol_detected <= 0;
                                counter <= 0;
                            end else if (prefix_buffer[0] == PREFIX_1_STL && prefix_buffer[1] == PREFIX_2_STL && prefix_buffer[2] == PREFIX_3_STL) begin
                                state <= STATE_FORWARD_STL;
                                protocol_detected <= 1;
                                counter <= 0;
                            end else begin
                                state <= STATE_IDLE;
                                counter <= 0;
                            end
                        end else if (counter < 3) begin
                            counter <= counter + 1;
                        end else begin
                            // Invalid prefix
                            state <= STATE_IDLE;
                            counter <= 0;
                        end
                    end
                end
                
                STATE_FORWARD_ASC: begin
                    if (incoming_fifo_rd_en_prev && asc_data_ready) begin
                        if (counter == ASC_PACKET_SIZE - 1) begin
                            state <= STATE_RESPOND_ASC;
                            counter <= 0;
                        end else begin
                            counter <= counter + 1;
                        end
                    end
                end
                
                STATE_FORWARD_STL: begin
                    if (incoming_fifo_rd_en_prev && stl_data_ready) begin
                        if (counter == STL_PACKET_SIZE - 1) begin
                            state <= STATE_RESPOND_STL;
                            counter <= 0;
                        end else begin
                            counter <= counter + 1;
                        end
                    end
                end
                
                STATE_RESPOND_ASC: begin
                    if (asc_response_valid && !outgoing_fifo_full) begin
                        state <= STATE_IDLE;
                        counter <= 0;
                    end
                end
                
                STATE_RESPOND_STL: begin
                    if (stl_response_valid && !outgoing_fifo_full) begin
                        if (counter == STL_RESPONSE_SIZE - 1) begin
                            state <= STATE_IDLE;
                            counter <= 0;
                        end else begin
                            counter <= counter + 1;
                        end
                    end
                end
                
                default: begin
                    state <= STATE_IDLE;
                    counter <= 0;
                end
            endcase
        end
    end
    
    // Mealy FSM: combinational outputs and FIFO control
    always @(*) begin
        case (state)
            STATE_IDLE: begin
                incoming_fifo_rd_en = !incoming_fifo_empty;
            end
            
            STATE_PREFIX: begin
                incoming_fifo_rd_en = !incoming_fifo_empty;
            end
            
            STATE_FORWARD_ASC: begin
                incoming_fifo_rd_en = !incoming_fifo_empty && asc_data_ready;
            end
            
            STATE_FORWARD_STL: begin
                incoming_fifo_rd_en = !incoming_fifo_empty && stl_data_ready;
            end
            
            STATE_RESPOND_ASC: begin
                incoming_fifo_rd_en = 1'b0;
            end
            
            STATE_RESPOND_STL: begin
                incoming_fifo_rd_en = 1'b0;
            end
            
            default: begin
                incoming_fifo_rd_en = 1'b0;
            end
        endcase
    end
    
    // Output assignments
    assign active_mode = (state == STATE_FORWARD_ASC || state == STATE_RESPOND_ASC) ? 2'b01 :
                        (state == STATE_FORWARD_STL || state == STATE_RESPOND_STL) ? 2'b10 :
                        2'b00;
    
    assign debug_state = {1'b0, state}; // Extend to 4 bits for compatibility
    
    // ASC subsystem connections
    assign asc_data_out = fifo_to_fsm_data;
    assign asc_data_valid = (state == STATE_FORWARD_ASC) ? incoming_fifo_rd_en_prev : 1'b0;
    assign asc_response_ready = (state == STATE_RESPOND_ASC) ? !outgoing_fifo_full : 1'b0;
    
    // STL subsystem connections  
    assign stl_data_out = fifo_to_fsm_data;
    assign stl_data_valid = (state == STATE_FORWARD_STL) ? incoming_fifo_rd_en_prev : 1'b0;
    assign stl_response_ready = (state == STATE_RESPOND_STL) ? !outgoing_fifo_full : 1'b0;
    
    // Response output mux (FSM -> Outgoing FIFO)
    assign fsm_to_fifo_data = (state == STATE_RESPOND_ASC) ? asc_response_data :
                             (state == STATE_RESPOND_STL) ? stl_response_data :
                             8'h00;
    
    assign fsm_to_fifo_valid = (state == STATE_RESPOND_ASC) ? asc_response_valid :
                              (state == STATE_RESPOND_STL) ? stl_response_valid :
                              1'b0;
endmodule