# RUN: not llvm-mc -triple=riscv32 -mattr=+experimental-xttensixwh %s 2>&1 \
# RUN:     | FileCheck -check-prefixes=CHECK %s
# RUN: not llvm-mc -triple=riscv32 %s 2>&1 \
# RUN:     | FileCheck -check-prefixes=CHECK-NOEXT %s

# Operand out of range.
tt.mop 0x10000, 5, 1
# CHECK: :[[@LINE-1]]:8: error: immediate must be an integer in the range [0, 65535]

tt.replay 1, 0, 64, 7
# CHECK: :[[@LINE-1]]:17: error: immediate must be an integer in the range [0, 63]

# .ttinsn word must be < 0xC0000000.
.ttinsn 0xc0000000
# CHECK: :[[@LINE-1]]:9: error: operand must be a valid Tensix immediate (< 0xC0000000)

# The instructions and directive require the XTTensixWH feature.
# CHECK-NOEXT: :[[@LINE+1]]:1: error: instruction requires the following: 'XTTensixWH'
tt.nop

# CHECK-NOEXT: :[[@LINE+1]]:9: error: '.ttinsn' requires 'XTTensixWH'
.ttinsn 0x1
