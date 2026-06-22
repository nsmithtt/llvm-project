; RUN: llc -mtriple=riscv32 -mattr=+experimental-xttensixwh < %s | FileCheck %s

; SFPU live-value (predication merge) lowering (docs §11, m5). The RISCVRVTTLive
; pass folds sfpassign_lv(live, computed) into the producer's _lv form so the
; result is tied to the live register (disabled CC lanes keep `live`). A
; non-foldable producer falls back to a predicated move sfpmov_lv.

declare <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 immarg, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpadd(<32 x i32>, <32 x i32>, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpmad(<32 x i32>, <32 x i32>, <32 x i32>, i32 immarg)
declare <32 x i32> @llvm.riscv.rvtt.sfpassign.lv(<32 x i32>, <32 x i32>)
declare void @llvm.riscv.rvtt.sfpsetcc.v(<32 x i32>, i32 immarg)
declare void @llvm.riscv.rvtt.sfppushc(i32 immarg)
declare void @llvm.riscv.rvtt.sfppopc(i32 immarg)
declare void @llvm.riscv.rvtt.sfpstore(<32 x i32>, i32 immarg, i32 immarg, i32 immarg)

; v = live; v_if(cond) v = v + d;  ->  the add is folded to add_lv tied to live.
; The single sfpadd becomes a tt.sfpadd whose dest == live reg (tie), and the
; store reads that same reg.
; CHECK-LABEL: predicated_add:
; CHECK:         tt.sfppushc 0
; CHECK:         tt.sfpsetcc {{[0-9]+}}, lreg{{[0-9]+}}
; CHECK:         tt.sfpadd {{[0-9]+}}, [[V:lreg[0-9]+]], {{.*}}
; CHECK:         tt.sfppopc 0
; CHECK:         tt.sfpstore 0, 0, 3, [[V]]
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

; A merge whose computed value is not a single-use foldable producer (here %x is
; used twice) falls back to a predicated move sfpmov_lv tying the result to live.
; CHECK-LABEL: fallback_move:
; CHECK:         tt.sfpmov {{[0-9]+}}, [[L:lreg[0-9]+]], lreg{{[0-9]+}}
; CHECK:         tt.sfpstore 0, 0, 3, [[L]]
define void @fallback_move() {
  %live = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 7, i32 0)
  %x = call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 5, i32 0)
  %merged = call <32 x i32> @llvm.riscv.rvtt.sfpassign.lv(<32 x i32> %live, <32 x i32> %x)
  call void @llvm.riscv.rvtt.sfpstore(<32 x i32> %merged, i32 0, i32 0, i32 3)
  call void @llvm.riscv.rvtt.sfpstore(<32 x i32> %x, i32 0, i32 0, i32 3)
  ret void
}
