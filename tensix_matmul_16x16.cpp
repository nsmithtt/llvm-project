// tensix_matmul_16x16.cpp — 16x16 BF16 matrix multiply using Tensix builtins
//
// Demonstrates the complete instruction sequence for computing:
//   C[i][j] = sum_{k=0..15} A[i][k] * B[k][j]
// with BF16 inputs and FP32 accumulation on the Tensix coprocessor.
//
// MVMUL semantics (from MVMUL.md functional model):
//   Dst[8x16] += SrcB[8x16] @ SrcA[16x16]
//   i.e. Dst[i][j] += sum_k SrcB[i][k] * SrcA[k][j]
//
// Therefore, for C = A * B:
//   SrcA  <-- matB (16x16, the RIGHT operand, loaded via Unpacker 0)
//   SrcB  <-- matA (8x16 at a time, the LEFT operand, loaded via Unpacker 1)
//
// Two MVMUL calls produce the full 16x16 result:
//   MVMUL #1: SrcB = matA rows 0-7   -> Dst rows 0-7
//   MVMUL #2: SrcB = matA rows 8-15  -> Dst rows 8-15
//
// Test data:
//   matA (16x16 BF16): row i filled with (i+1)
//   matB (16x16 BF16): column j filled with (j+1)
//   Expected C[i][j] = 16 * (i+1) * (j+1)
//
// Compilation:
//   clang++ --target=riscv32 -march=rv32i_xttensix0p1 -c tensix_matmul_16x16.cpp

// ============================================================================
// 1. Hardware Constants
// ============================================================================

// Memory-mapped Tensix config register base (from tensix.h)
#define TENSIX_CFG_BASE       0xFFEF0000u

// L1 memory base (from dev_mem_map.h)
#define MEM_L1_BASE           0x00000000u

// Config state size in 128-bit units
#define CFG_STATE_SIZE        47u

// Data format codes for ALU_FORMAT_SPEC_REG
#define DFMT_FP32             0u
#define DFMT_BF16             5u

// L1 memory layout for test data
#define L1_ADDR_MAT_A         (MEM_L1_BASE + 0x0000u)   // 512 B: 16x16 BF16
#define L1_ADDR_MAT_B         (MEM_L1_BASE + 0x0200u)   // 512 B: 16x16 BF16
#define L1_ADDR_RESULT        (MEM_L1_BASE + 0x0400u)   // 1024 B: 16x16 FP32

// --- STALLWAIT condition bits (C0-C14) ---
#define COND_UNPACK0_BUSY     (1u << 1)    // C1
#define COND_UNPACK1_BUSY     (1u << 2)    // C2
#define COND_PACK0_BUSY       (1u << 3)    // C3
#define COND_FPU_BUSY         (1u << 7)    // C7
#define COND_RISCV_CFG_PEND   (1u << 13)   // C13

// --- STALLWAIT block bits (B0-B8) ---
#define BLOCK_PACK            (1u << 2)    // B2
#define BLOCK_UNPACK          (1u << 3)    // B3
#define BLOCK_FPU             (1u << 6)    // B6
#define BLOCK_CFG             (1u << 7)    // B7

// --- ZEROACC modes ---
#define ZEROACC_MODE_ALL      3u

// --- Unpacker/packer config register offsets (symbolic) ---
// TODO: Replace with actual values from cfg_defines.h in the tt-metal repo:
// https://github.com/tenstorrent/tt-metal/.../cfg_defines.h
#define CFG_UNP0_TILE_DESC    16u   // Unpacker 0 tile descriptor offset
#define CFG_UNP0_BASE_ADDR    20u   // Unpacker 0 L1 base address
#define CFG_UNP1_TILE_DESC    24u   // Unpacker 1 tile descriptor offset
#define CFG_UNP1_BASE_ADDR    28u   // Unpacker 1 L1 base address

// ============================================================================
// 2. Constant Data Arrays
// ============================================================================

// BF16 encodings for integers 1 through 16.
// BF16 is the upper 16 bits of IEEE 754 FP32.
static const unsigned short bf16_int[16] = {
    0x3F80, 0x4000, 0x4040, 0x4080,   //  1,  2,  3,  4
    0x40A0, 0x40C0, 0x40E0, 0x4100,   //  5,  6,  7,  8
    0x4110, 0x4120, 0x4130, 0x4140,   //  9, 10, 11, 12
    0x4150, 0x4160, 0x4170, 0x4180    // 13, 14, 15, 16
};

