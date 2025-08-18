module data_arrays_0_ext(
  input  [9:0]  RW0_addr,
  input         RW0_clk,
  input  [63:0] RW0_wdata,
  output [63:0] RW0_rdata,
  input         RW0_en,
  input         RW0_wmode,
  input  [7:0]  RW0_wmask
);
  wire [9:0] mem_0_0_adr;
  wire  mem_0_0_clk;
  wire [63:0] mem_0_0_din;
  wire [63:0] mem_0_0_q;
  wire  mem_0_0_ren;
  wire  mem_0_0_wen;
  wire [63:0] mem_0_0_wbeb;
  wire  mem_0_0_mcen;
  wire [2:0] mem_0_0_mc;
  wire [1:0] mem_0_0_wa;
  wire [1:0] mem_0_0_wpulse;
  wire  mem_0_0_wpulseen;
  wire  mem_0_0_fwen;
  wire  mem_0_0_clkbyp;
  wire [9:0] _GEN_20 = {RW0_wmask[1],RW0_wmask[1],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],
    RW0_wmask[0],RW0_wmask[0],RW0_wmask[0]};
  wire [18:0] _GEN_38 = {RW0_wmask[2],RW0_wmask[2],RW0_wmask[2],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],
    RW0_wmask[1],RW0_wmask[1],_GEN_20};
  wire [27:0] _GEN_56 = {RW0_wmask[3],RW0_wmask[3],RW0_wmask[3],RW0_wmask[3],RW0_wmask[2],RW0_wmask[2],RW0_wmask[2],
    RW0_wmask[2],RW0_wmask[2],_GEN_38};
  wire [36:0] _GEN_74 = {RW0_wmask[4],RW0_wmask[4],RW0_wmask[4],RW0_wmask[4],RW0_wmask[4],RW0_wmask[3],RW0_wmask[3],
    RW0_wmask[3],RW0_wmask[3],_GEN_56};
  wire [45:0] _GEN_92 = {RW0_wmask[5],RW0_wmask[5],RW0_wmask[5],RW0_wmask[5],RW0_wmask[5],RW0_wmask[5],RW0_wmask[4],
    RW0_wmask[4],RW0_wmask[4],_GEN_74};
  wire [54:0] _GEN_110 = {RW0_wmask[6],RW0_wmask[6],RW0_wmask[6],RW0_wmask[6],RW0_wmask[6],RW0_wmask[6],RW0_wmask[6],
    RW0_wmask[5],RW0_wmask[5],_GEN_92};
  wire [63:0] _GEN_127 = {RW0_wmask[7],RW0_wmask[7],RW0_wmask[7],RW0_wmask[7],RW0_wmask[7],RW0_wmask[7],RW0_wmask[7],
    RW0_wmask[7],RW0_wmask[6],_GEN_110};
  sim_sram_1024x64 mem_0_0 (
    .adr(mem_0_0_adr),
    .clk(mem_0_0_clk),
    .din(mem_0_0_din),
    .q(mem_0_0_q),
    .ren(mem_0_0_ren),
    .wen(mem_0_0_wen),
    .wbeb(mem_0_0_wbeb),
    .mcen(mem_0_0_mcen),
    .mc(mem_0_0_mc),
    .wa(mem_0_0_wa),
    .wpulse(mem_0_0_wpulse),
    .wpulseen(mem_0_0_wpulseen),
    .fwen(mem_0_0_fwen),
    .clkbyp(mem_0_0_clkbyp)
  );
  assign RW0_rdata = mem_0_0_q;
  assign mem_0_0_adr = RW0_addr;
  assign mem_0_0_clk = RW0_clk;
  assign mem_0_0_din = RW0_wdata;
  assign mem_0_0_ren = ~RW0_wmode & RW0_en;
  assign mem_0_0_wen = RW0_wmode & RW0_en;
  assign mem_0_0_wbeb = ~_GEN_127;
  assign mem_0_0_mcen = 1'h1;
  assign mem_0_0_mc = 3'h5;
  assign mem_0_0_wa = 2'h0;
  assign mem_0_0_wpulse = 2'h0;
  assign mem_0_0_wpulseen = 1'h1;
  assign mem_0_0_fwen = 1'h0;
  assign mem_0_0_clkbyp = 1'h0;
