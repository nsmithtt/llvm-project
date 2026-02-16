# RUN: llvm-mc %s -triple=riscv32 -mattr=+experimental-xttensix -show-encoding \
# RUN:     | FileCheck -check-prefixes=CHECK-ASM %s
# RUN: not llvm-mc %s -triple=riscv32 2>&1 \
# RUN:     | FileCheck -check-prefix=CHECK-NO-EXT %s

# Test basic ttinsn instruction encoding
# The encoding is the 32-bit immediate rotated left by 2 bits
# Encoding formula: Inst = (imm{29-0} << 2) | imm{31-30}

# 0x02000000 -> encoded as 0x08000000
# CHECK-ASM: ttinsn 33554432
# CHECK-ASM: encoding: [0x00,0x00,0x00,0x08]
# CHECK-NO-EXT: error: instruction requires the following: 'XTTensix' (Tenstorrent Tensix accelerator interface)
ttinsn 0x02000000

# 0x26000000 -> encoded as 0x98000000
# CHECK-ASM: ttinsn 637534208
# CHECK-ASM: encoding: [0x00,0x00,0x00,0x98]
ttinsn 0x26000000

#===----------------------------------------------------------------------===#
# Frontend/Control Instructions
#===----------------------------------------------------------------------===#

# CHECK-ASM: tt.nop
# CHECK-ASM: encoding: [0x00,0x00,0x00,0x08]
# CHECK-NO-EXT: error: instruction requires the following: 'XTTensix' (Tenstorrent Tensix accelerator interface)
tt.nop

# CHECK-ASM: tt.mop 4660, 10, 1
# CHECK-ASM: encoding: [0xd0,0x48,0x28,0x06]
tt.mop 4660, 10, 1

# CHECK-ASM: tt.mop_cfg 4660
# CHECK-ASM: encoding: [0xd0,0x48,0x00,0x0c]
tt.mop_cfg 4660

# CHECK-ASM: tt.replay 1, 1, 15, 5
# CHECK-ASM: encoding: [0xcc,0x03,0x05,0x10]
tt.replay 1, 1, 15, 5

#===----------------------------------------------------------------------===#
# Matrix Unit (FPU) Instructions
#===----------------------------------------------------------------------===#

# CHECK-ASM: tt.mvmul 5, 2, 1, 0, 1
# CHECK-ASM: encoding: [0x14,0x00,0x24,0x9a]
tt.mvmul 5, 2, 1, 0, 1

# CHECK-ASM: tt.elwmul 5, 2, 1, 1, 0, 1
# CHECK-ASM: encoding: [0x14,0x00,0x64,0x9e]
tt.elwmul 5, 2, 1, 1, 0, 1

# CHECK-ASM: tt.elwadd 5, 2, 1, 1, 0, 0, 1
# CHECK-ASM: encoding: [0x14,0x00,0x64,0xa2]
tt.elwadd 5, 2, 1, 1, 0, 0, 1

# CHECK-ASM: tt.dotpv 5, 2, 0, 1
# CHECK-ASM: encoding: [0x14,0x00,0x04,0xa6]
tt.dotpv 5, 2, 0, 1

# CHECK-ASM: tt.elwsub 5, 2, 1, 1, 0, 0, 1
# CHECK-ASM: encoding: [0x14,0x00,0x64,0xc2]
tt.elwsub 5, 2, 1, 1, 0, 0, 1

# CHECK-ASM: tt.gmpool 5, 1, 2, 0, 1
# CHECK-ASM: encoding: [0x14,0x00,0x05,0xce]
tt.gmpool 5, 1, 2, 0, 1

# CHECK-ASM: tt.gapool 5, 2, 0, 1
# CHECK-ASM: encoding: [0x14,0x00,0x04,0xd2]
tt.gapool 5, 2, 0, 1

#===----------------------------------------------------------------------===#
# Data Movement Instructions
#===----------------------------------------------------------------------===#

# CHECK-ASM: tt.movd2a 5, 1, 2, 10, 1
# CHECK-ASM: encoding: [0x14,0x80,0x54,0x22]
tt.movd2a 5, 1, 2, 10, 1

# CHECK-ASM: tt.movdbga2d 5, 1, 2, 10, 1
# CHECK-ASM: encoding: [0x14,0x80,0x54,0x26]
tt.movdbga2d 5, 1, 2, 10, 1

