# RUN: llvm-mc %s -triple=riscv32 -mattr=+experimental-xttensixbh -show-encoding \
# RUN:     | FileCheck -check-prefixes=CHECK-ASM %s
# RUN: llvm-mc -filetype=obj -triple=riscv32 -mattr=+experimental-xttensixbh %s \
# RUN:     | llvm-objdump -d --mattr=+experimental-xttensixbh - \
# RUN:     | FileCheck -check-prefixes=CHECK-DIS %s
# RUN: not llvm-mc -triple=riscv32 -mattr=+experimental-xttensixwh %s 2>&1 \
# RUN:     | FileCheck -check-prefixes=CHECK-WH %s

# On Blackhole the data-movement address mode is 3 bits wide (and MOVB2D's
# instruction mode too), so values that need the extra bit assemble here but are
# rejected on Wormhole. The Blackhole disassembler table must take precedence so
# the wider fields decode correctly.

# CHECK-ASM: tt.movd2a 5, 1, 7, 7, 0
# CHECK-ASM-SAME: encoding: [0x14,0x40,0x3f,0x20]
# CHECK-DIS: 203f4014{{.*}}tt.movd2a{{.*}}0x5, 0x1, 0x7, 0x7, 0x0
# CHECK-WH: :[[@LINE+1]]:1: error: instruction requires the following: 'XTTensixBH'
tt.movd2a 5, 1, 7, 7, 0

# CHECK-ASM: tt.movb2a 63, 1, 5, 63
# CHECK-ASM-SAME: encoding: [0xfc,0x40,0xfd,0x2d]
# CHECK-WH: :[[@LINE+1]]:1: error: instruction requires the following: 'XTTensixBH'
tt.movb2a 0x3f, 1, 5, 0x3f

# CHECK-ASM: tt.movb2d 1023, 7, 5, 63, 1
# CHECK-ASM-SAME: encoding: [0xfc,0xef,0xfd,0x4f]
# CHECK-DIS: 4ffdeffc{{.*}}tt.movb2d{{.*}}0x3ff, 0x7, 0x5, 0x3f, 0x1
# CHECK-WH: :[[@LINE+1]]:1: error: instruction requires the following: 'XTTensixBH'
tt.movb2d 0x3ff, 7, 5, 0x3f, 1
