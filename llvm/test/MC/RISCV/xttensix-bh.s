# RUN: llvm-mc %s -triple=riscv32 -mattr=+experimental-xttensixbh -show-encoding \
# RUN:     | FileCheck -check-prefixes=CHECK-ASM %s
# RUN: llvm-mc -filetype=obj -triple=riscv32 -mattr=+experimental-xttensixbh %s \
# RUN:     | llvm-objdump -d --mattr=+experimental-xttensixbh - \
# RUN:     | FileCheck -check-prefixes=CHECK-DIS %s

# Blackhole-divergent (XTTensixBH) named Tensix instructions.
# One encode + decode check per instruction (operands set to field-maximum
# values). Encodings cross-checked against the ttsim Tensix ISA spec.

# CHECK-ASM: tt.cfgshiftmask	255, 3, 31, 31, 7, 1
# CHECK-ASM-SAME: encoding: [0xfe,0xff,0xff,0xe3]
# CHECK-DIS: e3fffffe{{.*}}tt.cfgshiftmask{{.*}}0xff, 0x3, 0x1f, 0x1f, 0x7, 0x1
tt.cfgshiftmask 255, 3, 31, 31, 7, 1

# CHECK-ASM: tt.elwadd	1023, 7, 1, 1, 1, 1, 1
# CHECK-ASM-SAME: encoding: [0xfc,0x0f,0xe7,0xa3]
# CHECK-DIS: a3e70ffc{{.*}}tt.elwadd{{.*}}0x3ff, 0x7, 0x1, 0x1, 0x1, 0x1, 0x1
tt.elwadd 1023, 7, 1, 1, 1, 1, 1

# CHECK-ASM: tt.elwmul	1023, 7, 1, 1, 1, 1, 1
# CHECK-ASM-SAME: encoding: [0xfc,0x0f,0xe7,0x9f]
# CHECK-DIS: 9fe70ffc{{.*}}tt.elwmul{{.*}}0x3ff, 0x7, 0x1, 0x1, 0x1, 0x1, 0x1
tt.elwmul 1023, 7, 1, 1, 1, 1, 1

# CHECK-ASM: tt.elwsub	1023, 7, 1, 1, 1, 1, 1
# CHECK-ASM-SAME: encoding: [0xfc,0x0f,0xe7,0xc3]
# CHECK-DIS: c3e70ffc{{.*}}tt.elwsub{{.*}}0x3ff, 0x7, 0x1, 0x1, 0x1, 0x1, 0x1
tt.elwsub 1023, 7, 1, 1, 1, 1, 1

# CHECK-ASM: tt.gapool	1023, 1, 7, 1, 3
# CHECK-ASM-SAME: encoding: [0xfc,0x0f,0x2f,0xd3]
# CHECK-DIS: d32f0ffc{{.*}}tt.gapool{{.*}}0x3ff, 0x1, 0x7, 0x1, 0x3
tt.gapool 1023, 1, 7, 1, 3

# CHECK-ASM: tt.gmpool	1023, 1, 7, 1, 3
# CHECK-ASM-SAME: encoding: [0xfc,0x0f,0x2f,0xcf]
# CHECK-DIS: cf2f0ffc{{.*}}tt.gmpool{{.*}}0x3ff, 0x1, 0x7, 0x1, 0x3
tt.gmpool 1023, 1, 7, 1, 3

# CHECK-ASM: tt.mova2d	1023, 3, 7, 63, 1
# CHECK-ASM-SAME: encoding: [0xfc,0xcf,0xff,0x4b]
# CHECK-DIS: 4bffcffc{{.*}}tt.mova2d{{.*}}0x3ff, 0x3, 0x7, 0x3f, 0x1
tt.mova2d 1023, 3, 7, 63, 1

# CHECK-ASM: tt.movb2a	63, 3, 7, 63
# CHECK-ASM-SAME: encoding: [0xfc,0xc0,0xff,0x2d]
# CHECK-DIS: 2dffc0fc{{.*}}tt.movb2a{{.*}}0x3f, 0x3, 0x7, 0x3f
tt.movb2a 63, 3, 7, 63

# CHECK-ASM: tt.movb2d	1023, 7, 7, 63, 1
# CHECK-ASM-SAME: encoding: [0xfc,0xef,0xff,0x4f]
# CHECK-DIS: 4fffeffc{{.*}}tt.movb2d{{.*}}0x3ff, 0x7, 0x7, 0x3f, 0x1
tt.movb2d 1023, 7, 7, 63, 1

# CHECK-ASM: tt.movd2a	1023, 3, 7, 63, 1
# CHECK-ASM-SAME: encoding: [0xfc,0xcf,0xff,0x23]
# CHECK-DIS: 23ffcffc{{.*}}tt.movd2a{{.*}}0x3ff, 0x3, 0x7, 0x3f, 0x1
tt.movd2a 1023, 3, 7, 63, 1

# CHECK-ASM: tt.movd2b	1023, 3, 7, 63, 1
# CHECK-ASM-SAME: encoding: [0xfc,0xcf,0xff,0x2b]
# CHECK-DIS: 2bffcffc{{.*}}tt.movd2b{{.*}}0x3ff, 0x3, 0x7, 0x3f, 0x1
tt.movd2b 1023, 3, 7, 63, 1

