`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/05/2022 10:31:31 PM
// Design Name: 
// Module Name: traffic_adapter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module traffic_adapter #(
    parameter BAUD_RATE = 2_000_000,
    parameter SYSCLK = 100_000_000,
    parameter WIDTH = 123
) (
    input clk,
    input rst,
    // UART lines
    input uart_rx,
    output uart_tx,
    
    // TileLink
    // Clock signal
    input tl_clk,
    // FPGA to testchip link
    output tl_out_valid,
    input tl_out_rd,
    output tl_out_data,
    // testchip to FPGA link
    input tl_in_valid,
    output tl_in_rd,
    input tl_in_data
);
    wire tl_rising_clk;

    /*
    assign uart_tx = tx_reg;
    always @(posedge CLK100MHZ) begin
        tx_reg <= uart_rx;
    end
    */

    uartToTsi #(.SYSCLK(SYSCLK), .WIDTH(WIDTH), .BAUD(BAUD_RATE)) tx (
        .clk(clk),
        .rst(rst),
        .uart_rx(uart_rx),
        .tl_rising_clk(tl_rising_clk),
        .tl_out_rd(tl_out_rd),
        .tl_out_data(tl_out_data),
        .tl_out_valid(tl_out_valid),
        .RESET(RESET)
    );

    tsiToUart #(.SYSCLK(SYSCLK), .WIDTH(WIDTH), .BAUD(BAUD_RATE)) rx (
        .clk(clk),
        .rst(rst),
        .uart_tx(uart_tx),
        .tl_rising_clk(tl_rising_clk),
        .tl_in_rd(tl_in_rd),
        .tl_in_data(tl_in_data),
        .tl_in_valid(tl_in_valid)
    );

    EdgeDetector tlClkEdge (
        .clk(clk),
        .rst(rst),
        .in(tl_clk),
        .rising(tl_rising_clk)
        //.falling(),
    );
endmodule
