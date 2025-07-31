
module GenericDeserializer(
  input         clock,
                reset,
  output        io_in_ready,
  input         io_in_valid,
                io_in_bits,
                io_out_ready,
  output        io_out_valid,
  output [2:0]  io_out_bits_chanId,
                io_out_bits_opcode,
                io_out_bits_param,
  output [7:0]  io_out_bits_size,
                io_out_bits_source,
  output [63:0] io_out_bits_address,
                io_out_bits_data,
  output        io_out_bits_corrupt,
  output [8:0]  io_out_bits_union
);
  reg        data_0;
  reg        data_1;
  reg        data_2;
  reg        data_3;
  reg        data_4;
  reg        data_5;
  reg        data_6;
  reg        data_7;
  reg        data_8;
  reg        data_9;
  reg        data_10;
  reg        data_11;
  reg        data_12;
  reg        data_13;
  reg        data_14;
  reg        data_15;
  reg        data_16;
  reg        data_17;
  reg        data_18;
  reg        data_19;
  reg        data_20;
  reg        data_21;
  reg        data_22;
  reg        data_23;
  reg        data_24;
  reg        data_25;
  reg        data_26;
  reg        data_27;
  reg        data_28;
  reg        data_29;
  reg        data_30;
  reg        data_31;
  reg        data_32;
  reg        data_33;
  reg        data_34;
  reg        data_35;
  reg        data_36;
  reg        data_37;
  reg        data_38;
  reg        data_39;
  reg        data_40;
  reg        data_41;
  reg        data_42;
  reg        data_43;
  reg        data_44;
  reg        data_45;
  reg        data_46;
  reg        data_47;
  reg        data_48;
  reg        data_49;
  reg        data_50;
  reg        data_51;
  reg        data_52;
  reg        data_53;
  reg        data_54;
  reg        data_55;
  reg        data_56;
  reg        data_57;
  reg        data_58;
  reg        data_59;
  reg        data_60;
  reg        data_61;
  reg        data_62;
  reg        data_63;
  reg        data_64;
  reg        data_65;
  reg        data_66;
  reg        data_67;
  reg        data_68;
  reg        data_69;
  reg        data_70;
  reg        data_71;
  reg        data_72;
  reg        data_73;
  reg        data_74;
  reg        data_75;
  reg        data_76;
  reg        data_77;
  reg        data_78;
  reg        data_79;
  reg        data_80;
  reg        data_81;
  reg        data_82;
  reg        data_83;
  reg        data_84;
  reg        data_85;
  reg        data_86;
  reg        data_87;
  reg        data_88;
  reg        data_89;
  reg        data_90;
  reg        data_91;
  reg        data_92;
  reg        data_93;
  reg        data_94;
  reg        data_95;
  reg        data_96;
  reg        data_97;
  reg        data_98;
  reg        data_99;
  reg        data_100;
  reg        data_101;
  reg        data_102;
  reg        data_103;
  reg        data_104;
  reg        data_105;
  reg        data_106;
  reg        data_107;
  reg        data_108;
  reg        data_109;
  reg        data_110;
  reg        data_111;
  reg        data_112;
  reg        data_113;
  reg        data_114;
  reg        data_115;
  reg        data_116;
  reg        data_117;
  reg        data_118;
  reg        data_119;
  reg        data_120;
  reg        data_121;
  reg        data_122;
  reg        data_123;
  reg        data_124;
  reg        data_125;
  reg        data_126;
  reg        data_127;
  reg        data_128;
  reg        data_129;
  reg        data_130;
  reg        data_131;
  reg        data_132;
  reg        data_133;
  reg        data_134;
  reg        data_135;
  reg        data_136;
  reg        data_137;
  reg        data_138;
  reg        data_139;
  reg        data_140;
  reg        data_141;
  reg        data_142;
  reg        data_143;
  reg        data_144;
  reg        data_145;
  reg        data_146;
  reg        data_147;
  reg        data_148;
  reg        data_149;
  reg        data_150;
  reg        data_151;
  reg        data_152;
  reg        data_153;
  reg        data_154;
  reg        data_155;
  reg        data_156;
  reg        data_157;
  reg        data_158;
  reg        data_159;
  reg        data_160;
  reg        data_161;
  reg        data_162;
  reg        data_163;
  reg        receiving;
  reg  [7:0] recvCount;
  wire       wrap_wrap = recvCount == 8'hA3;
  wire       _GEN = receiving & io_in_valid;
  always @(posedge clock) begin
    if (_GEN & recvCount == 8'h0)
      data_0 <= io_in_bits;
    if (_GEN & recvCount == 8'h1)
      data_1 <= io_in_bits;
    if (_GEN & recvCount == 8'h2)
      data_2 <= io_in_bits;
    if (_GEN & recvCount == 8'h3)
      data_3 <= io_in_bits;
    if (_GEN & recvCount == 8'h4)
      data_4 <= io_in_bits;
    if (_GEN & recvCount == 8'h5)
      data_5 <= io_in_bits;
    if (_GEN & recvCount == 8'h6)
      data_6 <= io_in_bits;
    if (_GEN & recvCount == 8'h7)
      data_7 <= io_in_bits;
    if (_GEN & recvCount == 8'h8)
      data_8 <= io_in_bits;
    if (_GEN & recvCount == 8'h9)
      data_9 <= io_in_bits;
    if (_GEN & recvCount == 8'hA)
      data_10 <= io_in_bits;
    if (_GEN & recvCount == 8'hB)
      data_11 <= io_in_bits;
    if (_GEN & recvCount == 8'hC)
      data_12 <= io_in_bits;
    if (_GEN & recvCount == 8'hD)
      data_13 <= io_in_bits;
    if (_GEN & recvCount == 8'hE)
      data_14 <= io_in_bits;
    if (_GEN & recvCount == 8'hF)
      data_15 <= io_in_bits;
    if (_GEN & recvCount == 8'h10)
      data_16 <= io_in_bits;
    if (_GEN & recvCount == 8'h11)
      data_17 <= io_in_bits;
    if (_GEN & recvCount == 8'h12)
      data_18 <= io_in_bits;
    if (_GEN & recvCount == 8'h13)
      data_19 <= io_in_bits;
    if (_GEN & recvCount == 8'h14)
      data_20 <= io_in_bits;
    if (_GEN & recvCount == 8'h15)
      data_21 <= io_in_bits;
    if (_GEN & recvCount == 8'h16)
      data_22 <= io_in_bits;
    if (_GEN & recvCount == 8'h17)
      data_23 <= io_in_bits;
    if (_GEN & recvCount == 8'h18)
      data_24 <= io_in_bits;
    if (_GEN & recvCount == 8'h19)
      data_25 <= io_in_bits;
    if (_GEN & recvCount == 8'h1A)
      data_26 <= io_in_bits;
    if (_GEN & recvCount == 8'h1B)
      data_27 <= io_in_bits;
    if (_GEN & recvCount == 8'h1C)
      data_28 <= io_in_bits;
    if (_GEN & recvCount == 8'h1D)
      data_29 <= io_in_bits;
    if (_GEN & recvCount == 8'h1E)
      data_30 <= io_in_bits;
    if (_GEN & recvCount == 8'h1F)
      data_31 <= io_in_bits;
    if (_GEN & recvCount == 8'h20)
      data_32 <= io_in_bits;
    if (_GEN & recvCount == 8'h21)
      data_33 <= io_in_bits;
    if (_GEN & recvCount == 8'h22)
      data_34 <= io_in_bits;
    if (_GEN & recvCount == 8'h23)
      data_35 <= io_in_bits;
    if (_GEN & recvCount == 8'h24)
      data_36 <= io_in_bits;
    if (_GEN & recvCount == 8'h25)
      data_37 <= io_in_bits;
    if (_GEN & recvCount == 8'h26)
      data_38 <= io_in_bits;
    if (_GEN & recvCount == 8'h27)
      data_39 <= io_in_bits;
    if (_GEN & recvCount == 8'h28)
      data_40 <= io_in_bits;
    if (_GEN & recvCount == 8'h29)
      data_41 <= io_in_bits;
    if (_GEN & recvCount == 8'h2A)
      data_42 <= io_in_bits;
    if (_GEN & recvCount == 8'h2B)
      data_43 <= io_in_bits;
    if (_GEN & recvCount == 8'h2C)
      data_44 <= io_in_bits;
    if (_GEN & recvCount == 8'h2D)
      data_45 <= io_in_bits;
    if (_GEN & recvCount == 8'h2E)
      data_46 <= io_in_bits;
    if (_GEN & recvCount == 8'h2F)
      data_47 <= io_in_bits;
    if (_GEN & recvCount == 8'h30)
      data_48 <= io_in_bits;
    if (_GEN & recvCount == 8'h31)
      data_49 <= io_in_bits;
    if (_GEN & recvCount == 8'h32)
      data_50 <= io_in_bits;
    if (_GEN & recvCount == 8'h33)
      data_51 <= io_in_bits;
    if (_GEN & recvCount == 8'h34)
      data_52 <= io_in_bits;
    if (_GEN & recvCount == 8'h35)
      data_53 <= io_in_bits;
    if (_GEN & recvCount == 8'h36)
      data_54 <= io_in_bits;
    if (_GEN & recvCount == 8'h37)
      data_55 <= io_in_bits;
    if (_GEN & recvCount == 8'h38)
      data_56 <= io_in_bits;
    if (_GEN & recvCount == 8'h39)
      data_57 <= io_in_bits;
    if (_GEN & recvCount == 8'h3A)
      data_58 <= io_in_bits;
    if (_GEN & recvCount == 8'h3B)
      data_59 <= io_in_bits;
    if (_GEN & recvCount == 8'h3C)
      data_60 <= io_in_bits;
    if (_GEN & recvCount == 8'h3D)
      data_61 <= io_in_bits;
    if (_GEN & recvCount == 8'h3E)
      data_62 <= io_in_bits;
    if (_GEN & recvCount == 8'h3F)
      data_63 <= io_in_bits;
    if (_GEN & recvCount == 8'h40)
      data_64 <= io_in_bits;
    if (_GEN & recvCount == 8'h41)
      data_65 <= io_in_bits;
    if (_GEN & recvCount == 8'h42)
      data_66 <= io_in_bits;
    if (_GEN & recvCount == 8'h43)
      data_67 <= io_in_bits;
    if (_GEN & recvCount == 8'h44)
      data_68 <= io_in_bits;
    if (_GEN & recvCount == 8'h45)
      data_69 <= io_in_bits;
    if (_GEN & recvCount == 8'h46)
      data_70 <= io_in_bits;
    if (_GEN & recvCount == 8'h47)
      data_71 <= io_in_bits;
    if (_GEN & recvCount == 8'h48)
      data_72 <= io_in_bits;
    if (_GEN & recvCount == 8'h49)
      data_73 <= io_in_bits;
    if (_GEN & recvCount == 8'h4A)
      data_74 <= io_in_bits;
    if (_GEN & recvCount == 8'h4B)
      data_75 <= io_in_bits;
    if (_GEN & recvCount == 8'h4C)
      data_76 <= io_in_bits;
    if (_GEN & recvCount == 8'h4D)
      data_77 <= io_in_bits;
    if (_GEN & recvCount == 8'h4E)
      data_78 <= io_in_bits;
    if (_GEN & recvCount == 8'h4F)
      data_79 <= io_in_bits;
    if (_GEN & recvCount == 8'h50)
      data_80 <= io_in_bits;
    if (_GEN & recvCount == 8'h51)
      data_81 <= io_in_bits;
    if (_GEN & recvCount == 8'h52)
      data_82 <= io_in_bits;
    if (_GEN & recvCount == 8'h53)
      data_83 <= io_in_bits;
    if (_GEN & recvCount == 8'h54)
      data_84 <= io_in_bits;
    if (_GEN & recvCount == 8'h55)
      data_85 <= io_in_bits;
    if (_GEN & recvCount == 8'h56)
      data_86 <= io_in_bits;
    if (_GEN & recvCount == 8'h57)
      data_87 <= io_in_bits;
    if (_GEN & recvCount == 8'h58)
      data_88 <= io_in_bits;
    if (_GEN & recvCount == 8'h59)
      data_89 <= io_in_bits;
    if (_GEN & recvCount == 8'h5A)
      data_90 <= io_in_bits;
    if (_GEN & recvCount == 8'h5B)
      data_91 <= io_in_bits;
    if (_GEN & recvCount == 8'h5C)
      data_92 <= io_in_bits;
    if (_GEN & recvCount == 8'h5D)
      data_93 <= io_in_bits;
    if (_GEN & recvCount == 8'h5E)
      data_94 <= io_in_bits;
    if (_GEN & recvCount == 8'h5F)
      data_95 <= io_in_bits;
    if (_GEN & recvCount == 8'h60)
      data_96 <= io_in_bits;
    if (_GEN & recvCount == 8'h61)
      data_97 <= io_in_bits;
    if (_GEN & recvCount == 8'h62)
      data_98 <= io_in_bits;
    if (_GEN & recvCount == 8'h63)
      data_99 <= io_in_bits;
    if (_GEN & recvCount == 8'h64)
      data_100 <= io_in_bits;
    if (_GEN & recvCount == 8'h65)
      data_101 <= io_in_bits;
    if (_GEN & recvCount == 8'h66)
      data_102 <= io_in_bits;
    if (_GEN & recvCount == 8'h67)
      data_103 <= io_in_bits;
    if (_GEN & recvCount == 8'h68)
      data_104 <= io_in_bits;
    if (_GEN & recvCount == 8'h69)
      data_105 <= io_in_bits;
    if (_GEN & recvCount == 8'h6A)
      data_106 <= io_in_bits;
    if (_GEN & recvCount == 8'h6B)
      data_107 <= io_in_bits;
    if (_GEN & recvCount == 8'h6C)
      data_108 <= io_in_bits;
    if (_GEN & recvCount == 8'h6D)
      data_109 <= io_in_bits;
    if (_GEN & recvCount == 8'h6E)
      data_110 <= io_in_bits;
    if (_GEN & recvCount == 8'h6F)
      data_111 <= io_in_bits;
    if (_GEN & recvCount == 8'h70)
      data_112 <= io_in_bits;
    if (_GEN & recvCount == 8'h71)
      data_113 <= io_in_bits;
    if (_GEN & recvCount == 8'h72)
      data_114 <= io_in_bits;
    if (_GEN & recvCount == 8'h73)
      data_115 <= io_in_bits;
    if (_GEN & recvCount == 8'h74)
      data_116 <= io_in_bits;
    if (_GEN & recvCount == 8'h75)
      data_117 <= io_in_bits;
    if (_GEN & recvCount == 8'h76)
      data_118 <= io_in_bits;
    if (_GEN & recvCount == 8'h77)
      data_119 <= io_in_bits;
    if (_GEN & recvCount == 8'h78)
      data_120 <= io_in_bits;
    if (_GEN & recvCount == 8'h79)
      data_121 <= io_in_bits;
    if (_GEN & recvCount == 8'h7A)
      data_122 <= io_in_bits;
    if (_GEN & recvCount == 8'h7B)
      data_123 <= io_in_bits;
    if (_GEN & recvCount == 8'h7C)
      data_124 <= io_in_bits;
    if (_GEN & recvCount == 8'h7D)
      data_125 <= io_in_bits;
    if (_GEN & recvCount == 8'h7E)
      data_126 <= io_in_bits;
    if (_GEN & recvCount == 8'h7F)
      data_127 <= io_in_bits;
    if (_GEN & recvCount == 8'h80)
      data_128 <= io_in_bits;
    if (_GEN & recvCount == 8'h81)
      data_129 <= io_in_bits;
    if (_GEN & recvCount == 8'h82)
      data_130 <= io_in_bits;
    if (_GEN & recvCount == 8'h83)
      data_131 <= io_in_bits;
    if (_GEN & recvCount == 8'h84)
      data_132 <= io_in_bits;
    if (_GEN & recvCount == 8'h85)
      data_133 <= io_in_bits;
    if (_GEN & recvCount == 8'h86)
      data_134 <= io_in_bits;
    if (_GEN & recvCount == 8'h87)
      data_135 <= io_in_bits;
    if (_GEN & recvCount == 8'h88)
      data_136 <= io_in_bits;
    if (_GEN & recvCount == 8'h89)
      data_137 <= io_in_bits;
    if (_GEN & recvCount == 8'h8A)
      data_138 <= io_in_bits;
    if (_GEN & recvCount == 8'h8B)
      data_139 <= io_in_bits;
    if (_GEN & recvCount == 8'h8C)
      data_140 <= io_in_bits;
    if (_GEN & recvCount == 8'h8D)
      data_141 <= io_in_bits;
    if (_GEN & recvCount == 8'h8E)
      data_142 <= io_in_bits;
    if (_GEN & recvCount == 8'h8F)
      data_143 <= io_in_bits;
    if (_GEN & recvCount == 8'h90)
      data_144 <= io_in_bits;
    if (_GEN & recvCount == 8'h91)
      data_145 <= io_in_bits;
    if (_GEN & recvCount == 8'h92)
      data_146 <= io_in_bits;
    if (_GEN & recvCount == 8'h93)
      data_147 <= io_in_bits;
    if (_GEN & recvCount == 8'h94)
      data_148 <= io_in_bits;
    if (_GEN & recvCount == 8'h95)
      data_149 <= io_in_bits;
    if (_GEN & recvCount == 8'h96)
      data_150 <= io_in_bits;
    if (_GEN & recvCount == 8'h97)
      data_151 <= io_in_bits;
    if (_GEN & recvCount == 8'h98)
      data_152 <= io_in_bits;
    if (_GEN & recvCount == 8'h99)
      data_153 <= io_in_bits;
    if (_GEN & recvCount == 8'h9A)
      data_154 <= io_in_bits;
    if (_GEN & recvCount == 8'h9B)
      data_155 <= io_in_bits;
    if (_GEN & recvCount == 8'h9C)
      data_156 <= io_in_bits;
    if (_GEN & recvCount == 8'h9D)
      data_157 <= io_in_bits;
    if (_GEN & recvCount == 8'h9E)
      data_158 <= io_in_bits;
    if (_GEN & recvCount == 8'h9F)
      data_159 <= io_in_bits;
    if (_GEN & recvCount == 8'hA0)
      data_160 <= io_in_bits;
    if (_GEN & recvCount == 8'hA1)
      data_161 <= io_in_bits;
    if (_GEN & recvCount == 8'hA2)
      data_162 <= io_in_bits;
    if (_GEN & recvCount == 8'hA3)
      data_163 <= io_in_bits;
    if (reset) begin
      receiving <= 1'h1;
      recvCount <= 8'h0;
    end
    else begin
      receiving <= io_out_ready & ~receiving | ~(_GEN & wrap_wrap) & receiving;
      if (_GEN) begin
        if (wrap_wrap)
          recvCount <= 8'h0;
        else
          recvCount <= recvCount + 8'h1;
      end
    end
  end // always @(posedge)
  assign io_in_ready = receiving;
  assign io_out_valid = ~receiving;
  assign io_out_bits_chanId = {data_163, data_162, data_161};
  assign io_out_bits_opcode = {data_160, data_159, data_158};
  assign io_out_bits_param = {data_157, data_156, data_155};
  assign io_out_bits_size = {data_154, data_153, data_152, data_151, data_150, data_149, data_148, data_147};
  assign io_out_bits_source = {data_146, data_145, data_144, data_143, data_142, data_141, data_140, data_139};
  assign io_out_bits_address = {data_138, data_137, data_136, data_135, data_134, data_133, data_132, data_131, data_130, data_129, data_128, data_127, data_126, data_125, data_124, data_123, data_122, data_121, data_120, data_119, data_118, data_117, data_116, data_115, data_114, data_113, data_112, data_111, data_110, data_109, data_108, data_107, data_106, data_105, data_104, data_103, data_102, data_101, data_100, data_99, data_98, data_97, data_96, data_95, data_94, data_93, data_92, data_91, data_90, data_89, data_88, data_87, data_86, data_85, data_84, data_83, data_82, data_81, data_80, data_79, data_78, data_77, data_76, data_75};
  assign io_out_bits_data = {data_74, data_73, data_72, data_71, data_70, data_69, data_68, data_67, data_66, data_65, data_64, data_63, data_62, data_61, data_60, data_59, data_58, data_57, data_56, data_55, data_54, data_53, data_52, data_51, data_50, data_49, data_48, data_47, data_46, data_45, data_44, data_43, data_42, data_41, data_40, data_39, data_38, data_37, data_36, data_35, data_34, data_33, data_32, data_31, data_30, data_29, data_28, data_27, data_26, data_25, data_24, data_23, data_22, data_21, data_20, data_19, data_18, data_17, data_16, data_15, data_14, data_13, data_12, data_11};
  assign io_out_bits_corrupt = data_10;
  assign io_out_bits_union = {data_9, data_8, data_7, data_6, data_5, data_4, data_3, data_2, data_1};
endmodule
