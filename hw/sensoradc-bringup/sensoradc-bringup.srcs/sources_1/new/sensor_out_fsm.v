`timescale 1ns / 1ps

module SensorOutFSM(
    input clock,
    input reset,
    input io_adc_data_out_valid,
    input [19:0] io_adc_data_out_bits,
    output io_adc_sensor_out
);

reg [19:0] adc_data_out_buffer;
reg [7:0] adc_out_counter;
reg sync_marker;

wire [7:0] _io_adc_sensor_out_T = adc_out_counter % 8'h2;
wire [19:0] _io_adc_sensor_out_T_2 = adc_data_out_buffer >> adc_out_counter;
wire _GEN = adc_out_counter == 8'h27;

always @(posedge clock) begin
    if (reset) begin
        adc_data_out_buffer <= 20'h0;
        adc_out_counter <= 8'h0;
        sync_marker <= 1'h0;
    end else begin
        if (io_adc_data_out_valid)
            adc_data_out_buffer <= io_adc_data_out_bits;
        if (_GEN)
            adc_out_counter <= 8'h0;
        else
            adc_out_counter <= adc_out_counter + 8'h1;
        sync_marker <= ~_GEN & (adc_out_counter == 8'h13 | sync_marker);
    end
end

assign io_adc_sensor_out = sync_marker ? _io_adc_sensor_out_T[1:0] == 2'h0 : _io_adc_sensor_out_T_2[0];

endmodule
