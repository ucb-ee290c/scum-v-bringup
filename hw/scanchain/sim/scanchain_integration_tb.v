`timescale 1ns/1ns
`define CLK_PERIOD 8
`define CLOCK_FREQ 20
`define CLOCKS_PER_SCAN_CLK 5
`define ADDR_BITS 12
`define PAYLOAD_BITS 169
module scanchain_integration_tb();
    /* Generate the simulated clock */
    reg clk = 0;
    always #(`CLK_PERIOD/2) clk <= ~clk;

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

    wire write_ready;
    reg write_valid;
    reg [11:0] write_addr;
    reg [168:0] write_payload;
    reg write_reset;

    wire scan_clk;
    wire scan_en;
    wire scan_in;
    wire scan_reset;


    scanchain_writer #(
        .CLOCK_FREQ(`CLOCK_FREQ),
        .CLOCKS_PER_SCAN_CLK(`CLOCKS_PER_SCAN_CLK),
        .ADDR_BITS(`ADDR_BITS),
        .PAYLOAD_BITS(`PAYLOAD_BITS)
    ) sc_writer (
        .clk(clk),
        .reset(reset),

        .write_ready(write_ready),
        .write_valid(write_valid),
        .write_addr(write_addr),
        .write_payload(write_payload),
        .write_reset(write_reset),

        .scan_clk(scan_clk),
        .scan_en(scan_en),
        .scan_in(scan_in),
        .scan_reset(scan_reset)
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

    task test_reset();
        wait (write_ready); #1;

        write_reset = 1;
        write_valid = 1;
        @(posedge clk); #1;
        write_valid = 0;
        write_reset = 'x;
        @(posedge clk); #1;
        while (scan_en) begin
            assert(scan_reset) else
                $error("Expected reset, got %x", scan_reset);
            @(posedge clk); #1;
        end
        assert(!scan_reset) else
            $error("Expected reset to drop, got %x", scan_reset);
    endtask

    integer i;
    task test_write(
        input [`ADDR_BITS - 1: 0] addr,
        input [`PAYLOAD_BITS -1 : 0] payload
    );
        reg [`PAYLOAD_BITS - 1 : 0] _scan_target;
        reg [`PAYLOAD_BITS - 1 : 0] _expected_payload;
        wait (write_ready); #1;

        write_valid = 1;
        write_addr = addr;
        write_payload = payload;
        write_reset = 0;
        @(posedge clk); #1;
        write_valid = 0;
        write_reset = 'x;
        write_addr = 'x;
        write_payload = 'x;

        wait (write_ready); #1;
        repeat (payload[7 : 0]) @(posedge clk);

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

        
    endtask

    integer addr_i, test_j;
    initial begin
        `ifdef IVERILOG
            $dumpfile("scanchain_integration_tb.fst");
            // $dumpvars(0, scanchain_writer_tb);
            $dumpvars(0, sc_writer);
            $dumpvars(0, sc_top);
        `endif
        `ifndef IVERILOG
            $vcdpluson;
            $vcdplusmemon;
        `endif

        /* Reset */
        write_valid = 0;
        @(posedge clk);
        reset = 1;
        @(posedge clk);
        reset = 0;
        @(posedge clk);

        test_reset();
        for (test_j = 0; test_j < 128; test_j = test_j + 1) begin
            for (addr_i = 1; addr_i < 4; addr_i = addr_i + 1) begin
            test_write(addr_i, {$random, $random, $random, $random, $random, $random});
            end
        end
        // test_write(3, {$random, $random, $random, $random, $random, $random});
        // repeat (128) @(posedge clk);
        // test_write(2, {$random, $random, $random, $random, $random, $random});

        $display("Done!");
        `ifndef IVERILOG
            $vcdplusoff;
        `endif
        $finish();

    end
endmodule