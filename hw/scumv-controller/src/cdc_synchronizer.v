/*
 * CDC Synchronizer Module
 * 
 * This module provides proper clock domain crossing synchronization
 * for both single-bit signals and handshaking interfaces.
 * 
 * Features:
 * - 2-stage flip-flop synchronizer for single signals
 * - Pulse synchronizer for single-cycle pulses
 * - Handshake synchronizer for valid/ready interfaces
 * - Configurable width for data synchronization
 */

module cdc_synchronizer #(
    parameter WIDTH = 1,
    parameter SYNC_STAGES = 2
)(
    input wire src_clk,
    input wire dst_clk,
    input wire reset,
    
    input wire [WIDTH-1:0] src_data,
    input wire src_valid,
    output wire src_ready,
    
    output wire [WIDTH-1:0] dst_data,
    output wire dst_valid,
    input wire dst_ready
);

    // Two-stage synchronizer registers
    reg [SYNC_STAGES-1:0] sync_req;
    reg [SYNC_STAGES-1:0] sync_ack;
    
    // Data holding register
    reg [WIDTH-1:0] data_reg;
    reg req_toggle;
    reg ack_toggle;
    
    // Source clock domain
    always @(posedge src_clk) begin
        if (reset) begin
            req_toggle <= 1'b0;
            data_reg <= {WIDTH{1'b0}};
        end else if (src_valid && src_ready) begin
            req_toggle <= ~req_toggle;
            data_reg <= src_data;
        end
    end
    
    // Destination clock domain - synchronize request
    always @(posedge dst_clk) begin
        if (reset) begin
            sync_req <= {SYNC_STAGES{1'b0}};
        end else begin
            sync_req <= {sync_req[SYNC_STAGES-2:0], req_toggle};
        end
    end
    
    // Source clock domain - synchronize acknowledgment
    always @(posedge src_clk) begin
        if (reset) begin
            sync_ack <= {SYNC_STAGES{1'b0}};
        end else begin
            sync_ack <= {sync_ack[SYNC_STAGES-2:0], ack_toggle};
        end
    end
    
    // Destination clock domain acknowledgment generation
    reg dst_valid_reg;
    always @(posedge dst_clk) begin
        if (reset) begin
            dst_valid_reg <= 1'b0;
            ack_toggle <= 1'b0;
        end else begin
            if (sync_req[SYNC_STAGES-1] != sync_req[SYNC_STAGES-2]) begin
                dst_valid_reg <= 1'b1;
            end else if (dst_valid && dst_ready) begin
                dst_valid_reg <= 1'b0;
                ack_toggle <= ~ack_toggle;
            end
        end
    end
    
    // Output assignments
    assign src_ready = (req_toggle == sync_ack[SYNC_STAGES-1]);
    assign dst_valid = dst_valid_reg;
    assign dst_data = data_reg;

endmodule

/*
 * Simple 2-stage synchronizer for single bits or level signals
 * Uses ASYNC_REG attributes for proper CDC recognition by Vivado
 * Industry standard implementation with Xilinx-specific optimizations
 */
module simple_synchronizer #(
    parameter WIDTH = 1,
    parameter SYNC_STAGES = 2
)(
    input wire clk,
    input wire [WIDTH-1:0] async_in,
    output wire [WIDTH-1:0] sync_out
);
    
    // Declare synchronizer registers with ASYNC_REG attribute
    // This tells Vivado these are CDC synchronizer registers
    (* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] sync_ff1;
    (* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] sync_ff2;
    
    // Optional third stage for extra metastability protection
    generate
        if (SYNC_STAGES >= 3) begin : gen_sync_ff3
            (* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] sync_ff3;
            always @(posedge clk) begin
                sync_ff1 <= async_in;
                sync_ff2 <= sync_ff1;
                sync_ff3 <= sync_ff2;
            end
            assign sync_out = sync_ff3;
        end else begin : gen_sync_2ff
            always @(posedge clk) begin
                sync_ff1 <= async_in;
                sync_ff2 <= sync_ff1;
            end
            assign sync_out = sync_ff2;
        end
    endgenerate
    
endmodule

/*
 * XPM_CDC-based synchronizer for Xilinx devices
 * Uses industry-standard Xilinx Parameterized Macros
 * Automatically includes all necessary attributes and optimizations
 */
module xpm_simple_synchronizer #(
    parameter WIDTH = 1
)(
    input wire src_clk,      // Source clock (optional - for handshaking)
    input wire dest_clk,     // Destination clock
    input wire [WIDTH-1:0] src_in,
    output wire [WIDTH-1:0] dest_out
);
    
    generate
        if (WIDTH == 1) begin : gen_single_bit
            // Use XPM_CDC_SINGLE for single-bit synchronization
            XPM_CDC_SINGLE #(
                .DEST_SYNC_FF(2),        // Number of sync FF stages (2-10)
                .INIT_SYNC_FF(0),        // Initial value of sync FFs
                .SIM_ASSERT_CHK(0),      // Enable simulation messages
                .SRC_INPUT_REG(0)        // No input register needed
            ) xpm_cdc_single_inst (
                .dest_out(dest_out),     // 1-bit output
                .dest_clk(dest_clk),     // 1-bit input: destination clock
                .src_in(src_in)          // 1-bit input: source signal
            );
        end else begin : gen_array_single
            // Use XPM_CDC_ARRAY_SINGLE for multi-bit level synchronization
            XPM_CDC_ARRAY_SINGLE #(
                .DEST_SYNC_FF(2),        // Number of sync FF stages (2-10)
                .INIT_SYNC_FF(0),        // Initial value of sync FFs
                .SIM_ASSERT_CHK(0),      // Enable simulation messages
                .SRC_INPUT_REG(0),       // No input register needed
                .WIDTH(WIDTH)            // Range: 1-1024
            ) xpm_cdc_array_single_inst (
                .dest_out(dest_out),     // WIDTH-bit output
                .dest_clk(dest_clk),     // 1-bit input: destination clock
                .src_in(src_in)          // WIDTH-bit input: source signal array
            );
        end
    endgenerate
    
endmodule

/*
 * Edge detector with proper CDC synchronization
 * Uses industry-standard 2-stage synchronizer
 */
module cdc_edge_detector (
    input wire clk,
    input wire async_reset_n, // Asynchronous reset (optional)
    input wire async_clk,
    output wire posedge_pulse,
    output wire negedge_pulse
);
    
    // Synchronize the async clock to our domain using standard 2-stage synchronizer
    wire sync_clk;
    
    (* ASYNC_REG = "TRUE", SHIFT_EXTRACT = "NO" *) reg sync_ff1;
    (* ASYNC_REG = "TRUE", SHIFT_EXTRACT = "NO" *) reg sync_ff2;
    
    always @(posedge clk or negedge async_reset_n) begin
        if (~async_reset_n) begin
            sync_ff1 <= 1'b0;
            sync_ff2 <= 1'b0;
        end else begin
            sync_ff1 <= async_clk;
            sync_ff2 <= sync_ff1;
        end
    end
    
    assign sync_clk = sync_ff2;
    
    // Edge detection with ASYNC_REG attribute
    (* ASYNC_REG = "TRUE" *) reg sync_clk_prev;
    always @(posedge clk or negedge async_reset_n) begin
        if (~async_reset_n) begin
            sync_clk_prev <= 1'b0;
        end else begin
            sync_clk_prev <= sync_clk;
        end
    end
    
    assign posedge_pulse = sync_clk && !sync_clk_prev;
    assign negedge_pulse = !sync_clk && sync_clk_prev;
    
endmodule

