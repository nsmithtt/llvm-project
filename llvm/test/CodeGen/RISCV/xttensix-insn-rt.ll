; RUN: llc -mtriple=riscv32 -mattr=+experimental-xttensixwh < %s | FileCheck %s

; The runtime-operand intrinsic issues a Tensix instruction whose 32-bit word is
; only known at runtime, by storing it to the instruction buffer at
; INSTRN_BUF_BASE (0xFFE40000). 0xFFE40000 >> 12 == 0xFFE40 == 1048128. It selects
; to TT_FIFO_SW -- a `sw` modeled with side effects in the same memory-effect
; domain as the named tt instructions, so it cannot be reordered across them.

declare void @llvm.riscv.tt.insn.rt(i32)
declare void @llvm.riscv.tt.nop()

; A plain runtime word stores straight to the instruction buffer.
; CHECK-LABEL: issue_word:
; CHECK:         lui a1, 1048128
; CHECK:         tt.fifo.sw a0, 0(a1)
; CHECK:         ret
define void @issue_word(i32 %word) {
  call void @llvm.riscv.tt.insn.rt(i32 %word)
  ret void
}

; A word built at runtime (opcode | data) is materialized then issued.
; CHECK-LABEL: issue_built_word:
; CHECK:         tt.fifo.sw {{a[0-9]+}}, 0({{a[0-9]+}})
; CHECK:         ret
define void @issue_built_word(i32 %data) {
  %lo = and i32 %data, 65535
  %word = or i32 %lo, 1895825408 ; 0x71000000
  call void @llvm.riscv.tt.insn.rt(i32 %word)
  ret void
}

; Two issues preserve order (the instruction has side effects / mayStore).
; CHECK-LABEL: issue_two:
; CHECK:         lui [[B:a[0-9]+]], 1048128
; CHECK:         tt.fifo.sw a0, 0([[B]])
; CHECK:         tt.fifo.sw a1, 0([[B]])
; CHECK:         ret
define void @issue_two(i32 %a, i32 %b) {
  call void @llvm.riscv.tt.insn.rt(i32 %a)
  call void @llvm.riscv.tt.insn.rt(i32 %b)
  ret void
}

; Regression: a runtime issue must stay ordered with the named (inaccessible-
; memory) tt instructions. A generic store would be treated as non-aliasing the
; named ops and could be hoisted/sunk across them, desyncing the FIFO; TT_FIFO_SW
; keeps the issue between the two tt.nop barriers, in program order.
; CHECK-LABEL: ordered_with_named:
; CHECK:         tt.nop
; CHECK:         tt.fifo.sw a0, 0({{a[0-9]+}})
; CHECK:         tt.nop
; CHECK:         ret
define void @ordered_with_named(i32 %word) {
  call void @llvm.riscv.tt.nop()
  call void @llvm.riscv.tt.insn.rt(i32 %word)
  call void @llvm.riscv.tt.nop()
  ret void
}
