module fifo #(
  parameter WIDTH = 8,
  parameter DEPTH = 32,
  parameter POINTER_WIDTH = $clog2(DEPTH)
) (
  input clk, rst,

  // Write side
  input wr_en,
  input [WIDTH-1:0] din,
  output full,

  // Read side
  input rd_en,
  output [WIDTH-1:0] dout,
  output empty
);
  /* Registers. */
  reg [WIDTH-1:0] fifo [DEPTH-1:0];
  reg [POINTER_WIDTH-1:0] rd_ptr;
  reg [POINTER_WIDTH-1:0] wr_ptr;
  reg [WIDTH-1:0] dout_reg;

  /* Helper variables for the circular buffer. */
  wire [POINTER_WIDTH-1:0] rst_ptr;
  reg [POINTER_WIDTH:0] counter;
  reg [POINTER_WIDTH:0] counter_next;
  reg rd_cnt;
  reg wr_cnt;

  /* Debug variables. */
  // Set this variable to be true to run the display messages.
  // To be used in simulation.
  wire debug = 0;

  /* Helper assignments. */
  assign rst_ptr = 0;

  /* Output assignments. */
  assign full = counter == DEPTH;
  assign empty = counter == 0;
  assign dout = dout_reg;

  /* Counter logic. */
  always @ (posedge clk) begin
    rd_cnt = 0;
    wr_cnt = 0;
    if (rst) begin
      counter_next = 0;
    end else if (counter == 0) begin
      if (wr_en && counter < DEPTH) begin
        wr_cnt = 1;
        if (rd_en) begin
          rd_cnt = 1;
        end
      end
      /* verilator lint_off WIDTH */
      counter_next = counter - rd_cnt + wr_cnt;
      /* lint_on */
    end else begin
      if (rd_en && counter > 0) begin
        rd_cnt = 1;
      end
      if (wr_en && counter < DEPTH) begin
        wr_cnt = 1;
      end
      counter_next = counter - rd_cnt + wr_cnt;
    end
  end

  /* Read and write logic. */
  always @ (posedge clk) begin
    if (rst) begin
      // Reset to defaults.
      rd_ptr <= rst_ptr;
      wr_ptr <= rst_ptr;
      counter <= 0;
      dout_reg <= 0;
    end 
    else if (counter == 0) begin
      // The main action we can do here is a write.
      if (wr_en && counter < DEPTH) begin
        fifo[wr_ptr] <= din;

        if (debug) begin
          $display("%d: fifo[%d] : W %d -> %d",
            $time, wr_ptr, fifo[wr_ptr], din);
        end
        wr_ptr <= (wr_ptr + 1) % DEPTH;
        // If we have a write and read in the same cycle here,
        // it should still be valid. HOWEVER, we should write first,
        // and then read what we have just written.
        if (rd_en) begin
          // Since the write won't happen until the next cycle,
          // we should read the DIN from this current cycle.
          dout_reg <= din;
          rd_ptr <= (rd_ptr + 1) % DEPTH;

          if (debug) begin
            $display("%d: fifo[%d] : R %d",
              $time, rd_ptr, din);
          end
        end
      end
      counter <= counter_next;
    end 
    else begin
      // Check first off if we want to read this cycle.
      if (rd_en && counter > 0) begin
        dout_reg <= fifo[rd_ptr];
        rd_ptr <= (rd_ptr + 1) % DEPTH;

        if (debug) begin
          $display("%d: fifo[%d] : R %d",
            $time, rd_ptr, fifo[rd_ptr]);
        end
      end
      // Then check if we want to (potentially also) write this cycle.
      if (wr_en && counter < DEPTH) begin
        fifo[wr_ptr] <= din;
        wr_ptr <= (wr_ptr + 1) % DEPTH;

        if (debug) begin
          $display("%d: fifo[%d] : W %d -> %d",
            $time, wr_ptr, fifo[wr_ptr], din);
        end
      end
      counter <= counter_next;
    end
  end

endmodule
