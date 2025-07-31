`timescale 1ns/1ns
`define CLK_PERIOD 8
`define CYCLES_PER_SECOND_SIMULATED 10
`define CLOCK_FREQ 20
`define BAUD_RATE 1
module scanchain_uart_client_tb();
    /* Generate the simulated clock */
    reg clk = 0;
    always #(`CLK_PERIOD/2) clk <= ~clk;
    /* Managed signals */
    reg reset;
    reg [7 : 0] uart_data_in;
    reg uart_data_in_valid;
    reg uart_data_out_ready;
    reg write_ready;
    /* Outputs */
    wire uart_rx;
    wire uart_tx;
    wire write_valid;
    wire [11:0] write_addr;
    wire [168:0] write_payload;
    wire write_reset;

    wire uart_data_in_ready;
    wire [7 : 0] uart_data_out;
    wire uart_data_out_valid;


    localparam PACKET_BIT_SIZE = 169 + 12 + 1 + 2;

    scanchain_uart_client #(
        .CLOCK_FREQ(`CLOCK_FREQ),
        .BAUD_RATE(`BAUD_RATE)
    ) sc_uart_client (
        .clk(clk),
        .reset(reset),

        .uart_rx(uart_rx),
        .uart_tx(uart_tx),

        .write_ready(write_ready),
        .write_valid(write_valid),
        .write_addr(write_addr),
        .write_payload(write_payload),
        .write_reset(write_reset)
    );

    uart #(
        .CLOCK_FREQ(`CLOCK_FREQ),
        .BAUD_RATE(`BAUD_RATE)
    ) uart_tb (
        .clk(clk),
        .reset(reset),

        .data_in(uart_data_in),
        .data_in_valid(uart_data_in_valid),
        .data_in_ready(uart_data_in_ready),

        .data_out(uart_data_out),
        .data_out_valid(uart_data_out_valid),
        .data_out_ready(uart_data_out_ready),

        .serial_in(uart_tx),
        .serial_out(uart_rx)
    );

    task uart_tx_packet(
        input [PACKET_BIT_SIZE] pkt
    );
        integer i;

        for (i = PACKET_BIT_SIZE - 8; i >= 0; i -= 8) begin
            wait (uart_data_in_ready); #1;
            uart_data_in = pkt[i +: 8];
            uart_data_in_valid = 1;
            @(posedge clk); #1;
            uart_data_in_valid = 0;
        end

    endtask

    task test_scan_write(
        input [11 : 0] addr,
        input [168:0] payload,
        input _reset,
        input ready
    );
        write_ready = ready;
        uart_data_out_ready = 1;

        uart_tx_packet({2'b0, _reset, payload, addr});
        if (ready) begin
            wait (write_valid);
            write_ready = 0;
            assert(write_addr == addr) else
                $error("Invalid addr. Expected %x, got %x", addr, write_addr);
            assert(write_payload == payload) else
                $error("Invalid payload. Expected %x, got %x", payload, write_payload);
            assert(write_reset == _reset);
        end

        wait (uart_data_out_valid);
        uart_data_out_ready = 0;
        assert(uart_data_out == {7'b0, ready}) else
            $error("Invalid response. Expected %x, got %x", {7'b0, ready}, uart_data_out);
        if (ready) begin
            assert(write_addr == addr) else
                $error("Invalid addr (hold fail). Expected %x, got %x", addr, write_addr);
            assert(write_payload == payload) else
                $error("Invalid payload (hold fail). Expected %x, got %x", payload, write_payload);
        end
    endtask


    initial begin
    `ifdef IVERILOG
        $dumpfile("scanchain_uart_client_tb.fst");
        $dumpvars(0, scanchain_uart_client_tb);
        $dumpvars(0, sc_uart_client);
    `endif
    `ifndef IVERILOG
        $vcdpluson;
        $vcdplusmemon;
    `endif

    /* Reset */
    uart_data_in_valid = 0;
    write_ready = 0;
    @(posedge clk);
    reset = 1;
    @(posedge clk);
    reset = 0;
    @(posedge clk);
    
    test_scan_write($random, {$random, $random, $random, $random, $random, $random}, 0, 1);
    test_scan_write($random, {$random, $random, $random, $random, $random, $random}, 0, 0);
    test_scan_write($random, {$random, $random, $random, $random, $random, $random}, 0, 1);
    test_scan_write($random, {$random, $random, $random, $random, $random, $random}, 1, 1);

    $display("Done!");
    `ifndef IVERILOG
        $vcdplusoff;
    `endif
    $finish();

    end
endmodule