`timescale 1ns / 1ps

module Integrator_6(
    input         clock,
    reset,
    input  [6:0]  io_input,
    output [58:0] io_output
);
    reg [58:0] accum;
    always @(posedge clock) begin
        if (reset)
            accum <= 59'h0;
        else
            accum <= accum + {{52{io_input[6]}}, io_input};
    end
    assign io_output = accum;
endmodule

module Integrator_7(
    input         clock,
    reset,
    input  [58:0] io_input,
    output [58:0] io_output
);
    reg [58:0] accum;
    always @(posedge clock) begin
        if (reset)
            accum <= 59'h0;
        else
            accum <= accum + io_input;
    end
    assign io_output = accum;
endmodule