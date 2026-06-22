; RUN: llc -mtriple=riscv32 -mattr=+experimental-xttensixwh < %s | FileCheck %s

; SFPU vector2 tuple op (docs §11, m5 tail): sfpswap updates two L-registers in
; place (min/max/swap by mode) and returns both (SFPI's __xtt_vector2). The
; select2 extraction is a plain extractvalue on the {v32i32,v32i32} result. Both
; outputs are tied to their inputs, so each result reuses its source register.
; Opcode 0x92.

declare <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 immarg, i32 immarg)
declare {<32 x i32>, <32 x i32>} @llvm.riscv.rvtt.sfpswap(<32 x i32>, <32 x i32>, i32 immarg)
declare void @llvm.riscv.rvtt.sfpstore(<32 x i32>, i32 immarg, i32 immarg, i32 immarg)

; CHECK-LABEL: swap:
; CHECK:         tt.sfploadi 1, 0, [[A:lreg[0-9]+]]
; CHECK:         tt.sfploadi 2, 0, [[B:lreg[0-9]+]]
; CHECK:         tt.sfpswap 1, [[A]], [[B]]
; CHECK:         tt.sfpstore 0, 0, 3, [[A]]
; CHECK:         tt.sfpstore 0, 0, 3, [[B]]
define void @swap() {
  %a = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 1, i32 0)
  %b = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 2, i32 0)
  %r = call {<32 x i32>, <32 x i32>} @llvm.riscv.rvtt.sfpswap(<32 x i32> %a, <32 x i32> %b, i32 1)
  %lo = extractvalue {<32 x i32>, <32 x i32>} %r, 0
  %hi = extractvalue {<32 x i32>, <32 x i32>} %r, 1
  call void @llvm.riscv.rvtt.sfpstore(<32 x i32> %lo, i32 0, i32 0, i32 3)
  call void @llvm.riscv.rvtt.sfpstore(<32 x i32> %hi, i32 0, i32 0, i32 3)
  ret void
}
