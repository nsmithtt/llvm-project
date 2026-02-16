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
// The .ttinsn instruction stores a 32-bit immediate to INSTRN_BUF_BASE.
//
// Encoding: The 32-bit Tensix word T[31:0] is rotated left by 2 bits:
//   Inst[1:0]   = T[31:30]  (opcode high 2 bits)
//   Inst[31:26]  = T[29:24]  (opcode low 6 bits)
//   Inst[25:2]   = T[23:0]   (operand fields)
//
// For operand at Tensix position T[n] where n <= 23: Inst[n+2].
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Operand definitions
//===----------------------------------------------------------------------===//

// Unsigned immediate operand types for Tensix instruction fields.
// uimm9, uimm10, uimm11 are defined by other extensions (XMips, Xqci).
def uimm12 : RISCVUImmOp<12>;
def uimm15 : RISCVUImmOp<15>;
def uimm18 : RISCVUImmOp<18>;

// Signed immediate operand type for Tensix instruction fields.
def simm12 : RISCVSImmOp<12>;

// Custom operand for 32-bit Tensix immediate.
// The immediate must be < 0xC0000000 to ensure proper encoding.
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
// The 24-bit operand field maps to T[23:0] -> Inst[25:2].
// Derived classes override individual bits of tt_opr using Tensix bit positions.
class TTInst<bits<8> opcode, dag outs, dag ins, string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatOther> {
  bits<24> tt_opr = 0;

  let Inst{1-0}   = opcode{7-6};
  let Inst{31-26}  = opcode{5-0};
  let Inst{25-2}   = tt_opr;

  let hasSideEffects = 1;
  let mayLoad = 0;
  let mayStore = 1;
  let isCodeGenOnly = 0;
  let DecoderNamespace = "XTTensix";
  let Predicates = [HasVendorXTTensix, IsRV32];
}

//===----------------------------------------------------------------------===//
// Generic .ttinsn instruction (retained as fallback)
//===----------------------------------------------------------------------===//

let Predicates = [HasVendorXTTensix, IsRV32] in {
let hasSideEffects = 1, mayLoad = 0, mayStore = 1,
    DecoderNamespace = "XTTensix" in {
  // TTINSN is a generic fallback for raw 32-bit Tensix encoding.
  // isAsmParserOnly excludes it from the disassembler (which uses specific defs).
  let isAsmParserOnly = 1 in
  def TTINSN : RVInst<(outs), (ins ttensix_imm32:$imm),
                      "ttinsn", "$imm", [], InstFormatOther> {
    bits<32> imm;
    let Inst{31-2} = imm{29-0};
    let Inst{1-0} = imm{31-30};
  }
} // hasSideEffects, mayLoad, mayStore, ...
} // Predicates

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
// Matrix Unit (FPU) Instructions
//===----------------------------------------------------------------------===//

def TT_MVMUL : TTInst<0x26, (outs),
    (ins uimm10:$DstRow, uimm2:$AddrMod, uimm1:$BroadcastSrcBRow,
         uimm1:$FlipSrcA, uimm1:$FlipSrcB),
    "tt.mvmul", "$DstRow, $AddrMod, $BroadcastSrcBRow, $FlipSrcA, $FlipSrcB"> {
  bits<10> DstRow;
  bits<2> AddrMod;
  bits<1> BroadcastSrcBRow;
  bits<1> FlipSrcA;
  bits<1> FlipSrcB;
  let tt_opr{9-0} = DstRow;
  let tt_opr{16-15} = AddrMod;
  let tt_opr{19} = BroadcastSrcBRow;
  let tt_opr{22} = FlipSrcA;
  let tt_opr{23} = FlipSrcB;
}

def TT_ELWMUL : TTInst<0x27, (outs),
    (ins uimm10:$DstRow, uimm2:$AddrMod, uimm1:$BroadcastSrcBCol0,
         uimm1:$BroadcastSrcBRow, uimm1:$FlipSrcA, uimm1:$FlipSrcB),
    "tt.elwmul",
    "$DstRow, $AddrMod, $BroadcastSrcBCol0, $BroadcastSrcBRow, $FlipSrcA, $FlipSrcB"> {
  bits<10> DstRow;
  bits<2> AddrMod;
  bits<1> BroadcastSrcBCol0;
  bits<1> BroadcastSrcBRow;
  bits<1> FlipSrcA;
  bits<1> FlipSrcB;
  let tt_opr{9-0} = DstRow;
  let tt_opr{16-15} = AddrMod;
  let tt_opr{19} = BroadcastSrcBCol0;
  let tt_opr{20} = BroadcastSrcBRow;
  let tt_opr{22} = FlipSrcA;
  let tt_opr{23} = FlipSrcB;
}

def TT_ELWADD : TTInst<0x28, (outs),
    (ins uimm10:$DstRow, uimm2:$AddrMod, uimm1:$BroadcastSrcBCol0,
         uimm1:$BroadcastSrcBRow, uimm1:$AddDst,
         uimm1:$FlipSrcA, uimm1:$FlipSrcB),
    "tt.elwadd",
    "$DstRow, $AddrMod, $BroadcastSrcBCol0, $BroadcastSrcBRow, $AddDst, $FlipSrcA, $FlipSrcB"> {
  bits<10> DstRow;
  bits<2> AddrMod;
  bits<1> BroadcastSrcBCol0;
  bits<1> BroadcastSrcBRow;
  bits<1> AddDst;
  bits<1> FlipSrcA;
  bits<1> FlipSrcB;
  let tt_opr{9-0} = DstRow;
  let tt_opr{16-15} = AddrMod;
  let tt_opr{19} = BroadcastSrcBCol0;
  let tt_opr{20} = BroadcastSrcBRow;
  let tt_opr{21} = AddDst;
  let tt_opr{22} = FlipSrcA;
  let tt_opr{23} = FlipSrcB;
}

def TT_DOTPV : TTInst<0x29, (outs),
    (ins uimm10:$DstRow, uimm2:$AddrMod, uimm1:$FlipSrcA, uimm1:$FlipSrcB),
    "tt.dotpv", "$DstRow, $AddrMod, $FlipSrcA, $FlipSrcB"> {
  bits<10> DstRow;
  bits<2> AddrMod;
  bits<1> FlipSrcA;
  bits<1> FlipSrcB;
  let tt_opr{9-0} = DstRow;
  let tt_opr{16-15} = AddrMod;
  let tt_opr{22} = FlipSrcA;
  let tt_opr{23} = FlipSrcB;
}

// ELWSUB has the same operand layout as ELWADD.
def TT_ELWSUB : TTInst<0x30, (outs),
    (ins uimm10:$DstRow, uimm2:$AddrMod, uimm1:$BroadcastSrcBCol0,
         uimm1:$BroadcastSrcBRow, uimm1:$AddDst,
         uimm1:$FlipSrcA, uimm1:$FlipSrcB),
    "tt.elwsub",
    "$DstRow, $AddrMod, $BroadcastSrcBCol0, $BroadcastSrcBRow, $AddDst, $FlipSrcA, $FlipSrcB"> {
  bits<10> DstRow;
  bits<2> AddrMod;
  bits<1> BroadcastSrcBCol0;
  bits<1> BroadcastSrcBRow;
  bits<1> AddDst;
  bits<1> FlipSrcA;
  bits<1> FlipSrcB;
  let tt_opr{9-0} = DstRow;
  let tt_opr{16-15} = AddrMod;
  let tt_opr{19} = BroadcastSrcBCol0;
  let tt_opr{20} = BroadcastSrcBRow;
  let tt_opr{21} = AddDst;
  let tt_opr{22} = FlipSrcA;
  let tt_opr{23} = FlipSrcB;
}

def TT_GMPOOL : TTInst<0x33, (outs),
    (ins uimm10:$DstRow, uimm1:$ArgMax, uimm2:$AddrMod,
         uimm1:$FlipSrcA, uimm1:$FlipSrcB),
    "tt.gmpool", "$DstRow, $ArgMax, $AddrMod, $FlipSrcA, $FlipSrcB"> {
  bits<10> DstRow;
  bits<1> ArgMax;
  bits<2> AddrMod;
  bits<1> FlipSrcA;
  bits<1> FlipSrcB;
  let tt_opr{9-0} = DstRow;
  let tt_opr{14} = ArgMax;
  let tt_opr{16-15} = AddrMod;
  let tt_opr{22} = FlipSrcA;
  let tt_opr{23} = FlipSrcB;
}

def TT_GAPOOL : TTInst<0x34, (outs),
    (ins uimm10:$DstRow, uimm2:$AddrMod, uimm1:$FlipSrcA, uimm1:$FlipSrcB),
    "tt.gapool", "$DstRow, $AddrMod, $FlipSrcA, $FlipSrcB"> {
  bits<10> DstRow;
  bits<2> AddrMod;
  bits<1> FlipSrcA;
  bits<1> FlipSrcB;
  let tt_opr{9-0} = DstRow;
  let tt_opr{16-15} = AddrMod;
  let tt_opr{22} = FlipSrcA;
  let tt_opr{23} = FlipSrcB;
}

//===----------------------------------------------------------------------===//
// Data Movement Instructions
//===----------------------------------------------------------------------===//

def TT_MOVD2A : TTInst<0x08, (outs),
    (ins uimm10:$DstRow, uimm1:$Move4Rows, uimm2:$AddrMod,
         uimm6:$SrcRow, uimm1:$UseDst32bLo),
    "tt.movd2a", "$DstRow, $Move4Rows, $AddrMod, $SrcRow, $UseDst32bLo"> {
  bits<10> DstRow;
  bits<1> Move4Rows;
  bits<2> AddrMod;
  bits<6> SrcRow;
  bits<1> UseDst32bLo;
  let tt_opr{9-0} = DstRow;
  let tt_opr{13} = Move4Rows;
  let tt_opr{16-15} = AddrMod;
  let tt_opr{22-17} = SrcRow;
  let tt_opr{23} = UseDst32bLo;
}

