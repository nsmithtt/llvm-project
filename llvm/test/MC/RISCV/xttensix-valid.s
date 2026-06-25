# RUN: llvm-mc %s -triple=riscv32 -mattr=+experimental-xttensixwh -show-encoding \
# RUN:     | FileCheck -check-prefixes=CHECK-ASM %s
# RUN: llvm-mc -filetype=obj -triple=riscv32 -mattr=+experimental-xttensixwh %s \
# RUN:     | llvm-objdump -d --mattr=+experimental-xttensixwh - \
# RUN:     | FileCheck -check-prefixes=CHECK-DIS %s

# All Wormhole (XTTensixWH) named Tensix instructions.
# One encode + decode check per instruction (operands set to field-maximum
# values). Encodings cross-checked against the ttsim Tensix ISA spec.

# CHECK-ASM: tt.adddmareg	63, 63, 63
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0x0f,0x60]
# CHECK-DIS: 600ffffd{{.*}}tt.adddmareg{{.*}}0x3f, 0x3f, 0x3f
tt.adddmareg 63, 63, 63

# CHECK-ASM: tt.adddmaregi	63, 63, 63
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0x0f,0x62]
# CHECK-DIS: 620ffffd{{.*}}tt.adddmaregi{{.*}}0x3f, 0x3f, 0x3f
tt.adddmaregi 63, 63, 63

# CHECK-ASM: tt.addrcrxy	1, 1, 1, 1, 7, 7, 7, 7, 1, 1, 1
# CHECK-ASM-SAME: encoding: [0x3d,0xff,0x8f,0x4f]
# CHECK-DIS: 4f8fff3d{{.*}}tt.addrcrxy{{.*}}0x1, 0x1, 0x1, 0x1, 0x7, 0x7, 0x7, 0x7, 0x1, 0x1, 0x1
tt.addrcrxy 1, 1, 1, 1, 7, 7, 7, 7, 1, 1, 1

# CHECK-ASM: tt.addrcrzw	1, 1, 1, 1, 7, 7, 7, 7, 1, 1, 1
# CHECK-ASM-SAME: encoding: [0x3d,0xff,0x8f,0x5b]
# CHECK-DIS: 5b8fff3d{{.*}}tt.addrcrzw{{.*}}0x1, 0x1, 0x1, 0x1, 0x7, 0x7, 0x7, 0x7, 0x1, 0x1, 0x1
tt.addrcrzw 1, 1, 1, 1, 7, 7, 7, 7, 1, 1, 1

# CHECK-ASM: tt.atcas	63, 3, 15, 15
# CHECK-ASM-SAME: encoding: [0xfd,0xc0,0xff,0x90]
# CHECK-DIS: 90ffc0fd{{.*}}tt.atcas{{.*}}0x3f, 0x3, 0xf, 0xf
tt.atcas 63, 3, 15, 15

# CHECK-ASM: tt.atgetm	65535
# CHECK-ASM-SAME: encoding: [0xfe,0xff,0x03,0x80]
# CHECK-DIS: 8003fffe{{.*}}tt.atgetm{{.*}}0xffff
tt.atgetm 65535

# CHECK-ASM: tt.atincget	63, 63, 3, 31
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0x1f,0x84]
# CHECK-DIS: 841ffffd{{.*}}tt.atincget{{.*}}0x3f, 0x3f, 0x3, 0x1f
tt.atincget 63, 63, 3, 31

# CHECK-ASM: tt.atincgetptr	63, 63, 3, 15, 15, 1
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0xff,0x89]
# CHECK-DIS: 89fffffd{{.*}}tt.atincgetptr{{.*}}0x3f, 0x3f, 0x3, 0xf, 0xf, 0x1
tt.atincgetptr 63, 63, 3, 15, 15, 1

# CHECK-ASM: tt.atrelm	65535
# CHECK-ASM-SAME: encoding: [0xfe,0xff,0x03,0x84]
# CHECK-DIS: 8403fffe{{.*}}tt.atrelm{{.*}}0xffff
tt.atrelm 65535

# CHECK-ASM: tt.atswap	63, 63, 255, 1
# CHECK-ASM-SAME: encoding: [0xfd,0x3f,0xff,0x8d]
# CHECK-DIS: 8dff3ffd{{.*}}tt.atswap{{.*}}0x3f, 0x3f, 0xff, 0x1
tt.atswap 63, 63, 255, 1

# CHECK-ASM: tt.bitwopdmareg	63, 63, 63, 7
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0x7f,0x6c]
# CHECK-DIS: 6c7ffffd{{.*}}tt.bitwopdmareg{{.*}}0x3f, 0x3f, 0x3f, 0x7
tt.bitwopdmareg 63, 63, 63, 7

# CHECK-ASM: tt.bitwopdmaregi	63, 63, 63, 7
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0x7f,0x6e]
# CHECK-DIS: 6e7ffffd{{.*}}tt.bitwopdmaregi{{.*}}0x3f, 0x3f, 0x3f, 0x7
tt.bitwopdmaregi 63, 63, 63, 7

# CHECK-ASM: tt.cleardvalid	1, 1, 1, 1
# CHECK-ASM-SAME: encoding: [0x0c,0x00,0x00,0xdb]
# CHECK-DIS: db00000c{{.*}}tt.cleardvalid{{.*}}0x1, 0x1, 0x1, 0x1
tt.cleardvalid 1, 1, 1, 1

