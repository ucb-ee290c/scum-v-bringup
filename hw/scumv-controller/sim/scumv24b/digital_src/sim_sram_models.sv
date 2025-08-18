// Behavioral SRAM models for simulation (neutral, vendor-agnostic)

`timescale 1ns/1ps

module sim_sram_generic #(
	parameter int unsigned ADDR_WIDTH = 10,
	parameter int unsigned DATA_WIDTH = 64,
	parameter int unsigned DEPTH = (1 << ADDR_WIDTH)
)(
	input  wire [ADDR_WIDTH-1:0] adr,
	input  wire                  clk,
	input  wire [DATA_WIDTH-1:0] din,
	output logic [DATA_WIDTH-1:0] q,
	input  wire                  ren,
	input  wire                  wen,
	// Active-low per-bit write enable (bit written when wbeb[i] == 1'b0)
	input  wire [DATA_WIDTH-1:0] wbeb,
	// Unused macro control pins for compatibility
	input  wire                  mcen,
	input  wire [2:0]            mc,
	input  wire [1:0]            wa,
	input  wire [1:0]            wpulse,
	input  wire                  wpulseen,
	input  wire                  fwen,
	input  wire                  clkbyp
);

	logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

	always_ff @(posedge clk) begin
		if (wen) begin
			for (int unsigned i = 0; i < DATA_WIDTH; i++) begin
				if (wbeb[i] == 1'b0) begin
					mem[adr][i] <= din[i];
				end
			end
		end
	end

	always_ff @(posedge clk) begin
		if (ren) begin
			q <= mem[adr];
		end else begin
			q <= 'x;
		end
	end

endmodule


// 1024 x 64
module sim_sram_1024x64(
	input  wire [9:0]   adr,
	input  wire         clk,
	input  wire [63:0]  din,
	output logic [63:0] q,
	input  wire         ren,
	input  wire         wen,
	input  wire [63:0]  wbeb,
	input  wire         mcen,
	input  wire [2:0]   mc,
	input  wire [1:0]   wa,
	input  wire [1:0]   wpulse,
	input  wire         wpulseen,
	input  wire         fwen,
	input  wire         clkbyp
);

	sim_sram_generic #(
		.ADDR_WIDTH(10),
		.DATA_WIDTH(64),
		.DEPTH(1024)
	) u_ram (
		.adr(adr),
		.clk(clk),
		.din(din),
		.q(q),
		.ren(ren),
		.wen(wen),
		.wbeb(wbeb),
		.mcen(mcen),
		.mc(mc),
		.wa(wa),
		.wpulse(wpulse),
		.wpulseen(wpulseen),
		.fwen(fwen),
		.clkbyp(clkbyp)
	);

endmodule


// 512 x 44
module sim_sram_512x44(
	input  wire [8:0]   adr,
	input  wire         clk,
	input  wire [43:0]  din,
	output logic [43:0] q,
	input  wire         ren,
	input  wire         wen,
	input  wire [43:0]  wbeb,
	input  wire         mcen,
	input  wire [2:0]   mc,
	input  wire [1:0]   wa,
	input  wire [1:0]   wpulse,
	input  wire         wpulseen,
	input  wire         fwen,
	input  wire         clkbyp
);

	sim_sram_generic #(
		.ADDR_WIDTH(9),
		.DATA_WIDTH(44),
		.DEPTH(512)
	) u_ram (
		.adr(adr),
		.clk(clk),
		.din(din),
		.q(q),
		.ren(ren),
		.wen(wen),
		.wbeb(wbeb),
		.mcen(mcen),
		.mc(mc),
		.wa(wa),
		.wpulse(wpulse),
		.wpulseen(wpulseen),
		.fwen(fwen),
		.clkbyp(clkbyp)
	);

endmodule


// 512 x 42
module sim_sram_512x42(
	input  wire [8:0]   adr,
	input  wire         clk,
	input  wire [41:0]  din,
	output logic [41:0] q,
	input  wire         ren,
	input  wire         wen,
	input  wire [41:0]  wbeb,
	input  wire         mcen,
	input  wire [2:0]   mc,
	input  wire [1:0]   wa,
	input  wire [1:0]   wpulse,
	input  wire         wpulseen,
	input  wire         fwen,
	input  wire         clkbyp
);

	sim_sram_generic #(
		.ADDR_WIDTH(9),
		.DATA_WIDTH(42),
		.DEPTH(512)
	) u_ram (
		.adr(adr),
		.clk(clk),
		.din(din),
		.q(q),
		.ren(ren),
		.wen(wen),
		.wbeb(wbeb),
		.mcen(mcen),
		.mc(mc),
		.wa(wa),
		.wpulse(wpulse),
		.wpulseen(wpulseen),
		.fwen(fwen),
		.clkbyp(clkbyp)
	);

endmodule


// 8192 x 32
module sim_sram_8192x32(
	input  wire [12:0]  adr,
	input  wire         clk,
	input  wire [31:0]  din,
	output logic [31:0] q,
	input  wire         ren,
	input  wire         wen,
	input  wire [31:0]  wbeb,
	input  wire         mcen,
	input  wire [2:0]   mc,
	input  wire [1:0]   wa,
	input  wire [1:0]   wpulse,
	input  wire         wpulseen,
	input  wire         fwen,
	input  wire         clkbyp
);

	sim_sram_generic #(
		.ADDR_WIDTH(13),
		.DATA_WIDTH(32),
		.DEPTH(8192)
	) u_ram (
		.adr(adr),
		.clk(clk),
		.din(din),
		.q(q),
		.ren(ren),
		.wen(wen),
		.wbeb(wbeb),
		.mcen(mcen),
		.mc(mc),
		.wa(wa),
		.wpulse(wpulse),
		.wpulseen(wpulseen),
		.fwen(fwen),
		.clkbyp(clkbyp)
	);

endmodule


