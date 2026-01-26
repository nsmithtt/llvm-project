# RUN: not llvm-mc %s -triple=riscv32 -mattr=+experimental-xttensix 2>&1 \
# RUN:     | FileCheck %s

# Test that immediates >= 0xC0000000 are rejected
# This constraint ensures bits[1:0] of the encoded instruction are never 0b11

# CHECK: error: operand must be a valid Tensix immediate (< 0xC0000000)
ttinsn 0xC0000000

# CHECK: error: operand must be a valid Tensix immediate (< 0xC0000000)
ttinsn 0xFFFFFFFF

# CHECK: error: operand must be a valid Tensix immediate (< 0xC0000000)
ttinsn 0xC0000001
