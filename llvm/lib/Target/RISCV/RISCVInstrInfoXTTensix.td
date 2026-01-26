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
// Encoding: The 32-bit immediate is rotated left by 2 bits. This places
// bits[31:30] of the original immediate into bits[1:0] of the encoded
// instruction. Since valid Tensix immediates must be < 0xC0000000, the
// resulting bits[1:0] will never be 0b11, allowing use of the compressed
// instruction encoding space (while remaining a 32-bit instruction).
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Operand definitions
//===----------------------------------------------------------------------===//

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
// Instruction definitions
//===----------------------------------------------------------------------===//

// Base .ttinsn instruction - stores a 32-bit immediate to INSTRN_BUF_BASE.
// The encoding is the immediate rotated left by 2 bits.
let Predicates = [HasVendorXTTensix, IsRV32] in {
let hasSideEffects = 1, mayLoad = 0, mayStore = 1, isCodeGenOnly = 0,
    DecoderNamespace = "XTTensix" in {
  def TTINSN : RVInst<(outs), (ins ttensix_imm32:$imm),
                      "ttinsn", "$imm", [], InstFormatOther> {
    bits<32> imm;

    // Encoding: rotate imm left by 2 bits
    // Inst[31:2] = imm[29:0]
    // Inst[1:0]  = imm[31:30]
    let Inst{31-2} = imm{29-0};
    let Inst{1-0} = imm{31-30};
  }
} // hasSideEffects = 1, mayLoad = 0, mayStore = 1, ...
} // Predicates = [HasVendorXTTensix, IsRV32]

//===----------------------------------------------------------------------===//
// Intrinsic patterns
//===----------------------------------------------------------------------===//

let Predicates = [HasVendorXTTensix, IsRV32] in {
  def : Pat<(int_riscv_tt_insn timm:$imm), (TTINSN ttensix_imm32:$imm)>;
} // Predicates = [HasVendorXTTensix, IsRV32]

//===----------------------------------------------------------------------===//
// Instruction aliases (pseudo-instructions)
//===----------------------------------------------------------------------===//

// These provide human-readable mnemonics that expand to .ttinsn with the
// appropriate encoding. Format: (opcode << 24) | operand_fields
//
// Note: InstAlias with immediates >= 0x80000000 are not supported by LLVM
// (they exceed INT32_MAX). Instructions with opcodes >= 0x80 (like SFPU
// instructions with opcodes 0x70-0x99, semaphore ops with 0xA0+) need to be
// accessed directly via .ttinsn.

let Predicates = [HasVendorXTTensix, IsRV32] in {

//--- Control Instructions ---
def : InstAlias<"tt.nop", (TTINSN 0x02000000)>;  // NOP opcode 0x02

//--- Matrix Unit (FPU) Instructions ---
def : InstAlias<"tt.mvmul", (TTINSN 0x26000000)>;      // Matrix-vector multiply
def : InstAlias<"tt.elwmul", (TTINSN 0x27000000)>;     // Element-wise multiply
def : InstAlias<"tt.elwadd", (TTINSN 0x28000000)>;     // Element-wise add
def : InstAlias<"tt.dotpv", (TTINSN 0x29000000)>;      // Dot product vector
def : InstAlias<"tt.elwsub", (TTINSN 0x30000000)>;     // Element-wise subtract
def : InstAlias<"tt.gmpool", (TTINSN 0x33000000)>;     // Global max pool
def : InstAlias<"tt.gapool", (TTINSN 0x34000000)>;     // Global average pool

//--- Data Movement Instructions ---
def : InstAlias<"tt.movd2a", (TTINSN 0x08000000)>;     // Move Dst to SrcA
def : InstAlias<"tt.movd2b", (TTINSN 0x0A000000)>;     // Move Dst to SrcB
def : InstAlias<"tt.movb2a", (TTINSN 0x0B000000)>;     // Move SrcB to SrcA
def : InstAlias<"tt.mova2d", (TTINSN 0x12000000)>;     // Move SrcA to Dst
def : InstAlias<"tt.movb2d", (TTINSN 0x13000000)>;     // Move SrcB to Dst
def : InstAlias<"tt.zeroacc", (TTINSN 0x10000000)>;    // Zero accumulator
def : InstAlias<"tt.zerosrc", (TTINSN 0x11000000)>;    // Zero source registers
def : InstAlias<"tt.trnspsrcb", (TTINSN 0x16000000)>;  // Transpose SrcB
def : InstAlias<"tt.clrexphist", (TTINSN 0x21000000)>; // Clear exponent histogram

//--- Packer/Unpacker Instructions ---
def : InstAlias<"tt.xmov", (TTINSN 0x40000000)>;       // Extended move
def : InstAlias<"tt.pacr", (TTINSN 0x41000000)>;       // Pack row
def : InstAlias<"tt.unpacr", (TTINSN 0x42000000)>;     // Unpack row

//--- Synchronization Instructions ---
// Note: Many sync instructions have opcodes >= 0x80 and need .ttinsn directly
def : InstAlias<"tt.flushdma", (TTINSN 0x46000000)>;   // Flush DMA
def : InstAlias<"tt.dmanop", (TTINSN 0x60000000)>;     // DMA NOP

//--- Miscellaneous Instructions ---
def : InstAlias<"tt.cleardvalid", (TTINSN 0x36000000)>; // Clear data valid
def : InstAlias<"tt.setdvalid", (TTINSN 0x57000000)>;   // Set data valid
def : InstAlias<"tt.setrwc", (TTINSN 0x37000000)>;      // Set read/write counters
def : InstAlias<"tt.incrwc", (TTINSN 0x38000000)>;      // Increment read/write counters

} // Predicates = [HasVendorXTTensix, IsRV32]
