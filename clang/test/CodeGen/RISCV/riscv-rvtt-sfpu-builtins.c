// RUN: %clang_cc1 -triple riscv32 -target-feature +experimental-xttensixwh \
// RUN:   -emit-llvm -o - %s | FileCheck %s

// SFPU value-semantics builtins (docs §11): __builtin_rvtt_sfp* over the 32-lane
// __xtt_vector lower to the int_riscv_rvtt_sfp* intrinsics. Checked at -emit-llvm
// (the frontend mapping + types); instruction selection of these intrinsics is
// covered by the llvm/test/CodeGen/RISCV/xttensix-sfpu-*.ll tests.

typedef unsigned __attribute__((vector_size(128))) __xtt_vector;

// CHECK-LABEL: @compute
// CHECK: call <32 x i32> @llvm.riscv.rvtt.sfpmad(<32 x i32> %{{.*}}, <32 x i32> %{{.*}}, <32 x i32> %{{.*}}, i32 0)
// CHECK: call <32 x i32> @llvm.riscv.rvtt.sfpmul(<32 x i32> %{{.*}}, <32 x i32> %{{.*}}, i32 0)
// CHECK: call <32 x i32> @llvm.riscv.rvtt.sfpadd(<32 x i32> %{{.*}}, <32 x i32> %{{.*}}, i32 0)
// CHECK: call <32 x i32> @llvm.riscv.rvtt.sfpabs(<32 x i32> %{{.*}}, i32 3)
// CHECK: call <32 x i32> @llvm.riscv.rvtt.sfpand(<32 x i32> %{{.*}}, <32 x i32> %{{.*}})
__xtt_vector compute(__xtt_vector a, __xtt_vector b, __xtt_vector c) {
  __xtt_vector m = __builtin_rvtt_sfpmad(a, b, c, 0);
  m = __builtin_rvtt_sfpmul(m, a, 0);
  m = __builtin_rvtt_sfpadd(m, b, 0);
  m = __builtin_rvtt_sfpabs(m, 3);
  return __builtin_rvtt_sfpand(m, c);
}

// CHECK-LABEL: @unary_set
// CHECK: call <32 x i32> @llvm.riscv.rvtt.sfplz(
// CHECK: call <32 x i32> @llvm.riscv.rvtt.sfpexexp(
// CHECK: call <32 x i32> @llvm.riscv.rvtt.sfpsetexp.v(
// CHECK: call <32 x i32> @llvm.riscv.rvtt.sfpiadd.v(
__xtt_vector unary_set(__xtt_vector a, __xtt_vector b) {
  __xtt_vector m = __builtin_rvtt_sfplz(a, 0);
  m = __builtin_rvtt_sfpexexp(m, 0);
  m = __builtin_rvtt_sfpsetexp_v(m, b, 0);
  return __builtin_rvtt_sfpiadd_v(m, b, 4);
}

// CHECK-LABEL: @predicated
// CHECK: call void @llvm.riscv.rvtt.sfppushc(i32 0)
// CHECK: call void @llvm.riscv.rvtt.sfpsetcc.v(<32 x i32> %{{.*}}, i32 0)
// CHECK: call void @llvm.riscv.rvtt.sfppopc(i32 0)
void predicated(__xtt_vector x) {
  __builtin_rvtt_sfppushc(0);
  __builtin_rvtt_sfpsetcc_v(x, 0);
  __builtin_rvtt_sfppopc(0);
}

// Mode/immediate operands are plain `unsigned int` (not _Constant): the builtin
// signatures match SFPI's tensix_builtins.def so the stock sfpi headers parse.
// A constant-folded operand is still encoded; selection (timm) is covered by the
// llvm/test/CodeGen/RISCV/xttensix-sfpu-*.ll tests.
// CHECK-LABEL: @const_mode
// CHECK: call <32 x i32> @llvm.riscv.rvtt.sfpmov(<32 x i32> %{{.*}}, i32 7)
__xtt_vector const_mode(__xtt_vector a) {
  return __builtin_rvtt_sfpmov(a, 7);
}

// Memory ops carry the full SFPI signature (instruction-buffer ptr + runtime-
// address placeholders, as the SFPI macros produce). CodeGen drops the ptr and
// the placeholders and reorders the two mode fields (J16<-mod0, J14<-mode).
// CHECK-LABEL: @memops
// CHECK: call <32 x i32> @llvm.riscv.rvtt.sfploadi(i32 1, i32 0)
// CHECK: call <32 x i32> @llvm.riscv.rvtt.sfpload(i32 4, i32 0, i32 0)
// CHECK: call void @llvm.riscv.rvtt.sfpstore(<32 x i32> %{{.*}}, i32 8, i32 3, i32 0)
void memops(void volatile *buf) {
  __xtt_vector v = __builtin_rvtt_sfploadi(buf, 1, 0, 0, 0);
  __xtt_vector w = __builtin_rvtt_sfpload(buf, 4, 0, 0, 0, 0);
  __xtt_vector m = __builtin_rvtt_sfpmov(w, 0);
  __builtin_rvtt_sfpstore(buf, m, 8, 0, 0, 0, 3);
}

// sfploadi_lv carries the full SFPI signature (buf, live, imm, 0, 0, mod0);
// CodeGen drops the ptr/placeholders -> sfploadi_lv(live, imm, mod0).
// CHECK-LABEL: @loadi_lv
// CHECK: call <32 x i32> @llvm.riscv.rvtt.sfploadi.lv(<32 x i32> %{{.*}}, i32 5, i32 2)
__xtt_vector loadi_lv(void volatile *buf, __xtt_vector live) {
  return __builtin_rvtt_sfploadi_lv(buf, live, 5, 0, 0, 2);
}