def TT_MOVDBGA2D : TTInst<0x09, (outs),
    (ins uimm10:$DstRow, uimm1:$Move8Rows, uimm2:$AddrMod,
         uimm6:$SrcRow, uimm1:$UseDst32bLo),
    "tt.movdbga2d", "$DstRow, $Move8Rows, $AddrMod, $SrcRow, $UseDst32bLo"> {
  bits<10> DstRow;
  bits<1> Move8Rows;
  bits<2> AddrMod;
  bits<6> SrcRow;
  bits<1> UseDst32bLo;
  let tt_opr{9-0} = DstRow;
  let tt_opr{13} = Move8Rows;
  let tt_opr{16-15} = AddrMod;
  let tt_opr{22-17} = SrcRow;
  let tt_opr{23} = UseDst32bLo;
}

def TT_MOVD2B : TTInst<0x0A, (outs),
    (ins uimm10:$DstRow, uimm1:$Move4Rows, uimm2:$AddrMod,
         uimm6:$SrcRow, uimm1:$UseDst32bLo),
    "tt.movd2b", "$DstRow, $Move4Rows, $AddrMod, $SrcRow, $UseDst32bLo"> {
  bits<10> DstRow;
  bits<1> Move4Rows;
  bits<2> AddrMod;
  bits<6> SrcRow;
  bits<1> UseDst32bLo;
  let tt_opr{9-0} = DstRow;
  let tt_opr{13} = Move4Rows;
  let tt_opr{16-15} = AddrMod;
  let tt_opr{22-17} = SrcRow;
  let tt_opr{23} = UseDst32bLo;
}

def TT_MOVB2A : TTInst<0x0B, (outs),
    (ins uimm6:$SrcBRow, uimm1:$Move4Rows, uimm2:$AddrMod, uimm6:$SrcARow),
    "tt.movb2a", "$SrcBRow, $Move4Rows, $AddrMod, $SrcARow"> {
  bits<6> SrcBRow;
  bits<1> Move4Rows;
  bits<2> AddrMod;
  bits<6> SrcARow;
  let tt_opr{5-0} = SrcBRow;
  let tt_opr{13} = Move4Rows;
  let tt_opr{16-15} = AddrMod;
  let tt_opr{22-17} = SrcARow;
}

def TT_ZEROACC : TTInst<0x10, (outs),
    (ins uimm10:$Imm10, uimm2:$AddrMod, uimm1:$Revert,
         uimm2:$Mode, uimm1:$UseDst32b),
    "tt.zeroacc", "$Imm10, $AddrMod, $Revert, $Mode, $UseDst32b"> {
  bits<10> Imm10;
  bits<2> AddrMod;
  bits<1> Revert;
  bits<2> Mode;
  bits<1> UseDst32b;
  let tt_opr{9-0} = Imm10;
  let tt_opr{16-15} = AddrMod;
  let tt_opr{18} = Revert;
  let tt_opr{20-19} = Mode;
  let tt_opr{21} = UseDst32b;
}

def TT_ZEROSRC : TTInst<0x11, (outs),
    (ins uimm1:$ClearSrcA, uimm1:$ClearSrcB, uimm1:$BothBanks,
         uimm1:$SingleBankMatrixUnit, uimm1:$NegativeInfSrcA),
    "tt.zerosrc",
    "$ClearSrcA, $ClearSrcB, $BothBanks, $SingleBankMatrixUnit, $NegativeInfSrcA"> {
  bits<1> ClearSrcA;
  bits<1> ClearSrcB;
  bits<1> BothBanks;
  bits<1> SingleBankMatrixUnit;
  bits<1> NegativeInfSrcA;
  let tt_opr{0} = ClearSrcA;
  let tt_opr{1} = ClearSrcB;
  let tt_opr{2} = BothBanks;
  let tt_opr{3} = SingleBankMatrixUnit;
  let tt_opr{4} = NegativeInfSrcA;
}

def TT_MOVA2D : TTInst<0x12, (outs),
    (ins uimm10:$DstRow, uimm1:$Move8Rows, uimm2:$AddrMod,
         uimm6:$SrcRow, uimm1:$UseDst32bLo),
    "tt.mova2d", "$DstRow, $Move8Rows, $AddrMod, $SrcRow, $UseDst32bLo"> {
  bits<10> DstRow;
  bits<1> Move8Rows;
  bits<2> AddrMod;
  bits<6> SrcRow;
  bits<1> UseDst32bLo;
  let tt_opr{9-0} = DstRow;
  let tt_opr{13} = Move8Rows;
  let tt_opr{16-15} = AddrMod;
  let tt_opr{22-17} = SrcRow;
  let tt_opr{23} = UseDst32bLo;
}

def TT_MOVB2D : TTInst<0x13, (outs),
    (ins uimm10:$DstRow, uimm1:$BroadcastCol0, uimm1:$Broadcast1RowTo8,
         uimm1:$Move4Rows, uimm2:$AddrMod, uimm6:$SrcRow,
         uimm1:$UseDst32bLo),
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

def TT_TRNSPSRCB : TTInst<0x16, (outs), (ins), "tt.trnspsrcb", "">;

def TT_SHIFTXA : TTInst<0x17, (outs), (ins uimm2:$Direction),
    "tt.shiftxa", "$Direction"> {
  bits<2> Direction;
  let tt_opr{1-0} = Direction;
}

def TT_SHIFTXB : TTInst<0x18, (outs),
    (ins uimm6:$SrcRow, uimm1:$ShiftInZero, uimm2:$AddrMod),
    "tt.shiftxb", "$SrcRow, $ShiftInZero, $AddrMod"> {
  bits<6> SrcRow;
  bits<1> ShiftInZero;
  bits<2> AddrMod;
  let tt_opr{5-0} = SrcRow;
  let tt_opr{10} = ShiftInZero;
  let tt_opr{16-15} = AddrMod;
}

def TT_CLREXPHIST : TTInst<0x21, (outs), (ins), "tt.clrexphist", "">;

//===----------------------------------------------------------------------===//
// Unpacker/Misc Matrix Instructions
//===----------------------------------------------------------------------===//

def TT_GATESRCRST : TTInst<0x35, (outs),
    (ins uimm1:$InvalidateSrcBCache),
    "tt.gatesrcrst", "$InvalidateSrcBCache"> {
  bits<1> InvalidateSrcBCache;
  let tt_opr{1} = InvalidateSrcBCache;
}

def TT_CLEARDVALID : TTInst<0x36, (outs),
    (ins uimm1:$Reset, uimm1:$KeepReadingSameSrc,
         uimm1:$FlipSrcA, uimm1:$FlipSrcB),
    "tt.cleardvalid", "$Reset, $KeepReadingSameSrc, $FlipSrcA, $FlipSrcB"> {
  bits<1> Reset;
  bits<1> KeepReadingSameSrc;
  bits<1> FlipSrcA;
  bits<1> FlipSrcB;
  let tt_opr{0} = Reset;
  let tt_opr{1} = KeepReadingSameSrc;
  let tt_opr{22} = FlipSrcA;
  let tt_opr{23} = FlipSrcB;
}

def TT_SETRWC : TTInst<0x37, (outs),
    (ins uimm1:$SrcA, uimm1:$SrcB, uimm1:$Dst, uimm1:$Fidelity,
         uimm4:$SrcAVal, uimm4:$SrcBVal, uimm4:$DstVal,
         uimm1:$SrcACr, uimm1:$SrcBCr, uimm1:$DstCr, uimm1:$DstCtoCr,
         uimm1:$FlipSrcA, uimm1:$FlipSrcB),
    "tt.setrwc",
    "$SrcA, $SrcB, $Dst, $Fidelity, $SrcAVal, $SrcBVal, $DstVal, $SrcACr, $SrcBCr, $DstCr, $DstCtoCr, $FlipSrcA, $FlipSrcB"> {
  bits<1> SrcA;
  bits<1> SrcB;
  bits<1> Dst;
  bits<1> Fidelity;
  bits<4> SrcAVal;
  bits<4> SrcBVal;
  bits<4> DstVal;
  bits<1> SrcACr;
  bits<1> SrcBCr;
  bits<1> DstCr;
  bits<1> DstCtoCr;
  bits<1> FlipSrcA;
  bits<1> FlipSrcB;
  let tt_opr{0} = SrcA;
  let tt_opr{1} = SrcB;
  let tt_opr{2} = Dst;
  let tt_opr{3} = Fidelity;
  let tt_opr{9-6} = SrcAVal;
  let tt_opr{13-10} = SrcBVal;
  let tt_opr{17-14} = DstVal;
  let tt_opr{18} = SrcACr;
  let tt_opr{19} = SrcBCr;
  let tt_opr{20} = DstCr;
  let tt_opr{21} = DstCtoCr;
  let tt_opr{22} = FlipSrcA;
  let tt_opr{23} = FlipSrcB;
}

def TT_INCRWC : TTInst<0x38, (outs),
    (ins uimm4:$SrcAInc, uimm4:$SrcBInc, uimm4:$DstInc,
         uimm1:$SrcACr, uimm1:$SrcBCr, uimm1:$DstCr),
    "tt.incrwc", "$SrcAInc, $SrcBInc, $DstInc, $SrcACr, $SrcBCr, $DstCr"> {
  bits<4> SrcAInc;
  bits<4> SrcBInc;
  bits<4> DstInc;
  bits<1> SrcACr;
  bits<1> SrcBCr;
  bits<1> DstCr;
  let tt_opr{9-6} = SrcAInc;
  let tt_opr{13-10} = SrcBInc;
  let tt_opr{17-14} = DstInc;
  let tt_opr{18} = SrcACr;
  let tt_opr{19} = SrcBCr;
  let tt_opr{20} = DstCr;
}

//===----------------------------------------------------------------------===//
// Packer/Unpacker Instructions
//===----------------------------------------------------------------------===//

def TT_XMOV : TTInst<0x40, (outs), (ins), "tt.xmov", "">;

def TT_PACR : TTInst<0x41, (outs),
    (ins uimm1:$Last, uimm1:$Flush, uimm1:$Concat, uimm1:$OvrdThreadId,
         uimm4:$PackerMask, uimm1:$ZeroWrite, uimm2:$AddrMod),
    "tt.pacr",
    "$Last, $Flush, $Concat, $OvrdThreadId, $PackerMask, $ZeroWrite, $AddrMod"> {
  bits<1> Last;
  bits<1> Flush;
  bits<1> Concat;
  bits<1> OvrdThreadId;
  bits<4> PackerMask;
  bits<1> ZeroWrite;
  bits<2> AddrMod;
  let tt_opr{0} = Last;
  let tt_opr{1} = Flush;
  let tt_opr{4} = Concat;
  let tt_opr{7} = OvrdThreadId;
  let tt_opr{11-8} = PackerMask;
  let tt_opr{12} = ZeroWrite;
  let tt_opr{16-15} = AddrMod;
  // bit[23] = 0 fixed
}

