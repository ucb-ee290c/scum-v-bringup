module ScanTB ();
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
reg scan_clk;
reg scan_en;
reg scan_in;
reg scan_reset;
wire [168:0] scan_SUPPLY_03;
 assign scan_SUPPLY_03 = {SUPPLY_bgr_temp_ctrl, SUPPLY_bgr_vref_ctrl, SUPPLY_current_src_left_ctrl, SUPPLY_current_src_right_ctrl};
wire [168:0] scan_OSC_01;
 assign scan_OSC_01 = {OSC_adc_tune_out, OSC_adc_reset, OSC_dig_tune_out, OSC_dig_reset, OSC_rtc_tune_out, OSC_rtc_reset, OSC_debug_mux_ctl};
wire [168:0] scan_RF_ANLG_02;
 assign scan_RF_ANLG_02 = {RF_ANLG_tuning_trim_g0, RF_ANLG_vga_gain_ctrl_q, RF_ANLG_vga_gain_ctrl_i, RF_ANLG_current_dac_vga_i, RF_ANLG_current_dac_vga_q, RF_ANLG_bpf_i_chp0, RF_ANLG_bpf_i_chp1, RF_ANLG_bpf_i_chp2, RF_ANLG_bpf_i_chp3, RF_ANLG_bpf_i_chp4, RF_ANLG_bpf_i_chp5, RF_ANLG_bpf_i_clp0, RF_ANLG_bpf_i_clp1, RF_ANLG_bpf_i_clp2, RF_ANLG_bpf_q_chp0, RF_ANLG_bpf_q_chp1, RF_ANLG_bpf_q_chp2, RF_ANLG_bpf_q_chp3, RF_ANLG_bpf_q_chp4, RF_ANLG_bpf_q_chp5, RF_ANLG_bpf_q_clp0, RF_ANLG_bpf_q_clp1, RF_ANLG_bpf_q_clp2, RF_ANLG_vco_cap_coarse, RF_ANLG_vco_cap_med, RF_ANLG_vco_cap_mod, RF_ANLG_vco_freq_reset, RF_ANLG_en_lna, RF_ANLG_en_mix_i, RF_ANLG_en_mix_q, RF_ANLG_en_tia_i, RF_ANLG_en_tia_q, RF_ANLG_en_buf_i, RF_ANLG_en_buf_q, RF_ANLG_en_vga_i, RF_ANLG_en_vga_q, RF_ANLG_en_bpf_i, RF_ANLG_en_bpf_q, RF_ANLG_en_vco_lo, RF_ANLG_mux_dbg_in, RF_ANLG_mux_dbg_out};

        reg [31:0] error_counter = 0;
        initial scan_clk = 0;
        always #(5.0) scan_clk <= ~scan_clk;
        reg [168:0] auto_check_output;
        always @(posedge scan_clk) begin
            auto_check_output <= {auto_check_output[168:0], scan_out};
        end        

        task send_bits;
            input [11:0] addr;
            input [168:0] payload;
            integer j;
            begin
                j = 11;
                @(negedge scan_clk);
                scan_en = 0;
                repeat(12) begin
                    @(negedge scan_clk);
                    scan_en = 1;
                    scan_in = addr[j];
                    j = j -1;
                end
                j = 168;
                repeat(169) begin
                    @(negedge scan_clk);
                    scan_en = 1;
                    scan_in = payload[j];
                    j = j - 1;
                end
                @(negedge scan_clk);
                scan_en = 0;
                @(negedge scan_clk);
            end
        endtask

        task check_bits;
            input [168:0] scan_data;
            input [168:0] desired_data;
            input integer max_bit_check;
            input integer scanIndex;
            reg check_failed;
            reg check_success;
            integer i;
            begin
        
                check_failed = 0;
                check_success = 0;
                for(i=0; i < max_bit_check; i=i+1) begin
                    if(scan_data[i] !== desired_data[i]) begin
                        check_failed = 1;
                    end
                end
                if (~check_failed) begin
                    check_success = 1;
                end
                if (check_success) begin
                    $display("got the correct data! for chain %d", scanIndex);
                end else begin
                    $display("got the wrong data, expected %h, but got %h", desired_data, scan_data);
                    $display("for the chain %d", scanIndex);
                    error_counter = error_counter + 1;
                end
            end
        endtask
        task report_values;
            begin
                $display("Total Number of Errors: %d", error_counter);
            end
        endtask
        
        task check_scan_SUPPLY_03;
            input [168:0] data_to_send;
            begin
                send_bits(3, data_to_send);
                repeat(10) @(negedge scan_clk);
                check_bits(scan_SUPPLY_03, data_to_send, 20, 3);
            end
        endtask
            
        task check_scan_OSC_01;
            input [168:0] data_to_send;
            begin
                send_bits(1, data_to_send);
                repeat(10) @(negedge scan_clk);
                check_bits(scan_OSC_01, data_to_send, 53, 1);
            end
        endtask
            
        task check_scan_RF_ANLG_02;
            input [168:0] data_to_send;
            begin
                send_bits(2, data_to_send);
                repeat(10) @(negedge scan_clk);
                check_bits(scan_RF_ANLG_02, data_to_send, 169, 2);
            end
        endtask
            initial begin

        scan_reset = 1;
        repeat(10) @(negedge scan_clk);
        scan_reset = 0;
        repeat(10) @(negedge scan_clk);
        check_scan_SUPPLY_03(169'd804937);
check_scan_OSC_01(169'd8810429048560116);
check_scan_RF_ANLG_02(169'd392054788278507322423845320053143435663284051237815);
check_scan_SUPPLY_03(169'd305649);
check_scan_OSC_01(169'd4599697899912737);
check_scan_RF_ANLG_02(169'd32960302345313545397451449265692730137051450395601);
check_scan_SUPPLY_03(169'd316893);
check_scan_OSC_01(169'd3031238204612206);
check_scan_RF_ANLG_02(169'd693455080965426378104287669912933787222885069913551);
check_scan_SUPPLY_03(169'd926698);
check_scan_OSC_01(169'd1569428566995280);
check_scan_RF_ANLG_02(169'd550288271609253864837454323371058254994286376009682);
check_scan_SUPPLY_03(169'd570097);
check_scan_OSC_01(169'd1095683563974184);
check_scan_RF_ANLG_02(169'd420335148335572936267839254651402444941961621871297);
check_scan_SUPPLY_03(169'd573377);
check_scan_OSC_01(169'd1505138250944671);
check_scan_RF_ANLG_02(169'd261400278358345986455548943656686299309360429254335);
check_scan_SUPPLY_03(169'd439036);
check_scan_OSC_01(169'd2151347371426713);
check_scan_RF_ANLG_02(169'd3022234434636537238295627346575033328218855068604);
check_scan_SUPPLY_03(169'd905873);
check_scan_OSC_01(169'd7245642803647660);
check_scan_RF_ANLG_02(169'd510325873104595225405370770122368736107393669731125);
check_scan_SUPPLY_03(169'd59852);
check_scan_OSC_01(169'd7601466974196353);
check_scan_RF_ANLG_02(169'd709911700585899191354188019543780181848395307376184);
check_scan_SUPPLY_03(169'd734743);
check_scan_OSC_01(169'd8951336800390215);
check_scan_RF_ANLG_02(169'd23293296011775421257613164230984774384162084086388);

report_values();

$finish();
end
ScanTop dut (
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
.scan_out(scan_out));

endmodule
