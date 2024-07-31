`timescale 1ns / 1ps

module Dechopper(
  input        clock,
               reset,
  input  [6:0] io_input,
  output [6:0] io_output,
  input        io_chopper_clock,
  input  [3:0] io_chopper_clock_delay
);

  reg         shiftReg_0;
  reg         shiftReg_1;
  reg         shiftReg_2;
  reg         shiftReg_3;
  reg         shiftReg_4;
  reg         shiftReg_5;
  reg         shiftReg_6;
  reg         shiftReg_7;
  reg         shiftReg_8;
  reg         shiftReg_9;
  reg         shiftReg_10;
  reg         shiftReg_11;
  reg         shiftReg_12;
  reg         shiftReg_13;
  reg         shiftReg_14;
  reg         shiftReg_15;
  wire [15:0] _GEN = {{shiftReg_15}, {shiftReg_14}, {shiftReg_13}, {shiftReg_12}, {shiftReg_11}, {shiftReg_10}, {shiftReg_9}, {shiftReg_8}, {shiftReg_7}, {shiftReg_6}, {shiftReg_5}, {shiftReg_4}, {shiftReg_3}, {shiftReg_2}, {shiftReg_1}, {shiftReg_0}};

  always @(posedge clock) begin
    if (reset) begin
      shiftReg_0 <= 1'h0;
      shiftReg_1 <= 1'h0;
      shiftReg_2 <= 1'h0;
      shiftReg_3 <= 1'h0;
      shiftReg_4 <= 1'h0;
      shiftReg_5 <= 1'h0;
      shiftReg_6 <= 1'h0;
      shiftReg_7 <= 1'h0;
      shiftReg_8 <= 1'h0;
      shiftReg_9 <= 1'h0;
      shiftReg_10 <= 1'h0;
      shiftReg_11 <= 1'h0;
      shiftReg_12 <= 1'h0;
      shiftReg_13 <= 1'h0;
      shiftReg_14 <= 1'h0;
      shiftReg_15 <= 1'h0;
    end
    else begin
      shiftReg_0 <= io_chopper_clock;
      shiftReg_1 <= shiftReg_0;
      shiftReg_2 <= shiftReg_1;
      shiftReg_3 <= shiftReg_2;
      shiftReg_4 <= shiftReg_3;
      shiftReg_5 <= shiftReg_4;
      shiftReg_6 <= shiftReg_5;
      shiftReg_7 <= shiftReg_6;
      shiftReg_8 <= shiftReg_7;
      shiftReg_9 <= shiftReg_8;
      shiftReg_10 <= shiftReg_9;
      shiftReg_11 <= shiftReg_10;
      shiftReg_12 <= shiftReg_11;
      shiftReg_13 <= shiftReg_12;
      shiftReg_14 <= shiftReg_13;
      shiftReg_15 <= shiftReg_14;
    end
  end

  assign io_output = (io_chopper_clock_delay == 4'h0 ? io_chopper_clock : _GEN[io_chopper_clock_delay - 4'h1]) ? io_input : io_input * 7'h7F;

endmodule