// UNPACR - Regular mode (bit[1]=0, bit[13]=0)
def TT_UNPACR : TTInst<0x42, (outs),
    (ins uimm1:$RowSearch, uimm1:$UseContextCounter,
         uimm1:$AllDatumsAreZero, uimm1:$FlipSrc, uimm1:$MultiContextMode,
         uimm2:$ContextADC, uimm3:$ContextNumber,
         uimm2:$Ch0ZInc, uimm2:$Ch0YInc, uimm2:$Ch1ZInc, uimm2:$Ch1YInc,
         uimm1:$WhichUnpacker),
    "tt.unpacr",
    "$RowSearch, $UseContextCounter, $AllDatumsAreZero, $FlipSrc, $MultiContextMode, $ContextADC, $ContextNumber, $Ch0ZInc, $Ch0YInc, $Ch1ZInc, $Ch1YInc, $WhichUnpacker"> {
  bits<1> RowSearch;
  bits<1> UseContextCounter;
  bits<1> AllDatumsAreZero;
  bits<1> FlipSrc;
  bits<1> MultiContextMode;
  bits<2> ContextADC;
  bits<3> ContextNumber;
  bits<2> Ch0ZInc;
  bits<2> Ch0YInc;
  bits<2> Ch1ZInc;
  bits<2> Ch1YInc;
  bits<1> WhichUnpacker;
  // bit[1]=0, bit[13]=0 (fixed for regular mode)
  let tt_opr{2} = RowSearch;
  let tt_opr{3} = UseContextCounter;
  let tt_opr{4} = AllDatumsAreZero;
  let tt_opr{6} = FlipSrc;
  let tt_opr{7} = MultiContextMode;
  let tt_opr{9-8} = ContextADC;
  let tt_opr{12-10} = ContextNumber;
  let tt_opr{16-15} = Ch0ZInc;
  let tt_opr{18-17} = Ch0YInc;
  let tt_opr{20-19} = Ch1ZInc;
  let tt_opr{22-21} = Ch1YInc;
  let tt_opr{23} = WhichUnpacker;
}

// UNPACR - IncrementContextCounter mode (bit[1]=0, bit[13]=1)
def TT_UNPACR_CTXINC : TTInst<0x42, (outs), (ins uimm1:$WhichUnpacker),
    "tt.unpacr.ctxinc", "$WhichUnpacker"> {
  bits<1> WhichUnpacker;
  let tt_opr{13} = 1; // discriminator
  let tt_opr{23} = WhichUnpacker;
}

// UNPACR - FlushCache mode (bit[1]=1)
def TT_UNPACR_FLUSH : TTInst<0x42, (outs),
    (ins uimm1:$MultiContextMode, uimm1:$WhichUnpacker),
    "tt.unpacr.flush", "$MultiContextMode, $WhichUnpacker"> {
  bits<1> MultiContextMode;
  bits<1> WhichUnpacker;
  let tt_opr{1} = 1; // discriminator
  let tt_opr{7} = MultiContextMode;
  let tt_opr{23} = WhichUnpacker;
}

def TT_UNPACR_NOP : TTInst<0x43, (outs), (ins), "tt.unpacr_nop", "">;

// PACR_SETREG: bit[1]=1, bits[11:8]=0xF, bit[23]=1
def TT_PACR_SETREG : TTInst<0x4A, (outs),
    (ins uimm6:$AddrMid, uimm10:$Value10, uimm1:$AddrSel),
    "tt.pacr_setreg", "$AddrMid, $Value10, $AddrSel"> {
  bits<6> AddrMid;
  bits<10> Value10;
  bits<1> AddrSel;
  let tt_opr{1} = 1;
  let tt_opr{7-2} = AddrMid;
  let tt_opr{11-8} = 0xF;
  let tt_opr{21-12} = Value10;
  let tt_opr{22} = AddrSel;
  let tt_opr{23} = 1;
}

//===----------------------------------------------------------------------===//
// Configuration Instructions
//===----------------------------------------------------------------------===//

// SETDMAREG - Immediate mode (bit[7]=0)
def TT_SETDMAREG_IMM : TTInst<0x45, (outs),
    (ins uimm7:$ResultHalfReg, uimm16:$NewValue),
    "tt.setdmareg", "$ResultHalfReg, $NewValue"> {
  bits<7> ResultHalfReg;
  bits<16> NewValue;
  let tt_opr{6-0} = ResultHalfReg;
  // bit[7] = 0 (immediate mode)
  let tt_opr{23-8} = NewValue;
}

// SETDMAREG - Special mode (bit[7]=1)
def TT_SETDMAREG_SPECIAL : TTInst<0x45, (outs),
    (ins uimm7:$ResultHalfReg, uimm3:$InputHalfReg, uimm4:$InputSource,
         uimm4:$WhichPackers, uimm2:$ResultSize),
    "tt.setdmareg.special",
    "$ResultHalfReg, $InputHalfReg, $InputSource, $WhichPackers, $ResultSize"> {
  bits<7> ResultHalfReg;
  bits<3> InputHalfReg;
  bits<4> InputSource;
  bits<4> WhichPackers;
  bits<2> ResultSize;
  let tt_opr{6-0} = ResultHalfReg;
  let tt_opr{7} = 1; // special mode discriminator
  let tt_opr{10-8} = InputHalfReg;
  let tt_opr{14-11} = InputSource;
  let tt_opr{18-15} = WhichPackers;
  let tt_opr{23-22} = ResultSize;
}

// REG2FLOP - Configuration mode (bits[21:20]=0)
def TT_REG2FLOP_CFG : TTInst<0x48, (outs),
    (ins uimm6:$InputReg, uimm7:$ThConCfgIndex, uimm2:$SizeSel),
    "tt.reg2flop", "$InputReg, $ThConCfgIndex, $SizeSel"> {
  bits<6> InputReg;
  bits<7> ThConCfgIndex;
  bits<2> SizeSel;
  let tt_opr{5-0} = InputReg;
  let tt_opr{12-6} = ThConCfgIndex;
  // bits[21:20] = 0 (CFG mode)
  let tt_opr{23-22} = SizeSel;
}

// REG2FLOP - ADC mode (bit[21]=1)
def TT_REG2FLOP_ADC : TTInst<0x48, (outs),
    (ins uimm6:$InputReg, uimm2:$XYZW, uimm1:$Cr, uimm2:$ADCSel,
         uimm1:$Channel, uimm2:$ThreadSel, uimm2:$Shift8,
         uimm1:$OverrideThread, uimm2:$SizeSel),
    "tt.reg2flop.adc",
    "$InputReg, $XYZW, $Cr, $ADCSel, $Channel, $ThreadSel, $Shift8, $OverrideThread, $SizeSel"> {
  bits<6> InputReg;
  bits<2> XYZW;
  bits<1> Cr;
  bits<2> ADCSel;
  bits<1> Channel;
  bits<2> ThreadSel;
  bits<2> Shift8;
  bits<1> OverrideThread;
  bits<2> SizeSel;
  let tt_opr{5-0} = InputReg;
  let tt_opr{7-6} = XYZW;
  let tt_opr{8} = Cr;
  let tt_opr{10-9} = ADCSel;
  let tt_opr{11} = Channel;
  let tt_opr{17-16} = ThreadSel;
  let tt_opr{19-18} = Shift8;
  let tt_opr{20} = OverrideThread;
  let tt_opr{21} = 1; // ADC mode discriminator
  let tt_opr{23-22} = SizeSel;
}

def TT_LOADIND : TTInst<0x49, (outs),
    (ins uimm6:$AddrReg, uimm6:$ResultReg, uimm2:$OffsetIncrement,
         uimm7:$OffsetHalfReg, uimm2:$MemSize),
    "tt.loadind",
    "$AddrReg, $ResultReg, $OffsetIncrement, $OffsetHalfReg, $MemSize"> {
  bits<6> AddrReg;
  bits<6> ResultReg;
  bits<2> OffsetIncrement;
  bits<7> OffsetHalfReg;
  bits<2> MemSize;
  let tt_opr{5-0} = AddrReg;
  let tt_opr{11-6} = ResultReg;
  let tt_opr{13-12} = OffsetIncrement;
  let tt_opr{20-14} = OffsetHalfReg;
  let tt_opr{23-22} = MemSize;
}

def TT_SETADC : TTInst<0x50, (outs),
    (ins uimm18:$NewValue, uimm2:$XYZW, uimm1:$Channel,
         uimm1:$U0, uimm1:$U1, uimm1:$PK),
    "tt.setadc", "$NewValue, $XYZW, $Channel, $U0, $U1, $PK"> {
  bits<18> NewValue;
  bits<2> XYZW;
  bits<1> Channel;
  bits<1> U0;
  bits<1> U1;
  bits<1> PK;
  let tt_opr{17-0} = NewValue;
  let tt_opr{19-18} = XYZW;
  let tt_opr{20} = Channel;
  let tt_opr{21} = U0;
  let tt_opr{22} = U1;
  let tt_opr{23} = PK;
}

def TT_SETADCXY : TTInst<0x51, (outs),
    (ins uimm1:$X0, uimm1:$Y0, uimm1:$X1, uimm1:$Y1,
         uimm3:$X0Val, uimm3:$Y0Val, uimm3:$X1Val, uimm3:$Y1Val,
         uimm2:$ThreadOverride, uimm1:$U0, uimm1:$U1, uimm1:$PK),
    "tt.setadcxy",
    "$X0, $Y0, $X1, $Y1, $X0Val, $Y0Val, $X1Val, $Y1Val, $ThreadOverride, $U0, $U1, $PK"> {
  bits<1> X0;
  bits<1> Y0;
  bits<1> X1;
  bits<1> Y1;
  bits<3> X0Val;
  bits<3> Y0Val;
  bits<3> X1Val;
  bits<3> Y1Val;
  bits<2> ThreadOverride;
  bits<1> U0;
  bits<1> U1;
  bits<1> PK;
  let tt_opr{0} = X0;
  let tt_opr{1} = Y0;
  let tt_opr{2} = X1;
  let tt_opr{3} = Y1;
  let tt_opr{8-6} = X0Val;
  let tt_opr{11-9} = Y0Val;
  let tt_opr{14-12} = X1Val;
  let tt_opr{17-15} = Y1Val;
  let tt_opr{19-18} = ThreadOverride;
  let tt_opr{21} = U0;
  let tt_opr{22} = U1;
  let tt_opr{23} = PK;
}

