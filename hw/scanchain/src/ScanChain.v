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
     input scan_clk, output [11:0] addr_out, output[2:0] scan_en_sub, output [2:0] scan_in_sub, output reg [180:0] scan_in_data_reg, input take_scanout_data, input [180:0] scan_out_mux_output);
    parameter ADDR0 = 'd0;
parameter ADDR1 = 'd1;
parameter ADDR2 = 'd2;
reg [3:0] count;
reg [2:0] state;
reg [11:0] addr_chain;
reg [11:0] addr;
reg [2:0] scan_en_dec;
assign addr_out = addr;
reg [8:0] bit_counter;
reg first_bit;
assign scan_en_sub = {3{scan_en}} & scan_en_dec;
always @(negedge scan_clk or posedge reset) begin
	if (reset) begin
		scan_en_dec = 0;
	end else begin
	case(addr)
	ADDR0: scan_en_dec = 3'd1;
	ADDR1: scan_en_dec = 3'd2;
	ADDR2: scan_en_dec = 3'd4;
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
scan_in_data_reg <= {scan_in_data_reg[180:0], scan_in};
 
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
scan_in_data_reg <= {scan_in_data_reg[180:0], scan_in};

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
                    scan_in_data_reg <= {scan_in_data_reg[180:0], scan_in};
                end
    			if (scan_en == 1'b0) begin 
scan_in_data_reg <= {scan_in_data_reg[180:0], scan_in};

    				state <= 'b000;
    				addr <= 'b0000;
    			end
    		end
    	default: begin 
scan_in_data_reg <= {scan_in_data_reg[180:0], scan_in};

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
output [4:0] SUPPLY_bgr_temp_ctrl,
output [4:0] SUPPLY_bgr_vref_ctrl,
output [4:0] SUPPLY_current_src_left_ctrl,
output [4:0] SUPPLY_current_src_right_ctrl,
output [15:0] OSC_adc_tune_out,
output OSC_adc_reset,
output [15:0] OSC_dig_tune_out,
output OSC_dig_reset,
output [15:0] OSC_rtc_tune_out,
output OSC_rtc_reset,
output [1:0] OSC_debug_mux_ctl,
output [7:0] RF_ANLG_tuning_trim_g0,
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
output RF_ANLG_en_lna,
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
wire [168:0] scan_SUPPLY_03;
wire [168:0] scan_OSC_01;
wire [168:0] scan_RF_ANLG_02;
reg take_scanout_data;
wire [180:0] scan_in_data_reg;
reg [180:0] scan_out_mux_output;
wire [2:0] scan_en_sub;
wire [11:0] addr;
assign scan_out = scan_in_data_reg[180];

                parameter ADDR0 = 12'b11;
                //parameter for digital chain # SUPPLY_03
                assign SUPPLY_bgr_temp_ctrl = scan_SUPPLY_03[19:15];
assign SUPPLY_bgr_vref_ctrl = scan_SUPPLY_03[14:10];
assign SUPPLY_current_src_left_ctrl = scan_SUPPLY_03[9:5];
assign SUPPLY_current_src_right_ctrl = scan_SUPPLY_03[4:0];

                Scan_reset #(.WIDTH(169)) scan_SUPPLY_03_module (
                  .reset(scan_reset),
                  .out(scan_SUPPLY_03),
                  .data_in(scan_in_data_reg),
                  .enable(scan_en_sub[0]),
                  .reset_value({149'd0, 5'd0,5'd0,5'd0,5'd0})
                );

                
                parameter ADDR1 = 12'b1;
                //parameter for digital chain # OSC_01
                assign OSC_adc_tune_out = scan_OSC_01[52:37];
assign OSC_adc_reset = scan_OSC_01[36];
assign OSC_dig_tune_out = scan_OSC_01[35:20];
assign OSC_dig_reset = scan_OSC_01[19];
assign OSC_rtc_tune_out = scan_OSC_01[18:3];
assign OSC_rtc_reset = scan_OSC_01[2];
assign OSC_debug_mux_ctl = scan_OSC_01[1:0];

                Scan_reset #(.WIDTH(169)) scan_OSC_01_module (
                  .reset(scan_reset),
                  .out(scan_OSC_01),
                  .data_in(scan_in_data_reg),
                  .enable(scan_en_sub[1]),
                  .reset_value({116'd0, 16'd9480,1'd0,16'd0,1'd0,16'd0,1'd0,2'd0})
                );

                
                parameter ADDR2 = 12'b10;
                //parameter for digital chain # RF_ANLG_02
                assign RF_ANLG_tuning_trim_g0 = scan_RF_ANLG_02[168:161];
assign RF_ANLG_vga_gain_ctrl_q = scan_RF_ANLG_02[160:151];
assign RF_ANLG_vga_gain_ctrl_i = scan_RF_ANLG_02[150:141];
assign RF_ANLG_current_dac_vga_i = scan_RF_ANLG_02[140:135];
assign RF_ANLG_current_dac_vga_q = scan_RF_ANLG_02[134:129];
assign RF_ANLG_bpf_i_chp0 = scan_RF_ANLG_02[128:125];
assign RF_ANLG_bpf_i_chp1 = scan_RF_ANLG_02[124:121];
assign RF_ANLG_bpf_i_chp2 = scan_RF_ANLG_02[120:117];
assign RF_ANLG_bpf_i_chp3 = scan_RF_ANLG_02[116:113];
assign RF_ANLG_bpf_i_chp4 = scan_RF_ANLG_02[112:109];
assign RF_ANLG_bpf_i_chp5 = scan_RF_ANLG_02[108:105];
assign RF_ANLG_bpf_i_clp0 = scan_RF_ANLG_02[104:101];
assign RF_ANLG_bpf_i_clp1 = scan_RF_ANLG_02[100:97];
assign RF_ANLG_bpf_i_clp2 = scan_RF_ANLG_02[96:93];
assign RF_ANLG_bpf_q_chp0 = scan_RF_ANLG_02[92:89];
assign RF_ANLG_bpf_q_chp1 = scan_RF_ANLG_02[88:85];
assign RF_ANLG_bpf_q_chp2 = scan_RF_ANLG_02[84:81];
assign RF_ANLG_bpf_q_chp3 = scan_RF_ANLG_02[80:77];
assign RF_ANLG_bpf_q_chp4 = scan_RF_ANLG_02[76:73];
assign RF_ANLG_bpf_q_chp5 = scan_RF_ANLG_02[72:69];
assign RF_ANLG_bpf_q_clp0 = scan_RF_ANLG_02[68:65];
assign RF_ANLG_bpf_q_clp1 = scan_RF_ANLG_02[64:61];
assign RF_ANLG_bpf_q_clp2 = scan_RF_ANLG_02[60:57];
assign RF_ANLG_vco_cap_coarse = scan_RF_ANLG_02[56:47];
assign RF_ANLG_vco_cap_med = scan_RF_ANLG_02[46:41];
assign RF_ANLG_vco_cap_mod = scan_RF_ANLG_02[40:33];
assign RF_ANLG_vco_freq_reset = scan_RF_ANLG_02[32];
assign RF_ANLG_en_lna = scan_RF_ANLG_02[31];
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

                Scan_reset #(.WIDTH(169)) scan_RF_ANLG_02_module (
                  .reset(scan_reset),
                  .out(scan_RF_ANLG_02),
                  .data_in(scan_in_data_reg),
                  .enable(scan_en_sub[2]),
                  .reset_value({8'd0,10'd0,10'd0,6'd0,6'd0,4'd10,4'd10,4'd10,4'd10,4'd10,4'd10,4'd10,4'd10,4'd10,4'd10,4'd10,4'd10,4'd10,4'd10,4'd10,4'd10,4'd10,4'd10,10'd0,6'd32,8'd128,1'd0,1'd1,1'd1,1'd1,1'd1,1'd1,1'd1,1'd1,1'd1,1'd1,1'd1,1'd1,1'd1,10'd0,10'd0})
                );

    /* verilator lint_off PINMISSING */
    subclk #( .ADDR0(ADDR0),
.ADDR1(ADDR1),
.ADDR2(ADDR2)
    ) subclk_sub ( .reset(scan_reset),
     .scan_in(scan_in), .scan_en(scan_en), .take_scanout_data(take_scanout_data),
     .scan_clk(scan_clk), .addr_out(addr), .scan_en_sub(scan_en_sub), .scan_out_mux_output(scan_out_mux_output), .scan_in_data_reg(scan_in_data_reg));
    /* lint_on */

always @(*) begin
	case(addr)
	default: begin
		scan_out_mux_output = 0;
		take_scanout_data=0;
	end
endcase
end
endmodule
