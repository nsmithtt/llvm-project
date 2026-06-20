// RUN: %clang_cc1 -triple riscv32 -emit-llvm %s -o - | FileCheck %s
//
// The Tenstorrent rvtt_l1_ptr / rvtt_reg_ptr type attributes (from the sfpi GCC
// fork) bind to the pointer and mangle as the Itanium vendor qualifiers
// U11rvtt_l1_ptr / U12rvtt_reg_ptr, matching the fork so clang objects link
// against fork-built ones. They lower to the default address space (normal
// pointers), and are kept in the (otherwise qualifier-stripped) parameter
// signature.

#define tt_l1_ptr __attribute__((rvtt_l1_ptr))
#define tt_reg_ptr __attribute__((rvtt_reg_ptr))

// CHECK: define {{.*}}void @_Z3fooU11rvtt_l1_ptrPj(ptr
void foo(unsigned tt_l1_ptr* p) { p[0] = 0; }

// CHECK: define {{.*}}void @_Z3barU12rvtt_reg_ptrPj(ptr
void bar(unsigned tt_reg_ptr* p) { p[0] = 0; }

// The qualifier is per-parameter; the plain pointer reuses the substitution.
// CHECK: define {{.*}}void @_Z3bazPjU11rvtt_l1_ptrS_(ptr
void baz(unsigned* a, unsigned tt_l1_ptr* b) {}
