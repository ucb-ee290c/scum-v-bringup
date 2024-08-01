`timescale 1ns / 1ps

module DSPClockDomainWrapper(
    input         clock,
    input         reset,
    input  [5:0]  io_adc_counter_p,
    input  [5:0]  io_adc_counter_n,
    input         io_chopper_control_chopper_div_1_valid,
    input  [24:0] io_chopper_control_chopper_div_1_bits,
    input         io_chopper_control_chopper_div_2_valid,
    input  [24:0] io_chopper_control_chopper_div_2_bits,
    input         io_chopper_control_chopper_clock_en_valid,
    input  [1:0]  io_chopper_control_chopper_clock_en_bits,
    input         io_dsp_control_valid,
    input  [7:0]  io_dsp_control_bits,
    output        io_adc_sensor_out,
    output        io_adc_data_out_valid,
    output [19:0] io_adc_data_out_bits,
    output        io_chopper_clock_1,
    output        io_chopper_clock_2,
    output [6:0]  io_adc_counter_diff,
    output [5:0]  io_adc_counter_p_diff,
    output [5:0]  io_adc_counter_n_diff
);
    wire        _cic_decim_io_output_valid;
    wire [66:0] _cic_decim_io_output_bits;
    wire [6:0]  _dechopper_io_output;
    wire        _secondStageGen_io_clock_gen;
    wire        _firstStageGen_io_clock_gen;
    reg  [12:0] rCtr;
    reg  [7:0]  dsp_control_buf;
    reg  [1:0]  chopper_clk_en_buf;
    reg  [24:0] firstStageDivider;
    wire        _io_chopper_clock_1_output = ~(chopper_clk_en_buf[0]) | _firstStageGen_io_clock_gen;
    reg  [24:0] secondStageDivider;
    wire        _io_chopper_clock_2_output = ~(chopper_clk_en_buf[1]) | _secondStageGen_io_clock_gen;
    reg  [5:0]  adc_counter_p_reg;
    reg  [5:0]  adc_counter_n_reg;
    reg  [5:0]  adc_counter_p_reg_z;
    reg  [5:0]  adc_counter_n_reg_z;
    wire [5:0]  _adc_counter_p_sub_T = adc_counter_p_reg - adc_counter_p_reg_z;
    wire [5:0]  _adc_counter_n_sub_T = adc_counter_n_reg - adc_counter_n_reg_z;
    wire [6:0]  _adc_counter_diff_T_2 = {1'h0, _adc_counter_p_sub_T} - {1'h0, _adc_counter_n_sub_T};
    reg         cic_decim_output_valid;
    reg  [66:0] cic_decim_output_bits;
    always @(posedge clock) begin
        adc_counter_p_reg <= io_adc_counter_p;
        adc_counter_n_reg <= io_adc_counter_n;
        adc_counter_p_reg_z <= adc_counter_p_reg;
        adc_counter_n_reg_z <= adc_counter_n_reg;
        cic_decim_output_valid <= _cic_decim_io_output_valid;
        cic_decim_output_bits <= _cic_decim_io_output_bits;
        if (reset) begin
            rCtr <= 13'h0;
            dsp_control_buf <= 8'h0;
            chopper_clk_en_buf <= 2'h0; 
            firstStageDivider <= 25'h0;
            secondStageDivider <= 25'h0;
        end
        else begin
            rCtr <= rCtr + 13'h1;
            if (io_dsp_control_valid) 
                dsp_control_buf <= io_dsp_control_bits;
            if (io_chopper_control_chopper_clock_en_valid) 
                chopper_clk_en_buf <= io_chopper_control_chopper_clock_en_bits;
            if (io_chopper_control_chopper_div_1_valid) 
                firstStageDivider <= io_chopper_control_chopper_div_1_bits;
            if (io_chopper_control_chopper_div_2_valid) 
                secondStageDivider <= io_chopper_control_chopper_div_2_bits;
        end
    end
    ClockGen firstStageGen (
        .clock        (clock),
        .reset        (reset),
        .io_divider   (firstStageDivider),
        .io_clock_gen (_firstStageGen_io_clock_gen)
    );
    ClockGen secondStageGen (
        .clock        (clock),
        .reset        (reset),
        .io_divider   (secondStageDivider),
        .io_clock_gen (_secondStageGen_io_clock_gen)
    );
    Dechopper dechopper (
        .clock                  (clock),
        .reset                  (reset),
        .io_input               (_adc_counter_diff_T_2),
        .io_output              (_dechopper_io_output),
        .io_chopper_clock       (dsp_control_buf[1] ? _io_chopper_clock_2_output : _io_chopper_clock_1_output),
        .io_chopper_clock_delay (dsp_control_buf[5:2])
    );
    CICDecimator cic_decim (
        .clock           (clock),
        .reset           (reset),
        .io_input        (dsp_control_buf[0] ? _dechopper_io_output : _adc_counter_diff_T_2),
        .io_output_valid (_cic_decim_io_output_valid),
        .io_output_bits  (_cic_decim_io_output_bits)
    );
    SensorOutFSM sensorOutFSM (
        .clock                 (clock),
        .reset                 (reset),
        .io_adc_data_out_valid (cic_decim_output_valid),
        .io_adc_data_out_bits  (cic_decim_output_bits[66:47]),
        .io_adc_sensor_out     (io_adc_sensor_out)
    );
    assign io_adc_data_out_valid = cic_decim_output_valid;
    assign io_adc_data_out_bits = cic_decim_output_bits[66:47];
    assign io_chopper_clock_1 = _io_chopper_clock_1_output;
    assign io_chopper_clock_2 = _io_chopper_clock_2_output;
    assign io_adc_counter_diff = _adc_counter_diff_T_2;
    assign io_adc_counter_p_diff = _adc_counter_p_sub_T;
    assign io_adc_counter_n_diff = _adc_counter_n_sub_T;
endmodule
