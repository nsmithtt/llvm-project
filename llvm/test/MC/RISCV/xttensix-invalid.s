# RUN: not llvm-mc %s -triple=riscv32 -mattr=+experimental-xttensix 2>&1 \
# RUN:     | FileCheck %s

# Test that immediates >= 0xC0000000 are rejected for ttinsn
# This constraint ensures bits[1:0] of the encoded instruction are never 0b11

# CHECK: error: operand must be a valid Tensix immediate (< 0xC0000000)
ttinsn 0xC0000000

# CHECK: error: operand must be a valid Tensix immediate (< 0xC0000000)
ttinsn 0xFFFFFFFF

# CHECK: error: operand must be a valid Tensix immediate (< 0xC0000000)
ttinsn 0xC0000001

# Test out-of-range operands for various instructions

# tt.mop: MaskLo is uimm16, max 65535
# CHECK: error: immediate must be an integer in the range [0, 65535]
tt.mop 65536, 0, 0

# tt.mvmul: DstRow is uimm10, max 1023
# CHECK: error: immediate must be an integer in the range [0, 1023]
tt.mvmul 1024, 0, 0, 0, 0

# tt.sfpload: Imm10 is uimm10, max 1023
# CHECK: error: immediate must be an integer in the range [0, 1023]
tt.sfpload 1024, 0, 0, 0

# tt.setadc: NewValue is uimm18, max 262143
# CHECK: error: immediate must be an integer in the range [0, 262143]
tt.setadc 262144, 0, 0, 0, 0, 0

# tt.stallwait: ConditionMask is uimm15, max 32767
# CHECK: error: immediate must be an integer in the range [0, 32767]
tt.stallwait 32768, 0

# tt.storereg: AddrLo is uimm18, max 262143
# CHECK: error: immediate must be an integer in the range [0, 262143]
tt.storereg 262144, 0

# tt.sfploadi: Imm16 is uimm16, max 65535
# CHECK: error: immediate must be an integer in the range [0, 65535]
tt.sfploadi 65536, 0, 0

# tt.setdmareg: ResultHalfReg is uimm7, max 127
# CHECK: error: immediate must be an integer in the range [0, 127]
tt.setdmareg 128, 0

# tt.wrcfg: CfgIndex is uimm11, max 2047
# CHECK: error: immediate must be an integer in the range [0, 2047]
tt.wrcfg 2048, 0, 0

# tt.adddmareg: LeftReg is uimm6, max 63
# CHECK: error: immediate must be an integer in the range [0, 63]
tt.adddmareg 64, 0, 0
