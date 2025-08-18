// This module instantiates the synchronizer -> debouncer -> edge detector signal chain for button inputs
module button_parser #(
  parameter WIDTH = 1,
  parameter SAMPLE_CNT_MAX = 25000,
  parameter PULSE_CNT_MAX = 150
) (
  input clk,
  input [WIDTH-1:0] in,
  output [WIDTH-1:0] out
);

  wire [WIDTH-1:0] synchronized_signals;

  simple_synchronizer # (
    .WIDTH(WIDTH)
  ) button_synchronizer (
    .clk(clk),
    .async_in(in),
    .sync_out(synchronized_signals)
  );

  debouncer # (
    .WIDTH(WIDTH),
    .SAMPLE_CNT_MAX(SAMPLE_CNT_MAX),
    .PULSE_CNT_MAX(PULSE_CNT_MAX)
  ) button_debouncer (
    .clk(clk),
    .glitchy_signal(synchronized_signals),
    .debounced_signal(out)
  );

endmodule