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

    // We need to buffer the ADC_CLOCK signal to drive the DSPClockDomainWrapper
    wire adc_clock_ibuf;
    wire adc_clock_bufg;

    IBUF #(
        .IBUF_LOW_PWR("TRUE"),
        .IOSTANDARD("DEFAULT")
    ) adc_clock_ibuf_inst (
        .O(adc_clock_ibuf),
        .I(ADC_CLOCK)
    );

    BUFG adc_clock_bufg_inst (
        .O(adc_clock_bufg),
        .I(adc_clock_ibuf)
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
        .clk(adc_clock_bufg),
        .ddr_counter(ADC_COUNTER),
        .counter_p(counter_p),
        .counter_n(counter_n)
    );

    // Instantiate the DSPClockDomainWrapper, which contains the CIC filter and decimator
    // Connect the counter_p and counter_n outputs of the DDR splitter to the DSPClockDomainWrapper
    DSPClockDomainWrapper dspClockDomainWrapper (
        .clock      (adc_clock_bufg),
        .reset      (n_reset),
        .io_adc_counter_p(counter_p),
        .io_adc_counter_n(counter_n),
        .io_adc_sensor_out(UART_RXD_IN),
        .io_adc_data_out_valid(uart_valid),
        .io_adc_data_out_bits(8'h00),
        .io_chopper_clock_1(),
        .io_chopper_clock_2(),
        .io_adc_counter_diff(),
        .io_adc_counter_p_diff(),
        .io_adc_counter_n_diff()
    );


    assign led[0] = n_reset;
    assign led[1] = SCAN_EN;
    assign led[2] = SCAN_CLK;
    assign led[3] = SCAN_IN;
endmodule
