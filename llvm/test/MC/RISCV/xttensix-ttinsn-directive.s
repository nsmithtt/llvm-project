# The .ttinsn directive emits a 32-bit Tensix instruction word, identical to the
# `ttinsn` instruction. It exists for source compatibility with kernels that
# inject raw words via a .ttinsn directive (tt-metal/LLK, ttsim test kernels).
#
# RUN: llvm-mc %s -triple=riscv32 -mattr=+experimental-xttensixwh -show-encoding \
# RUN:     | FileCheck -check-prefixes=CHECK-ASM %s
# RUN: not llvm-mc %s -triple=riscv32 2>&1 \
# RUN:     | FileCheck -check-prefix=CHECK-NO-EXT %s

# CHECK-ASM: ttinsn 637534208
# CHECK-ASM: encoding: [0x00,0x00,0x00,0x98]
# CHECK-NO-EXT: error: '.ttinsn' requires 'XTTensixWH'
.ttinsn 0x26000000

# Signed-int32 spelling of a word with bit 31 set (SFP* opcodes), as emitted by
# existing kernels' TT_OP macros.
# CHECK-ASM: ttinsn -1979699190
# CHECK-ASM: encoding: [0x2a,0xc0,0x00,0x28]
.ttinsn -1979699190