# CHECK-ASM: tt.movd2b 5, 1, 2, 10, 1
# CHECK-ASM: encoding: [0x14,0x80,0x54,0x2a]
tt.movd2b 5, 1, 2, 10, 1

# CHECK-ASM: tt.movb2a 5, 1, 2, 10
# CHECK-ASM: encoding: [0x14,0x80,0x54,0x2c]
tt.movb2a 5, 1, 2, 10

# CHECK-ASM: tt.zeroacc 100, 2, 1, 1, 0
# CHECK-ASM: encoding: [0x90,0x01,0x34,0x40]
tt.zeroacc 100, 2, 1, 1, 0

# CHECK-ASM: tt.zerosrc 1, 1, 0, 0, 1
# CHECK-ASM: encoding: [0x4c,0x00,0x00,0x44]
tt.zerosrc 1, 1, 0, 0, 1

# CHECK-ASM: tt.mova2d 5, 1, 2, 10, 1
# CHECK-ASM: encoding: [0x14,0x80,0x54,0x4a]
tt.mova2d 5, 1, 2, 10, 1

# CHECK-ASM: tt.trnspsrcb
# CHECK-ASM: encoding: [0x00,0x00,0x00,0x58]
tt.trnspsrcb

# CHECK-ASM: tt.shiftxa 2
# CHECK-ASM: encoding: [0x08,0x00,0x00,0x5c]
tt.shiftxa 2

# CHECK-ASM: tt.clrexphist
# CHECK-ASM: encoding: [0x00,0x00,0x00,0x84]
tt.clrexphist

#===----------------------------------------------------------------------===#
# Unpacker/Misc Instructions
#===----------------------------------------------------------------------===#

# CHECK-ASM: tt.setrwc 1, 0, 1, 0, 5, 3, 7, 1, 0, 1, 0, 0, 1
# CHECK-ASM: encoding: [0x14,0x35,0x57,0xde]
tt.setrwc 1, 0, 1, 0, 5, 3, 7, 1, 0, 1, 0, 0, 1

#===----------------------------------------------------------------------===#
# Configuration Instructions
#===----------------------------------------------------------------------===#

# CHECK-ASM: tt.setdmareg 10, 4660
# CHECK-ASM: encoding: [0x29,0xd0,0x48,0x14]
tt.setdmareg 10, 4660

# CHECK-ASM: tt.loadind 5, 10, 3, 20, 2
# CHECK-ASM: encoding: [0x15,0xca,0x14,0x26]
tt.loadind 5, 10, 3, 20, 2

# CHECK-ASM: tt.setadc 262143, 3, 1, 1, 1, 1
# CHECK-ASM: encoding: [0xfd,0xff,0xff,0x43]
tt.setadc 262143, 3, 1, 1, 1, 1

# CHECK-ASM: tt.setc16 43981, 18
# CHECK-ASM: encoding: [0x36,0xaf,0x4a,0xc8]
tt.setc16 43981, 18

# CHECK-ASM: tt.wrcfg 100, 1, 5
# CHECK-ASM: encoding: [0x92,0x01,0x16,0xc0]
tt.wrcfg 100, 1, 5

# CHECK-ASM: tt.rdcfg 100, 5
# CHECK-ASM: encoding: [0x92,0x01,0x14,0xc4]
tt.rdcfg 100, 5

#===----------------------------------------------------------------------===#
# DMA Register Arithmetic Instructions
#===----------------------------------------------------------------------===#

# CHECK-ASM: tt.adddmareg 10, 20, 30
# CHECK-ASM: encoding: [0x29,0x94,0x07,0x60]
tt.adddmareg 10, 20, 30

# CHECK-ASM: tt.subdmareg 10, 20, 30
# CHECK-ASM: encoding: [0x29,0x94,0x07,0x64]
tt.subdmareg 10, 20, 30

# CHECK-ASM: tt.muldmareg 10, 20, 30
# CHECK-ASM: encoding: [0x29,0x94,0x07,0x68]
tt.muldmareg 10, 20, 30

#===----------------------------------------------------------------------===#
# DMA/Sync Instructions
#===----------------------------------------------------------------------===#

# CHECK-ASM: tt.flushdma 5
# CHECK-ASM: encoding: [0x15,0x00,0x00,0x18]
tt.flushdma 5