# CHECK-ASM: tt.clrexphist
# CHECK-ASM-SAME: encoding: [0x00,0x00,0x00,0x84]
# CHECK-DIS: 84000000{{.*}}tt.clrexphist
tt.clrexphist

# CHECK-ASM: tt.cmpdmareg	63, 63, 63, 7
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0x7f,0x74]
# CHECK-DIS: 747ffffd{{.*}}tt.cmpdmareg{{.*}}0x3f, 0x3f, 0x3f, 0x7
tt.cmpdmareg 63, 63, 63, 7

# CHECK-ASM: tt.cmpdmaregi	63, 63, 63, 7
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0x7f,0x76]
# CHECK-DIS: 767ffffd{{.*}}tt.cmpdmaregi{{.*}}0x3f, 0x3f, 0x3f, 0x7
tt.cmpdmaregi 63, 63, 63, 7

# CHECK-ASM: tt.dmanop
# CHECK-ASM-SAME: encoding: [0x01,0x00,0x00,0x80]
# CHECK-DIS: 80000001{{.*}}tt.dmanop
tt.dmanop

# CHECK-ASM: tt.dotpv	1023, 3, 1, 1
# CHECK-ASM-SAME: encoding: [0xfc,0x0f,0x06,0xa7]
# CHECK-DIS: a7060ffc{{.*}}tt.dotpv{{.*}}0x3ff, 0x3, 0x1, 0x1
tt.dotpv 1023, 3, 1, 1

# CHECK-ASM: tt.elwadd	1023, 3, 1, 1, 1, 1, 1
# CHECK-ASM-SAME: encoding: [0xfc,0x0f,0xe6,0xa3]
# CHECK-DIS: a3e60ffc{{.*}}tt.elwadd{{.*}}0x3ff, 0x3, 0x1, 0x1, 0x1, 0x1, 0x1
tt.elwadd 1023, 3, 1, 1, 1, 1, 1

# CHECK-ASM: tt.elwmul	1023, 3, 1, 1, 1, 1, 1
# CHECK-ASM-SAME: encoding: [0xfc,0x0f,0xe6,0x9f]
# CHECK-DIS: 9fe60ffc{{.*}}tt.elwmul{{.*}}0x3ff, 0x3, 0x1, 0x1, 0x1, 0x1, 0x1
tt.elwmul 1023, 3, 1, 1, 1, 1, 1

# CHECK-ASM: tt.elwsub	1023, 3, 1, 1, 1, 1, 1
# CHECK-ASM-SAME: encoding: [0xfc,0x0f,0xe6,0xc3]
# CHECK-DIS: c3e60ffc{{.*}}tt.elwsub{{.*}}0x3ff, 0x3, 0x1, 0x1, 0x1, 0x1, 0x1
tt.elwsub 1023, 3, 1, 1, 1, 1, 1

# CHECK-ASM: tt.flushdma	15
# CHECK-ASM-SAME: encoding: [0x3d,0x00,0x00,0x18]
# CHECK-DIS: 1800003d{{.*}}tt.flushdma{{.*}}0xf
tt.flushdma 15

# CHECK-ASM: tt.gapool	1023, 1, 3, 1, 3
# CHECK-ASM-SAME: encoding: [0xfc,0x0f,0x27,0xd3]
# CHECK-DIS: d3270ffc{{.*}}tt.gapool{{.*}}0x3ff, 0x1, 0x3, 0x1, 0x3
tt.gapool 1023, 1, 3, 1, 3

# CHECK-ASM: tt.gatesrcrst	1, 1
# CHECK-ASM-SAME: encoding: [0x0c,0x00,0x00,0xd4]
# CHECK-DIS: d400000c{{.*}}tt.gatesrcrst{{.*}}0x1, 0x1
tt.gatesrcrst 1, 1

# CHECK-ASM: tt.gmpool	1023, 1, 3, 1, 3
# CHECK-ASM-SAME: encoding: [0xfc,0x0f,0x27,0xcf]
# CHECK-DIS: cf270ffc{{.*}}tt.gmpool{{.*}}0x3ff, 0x1, 0x3, 0x1, 0x3
tt.gmpool 1023, 1, 3, 1, 3

# CHECK-ASM: tt.incadcxy	7, 7, 7, 7, 1, 1, 1
# CHECK-ASM-SAME: encoding: [0x01,0xff,0x8f,0x4b]
# CHECK-DIS: 4b8fff01{{.*}}tt.incadcxy{{.*}}0x7, 0x7, 0x7, 0x7, 0x1, 0x1, 0x1
tt.incadcxy 7, 7, 7, 7, 1, 1, 1

# CHECK-ASM: tt.incadczw	7, 7, 7, 7, 1, 1, 1
# CHECK-ASM-SAME: encoding: [0x01,0xff,0x8f,0x57]
# CHECK-DIS: 578fff01{{.*}}tt.incadczw{{.*}}0x7, 0x7, 0x7, 0x7, 0x1, 0x1, 0x1
tt.incadczw 7, 7, 7, 7, 1, 1, 1

# CHECK-ASM: tt.incrwc	15, 15, 15, 1, 1, 1
# CHECK-ASM-SAME: encoding: [0x00,0xff,0x7f,0xe0]
# CHECK-DIS: e07fff00{{.*}}tt.incrwc{{.*}}0xf, 0xf, 0xf, 0x1, 0x1, 0x1
tt.incrwc 15, 15, 15, 1, 1, 1