# CHECK-ASM: tt.mvmul	1023, 7, 1, 1, 1
# CHECK-ASM-SAME: encoding: [0xfc,0x0f,0x27,0x9b]
# CHECK-DIS: 9b270ffc{{.*}}tt.mvmul{{.*}}0x3ff, 0x7, 0x1, 0x1, 0x1
tt.mvmul 1023, 7, 1, 1, 1

# CHECK-ASM: tt.pacr	1, 1, 3, 1, 1, 15, 1, 3, 3, 1, 7, 3
# CHECK-ASM-SAME: encoding: [0x7d,0xfe,0xff,0x05]
# CHECK-DIS: 05fffe7d{{.*}}tt.pacr{{.*}}0x1, 0x1, 0x3, 0x1, 0x1, 0xf, 0x1, 0x3, 0x3, 0x1, 0x7, 0x3
tt.pacr 1, 1, 3, 1, 1, 15, 1, 3, 3, 1, 7, 3

# CHECK-ASM: tt.sfparecip	15, 15, 15, 15
# CHECK-ASM-SAME: encoding: [0xfe,0xff,0x03,0x64]
# CHECK-DIS: 6403fffe{{.*}}tt.sfparecip{{.*}}0xf, 0xf, 0xf, 0xf
tt.sfparecip 15, 15, 15, 15

# CHECK-ASM: tt.sfpgt	15, 15, 15
# CHECK-ASM-SAME: encoding: [0xfe,0x3f,0x00,0x5c]
# CHECK-DIS: 5c003ffe{{.*}}tt.sfpgt{{.*}}0xf, 0xf, 0xf
tt.sfpgt 15, 15, 15

# CHECK-ASM: tt.sfple	15, 15, 15
# CHECK-ASM-SAME: encoding: [0xfe,0x3f,0x00,0x58]
# CHECK-DIS: 58003ffe{{.*}}tt.sfple{{.*}}0xf, 0xf, 0xf
tt.sfple 15, 15, 15

# CHECK-ASM: tt.sfploadmacro	1, 511, 7, 15, 3, 3
# CHECK-ASM-SAME: encoding: [0xfe,0x8f,0xff,0x4f]
# CHECK-DIS: 4fff8ffe{{.*}}tt.sfploadmacro{{.*}}0x1, 0x1ff, 0x7, 0xf, 0x3, 0x3
tt.sfploadmacro 1, 511, 7, 15, 3, 3

# CHECK-ASM: tt.sfpload	1023, 7, 15, 15
# CHECK-ASM-SAME: encoding: [0xfd,0x8f,0xff,0xc3]
# CHECK-DIS: c3ff8ffd{{.*}}tt.sfpload{{.*}}0x3ff, 0x7, 0xf, 0xf
tt.sfpload 1023, 7, 15, 15

# CHECK-ASM: tt.sfpmul24	15, 15, 15, 15, 15
# CHECK-ASM-SAME: encoding: [0xfe,0xff,0x3f,0x60]
# CHECK-DIS: 603ffffe{{.*}}tt.sfpmul24{{.*}}0xf, 0xf, 0xf, 0xf, 0xf
tt.sfpmul24 15, 15, 15, 15, 15

# CHECK-ASM: tt.sfpstochrnd	7, 15, 15, 3
# CHECK-ASM-SAME: encoding: [0xde,0x3f,0x80,0x39]
# CHECK-DIS: 39803fde{{.*}}tt.sfpstochrnd{{.*}}0x7, 0xf, 0xf, 0x3
tt.sfpstochrnd 7, 15, 15, 3

# CHECK-ASM: tt.sfpstochrndi	7, 15, 15, 15, 31, 3
# CHECK-ASM-SAME: encoding: [0xfe,0xff,0xff,0x39]
# CHECK-DIS: 39fffffe{{.*}}tt.sfpstochrndi{{.*}}0x7, 0xf, 0xf, 0xf, 0x1f, 0x3
tt.sfpstochrndi 7, 15, 15, 15, 31, 3

# CHECK-ASM: tt.sfpstore	1023, 7, 15, 15
# CHECK-ASM-SAME: encoding: [0xfd,0x8f,0xff,0xcb]
# CHECK-DIS: cbff8ffd{{.*}}tt.sfpstore{{.*}}0x3ff, 0x7, 0xf, 0xf
tt.sfpstore 1023, 7, 15, 15

# CHECK-ASM: tt.unpacr_nop	3, 3, 1, 1, 3, 1, 7, 63, 1
# CHECK-ASM-SAME: encoding: [0xfd,0xc7,0xfd,0x0e]
# CHECK-DIS: 0efdc7fd{{.*}}tt.unpacr_nop{{.*}}0x3, 0x3, 0x1, 0x1, 0x3, 0x1, 0x7, 0x3f, 0x1
tt.unpacr_nop 3, 3, 1, 1, 3, 1, 7, 63, 1

# CHECK-ASM: tt.zeroacc	1023, 7, 1, 1, 3
# CHECK-ASM-SAME: encoding: [0xfc,0x0f,0x7f,0x40]
# CHECK-DIS: 407f0ffc{{.*}}tt.zeroacc{{.*}}0x3ff, 0x7, 0x1, 0x1, 0x3
tt.zeroacc 1023, 7, 1, 1, 3
