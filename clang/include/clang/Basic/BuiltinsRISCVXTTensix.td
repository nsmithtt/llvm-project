//==- BuiltinsRISCVXTTensix.td - Tensix Builtin database -------*- C++ -*-==//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file defines the Tenstorrent Tensix-specific builtin function database.
//
//===----------------------------------------------------------------------===//

class RISCVXTTensixBuiltin<string prototype, string features = ""> : TargetBuiltin {
  let Spellings = ["__builtin_riscv_tt_" # NAME];
  let Prototype = prototype;
  let Features = features;
}

//===----------------------------------------------------------------------===//
// Arity helper classes — all void-returning, all args unsigned int
//===----------------------------------------------------------------------===//

class TTB0 : RISCVXTTensixBuiltin<"void()", "experimental-xttensixwh,32bit">;
class TTB1 : RISCVXTTensixBuiltin<"void(unsigned int)", "experimental-xttensixwh,32bit">;
class TTB2 : RISCVXTTensixBuiltin<"void(unsigned int, unsigned int)", "experimental-xttensixwh,32bit">;
class TTB3 : RISCVXTTensixBuiltin<"void(unsigned int, unsigned int, unsigned int)", "experimental-xttensixwh,32bit">;
class TTB4 : RISCVXTTensixBuiltin<"void(unsigned int, unsigned int, unsigned int, unsigned int)", "experimental-xttensixwh,32bit">;
class TTB5 : RISCVXTTensixBuiltin<"void(unsigned int, unsigned int, unsigned int, unsigned int, unsigned int)", "experimental-xttensixwh,32bit">;
class TTB6 : RISCVXTTensixBuiltin<"void(unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int)", "experimental-xttensixwh,32bit">;
class TTB7 : RISCVXTTensixBuiltin<"void(unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int)", "experimental-xttensixwh,32bit">;
class TTB8 : RISCVXTTensixBuiltin<"void(unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int)", "experimental-xttensixwh,32bit">;
class TTB9 : RISCVXTTensixBuiltin<"void(unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int)", "experimental-xttensixwh,32bit">;
class TTB11 : RISCVXTTensixBuiltin<"void(unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int)", "experimental-xttensixwh,32bit">;
class TTB12 : RISCVXTTensixBuiltin<"void(unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int)", "experimental-xttensixwh,32bit">;
class TTB13 : RISCVXTTensixBuiltin<"void(unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int)", "experimental-xttensixwh,32bit">;
class TTB14 : RISCVXTTensixBuiltin<"void(unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int)", "experimental-xttensixwh,32bit">;

// Blackhole-only arity helpers (require the XTTensixBH extension).
class TTB3BH : RISCVXTTensixBuiltin<"void(unsigned int, unsigned int, unsigned int)", "experimental-xttensixbh,32bit">;
class TTB4BH : RISCVXTTensixBuiltin<"void(unsigned int, unsigned int, unsigned int, unsigned int)", "experimental-xttensixbh,32bit">;
class TTB5BH : RISCVXTTensixBuiltin<"void(unsigned int, unsigned int, unsigned int, unsigned int, unsigned int)", "experimental-xttensixbh,32bit">;
class TTB6BH : RISCVXTTensixBuiltin<"void(unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int)", "experimental-xttensixbh,32bit">;
class TTB7BH : RISCVXTTensixBuiltin<"void(unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int)", "experimental-xttensixbh,32bit">;
class TTB9BH : RISCVXTTensixBuiltin<"void(unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int)", "experimental-xttensixbh,32bit">;
class TTB12BH : RISCVXTTensixBuiltin<"void(unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int)", "experimental-xttensixbh,32bit">;

//===----------------------------------------------------------------------===//
// Generic raw-immediate builtin (retained as fallback)
//===----------------------------------------------------------------------===//

// Tensix accelerator instruction builtin.
// Writes a 32-bit immediate to the Tensix instruction buffer.
// The immediate must be < 0xC0000000 to ensure proper encoding.
// This builtin requires a compile-time constant argument.
def insn : TTB1;

// Runtime-word issue (the word operand may be a runtime value).
def insn_rt : TTB1;

//===----------------------------------------------------------------------===//
// Frontend/Control Instructions
//===----------------------------------------------------------------------===//

def nop        : TTB0;
def mop        : TTB3;
def mop_cfg    : TTB1;
def replay     : TTB4;

//===----------------------------------------------------------------------===//
// Matrix Unit (FPU) Instructions
//===----------------------------------------------------------------------===//

def mvmul      : TTB5;
def elwmul     : TTB7;
def elwadd     : TTB7;
def dotpv      : TTB4;
def elwsub     : TTB7;
def gmpool     : TTB5;
def gapool     : TTB5;

//===----------------------------------------------------------------------===//
// Data Movement Instructions
//===----------------------------------------------------------------------===//

def movd2a     : TTB5;
def movdbga2d  : TTB5;
def movd2b     : TTB5;
def movb2a     : TTB4;
def zeroacc    : TTB3;
def zerosrc    : TTB5;
def mova2d     : TTB5;
def movb2d     : TTB7;
def trnspsrcb  : TTB0;
def shiftxa    : TTB1;
def shiftxb    : TTB3;
def clrexphist : TTB0;

//===----------------------------------------------------------------------===//
// Unpacker/Misc Matrix Instructions
//===----------------------------------------------------------------------===//

def gatesrcrst : TTB2;
def cleardvalid : TTB4;
def setrwc     : TTB13;
def incrwc     : TTB6;

//===----------------------------------------------------------------------===//
// Packer/Unpacker Instructions
//===----------------------------------------------------------------------===//

def xmov           : TTB0;
def pacr           : TTB7;
def unpacr         : TTB14;
def unpacr_ctxinc  : TTB1;
def unpacr_flush   : TTB2;
def unpacr_nop     : TTB2;
def pacr_setreg    : TTB3;

//===----------------------------------------------------------------------===//
// Configuration Instructions
//===----------------------------------------------------------------------===//

def setdmareg         : TTB2;
def setdmareg_special : TTB5;
def reg2flop          : TTB3;
def reg2flop_adc      : TTB9;
def loadind           : TTB5;
def setadc            : TTB6;
def setadcxy          : TTB11;
def incadcxy          : TTB7;
def addrcrxy          : TTB11;
def setadczw          : TTB11;
def incadczw          : TTB7;
def addrcrzw          : TTB11;
def setdvalid         : TTB2;
def setadcxx          : TTB5;

//===----------------------------------------------------------------------===//
// DMA Register Arithmetic Instructions
//===----------------------------------------------------------------------===//

def adddmareg   : TTB3;
def adddmaregi  : TTB3;
def subdmareg   : TTB3;
def subdmaregi  : TTB3;
def muldmareg   : TTB3;
def muldmaregi  : TTB3;
def bitwopdmareg  : TTB4;
def bitwopdmaregi : TTB4;
def shiftdmareg   : TTB4;
def shiftdmaregi  : TTB4;
def cmpdmareg     : TTB4;
def cmpdmaregi    : TTB4;

//===----------------------------------------------------------------------===//
// DMA/Sync Instructions
//===----------------------------------------------------------------------===//

def flushdma : TTB1;
def dmanop   : TTB0;

//===----------------------------------------------------------------------===//
// Atomic Instructions
//===----------------------------------------------------------------------===//

def atincget    : TTB4;
def atincgetptr : TTB6;
def atswap      : TTB4;
def atcas       : TTB4;

//===----------------------------------------------------------------------===//
// Indirect Memory Instructions
//===----------------------------------------------------------------------===//

def storeind_l1   : TTB5;
def storeind_src  : TTB5;
def storeind_mmio : TTB4;
def storereg      : TTB2;
def loadreg       : TTB2;

//===----------------------------------------------------------------------===//
// SFPU Vector Unit Instructions
//===----------------------------------------------------------------------===//

def sfpload      : TTB4;
def sfploadi     : TTB3;
def sfpstore     : TTB4;
def sfplut       : TTB2;
def sfpmuli      : TTB3;
def sfpaddi      : TTB3;
def sfpdivp2     : TTB4;
def sfpexexp     : TTB3;
def sfpexman     : TTB3;
// Blackhole-only SFPU compares.
def sfple        : TTB3BH;
def sfpgt        : TTB3BH;
def sfpmul24     : TTB5BH;
def sfparecip    : TTB4BH;
def cfgshiftmask : TTB6BH;
def pacr_bh      : TTB12BH;
def unpacr_nop_bh : TTB9BH;
def gapool_bh     : TTB5BH;
def gmpool_bh     : TTB5BH;
def mvmul_bh      : TTB5BH;
def elwmul_bh     : TTB7BH;
def elwadd_bh     : TTB7BH;
def elwsub_bh     : TTB7BH;
def movd2a_bh     : TTB5BH;
def movd2b_bh     : TTB5BH;
def mova2d_bh     : TTB5BH;
def movb2a_bh     : TTB4BH;
def sfpload_bh    : TTB4BH;
def sfpstore_bh   : TTB4BH;
def sfploadmacro_bh : TTB6BH;
def sfpstochrnd_bh  : TTB4BH;
def sfpstochrndi_bh : TTB6BH;
def movb2d_bh     : TTB5BH;
def zeroacc_bh    : TTB5BH;
def sfpiadd      : TTB4;
def sfpshft      : TTB4;
def sfpsetcc     : TTB4;
def sfpmov       : TTB3;
def sfpabs       : TTB3;
def sfpand       : TTB4;
def sfpor        : TTB4;
def sfpnot       : TTB2;
def sfplz        : TTB3;
def sfpsetexp    : TTB4;
def sfpsetman    : TTB4;
def sfpmad       : TTB5;
def sfpadd       : TTB5;
def sfpmul       : TTB5;
def sfppushc     : TTB2;
def sfppopc      : TTB2;
def sfpsetsgn    : TTB4;
def sfpencc      : TTB3;
def sfpcompc     : TTB1;
def sfptransp    : TTB1;
def sfpxor       : TTB2;
def sfpstochrnd  : TTB4;
def sfpstochrndi : TTB6;
def sfpnop       : TTB0;
def sfpcast      : TTB3;
def sfpconfig    : TTB3;
def sfpswap      : TTB3;
def sfploadmacro : TTB6;
def sfpshft2     : TTB4;
def sfpshft2i    : TTB3;
def sfplutfp32   : TTB2;

//===----------------------------------------------------------------------===//
// Sync/Semaphore Instructions
//===----------------------------------------------------------------------===//

def atgetm    : TTB1;
def atrelm    : TTB1;
def stallwait : TTB2;
def seminit   : TTB3;
def sempost   : TTB1;
def semget    : TTB1;
def semwait   : TTB3;

//===----------------------------------------------------------------------===//
// Config Read/Write Instructions
//===----------------------------------------------------------------------===//

def wrcfg   : TTB3;
def rdcfg   : TTB2;
def setc16  : TTB2;
def rmwcib0 : TTB3;
def rmwcib1 : TTB3;
def rmwcib2 : TTB3;
def rmwcib3 : TTB3;