# CHECK-ASM: tt.loadind	63, 63, 3, 127, 3
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0x7f,0x27]
# CHECK-DIS: 277ffffd{{.*}}tt.loadind{{.*}}0x3f, 0x3f, 0x3, 0x7f, 0x3
tt.loadind 63, 63, 3, 127, 3

# CHECK-ASM: tt.loadreg	262143, 63
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0xff,0xa3]
# CHECK-DIS: a3fffffd{{.*}}tt.loadreg{{.*}}0x3ffff, 0x3f
tt.loadreg 262143, 63

# CHECK-ASM: tt.mop	65535, 127, 1
# CHECK-ASM-SAME: encoding: [0xfc,0xff,0xff,0x07]
# CHECK-DIS: 07fffffc{{.*}}tt.mop{{.*}}0xffff, 0x7f, 0x1
tt.mop 65535, 127, 1

# CHECK-ASM: tt.mop_cfg	65535
# CHECK-ASM-SAME: encoding: [0xfc,0xff,0x03,0x0c]
# CHECK-DIS: 0c03fffc{{.*}}tt.mop_cfg{{.*}}0xffff
tt.mop_cfg 65535

# CHECK-ASM: tt.mova2d	1023, 3, 3, 63, 1
# CHECK-ASM-SAME: encoding: [0xfc,0xcf,0xfe,0x4b]
# CHECK-DIS: 4bfecffc{{.*}}tt.mova2d{{.*}}0x3ff, 0x3, 0x3, 0x3f, 0x1
tt.mova2d 1023, 3, 3, 63, 1

# CHECK-ASM: tt.movb2a	63, 3, 3, 63
# CHECK-ASM-SAME: encoding: [0xfc,0xc0,0xfe,0x2d]
# CHECK-DIS: 2dfec0fc{{.*}}tt.movb2a{{.*}}0x3f, 0x3, 0x3, 0x3f
tt.movb2a 63, 3, 3, 63

# CHECK-ASM: tt.movb2d	1023, 1, 1, 1, 3, 63, 1
# CHECK-ASM-SAME: encoding: [0xfc,0xcf,0xff,0x4f]
# CHECK-DIS: 4fffcffc{{.*}}tt.movb2d{{.*}}0x3ff, 0x1, 0x1, 0x1, 0x3, 0x3f, 0x1
tt.movb2d 1023, 1, 1, 1, 3, 63, 1

# CHECK-ASM: tt.movd2a	1023, 3, 3, 63, 1
# CHECK-ASM-SAME: encoding: [0xfc,0xcf,0xfe,0x23]
# CHECK-DIS: 23fecffc{{.*}}tt.movd2a{{.*}}0x3ff, 0x3, 0x3, 0x3f, 0x1
tt.movd2a 1023, 3, 3, 63, 1

# CHECK-ASM: tt.movd2b	1023, 3, 3, 63, 1
# CHECK-ASM-SAME: encoding: [0xfc,0xcf,0xfe,0x2b]
# CHECK-DIS: 2bfecffc{{.*}}tt.movd2b{{.*}}0x3ff, 0x3, 0x3, 0x3f, 0x1
tt.movd2b 1023, 3, 3, 63, 1

# CHECK-ASM: tt.movdbga2d	1023, 1, 3, 63, 1
# CHECK-ASM-SAME: encoding: [0xfc,0x8f,0xfe,0x27]
# CHECK-DIS: 27fe8ffc{{.*}}tt.movdbga2d{{.*}}0x3ff, 0x1, 0x3, 0x3f, 0x1
tt.movdbga2d 1023, 1, 3, 63, 1

# CHECK-ASM: tt.muldmareg	63, 63, 63
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0x0f,0x68]
# CHECK-DIS: 680ffffd{{.*}}tt.muldmareg{{.*}}0x3f, 0x3f, 0x3f
tt.muldmareg 63, 63, 63

# CHECK-ASM: tt.muldmaregi	63, 63, 63
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0x0f,0x6a]
# CHECK-DIS: 6a0ffffd{{.*}}tt.muldmaregi{{.*}}0x3f, 0x3f, 0x3f
tt.muldmaregi 63, 63, 63

# CHECK-ASM: tt.mvmul	1023, 3, 1, 1, 1
# CHECK-ASM-SAME: encoding: [0xfc,0x0f,0x26,0x9b]
# CHECK-DIS: 9b260ffc{{.*}}tt.mvmul{{.*}}0x3ff, 0x3, 0x1, 0x1, 0x1
tt.mvmul 1023, 3, 1, 1, 1

# CHECK-ASM: tt.nop
# CHECK-ASM-SAME: encoding: [0x00,0x00,0x00,0x08]
# CHECK-DIS: 08000000{{.*}}tt.nop
tt.nop

# CHECK-ASM: tt.pacr	1, 1, 1, 1, 15, 1, 3
# CHECK-ASM-SAME: encoding: [0x4d,0x7e,0x06,0x04]
# CHECK-DIS: 04067e4d{{.*}}tt.pacr{{.*}}0x1, 0x1, 0x1, 0x1, 0xf, 0x1, 0x3
tt.pacr 1, 1, 1, 1, 15, 1, 3

# CHECK-ASM: tt.pacr_setreg	63, 1023, 1
# CHECK-ASM-SAME: encoding: [0xf9,0xff,0xff,0x2b]
# CHECK-DIS: 2bfffff9{{.*}}tt.pacr_setreg{{.*}}0x3f, 0x3ff, 0x1
tt.pacr_setreg 63, 1023, 1

