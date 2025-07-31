module debouncer #(
  parameter WIDTH              = 1,
  parameter SAMPLE_CNT_MAX     = 62500,
  parameter PULSE_CNT_MAX      = 200,
  parameter WRAPPING_CNT_WIDTH = $clog2(SAMPLE_CNT_MAX),
  parameter SAT_CNT_WIDTH      = $clog2(PULSE_CNT_MAX) + 1
) (
  input clk,
  input [WIDTH-1:0] glitchy_signal,
  output [WIDTH-1:0] debounced_signal
);
  // TODO: fill in neccesary logic to implement the wrapping counter and the saturating counters
  // Some initial code has been provided to you, but feel free to change it however you like
  // One wrapping counter is required
  // One saturating counter is needed for each bit of glitchy_signal
  // You need to think of the conditions for reseting, clock enable, etc. those registers
  // Refer to the block diagram in the spec

  // -- BEGIN SAMPLE PULSE GENERATOR --
  reg [WRAPPING_CNT_WIDTH-1:0] wrapping_cnt = 0;
  reg sample_pulse_gen = 0;

  always @(posedge clk) begin
    if (wrapping_cnt == SAMPLE_CNT_MAX) begin
      // restart counter
      wrapping_cnt <= 0;
    end else begin 
      wrapping_cnt <= wrapping_cnt + 1;
    end            
  end

  always @(*) begin
    if (wrapping_cnt == SAMPLE_CNT_MAX) begin
      sample_pulse_gen = 1'b1;
    end else begin 
      sample_pulse_gen = 1'b0;
    end
  end

  // -- END SAMPLE PULSE GENERATOR --

  // -- BEGIN SATURATING COUNTER --
  reg [SAT_CNT_WIDTH-1:0] saturating_counter [WIDTH-1:0];
  // initialize counter
  integer k;
  initial begin
    for (k = 0; k < WIDTH; k = k + 1) begin
      saturating_counter[k] = 0;
    end
  end

  wire [WIDTH-1:0] enable;
  wire [WIDTH-1:0] reset;
  
  assign enable = {WIDTH{sample_pulse_gen}} & glitchy_signal;
  assign reset = ~glitchy_signal;

  genvar i;

  generate
    for (i = 0; i < WIDTH; i = i + 1) begin          
      always @(posedge clk) begin
        // logic for the sat counter for the ith bit
        if (enable[i]) begin
          // inc counter if less than max
          if (saturating_counter[i] < PULSE_CNT_MAX) begin
            saturating_counter[i] <= saturating_counter[i] + 1;
          end
        end
        if (reset[i]) begin
          // set counter to 0
          saturating_counter[i] <= 0;
        end
      end

      assign debounced_signal[i] = (saturating_counter[i] == PULSE_CNT_MAX);
    end
  endgenerate
  
endmodule