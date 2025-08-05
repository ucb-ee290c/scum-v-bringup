    module a7top #(
    parameter CLOCK_FREQ = 100_000_000,
    parameter CLOCK_PERIOD = 1_000_000_000 / CLOCK_FREQ,
    parameter SCAN_CLK_FREQ    = 1000,
    parameter SCAN_CLK_PERIOD  = 1_000_000_000 / SCAN_CLK_FREQ,
    parameter CLKS_PER_SCAN_CLK = CLOCK_FREQ / SCAN_CLK_FREQ,

    parameter ADDR_BITS = 12,
    parameter PAYLOAD_BITS = 160,

    parameter BAUD_RATE = 1_000_000,
    
    // Sample the button signal every 500us
    parameter integer B_SAMPLE_CNT_MAX = 0.0005 * CLOCK_FREQ,
    // The button is considered 'pressed' after 100ms of continuous pressing
    parameter integer B_PULSE_CNT_MAX = 0.100 / 0.0005
)(
    input CLK100MHZ,
    input RESET,
    input BUTTON_0,

    output UART_RXD_IN,
    input UART_TXD_IN,

    output SCAN_CLK,
    output SCAN_EN,
    output SCAN_IN,
    output SCAN_RESET,
    output CHIP_RESET,
    
    // SerialTL interface to SCuM-V (TODO: Add to constraint file)
    input TL_CLK,        // TileLink clock from SCuM-V
    input TL_IN_VALID,   // Valid signal for data coming from SCuM-V 
    output TL_IN_READY,  // Ready signal for data coming from SCuM-V (connect to SCuM's TL_OUT_READY)
    input TL_IN_DATA,    // Serial data coming from SCuM-V (connect to SCuM's TL_OUT_DATA)
    output TL_OUT_VALID, // Valid signal for data going to SCuM-V
    input TL_OUT_READY,  // Ready signal for data going to SCuM-V
    output TL_OUT_DATA,  // Serial data going to SCuM-V

    output [3 : 0] led
);
    
    /* 
    The A7's reset button is high when not pressed. We use active high reset.
    */
    wire n_reset = ~RESET;
    wire FPGA_CLK = CLK100MHZ;

    // Protocol handler to subsystem interfaces
    wire [1:0] active_mode;
    wire [3:0] debug_state;
    
    // ASC subsystem interface
    wire asc_data_valid;
    wire asc_data_ready;
    wire [7:0] asc_data_out;
    wire asc_response_valid;
    wire asc_response_ready;
    wire [7:0] asc_response_data;
    
    // STL subsystem interface
    wire stl_data_valid;
    wire stl_data_ready;
    wire [7:0] stl_data_out;
    wire stl_response_valid;
    wire stl_response_ready;
    wire [7:0] stl_response_data;
    wire [7:0] debug_uart_data_in;
    wire [7:0] debug_packet_count;
    wire [4:0] debug_byte_count;
    wire [1:0] debug_stl_state;
    wire debug_bridge_packet_valid;
    wire debug_bridge_packet_ready;
    wire debug_serializer_in_ready;
    wire debug_serializer_in_valid;
    // Protocol multiplexer - handles "asc+" and "stl+" prefixes
    scumvcontroller_uart_handler #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uart_handler (
        .clk(FPGA_CLK),
        .reset(n_reset),
        
        // External UART interface
        .uart_rx(UART_TXD_IN),
        .uart_tx(UART_RXD_IN),
        
        // ASC subsystem FIFO interface
        .asc_data_valid(asc_data_valid),
        .asc_data_ready(asc_data_ready),
        .asc_data_out(asc_data_out),
        .asc_response_valid(asc_response_valid),
        .asc_response_ready(asc_response_ready),
        .asc_response_data(asc_response_data),
        
        // STL subsystem FIFO interface
        .stl_data_valid(stl_data_valid),
        .stl_data_ready(stl_data_ready),
        .stl_data_out(stl_data_out),
        .stl_response_valid(stl_response_valid),
        .stl_response_ready(stl_response_ready),
        .stl_response_data(stl_response_data),
        
        // Status and control
        .active_mode(active_mode),
        .debug_state(debug_state),
        .debug_uart_data_in(debug_uart_data_in),
        .debug_packet_count(debug_packet_count)
    );

    // ASC subsystem - handles scan chain operations
    scanchain_subsystem #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .CLKS_PER_SCAN_CLK(CLKS_PER_SCAN_CLK),
        .ADDR_BITS(ADDR_BITS),
        .PAYLOAD_BITS(PAYLOAD_BITS)
    ) asc_subsystem (
        .clk(FPGA_CLK),
        .reset(n_reset),
        
        // FIFO interface from UART handler
        .data_valid(asc_data_valid),
        .data_ready(asc_data_ready),
        .data_in(asc_data_out),
        
        // FIFO interface to UART handler (response)
        .response_valid(asc_response_valid),
        .response_ready(asc_response_ready),
        .response_data(asc_response_data),
        
        // Scan chain interface to SCuM-V
        .scan_clk(SCAN_CLK),
        .scan_en(SCAN_EN),
        .scan_in(SCAN_IN),
        .scan_reset(SCAN_RESET)
    );

    // STL subsystem - handles SerialTL operations
    serialtl_subsystem #(
        .CLOCK_FREQ(CLOCK_FREQ)
    ) stl_subsystem (
        .clk(FPGA_CLK),
        .reset(n_reset),
        
        // FIFO interface from UART handler
        .data_valid(stl_data_valid),
        .data_ready(stl_data_ready),
        .data_in(stl_data_out),
        
        // FIFO interface to UART handler (response)
        .response_valid(stl_response_valid),
        .response_ready(stl_response_ready),
        .response_data(stl_response_data),
        
        // SerialTL interface to SCuM-V
        .tl_clk(TL_CLK),
        .tl_in_valid(TL_IN_VALID),
        .tl_in_ready(TL_IN_READY),
        .tl_in_data(TL_IN_DATA),
        .tl_out_valid(TL_OUT_VALID),
        .tl_out_ready(TL_OUT_READY),
        .tl_out_data(TL_OUT_DATA),
        .debug_byte_count(debug_byte_count),
        .debug_state(debug_stl_state),
        .debug_bridge_packet_valid(debug_bridge_packet_valid),
        .debug_bridge_packet_ready(debug_bridge_packet_ready),
        .debug_serializer_in_ready(debug_serializer_in_ready),
        .debug_serializer_in_valid(debug_serializer_in_valid)
    );

    button_parser #(
        .WIDTH(1),
        .SAMPLE_CNT_MAX(B_SAMPLE_CNT_MAX),
        .PULSE_CNT_MAX(B_PULSE_CNT_MAX)
    ) bp (
        .clk(FPGA_CLK),
        .in(BUTTON_0),
        .out(CHIP_RESET)
    );

    assign led[0] = n_reset;
    assign led[1] = active_mode[0]; // ASC mode active
    assign led[2] = active_mode[1]; // STL mode active  
    assign led[3] = TL_IN_VALID;

    ila_0 ILA1 (
        .clk    (FPGA_CLK),
        .probe0 (stl_data_out),                     // 8 bit
        .probe1 ({debug_bridge_packet_valid, debug_bridge_packet_ready, debug_serializer_in_ready, debug_serializer_in_valid, debug_byte_count}),                     // 8 bit
        .probe2 (TL_CLK),                     // 1 bit
        .probe3 (stl_data_valid),                 // 1 bit
        .probe4 (TL_OUT_READY),                    // 1 bit
        .probe5 (TL_OUT_VALID),                  // 1 bit
        .probe6 (UART_TXD_IN),              // 1 bit
        .probe7 (stl_data_ready),                // 1 bit
        .probe8 ({2'b00, debug_stl_state})
    );
endmodule