# CHECK-ASM: tt.rdcfg	2047, 63
# CHECK-ASM-SAME: encoding: [0xfe,0x1f,0xfc,0xc4]
# CHECK-DIS: c4fc1ffe{{.*}}tt.rdcfg{{.*}}0x7ff, 0x3f
tt.rdcfg 2047, 63

# CHECK-ASM: tt.reg2flop.adc	63, 3, 1, 3, 1, 3, 3, 1, 3
# CHECK-ASM-SAME: encoding: [0xfd,0x3f,0xfc,0x23]
# CHECK-DIS: 23fc3ffd{{.*}}tt.reg2flop.adc{{.*}}0x3f, 0x3, 0x1, 0x3, 0x1, 0x3, 0x3, 0x1, 0x3
tt.reg2flop.adc 63, 3, 1, 3, 1, 3, 3, 1, 3

# CHECK-ASM: tt.reg2flop	63, 127, 3
# CHECK-ASM-SAME: encoding: [0xfd,0x7f,0x00,0x23]
# CHECK-DIS: 23007ffd{{.*}}tt.reg2flop{{.*}}0x3f, 0x7f, 0x3
tt.reg2flop 63, 127, 3

# CHECK-ASM: tt.replay	1, 1, 63, 31
# CHECK-ASM-SAME: encoding: [0xcc,0x0f,0x1f,0x10]
# CHECK-DIS: 101f0fcc{{.*}}tt.replay{{.*}}0x1, 0x1, 0x3f, 0x1f
tt.replay 1, 1, 63, 31

# CHECK-ASM: tt.rmwcib0	255, 255, 255
# CHECK-ASM-SAME: encoding: [0xfe,0xff,0xff,0xcf]
# CHECK-DIS: cffffffe{{.*}}tt.rmwcib0{{.*}}0xff, 0xff, 0xff
tt.rmwcib0 255, 255, 255

# CHECK-ASM: tt.rmwcib1	255, 255, 255
# CHECK-ASM-SAME: encoding: [0xfe,0xff,0xff,0xd3]
# CHECK-DIS: d3fffffe{{.*}}tt.rmwcib1{{.*}}0xff, 0xff, 0xff
tt.rmwcib1 255, 255, 255

# CHECK-ASM: tt.rmwcib2	255, 255, 255
# CHECK-ASM-SAME: encoding: [0xfe,0xff,0xff,0xd7]
# CHECK-DIS: d7fffffe{{.*}}tt.rmwcib2{{.*}}0xff, 0xff, 0xff
tt.rmwcib2 255, 255, 255

# CHECK-ASM: tt.rmwcib3	255, 255, 255
# CHECK-ASM-SAME: encoding: [0xfe,0xff,0xff,0xdb]
# CHECK-DIS: dbfffffe{{.*}}tt.rmwcib3{{.*}}0xff, 0xff, 0xff
tt.rmwcib3 255, 255, 255

# CHECK-ASM: tt.semget	255
# CHECK-ASM-SAME: encoding: [0xf2,0x0f,0x00,0x94]
# CHECK-DIS: 94000ff2{{.*}}tt.semget{{.*}}0xff
tt.semget 255

# CHECK-ASM: tt.seminit	255, 15, 15
# CHECK-ASM-SAME: encoding: [0xf2,0x0f,0xfc,0x8f]
# CHECK-DIS: 8ffc0ff2{{.*}}tt.seminit{{.*}}0xff, 0xf, 0xf
tt.seminit 255, 15, 15

# CHECK-ASM: tt.sempost	255
# CHECK-ASM-SAME: encoding: [0xf2,0x0f,0x00,0x90]
# CHECK-DIS: 90000ff2{{.*}}tt.sempost{{.*}}0xff
tt.sempost 255

# CHECK-ASM: tt.semwait	3, 255, 511
# CHECK-ASM-SAME: encoding: [0xfe,0x0f,0xfe,0x9b]
# CHECK-DIS: 9bfe0ffe{{.*}}tt.semwait{{.*}}0x3, 0xff, 0x1ff
tt.semwait 3, 255, 511

# CHECK-ASM: tt.setadc	262143, 3, 1, 1, 1, 1
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0xff,0x43]
# CHECK-DIS: 43fffffd{{.*}}tt.setadc{{.*}}0x3ffff, 0x3, 0x1, 0x1, 0x1, 0x1
tt.setadc 262143, 3, 1, 1, 1, 1

# CHECK-ASM: tt.setadcxx	1023, 1023, 1, 1, 1
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0xbf,0x7b]
# CHECK-DIS: 7bbffffd{{.*}}tt.setadcxx{{.*}}0x3ff, 0x3ff, 0x1, 0x1, 0x1
tt.setadcxx 1023, 1023, 1, 1, 1

# CHECK-ASM: tt.setadcxy	1, 1, 1, 1, 7, 7, 7, 7, 1, 1, 1
# CHECK-ASM-SAME: encoding: [0x3d,0xff,0x8f,0x47]
# CHECK-DIS: 478fff3d{{.*}}tt.setadcxy{{.*}}0x1, 0x1, 0x1, 0x1, 0x7, 0x7, 0x7, 0x7, 0x1, 0x1, 0x1
tt.setadcxy 1, 1, 1, 1, 7, 7, 7, 7, 1, 1, 1

