void kernel_main() {
  __builtin_riscv_tt_insn(0x02000000);
  asm("ttinsn 0x02000000");
}
