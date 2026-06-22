; RUN: llc -mtriple=riscv32 -mattr=+experimental-xttensixwh < %s | FileCheck %s

; SFPU vector calling convention (docs §11): __xtt_vector (v32i32) is passed and
; returned in the general-purpose L-registers L0..L7. This lets SFPU vectors
; cross (non-inlined) function boundaries, which previously aborted in CC_RISCV.

declare <32 x i32> @llvm.riscv.rvtt.sfpabs(<32 x i32>, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpmad(<32 x i32>, <32 x i32>, <32 x i32>, i32 immarg)
declare void @llvm.riscv.rvtt.sfpstore(<32 x i32>, i32 immarg, i32 immarg, i32 immarg)

; First vector arg in L0, result returned in L0.
; CHECK-LABEL: absify:
; CHECK:         tt.sfpabs 3, lreg0, lreg0
; CHECK:         ret
define <32 x i32> @absify(<32 x i32> %a) {
  %r = call <32 x i32> @llvm.riscv.rvtt.sfpabs(<32 x i32> %a, i32 3)
  ret <32 x i32> %r
}

; Three vector args land in L0/L1/L2; result in L0.
; CHECK-LABEL: madify:
; CHECK:         tt.sfpmad 0, lreg0, lreg2, lreg1, lreg0
define <32 x i32> @madify(<32 x i32> %a, <32 x i32> %b, <32 x i32> %c) {
  %r = call <32 x i32> @llvm.riscv.rvtt.sfpmad(<32 x i32> %a, <32 x i32> %b, <32 x i32> %c, i32 0)
  ret <32 x i32> %r
}

; Caller passes a vector in L0 and stores the returned vector (also L0).
; CHECK-LABEL: use:
; CHECK:         call absify
; CHECK:         tt.sfpstore 0, 0, 3, lreg0
define void @use(<32 x i32> %x) {
  %r = call <32 x i32> @absify(<32 x i32> %x)
  call void @llvm.riscv.rvtt.sfpstore(<32 x i32> %r, i32 0, i32 0, i32 3)
  ret void
}