def TT_INCADCXY : TTInst<0x52, (outs),
    (ins uimm3:$X0Inc, uimm3:$Y0Inc, uimm3:$X1Inc, uimm3:$Y1Inc,
         uimm2:$ThreadOverride, uimm1:$U0, uimm1:$U1, uimm1:$PK),
    "tt.incadcxy",
    "$X0Inc, $Y0Inc, $X1Inc, $Y1Inc, $ThreadOverride, $U0, $U1, $PK"> {
  bits<3> X0Inc;
  bits<3> Y0Inc;
  bits<3> X1Inc;
  bits<3> Y1Inc;
  bits<2> ThreadOverride;
  bits<1> U0;
  bits<1> U1;
  bits<1> PK;
  let tt_opr{8-6} = X0Inc;
  let tt_opr{11-9} = Y0Inc;
  let tt_opr{14-12} = X1Inc;
  let tt_opr{17-15} = Y1Inc;
  let tt_opr{19-18} = ThreadOverride;
  let tt_opr{21} = U0;
  let tt_opr{22} = U1;
  let tt_opr{23} = PK;
}

def TT_ADDRCRXY : TTInst<0x53, (outs),
    (ins uimm1:$X0, uimm1:$Y0, uimm1:$X1, uimm1:$Y1,
         uimm3:$X0Inc, uimm3:$Y0Inc, uimm3:$X1Inc, uimm3:$Y1Inc,
         uimm2:$ThreadOverride, uimm1:$U0, uimm1:$U1, uimm1:$PK),
    "tt.addrcrxy",
    "$X0, $Y0, $X1, $Y1, $X0Inc, $Y0Inc, $X1Inc, $Y1Inc, $ThreadOverride, $U0, $U1, $PK"> {
  bits<1> X0;
  bits<1> Y0;
  bits<1> X1;
  bits<1> Y1;
  bits<3> X0Inc;
  bits<3> Y0Inc;
  bits<3> X1Inc;
  bits<3> Y1Inc;
  bits<2> ThreadOverride;
  bits<1> U0;
  bits<1> U1;
  bits<1> PK;
  let tt_opr{0} = X0;
  let tt_opr{1} = Y0;
  let tt_opr{2} = X1;
  let tt_opr{3} = Y1;
  let tt_opr{8-6} = X0Inc;
  let tt_opr{11-9} = Y0Inc;
  let tt_opr{14-12} = X1Inc;
  let tt_opr{17-15} = Y1Inc;
  let tt_opr{19-18} = ThreadOverride;
  let tt_opr{21} = U0;
  let tt_opr{22} = U1;
  let tt_opr{23} = PK;
}

def TT_SETADCZW : TTInst<0x54, (outs),
    (ins uimm1:$Z0, uimm1:$W0, uimm1:$Z1, uimm1:$W1,
         uimm3:$Z0Val, uimm3:$W0Val, uimm3:$Z1Val, uimm3:$W1Val,
         uimm2:$ThreadOverride, uimm1:$U0, uimm1:$U1, uimm1:$PK),
    "tt.setadczw",
    "$Z0, $W0, $Z1, $W1, $Z0Val, $W0Val, $Z1Val, $W1Val, $ThreadOverride, $U0, $U1, $PK"> {
  bits<1> Z0;
  bits<1> W0;
  bits<1> Z1;
  bits<1> W1;
  bits<3> Z0Val;
  bits<3> W0Val;
  bits<3> Z1Val;
  bits<3> W1Val;
  bits<2> ThreadOverride;
  bits<1> U0;
  bits<1> U1;
  bits<1> PK;
  let tt_opr{0} = Z0;
  let tt_opr{1} = W0;
  let tt_opr{2} = Z1;
  let tt_opr{3} = W1;
  let tt_opr{8-6} = Z0Val;
  let tt_opr{11-9} = W0Val;
  let tt_opr{14-12} = Z1Val;
  let tt_opr{17-15} = W1Val;
  let tt_opr{19-18} = ThreadOverride;
  let tt_opr{21} = U0;
  let tt_opr{22} = U1;
  let tt_opr{23} = PK;
}

def TT_INCADCZW : TTInst<0x55, (outs),
    (ins uimm3:$Z0Inc, uimm3:$W0Inc, uimm3:$Z1Inc, uimm3:$W1Inc,
         uimm2:$ThreadOverride, uimm1:$U0, uimm1:$U1, uimm1:$PK),
    "tt.incadczw",
    "$Z0Inc, $W0Inc, $Z1Inc, $W1Inc, $ThreadOverride, $U0, $U1, $PK"> {
  bits<3> Z0Inc;
  bits<3> W0Inc;
  bits<3> Z1Inc;
  bits<3> W1Inc;
  bits<2> ThreadOverride;
  bits<1> U0;
  bits<1> U1;
  bits<1> PK;
  let tt_opr{8-6} = Z0Inc;
  let tt_opr{11-9} = W0Inc;
  let tt_opr{14-12} = Z1Inc;
  let tt_opr{17-15} = W1Inc;
  let tt_opr{19-18} = ThreadOverride;
  let tt_opr{21} = U0;
  let tt_opr{22} = U1;
  let tt_opr{23} = PK;
}

def TT_ADDRCRZW : TTInst<0x56, (outs),
    (ins uimm1:$Z0, uimm1:$W0, uimm1:$Z1, uimm1:$W1,
         uimm3:$Z0Inc, uimm3:$W0Inc, uimm3:$Z1Inc, uimm3:$W1Inc,
         uimm2:$ThreadOverride, uimm1:$U0, uimm1:$U1, uimm1:$PK),
    "tt.addrcrzw",
    "$Z0, $W0, $Z1, $W1, $Z0Inc, $W0Inc, $Z1Inc, $W1Inc, $ThreadOverride, $U0, $U1, $PK"> {
  bits<1> Z0;
  bits<1> W0;
  bits<1> Z1;
  bits<1> W1;
  bits<3> Z0Inc;
  bits<3> W0Inc;
  bits<3> Z1Inc;
  bits<3> W1Inc;
  bits<2> ThreadOverride;
  bits<1> U0;
  bits<1> U1;
  bits<1> PK;
  let tt_opr{0} = Z0;
  let tt_opr{1} = W0;
  let tt_opr{2} = Z1;
  let tt_opr{3} = W1;
  let tt_opr{8-6} = Z0Inc;
  let tt_opr{11-9} = W0Inc;
  let tt_opr{14-12} = Z1Inc;
  let tt_opr{17-15} = W1Inc;
  let tt_opr{19-18} = ThreadOverride;
  let tt_opr{21} = U0;
  let tt_opr{22} = U1;
  let tt_opr{23} = PK;
}

def TT_SETDVALID : TTInst<0x57, (outs),
    (ins uimm1:$FlipSrcA, uimm1:$FlipSrcB),
    "tt.setdvalid", "$FlipSrcA, $FlipSrcB"> {
  bits<1> FlipSrcA;
  bits<1> FlipSrcB;
  let tt_opr{0} = FlipSrcA;
  let tt_opr{1} = FlipSrcB;
}

def TT_SETADCXX : TTInst<0x5E, (outs),
    (ins uimm10:$X0Val, uimm10:$X1Val, uimm1:$U0, uimm1:$U1, uimm1:$PK),
    "tt.setadcxx", "$X0Val, $X1Val, $U0, $U1, $PK"> {
  bits<10> X0Val;
  bits<10> X1Val;
  bits<1> U0;
  bits<1> U1;
  bits<1> PK;
  let tt_opr{9-0} = X0Val;
  let tt_opr{19-10} = X1Val;
  let tt_opr{21} = U0;
  let tt_opr{22} = U1;
  let tt_opr{23} = PK;
}

//===----------------------------------------------------------------------===//
// Scalar Unit - DMA Register Arithmetic Instructions
// All share: LeftReg[5:0], Right[11:6], ResultReg[17:12], ImmMode[23]
//===----------------------------------------------------------------------===//

// Register variants (ImmMode=0): Right is a register index
// Immediate variants (ImmMode=1): Right is an immediate value

def TT_ADDDMAREG : TTInst<0x58, (outs),
    (ins uimm6:$LeftReg, uimm6:$Right, uimm6:$ResultReg),
    "tt.adddmareg", "$LeftReg, $Right, $ResultReg"> {
  bits<6> LeftReg;
  bits<6> Right;
  bits<6> ResultReg;
  let tt_opr{5-0} = LeftReg;
  let tt_opr{11-6} = Right;
  let tt_opr{17-12} = ResultReg;
  // ImmMode[23] = 0
}

def TT_ADDDMAREGi : TTInst<0x58, (outs),
    (ins uimm6:$LeftReg, uimm6:$Imm, uimm6:$ResultReg),
    "tt.adddmaregi", "$LeftReg, $Imm, $ResultReg"> {
  bits<6> LeftReg;
  bits<6> Imm;
  bits<6> ResultReg;
  let tt_opr{5-0} = LeftReg;
  let tt_opr{11-6} = Imm;
  let tt_opr{17-12} = ResultReg;
  let tt_opr{23} = 1; // ImmMode
}

def TT_SUBDMAREG : TTInst<0x59, (outs),
    (ins uimm6:$LeftReg, uimm6:$Right, uimm6:$ResultReg),
    "tt.subdmareg", "$LeftReg, $Right, $ResultReg"> {
  bits<6> LeftReg;
  bits<6> Right;
  bits<6> ResultReg;
  let tt_opr{5-0} = LeftReg;
  let tt_opr{11-6} = Right;
  let tt_opr{17-12} = ResultReg;
}

