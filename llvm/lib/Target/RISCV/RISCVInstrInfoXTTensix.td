//===-- RISCVInstrInfoXTTensix.td --------------------------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file describes the Tenstorrent Tensix accelerator interface extension.
//
// The Tensix accelerator is controlled by "Baby RISC-V" cores that push
// 32-bit encoded instructions to the accelerator via memory-mapped stores.
// A Tensix instruction word is emitted by storing the 32-bit immediate to the
// instruction buffer.
//
// Encoding: the 32-bit Tensix word T[31:0] is rotated left by 2 bits so that
// its low two bits never form the 0b11 pattern reserved for 32-bit standard
// instructions:
//   Inst[1:0]   = T[31:30]  (opcode high 2 bits)
//   Inst[31:26] = T[29:24]  (opcode low 6 bits)
//   Inst[25:2]  = T[23:0]   (operand fields)
//
// For an operand at Tensix bit position T[n] where n <= 23: Inst[n+2].
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Operand definitions
//===----------------------------------------------------------------------===//

// Custom operand for a 32-bit Tensix instruction word. The value must be
// < 0xC0000000 so that, after the left-rotate-by-2 encoding, the low two bits
// are never 0b11 (which would alias the standard 32-bit instruction space).
def TTensixImm32AsmOperand : AsmOperandClass {
  let Name = "TTensixImm32";
  let RenderMethod = "addImmOperands";
  let DiagnosticType = "InvalidTTensixImm32";
  let DiagnosticString = "operand must be a valid Tensix immediate (< 0xC0000000)";
}

def ttensix_imm32 : Operand<i32> {
  let ParserMatchClass = TTensixImm32AsmOperand;
  let EncoderMethod = "getTTensixImm32OpValue";
  let DecoderMethod = "decodeTTensixImm32Operand";
}

//===----------------------------------------------------------------------===//
// Base instruction class
//===----------------------------------------------------------------------===//

// TTInst - Base class for named Tensix instructions with individual operands.
// The 8-bit opcode maps to T[31:24]:
//   Inst[1:0]   = opcode[7:6]  (T[31:30])
//   Inst[31:26] = opcode[5:0]  (T[29:24])
// The 24-bit operand field maps to T[23:0] -> Inst[25:2]. Derived instructions
// place their operands into tt_opr using Tensix bit positions.
class TTInst<bits<8> opcode, dag outs, dag ins, string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatOther> {
  bits<24> tt_opr = 0;

  let Inst{1-0}   = opcode{7-6};
  let Inst{31-26} = opcode{5-0};
  let Inst{25-2}  = tt_opr;

  let hasSideEffects = 1;
  let mayLoad = 0;
  let mayStore = 1;
  let DecoderNamespace = "XTTensix";
  let Predicates = [HasVendorXTTensixWH, IsRV32];
}

//===----------------------------------------------------------------------===//
// Generic raw-word instruction
//===----------------------------------------------------------------------===//

let Predicates = [HasVendorXTTensixWH, IsRV32] in {
// TTINSN emits an arbitrary 32-bit Tensix word. It backs the `.ttinsn`
// assembler directive and is used to issue instructions that are not (yet)
// modelled with a dedicated mnemonic. It is asm-parser only: the disassembler
// recovers the specific named instructions instead.
let hasSideEffects = 1, mayLoad = 0, mayStore = 1,
    DecoderNamespace = "XTTensix", isAsmParserOnly = 1 in
def TTINSN : RVInst<(outs), (ins ttensix_imm32:$imm),
                    "ttinsn", "$imm", [], InstFormatOther> {
  bits<32> imm;
  let Inst{31-2} = imm{29-0};
  let Inst{1-0} = imm{31-30};
}
} // Predicates = [HasVendorXTTensixWH, IsRV32]

//===----------------------------------------------------------------------===//
// Frontend/Control Instructions
//===----------------------------------------------------------------------===//

def TT_NOP : TTInst<0x02, (outs), (ins), "tt.nop", "">;

def TT_MOP : TTInst<0x01, (outs),
    (ins uimm16:$MaskLo, uimm7:$Count1, uimm1:$Template),
    "tt.mop", "$MaskLo, $Count1, $Template"> {
  bits<16> MaskLo;
  bits<7> Count1;
  bits<1> Template;
  let tt_opr{15-0} = MaskLo;
  let tt_opr{22-16} = Count1;
  let tt_opr{23} = Template;
}

def TT_MOP_CFG : TTInst<0x03, (outs), (ins uimm16:$MaskHi),
    "tt.mop_cfg", "$MaskHi"> {
  bits<16> MaskHi;
  let tt_opr{15-0} = MaskHi;
}

def TT_REPLAY : TTInst<0x04, (outs),
    (ins uimm1:$Load, uimm1:$Exec, uimm6:$Count, uimm5:$Index),
    "tt.replay", "$Load, $Exec, $Count, $Index"> {
  bits<1> Load;
  bits<1> Exec;
  bits<6> Count;
  bits<5> Index;
  let tt_opr{0} = Load;
  let tt_opr{1} = Exec;
  let tt_opr{9-4} = Count;
  let tt_opr{18-14} = Index;
}

//===----------------------------------------------------------------------===//
// Data Movement Instructions
//===----------------------------------------------------------------------===//

