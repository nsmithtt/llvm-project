# RUN: llvm-mc %s -triple=riscv32 -mattr=+experimental-xttensixwh -show-encoding \
# RUN:     | FileCheck -check-prefixes=CHECK-ASM %s

# The .ttinsn directive emits a raw 32-bit Tensix instruction word using the
# same left-rotate-by-2 encoding as the ttinsn instruction.

# CHECK-ASM: ttinsn 305419896
# CHECK-ASM-SAME: encoding: [0xe0,0x59,0xd1,0x48]
.ttinsn 0x12345678

# A word with bit 31 set may be written either as an unsigned value or as its
# signed-int32 spelling; both encode identically.
# CHECK-ASM: ttinsn 2952855552
# CHECK-ASM-SAME: encoding: [0x02,0x00,0x04,0xc0]
.ttinsn 0xb0010000

# CHECK-ASM: ttinsn -1342111744
# CHECK-ASM-SAME: encoding: [0x02,0x00,0x04,0xc0]
.ttinsn -1342111744