def TT_SUBDMAREGi : TTInst<0x59, (outs),
    (ins uimm6:$LeftReg, uimm6:$Imm, uimm6:$ResultReg),
    "tt.subdmaregi", "$LeftReg, $Imm, $ResultReg"> {
  bits<6> LeftReg;
  bits<6> Imm;
  bits<6> ResultReg;
  let tt_opr{5-0} = LeftReg;
  let tt_opr{11-6} = Imm;
  let tt_opr{17-12} = ResultReg;
  let tt_opr{23} = 1;
}

def TT_MULDMAREG : TTInst<0x5A, (outs),
    (ins uimm6:$LeftReg, uimm6:$Right, uimm6:$ResultReg),
    "tt.muldmareg", "$LeftReg, $Right, $ResultReg"> {
  bits<6> LeftReg;
  bits<6> Right;
  bits<6> ResultReg;
  let tt_opr{5-0} = LeftReg;
  let tt_opr{11-6} = Right;
  let tt_opr{17-12} = ResultReg;
}

def TT_MULDMAREGi : TTInst<0x5A, (outs),
    (ins uimm6:$LeftReg, uimm6:$Imm, uimm6:$ResultReg),
    "tt.muldmaregi", "$LeftReg, $Imm, $ResultReg"> {
  bits<6> LeftReg;
  bits<6> Imm;
  bits<6> ResultReg;
  let tt_opr{5-0} = LeftReg;
  let tt_opr{11-6} = Imm;
  let tt_opr{17-12} = ResultReg;
  let tt_opr{23} = 1;
}

// BITWOPDMAREG/SHIFTDMAREG/CMPDMAREG have additional Mode[20:18]

def TT_BITWOPDMAREG : TTInst<0x5B, (outs),
    (ins uimm6:$LeftReg, uimm6:$Right, uimm6:$ResultReg, uimm3:$Mode),
    "tt.bitwopdmareg", "$LeftReg, $Right, $ResultReg, $Mode"> {
  bits<6> LeftReg;
  bits<6> Right;
  bits<6> ResultReg;
  bits<3> Mode;
  let tt_opr{5-0} = LeftReg;
  let tt_opr{11-6} = Right;
  let tt_opr{17-12} = ResultReg;
  let tt_opr{20-18} = Mode;
}

def TT_BITWOPDMAREGi : TTInst<0x5B, (outs),
    (ins uimm6:$LeftReg, uimm6:$Imm, uimm6:$ResultReg, uimm3:$Mode),
    "tt.bitwopdmaregi", "$LeftReg, $Imm, $ResultReg, $Mode"> {
  bits<6> LeftReg;
  bits<6> Imm;
  bits<6> ResultReg;
  bits<3> Mode;
  let tt_opr{5-0} = LeftReg;
  let tt_opr{11-6} = Imm;
  let tt_opr{17-12} = ResultReg;
  let tt_opr{20-18} = Mode;
  let tt_opr{23} = 1;
}

def TT_SHIFTDMAREG : TTInst<0x5C, (outs),
    (ins uimm6:$LeftReg, uimm6:$Right, uimm6:$ResultReg, uimm3:$Mode),
    "tt.shiftdmareg", "$LeftReg, $Right, $ResultReg, $Mode"> {
  bits<6> LeftReg;
  bits<6> Right;
  bits<6> ResultReg;
  bits<3> Mode;
  let tt_opr{5-0} = LeftReg;
  let tt_opr{11-6} = Right;
  let tt_opr{17-12} = ResultReg;
  let tt_opr{20-18} = Mode;
}

def TT_SHIFTDMAREGi : TTInst<0x5C, (outs),
    (ins uimm6:$LeftReg, uimm6:$Imm, uimm6:$ResultReg, uimm3:$Mode),
    "tt.shiftdmaregi", "$LeftReg, $Imm, $ResultReg, $Mode"> {
  bits<6> LeftReg;
  bits<6> Imm;
  bits<6> ResultReg;
  bits<3> Mode;
  let tt_opr{5-0} = LeftReg;
  let tt_opr{11-6} = Imm;
  let tt_opr{17-12} = ResultReg;
  let tt_opr{20-18} = Mode;
  let tt_opr{23} = 1;
}

def TT_CMPDMAREG : TTInst<0x5D, (outs),
    (ins uimm6:$LeftReg, uimm6:$Right, uimm6:$ResultReg, uimm3:$Mode),
    "tt.cmpdmareg", "$LeftReg, $Right, $ResultReg, $Mode"> {
  bits<6> LeftReg;
  bits<6> Right;
  bits<6> ResultReg;
  bits<3> Mode;
  let tt_opr{5-0} = LeftReg;
  let tt_opr{11-6} = Right;
  let tt_opr{17-12} = ResultReg;
  let tt_opr{20-18} = Mode;
}

def TT_CMPDMAREGi : TTInst<0x5D, (outs),
    (ins uimm6:$LeftReg, uimm6:$Imm, uimm6:$ResultReg, uimm3:$Mode),
    "tt.cmpdmaregi", "$LeftReg, $Imm, $ResultReg, $Mode"> {
  bits<6> LeftReg;
  bits<6> Imm;
  bits<6> ResultReg;
  bits<3> Mode;
  let tt_opr{5-0} = LeftReg;
  let tt_opr{11-6} = Imm;
  let tt_opr{17-12} = ResultReg;
  let tt_opr{20-18} = Mode;
  let tt_opr{23} = 1;
}

//===----------------------------------------------------------------------===//
// DMA/Sync Instructions
//===----------------------------------------------------------------------===//

def TT_FLUSHDMA : TTInst<0x46, (outs), (ins uimm4:$ConditionMask),
    "tt.flushdma", "$ConditionMask"> {
  bits<4> ConditionMask;
  let tt_opr{3-0} = ConditionMask;
}

def TT_DMANOP : TTInst<0x60, (outs), (ins), "tt.dmanop", "">;

//===----------------------------------------------------------------------===//
// Atomic Instructions
//===----------------------------------------------------------------------===//

def TT_ATINCGET : TTInst<0x61, (outs),
    (ins uimm6:$AddrReg, uimm6:$InOutReg, uimm2:$Ofs, uimm5:$IntWidth),
    "tt.atincget", "$AddrReg, $InOutReg, $Ofs, $IntWidth"> {
  bits<6> AddrReg;
  bits<6> InOutReg;
  bits<2> Ofs;
  bits<5> IntWidth;
  let tt_opr{5-0} = AddrReg;
  let tt_opr{11-6} = InOutReg;
  let tt_opr{13-12} = Ofs;
  let tt_opr{18-14} = IntWidth;
}

def TT_ATINCGETPTR : TTInst<0x62, (outs),
    (ins uimm6:$AddrReg, uimm6:$ResultReg, uimm2:$Ofs, uimm4:$IntWidth,
         uimm4:$IncrLog2, uimm1:$NoIncr),
    "tt.atincgetptr",
    "$AddrReg, $ResultReg, $Ofs, $IntWidth, $IncrLog2, $NoIncr"> {
  bits<6> AddrReg;
  bits<6> ResultReg;
  bits<2> Ofs;
  bits<4> IntWidth;
  bits<4> IncrLog2;
  bits<1> NoIncr;
  let tt_opr{5-0} = AddrReg;
  let tt_opr{11-6} = ResultReg;
  let tt_opr{13-12} = Ofs;
  let tt_opr{17-14} = IntWidth;
  let tt_opr{21-18} = IncrLog2;
  let tt_opr{22} = NoIncr;
}

def TT_ATSWAP : TTInst<0x63, (outs),
    (ins uimm6:$AddrReg, uimm6:$DataReg, uimm8:$Mask, uimm1:$SingleDataReg),
    "tt.atswap", "$AddrReg, $DataReg, $Mask, $SingleDataReg"> {
  bits<6> AddrReg;
  bits<6> DataReg;
  bits<8> Mask;
  bits<1> SingleDataReg;
  let tt_opr{5-0} = AddrReg;
  let tt_opr{11-6} = DataReg;
  let tt_opr{21-14} = Mask;
  let tt_opr{22} = SingleDataReg;
}

def TT_ATCAS : TTInst<0x64, (outs),
    (ins uimm6:$AddrReg, uimm2:$Ofs, uimm4:$CmpVal, uimm4:$SetVal),
    "tt.atcas", "$AddrReg, $Ofs, $CmpVal, $SetVal"> {
  bits<6> AddrReg;
  bits<2> Ofs;
  bits<4> CmpVal;
  bits<4> SetVal;
  let tt_opr{5-0} = AddrReg;
  let tt_opr{13-12} = Ofs;
  let tt_opr{17-14} = CmpVal;
  let tt_opr{21-18} = SetVal;
}

//===----------------------------------------------------------------------===//
// Indirect Memory Instructions
//===----------------------------------------------------------------------===//

// STOREIND - L1 mode (bit[23]=1)
def TT_STOREIND_L1 : TTInst<0x66, (outs),
    (ins uimm6:$AddrReg, uimm6:$DataReg, uimm2:$OffsetIncrement,
         uimm7:$OffsetHalfReg, uimm2:$MemSize),
    "tt.storeind.l1",
    "$AddrReg, $DataReg, $OffsetIncrement, $OffsetHalfReg, $MemSize"> {
  bits<6> AddrReg;
  bits<6> DataReg;
  bits<2> OffsetIncrement;
  bits<7> OffsetHalfReg;
  bits<2> MemSize;
  let tt_opr{5-0} = AddrReg;
  let tt_opr{11-6} = DataReg;
  let tt_opr{13-12} = OffsetIncrement;
  let tt_opr{20-14} = OffsetHalfReg;
  let tt_opr{22-21} = MemSize;
  let tt_opr{23} = 1; // L1 mode
}

// STOREIND - Src mode (bits[23:22]=0)
def TT_STOREIND_SRC : TTInst<0x66, (outs),
    (ins uimm6:$AddrReg, uimm6:$DataReg, uimm2:$OffsetIncrement,
         uimm7:$OffsetHalfReg, uimm1:$StoreToSrcB),
    "tt.storeind.src",
    "$AddrReg, $DataReg, $OffsetIncrement, $OffsetHalfReg, $StoreToSrcB"> {
  bits<6> AddrReg;
  bits<6> DataReg;
  bits<2> OffsetIncrement;
  bits<7> OffsetHalfReg;
  bits<1> StoreToSrcB;
  let tt_opr{5-0} = AddrReg;
  let tt_opr{11-6} = DataReg;
  let tt_opr{13-12} = OffsetIncrement;
  let tt_opr{20-14} = OffsetHalfReg;
  let tt_opr{21} = StoreToSrcB;
  // bits[23:22] = 0 (Src mode)
}