endmodule

module tag_array_ext(
  input  [5:0]  RW0_addr,
  input         RW0_clk,
  input  [43:0] RW0_wdata,
  output [43:0] RW0_rdata,
  input         RW0_en,
  input         RW0_wmode,
  input  [1:0]  RW0_wmask
);
  wire [8:0] mem_0_0_adr;
  wire  mem_0_0_clk;
  wire [43:0] mem_0_0_din;
  wire [43:0] mem_0_0_q;
  wire  mem_0_0_ren;
  wire  mem_0_0_wen;
  wire [43:0] mem_0_0_wbeb;
  wire  mem_0_0_mcen;
  wire [2:0] mem_0_0_mc;
  wire [1:0] mem_0_0_wa;
  wire [1:0] mem_0_0_wpulse;
  wire  mem_0_0_wpulseen;
  wire  mem_0_0_fwen;
  wire  mem_0_0_clkbyp;
  wire [9:0] _GEN_20 = {RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],
    RW0_wmask[0],RW0_wmask[0],RW0_wmask[0]};
  wire [18:0] _GEN_38 = {RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],
    RW0_wmask[0],RW0_wmask[0],_GEN_20};
  wire [27:0] _GEN_56 = {RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[0],
    RW0_wmask[0],RW0_wmask[0],_GEN_38};
  wire [36:0] _GEN_74 = {RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],
    RW0_wmask[1],RW0_wmask[1],_GEN_56};
  wire [43:0] _GEN_87 = {RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],
    _GEN_74};
  sim_sram_512x44 mem_0_0 (
    .adr(mem_0_0_adr),
    .clk(mem_0_0_clk),
    .din(mem_0_0_din),
    .q(mem_0_0_q),
    .ren(mem_0_0_ren),
    .wen(mem_0_0_wen),
    .wbeb(mem_0_0_wbeb),
    .mcen(mem_0_0_mcen),
    .mc(mem_0_0_mc),
    .wa(mem_0_0_wa),
    .wpulse(mem_0_0_wpulse),
    .wpulseen(mem_0_0_wpulseen),
    .fwen(mem_0_0_fwen),
    .clkbyp(mem_0_0_clkbyp)
  );
  assign RW0_rdata = mem_0_0_q;
  assign mem_0_0_adr = {{3'd0}, RW0_addr};
  assign mem_0_0_clk = RW0_clk;
  assign mem_0_0_din = RW0_wdata;
  assign mem_0_0_ren = ~RW0_wmode & RW0_en;
  assign mem_0_0_wen = RW0_wmode & RW0_en;
  assign mem_0_0_wbeb = ~_GEN_87;
  assign mem_0_0_mcen = 1'h1;
  assign mem_0_0_mc = 3'h5;
  assign mem_0_0_wa = 2'h0;
  assign mem_0_0_wpulse = 2'h0;
  assign mem_0_0_wpulseen = 1'h1;
  assign mem_0_0_fwen = 1'h0;
  assign mem_0_0_clkbyp = 1'h0;
endmodule


module tag_array_0_ext(
  input  [5:0]  RW0_addr,
  input         RW0_clk,
  input  [41:0] RW0_wdata,
  output [41:0] RW0_rdata,
  input         RW0_en,
  input         RW0_wmode,
  input  [1:0]  RW0_wmask
);
  wire [8:0] mem_0_0_adr;
  wire  mem_0_0_clk;
  wire [41:0] mem_0_0_din;
  wire [41:0] mem_0_0_q;
  wire  mem_0_0_ren;
  wire  mem_0_0_wen;
  wire [41:0] mem_0_0_wbeb;
  wire  mem_0_0_mcen;
  wire [2:0] mem_0_0_mc;
  wire [1:0] mem_0_0_wa;
  wire [1:0] mem_0_0_wpulse;
  wire  mem_0_0_wpulseen;
  wire  mem_0_0_fwen;
  wire  mem_0_0_clkbyp;
  wire [9:0] _GEN_20 = {RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],
    RW0_wmask[0],RW0_wmask[0],RW0_wmask[0]};
  wire [18:0] _GEN_38 = {RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],
    RW0_wmask[0],RW0_wmask[0],_GEN_20};
  wire [27:0] _GEN_56 = {RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],
    RW0_wmask[0],RW0_wmask[0],_GEN_38};
  wire [36:0] _GEN_74 = {RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],
    RW0_wmask[1],RW0_wmask[1],_GEN_56};
  wire [41:0] _GEN_83 = {RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],_GEN_74};
  sim_sram_512x42 mem_0_0 (
    .adr(mem_0_0_adr),
    .clk(mem_0_0_clk),
    .din(mem_0_0_din),
    .q(mem_0_0_q),
    .ren(mem_0_0_ren),
    .wen(mem_0_0_wen),
    .wbeb(mem_0_0_wbeb),
    .mcen(mem_0_0_mcen),
    .mc(mem_0_0_mc),
    .wa(mem_0_0_wa),
    .wpulse(mem_0_0_wpulse),
    .wpulseen(mem_0_0_wpulseen),
    .fwen(mem_0_0_fwen),
    .clkbyp(mem_0_0_clkbyp)
  );
  assign RW0_rdata = mem_0_0_q;
  assign mem_0_0_adr = {{3'd0}, RW0_addr};
  assign mem_0_0_clk = RW0_clk;
  assign mem_0_0_din = RW0_wdata;
  assign mem_0_0_ren = ~RW0_wmode & RW0_en;
  assign mem_0_0_wen = RW0_wmode & RW0_en;
  assign mem_0_0_wbeb = ~_GEN_83;
  assign mem_0_0_mcen = 1'h1;
  assign mem_0_0_mc = 3'h5;
  assign mem_0_0_wa = 2'h0;
  assign mem_0_0_wpulse = 2'h0;
  assign mem_0_0_wpulseen = 1'h1;
  assign mem_0_0_fwen = 1'h0;
  assign mem_0_0_clkbyp = 1'h0;
endmodule


module data_arrays_0_0_ext(
  input  [9:0]  RW0_addr,
  input         RW0_clk,
  input  [63:0] RW0_wdata,
  output [63:0] RW0_rdata,
  input         RW0_en,
  input         RW0_wmode,
  input  [1:0]  RW0_wmask
);
  wire [9:0] mem_0_0_adr;
  wire  mem_0_0_clk;
  wire [63:0] mem_0_0_din;
  wire [63:0] mem_0_0_q;
  wire  mem_0_0_ren;
  wire  mem_0_0_wen;
  wire [63:0] mem_0_0_wbeb;
  wire  mem_0_0_mcen;
  wire [2:0] mem_0_0_mc;
  wire [1:0] mem_0_0_wa;
  wire [1:0] mem_0_0_wpulse;
  wire  mem_0_0_wpulseen;
  wire  mem_0_0_fwen;
  wire  mem_0_0_clkbyp;
  wire [9:0] _GEN_20 = {RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],
    RW0_wmask[0],RW0_wmask[0],RW0_wmask[0]};
  wire [18:0] _GEN_38 = {RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],
    RW0_wmask[0],RW0_wmask[0],_GEN_20};
  wire [27:0] _GEN_56 = {RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],
    RW0_wmask[0],RW0_wmask[0],_GEN_38};
  wire [36:0] _GEN_74 = {RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[0],RW0_wmask[0],
    RW0_wmask[0],RW0_wmask[0],_GEN_56};
  wire [45:0] _GEN_92 = {RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],
    RW0_wmask[1],RW0_wmask[1],_GEN_74};
  wire [54:0] _GEN_110 = {RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],
    RW0_wmask[1],RW0_wmask[1],_GEN_92};
  wire [63:0] _GEN_127 = {RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],
    RW0_wmask[1],RW0_wmask[1],_GEN_110};
  sim_sram_1024x64 mem_0_0 (
    .adr(mem_0_0_adr),
    .clk(mem_0_0_clk),
    .din(mem_0_0_din),
    .q(mem_0_0_q),
    .ren(mem_0_0_ren),
    .wen(mem_0_0_wen),
    .wbeb(mem_0_0_wbeb),
    .mcen(mem_0_0_mcen),
    .mc(mem_0_0_mc),
    .wa(mem_0_0_wa),
    .wpulse(mem_0_0_wpulse),
    .wpulseen(mem_0_0_wpulseen),
    .fwen(mem_0_0_fwen),
    .clkbyp(mem_0_0_clkbyp)
  );
  assign RW0_rdata = mem_0_0_q;
  assign mem_0_0_adr = RW0_addr;
  assign mem_0_0_clk = RW0_clk;
  assign mem_0_0_din = RW0_wdata;
  assign mem_0_0_ren = ~RW0_wmode & RW0_en;
  assign mem_0_0_wen = RW0_wmode & RW0_en;
  assign mem_0_0_wbeb = ~_GEN_127;
  assign mem_0_0_mcen = 1'h1;
  assign mem_0_0_mc = 3'h5;
  assign mem_0_0_wa = 2'h0;
  assign mem_0_0_wpulse = 2'h0;
  assign mem_0_0_wpulseen = 1'h1;
  assign mem_0_0_fwen = 1'h0;
  assign mem_0_0_clkbyp = 1'h0;
