`timescale 1ns / 1ps

module ClockGen(
    input clock,
    input reset,
    input [24:0] io_divider,
    output io_clock_gen
);

reg [25:0] counter;

always @(posedge clock) begin
    if (reset)
        counter <= 26'h0;
    else if (counter == {1'h0, io_divider})
        counter <= 26'h0;
    else
        counter <= counter + 26'h1;
end

assign io_clock_gen = counter <= {2'h0, io_divider[24:1]};

endmodule