`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/22/2024 06:53:00 PM
// Design Name: 
// Module Name: decimator
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Decimator(
    input         clock,
    reset,
    input  [58:0] io_input,
    output        io_output_valid,
    output [58:0] io_output_bits
);
    reg [12:0] counter;
    reg [58:0] outBuffer;
    reg        valBuffer;
    wire       _GEN_3 = counter == 13'h0;
    always @(posedge clock) begin
        if (reset) begin
            counter   <= 13'h0;
            outBuffer <= 59'h0;
            valBuffer <= 1'h0;
        end 
        else begin
            if (_GEN_3 | counter != 13'h1F3F)
                counter <= counter + 13'h1;
            else
                counter <= 13'h0;
            if (_GEN_3)
                outBuffer <= io_input;
            valBuffer <= _GEN_3;
        end
    end
    assign io_output_valid = valBuffer;
    assign io_output_bits = outBuffer;
endmodule