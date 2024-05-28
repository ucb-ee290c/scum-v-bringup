module uart_transmitter #(
  parameter CLOCK_FREQ = 125_000_000,
  parameter BAUD_RATE = 115_200
) (
  input clk,
  input rst,

  input [7:0] data_in,
  input data_in_valid,
  output data_in_ready,

  output serial_out
);
  // See diagram in the lab guide
  localparam  SYMBOL_EDGE_TIME    =   CLOCK_FREQ / BAUD_RATE;
  localparam  CLOCK_COUNTER_WIDTH =   $clog2(SYMBOL_EDGE_TIME);

  wire symbol_edge;
  wire tx_running;

  reg [9:0] tx_shift;
  reg [3:0] bit_counter;
  reg [CLOCK_COUNTER_WIDTH-1:0] clock_counter;
  reg bit_out;

  //--|Signal Assignments|------------------------------------------------------

  // Goes high at every symbol edge.
  /* verilator lint_off WIDTH */
  assign symbol_edge = clock_counter == (SYMBOL_EDGE_TIME - 1);
  /* lint_on */

  assign tx_running = bit_counter != 4'd0;

  // Outputs
  assign serial_out = bit_out;
  assign data_in_ready = !tx_running;

  always @ (posedge clk) begin
    clock_counter <=
      (rst || symbol_edge || (bit_counter == 0 && data_in_valid)) ?
      0 : clock_counter + 1;
  end

  always @ (posedge clk) begin
      if (rst) begin
          bit_counter <= 0;
      end else if (data_in_valid && !tx_running) begin
          bit_counter <= 10;
      end else if (symbol_edge && tx_running) begin
          bit_counter <= bit_counter - 1;
      end
  end

  always @ (posedge clk) begin
    if (rst) begin
            bit_out <= 1'b1;
    end else if (data_in_valid && !tx_running) begin
      // Store data when READY and VALID
      // Receive the data
      tx_shift <= {2'b11, data_in};
            bit_out <= 1'b0;
    end else if (symbol_edge && tx_running) begin
      bit_out <= tx_shift[0];
      tx_shift <= {1'b1, tx_shift[9:1]};
    end
  end
endmodule