// MOVD2A / MOVD2B / MOVA2D share an operand layout. On Blackhole the address
// mode widens from 2 to 3 bits (claiming bit 14), so the Blackhole variants are
// defined separately below.
class TTMov<bits<8> opcode, string mnemonic>
    : TTInst<opcode, (outs),
             (ins uimm10:$DstRow, uimm2:$InstrMod, uimm2:$AddrMod,
                  uimm6:$SrcRow, uimm1:$UseDst32bLo),
             mnemonic, "$DstRow, $InstrMod, $AddrMod, $SrcRow, $UseDst32bLo"> {
  bits<10> DstRow;
  bits<2> InstrMod;
  bits<2> AddrMod;
  bits<6> SrcRow;
  bits<1> UseDst32bLo;
  let tt_opr{9-0} = DstRow;
  let tt_opr{13-12} = InstrMod;
  let tt_opr{16-15} = AddrMod;
  let tt_opr{22-17} = SrcRow;
  let tt_opr{23} = UseDst32bLo;
}

def TT_MOVD2A : TTMov<0x08, "tt.movd2a">;
def TT_MOVD2B : TTMov<0x0A, "tt.movd2b">;
def TT_MOVA2D : TTMov<0x12, "tt.mova2d">;

def TT_MOVB2A : TTInst<0x0B, (outs),
    (ins uimm6:$SrcBRow, uimm2:$InstrMod, uimm2:$AddrMod, uimm6:$SrcARow),
    "tt.movb2a", "$SrcBRow, $InstrMod, $AddrMod, $SrcARow"> {
  bits<6> SrcBRow;
  bits<2> InstrMod;
  bits<2> AddrMod;
  bits<6> SrcARow;
  let tt_opr{5-0} = SrcBRow;
  let tt_opr{13-12} = InstrMod;
  let tt_opr{16-15} = AddrMod;
  let tt_opr{22-17} = SrcARow;
}

def TT_MOVB2D : TTInst<0x13, (outs),
    (ins uimm10:$DstRow, uimm1:$BroadcastCol0, uimm1:$Broadcast1RowTo8,
         uimm1:$Move4Rows, uimm2:$AddrMod, uimm6:$SrcRow, uimm1:$UseDst32bLo),
    "tt.movb2d",
    "$DstRow, $BroadcastCol0, $Broadcast1RowTo8, $Move4Rows, $AddrMod, $SrcRow, $UseDst32bLo"> {
  bits<10> DstRow;
  bits<1> BroadcastCol0;
  bits<1> Broadcast1RowTo8;
  bits<1> Move4Rows;
  bits<2> AddrMod;
  bits<6> SrcRow;
  bits<1> UseDst32bLo;
  let tt_opr{9-0} = DstRow;
  let tt_opr{12} = BroadcastCol0;
  let tt_opr{13} = Broadcast1RowTo8;
  let tt_opr{14} = Move4Rows;
  let tt_opr{16-15} = AddrMod;
  let tt_opr{22-17} = SrcRow;
  let tt_opr{23} = UseDst32bLo;
}

//===----------------------------------------------------------------------===//
// Data Movement Instructions -- Blackhole variants
//===----------------------------------------------------------------------===//
//
// These instructions have a different operand layout on Blackhole (a wider
// address mode, and MOVB2D a wider instruction-mode field). They are gated on
// XTTensixBH and decoded from a Blackhole-specific table.

let Predicates = [HasVendorXTTensixBH, IsRV32], DecoderNamespace = "XTTensixBH" in {

class TTMovBH<bits<8> opcode, string mnemonic>
    : TTInst<opcode, (outs),
             (ins uimm10:$DstRow, uimm2:$InstrMod, uimm3:$AddrMod,
                  uimm6:$SrcRow, uimm1:$UseDst32bLo),
             mnemonic, "$DstRow, $InstrMod, $AddrMod, $SrcRow, $UseDst32bLo"> {
  bits<10> DstRow;
  bits<2> InstrMod;
  bits<3> AddrMod;
  bits<6> SrcRow;
  bits<1> UseDst32bLo;
  let tt_opr{9-0} = DstRow;
  let tt_opr{13-12} = InstrMod;
  let tt_opr{16-14} = AddrMod;
  let tt_opr{22-17} = SrcRow;
  let tt_opr{23} = UseDst32bLo;
}

def TT_MOVD2A_BH : TTMovBH<0x08, "tt.movd2a">;
def TT_MOVD2B_BH : TTMovBH<0x0A, "tt.movd2b">;
def TT_MOVA2D_BH : TTMovBH<0x12, "tt.mova2d">;

def TT_MOVB2A_BH : TTInst<0x0B, (outs),
    (ins uimm6:$SrcBRow, uimm2:$InstrMod, uimm3:$AddrMod, uimm6:$SrcARow),
    "tt.movb2a", "$SrcBRow, $InstrMod, $AddrMod, $SrcARow"> {
  bits<6> SrcBRow;
  bits<2> InstrMod;
  bits<3> AddrMod;
  bits<6> SrcARow;
  let tt_opr{5-0} = SrcBRow;
  let tt_opr{13-12} = InstrMod;
  let tt_opr{16-14} = AddrMod;
  let tt_opr{22-17} = SrcARow;
}

def TT_MOVB2D_BH : TTInst<0x13, (outs),
    (ins uimm10:$DstRow, uimm3:$InstrMod, uimm3:$AddrMod, uimm6:$SrcRow,
         uimm1:$UseDst32bLo),
    "tt.movb2d", "$DstRow, $InstrMod, $AddrMod, $SrcRow, $UseDst32bLo"> {
  bits<10> DstRow;
  bits<3> InstrMod;
  bits<3> AddrMod;
  bits<6> SrcRow;
  bits<1> UseDst32bLo;
  let tt_opr{9-0} = DstRow;
  let tt_opr{13-11} = InstrMod;
  let tt_opr{16-14} = AddrMod;
  let tt_opr{22-17} = SrcRow;
  let tt_opr{23} = UseDst32bLo;
}

} // Predicates = [HasVendorXTTensixBH, IsRV32], DecoderNamespace = "XTTensixBH"
