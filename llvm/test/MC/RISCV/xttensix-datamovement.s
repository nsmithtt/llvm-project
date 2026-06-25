# RUN: llvm-mc %s -triple=riscv32 -mattr=+experimental-xttensixwh -show-encoding \
# RUN:     | FileCheck -check-prefixes=CHECK-ASM %s
# RUN: llvm-mc -filetype=obj -triple=riscv32 -mattr=+experimental-xttensixwh %s \
# RUN:     | llvm-objdump -d --mattr=+experimental-xttensixwh - \
# RUN:     | FileCheck -check-prefixes=CHECK-DIS %s

# CHECK-ASM: tt.movd2a 1023, 3, 3, 63, 1
# CHECK-ASM-SAME: encoding: [0xfc,0xcf,0xfe,0x23]
# CHECK-DIS: 23fecffc{{.*}}tt.movd2a{{.*}}0x3ff, 0x3, 0x3, 0x3f, 0x1
tt.movd2a 0x3ff, 3, 3, 0x3f, 1

# CHECK-ASM: tt.movd2b 1, 2, 1, 3, 0
# CHECK-ASM-SAME: encoding: [0x04,0x80,0x1a,0x28]
# CHECK-DIS: 281a8004{{.*}}tt.movd2b{{.*}}0x1, 0x2, 0x1, 0x3, 0x0
tt.movd2b 1, 2, 1, 3, 0

# CHECK-ASM: tt.mova2d 5, 0, 2, 7, 1
# CHECK-ASM-SAME: encoding: [0x14,0x00,0x3c,0x4a]
# CHECK-DIS: 4a3c0014{{.*}}tt.mova2d{{.*}}0x5, 0x0, 0x2, 0x7, 0x1
tt.mova2d 5, 0, 2, 7, 1

# CHECK-ASM: tt.movb2a 63, 1, 2, 63
# CHECK-ASM-SAME: encoding: [0xfc,0x40,0xfc,0x2d]
# CHECK-DIS: 2dfc40fc{{.*}}tt.movb2a{{.*}}0x3f, 0x1, 0x2, 0x3f
tt.movb2a 0x3f, 1, 2, 0x3f

# CHECK-ASM: tt.movb2d 1023, 1, 1, 1, 3, 63, 1
# CHECK-ASM-SAME: encoding: [0xfc,0xcf,0xff,0x4f]
# CHECK-DIS: 4fffcffc{{.*}}tt.movb2d{{.*}}0x3ff, 0x1, 0x1, 0x1, 0x3, 0x3f, 0x1
tt.movb2d 0x3ff, 1, 1, 1, 3, 0x3f, 1
