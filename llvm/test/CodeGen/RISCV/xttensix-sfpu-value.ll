; RUN: llc -mtriple=riscv32 -mattr=+experimental-xttensixwh < %s | FileCheck %s

; SFPU value-semantics path (docs/tensix-backend.md §11): SFPI's
; __builtin_rvtt_sfp* builtins map to value intrinsics over the 32-lane
; __xtt_vector (v32i32 = one SFPU L-register). The L-registers are a register
; class the allocator fills in, unlike the instruction-level int_riscv_tt_sfp*
; forms which take Lreg indices as immediates.

declare <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 immarg, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpmov(<32 x i32>, i32 immarg)
declare void @llvm.riscv.rvtt.sfpstore(<32 x i32>, i32 immarg, i32 immarg, i32 immarg)

; A linear chain reuses a single L-register.
; CHECK-LABEL: round_trip:
; CHECK:         tt.sfploadi 1, 0, lreg0
; CHECK-NEXT:    tt.sfpmov 0, lreg0, lreg0
; CHECK-NEXT:    tt.sfpstore 0, 0, 3, lreg0
define void @round_trip() {
  %a = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 1, i32 0)
  %m = call <32 x i32> @llvm.riscv.rvtt.sfpmov(<32 x i32> %a, i32 0)
  call void @llvm.riscv.rvtt.sfpstore(<32 x i32> %m, i32 0, i32 0, i32 3)
  ret void
}

; Two values live simultaneously must land in distinct L-registers; the dead
; source may be reused.
; CHECK-LABEL: two_live:
; CHECK:         tt.sfploadi 1, 0, lreg0
; CHECK-NEXT:    tt.sfploadi 2, 0, lreg1
; CHECK-NEXT:    tt.sfpmov 0, lreg0, lreg0
; CHECK-NEXT:    tt.sfpstore 0, 0, 3, lreg0
; CHECK-NEXT:    tt.sfpstore 0, 0, 3, lreg1
define void @two_live() {
  %a = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 1, i32 0)
  %b = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 2, i32 0)
  %m = call <32 x i32> @llvm.riscv.rvtt.sfpmov(<32 x i32> %a, i32 0)
  call void @llvm.riscv.rvtt.sfpstore(<32 x i32> %m, i32 0, i32 0, i32 3)
  call void @llvm.riscv.rvtt.sfpstore(<32 x i32> %b, i32 0, i32 0, i32 3)
  ret void
}
