; RUN: llc -mtriple=riscv32 -mattr=+experimental-xttensixwh < %s | FileCheck %s

; SFPU 2-address value ops (docs §11, m5 tail): and/or/xor and the set-field
; ops setexp_v/setman_v/setsgn_v. The instruction modifies its destination in
; place, so the first vector operand is tied to the result (in/out same lreg);
; the second operand is VC. Opcodes verified against binutils MATCH_* (and 0x7e,
; or 0x7f, xor 0x8d, setexp 0x82, setman 0x83, setsgn 0x89).

declare <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 immarg, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpand(<32 x i32>, <32 x i32>)
declare <32 x i32> @llvm.riscv.rvtt.sfpor(<32 x i32>, <32 x i32>)
declare <32 x i32> @llvm.riscv.rvtt.sfpxor(<32 x i32>, <32 x i32>)
declare <32 x i32> @llvm.riscv.rvtt.sfpsetexp.v(<32 x i32>, <32 x i32>, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpsetman.v(<32 x i32>, <32 x i32>, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpsetsgn.v(<32 x i32>, <32 x i32>, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpiadd.v(<32 x i32>, <32 x i32>, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpshft.v(<32 x i32>, <32 x i32>, i32 immarg)
declare void @llvm.riscv.rvtt.sfpstore(<32 x i32>, i32 immarg, i32 immarg, i32 immarg)

; and/or/xor: the first operand (%a) is tied to the dest, so the result lreg
; equals %a's lreg, and the asm shows just dest + VC.
; CHECK-LABEL: logical:
; CHECK:         tt.sfpand [[A:lreg[0-9]+]], lreg{{[0-9]+}}
; CHECK:         tt.sfpor [[A]], lreg{{[0-9]+}}
; CHECK:         tt.sfpxor [[A]], lreg{{[0-9]+}}
; CHECK:         tt.sfpstore 0, 0, 3, [[A]]
define void @logical() {
  %a = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 1, i32 0)
  %b = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 2, i32 0)
  %x = call <32 x i32> @llvm.riscv.rvtt.sfpand(<32 x i32> %a, <32 x i32> %b)
  %y = call <32 x i32> @llvm.riscv.rvtt.sfpor(<32 x i32> %x, <32 x i32> %b)
  %z = call <32 x i32> @llvm.riscv.rvtt.sfpxor(<32 x i32> %y, <32 x i32> %b)
  call void @llvm.riscv.rvtt.sfpstore(<32 x i32> %z, i32 0, i32 0, i32 3)
  ret void
}

; set-field ops: value tied to dest, VC is the field source, mode + zero imm.
; CHECK-LABEL: setfield:
; CHECK:         tt.sfpsetexp 0, [[V:lreg[0-9]+]], lreg{{[0-9]+}}, 0
; CHECK:         tt.sfpsetman 0, [[V]], lreg{{[0-9]+}}, 0
; CHECK:         tt.sfpsetsgn 0, [[V]], lreg{{[0-9]+}}, 0
; CHECK:         tt.sfpstore 0, 0, 3, [[V]]
define void @setfield() {
  %v = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 1, i32 0)
  %f = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 2, i32 0)
  %e = call <32 x i32> @llvm.riscv.rvtt.sfpsetexp.v(<32 x i32> %v, <32 x i32> %f, i32 0)
  %m = call <32 x i32> @llvm.riscv.rvtt.sfpsetman.v(<32 x i32> %e, <32 x i32> %f, i32 0)
  %s = call <32 x i32> @llvm.riscv.rvtt.sfpsetsgn.v(<32 x i32> %m, <32 x i32> %f, i32 0)
  call void @llvm.riscv.rvtt.sfpstore(<32 x i32> %s, i32 0, i32 0, i32 3)
  ret void
}

; integer add (vector) and shift (vector amount): same 2-address tie, with mode.
; CHECK-LABEL: iadd_shft:
; CHECK:         tt.sfpiadd 4, [[A:lreg[0-9]+]], lreg{{[0-9]+}}, 0
; CHECK:         tt.sfpshft 0, [[A]], lreg{{[0-9]+}}, 0
; CHECK:         tt.sfpstore 0, 0, 3, [[A]]
define void @iadd_shft() {
  %a = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 1, i32 0)
  %b = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 2, i32 0)
  %s = call <32 x i32> @llvm.riscv.rvtt.sfpiadd.v(<32 x i32> %a, <32 x i32> %b, i32 4)
  %t = call <32 x i32> @llvm.riscv.rvtt.sfpshft.v(<32 x i32> %s, <32 x i32> %b, i32 0)
  call void @llvm.riscv.rvtt.sfpstore(<32 x i32> %t, i32 0, i32 0, i32 3)
  ret void
}