// Matrix A (16x16 BF16): row i is filled with BF16 encoding of (i+1).
// Loaded into SrcB (the LEFT operand of MVMUL) via Unpacker 1.
static const unsigned short matA[16][16] = {
    {0x3F80,0x3F80,0x3F80,0x3F80,0x3F80,0x3F80,0x3F80,0x3F80,0x3F80,0x3F80,0x3F80,0x3F80,0x3F80,0x3F80,0x3F80,0x3F80},
    {0x4000,0x4000,0x4000,0x4000,0x4000,0x4000,0x4000,0x4000,0x4000,0x4000,0x4000,0x4000,0x4000,0x4000,0x4000,0x4000},
    {0x4040,0x4040,0x4040,0x4040,0x4040,0x4040,0x4040,0x4040,0x4040,0x4040,0x4040,0x4040,0x4040,0x4040,0x4040,0x4040},
    {0x4080,0x4080,0x4080,0x4080,0x4080,0x4080,0x4080,0x4080,0x4080,0x4080,0x4080,0x4080,0x4080,0x4080,0x4080,0x4080},
    {0x40A0,0x40A0,0x40A0,0x40A0,0x40A0,0x40A0,0x40A0,0x40A0,0x40A0,0x40A0,0x40A0,0x40A0,0x40A0,0x40A0,0x40A0,0x40A0},
    {0x40C0,0x40C0,0x40C0,0x40C0,0x40C0,0x40C0,0x40C0,0x40C0,0x40C0,0x40C0,0x40C0,0x40C0,0x40C0,0x40C0,0x40C0,0x40C0},
    {0x40E0,0x40E0,0x40E0,0x40E0,0x40E0,0x40E0,0x40E0,0x40E0,0x40E0,0x40E0,0x40E0,0x40E0,0x40E0,0x40E0,0x40E0,0x40E0},
    {0x4100,0x4100,0x4100,0x4100,0x4100,0x4100,0x4100,0x4100,0x4100,0x4100,0x4100,0x4100,0x4100,0x4100,0x4100,0x4100},
    {0x4110,0x4110,0x4110,0x4110,0x4110,0x4110,0x4110,0x4110,0x4110,0x4110,0x4110,0x4110,0x4110,0x4110,0x4110,0x4110},
    {0x4120,0x4120,0x4120,0x4120,0x4120,0x4120,0x4120,0x4120,0x4120,0x4120,0x4120,0x4120,0x4120,0x4120,0x4120,0x4120},
    {0x4130,0x4130,0x4130,0x4130,0x4130,0x4130,0x4130,0x4130,0x4130,0x4130,0x4130,0x4130,0x4130,0x4130,0x4130,0x4130},
    {0x4140,0x4140,0x4140,0x4140,0x4140,0x4140,0x4140,0x4140,0x4140,0x4140,0x4140,0x4140,0x4140,0x4140,0x4140,0x4140},
    {0x4150,0x4150,0x4150,0x4150,0x4150,0x4150,0x4150,0x4150,0x4150,0x4150,0x4150,0x4150,0x4150,0x4150,0x4150,0x4150},
    {0x4160,0x4160,0x4160,0x4160,0x4160,0x4160,0x4160,0x4160,0x4160,0x4160,0x4160,0x4160,0x4160,0x4160,0x4160,0x4160},
    {0x4170,0x4170,0x4170,0x4170,0x4170,0x4170,0x4170,0x4170,0x4170,0x4170,0x4170,0x4170,0x4170,0x4170,0x4170,0x4170},
    {0x4180,0x4180,0x4180,0x4180,0x4180,0x4180,0x4180,0x4180,0x4180,0x4180,0x4180,0x4180,0x4180,0x4180,0x4180,0x4180},
};