// STOREIND - MMIO mode (bit[22]=1, bit[23]=0)
def TT_STOREIND_MMIO : TTInst<0x66, (outs),
    (ins uimm6:$AddrReg, uimm6:$DataReg, uimm2:$OffsetIncrement,
         uimm7:$OffsetHalfReg),
    "tt.storeind.mmio",
    "$AddrReg, $DataReg, $OffsetIncrement, $OffsetHalfReg"> {
  bits<6> AddrReg;
  bits<6> DataReg;
  bits<2> OffsetIncrement;
  bits<7> OffsetHalfReg;
  let tt_opr{5-0} = AddrReg;
  let tt_opr{11-6} = DataReg;
  let tt_opr{13-12} = OffsetIncrement;
  let tt_opr{20-14} = OffsetHalfReg;
  let tt_opr{22} = 1; // MMIO discriminator
  // bit[23] = 0
}

def TT_STOREREG : TTInst<0x67, (outs),
    (ins uimm18:$AddrLo, uimm6:$DataReg),
    "tt.storereg", "$AddrLo, $DataReg"> {
  bits<18> AddrLo;
  bits<6> DataReg;
  let tt_opr{17-0} = AddrLo;
  let tt_opr{23-18} = DataReg;
}

def TT_LOADREG : TTInst<0x68, (outs),
    (ins uimm18:$AddrLo, uimm6:$ResultReg),
    "tt.loadreg", "$AddrLo, $ResultReg"> {
  bits<18> AddrLo;
  bits<6> ResultReg;
  let tt_opr{17-0} = AddrLo;
  let tt_opr{23-18} = ResultReg;
}

//===----------------------------------------------------------------------===//
// SFPU Vector Unit Instructions (opcodes 0x70-0x95)
// VD, VC, VB, VA are uimm4 (SFPU register file indices, not RISC-V regs)
//===----------------------------------------------------------------------===//

def TT_SFPLOAD : TTInst<0x70, (outs),
    (ins uimm10:$Imm10, uimm2:$AddrMod, uimm4:$Mod0, uimm4:$VD),
    "tt.sfpload", "$Imm10, $AddrMod, $Mod0, $VD"> {
  bits<10> Imm10;
  bits<2> AddrMod;
  bits<4> Mod0;
  bits<4> VD;
  let tt_opr{9-0} = Imm10;
  let tt_opr{15-14} = AddrMod;
  let tt_opr{19-16} = Mod0;
  let tt_opr{23-20} = VD;
}

def TT_SFPLOADI : TTInst<0x71, (outs),
    (ins uimm16:$Imm16, uimm4:$Mod0, uimm4:$VD),
    "tt.sfploadi", "$Imm16, $Mod0, $VD"> {
  bits<16> Imm16;
  bits<4> Mod0;
  bits<4> VD;
  let tt_opr{15-0} = Imm16;
  let tt_opr{19-16} = Mod0;
  let tt_opr{23-20} = VD;
}

def TT_SFPSTORE : TTInst<0x72, (outs),
    (ins uimm10:$Imm10, uimm2:$AddrMod, uimm4:$Mod0, uimm4:$VD),
    "tt.sfpstore", "$Imm10, $AddrMod, $Mod0, $VD"> {
  bits<10> Imm10;
  bits<2> AddrMod;
  bits<4> Mod0;
  bits<4> VD;
  let tt_opr{9-0} = Imm10;
  let tt_opr{15-14} = AddrMod;
  let tt_opr{19-16} = Mod0;
  let tt_opr{23-20} = VD;
}

def TT_SFPLUT : TTInst<0x73, (outs),
    (ins uimm4:$Mod0, uimm4:$VD),
    "tt.sfplut", "$Mod0, $VD"> {
  bits<4> Mod0;
  bits<4> VD;
  let tt_opr{19-16} = Mod0;
  let tt_opr{23-20} = VD;
}

def TT_SFPMULI : TTInst<0x74, (outs),
    (ins uimm4:$Mod1, uimm4:$VD, uimm16:$Imm16),
    "tt.sfpmuli", "$Mod1, $VD, $Imm16"> {
  bits<4> Mod1;
  bits<4> VD;
  bits<16> Imm16;
  let tt_opr{3-0} = Mod1;
  let tt_opr{7-4} = VD;
  let tt_opr{23-8} = Imm16;
}

def TT_SFPADDI : TTInst<0x75, (outs),
    (ins uimm4:$Mod1, uimm4:$VD, uimm16:$Imm16),
    "tt.sfpaddi", "$Mod1, $VD, $Imm16"> {
  bits<4> Mod1;
  bits<4> VD;
  bits<16> Imm16;
  let tt_opr{3-0} = Mod1;
  let tt_opr{7-4} = VD;
  let tt_opr{23-8} = Imm16;
}

def TT_SFPDIVP2 : TTInst<0x76, (outs),
    (ins uimm4:$Mod1, uimm4:$VD, uimm4:$VC, uimm8:$Imm8),
    "tt.sfpdivp2", "$Mod1, $VD, $VC, $Imm8"> {
  bits<4> Mod1;
  bits<4> VD;
  bits<4> VC;
  bits<8> Imm8;
  let tt_opr{3-0} = Mod1;
  let tt_opr{7-4} = VD;
  let tt_opr{11-8} = VC;
  let tt_opr{19-12} = Imm8;
}

def TT_SFPEXEXP : TTInst<0x77, (outs),
    (ins uimm4:$Mod1, uimm4:$VD, uimm4:$VC),
    "tt.sfpexexp", "$Mod1, $VD, $VC"> {
  bits<4> Mod1;
  bits<4> VD;
  bits<4> VC;
  let tt_opr{3-0} = Mod1;
  let tt_opr{7-4} = VD;
  let tt_opr{11-8} = VC;
}

def TT_SFPEXMAN : TTInst<0x78, (outs),
    (ins uimm4:$Mod1, uimm4:$VD, uimm4:$VC),
    "tt.sfpexman", "$Mod1, $VD, $VC"> {
  bits<4> Mod1;
  bits<4> VD;
  bits<4> VC;
  let tt_opr{3-0} = Mod1;
  let tt_opr{7-4} = VD;
  let tt_opr{11-8} = VC;
}

def TT_SFPIADD : TTInst<0x79, (outs),
    (ins uimm4:$Mod1, uimm4:$VD, uimm4:$VC, simm12:$Imm12),
    "tt.sfpiadd", "$Mod1, $VD, $VC, $Imm12"> {
  bits<4> Mod1;
  bits<4> VD;
  bits<4> VC;
  bits<12> Imm12;
  let tt_opr{3-0} = Mod1;
  let tt_opr{7-4} = VD;
  let tt_opr{11-8} = VC;
  let tt_opr{23-12} = Imm12;
}

def TT_SFPSHFT : TTInst<0x7A, (outs),
    (ins uimm4:$Mod1, uimm4:$VD, uimm4:$VC, simm12:$Imm12),
    "tt.sfpshft", "$Mod1, $VD, $VC, $Imm12"> {
  bits<4> Mod1;
  bits<4> VD;
  bits<4> VC;
  bits<12> Imm12;
  let tt_opr{3-0} = Mod1;
  let tt_opr{7-4} = VD;
  let tt_opr{11-8} = VC;
  let tt_opr{23-12} = Imm12;
}

def TT_SFPSETCC : TTInst<0x7B, (outs),
    (ins uimm4:$Mod1, uimm4:$VD, uimm4:$VC, uimm1:$Imm1),
    "tt.sfpsetcc", "$Mod1, $VD, $VC, $Imm1"> {
  bits<4> Mod1;
  bits<4> VD;
  bits<4> VC;
  bits<1> Imm1;
  let tt_opr{3-0} = Mod1;
  let tt_opr{7-4} = VD;
  let tt_opr{11-8} = VC;
  let tt_opr{12} = Imm1;
}

def TT_SFPMOV : TTInst<0x7C, (outs),
    (ins uimm4:$Mod1, uimm4:$VD, uimm4:$VC),
    "tt.sfpmov", "$Mod1, $VD, $VC"> {
  bits<4> Mod1;
  bits<4> VD;
  bits<4> VC;
  let tt_opr{3-0} = Mod1;
  let tt_opr{7-4} = VD;
  let tt_opr{11-8} = VC;
}

def TT_SFPABS : TTInst<0x7D, (outs),
    (ins uimm4:$Mod1, uimm4:$VD, uimm4:$VC),
    "tt.sfpabs", "$Mod1, $VD, $VC"> {
  bits<4> Mod1;
  bits<4> VD;
  bits<4> VC;
  let tt_opr{3-0} = Mod1;
  let tt_opr{7-4} = VD;
  let tt_opr{11-8} = VC;
}

def TT_SFPAND : TTInst<0x7E, (outs),
    (ins uimm4:$VD, uimm4:$VC),
    "tt.sfpand", "$VD, $VC"> {
  bits<4> VD;
  bits<4> VC;
  let tt_opr{7-4} = VD;
  let tt_opr{11-8} = VC;
}

def TT_SFPOR : TTInst<0x7F, (outs),
    (ins uimm4:$VD, uimm4:$VC),
    "tt.sfpor", "$VD, $VC"> {
  bits<4> VD;
  bits<4> VC;
  let tt_opr{7-4} = VD;
  let tt_opr{11-8} = VC;
}

def TT_SFPNOT : TTInst<0x80, (outs),
    (ins uimm4:$VD, uimm4:$VC),
    "tt.sfpnot", "$VD, $VC"> {
  bits<4> VD;
  bits<4> VC;
  let tt_opr{7-4} = VD;
  let tt_opr{11-8} = VC;
}

