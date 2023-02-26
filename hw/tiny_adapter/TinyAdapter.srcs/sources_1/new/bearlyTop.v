`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Franklin Huang
// 
// Create Date: 09/26/2022 08:35:12 PM
// Design Name: 
// Module Name: chiptop
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


module bearlyTop (
    input CLK100MHZ,
    input rstBtn,
    // UART
    input uart_rx,
    output uart_tx,
    
    // TileLink
    // Clock signal
    //input tl_clk,
    // FPGA to testchip link
    output tl_out_valid,
    input tl_out_rd,
    output tl_out_data,
    // testchip to FPGA link
    input tl_in_valid,
    output tl_in_rd,
    input tl_in_data,
    // RESET is high when TSI/UART packets are all one
    output dutReset,
    output CLKSRC,
    output [0:0] led
);
    wire tl_rising_clk, rst, triggerReset, CLK100MHZ, tl_clk;
    assign rst = rstBtn || dutReset;
    assign led[0] = rst;
    ila_0(  .clk(CLK100MHZ), .probe0(CLKSRC), .probe1(uart_rx),
            .probe2(uart_tx), .probe3(tl_clk), .probe4(tl_out_valid),
            .probe5(tl_out_rd), .probe6(tl_out_data), .probe7(tl_in_valid),
            .probe8(tl_in_rd), .probe9(tl_in_data));
            
    clk_wiz_1(.clk_in1(CLK100MHZ), .clk_out1(tl_clk), .clk_out2(CLKSRC));
    /*
    assign uart_tx = tx_reg;
    always @(posedge CLK100MHZ) begin
        tx_reg <= uart_rx;
    end
    */
    localparam SYSCLK = 100_000_000;
    localparam WIDTH = 126;
    localparam BAUD = 2_000_000;

    uartToTsi #(.SYSCLK(SYSCLK), .WIDTH(WIDTH), .BAUD(BAUD)) tx (
        .clk(CLK100MHZ),
        .rst(rst),
        .uart_rx(uart_rx),
        .tl_rising_clk(tl_rising_clk),
        .tl_out_rd(tl_out_rd),
        .tl_out_data(tl_out_data),
        .tl_out_valid(tl_out_valid),
        .RESET(triggerReset)
    );

    tsiToUart #(.SYSCLK(SYSCLK), .WIDTH(WIDTH), .BAUD(BAUD)) rx (
        .clk(CLK100MHZ),
        .rst(rst),
        .uart_tx(uart_tx),
        .tl_rising_clk(tl_rising_clk),
        .tl_in_rd(tl_in_rd),
        .tl_in_data(tl_in_data),
        .tl_in_valid(tl_in_valid)
    );

    EdgeDetector tlClkEdge (
        .clk(CLK100MHZ),
        .rst(rst),
        .in(tl_clk),
        .rising(tl_rising_clk)
        //.falling(),
    );
    
    resetTop #(.TIME(100_000_000)) resetter (
        .clk(CLK100MHZ),
        .trigger(triggerReset || rstBtn),
        .dutReset(dutReset)
    );
    
endmodule
