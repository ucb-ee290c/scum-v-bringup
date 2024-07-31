`timescale 1ns / 1ps

module CICDecimator(
  input         clock,
                reset,
  input  [6:0]  io_input,
  output        io_output_valid,
  output [66:0] io_output_bits
);

  wire        _combs_2_io_output_valid;
  wire [66:0] _combs_2_io_output_bits;
  wire        _combs_1_io_output_valid;
  wire [66:0] _combs_1_io_output_bits;
  wire        _combs_0_io_output_valid;
  wire [66:0] _combs_0_io_output_bits;
  wire        _decimator_io_output_valid;
  wire [66:0] _decimator_io_output_bits;
  wire [66:0] _integrators_2_io_output;
  wire [66:0] _integrators_1_io_output;
  wire [66:0] _integrators_0_io_output;
  wire [66:0] _firstStage_io_output;

  Integrator_6 firstStage (
    .clock     (clock),
    .reset     (reset),
    .io_input  (io_input),
    .io_output (_firstStage_io_output)
  );

  Integrator_7 integrators_0 (
    .clock     (clock),
    .reset     (reset),
    .io_input  (_firstStage_io_output),
    .io_output (_integrators_0_io_output)
  );

  Integrator_7 integrators_1 (
    .clock     (clock),
    .reset     (reset),
    .io_input  (_integrators_0_io_output),
    .io_output (_integrators_1_io_output)
  );

  Integrator_7 integrators_2 (
    .clock     (clock),
    .reset     (reset),
    .io_input  (_integrators_1_io_output),
    .io_output (_integrators_2_io_output)
  );

  Decimator decimator (
    .clock           (clock),
    .reset           (reset),
    .io_input        (_integrators_2_io_output),
    .io_output_valid (_decimator_io_output_valid),
    .io_output_bits  (_decimator_io_output_bits)
  );

  Comb combs_0 (
    .clock           (clock),
    .reset           (reset),
    .io_input_valid  (_decimator_io_output_valid),
    .io_input_bits   (_decimator_io_output_bits),
    .io_output_valid (_combs_0_io_output_valid),
    .io_output_bits  (_combs_0_io_output_bits)
  );

  Comb combs_1 (
    .clock           (clock),
    .reset           (reset),
    .io_input_valid  (_combs_0_io_output_valid),
    .io_input_bits   (_combs_0_io_output_bits),
    .io_output_valid (_combs_1_io_output_valid),
    .io_output_bits  (_combs_1_io_output_bits)
  );

  Comb combs_2 (
    .clock           (clock),
    .reset           (reset),
    .io_input_valid  (_combs_1_io_output_valid),
    .io_input_bits   (_combs_1_io_output_bits),
    .io_output_valid (_combs_2_io_output_valid),
    .io_output_bits  (_combs_2_io_output_bits)
  );

  Comb combs_3 (
    .clock           (clock),
    .reset           (reset),
    .io_input_valid  (_combs_2_io_output_valid),
    .io_input_bits   (_combs_2_io_output_bits),
    .io_output_valid (io_output_valid),
    .io_output_bits  (io_output_bits)
  );
endmodule
