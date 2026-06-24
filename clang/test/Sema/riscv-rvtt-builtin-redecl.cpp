// RUN: %clang_cc1 -triple riscv32 -target-feature +experimental-xttensixwh \
// RUN:   -std=c++17 -fsyntax-only -verify %s
// expected-no-diagnostics

// GCC-style headers (SFPI's tensix_builtins.def) redeclare the compiler
// builtins in an `extern "C"` block with an explicit `noexcept`. clang must
// accept this for builtins (the builtin's own spec is authoritative) rather
// than reject it as an exception-specification mismatch.
typedef unsigned __attribute__((vector_size(128))) __xtt_vector;
extern "C" {
__xtt_vector __builtin_rvtt_sfpmov(__xtt_vector, unsigned) noexcept;
__xtt_vector __builtin_rvtt_sfpmad(__xtt_vector, __xtt_vector, __xtt_vector, unsigned) noexcept;
void __builtin_rvtt_sfppushc(unsigned) noexcept;
}
