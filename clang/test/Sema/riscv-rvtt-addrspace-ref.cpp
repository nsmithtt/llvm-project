// RUN: %clang_cc1 -triple riscv32 -target-feature +experimental-xttensixwh \
// RUN:   -std=c++17 -fsyntax-only -verify %s
// expected-no-diagnostics

// The rvtt logical address spaces lower to ordinary pointers, so they are
// compatible with the default address space. SFPI's ckernel.h binds a
// tt_reg_ptr (rvtt_reg_ptr) reference to a plain array; clang must accept that
// rather than reject it as "changes address space".
#define tt_reg_ptr __attribute__((rvtt_reg_ptr))

extern volatile unsigned plain_arr[];
constexpr inline volatile unsigned (tt_reg_ptr &reg_ref)[] = plain_arr;

// A plain pointer where an rvtt-qualified one is expected, and vice versa.
void f(volatile unsigned tt_reg_ptr *p);
void g(volatile unsigned *q) { f(q); }