# CHECK-ASM: tt.setadczw	1, 1, 1, 1, 7, 7, 7, 7, 1, 1, 1
# CHECK-ASM-SAME: encoding: [0x3d,0xff,0x8f,0x53]
# CHECK-DIS: 538fff3d{{.*}}tt.setadczw{{.*}}0x1, 0x1, 0x1, 0x1, 0x7, 0x7, 0x7, 0x7, 0x1, 0x1, 0x1
tt.setadczw 1, 1, 1, 1, 7, 7, 7, 7, 1, 1, 1

# CHECK-ASM: tt.setc16	65535, 255
# CHECK-ASM-SAME: encoding: [0xfe,0xff,0xff,0xcb]
# CHECK-DIS: cbfffffe{{.*}}tt.setc16{{.*}}0xffff, 0xff
tt.setc16 65535, 255

# CHECK-ASM: tt.setdmareg	127, 65535
# CHECK-ASM-SAME: encoding: [0xfd,0xfd,0xff,0x17]
# CHECK-DIS: 17fffdfd{{.*}}tt.setdmareg{{.*}}0x7f, 0xffff
tt.setdmareg 127, 65535

# CHECK-ASM: tt.setdmareg.special	127, 7, 15, 15, 3
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0x1f,0x17]
# CHECK-DIS: 171ffffd{{.*}}tt.setdmareg.special{{.*}}0x7f, 0x7, 0xf, 0xf, 0x3
tt.setdmareg.special 127, 7, 15, 15, 3

# CHECK-ASM: tt.setdvalid	1, 1
# CHECK-ASM-SAME: encoding: [0x0d,0x00,0x00,0x5c]
# CHECK-DIS: 5c00000d{{.*}}tt.setdvalid{{.*}}0x1, 0x1
tt.setdvalid 1, 1

# CHECK-ASM: tt.setrwc	1, 1, 1, 1, 15, 15, 15, 1, 1, 1, 1, 1, 1
# CHECK-ASM-SAME: encoding: [0x3c,0xff,0xff,0xdf]
# CHECK-DIS: dfffff3c{{.*}}tt.setrwc{{.*}}0x1, 0x1, 0x1, 0x1, 0xf, 0xf, 0xf, 0x1, 0x1, 0x1, 0x1, 0x1, 0x1
tt.setrwc 1, 1, 1, 1, 15, 15, 15, 1, 1, 1, 1, 1, 1

# CHECK-ASM: tt.sfpabs	15, 15, 15
# CHECK-ASM-SAME: encoding: [0xfd,0x3f,0x00,0xf4]
# CHECK-DIS: f4003ffd{{.*}}tt.sfpabs{{.*}}0xf, 0xf, 0xf
tt.sfpabs 15, 15, 15

# CHECK-ASM: tt.sfpadd	15, 15, 15, 15, 15
# CHECK-ASM-SAME: encoding: [0xfe,0xff,0x3f,0x14]
# CHECK-DIS: 143ffffe{{.*}}tt.sfpadd{{.*}}0xf, 0xf, 0xf, 0xf, 0xf
tt.sfpadd 15, 15, 15, 15, 15

# CHECK-ASM: tt.sfpaddi	15, 15, 65535
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0xff,0xd7]
# CHECK-DIS: d7fffffd{{.*}}tt.sfpaddi{{.*}}0xf, 0xf, 0xffff
tt.sfpaddi 15, 15, 65535

# CHECK-ASM: tt.sfpand	15, 15, 15, 15
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0x03,0xf8]
# CHECK-DIS: f803fffd{{.*}}tt.sfpand{{.*}}0xf, 0xf, 0xf, 0xf
tt.sfpand 15, 15, 15, 15

# CHECK-ASM: tt.sfpcast	15, 15, 15
# CHECK-ASM-SAME: encoding: [0xfe,0x3f,0x00,0x40]
# CHECK-DIS: 40003ffe{{.*}}tt.sfpcast{{.*}}0xf, 0xf, 0xf
tt.sfpcast 15, 15, 15

# CHECK-ASM: tt.sfpcompc	15
# CHECK-ASM-SAME: encoding: [0xc2,0x03,0x00,0x2c]
# CHECK-DIS: 2c0003c2{{.*}}tt.sfpcompc{{.*}}0xf
tt.sfpcompc 15

# CHECK-ASM: tt.sfpconfig	15, 15, 65535
# CHECK-ASM-SAME: encoding: [0xfe,0xff,0xff,0x47]
# CHECK-DIS: 47fffffe{{.*}}tt.sfpconfig{{.*}}0xf, 0xf, 0xffff
tt.sfpconfig 15, 15, 65535

# CHECK-ASM: tt.sfpdivp2	15, 15, 15, 4095
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0xff,0xdb]
# CHECK-DIS: dbfffffd{{.*}}tt.sfpdivp2{{.*}}0xf, 0xf, 0xf, 0xfff
tt.sfpdivp2 15, 15, 15, 4095

# CHECK-ASM: tt.sfpencc	15, 15, 3
# CHECK-ASM-SAME: encoding: [0xfe,0xc3,0x00,0x28]
# CHECK-DIS: 2800c3fe{{.*}}tt.sfpencc{{.*}}0xf, 0xf, 0x3
tt.sfpencc 15, 15, 3

# CHECK-ASM: tt.sfpexexp	15, 15, 15
# CHECK-ASM-SAME: encoding: [0xfd,0x3f,0x00,0xdc]
# CHECK-DIS: dc003ffd{{.*}}tt.sfpexexp{{.*}}0xf, 0xf, 0xf
tt.sfpexexp 15, 15, 15

