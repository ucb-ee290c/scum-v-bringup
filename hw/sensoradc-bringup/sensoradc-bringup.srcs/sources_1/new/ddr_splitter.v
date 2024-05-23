`timescale 1ns / 1ps

module ddr_splitter (
  input        clk,
  input  [5:0] ddr_counter,
  output reg [5:0] counter_p,
  output reg [5:0] counter_n
);

  // Register to capture the negative edge data
  reg [5:0] ddr_counter_n;

  // Capture the data on the negative edge of the clock
  always @(negedge clk) begin
    ddr_counter_n <= ddr_counter;
  end

  // Assign the positive and negative edge data to the output counters
  always @(posedge clk) begin
    counter_p <= ddr_counter;
    counter_n <= ddr_counter_n;
  end

endmodule