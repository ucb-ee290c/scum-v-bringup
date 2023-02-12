module synchronizer #(parameter WIDTH = 1) (
  input [WIDTH-1:0] async_signal,
  input clk,
  output reg [WIDTH-1:0] sync_signal
);
  // This module takes in a vector of WIDTH-bit asynchronous
  // (from different clock domain or not clocked, such as button press) signals
  // and should output a vector of WIDTH-bit synchronous signals
  // that are synchronized to the input clk

  reg [WIDTH-1:0] x;
  genvar i;

  generate
    for (i = 0; i < WIDTH; i = i + 1) begin
      always @(posedge clk) begin
        x[i] <= async_signal[i];
        sync_signal[i] <= x[i];
      end
    end
  endgenerate
    
endmodule