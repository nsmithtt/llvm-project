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

# CHECK-ASM: tt.sfpmul24 1, 2, 3, 4, 5
# CHECK-ASM: encoding: [0x86,0x0c,0x15,0x60]
# CHECK-NO-BH: error: instruction requires the following: 'XTTensixBH' (Tenstorrent Tensix accelerator interface, Blackhole)
tt.sfpmul24 1, 2, 3, 4, 5

# CHECK-ASM: tt.sfparecip 1, 2, 3, 4
# CHECK-ASM: encoding: [0x86,0x0c,0x01,0x64]
# CHECK-NO-BH: error: instruction requires the following: 'XTTensixBH' (Tenstorrent Tensix accelerator interface, Blackhole)
tt.sfparecip 1, 2, 3, 4

# CHECK-ASM: tt.cfgshiftmask 18, 1, 2, 3, 4, 1
# CHECK-ASM: encoding: [0x4a,0x24,0x06,0xe3]
# CHECK-NO-BH: error: instruction requires the following: 'XTTensixBH' (Tenstorrent Tensix accelerator interface, Blackhole)
tt.cfgshiftmask 18, 1, 2, 3, 4, 1

# Blackhole PACR: the 12-operand form (same mnemonic as the 7-operand Wormhole
# tt.pacr, distinguished by operand count + the XTTensixBH predicate).
# CHECK-ASM: tt.pacr 1, 0, 2, 1, 0, 7, 1, 2, 3, 1, 5, 2
# CHECK-ASM: encoding: [0x65,0x5c,0x5f,0x05]
# CHECK-NO-BH: error: instruction requires the following: 'XTTensixBH' (Tenstorrent Tensix accelerator interface, Blackhole)
tt.pacr 1, 0, 2, 1, 0, 7, 1, 2, 3, 1, 5, 2

# Blackhole UNPACR_NOP: the 9-operand form (same mnemonic as the 2-operand
# Wormhole tt.unpacr_nop, distinguished by operand count + XTTensixBH).
# CHECK-ASM: tt.unpacr_nop 1, 2, 1, 1, 2, 1, 3, 7, 1
# CHECK-ASM: encoding: [0xe5,0xc6,0x1c,0x0e]
# CHECK-NO-BH: error: instruction requires the following: 'XTTensixBH' (Tenstorrent Tensix accelerator interface, Blackhole)
tt.unpacr_nop 1, 2, 1, 1, 2, 1, 3, 7, 1

# Zero-operand aliases.
# CHECK-ASM: tt.sfple
# CHECK-ASM: encoding: [0x02,0x00,0x00,0x58]
tt.sfple

# CHECK-ASM: tt.sfpgt
# CHECK-ASM: encoding: [0x02,0x00,0x00,0x5c]
tt.sfpgt
