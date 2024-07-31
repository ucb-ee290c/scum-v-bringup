`timescale 1ns / 1ps

module Decimator(
  input         clock,
                reset,
  input  [66:0] io_input,
  output        io_output_valid,
  output [66:0] io_output_bits
);

  reg  [14:0] counter;
  reg  [66:0] outBuffer;
  reg         valBuffer;
  wire        _GEN_3 = counter == 15'h0;
  always @(posedge clock) begin
    if (reset) begin
      counter <= 15'h0;
      outBuffer <= 67'h0;
      valBuffer <= 1'h0;
    end
    else begin
      if (_GEN_3 | counter != 15'h7CFF)
        counter <= counter + 15'h1;
      else
        counter <= 15'h0;
      if (_GEN_3)
        outBuffer <= io_input;
      valBuffer <= _GEN_3;
    end
  end
  assign io_output_valid = valBuffer;
  assign io_output_bits = outBuffer;
endmodule
