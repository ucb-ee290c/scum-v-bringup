module Scan (enable, data_in, out);

parameter WIDTH = 16;
input enable;
input [WIDTH-1:0] data_in;
output reg [WIDTH - 1:0] out;


always @(negedge enable) begin
    out <= data_in[WIDTH-1 : 0];
end



endmodule
module Scan_reset (reset, reset_value, enable, data_in, out);

parameter WIDTH = 16;
input enable;
input reset;
input [WIDTH-1:0] data_in;
input [WIDTH-1:0] reset_value;
output reg [WIDTH - 1:0] out;


always @(negedge enable or posedge reset) begin
    if (reset) begin
        out <= reset_value;
    end else begin
        out <= data_in[WIDTH-1 : 0];
    end
end



endmodule

    module subclk ( input reset, 
     input scan_in, input scan_en,
     input scan_clk, output [11:0] addr_out, output[4:0] scan_en_sub, output [4:0] scan_in_sub, output reg [171:0] scan_in_data_reg, input take_scanout_data, input [171:0] scan_out_mux_output);
    parameter ADDR0 = 'd0;
parameter ADDR1 = 'd1;
parameter ADDR2 = 'd2;
parameter ADDR3 = 'd3;
parameter ADDR4 = 'd4;
reg [3:0] count;
reg [2:0] state;
reg [11:0] addr_chain;
reg [11:0] addr;
reg [4:0] scan_en_dec;
assign addr_out = addr;
reg [8:0] bit_counter;
reg first_bit;
assign scan_en_sub = {5{scan_en}} & scan_en_dec;
always @(negedge scan_clk or posedge reset) begin
    if (reset) begin
        scan_en_dec = 0;
    end else begin
    case(addr)
    ADDR0: scan_en_dec = 5'd1;
    ADDR1: scan_en_dec = 5'd2;
    ADDR2: scan_en_dec = 5'd4;
    ADDR3: scan_en_dec = 5'd8;
    ADDR4: scan_en_dec = 5'd16;
    default: scan_en_dec = 0;
    endcase
end
end

    always @(posedge scan_clk or posedge reset) begin
        
        if (reset) begin
            count <= 0;
            state <= 3'b000;
            addr <= 0;
            addr_chain <= 0;
            scan_in_data_reg <= 0;
            first_bit <= 0;
        end else begin
        
        case (state)
            3'b000: begin 
