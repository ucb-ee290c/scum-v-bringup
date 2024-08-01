`timescale 1ns / 1ps

module Comb(
    input         clock,
    input         reset,
    input         io_input_valid,
    input  [66:0] io_input_bits,
    output        io_output_valid,
    output [66:0] io_output_bits
);
    reg [66:0] shiftReg;
    always @(posedge clock) begin
        if (reset)
            shiftReg <= 67'h0;
        else if (io_input_valid)
            shiftReg <= io_input_bits;
    end
    assign io_output_valid = io_input_valid;
    assign io_output_bits = io_input_bits - shiftReg;
endmodule
