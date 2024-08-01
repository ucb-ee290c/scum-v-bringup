`timescale 1ns / 1ps

module Integrator_6(
    input         clock,
    input         reset,
    input  [6:0]  io_input,
    output [66:0] io_output
);
    reg [66:0] accum;
    always @(posedge clock) begin
        if (reset)
            accum <= 67'h0;
        else
            accum <= accum + {{60{io_input[6]}}, io_input};
    end
    assign io_output = accum;
endmodule

module Integrator_7(
    input         clock,
    input         reset,
    input  [66:0] io_input,
    output [66:0] io_output
);
    reg [66:0] accum;
    always @(posedge clock) begin
        if (reset)
            accum <= 67'h0;
        else
            accum <= accum + io_input;
    end
    assign io_output = accum;
endmodule
