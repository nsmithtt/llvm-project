# RUN: llvm-mc %s -triple=riscv32 -mattr=+experimental-xttensix -show-encoding \
# RUN:     | FileCheck -check-prefixes=CHECK-ASM %s
# RUN: not llvm-mc %s -triple=riscv32 2>&1 \
# RUN:     | FileCheck -check-prefix=CHECK-NO-EXT %s

# Test basic ttinsn instruction encoding
# The encoding is the 32-bit immediate rotated left by 2 bits
# Encoding formula: Inst = (imm{29-0} << 2) | imm{31-30}

# 0x02000000 -> encoded as 0x08000000
# Note: ttinsn with a known immediate prints as the matching alias (tt.nop)
# CHECK-ASM: tt.nop
# CHECK-ASM: encoding: [0x00,0x00,0x00,0x08]
# CHECK-NO-EXT: error: instruction requires the following: 'XTTensix' (Tenstorrent Tensix accelerator interface)
ttinsn 0x02000000

# 0x26000000 -> encoded as 0x98000000
# CHECK-ASM: tt.mvmul
# CHECK-ASM: encoding: [0x00,0x00,0x00,0x98]
ttinsn 0x26000000

# Test instruction aliases

# tt.nop = 0x02000000 -> 0x08000000
# CHECK-ASM: tt.nop
# CHECK-ASM: encoding: [0x00,0x00,0x00,0x08]
tt.nop

# tt.mvmul = 0x26000000 -> 0x98000000
# CHECK-ASM: tt.mvmul
# CHECK-ASM: encoding: [0x00,0x00,0x00,0x98]
tt.mvmul

# tt.elwmul = 0x27000000 -> 0x9C000000
# CHECK-ASM: tt.elwmul
# CHECK-ASM: encoding: [0x00,0x00,0x00,0x9c]
tt.elwmul

# tt.elwadd = 0x28000000 -> 0xA0000000
# CHECK-ASM: tt.elwadd
# CHECK-ASM: encoding: [0x00,0x00,0x00,0xa0]
tt.elwadd

# tt.elwsub = 0x30000000 -> 0xC0000000
# CHECK-ASM: tt.elwsub
# CHECK-ASM: encoding: [0x00,0x00,0x00,0xc0]
tt.elwsub

# Data movement instructions
# tt.movd2a = 0x08000000 -> 0x20000000
# CHECK-ASM: tt.movd2a
# CHECK-ASM: encoding: [0x00,0x00,0x00,0x20]
tt.movd2a

# tt.zeroacc = 0x10000000 -> 0x40000000
# CHECK-ASM: tt.zeroacc
# CHECK-ASM: encoding: [0x00,0x00,0x00,0x40]
tt.zeroacc

# Synchronization instructions
# tt.flushdma = 0x46000000 -> 0x18000001 (bits 31-30 are 01)
# CHECK-ASM: tt.flushdma
# CHECK-ASM: encoding: [0x01,0x00,0x00,0x18]
tt.flushdma

# tt.dmanop = 0x60000000 -> 0x80000001 (bits 31-30 are 01)
# CHECK-ASM: tt.dmanop
# CHECK-ASM: encoding: [0x01,0x00,0x00,0x80]
tt.dmanop
