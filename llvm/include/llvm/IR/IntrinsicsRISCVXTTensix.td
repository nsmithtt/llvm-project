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

class TTI11 : Intrinsic<[],
    !listsplat(llvm_i32_ty, 11),
    !listconcat([IntrHasSideEffects, IntrWriteMem, IntrInaccessibleMemOnly],
                !foreach(idx, !range(11), ImmArg<ArgIndex<idx>>))>;

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


class TTI14 : Intrinsic<[],
    !listsplat(llvm_i32_ty, 14),
    !listconcat([IntrHasSideEffects, IntrWriteMem, IntrInaccessibleMemOnly],
                !foreach(idx, !range(14), ImmArg<ArgIndex<idx>>))>;

//===----------------------------------------------------------------------===//
// Generic raw-immediate intrinsic (retained as fallback)
//===----------------------------------------------------------------------===//

// Tensix accelerator instruction intrinsic.
// Writes a 32-bit immediate to the Tensix instruction buffer.
// The immediate must be < 0xC0000000 to ensure proper encoding.
// Uses IntrInaccessibleMemOnly because it writes to memory-mapped hardware
// (INSTRN_BUF_BASE) that isn't part of LLVM's addressable memory model.
def int_riscv_tt_insn : TTI1;

// Runtime-operand path: issue a Tensix instruction whose 32-bit word is computed
// at runtime (e.g. data-staging instructions whose fields hold a data value or a
// computed address). Unlike the named instructions, the word operand is NOT an
// ImmArg. Lowered to a store of the word to the Tensix instruction buffer; shares
// the other tt intrinsics' memory effects so issue order is preserved.
def int_riscv_tt_insn_rt : Intrinsic<[], [llvm_i32_ty],
    [IntrHasSideEffects, IntrWriteMem, IntrInaccessibleMemOnly]>;

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
def int_riscv_tt_elwmul     : TTI7;
def int_riscv_tt_elwadd     : TTI7;
def int_riscv_tt_dotpv      : TTI4;
def int_riscv_tt_elwsub     : TTI7;
def int_riscv_tt_gmpool     : TTI5;
def int_riscv_tt_gapool     : TTI5;

// Data Movement
def int_riscv_tt_movd2a     : TTI5;
def int_riscv_tt_movdbga2d  : TTI5;
def int_riscv_tt_movd2b     : TTI5;
def int_riscv_tt_movb2a     : TTI4;
def int_riscv_tt_zeroacc    : TTI3;
def int_riscv_tt_zerosrc    : TTI5;
def int_riscv_tt_mova2d     : TTI5;
def int_riscv_tt_movb2d     : TTI7;
def int_riscv_tt_trnspsrcb  : TTI0;
def int_riscv_tt_shiftxa    : TTI1;
def int_riscv_tt_shiftxb    : TTI3;
def int_riscv_tt_clrexphist : TTI0;

// Unpacker/Misc Matrix
def int_riscv_tt_gatesrcrst : TTI2;
def int_riscv_tt_cleardvalid : TTI4;
def int_riscv_tt_setrwc     : TTI13;
def int_riscv_tt_incrwc     : TTI6;

// Packer/Unpacker
def int_riscv_tt_xmov           : TTI0;
def int_riscv_tt_pacr           : TTI7;
def int_riscv_tt_unpacr         : TTI14;
def int_riscv_tt_unpacr_ctxinc  : TTI1;
def int_riscv_tt_unpacr_flush   : TTI2;
def int_riscv_tt_unpacr_nop     : TTI2;
def int_riscv_tt_pacr_setreg    : TTI3;

// Configuration
def int_riscv_tt_setdmareg         : TTI2;
def int_riscv_tt_setdmareg_special : TTI5;
def int_riscv_tt_reg2flop          : TTI3;
def int_riscv_tt_reg2flop_adc      : TTI9;
def int_riscv_tt_loadind           : TTI5;
def int_riscv_tt_setadc            : TTI6;
def int_riscv_tt_setadcxy          : TTI11;
def int_riscv_tt_incadcxy          : TTI7;
def int_riscv_tt_addrcrxy          : TTI11;
def int_riscv_tt_setadczw          : TTI11;
def int_riscv_tt_incadczw          : TTI7;
def int_riscv_tt_addrcrzw          : TTI11;
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
// Blackhole-only SFPU compares.
def int_riscv_tt_sfple        : TTI3;
def int_riscv_tt_sfpgt        : TTI3;
def int_riscv_tt_sfpmul24     : TTI5;
def int_riscv_tt_sfparecip    : TTI4;
def int_riscv_tt_cfgshiftmask : TTI6;
// Blackhole PACR (12-field encoding; see TT_PACR_BH).
def int_riscv_tt_pacr_bh      : TTI12;
// Blackhole UNPACR_NOP (9-field encoding; see TT_UNPACR_NOP_BH).
def int_riscv_tt_unpacr_nop_bh : TTI9;
// Blackhole GAPOOL/GMPOOL (3-bit pool_addr_mode; see TT_GAPOOL_BH/TT_GMPOOL_BH).
def int_riscv_tt_gapool_bh    : TTI5;
def int_riscv_tt_gmpool_bh    : TTI5;
def int_riscv_tt_mvmul_bh     : TTI5;
def int_riscv_tt_elwmul_bh    : TTI7;
def int_riscv_tt_elwadd_bh    : TTI7;
def int_riscv_tt_elwsub_bh    : TTI7;
def int_riscv_tt_movd2a_bh    : TTI5;
def int_riscv_tt_movd2b_bh    : TTI5;
def int_riscv_tt_mova2d_bh    : TTI5;
def int_riscv_tt_movb2a_bh    : TTI4;
def int_riscv_tt_sfpload_bh   : TTI4;
def int_riscv_tt_sfpstore_bh  : TTI4;
def int_riscv_tt_sfploadmacro_bh : TTI6;
def int_riscv_tt_sfpstochrnd_bh  : TTI4;
def int_riscv_tt_sfpstochrndi_bh : TTI6;
def int_riscv_tt_movb2d_bh    : TTI5;
def int_riscv_tt_zeroacc_bh   : TTI5;
def int_riscv_tt_sfpiadd      : TTI4;
def int_riscv_tt_sfpshft      : TTI4;
def int_riscv_tt_sfpsetcc     : TTI4;
def int_riscv_tt_sfpmov       : TTI3;
def int_riscv_tt_sfpabs       : TTI3;
def int_riscv_tt_sfpand       : TTI4;
def int_riscv_tt_sfpor        : TTI4;
def int_riscv_tt_sfpnot       : TTI2;
def int_riscv_tt_sfplz        : TTI3;
def int_riscv_tt_sfpsetexp    : TTI4;
def int_riscv_tt_sfpsetman    : TTI4;
def int_riscv_tt_sfpmad       : TTI5;
def int_riscv_tt_sfpadd       : TTI5;
def int_riscv_tt_sfpmul       : TTI5;
def int_riscv_tt_sfppushc     : TTI2;
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
def int_riscv_tt_rmwcib2 : TTI3;
def int_riscv_tt_rmwcib3 : TTI3;

} // TargetPrefix = "riscv"