# CHECK-ASM: tt.sfpexman	15, 15, 15
# CHECK-ASM-SAME: encoding: [0xfd,0x3f,0x00,0xe0]
# CHECK-DIS: e0003ffd{{.*}}tt.sfpexman{{.*}}0xf, 0xf, 0xf
tt.sfpexman 15, 15, 15

# CHECK-ASM: tt.sfpiadd	15, 15, 15, 2047
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0xff,0xe5]
# CHECK-DIS: e5fffffd{{.*}}tt.sfpiadd{{.*}}0xf, 0xf, 0xf, 0x7ff
tt.sfpiadd 15, 15, 15, 2047

# CHECK-ASM: tt.sfpload	1023, 3, 15, 15
# CHECK-ASM-SAME: encoding: [0xfd,0x0f,0xff,0xc3]
# CHECK-DIS: c3ff0ffd{{.*}}tt.sfpload{{.*}}0x3ff, 0x3, 0xf, 0xf
tt.sfpload 1023, 3, 15, 15

# CHECK-ASM: tt.sfploadi	65535, 15, 15
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0xff,0xc7]
# CHECK-DIS: c7fffffd{{.*}}tt.sfploadi{{.*}}0xffff, 0xf, 0xf
tt.sfploadi 65535, 15, 15

# CHECK-ASM: tt.sfploadmacro	1, 511, 3, 15, 3, 3
# CHECK-ASM-SAME: encoding: [0xfe,0x0f,0xff,0x4f]
# CHECK-DIS: 4fff0ffe{{.*}}tt.sfploadmacro{{.*}}0x1, 0x1ff, 0x3, 0xf, 0x3, 0x3
tt.sfploadmacro 1, 511, 3, 15, 3, 3

# CHECK-ASM: tt.sfplut	15, 15
# CHECK-ASM-SAME: encoding: [0x01,0x00,0xfc,0xcf]
# CHECK-DIS: cffc0001{{.*}}tt.sfplut{{.*}}0xf, 0xf
tt.sfplut 15, 15

# CHECK-ASM: tt.sfplutfp32	15, 15
# CHECK-ASM-SAME: encoding: [0xfe,0x03,0x00,0x54]
# CHECK-DIS: 540003fe{{.*}}tt.sfplutfp32{{.*}}0xf, 0xf
tt.sfplutfp32 15, 15

# CHECK-ASM: tt.sfplz	15, 15, 15
# CHECK-ASM-SAME: encoding: [0xfe,0x3f,0x00,0x04]
# CHECK-DIS: 04003ffe{{.*}}tt.sfplz{{.*}}0xf, 0xf, 0xf
tt.sfplz 15, 15, 15

# CHECK-ASM: tt.sfpmad	15, 15, 15, 15, 15
# CHECK-ASM-SAME: encoding: [0xfe,0xff,0x3f,0x10]
# CHECK-DIS: 103ffffe{{.*}}tt.sfpmad{{.*}}0xf, 0xf, 0xf, 0xf, 0xf
tt.sfpmad 15, 15, 15, 15, 15

# CHECK-ASM: tt.sfpmov	15, 15, 15
# CHECK-ASM-SAME: encoding: [0xfd,0x3f,0x00,0xf0]
# CHECK-DIS: f0003ffd{{.*}}tt.sfpmov{{.*}}0xf, 0xf, 0xf
tt.sfpmov 15, 15, 15

# CHECK-ASM: tt.sfpmul	15, 15, 15, 15, 15
# CHECK-ASM-SAME: encoding: [0xfe,0xff,0x3f,0x18]
# CHECK-DIS: 183ffffe{{.*}}tt.sfpmul{{.*}}0xf, 0xf, 0xf, 0xf, 0xf
tt.sfpmul 15, 15, 15, 15, 15

# CHECK-ASM: tt.sfpmuli	15, 15, 65535
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0xff,0xd3]
# CHECK-DIS: d3fffffd{{.*}}tt.sfpmuli{{.*}}0xf, 0xf, 0xffff
tt.sfpmuli 15, 15, 65535

# CHECK-ASM: tt.sfpnop
# CHECK-ASM-SAME: encoding: [0x02,0x00,0x00,0x3c]
# CHECK-DIS: 3c000002{{.*}}tt.sfpnop
tt.sfpnop

# CHECK-ASM: tt.sfpnot	15, 15
# CHECK-ASM-SAME: encoding: [0xc2,0x3f,0x00,0x00]
# CHECK-DIS: 00003fc2{{.*}}tt.sfpnot{{.*}}0xf, 0xf
tt.sfpnot 15, 15

# CHECK-ASM: tt.sfpor	15, 15, 15, 15
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0x03,0xfc]
# CHECK-DIS: fc03fffd{{.*}}tt.sfpor{{.*}}0xf, 0xf, 0xf, 0xf
tt.sfpor 15, 15, 15, 15

# CHECK-ASM: tt.sfppopc	15, 15
# CHECK-ASM-SAME: encoding: [0xfe,0x03,0x00,0x20]
# CHECK-DIS: 200003fe{{.*}}tt.sfppopc{{.*}}0xf, 0xf
tt.sfppopc 15, 15

# CHECK-ASM: tt.sfppushc	15, 15
# CHECK-ASM-SAME: encoding: [0xfe,0x03,0x00,0x1c]
# CHECK-DIS: 1c0003fe{{.*}}tt.sfppushc{{.*}}0xf, 0xf
tt.sfppushc 15, 15

