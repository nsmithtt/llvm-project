; RUN: llc -mtriple=riscv32 -mattr=+experimental-xttensixwh < %s | FileCheck %s
; RUN: llc -mtriple=riscv32 -mattr=+experimental-xttensixwh -stop-after=riscv-rvtt-live < %s | FileCheck %s --check-prefix=IR

; SFPU live-value (predication merge) lowering (docs §11, m5). RISCVRVTTLive folds
; sfpassign_lv(live, computed) into the producer's _lv form so disabled CC lanes
; keep `live`; a non-foldable producer becomes a predicated move sfpmov_lv. A
; CC-level analysis first prunes merges that are provably unnecessary (the live
; value defined at a CC depth no shallower than the merge).

declare <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 immarg, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpadd(<32 x i32>, <32 x i32>, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpassign.lv(<32 x i32>, <32 x i32>)
declare void @llvm.riscv.rvtt.sfpsetcc.v(<32 x i32>, i32 immarg)
declare void @llvm.riscv.rvtt.sfppushc(i32 immarg)
declare void @llvm.riscv.rvtt.sfppopc(i32 immarg)
declare void @llvm.riscv.rvtt.sfpstore(<32 x i32>, i32 immarg, i32 immarg, i32 immarg)

; Merge inside a CC region (deeper than the live def): kept and folded to add_lv,
; result tied to the live register and read by the store.
; CHECK-LABEL: predicated_add:
; CHECK:         tt.sfpadd {{[0-9]+}}, [[V:lreg[0-9]+]], {{.*}}
; CHECK:         tt.sfpstore 0, 0, 3, [[V]]
; IR-LABEL: @predicated_add
; IR:         call <32 x i32> @llvm.riscv.rvtt.sfpadd.lv(
; IR-NOT:     sfpassign
define void @predicated_add() {
  %live = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 7, i32 0)
  %d = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 1, i32 0)
  %c = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 2, i32 0)
  call void @llvm.riscv.rvtt.sfppushc(i32 0)
  call void @llvm.riscv.rvtt.sfpsetcc.v(<32 x i32> %c, i32 0)
  %new = call <32 x i32> @llvm.riscv.rvtt.sfpadd(<32 x i32> %live, <32 x i32> %d, i32 0)
  %merged = call <32 x i32> @llvm.riscv.rvtt.sfpassign.lv(<32 x i32> %live, <32 x i32> %new)
  call void @llvm.riscv.rvtt.sfppopc(i32 0)
  call void @llvm.riscv.rvtt.sfpstore(<32 x i32> %merged, i32 0, i32 0, i32 3)
  ret void
}

; No CC region: the merge is at the same CC depth as the live def, so it is
; provably unnecessary and pruned -- the result is %new directly, with no _lv tie
; and no leftover marker.
; IR-LABEL: @pruned
; IR:         call <32 x i32> @llvm.riscv.rvtt.sfpadd(
; IR-NOT:     sfpassign
; IR-NOT:     sfpadd.lv
; IR-NOT:     sfpmov.lv
define void @pruned() {
  %live = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 7, i32 0)
  %d = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 1, i32 0)
  %new = call <32 x i32> @llvm.riscv.rvtt.sfpadd(<32 x i32> %live, <32 x i32> %d, i32 0)
  %merged = call <32 x i32> @llvm.riscv.rvtt.sfpassign.lv(<32 x i32> %live, <32 x i32> %new)
  call void @llvm.riscv.rvtt.sfpstore(<32 x i32> %merged, i32 0, i32 0, i32 3)
  ret void
}

; Merge inside a CC region over a non-foldable producer (sfploadi has no _lv
; form): kept as a predicated move sfpmov_lv.
; IR-LABEL: @predicated_fallback
; IR:         call <32 x i32> @llvm.riscv.rvtt.sfpmov.lv(
define void @predicated_fallback() {
  %live = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 7, i32 0)
  %c = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 2, i32 0)
  call void @llvm.riscv.rvtt.sfppushc(i32 0)
  call void @llvm.riscv.rvtt.sfpsetcc.v(<32 x i32> %c, i32 0)
  %x = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 5, i32 0)
  %merged = call <32 x i32> @llvm.riscv.rvtt.sfpassign.lv(<32 x i32> %live, <32 x i32> %x)
  call void @llvm.riscv.rvtt.sfppopc(i32 0)
  call void @llvm.riscv.rvtt.sfpstore(<32 x i32> %merged, i32 0, i32 0, i32 3)
  ret void
}
