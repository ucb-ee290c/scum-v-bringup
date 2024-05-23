module a7top #(
    parameter CLOCK_FREQ = 100_000_000,
    parameter CLOCK_PERIOD = 1_000_000_000 / CLOCK_FREQ,
    parameter SCAN_CLK_FREQ    = 1000,
    parameter SCAN_CLK_PERIOD  = 1_000_000_000 / SCAN_CLK_FREQ,
    parameter CLKS_PER_SCAN_CLK = CLOCK_FREQ / SCAN_CLK_FREQ,


    parameter BAUD_RATE = 115_200

)(
    input CLK100MHZ,
    input RESET,
    input BUTTON_0,

    output UART_RXD_IN,
    input UART_TXD_IN,

    input [5 : 0] ADC_COUNTER,
    input ADC_CLOCK,

    output [3 : 0] led
);
    
    /* 
    The A7's reset button is high when not pressed. We use active high reset.
    */
    wire n_reset = ~RESET;
    wire uart_valid;
    wire uart_ready;

    wire write_reset;
    wire FPGA_CLK = CLK100MHZ;

    // DDR splitter to recover counter_p and counter_n from ADC_COUNTER
    wire [5:0] counter_p;
    wire [5:0] counter_n;
    
    ddr_splitter ddr_splitter (
        .clk(ADC_CLOCK),
        .ddr_counter(ADC_COUNTER),
        .counter_p(counter_p),
        .counter_n(counter_n)
    );


    assign led[0] = n_reset;
    assign led[1] = SCAN_EN;
    assign led[2] = SCAN_CLK;
    assign led[3] = SCAN_IN;
endmodule
