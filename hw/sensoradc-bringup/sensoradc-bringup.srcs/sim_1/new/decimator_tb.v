`timescale 1ns/1ps

module decimator_tb;
  reg clock;
  reg reset;
  reg signed [58:0] io_input;
  wire io_output_valid;
  wire signed [58:0] io_output_bits;

  Decimator dut (
    .clock(clock),
    .reset(reset),
    .io_input(io_input),
    .io_output_valid(io_output_valid),
    .io_output_bits(io_output_bits)
  );

  initial begin
    $dumpfile("decimator_tb.vcd");
    $dumpvars(0, decimator_tb);

    // Initialize inputs
    clock = 0;
    reset = 1;
    io_input = 0;

    // Deassert reset after a few clock cycles
    #10 reset = 0;

    // Test case: Output values at correct decimation factor
    reg [31:0] inputVals[11:0];
    initial begin
      inputVals[0] = 1;
      inputVals[1] = 2;
      inputVals[2] = 3;
      inputVals[3] = 4;
      inputVals[4] = 5;
      inputVals[5] = 6;
      inputVals[6] = 7;
      inputVals[7] = 8;
      inputVals[8] = 9;
      inputVals[9] = 10;
      inputVals[10] = 11;
      inputVals[11] = 12;

    for (integer i = 0; i < 12; i = i + 1) begin
      io_input = inputVals[i];
      #1 clock = ~clock;
      #1 clock = ~clock;

      $display("idx: %d, valid: %b, bits: %d", i, io_output_valid, io_output_bits);

      if (i % 4 == 0) begin
        if (!io_output_valid) begin
          $display("Test case failed: Expected valid output");
          $finish;
        end
        if (io_output_bits !== inputVals[i]) begin
          $display("Test case failed: Expected %d, got %d", inputVals[i], io_output_bits);
          $finish;
        end
      end else begin
        if (io_output_valid) begin
          $display("Test case failed: Expected invalid output");
          $finish;
        end
      end
    end

    $display("All tests passed");
    $finish;
  end

  always #1 clock = ~clock;

endmodule
