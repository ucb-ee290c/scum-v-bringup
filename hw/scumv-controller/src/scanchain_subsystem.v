/*
 * Scan Chain Subsystem
 * 
 * This module encapsulates all ASC-related functionality, including the
 * modified scanchain_uart_client and scanchain_writer. It provides a
 * clean FIFO-based interface to the UART handler.
 */

module scanchain_subsystem #(
    parameter CLOCK_FREQ = 100_000_000,
    parameter CLKS_PER_SCAN_CLK = 100_000, // 1kHz scan clock
    parameter ADDR_BITS = 12,
    parameter PAYLOAD_BITS = 160
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
    
    // Scan chain interface to SCuM-V
    output wire scan_clk,
    output wire scan_en,
    output wire scan_in,
    output wire scan_reset
);

    // Internal signals between uart client and writer
    wire uart_ready;
    wire uart_valid;
    wire write_reset;
    wire [ADDR_BITS - 1 : 0] write_addr;
    wire [PAYLOAD_BITS - 1 : 0] write_payload;
    wire sc_writer_ready;
    wire scan_en_mid;
    
    // Invert scan_en as per original design
    assign scan_en = ~scan_en_mid;

    // Modified scanchain_uart_client to work with FIFO interface
    scanchain_uart_client #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(115_200), // Baud rate not used in FIFO mode
        .ADDR_BITS(ADDR_BITS),
        .PAYLOAD_BITS(PAYLOAD_BITS)
    ) sc_uart_client (
        .clk(clk),
        .reset(reset),

        // FIFO interface instead of UART
        .data_valid(data_valid),
        .data_ready(data_ready),
        .data_in(data_in),
        .response_valid(response_valid),
        .response_ready(response_ready),
        .response_data(response_data),

        // Interface to scan chain writer
        .write_ready(uart_ready),
        .write_valid(uart_valid),
        .write_addr(write_addr),
        .write_payload(write_payload),
        .write_reset(write_reset)
    );

    scanchain_writer #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .CLOCKS_PER_SCAN_CLK(CLKS_PER_SCAN_CLK),
        .ADDR_BITS(ADDR_BITS),
        .PAYLOAD_BITS(PAYLOAD_BITS)
    ) sc_writer (
        .clk(clk),
        .reset(reset),

        .write_ready(sc_writer_ready),
        .write_valid(uart_valid),
        .write_addr(write_addr),
        .write_payload(write_payload),
        .write_reset(write_reset),

        .scan_clk(scan_clk),
        .scan_en(scan_en_mid),
        .scan_in(scan_in),
        .scan_reset(scan_reset)
    );

    assign uart_ready = sc_writer_ready;

endmodule