; RUN: llc -mtriple=riscv32 -mattr=+experimental-xttensixwh < %s | FileCheck %s

; SFPU unary value ops (docs §11, m4): abs/lz/exexp/exman/cast/not. Same operand
; layout as sfpmov (VD = op(VC, mod)); sfpnot has no mode. Opcodes verified
; against binutils MATCH_* (abs 0x7d, lz 0x81, exexp 0x77, exman 0x78,
; cast 0x90, not 0x80).

declare <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 immarg, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpabs(<32 x i32>, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfplz(<32 x i32>, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpexexp(<32 x i32>, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpexman(<32 x i32>, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpcast(<32 x i32>, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpnot(<32 x i32>)
declare void @llvm.riscv.rvtt.sfpstore(<32 x i32>, i32 immarg, i32 immarg, i32 immarg)

; CHECK-LABEL: unary:
; CHECK:         tt.sfpabs 3, lreg{{[0-9]+}}, lreg0
; CHECK:         tt.sfplz 0, lreg{{[0-9]+}}, lreg{{[0-9]+}}
; CHECK:         tt.sfpexexp 0, lreg{{[0-9]+}}, lreg{{[0-9]+}}
; CHECK:         tt.sfpexman 0, lreg{{[0-9]+}}, lreg{{[0-9]+}}
; CHECK:         tt.sfpcast 0, lreg{{[0-9]+}}, lreg{{[0-9]+}}
; CHECK:         tt.sfpnot lreg{{[0-9]+}}, lreg{{[0-9]+}}
define void @unary() {
  %x = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 1, i32 0)
  %a = call <32 x i32> @llvm.riscv.rvtt.sfpabs(<32 x i32> %x, i32 3)
  %b = call <32 x i32> @llvm.riscv.rvtt.sfplz(<32 x i32> %a, i32 0)
  %c = call <32 x i32> @llvm.riscv.rvtt.sfpexexp(<32 x i32> %b, i32 0)
  %d = call <32 x i32> @llvm.riscv.rvtt.sfpexman(<32 x i32> %c, i32 0)
  %e = call <32 x i32> @llvm.riscv.rvtt.sfpcast(<32 x i32> %d, i32 0)
  %f = call <32 x i32> @llvm.riscv.rvtt.sfpnot(<32 x i32> %e)
  call void @llvm.riscv.rvtt.sfpstore(<32 x i32> %f, i32 0, i32 0, i32 3)
  ret void
}