# CHECK-ASM: tt.dmanop
# CHECK-ASM: encoding: [0x01,0x00,0x00,0x80]
tt.dmanop

#===----------------------------------------------------------------------===#
# Indirect Memory Instructions
#===----------------------------------------------------------------------===#

# CHECK-ASM: tt.storereg 4660, 5
# CHECK-ASM: encoding: [0xd1,0x48,0x50,0x9c]
tt.storereg 4660, 5

# CHECK-ASM: tt.loadreg 4660, 5
# CHECK-ASM: encoding: [0xd1,0x48,0x50,0xa0]
tt.loadreg 4660, 5

#===----------------------------------------------------------------------===#
# Sync/Semaphore Instructions
#===----------------------------------------------------------------------===#

# CHECK-ASM: tt.stallwait 100, 3
# CHECK-ASM: encoding: [0x92,0x01,0x06,0x88]
tt.stallwait 100, 3

# CHECK-ASM: tt.seminit 255, 10, 15
# CHECK-ASM: encoding: [0xf2,0x0f,0xe8,0x8f]
tt.seminit 255, 10, 15

#===----------------------------------------------------------------------===#
# SFPU Instructions
#===----------------------------------------------------------------------===#

# CHECK-ASM: tt.sfpload 100, 3, 5, 10
# CHECK-ASM: encoding: [0x91,0x01,0x97,0xc2]
tt.sfpload 100, 3, 5, 10

# CHECK-ASM: tt.sfploadi 43981, 5, 10
# CHECK-ASM: encoding: [0x35,0xaf,0x96,0xc6]
tt.sfploadi 43981, 5, 10

# CHECK-ASM: tt.sfpstore 100, 3, 5, 10
# CHECK-ASM: encoding: [0x91,0x01,0x97,0xca]
tt.sfpstore 100, 3, 5, 10

# CHECK-ASM: tt.sfpmad 3, 7, 2, 5, 9
# CHECK-ASM: encoding: [0xce,0x49,0x25,0x10]
tt.sfpmad 3, 7, 2, 5, 9

# CHECK-ASM: tt.sfpadd 3, 7, 2, 5, 9
# CHECK-ASM: encoding: [0xce,0x49,0x25,0x14]
tt.sfpadd 3, 7, 2, 5, 9

# CHECK-ASM: tt.sfpmul 3, 7, 2, 5, 9
# CHECK-ASM: encoding: [0xce,0x49,0x25,0x18]
tt.sfpmul 3, 7, 2, 5, 9

# CHECK-ASM: tt.sfpnop
# CHECK-ASM: encoding: [0x02,0x00,0x00,0x3c]
tt.sfpnop

# CHECK-ASM: tt.sfpmov 3, 7, 2
# CHECK-ASM: encoding: [0xcd,0x09,0x00,0xf0]
tt.sfpmov 3, 7, 2

# CHECK-ASM: tt.sfpabs 3, 7, 2
# CHECK-ASM: encoding: [0xcd,0x09,0x00,0xf4]
tt.sfpabs 3, 7, 2

#===----------------------------------------------------------------------===#
# Zero-operand aliases (backward compatibility)
#===----------------------------------------------------------------------===#

# CHECK-ASM: tt.mvmul
# CHECK-ASM: encoding: [0x00,0x00,0x00,0x98]
tt.mvmul

# CHECK-ASM: tt.elwmul
# CHECK-ASM: encoding: [0x00,0x00,0x00,0x9c]
tt.elwmul

# CHECK-ASM: tt.elwadd
# CHECK-ASM: encoding: [0x00,0x00,0x00,0xa0]
tt.elwadd

# CHECK-ASM: tt.elwsub
# CHECK-ASM: encoding: [0x00,0x00,0x00,0xc0]
tt.elwsub

# CHECK-ASM: tt.movd2a
# CHECK-ASM: encoding: [0x00,0x00,0x00,0x20]
tt.movd2a

# CHECK-ASM: tt.zeroacc
# CHECK-ASM: encoding: [0x00,0x00,0x00,0x40]
tt.zeroacc

# CHECK-ASM: tt.flushdma
# CHECK-ASM: encoding: [0x01,0x00,0x00,0x18]
tt.flushdma

# CHECK-ASM: tt.dmanop
# CHECK-ASM: encoding: [0x01,0x00,0x00,0x80]
tt.dmanop
