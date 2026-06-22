; RUN: llc -mtriple=riscv32 -mattr=+experimental-xttensixwh < %s | FileCheck %s

; SFPU compile-time-address load/store (docs §11, m5 tail). sfpload produces a
; fresh L-register from an L1/dest offset; sfpstore writes one back. Field
; layout from binutils (J20 reg, J0 s14 addr, J16 mode, J14 u2). The
; runtime-address form (synthesized word issued via the FIFO) is deferred.

declare <32 x i32> @llvm.riscv.rvtt.sfpload(i32 immarg, i32 immarg, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpmov(<32 x i32>, i32 immarg)
declare void @llvm.riscv.rvtt.sfpstore(<32 x i32>, i32 immarg, i32 immarg, i32 immarg)

; load from offset 4, move, store to offset 8.
; CHECK-LABEL: load_store:
; CHECK:         tt.sfpload 4, 0, 0, [[R:lreg[0-9]+]]
; CHECK:         tt.sfpmov 0, lreg{{[0-9]+}}, [[R]]
; CHECK:         tt.sfpstore 8, 0, 3, lreg{{[0-9]+}}
define void @load_store() {
  %v = call <32 x i32> @llvm.riscv.rvtt.sfpload(i32 4, i32 0, i32 0)
  %m = call <32 x i32> @llvm.riscv.rvtt.sfpmov(<32 x i32> %v, i32 0)
  call void @llvm.riscv.rvtt.sfpstore(<32 x i32> %m, i32 8, i32 0, i32 3)
  ret void
}

; negative offset exercises the signed 14-bit address field.
; CHECK-LABEL: neg_offset:
; CHECK:         tt.sfpload -3, 0, 0, lreg{{[0-9]+}}
define void @neg_offset() {
  %v = call <32 x i32> @llvm.riscv.rvtt.sfpload(i32 -3, i32 0, i32 0)
  call void @llvm.riscv.rvtt.sfpstore(<32 x i32> %v, i32 0, i32 0, i32 3)
  ret void
}