endmodule


module mem_ext(
  input  [12:0] RW0_addr,
  input         RW0_clk,
  input  [31:0] RW0_wdata,
  output [31:0] RW0_rdata,
  input         RW0_en,
  input         RW0_wmode,
  input  [3:0]  RW0_wmask
);
  wire [12:0] mem_0_0_adr;
  wire  mem_0_0_clk;
  wire [31:0] mem_0_0_din;
  wire [31:0] mem_0_0_q;
  wire  mem_0_0_ren;
  wire  mem_0_0_wen;
  wire [31:0] mem_0_0_wbeb;
  wire  mem_0_0_mcen;
  wire [2:0] mem_0_0_mc;
  wire [1:0] mem_0_0_wa;
  wire [1:0] mem_0_0_wpulse;
  wire  mem_0_0_wpulseen;
  wire  mem_0_0_fwen;
  wire  mem_0_0_clkbyp;
  wire [9:0] _GEN_20 = {RW0_wmask[1],RW0_wmask[1],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],RW0_wmask[0],
    RW0_wmask[0],RW0_wmask[0],RW0_wmask[0]};
  wire [18:0] _GEN_38 = {RW0_wmask[2],RW0_wmask[2],RW0_wmask[2],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],RW0_wmask[1],
    RW0_wmask[1],RW0_wmask[1],_GEN_20};
  wire [27:0] _GEN_56 = {RW0_wmask[3],RW0_wmask[3],RW0_wmask[3],RW0_wmask[3],RW0_wmask[2],RW0_wmask[2],RW0_wmask[2],
    RW0_wmask[2],RW0_wmask[2],_GEN_38};
  wire [31:0] _GEN_63 = {RW0_wmask[3],RW0_wmask[3],RW0_wmask[3],RW0_wmask[3],_GEN_56};
  sim_sram_8192x32 mem_0_0 (
    .adr(mem_0_0_adr),
    .clk(mem_0_0_clk),
    .din(mem_0_0_din),
    .q(mem_0_0_q),
    .ren(mem_0_0_ren),
    .wen(mem_0_0_wen),
    .wbeb(mem_0_0_wbeb),
    .mcen(mem_0_0_mcen),
    .mc(mem_0_0_mc),
    .wa(mem_0_0_wa),
    .wpulse(mem_0_0_wpulse),
    .wpulseen(mem_0_0_wpulseen),
    .fwen(mem_0_0_fwen),
    .clkbyp(mem_0_0_clkbyp)
  );
  assign RW0_rdata = mem_0_0_q;
  assign mem_0_0_adr = RW0_addr;
  assign mem_0_0_clk = RW0_clk;
  assign mem_0_0_din = RW0_wdata;
  assign mem_0_0_ren = ~RW0_wmode & RW0_en;
  assign mem_0_0_wen = RW0_wmode & RW0_en;
  assign mem_0_0_wbeb = ~_GEN_63;
  assign mem_0_0_mcen = 1'h1;
  assign mem_0_0_mc = 3'h5;
  assign mem_0_0_wa = 2'h0;
  assign mem_0_0_wpulse = 2'h0;
  assign mem_0_0_wpulseen = 1'h1;
  assign mem_0_0_fwen = 1'h0;
  assign mem_0_0_clkbyp = 1'h0;
endmodule