// Matrix B (16x16 BF16): column j is filled with BF16 encoding of (j+1).
// Loaded into SrcA (the RIGHT operand of MVMUL) via Unpacker 0.
// All rows are identical: {bf16(1), bf16(2), ..., bf16(16)}.
static const unsigned short matB[16][16] = {
    {0x3F80,0x4000,0x4040,0x4080,0x40A0,0x40C0,0x40E0,0x4100,0x4110,0x4120,0x4130,0x4140,0x4150,0x4160,0x4170,0x4180},
    {0x3F80,0x4000,0x4040,0x4080,0x40A0,0x40C0,0x40E0,0x4100,0x4110,0x4120,0x4130,0x4140,0x4150,0x4160,0x4170,0x4180},
    {0x3F80,0x4000,0x4040,0x4080,0x40A0,0x40C0,0x40E0,0x4100,0x4110,0x4120,0x4130,0x4140,0x4150,0x4160,0x4170,0x4180},
    {0x3F80,0x4000,0x4040,0x4080,0x40A0,0x40C0,0x40E0,0x4100,0x4110,0x4120,0x4130,0x4140,0x4150,0x4160,0x4170,0x4180},
    {0x3F80,0x4000,0x4040,0x4080,0x40A0,0x40C0,0x40E0,0x4100,0x4110,0x4120,0x4130,0x4140,0x4150,0x4160,0x4170,0x4180},
    {0x3F80,0x4000,0x4040,0x4080,0x40A0,0x40C0,0x40E0,0x4100,0x4110,0x4120,0x4130,0x4140,0x4150,0x4160,0x4170,0x4180},
    {0x3F80,0x4000,0x4040,0x4080,0x40A0,0x40C0,0x40E0,0x4100,0x4110,0x4120,0x4130,0x4140,0x4150,0x4160,0x4170,0x4180},
    {0x3F80,0x4000,0x4040,0x4080,0x40A0,0x40C0,0x40E0,0x4100,0x4110,0x4120,0x4130,0x4140,0x4150,0x4160,0x4170,0x4180},
    {0x3F80,0x4000,0x4040,0x4080,0x40A0,0x40C0,0x40E0,0x4100,0x4110,0x4120,0x4130,0x4140,0x4150,0x4160,0x4170,0x4180},
    {0x3F80,0x4000,0x4040,0x4080,0x40A0,0x40C0,0x40E0,0x4100,0x4110,0x4120,0x4130,0x4140,0x4150,0x4160,0x4170,0x4180},
    {0x3F80,0x4000,0x4040,0x4080,0x40A0,0x40C0,0x40E0,0x4100,0x4110,0x4120,0x4130,0x4140,0x4150,0x4160,0x4170,0x4180},
    {0x3F80,0x4000,0x4040,0x4080,0x40A0,0x40C0,0x40E0,0x4100,0x4110,0x4120,0x4130,0x4140,0x4150,0x4160,0x4170,0x4180},
    {0x3F80,0x4000,0x4040,0x4080,0x40A0,0x40C0,0x40E0,0x4100,0x4110,0x4120,0x4130,0x4140,0x4150,0x4160,0x4170,0x4180},
    {0x3F80,0x4000,0x4040,0x4080,0x40A0,0x40C0,0x40E0,0x4100,0x4110,0x4120,0x4130,0x4140,0x4150,0x4160,0x4170,0x4180},
    {0x3F80,0x4000,0x4040,0x4080,0x40A0,0x40C0,0x40E0,0x4100,0x4110,0x4120,0x4130,0x4140,0x4150,0x4160,0x4170,0x4180},
    {0x3F80,0x4000,0x4040,0x4080,0x40A0,0x40C0,0x40E0,0x4100,0x4110,0x4120,0x4130,0x4140,0x4150,0x4160,0x4170,0x4180},
};

// ============================================================================
// 3. store_matrices_to_l1 — Copy constant data to L1 via volatile pointers
// ============================================================================

static void store_matrices_to_l1() {
    volatile unsigned short *l1_a = (volatile unsigned short *)L1_ADDR_MAT_A;
    volatile unsigned short *l1_b = (volatile unsigned short *)L1_ADDR_MAT_B;

    for (int i = 0; i < 16; i++) {
        for (int j = 0; j < 16; j++) {
            l1_a[i * 16 + j] = matA[i][j];
            l1_b[i * 16 + j] = matB[i][j];
        }
    }
}

// ============================================================================
// 4. configure_hardware — Set up ALU formats, unpackers, and packer
// ============================================================================

