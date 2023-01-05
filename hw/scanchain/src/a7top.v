module a7top #(
    parameter CLOCK_FREQ = 100_000_000,
    parameter CLOCK_PERIOD = 1_000_000_000 / CLOCK_FREQ,
    // 100KHz scan_clock
    parameter SCAN_CLK_FREQ    = 100_000_000,
    parameter SCAN_CLK_PERIOD  = 1_000_000_000 / SCAN_CLK_FREQ,
    parameter CLKS_PER_SCAN_CLK = CLOCK_FREQ / SCAN_CLK_FREQ,

    parameter ADDR_BITS = 12,
    parameter PAYLOAD_BITS = 169,

    parameter BAUD_RATE = 115_200
)(
    input CLK100MHZ,
    input RESET,

    output UART_RXD_IN,
    input UART_TXD_IN,

    output SCAN_CLK,
    output SCAN_EN,
    output SCAN_IN,
    output SCAN_RESET,

    output [3 : 0] led
);
    
    /* 
    The A7's reset button is high when not pressed. We use active high reset.
    */
    wire n_reset = ~RESET;
    wire uart_valid;
    wire uart_ready;
    wire sc_writer_ready;
    wire write_reset;

    wire [ADDR_BITS - 1 : 0] write_addr;
    wire [PAYLOAD_BITS - 1 : 0] write_payload;
    wire FPGA_CLK = CLK100MHZ;

    scanchain_uart_client #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) sc_uart_client (
        .clk(FPGA_CLK),
        .reset(n_reset),

        .uart_rx(UART_TXD_IN),
        .uart_tx(UART_RXD_IN),

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
        .clk(FPGA_CLK),
        .reset(n_reset),

        .write_ready(sc_writer_ready),
        .write_valid(uart_valid),
        .write_addr(write_addr),
        .write_payload(write_payload),
        .write_reset(write_reset),

        .scan_clk(SCAN_CLK),
        .scan_en(SCAN_EN),
        .scan_in(SCAN_IN),
        .scan_reset(SCAN_RESET)
    );

    assign uart_ready = sc_writer_ready;

    // always @(posedge clk) begin
    //     if (reset) begin
    //         uart_ready <= 1;
    //     end
    //     else if (uart_ready && uart_valid) begin
    //         /* 
    //         We've just turned ready! Hold on to it till we can hand it off.
    //         If the writer is ready right now, we can take another UART packet
    //         next cycle since they writer will internalize first.
    //         */
    //         uart_ready <= sc_writer_ready;
    //     end
    //     else if (uart_valid && sc_read)
    // end

    assign led[0] = n_reset;
    assign led[1] = SCAN_EN;
    assign led[2] = SCAN_CLK;
    assign led[3] = SCAN_IN;
endmodule