def TT_SFPLZ : TTInst<0x81, (outs),
    (ins uimm4:$Mod1, uimm4:$VD, uimm4:$VC),
    "tt.sfplz", "$Mod1, $VD, $VC"> {
  bits<4> Mod1;
  bits<4> VD;
  bits<4> VC;
  let tt_opr{3-0} = Mod1;
  let tt_opr{7-4} = VD;
  let tt_opr{11-8} = VC;
}

def TT_SFPSETEXP : TTInst<0x82, (outs),
    (ins uimm4:$Mod1, uimm4:$VD, uimm4:$VC, uimm8:$Imm8),
    "tt.sfpsetexp", "$Mod1, $VD, $VC, $Imm8"> {
  bits<4> Mod1;
  bits<4> VD;
  bits<4> VC;
  bits<8> Imm8;
  let tt_opr{3-0} = Mod1;
  let tt_opr{7-4} = VD;
  let tt_opr{11-8} = VC;
  let tt_opr{19-12} = Imm8;
}

def TT_SFPSETMAN : TTInst<0x83, (outs),
    (ins uimm4:$Mod1, uimm4:$VD, uimm4:$VC, uimm12:$Imm12),
    "tt.sfpsetman", "$Mod1, $VD, $VC, $Imm12"> {
  bits<4> Mod1;
  bits<4> VD;
  bits<4> VC;
  bits<12> Imm12;
  let tt_opr{3-0} = Mod1;
  let tt_opr{7-4} = VD;
  let tt_opr{11-8} = VC;
  let tt_opr{23-12} = Imm12;
}

def TT_SFPMAD : TTInst<0x84, (outs),
    (ins uimm4:$Mod1, uimm4:$VD, uimm4:$VC, uimm4:$VB, uimm4:$VA),
    "tt.sfpmad", "$Mod1, $VD, $VC, $VB, $VA"> {
  bits<4> Mod1;
  bits<4> VD;
  bits<4> VC;
  bits<4> VB;
  bits<4> VA;
  let tt_opr{3-0} = Mod1;
  let tt_opr{7-4} = VD;
  let tt_opr{11-8} = VC;
  let tt_opr{15-12} = VB;
  let tt_opr{19-16} = VA;
}

def TT_SFPADD : TTInst<0x85, (outs),
    (ins uimm4:$Mod1, uimm4:$VD, uimm4:$VC, uimm4:$VB, uimm4:$VA),
    "tt.sfpadd", "$Mod1, $VD, $VC, $VB, $VA"> {
  bits<4> Mod1;
  bits<4> VD;
  bits<4> VC;
  bits<4> VB;
  bits<4> VA;
  let tt_opr{3-0} = Mod1;
  let tt_opr{7-4} = VD;
  let tt_opr{11-8} = VC;
  let tt_opr{15-12} = VB;
  let tt_opr{19-16} = VA;
}

def TT_SFPMUL : TTInst<0x86, (outs),
    (ins uimm4:$Mod1, uimm4:$VD, uimm4:$VC, uimm4:$VB, uimm4:$VA),
    "tt.sfpmul", "$Mod1, $VD, $VC, $VB, $VA"> {
  bits<4> Mod1;
  bits<4> VD;
  bits<4> VC;
  bits<4> VB;
  bits<4> VA;
  let tt_opr{3-0} = Mod1;
  let tt_opr{7-4} = VD;
  let tt_opr{11-8} = VC;
  let tt_opr{15-12} = VB;
  let tt_opr{19-16} = VA;
}

// SFPPUSHC: Mod1[3:0]=0 fixed, VD[7:4]
def TT_SFPPUSHC : TTInst<0x87, (outs),
    (ins uimm4:$VD),
    "tt.sfppushc", "$VD"> {
  bits<4> VD;
  // Mod1[3:0] = 0 fixed
  let tt_opr{7-4} = VD;
}

def TT_SFPPOPC : TTInst<0x88, (outs),
    (ins uimm4:$Mod1, uimm4:$VD),
    "tt.sfppopc", "$Mod1, $VD"> {
  bits<4> Mod1;
  bits<4> VD;
  let tt_opr{3-0} = Mod1;
  let tt_opr{7-4} = VD;
}

def TT_SFPSETSGN : TTInst<0x89, (outs),
    (ins uimm4:$Mod1, uimm4:$VD, uimm4:$VC, uimm1:$Imm1),
    "tt.sfpsetsgn", "$Mod1, $VD, $VC, $Imm1"> {
  bits<4> Mod1;
  bits<4> VD;
  bits<4> VC;
  bits<1> Imm1;
  let tt_opr{3-0} = Mod1;
  let tt_opr{7-4} = VD;
  let tt_opr{11-8} = VC;
  let tt_opr{12} = Imm1;
}

def TT_SFPENCC : TTInst<0x8A, (outs),
    (ins uimm4:$Mod1, uimm4:$VD, uimm2:$Imm2),
    "tt.sfpencc", "$Mod1, $VD, $Imm2"> {
  bits<4> Mod1;
  bits<4> VD;
  bits<2> Imm2;
  let tt_opr{3-0} = Mod1;
  let tt_opr{7-4} = VD;
  let tt_opr{13-12} = Imm2;
}

def TT_SFPCOMPC : TTInst<0x8B, (outs), (ins uimm4:$VD),
    "tt.sfpcompc", "$VD"> {
  bits<4> VD;
  let tt_opr{7-4} = VD;
}

def TT_SFPTRANSP : TTInst<0x8C, (outs), (ins uimm4:$VD),
    "tt.sfptransp", "$VD"> {
  bits<4> VD;
  let tt_opr{7-4} = VD;
}

def TT_SFPXOR : TTInst<0x8D, (outs),
    (ins uimm4:$VD, uimm4:$VC),
    "tt.sfpxor", "$VD, $VC"> {
  bits<4> VD;
  bits<4> VC;
  let tt_opr{7-4} = VD;
  let tt_opr{11-8} = VC;
}

// SFPSTOCHRND - register variant (bit[3]=0)
def TT_SFPSTOCHRND : TTInst<0x8E, (outs),
    (ins uimm3:$Mod1Lo, uimm4:$VD, uimm4:$VC, uimm1:$StochasticRounding),
    "tt.sfpstochrnd", "$Mod1Lo, $VD, $VC, $StochasticRounding"> {
  bits<3> Mod1Lo;
  bits<4> VD;
  bits<4> VC;
  bits<1> StochasticRounding;
  let tt_opr{2-0} = Mod1Lo;
  // bit[3] = 0 (register variant)
  let tt_opr{7-4} = VD;
  let tt_opr{11-8} = VC;
  let tt_opr{21} = StochasticRounding;
}

// SFPSTOCHRND - immediate variant (bit[3]=1)
def TT_SFPSTOCHRNDi : TTInst<0x8E, (outs),
    (ins uimm3:$Mod1Lo, uimm4:$VD, uimm4:$VC, uimm4:$VB,
         uimm5:$Imm5, uimm1:$StochasticRounding),
    "tt.sfpstochrndi", "$Mod1Lo, $VD, $VC, $VB, $Imm5, $StochasticRounding"> {
  bits<3> Mod1Lo;
  bits<4> VD;
  bits<4> VC;
  bits<4> VB;
  bits<5> Imm5;
  bits<1> StochasticRounding;
  let tt_opr{2-0} = Mod1Lo;
  let tt_opr{3} = 1; // immediate variant discriminator
  let tt_opr{7-4} = VD;
  let tt_opr{11-8} = VC;
  let tt_opr{15-12} = VB;
  let tt_opr{20-16} = Imm5;
  let tt_opr{21} = StochasticRounding;
}

// SFPNOP: bit[7]=0 fixed
def TT_SFPNOP : TTInst<0x8F, (outs), (ins), "tt.sfpnop", "">;

def TT_SFPCAST : TTInst<0x90, (outs),
    (ins uimm4:$Mod1, uimm4:$VD, uimm4:$VC),
    "tt.sfpcast", "$Mod1, $VD, $VC"> {
  bits<4> Mod1;
  bits<4> VD;
  bits<4> VC;
  let tt_opr{3-0} = Mod1;
  let tt_opr{7-4} = VD;
  let tt_opr{11-8} = VC;
}

def TT_SFPCONFIG : TTInst<0x91, (outs),
    (ins uimm4:$Mod1, uimm4:$VD, uimm16:$Imm16),
    "tt.sfpconfig", "$Mod1, $VD, $Imm16"> {
  bits<4> Mod1;
  bits<4> VD;
  bits<16> Imm16;
  let tt_opr{3-0} = Mod1;
  let tt_opr{7-4} = VD;
  let tt_opr{23-8} = Imm16;
}

def TT_SFPSWAP : TTInst<0x92, (outs),
    (ins uimm4:$Mod1, uimm4:$VD, uimm4:$VC),
    "tt.sfpswap", "$Mod1, $VD, $VC"> {
  bits<4> Mod1;
  bits<4> VD;
  bits<4> VC;
  let tt_opr{3-0} = Mod1;
  let tt_opr{7-4} = VD;
  let tt_opr{11-8} = VC;
}

def TT_SFPLOADMACRO : TTInst<0x93, (outs),
    (ins uimm1:$VDHi, uimm9:$Imm9, uimm2:$AddrMod,
         uimm4:$Mod0, uimm2:$VDLo, uimm2:$MacroIndex),
    "tt.sfploadmacro", "$VDHi, $Imm9, $AddrMod, $Mod0, $VDLo, $MacroIndex"> {
  bits<1> VDHi;
  bits<9> Imm9;
  bits<2> AddrMod;
  bits<4> Mod0;
  bits<2> VDLo;
  bits<2> MacroIndex;
  let tt_opr{0} = VDHi;
  let tt_opr{9-1} = Imm9;
  let tt_opr{15-14} = AddrMod;
  let tt_opr{19-16} = Mod0;
  let tt_opr{21-20} = VDLo;
  let tt_opr{23-22} = MacroIndex;
}

// SFPSHFT2 - register form
def TT_SFPSHFT2 : TTInst<0x94, (outs),
    (ins uimm4:$Mod1, uimm4:$VD, uimm4:$VC, uimm4:$VB),
    "tt.sfpshft2", "$Mod1, $VD, $VC, $VB"> {
  bits<4> Mod1;
  bits<4> VD;
  bits<4> VC;
  bits<4> VB;
  let tt_opr{3-0} = Mod1;
  let tt_opr{7-4} = VD;
  let tt_opr{11-8} = VC;
  let tt_opr{15-12} = VB;
}