static void configure_hardware() {
    volatile unsigned int *cfg = (volatile unsigned int *)TENSIX_CFG_BASE;

    // --- ALU Configuration (Config[0][0..1]) ---

    // Config[0][0]: ALU_FORMAT_SPEC_REG.
    //   The per-source "override" mechanism (SrcA/SrcB/Dstacc_override bits) is
    //   not modeled by ttsim, which always reads the formats from Config[0][1]
    //   (ALU_FORMAT_SPEC_REG0_SrcA / REG1_SrcB / REG2_Dstacc) below. Those are
    //   set identically, so leave the override register clear.
    cfg[0] = 0u;

    // Config[0][1]: ALU format registers + FP32 accumulation enable
    //   DEST_TARGET_REG_CFG_MATH_Offset = 0   bits [11:0]
    //   ALU_FORMAT_SPEC_REG0_SrcA = BF16(5)   bits [20:17]
    //   ALU_FORMAT_SPEC_REG1_SrcB = BF16(5)   bits [24:21]
    //   ALU_FORMAT_SPEC_REG2_Dstacc = FP32(0) bits [28:25]
    //   ALU_ACC_CTRL_Fp32_enabled = 1          bit  [29]
    cfg[1] = (DFMT_BF16 << 17) | (DFMT_BF16 << 21)
           | (DFMT_FP32 << 25) | (1u << 29);

    // --- Destination Configuration ---

    // Config[0][6]: DEST_REGW_BASE_Base = 0 (start writing at Dst row 0)
    cfg[6] = 0;

    // --- Unpacker Configuration ---
    // Unpacker 0 (SrcA) loads matB from L1.
    // Unpacker 1 (SrcB) loads matA from L1.
    //
    // TileDescriptor fields (per unpacker):
    //   InDataFormat = BF16(5), IsUncompressed = 1
    //   XDim = 16, YDim = 16, ZDim = 1, WDim = 1, DigestSize = 0
    //
    // Base address = (L1_byte_addr / 16) - 1
    //
    // TODO: The following offsets are symbolic placeholders. Replace with
    // actual Field_ADDR32 values from cfg_defines.h in tt-metal.

    // Unpacker 0 tile descriptor: BF16 input, 16x16 uncompressed tile
    cfg[CFG_UNP0_TILE_DESC] = (DFMT_BF16 << 0) | (1u << 4) | (16u << 8) | (16u << 16);
    // Unpacker 0 base address: points to matB in L1
    cfg[CFG_UNP0_BASE_ADDR] = (L1_ADDR_MAT_B / 16u) - 1u;

    // Unpacker 1 tile descriptor: BF16 input, 16x16 uncompressed tile
    cfg[CFG_UNP1_TILE_DESC] = (DFMT_BF16 << 0) | (1u << 4) | (16u << 8) | (16u << 16);
    // Unpacker 1 base address: points to matA in L1
    cfg[CFG_UNP1_BASE_ADDR] = (L1_ADDR_MAT_A / 16u) - 1u;

    // --- Packer Configuration ---

    // Config[0][14]: PCK_DEST_RD_CTRL_Read_32b_data = 1 (read FP32 from Dst)
    cfg[14] = 1u;
}

// ============================================================================
// 5. matmul_16x16 — Core Tensix builtin sequence for 16x16 matrix multiply
// ============================================================================
//
// MVMUL does: Dst[8x16] += SrcB[8x16] @ SrcA[16x16]
//
// For a full 16x16 result we issue two MVMULs:
//   #1: rows 0-7  of matA in SrcB, full matB in SrcA  -> Dst rows 0-7
//   #2: rows 8-15 of matA in SrcB, full matB in SrcA  -> Dst rows 8-15
//
// Bank management via FlipSrc bits:
//   UNPACR FlipSrc=1  : hands bank to Matrix Unit, flips unpacker to other bank
//   MVMUL  FlipSrcB=1 : returns SrcB bank to unpackers for reload
//   MVMUL  FlipSrcA=1 : returns SrcA bank to unpackers (final cleanup)