scan_in_data_reg <= {scan_in_data_reg[171:0], scan_in};
 
                count <= 2'b00;
                if (scan_en == 1'b0) begin
                    state <= 3'b000;
                    addr <= 12'b0000;
                end else begin
                    state <= 3'b001;
                    addr_chain <= {addr_chain[11:0], scan_in};
                end
            end
            3'b001 : begin 
scan_in_data_reg <= {scan_in_data_reg[171:0], scan_in};

                if (scan_en == 1'b0) begin
                    state <= 3'b000;
                    addr <= 12'b0000;
                end else if (scan_en && (count == 10)) begin
                    addr_chain <= {addr_chain[11:0], scan_in};
                    addr <= {addr_chain[11:0], scan_in};
                    state <= 3'b010;
                    count <= 2'b00;
                    first_bit <= 0;
                end else if (scan_en) begin
                    state <= 3'b001;
                    count <= count + 1;
                    addr_chain <= {addr_chain[11:0], scan_in};
                end
            end
            3'b010: begin
                if (take_scanout_data && (first_bit == 0)) begin
                    scan_in_data_reg <= scan_out_mux_output;
                    first_bit <= 1;
                end else begin
                    scan_in_data_reg <= {scan_in_data_reg[171:0], scan_in};
                end
                if (scan_en == 1'b0) begin 
scan_in_data_reg <= {scan_in_data_reg[171:0], scan_in};

                    state <= 'b000;
                    addr <= 'b0000;
                end
            end
        default: begin 
scan_in_data_reg <= {scan_in_data_reg[171:0], scan_in};

            state <= 'b000;
        end
        endcase
        end

    end 

endmodule
module ScanTop (
input scan_clk,
input scan_en,
input scan_in,
input scan_reset,
output RADAR_rampGenerator_clkMuxSel,
output RADAR_rampGenerator_enable,
output [7:0] RADAR_rampGenerator_frequencyStepStart,
output [7:0] RADAR_rampGenerator_numFrequencySteps,
output [23:0] RADAR_rampGenerator_numCyclesPerFrequency,
output [31:0] RADAR_rampGenerator_numIdleCycles,
output RADAR_rampGenerator_rst,
output [4:0] RADAR_vco_capTuning,
output RADAR_vco_enable,
output RADAR_vco_divEnable,
output RADAR_pa_enable,
output RADAR_pa_bypass,
output [4:0] SUPPLY_bgr_temp_ctrl,
output [4:0] SUPPLY_bgr_vref_ctrl,
output [4:0] SUPPLY_current_src_left_ctrl,
output [4:0] SUPPLY_current_src_right_ctrl,
output SUPPLY_clkOvrd,
output [15:0] OSC_clk_analog_tune,
output OSC_clk_analog_reset,
output [15:0] OSC_clk_dig_tune,
output OSC_clk_dig_reset,
output [1:0] OSC_clk_cpu_sel,
output [31:0] SENSOR_ADC_tuning,
output [9:0] RF_ANLG_vga_gain_ctrl_q,
output [9:0] RF_ANLG_vga_gain_ctrl_i,
output [5:0] RF_ANLG_current_dac_vga_i,
output [5:0] RF_ANLG_current_dac_vga_q,
output [3:0] RF_ANLG_bpf_i_chp0,
output [3:0] RF_ANLG_bpf_i_chp1,
output [3:0] RF_ANLG_bpf_i_chp2,
output [3:0] RF_ANLG_bpf_i_chp3,
output [3:0] RF_ANLG_bpf_i_chp4,
output [3:0] RF_ANLG_bpf_i_chp5,
output [3:0] RF_ANLG_bpf_i_clp0,
output [3:0] RF_ANLG_bpf_i_clp1,
output [3:0] RF_ANLG_bpf_i_clp2,
output [3:0] RF_ANLG_bpf_q_chp0,
output [3:0] RF_ANLG_bpf_q_chp1,
output [3:0] RF_ANLG_bpf_q_chp2,
output [3:0] RF_ANLG_bpf_q_chp3,
output [3:0] RF_ANLG_bpf_q_chp4,
output [3:0] RF_ANLG_bpf_q_chp5,
output [3:0] RF_ANLG_bpf_q_clp0,
output [3:0] RF_ANLG_bpf_q_clp1,
output [3:0] RF_ANLG_bpf_q_clp2,
output [9:0] RF_ANLG_vco_cap_coarse,
output [5:0] RF_ANLG_vco_cap_med,
output [7:0] RF_ANLG_vco_cap_mod,
output RF_ANLG_vco_freq_reset,
output RF_ANLG_en_mix_i,
output RF_ANLG_en_mix_q,
output RF_ANLG_en_tia_i,
output RF_ANLG_en_tia_q,
output RF_ANLG_en_buf_i,
output RF_ANLG_en_buf_q,
output RF_ANLG_en_vga_i,
output RF_ANLG_en_vga_q,
output RF_ANLG_en_bpf_i,
output RF_ANLG_en_bpf_q,
output RF_ANLG_en_vco_lo,
output [9:0] RF_ANLG_mux_dbg_in,
output [9:0] RF_ANLG_mux_dbg_out,
output scan_out
);
wire [159:0] scan_RADAR_04;
wire [159:0] scan_SUPPLY_03;
wire [159:0] scan_OSC_01;
wire [159:0] scan_SENSOR_ADC05;
wire [159:0] scan_RF_ANLG_02;
reg take_scanout_data;
wire [171:0] scan_in_data_reg;
reg [171:0] scan_out_mux_output;
wire [4:0] scan_en_sub;
wire [11:0] addr;
assign scan_out = scan_in_data_reg[171];

                parameter ADDR0 = 12'b100;
                //parameter for digital chain # RADAR_04
                assign RADAR_rampGenerator_clkMuxSel = scan_RADAR_04[83];
assign RADAR_rampGenerator_enable = scan_RADAR_04[82];
assign RADAR_rampGenerator_frequencyStepStart = scan_RADAR_04[81:74];
assign RADAR_rampGenerator_numFrequencySteps = scan_RADAR_04[73:66];
assign RADAR_rampGenerator_numCyclesPerFrequency = scan_RADAR_04[65:42];
assign RADAR_rampGenerator_numIdleCycles = scan_RADAR_04[41:10];
assign RADAR_rampGenerator_rst = scan_RADAR_04[9];
assign RADAR_vco_capTuning = scan_RADAR_04[8:4];
assign RADAR_vco_enable = scan_RADAR_04[3];
assign RADAR_vco_divEnable = scan_RADAR_04[2];
assign RADAR_pa_enable = scan_RADAR_04[1];
assign RADAR_pa_bypass = scan_RADAR_04[0];

                Scan_reset #(.WIDTH(160)) scan_RADAR_04_module (
                  .reset(scan_reset),
                  .out(scan_RADAR_04),
                  .data_in(scan_in_data_reg),
                  .enable(scan_en_sub[0]),
                  .reset_value({76'd0, 1'd0,1'd1,8'd0,8'd0,24'd0,32'd0,1'd0,5'd0,1'd1,1'd1,1'd1,1'd0})
                );

                
                parameter ADDR1 = 12'b11;
                //parameter for digital chain # SUPPLY_03
                assign SUPPLY_bgr_temp_ctrl = scan_SUPPLY_03[20:16];
assign SUPPLY_bgr_vref_ctrl = scan_SUPPLY_03[15:11];
assign SUPPLY_current_src_left_ctrl = scan_SUPPLY_03[10:6];
assign SUPPLY_current_src_right_ctrl = scan_SUPPLY_03[5:1];
assign SUPPLY_clkOvrd = scan_SUPPLY_03[0];

                Scan_reset #(.WIDTH(160)) scan_SUPPLY_03_module (
                  .reset(scan_reset),
                  .out(scan_SUPPLY_03),
                  .data_in(scan_in_data_reg),
                  .enable(scan_en_sub[1]),
                  .reset_value({139'd0, 5'd0,5'd0,5'd0,5'd0,1'd0})
                );

                
                parameter ADDR2 = 12'b1;
                //parameter for digital chain # OSC_01
                assign OSC_clk_analog_tune = scan_OSC_01[35:20];
assign OSC_clk_analog_reset = scan_OSC_01[19];
assign OSC_clk_dig_tune = scan_OSC_01[18:3];
assign OSC_clk_dig_reset = scan_OSC_01[2];
assign OSC_clk_cpu_sel = scan_OSC_01[1:0];

                Scan_reset #(.WIDTH(160)) scan_OSC_01_module (
                  .reset(scan_reset),
                  .out(scan_OSC_01),
                  .data_in(scan_in_data_reg),
                  .enable(scan_en_sub[2]),
                  .reset_value({124'd0, 16'd9480,1'd0,16'd0,1'd0,2'd0})
                );

                
                parameter ADDR3 = 12'b101;
                //parameter for digital chain # SENSOR_ADC05
                assign SENSOR_ADC_tuning = scan_SENSOR_ADC05[31:0];

                Scan_reset #(.WIDTH(160)) scan_SENSOR_ADC05_module (
                  .reset(scan_reset),
                  .out(scan_SENSOR_ADC05),
                  .data_in(scan_in_data_reg),
                  .enable(scan_en_sub[3]),
                  .reset_value({128'd0, 32'd0})
                );

                
                parameter ADDR4 = 12'b10;
                //parameter for digital chain # RF_ANLG_02
                assign RF_ANLG_vga_gain_ctrl_q = scan_RF_ANLG_02[159:150];
assign RF_ANLG_vga_gain_ctrl_i = scan_RF_ANLG_02[149:140];
assign RF_ANLG_current_dac_vga_i = scan_RF_ANLG_02[139:134];
assign RF_ANLG_current_dac_vga_q = scan_RF_ANLG_02[133:128];
assign RF_ANLG_bpf_i_chp0 = scan_RF_ANLG_02[127:124];
assign RF_ANLG_bpf_i_chp1 = scan_RF_ANLG_02[123:120];
assign RF_ANLG_bpf_i_chp2 = scan_RF_ANLG_02[119:116];
assign RF_ANLG_bpf_i_chp3 = scan_RF_ANLG_02[115:112];
assign RF_ANLG_bpf_i_chp4 = scan_RF_ANLG_02[111:108];
assign RF_ANLG_bpf_i_chp5 = scan_RF_ANLG_02[107:104];
assign RF_ANLG_bpf_i_clp0 = scan_RF_ANLG_02[103:100];
assign RF_ANLG_bpf_i_clp1 = scan_RF_ANLG_02[99:96];
assign RF_ANLG_bpf_i_clp2 = scan_RF_ANLG_02[95:92];
assign RF_ANLG_bpf_q_chp0 = scan_RF_ANLG_02[91:88];
assign RF_ANLG_bpf_q_chp1 = scan_RF_ANLG_02[87:84];
assign RF_ANLG_bpf_q_chp2 = scan_RF_ANLG_02[83:80];
assign RF_ANLG_bpf_q_chp3 = scan_RF_ANLG_02[79:76];
assign RF_ANLG_bpf_q_chp4 = scan_RF_ANLG_02[75:72];
assign RF_ANLG_bpf_q_chp5 = scan_RF_ANLG_02[71:68];
assign RF_ANLG_bpf_q_clp0 = scan_RF_ANLG_02[67:64];
assign RF_ANLG_bpf_q_clp1 = scan_RF_ANLG_02[63:60];
assign RF_ANLG_bpf_q_clp2 = scan_RF_ANLG_02[59:56];
assign RF_ANLG_vco_cap_coarse = scan_RF_ANLG_02[55:46];
assign RF_ANLG_vco_cap_med = scan_RF_ANLG_02[45:40];
assign RF_ANLG_vco_cap_mod = scan_RF_ANLG_02[39:32];
assign RF_ANLG_vco_freq_reset = scan_RF_ANLG_02[31];
assign RF_ANLG_en_mix_i = scan_RF_ANLG_02[30];
assign RF_ANLG_en_mix_q = scan_RF_ANLG_02[29];
assign RF_ANLG_en_tia_i = scan_RF_ANLG_02[28];
assign RF_ANLG_en_tia_q = scan_RF_ANLG_02[27];
assign RF_ANLG_en_buf_i = scan_RF_ANLG_02[26];
assign RF_ANLG_en_buf_q = scan_RF_ANLG_02[25];
assign RF_ANLG_en_vga_i = scan_RF_ANLG_02[24];
assign RF_ANLG_en_vga_q = scan_RF_ANLG_02[23];
assign RF_ANLG_en_bpf_i = scan_RF_ANLG_02[22];
assign RF_ANLG_en_bpf_q = scan_RF_ANLG_02[21];
assign RF_ANLG_en_vco_lo = scan_RF_ANLG_02[20];
assign RF_ANLG_mux_dbg_in = scan_RF_ANLG_02[19:10];
assign RF_ANLG_mux_dbg_out = scan_RF_ANLG_02[9:0];

                Scan_reset #(.WIDTH(160)) scan_RF_ANLG_02_module (
                  .reset(scan_reset),
                  .out(scan_RF_ANLG_02),
                  .data_in(scan_in_data_reg),
                  .enable(scan_en_sub[4]),
                  .reset_value({10'd0,10'd0,6'd0,6'd0,4'd10,4'd10,4'd10,4'd10,4'd10,4'd10,4'd10,4'd10,4'd10,4'd10,4'd10,4'd10,4'd10,4'd10,4'd10,4'd10,4'd10,4'd10,10'd0,6'd32,8'd128,1'd0,1'd1,1'd1,1'd1,1'd1,1'd1,1'd1,1'd1,1'd1,1'd1,1'd1,1'd1,10'd0,10'd0})
                );

                
    subclk #( .ADDR0(ADDR0),
.ADDR1(ADDR1),
.ADDR2(ADDR2),
.ADDR3(ADDR3),
.ADDR4(ADDR4)
    ) subclk_sub ( .reset(scan_reset),
     .scan_in(scan_in), .scan_en(scan_en), .take_scanout_data(take_scanout_data),
     .scan_clk(scan_clk), .addr_out(addr), .scan_en_sub(scan_en_sub), .scan_out_mux_output(scan_out_mux_output), .scan_in_data_reg(scan_in_data_reg));
    

always @(*) begin
    case(addr)
    default: begin
        scan_out_mux_output = 0;
        take_scanout_data=0;
    end
endcase
end
endmodule
