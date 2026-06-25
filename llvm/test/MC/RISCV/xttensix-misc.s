# RUN: llvm-mc %s -triple=riscv32 -mattr=+experimental-xttensixwh -show-encoding \
# RUN:     | FileCheck -check-prefixes=CHECK-ASM %s
# RUN: llvm-mc -filetype=obj -triple=riscv32 -mattr=+experimental-xttensixwh %s \
# RUN:     | llvm-objdump -d --mattr=+experimental-xttensixwh - \
# RUN:     | FileCheck -check-prefixes=CHECK-DIS %s

# A representative sample across the instruction families (matrix, atomic, SFPU).
# Per-instruction coverage for each family lands with the family's own test file.

# CHECK-ASM: tt.mvmul 1023, 3, 1, 0, 1
# CHECK-ASM-SAME: encoding: [0xfc,0x0f,0x26,0x9a]
# CHECK-DIS: 9a260ffc{{.*}}tt.mvmul{{.*}}0x3ff, 0x3, 0x1, 0x0, 0x1
tt.mvmul 0x3ff, 3, 1, 0, 1

# CHECK-ASM: tt.atcas 63, 3, 15, 15
# CHECK-ASM-SAME: encoding: [0xfd,0xc0,0xff,0x90]
# CHECK-DIS: 90ffc0fd{{.*}}tt.atcas{{.*}}0x3f, 0x3, 0xf, 0xf
tt.atcas 0x3f, 3, 15, 15

# CHECK-ASM: tt.sfpload 1023, 3, 15, 15
# CHECK-ASM-SAME: encoding: [0xfd,0x0f,0xff,0xc3]
# CHECK-DIS: c3ff0ffd{{.*}}tt.sfpload{{.*}}0x3ff, 0x3, 0xf, 0xf
tt.sfpload 0x3ff, 3, 15, 15

# CHECK-ASM: tt.sfpmad 1, 2, 3, 4, 5
# CHECK-ASM-SAME: encoding: [0x86,0x0c,0x15,0x10]
# CHECK-DIS: 10150c86{{.*}}tt.sfpmad{{.*}}0x1, 0x2, 0x3, 0x4, 0x5
tt.sfpmad 1, 2, 3, 4, 5
