; RUN: llc -mtriple=riscv32 -mattr=+experimental-xttensixwh < %s | FileCheck %s

; SFPU CC (lane-enable) stack control (docs §11, m3). The control ops are
; side-effecting barriers; value ops read the abstract CC state, so a predicated
; update stays fenced between the setcc/pushc and popc that gate it.

declare <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 immarg, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpmov(<32 x i32>, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpmad.lv(<32 x i32>, <32 x i32>, <32 x i32>, <32 x i32>, i32 immarg)
declare void @llvm.riscv.rvtt.sfpstore(<32 x i32>, i32 immarg, i32 immarg, i32 immarg)
declare void @llvm.riscv.rvtt.sfpsetcc.v(<32 x i32>, i32 immarg)
declare void @llvm.riscv.rvtt.sfpsetcc.i(i32 immarg, i32 immarg)
declare void @llvm.riscv.rvtt.sfpencc(i32 immarg, i32 immarg)
declare void @llvm.riscv.rvtt.sfppushc(i32 immarg)
declare void @llvm.riscv.rvtt.sfppopc(i32 immarg)
declare void @llvm.riscv.rvtt.sfpcompc()

; A lane-predicated accumulate: pushc; setcc from a vector; mad_lv (only enabled
; lanes update, others keep acc); popc. The mad_lv must stay between pushc/popc.
; CHECK-LABEL: predicated:
; CHECK:         tt.sfppushc 0
; CHECK:         tt.sfpsetcc {{[0-9]+}}, lreg{{[0-9]+}}
; CHECK:         tt.sfpmad {{[0-9]+}}, [[ACC:lreg[0-9]+]], {{.*}}
; CHECK:         tt.sfppopc 0
; CHECK:         tt.sfpstore 0, 0, 3, [[ACC]]
define void @predicated() {
  %acc = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 0, i32 0)
  %x = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 1, i32 0)
  %a = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 2, i32 0)
  %b = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 3, i32 0)
  call void @llvm.riscv.rvtt.sfppushc(i32 0)
  call void @llvm.riscv.rvtt.sfpsetcc.v(<32 x i32> %x, i32 0)
  %acc2 = call <32 x i32> @llvm.riscv.rvtt.sfpmad.lv(<32 x i32> %acc, <32 x i32> %a, <32 x i32> %b, <32 x i32> %acc, i32 0)
  call void @llvm.riscv.rvtt.sfppopc(i32 0)
  call void @llvm.riscv.rvtt.sfpstore(<32 x i32> %acc2, i32 0, i32 0, i32 3)
  ret void
}

; The immediate-only control ops.
; CHECK-LABEL: ctrl:
; CHECK:         tt.sfpencc {{[0-9]+}}, {{[0-9]+}}
; CHECK:         tt.sfpsetcc {{[0-9]+}}, L0, {{[0-9]+}}
; CHECK:         tt.sfpcompc
; CHECK:         tt.sfppushc
; CHECK:         tt.sfppopc
define void @ctrl() {
  call void @llvm.riscv.rvtt.sfpencc(i32 0, i32 3)
  call void @llvm.riscv.rvtt.sfpsetcc.i(i32 1, i32 2)
  call void @llvm.riscv.rvtt.sfpcompc()
  call void @llvm.riscv.rvtt.sfppushc(i32 0)
  call void @llvm.riscv.rvtt.sfppopc(i32 0)
  ret void
}
