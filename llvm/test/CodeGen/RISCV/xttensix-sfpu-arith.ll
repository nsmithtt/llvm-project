; RUN: llc -mtriple=riscv32 -mattr=+experimental-xttensixwh < %s | FileCheck %s

; SFPU float arithmetic value ops (docs §11, m2): mad/mul/add and their _lv
; predicated-update variants. SFPU datapath: mad = a*b+c (VA,VB,VC); mul = a*b
; with the +c term reading const Lreg9; add = a+b with the *a term reading
; const Lreg10. The _lv form ties its live operand to the dest register.

declare <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 immarg, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpmad(<32 x i32>, <32 x i32>, <32 x i32>, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpmad.lv(<32 x i32>, <32 x i32>, <32 x i32>, <32 x i32>, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpmul(<32 x i32>, <32 x i32>, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpadd(<32 x i32>, <32 x i32>, i32 immarg)
declare void @llvm.riscv.rvtt.sfpstore(<32 x i32>, i32 immarg, i32 immarg, i32 immarg)

; d = a*b + c, stored.
; CHECK-LABEL: mad:
; CHECK:         tt.sfploadi 1, 0, lreg0
; CHECK:         tt.sfploadi 2, 0, lreg1
; CHECK:         tt.sfploadi 3, 0, lreg2
; CHECK:         tt.sfpmad 0, lreg{{[0-9]+}}, lreg2, lreg1, lreg0
; CHECK:         tt.sfpstore
define void @mad() {
  %a = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 1, i32 0)
  %b = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 2, i32 0)
  %c = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 3, i32 0)
  %d = call <32 x i32> @llvm.riscv.rvtt.sfpmad(<32 x i32> %a, <32 x i32> %b, <32 x i32> %c, i32 0)
  call void @llvm.riscv.rvtt.sfpstore(<32 x i32> %d, i32 0, i32 0, i32 3)
  ret void
}

; mul: only two source regs; the +c term is the hardwired const Lreg9.
; CHECK-LABEL: mul:
; CHECK:         tt.sfpmul 0, lreg{{[0-9]+}}, lreg1, lreg0
define void @mul() {
  %a = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 1, i32 0)
  %b = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 2, i32 0)
  %d = call <32 x i32> @llvm.riscv.rvtt.sfpmul(<32 x i32> %a, <32 x i32> %b, i32 0)
  call void @llvm.riscv.rvtt.sfpstore(<32 x i32> %d, i32 0, i32 0, i32 3)
  ret void
}

; add: two source regs; the *a term is the hardwired const Lreg10.
; CHECK-LABEL: add:
; CHECK:         tt.sfpadd 0, lreg{{[0-9]+}}, lreg1, lreg0
define void @add() {
  %a = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 1, i32 0)
  %b = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 2, i32 0)
  %d = call <32 x i32> @llvm.riscv.rvtt.sfpadd(<32 x i32> %a, <32 x i32> %b, i32 0)
  call void @llvm.riscv.rvtt.sfpstore(<32 x i32> %d, i32 0, i32 0, i32 3)
  ret void
}

; _lv: the live (accumulator) value must be tied to the mad dest -- same lreg in
; and out.
; CHECK-LABEL: mad_lv:
; CHECK:         tt.sfpmad 0, [[ACC:lreg[0-9]+]], lreg{{[0-9]+}}, lreg{{[0-9]+}}, lreg{{[0-9]+}}
; CHECK:         tt.sfpstore 0, 0, 3, [[ACC]]
define void @mad_lv() {
  %acc = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 9, i32 0)
  %a = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 1, i32 0)
  %b = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 2, i32 0)
  %c = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 3, i32 0)
  %d = call <32 x i32> @llvm.riscv.rvtt.sfpmad.lv(<32 x i32> %acc, <32 x i32> %a, <32 x i32> %b, <32 x i32> %c, i32 0)
  call void @llvm.riscv.rvtt.sfpstore(<32 x i32> %d, i32 0, i32 0, i32 3)
  ret void
}
