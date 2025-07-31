
module GenericSerializer(
  input         clock,
                reset,
  output        io_in_ready,
  input         io_in_valid,
  input  [2:0]  io_in_bits_chanId,
                io_in_bits_opcode,
                io_in_bits_param,
  input  [7:0]  io_in_bits_size,
                io_in_bits_source,
  input  [63:0] io_in_bits_address,
                io_in_bits_data,
  input         io_in_bits_corrupt,
  input  [8:0]  io_in_bits_union,
  input         io_in_bits_last,
                io_out_ready,
  output        io_out_valid,
                io_out_bits
);
  reg  [163:0] data;
  reg          sending;
  reg  [7:0]   sendCount;
  wire         wrap_wrap = sendCount == 8'hA3;
  wire         _GEN = io_out_ready & sending;
  wire         _GEN_0 = ~sending & io_in_valid;
  always @(posedge clock) begin
    if (_GEN)
      data <= {1'h0, data[163:1]};
    else if (_GEN_0)
      data <= {io_in_bits_chanId, io_in_bits_opcode, io_in_bits_param, io_in_bits_size, io_in_bits_source, io_in_bits_address, io_in_bits_data, io_in_bits_corrupt, io_in_bits_union, io_in_bits_last};
    if (reset) begin
      sending <= 1'h0;
      sendCount <= 8'h0;
    end
    else begin
      sending <= ~(_GEN & wrap_wrap) & (_GEN_0 | sending);
      if (_GEN) begin
        if (wrap_wrap)
          sendCount <= 8'h0;
        else
          sendCount <= sendCount + 8'h1;
      end
    end
  end // always @(posedge)
  assign io_in_ready = ~sending;
  assign io_out_valid = sending;
  assign io_out_bits = data[0];
endmodule