# CHECK-ASM: tt.sfpsetcc	15, 15, 15, 1
# CHECK-ASM-SAME: encoding: [0xfd,0x7f,0x00,0xec]
# CHECK-DIS: ec007ffd{{.*}}tt.sfpsetcc{{.*}}0xf, 0xf, 0xf, 0x1
tt.sfpsetcc 15, 15, 15, 1

# CHECK-ASM: tt.sfpsetexp	15, 15, 15, 255
# CHECK-ASM-SAME: encoding: [0xfe,0xff,0x3f,0x08]
# CHECK-DIS: 083ffffe{{.*}}tt.sfpsetexp{{.*}}0xf, 0xf, 0xf, 0xff
tt.sfpsetexp 15, 15, 15, 255

# CHECK-ASM: tt.sfpsetman	15, 15, 15, 4095
# CHECK-ASM-SAME: encoding: [0xfe,0xff,0xff,0x0f]
# CHECK-DIS: 0ffffffe{{.*}}tt.sfpsetman{{.*}}0xf, 0xf, 0xf, 0xfff
tt.sfpsetman 15, 15, 15, 4095

# CHECK-ASM: tt.sfpsetsgn	15, 15, 15, 1
# CHECK-ASM-SAME: encoding: [0xfe,0x7f,0x00,0x24]
# CHECK-DIS: 24007ffe{{.*}}tt.sfpsetsgn{{.*}}0xf, 0xf, 0xf, 0x1
tt.sfpsetsgn 15, 15, 15, 1

# CHECK-ASM: tt.sfpshft	15, 15, 15, 2047
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0xff,0xe9]
# CHECK-DIS: e9fffffd{{.*}}tt.sfpshft{{.*}}0xf, 0xf, 0xf, 0x7ff
tt.sfpshft 15, 15, 15, 2047

# CHECK-ASM: tt.sfpshft2	15, 15, 15, 15
# CHECK-ASM-SAME: encoding: [0xfe,0xff,0x03,0x50]
# CHECK-DIS: 5003fffe{{.*}}tt.sfpshft2{{.*}}0xf, 0xf, 0xf, 0xf
tt.sfpshft2 15, 15, 15, 15

# CHECK-ASM: tt.sfpshft2i	15, 15, 2047
# CHECK-ASM-SAME: encoding: [0xfe,0xc3,0xff,0x51]
# CHECK-DIS: 51ffc3fe{{.*}}tt.sfpshft2i{{.*}}0xf, 0xf, 0x7ff
tt.sfpshft2i 15, 15, 2047

# CHECK-ASM: tt.sfpstochrnd	7, 15, 15, 1
# CHECK-ASM-SAME: encoding: [0xde,0x3f,0x80,0x38]
# CHECK-DIS: 38803fde{{.*}}tt.sfpstochrnd{{.*}}0x7, 0xf, 0xf, 0x1
tt.sfpstochrnd 7, 15, 15, 1

# CHECK-ASM: tt.sfpstochrndi	7, 15, 15, 15, 31, 1
# CHECK-ASM-SAME: encoding: [0xfe,0xff,0xff,0x38]
# CHECK-DIS: 38fffffe{{.*}}tt.sfpstochrndi{{.*}}0x7, 0xf, 0xf, 0xf, 0x1f, 0x1
tt.sfpstochrndi 7, 15, 15, 15, 31, 1

# CHECK-ASM: tt.sfpstore	1023, 3, 15, 15
# CHECK-ASM-SAME: encoding: [0xfd,0x0f,0xff,0xcb]
# CHECK-DIS: cbff0ffd{{.*}}tt.sfpstore{{.*}}0x3ff, 0x3, 0xf, 0xf
tt.sfpstore 1023, 3, 15, 15

# CHECK-ASM: tt.sfpswap	15, 15, 15
# CHECK-ASM-SAME: encoding: [0xfe,0x3f,0x00,0x48]
# CHECK-DIS: 48003ffe{{.*}}tt.sfpswap{{.*}}0xf, 0xf, 0xf
tt.sfpswap 15, 15, 15

# CHECK-ASM: tt.sfptransp	15
# CHECK-ASM-SAME: encoding: [0xc2,0x03,0x00,0x30]
# CHECK-DIS: 300003c2{{.*}}tt.sfptransp{{.*}}0xf
tt.sfptransp 15

# CHECK-ASM: tt.sfpxor	15, 15
# CHECK-ASM-SAME: encoding: [0xc2,0x3f,0x00,0x34]
# CHECK-DIS: 34003fc2{{.*}}tt.sfpxor{{.*}}0xf, 0xf
tt.sfpxor 15, 15

# CHECK-ASM: tt.shiftdmareg	63, 63, 63, 7
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0x7f,0x70]
# CHECK-DIS: 707ffffd{{.*}}tt.shiftdmareg{{.*}}0x3f, 0x3f, 0x3f, 0x7
tt.shiftdmareg 63, 63, 63, 7

# CHECK-ASM: tt.shiftdmaregi	63, 63, 63, 7
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0x7f,0x72]
# CHECK-DIS: 727ffffd{{.*}}tt.shiftdmaregi{{.*}}0x3f, 0x3f, 0x3f, 0x7
tt.shiftdmaregi 63, 63, 63, 7

# CHECK-ASM: tt.shiftxa	3
# CHECK-ASM-SAME: encoding: [0x0c,0x00,0x00,0x5c]
# CHECK-DIS: 5c00000c{{.*}}tt.shiftxa{{.*}}0x3
tt.shiftxa 3

