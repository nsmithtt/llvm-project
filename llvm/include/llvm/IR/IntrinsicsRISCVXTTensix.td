//===- IntrinsicsRISCVXTTensix.td - Tensix intrinsics ------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file defines all of the Tenstorrent Tensix vendor intrinsics for RISC-V.
//
//===----------------------------------------------------------------------===//

let TargetPrefix = "riscv" in {

//===----------------------------------------------------------------------===//
// Arity helper classes for Tensix intrinsics
// All are void-returning with N x i32 immediate args.
// Properties: IntrHasSideEffects, IntrWriteMem, IntrInaccessibleMemOnly
//===----------------------------------------------------------------------===//

class TTI0 : Intrinsic<[], [],
    [IntrHasSideEffects, IntrWriteMem, IntrInaccessibleMemOnly]>;

class TTI1 : Intrinsic<[], [llvm_i32_ty],
    [IntrHasSideEffects, IntrWriteMem, IntrInaccessibleMemOnly,
     ImmArg<ArgIndex<0>>]>;

class TTI2 : Intrinsic<[], [llvm_i32_ty, llvm_i32_ty],
    [IntrHasSideEffects, IntrWriteMem, IntrInaccessibleMemOnly,
     ImmArg<ArgIndex<0>>, ImmArg<ArgIndex<1>>]>;

class TTI3 : Intrinsic<[], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
    [IntrHasSideEffects, IntrWriteMem, IntrInaccessibleMemOnly,
     ImmArg<ArgIndex<0>>, ImmArg<ArgIndex<1>>, ImmArg<ArgIndex<2>>]>;

class TTI4 : Intrinsic<[],
    [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
    [IntrHasSideEffects, IntrWriteMem, IntrInaccessibleMemOnly,
     ImmArg<ArgIndex<0>>, ImmArg<ArgIndex<1>>, ImmArg<ArgIndex<2>>,
     ImmArg<ArgIndex<3>>]>;

class TTI5 : Intrinsic<[],
    [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
    [IntrHasSideEffects, IntrWriteMem, IntrInaccessibleMemOnly,
     ImmArg<ArgIndex<0>>, ImmArg<ArgIndex<1>>, ImmArg<ArgIndex<2>>,
     ImmArg<ArgIndex<3>>, ImmArg<ArgIndex<4>>]>;

class TTI6 : Intrinsic<[],
    [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty,
     llvm_i32_ty],
    [IntrHasSideEffects, IntrWriteMem, IntrInaccessibleMemOnly,
     ImmArg<ArgIndex<0>>, ImmArg<ArgIndex<1>>, ImmArg<ArgIndex<2>>,
     ImmArg<ArgIndex<3>>, ImmArg<ArgIndex<4>>, ImmArg<ArgIndex<5>>]>;

class TTI7 : Intrinsic<[],
    [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty,
     llvm_i32_ty, llvm_i32_ty],
    [IntrHasSideEffects, IntrWriteMem, IntrInaccessibleMemOnly,
     ImmArg<ArgIndex<0>>, ImmArg<ArgIndex<1>>, ImmArg<ArgIndex<2>>,
     ImmArg<ArgIndex<3>>, ImmArg<ArgIndex<4>>, ImmArg<ArgIndex<5>>,
     ImmArg<ArgIndex<6>>]>;

class TTI8 : Intrinsic<[],
    [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty,
     llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
    [IntrHasSideEffects, IntrWriteMem, IntrInaccessibleMemOnly,
     ImmArg<ArgIndex<0>>, ImmArg<ArgIndex<1>>, ImmArg<ArgIndex<2>>,
     ImmArg<ArgIndex<3>>, ImmArg<ArgIndex<4>>, ImmArg<ArgIndex<5>>,
     ImmArg<ArgIndex<6>>, ImmArg<ArgIndex<7>>]>;

class TTI9 : Intrinsic<[],
    [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty,
     llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
    [IntrHasSideEffects, IntrWriteMem, IntrInaccessibleMemOnly,
     ImmArg<ArgIndex<0>>, ImmArg<ArgIndex<1>>, ImmArg<ArgIndex<2>>,
     ImmArg<ArgIndex<3>>, ImmArg<ArgIndex<4>>, ImmArg<ArgIndex<5>>,
     ImmArg<ArgIndex<6>>, ImmArg<ArgIndex<7>>, ImmArg<ArgIndex<8>>]>;

class TTI12 : Intrinsic<[],
    [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty,
     llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty,
     llvm_i32_ty, llvm_i32_ty],
    [IntrHasSideEffects, IntrWriteMem, IntrInaccessibleMemOnly,
     ImmArg<ArgIndex<0>>, ImmArg<ArgIndex<1>>, ImmArg<ArgIndex<2>>,
     ImmArg<ArgIndex<3>>, ImmArg<ArgIndex<4>>, ImmArg<ArgIndex<5>>,
     ImmArg<ArgIndex<6>>, ImmArg<ArgIndex<7>>, ImmArg<ArgIndex<8>>,
     ImmArg<ArgIndex<9>>, ImmArg<ArgIndex<10>>, ImmArg<ArgIndex<11>>]>;

class TTI13 : Intrinsic<[],
    [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty,
     llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty,
     llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
    [IntrHasSideEffects, IntrWriteMem, IntrInaccessibleMemOnly,
     ImmArg<ArgIndex<0>>, ImmArg<ArgIndex<1>>, ImmArg<ArgIndex<2>>,
     ImmArg<ArgIndex<3>>, ImmArg<ArgIndex<4>>, ImmArg<ArgIndex<5>>,
     ImmArg<ArgIndex<6>>, ImmArg<ArgIndex<7>>, ImmArg<ArgIndex<8>>,
     ImmArg<ArgIndex<9>>, ImmArg<ArgIndex<10>>, ImmArg<ArgIndex<11>>,
     ImmArg<ArgIndex<12>>]>;

//===----------------------------------------------------------------------===//
// Generic raw-immediate intrinsic (retained as fallback)
//===----------------------------------------------------------------------===//

// Tensix accelerator instruction intrinsic.
// Writes a 32-bit immediate to the Tensix instruction buffer.
// The immediate must be < 0xC0000000 to ensure proper encoding.
// Uses IntrInaccessibleMemOnly because it writes to memory-mapped hardware
// (INSTRN_BUF_BASE) that isn't part of LLVM's addressable memory model.
def int_riscv_tt_insn : TTI1;

//===----------------------------------------------------------------------===//
// Named intrinsics — one per instruction def
//===----------------------------------------------------------------------===//

// Frontend/Control
def int_riscv_tt_nop        : TTI0;
def int_riscv_tt_mop        : TTI3;
def int_riscv_tt_mop_cfg    : TTI1;
def int_riscv_tt_replay     : TTI4;

// Matrix Unit (FPU)
def int_riscv_tt_mvmul      : TTI5;
def int_riscv_tt_elwmul     : TTI6;
def int_riscv_tt_elwadd     : TTI7;
def int_riscv_tt_dotpv      : TTI4;
def int_riscv_tt_elwsub     : TTI7;
def int_riscv_tt_gmpool     : TTI5;
def int_riscv_tt_gapool     : TTI4;

// Data Movement
def int_riscv_tt_movd2a     : TTI5;
def int_riscv_tt_movdbga2d  : TTI5;
def int_riscv_tt_movd2b     : TTI5;
def int_riscv_tt_movb2a     : TTI4;
def int_riscv_tt_zeroacc    : TTI5;
def int_riscv_tt_zerosrc    : TTI5;
def int_riscv_tt_mova2d     : TTI5;
def int_riscv_tt_movb2d     : TTI7;
def int_riscv_tt_trnspsrcb  : TTI0;
def int_riscv_tt_shiftxa    : TTI1;
def int_riscv_tt_shiftxb    : TTI3;
def int_riscv_tt_clrexphist : TTI0;

// Unpacker/Misc Matrix
def int_riscv_tt_gatesrcrst : TTI1;
def int_riscv_tt_cleardvalid : TTI4;
def int_riscv_tt_setrwc     : TTI13;
def int_riscv_tt_incrwc     : TTI6;

// Packer/Unpacker
def int_riscv_tt_xmov           : TTI0;
def int_riscv_tt_pacr           : TTI7;
def int_riscv_tt_unpacr         : TTI12;
def int_riscv_tt_unpacr_ctxinc  : TTI1;
def int_riscv_tt_unpacr_flush   : TTI2;
def int_riscv_tt_unpacr_nop     : TTI0;
def int_riscv_tt_pacr_setreg    : TTI3;

// Configuration
def int_riscv_tt_setdmareg         : TTI2;
def int_riscv_tt_setdmareg_special : TTI5;
def int_riscv_tt_reg2flop          : TTI3;
def int_riscv_tt_reg2flop_adc      : TTI9;
def int_riscv_tt_loadind           : TTI5;
def int_riscv_tt_setadc            : TTI6;
def int_riscv_tt_setadcxy          : TTI12;
def int_riscv_tt_incadcxy          : TTI8;
def int_riscv_tt_addrcrxy          : TTI12;
def int_riscv_tt_setadczw          : TTI12;
def int_riscv_tt_incadczw          : TTI8;
def int_riscv_tt_addrcrzw          : TTI12;
def int_riscv_tt_setdvalid         : TTI2;
def int_riscv_tt_setadcxx          : TTI5;

// DMA Register Arithmetic
def int_riscv_tt_adddmareg   : TTI3;
def int_riscv_tt_adddmaregi  : TTI3;
def int_riscv_tt_subdmareg   : TTI3;
def int_riscv_tt_subdmaregi  : TTI3;
def int_riscv_tt_muldmareg   : TTI3;
def int_riscv_tt_muldmaregi  : TTI3;
def int_riscv_tt_bitwopdmareg  : TTI4;
def int_riscv_tt_bitwopdmaregi : TTI4;
def int_riscv_tt_shiftdmareg   : TTI4;
def int_riscv_tt_shiftdmaregi  : TTI4;
def int_riscv_tt_cmpdmareg     : TTI4;
def int_riscv_tt_cmpdmaregi    : TTI4;

// DMA/Sync
def int_riscv_tt_flushdma : TTI1;
def int_riscv_tt_dmanop   : TTI0;

// Atomic
def int_riscv_tt_atincget    : TTI4;
def int_riscv_tt_atincgetptr : TTI6;
def int_riscv_tt_atswap      : TTI4;
def int_riscv_tt_atcas       : TTI4;

// Indirect Memory
def int_riscv_tt_storeind_l1   : TTI5;
def int_riscv_tt_storeind_src  : TTI5;
def int_riscv_tt_storeind_mmio : TTI4;
def int_riscv_tt_storereg      : TTI2;
def int_riscv_tt_loadreg       : TTI2;

// SFPU Vector Unit
def int_riscv_tt_sfpload      : TTI4;
def int_riscv_tt_sfploadi     : TTI3;
def int_riscv_tt_sfpstore     : TTI4;
def int_riscv_tt_sfplut       : TTI2;
def int_riscv_tt_sfpmuli      : TTI3;
def int_riscv_tt_sfpaddi      : TTI3;
def int_riscv_tt_sfpdivp2     : TTI4;
def int_riscv_tt_sfpexexp     : TTI3;
def int_riscv_tt_sfpexman     : TTI3;
def int_riscv_tt_sfpiadd      : TTI4;
def int_riscv_tt_sfpshft      : TTI4;
def int_riscv_tt_sfpsetcc     : TTI4;
def int_riscv_tt_sfpmov       : TTI3;
def int_riscv_tt_sfpabs       : TTI3;
def int_riscv_tt_sfpand       : TTI2;
def int_riscv_tt_sfpor        : TTI2;
def int_riscv_tt_sfpnot       : TTI2;
def int_riscv_tt_sfplz        : TTI3;
def int_riscv_tt_sfpsetexp    : TTI4;
def int_riscv_tt_sfpsetman    : TTI4;
def int_riscv_tt_sfpmad       : TTI5;
def int_riscv_tt_sfpadd       : TTI5;
def int_riscv_tt_sfpmul       : TTI5;
def int_riscv_tt_sfppushc     : TTI1;
def int_riscv_tt_sfppopc      : TTI2;
def int_riscv_tt_sfpsetsgn    : TTI4;
def int_riscv_tt_sfpencc      : TTI3;
def int_riscv_tt_sfpcompc     : TTI1;
def int_riscv_tt_sfptransp    : TTI1;
def int_riscv_tt_sfpxor       : TTI2;
def int_riscv_tt_sfpstochrnd  : TTI4;
def int_riscv_tt_sfpstochrndi : TTI6;
def int_riscv_tt_sfpnop       : TTI0;
def int_riscv_tt_sfpcast      : TTI3;
def int_riscv_tt_sfpconfig    : TTI3;
def int_riscv_tt_sfpswap      : TTI3;
def int_riscv_tt_sfploadmacro : TTI6;
def int_riscv_tt_sfpshft2     : TTI4;
def int_riscv_tt_sfpshft2i    : TTI3;
def int_riscv_tt_sfplutfp32   : TTI2;

// Sync/Semaphore
def int_riscv_tt_atgetm    : TTI1;
def int_riscv_tt_atrelm    : TTI1;
def int_riscv_tt_stallwait : TTI2;
def int_riscv_tt_seminit   : TTI3;
def int_riscv_tt_sempost   : TTI1;
def int_riscv_tt_semget    : TTI1;
def int_riscv_tt_semwait   : TTI3;

// Config Read/Write
def int_riscv_tt_wrcfg   : TTI3;
def int_riscv_tt_rdcfg   : TTI2;
def int_riscv_tt_setc16  : TTI2;
def int_riscv_tt_rmwcib0 : TTI3;
def int_riscv_tt_rmwcib1 : TTI3;

} // TargetPrefix = "riscv"
