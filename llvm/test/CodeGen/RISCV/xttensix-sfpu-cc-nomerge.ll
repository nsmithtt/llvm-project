; RUN: opt -O2 -S < %s | FileCheck %s

; SFPU CC-stack control ops must not be CSE-merged or dead-store-eliminated when
; they have identical operands (e.g. the two `sfppushc 0` / `sfppopc 0` from a
; nested or if/elseif predication region). They read+write the abstract CC
; state (memory(inaccessiblemem: readwrite)), so each observes the prior one.
; Regression for the write-only modeling that collapsed them.

declare void @llvm.riscv.rvtt.sfppushc(i32 immarg)
declare void @llvm.riscv.rvtt.sfppopc(i32 immarg)

; CHECK-LABEL: @nest(
; CHECK: call void @llvm.riscv.rvtt.sfppushc(i32 0)
; CHECK: call void @llvm.riscv.rvtt.sfppushc(i32 0)
; CHECK: call void @llvm.riscv.rvtt.sfppopc(i32 0)
; CHECK: call void @llvm.riscv.rvtt.sfppopc(i32 0)
define void @nest() {
  call void @llvm.riscv.rvtt.sfppushc(i32 0)
  call void @llvm.riscv.rvtt.sfppushc(i32 0)
  call void @llvm.riscv.rvtt.sfppopc(i32 0)
  call void @llvm.riscv.rvtt.sfppopc(i32 0)
  ret void
}
