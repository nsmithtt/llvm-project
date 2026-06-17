# Blackhole-only Tensix instructions: gated on the XTTensixBH extension.
#
# RUN: llvm-mc %s -triple=riscv32 -mattr=+experimental-xttensixbh -show-encoding \
# RUN:     | FileCheck -check-prefixes=CHECK-ASM %s
# RUN: llvm-mc %s -triple=riscv32 -mcpu=tt-bh-brisc -show-encoding \
# RUN:     | FileCheck -check-prefixes=CHECK-ASM %s
# Rejected with only the Wormhole Tensix interface:
# RUN: not llvm-mc %s -triple=riscv32 -mattr=+experimental-xttensixwh 2>&1 \
# RUN:     | FileCheck -check-prefix=CHECK-NO-BH %s
# Rejected with no Tensix extension at all:
# RUN: not llvm-mc %s -triple=riscv32 2>&1 \
# RUN:     | FileCheck -check-prefix=CHECK-NO-BH %s

# CHECK-ASM: tt.sfple 1, 2, 3
# CHECK-ASM: encoding: [0x86,0x0c,0x00,0x58]
# CHECK-NO-BH: error: instruction requires the following: 'XTTensixBH' (Tenstorrent Tensix accelerator interface, Blackhole)
tt.sfple 1, 2, 3

# CHECK-ASM: tt.sfpgt 4, 5, 6
# CHECK-ASM: encoding: [0x52,0x19,0x00,0x5c]
# CHECK-NO-BH: error: instruction requires the following: 'XTTensixBH' (Tenstorrent Tensix accelerator interface, Blackhole)
tt.sfpgt 4, 5, 6

# Zero-operand aliases.
# CHECK-ASM: tt.sfple
# CHECK-ASM: encoding: [0x02,0x00,0x00,0x58]
tt.sfple

# CHECK-ASM: tt.sfpgt
# CHECK-ASM: encoding: [0x02,0x00,0x00,0x5c]
tt.sfpgt
