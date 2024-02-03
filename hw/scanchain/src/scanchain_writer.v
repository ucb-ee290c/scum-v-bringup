module scanchain_writer #(
    parameter CLOCK_FREQ = 100_000_000,
    parameter CLOCKS_PER_SCAN_CLK = 1_000, /* produces a scan_clk of 100KHz */
    parameter ADDR_BITS = 12,
    parameter PAYLOAD_BITS = 160
) (
    input clk,
    input reset,
    
    output write_ready,
    input write_valid,
    input [ADDR_BITS - 1:0] write_addr,
    input [PAYLOAD_BITS - 1:0] write_payload,
    input write_reset,

    output reg scan_clk,
    output reg scan_en,
    output scan_in,
    output reg scan_reset
);

localparam TX_BUFFER_SIZE = (ADDR_BITS + PAYLOAD_BITS);
localparam TX_BUFFER_BIT_SIZE = $clog2(TX_BUFFER_SIZE);
localparam TX_BUFFER_COUNTER_MAX = TX_BUFFER_SIZE;

localparam SCAN_CLK_COUNTER_MAX = CLOCKS_PER_SCAN_CLK;
localparam SCAN_CLK_COUNTER_BIT_SIZE = $clog2(SCAN_CLK_COUNTER_MAX);
localparam SCAN_CLK_COUNTER_HALF_PERIOD = ((SCAN_CLK_COUNTER_MAX) / 2);

reg [SCAN_CLK_COUNTER_BIT_SIZE - 1 : 0] scan_clk_counter;
reg internalized_write_valid;
reg [TX_BUFFER_SIZE - 1 : 0] internalized_tx_buffer;
reg [TX_BUFFER_BIT_SIZE - 1 : 0] tx_buffer_counter;
reg internalized_write_reset;
wire _scan_clk_posedge, _scan_clk_negedge;
wire keep_scanning;

wire [ADDR_BITS - 1:0] write_addr_be;
wire [PAYLOAD_BITS - 1:0] write_payload_be;

/* Flip the addr and payload */
genvar i;
generate
    for (i = 0; i < ADDR_BITS; i = i + 1) begin
        assign write_addr_be[i] = write_addr[ADDR_BITS - 1 - i];
    end
endgenerate
generate
    for (i = 0; i < PAYLOAD_BITS; i = i + 1) begin
        assign write_payload_be[i] = write_payload[PAYLOAD_BITS - 1 - i];
    end
endgenerate

always @(posedge clk) begin
    if (reset) begin
        scan_clk_counter <= 0;
    end
    else if (scan_clk_counter == SCAN_CLK_COUNTER_MAX) begin
        scan_clk_counter <= 0;
    end
    else begin
        scan_clk_counter <= scan_clk_counter + 1;
    end
end
/* We want a clock cycle that's inactive low, so have cnt=0 low */
assign _scan_clk_negedge = scan_clk_counter == 0;
assign _scan_clk_posedge = scan_clk_counter == SCAN_CLK_COUNTER_HALF_PERIOD;

/* Manage tx_buffer_counter */
always @(posedge clk) begin
    if (reset || !internalized_write_valid) begin
        tx_buffer_counter <= 0;
    end
    else if (_scan_clk_negedge) begin
        tx_buffer_counter <= tx_buffer_counter + 1;
    end
    else begin
        tx_buffer_counter <= tx_buffer_counter;
    end
end

/* Manage internalize */
assign write_ready = !internalized_write_valid && !scan_en;
/* Hold write valid high until we reach the end of the transmit */ 
assign keep_scanning = internalized_write_valid 
                        && tx_buffer_counter != TX_BUFFER_COUNTER_MAX;
always @(posedge clk) begin
    if (reset) begin
       internalized_write_valid <= 0; 
       internalized_tx_buffer <= 'bx;
       internalized_write_reset <= 'bx;
    end
    else if (write_ready && write_valid) begin
        /* Ready to internalize! */
        internalized_write_valid <= 1;
        internalized_tx_buffer <= {write_payload_be, write_addr_be};
        internalized_write_reset <= write_reset;
    end
    else begin
        /* 
        To make transmission simple, we use the tx buffer as a shift register.
        We ratchet it down one on each scan clock edge.
        Note though that since we start on a negedge (inactive low), we don't
        want to ratchet on the first negedge (counter=0).
        */
        if (_scan_clk_negedge && tx_buffer_counter != 0) begin
            internalized_tx_buffer <= 
                {1'bx, internalized_tx_buffer[TX_BUFFER_SIZE - 1 : 1]};
            internalized_write_valid <= keep_scanning;
        end
        else begin
            internalized_tx_buffer <= internalized_tx_buffer;
            internalized_write_valid <= internalized_write_valid;
        end

        internalized_write_reset <= internalized_write_reset;
    end
end
assign scan_in = internalized_tx_buffer[0];

/* Manage scan_clk */
always @(posedge clk) begin
    if (reset) begin
        scan_clk <= 0;
    end
    else if (_scan_clk_posedge) begin
        scan_clk <= 1;
    end
    else if (_scan_clk_negedge) begin
        scan_clk <= 0;
    end
    else begin
        scan_clk <= scan_clk;
    end
end

always @(posedge clk) begin
    if (reset) begin
        scan_en <= 0;
        scan_reset <= 0;
    end
    else if (_scan_clk_negedge) begin
        scan_en <= keep_scanning;
        scan_reset <= keep_scanning && internalized_write_reset;
    end
    else begin
        scan_en <= scan_en;
        scan_reset <= scan_reset;
    end
end

endmodule