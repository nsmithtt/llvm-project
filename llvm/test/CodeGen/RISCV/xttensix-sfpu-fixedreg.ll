; RUN: llc -mtriple=riscv32 -mattr=+experimental-xttensixwh < %s | FileCheck %s

; SFPU fixed-L-register ops (docs §11, m5 tail): sfplut and sfptransp read/write
; specific L-registers (the instruction encodes no register operands, or only a
; dest). Single-register operand classes pin the inputs to L0..L3; the allocator
; inserts the copies. sfplut writes L3; sfptransp transposes L0..L3 in place.

declare <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 immarg, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfplut(<32 x i32>, <32 x i32>, <32 x i32>, <32 x i32>, i32 immarg)
declare {<32 x i32>, <32 x i32>, <32 x i32>, <32 x i32>} @llvm.riscv.rvtt.sfptransp(<32 x i32>, <32 x i32>, <32 x i32>, <32 x i32>)
declare void @llvm.riscv.rvtt.sfpstore(<32 x i32>, i32 immarg, i32 immarg, i32 immarg)

; lut: inputs land in L0/L1/L2/L3, dest is L3.
; CHECK-LABEL: lut:
; CHECK:         tt.sfplut 0, lreg3
; CHECK:         tt.sfpstore 0, 0, 3, lreg3
define void @lut() {
  %a = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 1, i32 0)
  %b = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 2, i32 0)
  %c = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 3, i32 0)
  %d = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 4, i32 0)
  %r = call <32 x i32> @llvm.riscv.rvtt.sfplut(<32 x i32> %a, <32 x i32> %b, <32 x i32> %c, <32 x i32> %d, i32 0)
  call void @llvm.riscv.rvtt.sfpstore(<32 x i32> %r, i32 0, i32 0, i32 3)
  ret void
}

; transp: four results come back in L0..L3 (in place).
; CHECK-LABEL: transp:
; CHECK:         tt.sfptransp
; CHECK:         tt.sfpstore 0, 0, 3, lreg0
; CHECK:         tt.sfpstore 0, 0, 3, lreg1
; CHECK:         tt.sfpstore 0, 0, 3, lreg2
; CHECK:         tt.sfpstore 0, 0, 3, lreg3
define void @transp() {
  %a = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 1, i32 0)
  %b = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 2, i32 0)
  %c = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 3, i32 0)
  %d = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 4, i32 0)
  %r = call {<32 x i32>, <32 x i32>, <32 x i32>, <32 x i32>} @llvm.riscv.rvtt.sfptransp(<32 x i32> %a, <32 x i32> %b, <32 x i32> %c, <32 x i32> %d)
  %r0 = extractvalue {<32 x i32>, <32 x i32>, <32 x i32>, <32 x i32>} %r, 0
  %r1 = extractvalue {<32 x i32>, <32 x i32>, <32 x i32>, <32 x i32>} %r, 1
  %r2 = extractvalue {<32 x i32>, <32 x i32>, <32 x i32>, <32 x i32>} %r, 2
  %r3 = extractvalue {<32 x i32>, <32 x i32>, <32 x i32>, <32 x i32>} %r, 3
  call void @llvm.riscv.rvtt.sfpstore(<32 x i32> %r0, i32 0, i32 0, i32 3)
  call void @llvm.riscv.rvtt.sfpstore(<32 x i32> %r1, i32 0, i32 0, i32 3)
  call void @llvm.riscv.rvtt.sfpstore(<32 x i32> %r2, i32 0, i32 0, i32 3)
  call void @llvm.riscv.rvtt.sfpstore(<32 x i32> %r3, i32 0, i32 0, i32 3)
  ret void
}
