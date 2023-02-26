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


module osciTop (
    input CLK12MHZ,
    input rstBtn,
    // UART
    input uart_rx,
    output uart_tx,
    
    // TileLink
    // Clock signal
    // input tl_clk,
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
    wire tl_rising_clk, rst, triggerReset, CLK100MHZ, CLK10MHZ;
    assign rst = rstBtn || dutReset;
    assign led[0] = rst;
    //ila_0(  .clk(CLK12MHZ), .probe0(CLKSRC), .probe1(uart_rx),
    //    .probe2(uart_tx), .probe3(tl_clk), .probe4(tl_out_valid),
    //    .probe5(tl_out_rd), .probe6(tl_out_data), .probe7(tl_in_valid),
    //    .probe8(tl_in_rd), .probe9(tl_in_data));         
    clk_wiz_0(.clk_in1(CLK12MHZ), .clk_out1(), .clk_out2(CLK10MHZ), .clk_out3(CLK100MHZ));
    
    // divide 10 MHz by 1000 so we can have a reasonable clock frequency..
    reg [9:0] ctr;
    always @(posedge CLK12MHZ) begin
        if (rst || ctr >= 125)
            ctr <= 'd0;
        else
            ctr <= ctr + 'd1;
    end
    assign CLKSRC = ((ctr < 63) && ~rst);
    
    /*
    assign uart_tx = tx_reg;
    always @(posedge CLK100MHZ) begin
        tx_reg <= uart_rx;
    end
    */
    localparam SYSCLK = 12_000_000;
    localparam WIDTH = 123;
    localparam BAUD = 19_200;

    uartToTsi #(.SYSCLK(SYSCLK), .WIDTH(WIDTH), .BAUD(BAUD)) tx (
        .clk(CLK12MHZ),
        .rst(rst),
        .uart_rx(uart_rx),
        .tl_rising_clk(tl_rising_clk),
        .tl_out_rd(tl_out_rd),
        .tl_out_data(tl_out_data),
        .tl_out_valid(tl_out_valid),
        .RESET(triggerReset)
    );

    tsiToUart #(.SYSCLK(SYSCLK), .WIDTH(WIDTH), .BAUD(BAUD)) rx (
        .clk(CLK12MHZ),
        .rst(rst),
        .uart_tx(uart_tx),
        .tl_rising_clk(tl_rising_clk),
        .tl_in_rd(tl_in_rd),
        .tl_in_data(tl_in_data),
        .tl_in_valid(tl_in_valid)
    );

    EdgeDetector tlClkEdge (
        .clk(CLK12MHZ),
        .rst(rst),
        .in(CLKSRC),
        .rising(tl_rising_clk)
        //.falling(),
    );
    
    resetTop #(.TIME(12_000_000)) resetter (
        .clk(CLK12MHZ ),
        .trigger(triggerReset),
        .dutReset(dutReset)
    );
    
endmodule
