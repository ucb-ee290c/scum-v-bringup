`timescale 1ns/1ns
`define CLK_PERIOD 8
`define CLOCK_FREQ 20
`define CLOCKS_PER_SCAN_CLK 5
// `define CLOCK_FREQ 100_000_000
// `define CLOCKS_PER_SCAN_CLK 1_000
`define ADDR_BITS 12
`define PAYLOAD_BITS 169
module scanchain_writer_tb();
    /* Generate the simulated clock */
    reg clk = 0;
    always #(`CLK_PERIOD/2) clk <= ~clk;
    /* Managed signals */
    reg reset;

    wire write_ready;
    reg write_valid;
    reg [11:0] write_addr;
    reg [168:0] write_payload;
    reg write_reset;

    wire scan_clk;
    wire scan_en;
    wire scan_in;
    wire scan_reset;


    scanchain_writer #(
        .CLOCK_FREQ(`CLOCK_FREQ),
        .CLOCKS_PER_SCAN_CLK(`CLOCKS_PER_SCAN_CLK),
        .ADDR_BITS(`ADDR_BITS),
        .PAYLOAD_BITS(`PAYLOAD_BITS)
    ) sc_writer (
        .clk(clk),
        .reset(reset),

        .write_ready(write_ready),
        .write_valid(write_valid),
        .write_addr(write_addr),
        .write_payload(write_payload),
        .write_reset(write_reset),

        .scan_clk(scan_clk),
        .scan_en(scan_en),
        .scan_in(scan_in),
        .scan_reset(scan_reset)
    );

    task test_reset();
        wait (write_ready); #1;

        write_reset = 1;
        write_valid = 1;
        @(posedge clk); #1;
        write_valid = 0;
        write_reset = 'x;
        @(posedge clk); #1;
        while (scan_en) begin
            assert(scan_reset) else
                $error("Expected reset, got %x", scan_reset);
            @(posedge clk); #1;
        end
        assert(!scan_reset) else
            $error("Expected reset to drop, got %x", scan_reset);
    endtask

    integer i;
    task test_write(
        input [`ADDR_BITS - 1: 0] addr,
        input [`PAYLOAD_BITS -1 : 0] payload
    );
        reg [`ADDR_BITS - 1 : 0] scanned_addr;
        reg [`PAYLOAD_BITS - 1 : 0] scanned_payload;

        wait (write_ready); #1;

        write_valid = 1;
        write_addr = addr;
        write_payload = payload;
        write_reset = 0;
        @(posedge clk); #1;
        write_valid = 0;
        write_reset = 'x;
        write_addr = 'x;
        write_payload = 'x;
        wait (scan_en) #1;
    
        for (i = 0; i < `ADDR_BITS; i = i + 1) begin
            @(posedge scan_clk); #1;
            scanned_addr = scanned_addr << 1 | scan_in;
            assert(scan_en) else
                $error("Expected scan_en enabled for addr, got %x", scan_en);
            assert(!scan_reset) else
                $error("Scan reset should never be high here, got %x", scan_reset);

        end
        assert(scanned_addr == addr) else
            $error("addr mismatch. Expected = %x, got = %x", addr, scanned_addr);

        for (i = 0; i < `PAYLOAD_BITS; i = i + 1) begin
            @(posedge scan_clk); #1;
            scanned_payload = scanned_payload << 1 | scan_in;
            assert(scan_en) else
                $error("Expected scan_en enabled for payload, got %x", scan_en);
            assert(!scan_reset) else
                $error("Scan reset should never be high here, got %x", scan_reset);
        end
        assert(scanned_payload == payload) else
            $error("payload mismatch. Expected = %x, got = %x", payload, scanned_payload);
        
        @(posedge clk); #1;
    endtask

    integer j;
    initial begin
        `ifdef IVERILOG
            $dumpfile("scanchain_writer_tb.fst");
            // $dumpvars(0, scanchain_writer_tb);
            $dumpvars(0, sc_writer);
        `endif
        `ifndef IVERILOG
            $vcdpluson;
            $vcdplusmemon;
        `endif

        /* Reset */
        write_valid = 0;
        @(posedge clk);
        reset = 1;
        @(posedge clk);
        reset = 0;
        @(posedge clk);

        test_reset();
        // test_write(12'b100000000000, {$random, $random, $random, $random, $random, $random});
        for (j = 0; j < 128; j = j + 1) begin
            test_write($random, {$random, $random, $random, $random, $random, $random});
            repeat (j) @(posedge clk);
        end

        $display("Done!");
        `ifndef IVERILOG
            $vcdplusoff;
        `endif
        $finish();

    end
endmodule