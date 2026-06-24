; RUN: llc -mtriple=riscv32 -mattr=+experimental-xttensixwh < %s | FileCheck %s

; SFPU immediate-operand value ops (docs §11): vec + immediate + mode. The
; fresh-dest forms (iadd_i/setexp_i/setman_i/setsgn_i) put the value in VC and
; the immediate in the field; muli/addi are 2-address (value tied to dest).

declare <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 immarg, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpiadd.i(<32 x i32>, i32 immarg, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpsetexp.i(<32 x i32>, i32 immarg, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpsetman.i(<32 x i32>, i32 immarg, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpsetsgn.i(<32 x i32>, i32 immarg, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpmuli(<32 x i32>, i32 immarg, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpaddi(<32 x i32>, i32 immarg, i32 immarg)
declare void @llvm.riscv.rvtt.sfpnop()
declare void @llvm.riscv.rvtt.sfpstore(<32 x i32>, i32 immarg, i32 immarg, i32 immarg)

; CHECK-LABEL: imm_ops:
; CHECK:         tt.sfpiadd 1, lreg{{[0-9]+}}, lreg{{[0-9]+}}, 127
; CHECK:         tt.sfpsetexp 0, lreg{{[0-9]+}}, lreg{{[0-9]+}}, 130
; CHECK:         tt.sfpsetman 0, lreg{{[0-9]+}}, lreg{{[0-9]+}}, 5
; CHECK:         tt.sfpsetsgn 0, lreg{{[0-9]+}}, lreg{{[0-9]+}}, 1
; CHECK:         tt.sfpmuli 0, [[R:lreg[0-9]+]], 16256
; CHECK:         tt.sfpaddi 0, [[R]], 16256
; CHECK:         tt.sfpnop
define void @imm_ops() {
  %x = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 1, i32 0)
  %a = call <32 x i32> @llvm.riscv.rvtt.sfpiadd.i(<32 x i32> %x, i32 127, i32 1)
  %b = call <32 x i32> @llvm.riscv.rvtt.sfpsetexp.i(<32 x i32> %a, i32 130, i32 0)
  %c = call <32 x i32> @llvm.riscv.rvtt.sfpsetman.i(<32 x i32> %b, i32 5, i32 0)
  %d = call <32 x i32> @llvm.riscv.rvtt.sfpsetsgn.i(<32 x i32> %c, i32 1, i32 0)
  %e = call <32 x i32> @llvm.riscv.rvtt.sfpmuli(<32 x i32> %d, i32 16256, i32 0)
  %f = call <32 x i32> @llvm.riscv.rvtt.sfpaddi(<32 x i32> %e, i32 16256, i32 0)
  call void @llvm.riscv.rvtt.sfpnop()
  call void @llvm.riscv.rvtt.sfpstore(<32 x i32> %f, i32 0, i32 0, i32 3)
  ret void
}
