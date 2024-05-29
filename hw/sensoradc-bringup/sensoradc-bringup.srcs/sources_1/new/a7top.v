module a7top #(
    parameter CLOCK_FREQ = 100_000_000,
    parameter CLOCK_PERIOD = 1_000_000_000 / CLOCK_FREQ,
    parameter BAUD_RATE = 1_000_000

)(
    input CLK100MHZ,
    input RESET,
    input BUTTON_0,

    output UART_RXD_IN,
    input UART_TXD_IN,

    input [5 : 0] ADC_COUNTER,
    input ADC_CLOCK,

    output SENSOR_OUT,

    output [3 : 0] led
);

    // We need to buffer the ADC_CLOCK signal to drive the DSPClockDomainWrapper
    wire adc_clock_ibuf;
    wire adc_clock_bufr;


    IBUF #(
        .IBUF_LOW_PWR("TRUE"),
        .IOSTANDARD("DEFAULT")
    ) adc_clock_ibuf_inst (
        .O(adc_clock_ibuf),
        .I(ADC_CLOCK)
    );


    BUFR #(
        .BUFR_DIVIDE("BYPASS"),
        .SIM_DEVICE("7SERIES")
    ) adc_clock_bufr_inst (
        .O(adc_clock_bufr),
        .I(adc_clock_ibuf),
        .CE(1'b1),
        .CLR(1'b0)
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
        .clk(adc_clock_bufr),
        .ddr_counter(ADC_COUNTER),
        .counter_p(counter_p),
        .counter_n(counter_n)
    );

    wire translator_data_in_ready;
    wire [7:0] translator_data_out;
    wire translator_data_out_valid;
    wire [19:0] adc_data_out_bits;
    wire adc_data_out_valid;


    data_translator #(
        .INPUT_WIDTH(20),
        .OUTPUT_WIDTH(8),
        .FIFO_DEPTH(32)
    ) data_translator_inst (
        .clk(CLK100MHZ),
        .rst(n_reset),
        .data_in(adc_data_out_bits),
        .data_in_valid(adc_data_out_valid),
        .data_in_ready(translator_data_in_ready),
        .data_out(translator_data_out),
        .data_out_valid(translator_data_out_valid),
        .data_out_ready(uart_data_in_ready)
    );

    // Instantiate the UART module
    uart #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uart_inst (
        .clk(CLK100MHZ),
        .reset(n_reset),
        .data_in(translator_data_out),
        .data_in_valid(translator_data_out_valid),
        .data_in_ready(uart_data_in_ready),
        .data_out(),
        .data_out_valid(),
        .data_out_ready(1'b1),
        .serial_in(UART_TXD_IN),
        .serial_out(UART_RXD_IN)
    );


    // Instantiate the DSPClockDomainWrapper, which contains the CIC filter and decimator
    // Connect the counter_p and counter_n outputs of the DDR splitter to the DSPClockDomainWrapper
    DSPClockDomainWrapper dspClockDomainWrapper (
        .clock      (adc_clock_bufr),
        .reset      (n_reset),
        .io_adc_counter_p(counter_p),
        .io_adc_counter_n(counter_n),
        .io_adc_sensor_out(SENSOR_OUT),
        .io_adc_data_out_valid(adc_data_out_valid),
        .io_adc_data_out_bits(adc_data_out_bits),
        .io_chopper_clock_1(),
        .io_chopper_clock_2(),
        .io_adc_counter_diff(),
        .io_adc_counter_p_diff(),
        .io_adc_counter_n_diff()
    );
    
    ila_0 ila(
        .clk(CLK100MHZ),
        
        .probe0(counter_p),
        .probe1(counter_n),
        .probe2(adc_data_out_bits),
        .probe3(translator_data_out),
        .probe4(adc_data_out_valid),
        .probe5(translator_data_out_valid),
        .probe6(UART_RXD_IN),
        .probe7(SENSOR_OUT)
    );


    assign led[0] = n_reset;
endmodule
