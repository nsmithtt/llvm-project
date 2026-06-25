# RUN: llvm-mc %s -triple=riscv32 -mattr=+experimental-xttensixwh -show-encoding \
# RUN:     | FileCheck -check-prefixes=CHECK-ASM %s
# RUN: llvm-mc -filetype=obj -triple=riscv32 -mattr=+experimental-xttensixwh %s \
# RUN:     | llvm-objdump -d --mattr=+experimental-xttensixwh - \
# RUN:     | FileCheck -check-prefixes=CHECK-DIS %s

# CHECK-ASM: tt.nop
# CHECK-ASM-SAME: encoding: [0x00,0x00,0x00,0x08]
# CHECK-DIS: 08000000{{.*}}tt.nop
tt.nop

# CHECK-ASM: tt.mop 4660, 5, 1
# CHECK-ASM-SAME: encoding: [0xd0,0x48,0x14,0x06]
# CHECK-DIS: 061448d0{{.*}}tt.mop{{.*}}0x1234, 0x5, 0x1
tt.mop 0x1234, 5, 1

# CHECK-ASM: tt.mop_cfg 43981
# CHECK-ASM-SAME: encoding: [0x34,0xaf,0x02,0x0c]
# CHECK-DIS: 0c02af34{{.*}}tt.mop_cfg{{.*}}0xabcd
tt.mop_cfg 0xabcd

# CHECK-ASM: tt.replay 1, 0, 3, 7
# CHECK-ASM-SAME: encoding: [0xc4,0x00,0x07,0x10]
# CHECK-DIS: 100700c4{{.*}}tt.replay{{.*}}0x1, 0x0, 0x3, 0x7
tt.replay 1, 0, 3, 7