// SFPSHFT2 - immediate form
def TT_SFPSHFT2i : TTInst<0x94, (outs),
    (ins uimm4:$Mod1, uimm4:$VD, simm12:$Imm12),
    "tt.sfpshft2i", "$Mod1, $VD, $Imm12"> {
  bits<4> Mod1;
  bits<4> VD;
  bits<12> Imm12;
  let tt_opr{3-0} = Mod1;
  let tt_opr{7-4} = VD;
  let tt_opr{23-12} = Imm12;
}

def TT_SFPLUTFP32 : TTInst<0x95, (outs),
    (ins uimm4:$Mod1, uimm4:$VD),
    "tt.sfplutfp32", "$Mod1, $VD"> {
  bits<4> Mod1;
  bits<4> VD;
  let tt_opr{3-0} = Mod1;
  let tt_opr{7-4} = VD;
}

//===----------------------------------------------------------------------===//
// Sync/Semaphore Instructions (opcodes >= 0xA0)
//===----------------------------------------------------------------------===//

def TT_ATGETM : TTInst<0xA0, (outs), (ins uimm16:$Index),
    "tt.atgetm", "$Index"> {
  bits<16> Index;
  let tt_opr{15-0} = Index;
}

def TT_ATRELM : TTInst<0xA1, (outs), (ins uimm16:$Index),
    "tt.atrelm", "$Index"> {
  bits<16> Index;
  let tt_opr{15-0} = Index;
}

def TT_STALLWAIT : TTInst<0xA2, (outs),
    (ins uimm15:$ConditionMask, uimm9:$BlockMask),
    "tt.stallwait", "$ConditionMask, $BlockMask"> {
  bits<15> ConditionMask;
  bits<9> BlockMask;
  let tt_opr{14-0} = ConditionMask;
  let tt_opr{23-15} = BlockMask;
}

def TT_SEMINIT : TTInst<0xA3, (outs),
    (ins uimm8:$SemaphoreMask, uimm4:$NewValue, uimm4:$NewMax),
    "tt.seminit", "$SemaphoreMask, $NewValue, $NewMax"> {
  bits<8> SemaphoreMask;
  bits<4> NewValue;
  bits<4> NewMax;
  let tt_opr{9-2} = SemaphoreMask;
  let tt_opr{19-16} = NewValue;
  let tt_opr{23-20} = NewMax;
}

def TT_SEMPOST : TTInst<0xA4, (outs), (ins uimm8:$SemaphoreMask),
    "tt.sempost", "$SemaphoreMask"> {
  bits<8> SemaphoreMask;
  let tt_opr{9-2} = SemaphoreMask;
}

def TT_SEMGET : TTInst<0xA5, (outs), (ins uimm8:$SemaphoreMask),
    "tt.semget", "$SemaphoreMask"> {
  bits<8> SemaphoreMask;
  let tt_opr{9-2} = SemaphoreMask;
}

def TT_SEMWAIT : TTInst<0xA6, (outs),
    (ins uimm2:$ConditionMask, uimm8:$SemaphoreMask, uimm9:$BlockMask),
    "tt.semwait", "$ConditionMask, $SemaphoreMask, $BlockMask"> {
  bits<2> ConditionMask;
  bits<8> SemaphoreMask;
  bits<9> BlockMask;
  let tt_opr{1-0} = ConditionMask;
  let tt_opr{9-2} = SemaphoreMask;
  let tt_opr{23-15} = BlockMask;
}

//===----------------------------------------------------------------------===//
// Config Read/Write Instructions (opcodes >= 0xB0)
//===----------------------------------------------------------------------===//

def TT_WRCFG : TTInst<0xB0, (outs),
    (ins uimm11:$CfgIndex, uimm1:$Is128Bit, uimm6:$InputReg),
    "tt.wrcfg", "$CfgIndex, $Is128Bit, $InputReg"> {
  bits<11> CfgIndex;
  bits<1> Is128Bit;
  bits<6> InputReg;
  let tt_opr{10-0} = CfgIndex;
  let tt_opr{15} = Is128Bit;
  let tt_opr{21-16} = InputReg;
}

def TT_RDCFG : TTInst<0xB1, (outs),
    (ins uimm11:$CfgIndex, uimm6:$ResultReg),
    "tt.rdcfg", "$CfgIndex, $ResultReg"> {
  bits<11> CfgIndex;
  bits<6> ResultReg;
  let tt_opr{10-0} = CfgIndex;
  let tt_opr{21-16} = ResultReg;
}

def TT_SETC16 : TTInst<0xB2, (outs),
    (ins uimm16:$NewValue, uimm8:$CfgIndex),
    "tt.setc16", "$NewValue, $CfgIndex"> {
  bits<16> NewValue;
  bits<8> CfgIndex;
  let tt_opr{15-0} = NewValue;
  let tt_opr{23-16} = CfgIndex;
}

def TT_RMWCIB0 : TTInst<0xB3, (outs),
    (ins uimm8:$Index4, uimm8:$NewValue, uimm8:$Mask),
    "tt.rmwcib0", "$Index4, $NewValue, $Mask"> {
  bits<8> Index4;
  bits<8> NewValue;
  bits<8> Mask;
  let tt_opr{7-0} = Index4;
  let tt_opr{15-8} = NewValue;
  let tt_opr{23-16} = Mask;
}

def TT_RMWCIB1 : TTInst<0xB4, (outs),
    (ins uimm8:$Index4, uimm8:$NewValue, uimm8:$Mask),
    "tt.rmwcib1", "$Index4, $NewValue, $Mask"> {
  bits<8> Index4;
  bits<8> NewValue;
  bits<8> Mask;
  let tt_opr{7-0} = Index4;
  let tt_opr{15-8} = NewValue;
  let tt_opr{23-16} = Mask;
}

//===----------------------------------------------------------------------===//
// Intrinsic patterns
//===----------------------------------------------------------------------===//

let Predicates = [HasVendorXTTensix, IsRV32] in {
  def : Pat<(int_riscv_tt_insn timm:$imm), (TTINSN ttensix_imm32:$imm)>;
} // Predicates

//===----------------------------------------------------------------------===//
// Instruction aliases for backward compatibility
// Zero-operand forms that map to all-zero operands.
//===----------------------------------------------------------------------===//

let Predicates = [HasVendorXTTensix, IsRV32] in {

//--- Control ---
def : InstAlias<"tt.mop", (TT_MOP 0, 0, 0)>;
def : InstAlias<"tt.mop_cfg", (TT_MOP_CFG 0)>;
def : InstAlias<"tt.replay", (TT_REPLAY 0, 0, 0, 0)>;

//--- Matrix Unit ---
def : InstAlias<"tt.mvmul", (TT_MVMUL 0, 0, 0, 0, 0)>;
def : InstAlias<"tt.elwmul", (TT_ELWMUL 0, 0, 0, 0, 0, 0)>;
def : InstAlias<"tt.elwadd", (TT_ELWADD 0, 0, 0, 0, 0, 0, 0)>;
def : InstAlias<"tt.dotpv", (TT_DOTPV 0, 0, 0, 0)>;
def : InstAlias<"tt.elwsub", (TT_ELWSUB 0, 0, 0, 0, 0, 0, 0)>;
def : InstAlias<"tt.gmpool", (TT_GMPOOL 0, 0, 0, 0, 0)>;
def : InstAlias<"tt.gapool", (TT_GAPOOL 0, 0, 0, 0)>;

//--- Data Movement ---
def : InstAlias<"tt.movd2a", (TT_MOVD2A 0, 0, 0, 0, 0)>;
def : InstAlias<"tt.movdbga2d", (TT_MOVDBGA2D 0, 0, 0, 0, 0)>;
def : InstAlias<"tt.movd2b", (TT_MOVD2B 0, 0, 0, 0, 0)>;
def : InstAlias<"tt.movb2a", (TT_MOVB2A 0, 0, 0, 0)>;
def : InstAlias<"tt.zeroacc", (TT_ZEROACC 0, 0, 0, 0, 0)>;
def : InstAlias<"tt.zerosrc", (TT_ZEROSRC 0, 0, 0, 0, 0)>;
def : InstAlias<"tt.mova2d", (TT_MOVA2D 0, 0, 0, 0, 0)>;
def : InstAlias<"tt.movb2d", (TT_MOVB2D 0, 0, 0, 0, 0, 0, 0)>;
def : InstAlias<"tt.shiftxa", (TT_SHIFTXA 0)>;
def : InstAlias<"tt.shiftxb", (TT_SHIFTXB 0, 0, 0)>;

//--- Unpacker/Misc ---
def : InstAlias<"tt.gatesrcrst", (TT_GATESRCRST 0)>;
def : InstAlias<"tt.cleardvalid", (TT_CLEARDVALID 0, 0, 0, 0)>;
def : InstAlias<"tt.setrwc", (TT_SETRWC 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)>;
def : InstAlias<"tt.incrwc", (TT_INCRWC 0, 0, 0, 0, 0, 0)>;

//--- Packer/Unpacker ---
def : InstAlias<"tt.pacr", (TT_PACR 0, 0, 0, 0, 0, 0, 0)>;
def : InstAlias<"tt.unpacr", (TT_UNPACR 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)>;

//--- Configuration ---
def : InstAlias<"tt.setdmareg", (TT_SETDMAREG_IMM 0, 0)>;
def : InstAlias<"tt.reg2flop", (TT_REG2FLOP_CFG 0, 0, 0)>;
def : InstAlias<"tt.loadind", (TT_LOADIND 0, 0, 0, 0, 0)>;
def : InstAlias<"tt.setadc", (TT_SETADC 0, 0, 0, 0, 0, 0)>;
def : InstAlias<"tt.setadcxy", (TT_SETADCXY 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)>;
def : InstAlias<"tt.setdvalid", (TT_SETDVALID 0, 0)>;

//--- DMA/Sync ---
def : InstAlias<"tt.flushdma", (TT_FLUSHDMA 0)>;

//--- Sync/Semaphore ---
def : InstAlias<"tt.stallwait", (TT_STALLWAIT 0, 0)>;

} // Predicates
