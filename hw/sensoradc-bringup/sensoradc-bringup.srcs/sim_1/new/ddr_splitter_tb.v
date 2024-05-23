`timescale 1ns/1ps

module ddr_splitter_tb;

  // Parameters
  parameter CLK_PERIOD = 10;
  parameter NUM_TESTS = 20;

  // Inputs
  reg clk;
  reg [5:0] ddr_counter;

  // Outputs
  wire [5:0] counter_p;
  wire [5:0] counter_n;

  // Random value variables
  reg [5:0] pos_value;
  reg [5:0] neg_value;

  // Loop variable
  integer i;

  // Instantiate the ddr_counter_splitter module
  ddr_splitter dut (
    .clk(clk),
    .ddr_counter(ddr_counter),
    .counter_p(counter_p),
    .counter_n(counter_n)
  );

  // Clock generation
  always begin
    clk = 1'b0;
    #(CLK_PERIOD/2);
    clk = 1'b1;
    #(CLK_PERIOD/2);
  end

  // Stimulus and checks
  initial begin
    // Initialize inputs
    ddr_counter = 6'b000000;

    // Wait for a few clock cycles
    #(CLK_PERIOD * 2);

    // Generate and verify random test cases
    for (i = 0; i < NUM_TESTS; i = i + 1) begin
      // Generate random values for ddr_counter
      pos_value = $random;
      neg_value = $random;

      // Apply the random values to ddr_counter
      ddr_counter = pos_value;
      #(CLK_PERIOD/2);
      ddr_counter = neg_value;
      #(CLK_PERIOD/2);

      // Check the outputs against the expected values
      if (counter_p !== neg_value) begin
        $display("Test failed for counter_p");
        $display("Expected: %b, Actual: %b", neg_value, counter_p);
        $stop;
      end
      if (counter_n !== pos_value) begin
        $display("Test failed for counter_n");
        $display("Expected: %b, Actual: %b", pos_value, counter_n);
        $stop;
      end
    end

    // End the simulation
    #(CLK_PERIOD);
    $display("All tests passed!");
    $finish;
  end

  // Dump waveforms
  initial begin
    $dumpfile("ddr_splitter_tb.vcd");
    $dumpvars(0, ddr_splitter_tb);
  end

endmodule