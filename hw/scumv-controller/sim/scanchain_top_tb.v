`timescale 1ns/1ns
`define CLK_PERIOD 8
`define CLOCK_FREQ 20
`define SCAN_CLK_FREQ 4
`define ADDR_BITS 12
`define PAYLOAD_BITS 169
`define BAUD_RATE 1

module scanchain_top_tb();
    /* Generate the simulated clock */
    reg clk = 0;
    always #(`CLK_PERIOD/2) clk <= ~clk;
    localparam PACKET_BIT_SIZE = 169 + 12 + 1 + 2;

    wire [4:0] SUPPLY_bgr_temp_ctrl;
    wire [4:0] SUPPLY_bgr_vref_ctrl;
    wire [4:0] SUPPLY_current_src_left_ctrl;
    wire [4:0] SUPPLY_current_src_right_ctrl;
    wire [15:0] OSC_adc_tune_out;
    wire OSC_adc_reset;
    wire [15:0] OSC_dig_tune_out;
    wire OSC_dig_reset;
    wire [15:0] OSC_rtc_tune_out;
    wire OSC_rtc_reset;
    wire [1:0] OSC_debug_mux_ctl;
    wire [7:0] RF_ANLG_tuning_trim_g0;
    wire [9:0] RF_ANLG_vga_gain_ctrl_q;
    wire [9:0] RF_ANLG_vga_gain_ctrl_i;
    wire [5:0] RF_ANLG_current_dac_vga_i;
    wire [5:0] RF_ANLG_current_dac_vga_q;
    wire [3:0] RF_ANLG_bpf_i_chp0;
    wire [3:0] RF_ANLG_bpf_i_chp1;
    wire [3:0] RF_ANLG_bpf_i_chp2;
    wire [3:0] RF_ANLG_bpf_i_chp3;
    wire [3:0] RF_ANLG_bpf_i_chp4;
    wire [3:0] RF_ANLG_bpf_i_chp5;
    wire [3:0] RF_ANLG_bpf_i_clp0;
    wire [3:0] RF_ANLG_bpf_i_clp1;
    wire [3:0] RF_ANLG_bpf_i_clp2;
    wire [3:0] RF_ANLG_bpf_q_chp0;
    wire [3:0] RF_ANLG_bpf_q_chp1;
    wire [3:0] RF_ANLG_bpf_q_chp2;
    wire [3:0] RF_ANLG_bpf_q_chp3;
    wire [3:0] RF_ANLG_bpf_q_chp4;
    wire [3:0] RF_ANLG_bpf_q_chp5;
    wire [3:0] RF_ANLG_bpf_q_clp0;
    wire [3:0] RF_ANLG_bpf_q_clp1;
    wire [3:0] RF_ANLG_bpf_q_clp2;
    wire [9:0] RF_ANLG_vco_cap_coarse;
    wire [5:0] RF_ANLG_vco_cap_med;
    wire [7:0] RF_ANLG_vco_cap_mod;
    wire RF_ANLG_vco_freq_reset;
    wire RF_ANLG_en_lna;
    wire RF_ANLG_en_mix_i;
    wire RF_ANLG_en_mix_q;
    wire RF_ANLG_en_tia_i;
    wire RF_ANLG_en_tia_q;
    wire RF_ANLG_en_buf_i;
    wire RF_ANLG_en_buf_q;
    wire RF_ANLG_en_vga_i;
    wire RF_ANLG_en_vga_q;
    wire RF_ANLG_en_bpf_i;
    wire RF_ANLG_en_bpf_q;
    wire RF_ANLG_en_vco_lo;
    wire [9:0] RF_ANLG_mux_dbg_in;
    wire [9:0] RF_ANLG_mux_dbg_out;
    wire scan_out;
    wire [168:0] scan_SUPPLY_03;
    assign scan_SUPPLY_03 = {SUPPLY_bgr_temp_ctrl, SUPPLY_bgr_vref_ctrl, SUPPLY_current_src_left_ctrl, SUPPLY_current_src_right_ctrl};
    wire [168:0] scan_OSC_01;
    assign scan_OSC_01 = {OSC_adc_tune_out, OSC_adc_reset, OSC_dig_tune_out, OSC_dig_reset, OSC_rtc_tune_out, OSC_rtc_reset, OSC_debug_mux_ctl};
    wire [168:0] scan_RF_ANLG_02;
    assign scan_RF_ANLG_02 = {RF_ANLG_tuning_trim_g0, RF_ANLG_vga_gain_ctrl_q, RF_ANLG_vga_gain_ctrl_i, RF_ANLG_current_dac_vga_i, RF_ANLG_current_dac_vga_q, RF_ANLG_bpf_i_chp0, RF_ANLG_bpf_i_chp1, RF_ANLG_bpf_i_chp2, RF_ANLG_bpf_i_chp3, RF_ANLG_bpf_i_chp4, RF_ANLG_bpf_i_chp5, RF_ANLG_bpf_i_clp0, RF_ANLG_bpf_i_clp1, RF_ANLG_bpf_i_clp2, RF_ANLG_bpf_q_chp0, RF_ANLG_bpf_q_chp1, RF_ANLG_bpf_q_chp2, RF_ANLG_bpf_q_chp3, RF_ANLG_bpf_q_chp4, RF_ANLG_bpf_q_chp5, RF_ANLG_bpf_q_clp0, RF_ANLG_bpf_q_clp1, RF_ANLG_bpf_q_clp2, RF_ANLG_vco_cap_coarse, RF_ANLG_vco_cap_med, RF_ANLG_vco_cap_mod, RF_ANLG_vco_freq_reset, RF_ANLG_en_lna, RF_ANLG_en_mix_i, RF_ANLG_en_mix_q, RF_ANLG_en_tia_i, RF_ANLG_en_tia_q, RF_ANLG_en_buf_i, RF_ANLG_en_buf_q, RF_ANLG_en_vga_i, RF_ANLG_en_vga_q, RF_ANLG_en_bpf_i, RF_ANLG_en_bpf_q, RF_ANLG_en_vco_lo, RF_ANLG_mux_dbg_in, RF_ANLG_mux_dbg_out};

    /* Managed signals */
    reg reset;

    wire scan_clk;
    wire scan_en;
    wire scan_in;
    wire scan_reset;

    wire uart_rxd_in, uart_txd_in;
    wire [3 : 0] led;

    a7top #(
        .CLOCK_FREQ(`CLOCK_FREQ),
        .SCAN_CLK_FREQ(`SCAN_CLK_FREQ),

        .ADDR_BITS(`ADDR_BITS),
        .PAYLOAD_BITS(`PAYLOAD_BITS),

        .BAUD_RATE(`BAUD_RATE)
    ) top (
        .CLK100MHZ(clk),
        .RESET(reset),

        .UART_RXD_IN(uart_rxd_in),
        .UART_TXD_IN(uart_txd_in),

        .SCAN_CLK(scan_clk),
        .SCAN_EN(scan_en),
        .SCAN_IN(scan_in),
        .SCAN_RESET(scan_reset),

        .led(led)
    );



    ScanTop sc_top (
        .scan_clk(scan_clk),
        .scan_en(scan_en),
        .scan_in(scan_in),
        .scan_reset(scan_reset),
        .SUPPLY_bgr_temp_ctrl(SUPPLY_bgr_temp_ctrl),
        .SUPPLY_bgr_vref_ctrl(SUPPLY_bgr_vref_ctrl),
        .SUPPLY_current_src_left_ctrl(SUPPLY_current_src_left_ctrl),
        .SUPPLY_current_src_right_ctrl(SUPPLY_current_src_right_ctrl),
        .OSC_adc_tune_out(OSC_adc_tune_out),
        .OSC_adc_reset(OSC_adc_reset),
        .OSC_dig_tune_out(OSC_dig_tune_out),
        .OSC_dig_reset(OSC_dig_reset),
        .OSC_rtc_tune_out(OSC_rtc_tune_out),
        .OSC_rtc_reset(OSC_rtc_reset),
        .OSC_debug_mux_ctl(OSC_debug_mux_ctl),
        .RF_ANLG_tuning_trim_g0(RF_ANLG_tuning_trim_g0),
        .RF_ANLG_vga_gain_ctrl_q(RF_ANLG_vga_gain_ctrl_q),
        .RF_ANLG_vga_gain_ctrl_i(RF_ANLG_vga_gain_ctrl_i),
        .RF_ANLG_current_dac_vga_i(RF_ANLG_current_dac_vga_i),
        .RF_ANLG_current_dac_vga_q(RF_ANLG_current_dac_vga_q),
        .RF_ANLG_bpf_i_chp0(RF_ANLG_bpf_i_chp0),
        .RF_ANLG_bpf_i_chp1(RF_ANLG_bpf_i_chp1),
        .RF_ANLG_bpf_i_chp2(RF_ANLG_bpf_i_chp2),
        .RF_ANLG_bpf_i_chp3(RF_ANLG_bpf_i_chp3),
        .RF_ANLG_bpf_i_chp4(RF_ANLG_bpf_i_chp4),
        .RF_ANLG_bpf_i_chp5(RF_ANLG_bpf_i_chp5),
        .RF_ANLG_bpf_i_clp0(RF_ANLG_bpf_i_clp0),
        .RF_ANLG_bpf_i_clp1(RF_ANLG_bpf_i_clp1),
        .RF_ANLG_bpf_i_clp2(RF_ANLG_bpf_i_clp2),
        .RF_ANLG_bpf_q_chp0(RF_ANLG_bpf_q_chp0),
        .RF_ANLG_bpf_q_chp1(RF_ANLG_bpf_q_chp1),
        .RF_ANLG_bpf_q_chp2(RF_ANLG_bpf_q_chp2),
        .RF_ANLG_bpf_q_chp3(RF_ANLG_bpf_q_chp3),
        .RF_ANLG_bpf_q_chp4(RF_ANLG_bpf_q_chp4),
        .RF_ANLG_bpf_q_chp5(RF_ANLG_bpf_q_chp5),
        .RF_ANLG_bpf_q_clp0(RF_ANLG_bpf_q_clp0),
        .RF_ANLG_bpf_q_clp1(RF_ANLG_bpf_q_clp1),
        .RF_ANLG_bpf_q_clp2(RF_ANLG_bpf_q_clp2),
        .RF_ANLG_vco_cap_coarse(RF_ANLG_vco_cap_coarse),
        .RF_ANLG_vco_cap_med(RF_ANLG_vco_cap_med),
        .RF_ANLG_vco_cap_mod(RF_ANLG_vco_cap_mod),
        .RF_ANLG_vco_freq_reset(RF_ANLG_vco_freq_reset),
        .RF_ANLG_en_lna(RF_ANLG_en_lna),
        .RF_ANLG_en_mix_i(RF_ANLG_en_mix_i),
        .RF_ANLG_en_mix_q(RF_ANLG_en_mix_q),
        .RF_ANLG_en_tia_i(RF_ANLG_en_tia_i),
        .RF_ANLG_en_tia_q(RF_ANLG_en_tia_q),
        .RF_ANLG_en_buf_i(RF_ANLG_en_buf_i),
        .RF_ANLG_en_buf_q(RF_ANLG_en_buf_q),
        .RF_ANLG_en_vga_i(RF_ANLG_en_vga_i),
        .RF_ANLG_en_vga_q(RF_ANLG_en_vga_q),
        .RF_ANLG_en_bpf_i(RF_ANLG_en_bpf_i),
        .RF_ANLG_en_bpf_q(RF_ANLG_en_bpf_q),
        .RF_ANLG_en_vco_lo(RF_ANLG_en_vco_lo),
        .RF_ANLG_mux_dbg_in(RF_ANLG_mux_dbg_in),
        .RF_ANLG_mux_dbg_out(RF_ANLG_mux_dbg_out),
        .scan_out(scan_out)
    );

    reg [7 : 0] uart_data_in;
    reg uart_data_in_valid;
    reg uart_data_out_ready;
    wire uart_data_in_ready;
    wire [7 : 0] uart_data_out;
    wire uart_data_out_valid;

    wire n_reset = !reset;
    uart #(
        .CLOCK_FREQ(`CLOCK_FREQ),
        .BAUD_RATE(`BAUD_RATE)
    ) uart_tb (
        .clk(clk),
        .reset(n_reset),

        .data_in(uart_data_in),
        .data_in_valid(uart_data_in_valid),
        .data_in_ready(uart_data_in_ready),

        .data_out(uart_data_out),
        .data_out_valid(uart_data_out_valid),
        .data_out_ready(uart_data_out_ready),

        .serial_in(uart_rxd_in),
        .serial_out(uart_txd_in)
    );

        task uart_tx_packet(
        input [PACKET_BIT_SIZE] pkt
    );
        integer i;

        for (i = PACKET_BIT_SIZE - 8; i >= 0; i -= 8) begin
            wait (uart_data_in_ready); #1;
            uart_data_in = pkt[i +: 8];
            uart_data_in_valid = 1;
            @(posedge clk); #1;
            uart_data_in_valid = 0;
        end

    endtask

    task test_scan_write(
        input [11 : 0] addr,
        input [168:0] payload,
        input _reset
    );
        reg [`PAYLOAD_BITS - 1 : 0] _scan_target;
        reg [`PAYLOAD_BITS - 1 : 0] _expected_payload;
        uart_data_out_ready = 1;

        uart_tx_packet({2'b0, _reset, payload, addr});
        
        wait (uart_data_out_valid);
        uart_data_out_ready = 0;
        assert(uart_data_out == 8'b1) else
            $error("Invalid response. Expected %x, got %x", 8'b1, uart_data_out);
        
        /* 
        writing to the scan chain takes longer than the UART response in this
        config. Wait to observe it.
        */
        wait (!scan_en);
        repeat (10) @(posedge clk);


        if (_reset) begin
            /* evil, but 'bx is always false. This checks if we're something */
            assert(scan_OSC_01 || !scan_OSC_01) else
                $error("scan_OSC_01 still undefined after reset?");
        end
        else begin
            case (addr)
                1: begin 
                    _scan_target = scan_OSC_01;
                    _expected_payload = payload[52 : 0];
                end
                2: begin 
                    _scan_target = scan_RF_ANLG_02;
                    _expected_payload = payload;
                end
                3: begin
                    _scan_target = scan_SUPPLY_03;
                    _expected_payload = payload[19 : 0];
                end
                default: begin
                    _scan_target = 'bx;
                    _expected_payload = 'bx;
                end
            endcase
            assert(_scan_target == _expected_payload) else
                $error("_scan_target %x mismatch. Expected = %x, got = %x", addr, _expected_payload, _scan_target);
        end

    endtask

    integer addr_i, test_j;
    initial begin
        `ifdef IVERILOG
            $dumpfile("scanchain_top_tb.fst");
            // $dumpvars(0, scanchain_writer_tb);
            $dumpvars(0, top);
        `endif
        `ifndef IVERILOG
            $vcdpluson;
            $vcdplusmemon;
        `endif

        /* Reset */
        reset = 1;
        @(posedge clk);
        reset = 0;
        @(posedge clk);
        reset = 1;
        @(posedge clk);

        /* reset packet */
        test_scan_write(12'b100000000000, {$random, $random, $random, $random, $random, $random}, 1);
        /* try a bunch of packets! */
        for (test_j = 0; test_j < 10; test_j = test_j + 1) begin
            for (addr_i = 1; addr_i < 4; addr_i = addr_i + 1) begin
                test_scan_write(addr_i, {$random, $random, $random, $random, $random, $random}, 0);
            end
        end

        $display("Done!");
        `ifndef IVERILOG
            $vcdplusoff;
        `endif
        $finish();

    end
endmodule