static void matmul_16x16() {
    // ---- Phase 1: Wait for any pending RISCV config writes to propagate ----
    __builtin_riscv_tt_stallwait(
        COND_RISCV_CFG_PEND,                              // condition: C13
        BLOCK_UNPACK | BLOCK_FPU | BLOCK_PACK | BLOCK_CFG // block: B3|B6|B2|B7
    );

    // ---- Phase 2: Reset all RWC counters to 0, reset fidelity phase ----
    // setrwc(SrcA, SrcB, Dst, Fidelity,
    //        SrcAVal, SrcBVal, DstVal,
    //        SrcACr, SrcBCr, DstCr, DstCtoCr,
    //        FlipSrcA, FlipSrcB)
    __builtin_riscv_tt_setrwc(
        1, 1, 1, 1,   // set SrcA, SrcB, Dst counters; reset Fidelity
        0, 0, 0,       // all counter values = 0
        0, 0, 0, 0,    // no carry resets
        0, 0            // no flips
    );

    // ---- Phase 3: Zero all of Dst (FP32 mode) ----
    // zeroacc(Imm10, AddrMod, ClearMode).  ClearMode is the 3-bit clear_mode
    // field [21:19]; 7 == old (Mode=ALL=3 in [20:19]) | (UseDst32b=1 in [21]).
    __builtin_riscv_tt_zeroacc(
        0,               // Imm10 (unused for clear-all)
        0,               // AddrMod
        7                // ClearMode = clear all of Dst, FP32 destination
    );
    // Wait for FPU to finish zeroing
    __builtin_riscv_tt_stallwait(COND_FPU_BUSY, BLOCK_FPU);

    // ---- Phase 4: Load matB (16x16) into SrcA via Unpacker 0 ----
    // setadc(NewValue, XYZW, Channel, U0, U1, PK)
    //   XYZW: 0=X, 1=Y, 2=Z, 3=W
    __builtin_riscv_tt_setadc(0, 0, 0, 1, 0, 0);   // Ch0.X = 0, Unpacker 0
    __builtin_riscv_tt_setadc(0, 1, 0, 1, 0, 0);   // Ch0.Y = 0, Unpacker 0

    // setadcxx(X0Val, X1Val, U0, U1, PK)
    //   X0Val = Ch0.X start, X1Val = Ch1.X (datum count - 1)
    __builtin_riscv_tt_setadcxx(0, 255, 1, 0, 0);   // 256 datums (16x16), Unp0

    // unpacr(Last, RowSearch, UseCtxCtr, AllZero, RarebEn, FlipSrc, MultiCtx,
    //        CtxADC, CtxNum, Ch0ZInc, Ch0YInc, Ch1ZInc, Ch1YInc, WhichUnpacker)
    // (Last and RarebEn are new operands; both 0 here, preserving the encoding.)
    __builtin_riscv_tt_unpacr(
        0,           // Last
        0, 0, 0,
        0,           // RarebEn
        1,           // FlipSrc = 1: hand bank to Matrix Unit after unpack
        0, 0, 0,
        0, 0, 0, 0,
        0            // WhichUnpacker = 0 (Unpacker 0 -> SrcA)
    );
    // Wait for Unpacker 0 to finish
    __builtin_riscv_tt_stallwait(COND_UNPACK0_BUSY, BLOCK_UNPACK);

    // ---- Phase 5: Load matA rows 0-7 into SrcB via Unpacker 1 ----
    __builtin_riscv_tt_setadc(0, 0, 0, 0, 1, 0);   // Ch0.X = 0, Unpacker 1
    __builtin_riscv_tt_setadc(0, 1, 0, 0, 1, 0);   // Ch0.Y = 0, Unpacker 1
    __builtin_riscv_tt_setadcxx(0, 127, 0, 1, 0);   // 128 datums (8x16), Unp1

    __builtin_riscv_tt_unpacr(
        0,           // Last
        0, 0, 0,
        0,           // RarebEn
        1,           // FlipSrc = 1
        0, 0, 0,
        0, 0, 0, 0,
        1            // WhichUnpacker = 1 (Unpacker 1 -> SrcB)
    );
    // Wait for Unpacker 1 to finish
    __builtin_riscv_tt_stallwait(COND_UNPACK1_BUSY, BLOCK_UNPACK);

    // ---- Phase 6: First MVMUL — Dst rows 0-7 ----
    // Reset SrcA, SrcB, Dst RWC counters (not fidelity)
    __builtin_riscv_tt_setrwc(1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

    // mvmul(DstRow, AddrMod, BroadcastSrcBRow, FlipSrcA, FlipSrcB)
    __builtin_riscv_tt_mvmul(
        0,   // DstRow = 0 (write to Dst rows 0-7)
        0,   // AddrMod
        0,   // BroadcastSrcBRow = 0 (use all 8 rows)
        0,   // FlipSrcA = 0 (keep SrcA for second MVMUL)
        1    // FlipSrcB = 1 (release SrcB bank for reload)
    );
    // Wait for FPU to finish
    __builtin_riscv_tt_stallwait(COND_FPU_BUSY, BLOCK_FPU);

    // ---- Phase 7: Load matA rows 8-15 into SrcB via Unpacker 1 ----
    __builtin_riscv_tt_setadc(0, 0, 0, 0, 1, 0);   // Ch0.X = 0, Unpacker 1
    __builtin_riscv_tt_setadc(8, 1, 0, 0, 1, 0);   // Ch0.Y = 8 (skip rows 0-7), Unp1
    __builtin_riscv_tt_setadcxx(0, 127, 0, 1, 0);   // 128 datums (8x16), Unp1

    __builtin_riscv_tt_unpacr(
        0,           // Last
        0, 0, 0,
        0,           // RarebEn
        1,           // FlipSrc = 1
        0, 0, 0,
        0, 0, 0, 0,
        1            // WhichUnpacker = 1
    );
    // Wait for Unpacker 1 to finish
    __builtin_riscv_tt_stallwait(COND_UNPACK1_BUSY, BLOCK_UNPACK);

    // ---- Phase 8: Second MVMUL — Dst rows 8-15 ----
    // Reset only SrcB counter (SrcA stays, Dst advances to row 8)
    __builtin_riscv_tt_setrwc(0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

    __builtin_riscv_tt_mvmul(
        8,   // DstRow = 8 (write to Dst rows 8-15)
        0,   // AddrMod
        0,   // BroadcastSrcBRow = 0
        1,   // FlipSrcA = 1 (release SrcA bank — done with matB)
        1    // FlipSrcB = 1 (release SrcB bank — done with matA)
    );
    // Wait for FPU to finish
    __builtin_riscv_tt_stallwait(COND_FPU_BUSY, BLOCK_FPU);

    // ---- Phase 9: Pack results from Dst to L1 via Packer 0 ----
    // setadcxx for packer: 256 datums (16x16 FP32 values)
    __builtin_riscv_tt_setadcxx(0, 255, 0, 0, 1);   // PK=1

    // pacr(Last, Flush, Concat, OvrdThreadId, PackerMask, ZeroWrite, AddrMod)
    __builtin_riscv_tt_pacr(
        1,   // Last = 1 (final pack operation)
        0,   // Flush
        0,   // Concat
        0,   // OvrdThreadId
        1,   // PackerMask = 1 (enable Packer 0)
        0,   // ZeroWrite = 0
        0    // AddrMod
    );
    // Wait for Packer 0 to finish
    __builtin_riscv_tt_stallwait(COND_PACK0_BUSY, BLOCK_PACK);
}

// ============================================================================
// 6. Reference computation and verification
// ============================================================================

static float bf16_to_float(unsigned short bf16) {
    union { float f; unsigned int u; } conv;
    conv.u = (unsigned int)bf16 << 16;
    return conv.f;
}

static unsigned int float_to_bits(float f) {
    union { float f; unsigned int u; } conv;
    conv.f = f;
    return conv.u;
}

// Compute the reference result in plain C++ (no Tensix builtins).
// C[i][j] = sum_{k=0..15} matA[i][k] * matB[k][j]
//         = sum_{k=0..15} (i+1) * (j+1)
//         = 16 * (i+1) * (j+1)
#if 0
static void compute_reference(unsigned int result[16][16]) {
    for (int i = 0; i < 16; i++) {
        for (int j = 0; j < 16; j++) {
            float sum = 0.0f;
            for (int k = 0; k < 16; k++) {
                float a = bf16_to_float(matA[i][k]);
                float b = bf16_to_float(matB[k][j]);
                sum += a * b;
            }
            result[i][j] = float_to_bits(sum);
        }
    }
}
#endif

// Read back results from L1 and compare to reference.
// Returns the number of mismatches (0 = success).
static int verify_result() {
    volatile unsigned int *l1_result = (volatile unsigned int *)L1_ADDR_RESULT;
    unsigned int expected[16][16];
    // compute_reference(expected);

    int errors = 0;
    for (int i = 0; i < 16; i++) {
        for (int j = 0; j < 16; j++) {
            if (l1_result[i * 16 + j] != expected[i][j])
                errors++;
        }
    }
    return errors;
}

// ============================================================================
// 7. kernel_main — Entry point
// ============================================================================

extern "C" int kernel_main() {
    store_matrices_to_l1();
    configure_hardware();
    matmul_16x16();
    return verify_result();
}