# CHECK-ASM: tt.shiftxb	63, 1, 3
# CHECK-ASM-SAME: encoding: [0xfc,0x10,0x06,0x60]
# CHECK-DIS: 600610fc{{.*}}tt.shiftxb{{.*}}0x3f, 0x1, 0x3
tt.shiftxb 63, 1, 3

# CHECK-ASM: tt.stallwait	32767, 511
# CHECK-ASM-SAME: encoding: [0xfe,0xff,0xff,0x8b]
# CHECK-DIS: 8bfffffe{{.*}}tt.stallwait{{.*}}0x7fff, 0x1ff
tt.stallwait 32767, 511

# CHECK-ASM: tt.storeind.l1	63, 63, 3, 127, 3
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0xff,0x9b]
# CHECK-DIS: 9bfffffd{{.*}}tt.storeind.l1{{.*}}0x3f, 0x3f, 0x3, 0x7f, 0x3
tt.storeind.l1 63, 63, 3, 127, 3

# CHECK-ASM: tt.storeind.mmio	63, 63, 3, 127
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0x7f,0x99]
# CHECK-DIS: 997ffffd{{.*}}tt.storeind.mmio{{.*}}0x3f, 0x3f, 0x3, 0x7f
tt.storeind.mmio 63, 63, 3, 127

# CHECK-ASM: tt.storeind.src	63, 63, 3, 127, 1
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0xff,0x98]
# CHECK-DIS: 98fffffd{{.*}}tt.storeind.src{{.*}}0x3f, 0x3f, 0x3, 0x7f, 0x1
tt.storeind.src 63, 63, 3, 127, 1

# CHECK-ASM: tt.storereg	262143, 63
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0xff,0x9f]
# CHECK-DIS: 9ffffffd{{.*}}tt.storereg{{.*}}0x3ffff, 0x3f
tt.storereg 262143, 63

# CHECK-ASM: tt.subdmareg	63, 63, 63
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0x0f,0x64]
# CHECK-DIS: 640ffffd{{.*}}tt.subdmareg{{.*}}0x3f, 0x3f, 0x3f
tt.subdmareg 63, 63, 63

# CHECK-ASM: tt.subdmaregi	63, 63, 63
# CHECK-ASM-SAME: encoding: [0xfd,0xff,0x0f,0x66]
# CHECK-DIS: 660ffffd{{.*}}tt.subdmaregi{{.*}}0x3f, 0x3f, 0x3f
tt.subdmaregi 63, 63, 63

# CHECK-ASM: tt.trnspsrcb
# CHECK-ASM-SAME: encoding: [0x00,0x00,0x00,0x58]
# CHECK-DIS: 58000000{{.*}}tt.trnspsrcb
tt.trnspsrcb

# CHECK-ASM: tt.unpacr	1, 1, 1, 1, 1, 1, 1, 3, 7, 3, 3, 3, 3, 1
# CHECK-ASM-SAME: encoding: [0xf5,0x7f,0xfe,0x0b]
# CHECK-DIS: 0bfe7ff5{{.*}}tt.unpacr{{.*}}0x1, 0x1, 0x1, 0x1, 0x1, 0x1, 0x1, 0x3, 0x7, 0x3, 0x3, 0x3, 0x3, 0x1
tt.unpacr 1, 1, 1, 1, 1, 1, 1, 3, 7, 3, 3, 3, 3, 1

# CHECK-ASM: tt.unpacr.ctxinc	1
# CHECK-ASM-SAME: encoding: [0x01,0x80,0x00,0x0a]
# CHECK-DIS: 0a008001{{.*}}tt.unpacr.ctxinc{{.*}}0x1
tt.unpacr.ctxinc 1

# CHECK-ASM: tt.unpacr.flush	1, 1
# CHECK-ASM-SAME: encoding: [0x09,0x02,0x00,0x0a]
# CHECK-DIS: 0a000209{{.*}}tt.unpacr.flush{{.*}}0x1, 0x1
tt.unpacr.flush 1, 1

# CHECK-ASM: tt.unpacr_nop	31, 1
# CHECK-ASM-SAME: encoding: [0x7d,0x00,0x00,0x0e]
# CHECK-DIS: 0e00007d{{.*}}tt.unpacr_nop{{.*}}0x1f, 0x1
tt.unpacr_nop 31, 1

# CHECK-ASM: tt.wrcfg	2047, 1, 63
# CHECK-ASM-SAME: encoding: [0xfe,0x1f,0xfe,0xc0]
# CHECK-DIS: c0fe1ffe{{.*}}tt.wrcfg{{.*}}0x7ff, 0x1, 0x3f
tt.wrcfg 2047, 1, 63

# CHECK-ASM: tt.xmov
# CHECK-ASM-SAME: encoding: [0x01,0x00,0x00,0x00]
# CHECK-DIS: 00000001{{.*}}tt.xmov
tt.xmov

# CHECK-ASM: tt.zeroacc	1023, 3, 7
# CHECK-ASM-SAME: encoding: [0xfc,0x0f,0xe6,0x40]
# CHECK-DIS: 40e60ffc{{.*}}tt.zeroacc{{.*}}0x3ff, 0x3, 0x7
tt.zeroacc 1023, 3, 7

# CHECK-ASM: tt.zerosrc	1, 1, 1, 1, 1
# CHECK-ASM-SAME: encoding: [0x7c,0x00,0x00,0x44]
# CHECK-DIS: 4400007c{{.*}}tt.zerosrc{{.*}}0x1, 0x1, 0x1, 0x1, 0x1
tt.zerosrc 1, 1, 1, 1, 1
