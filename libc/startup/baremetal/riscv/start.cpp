//===-- Implementation of crt for riscv -----------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "hdr/stdint_proxy.h"
#include "src/__support/macros/config.h"
#include "src/stdlib/atexit.h"
#include "src/stdlib/exit.h"
#include "src/string/memcpy.h"
#include "src/string/memset.h"
#include "startup/baremetal/fini.h"
#include "startup/baremetal/init.h"

extern "C" {
int main(int argc, char **argv);
void _start();

// Semihosting library initialisation if applicable. Required for printf, etc.
[[gnu::weak]] void _platform_init() {}

// These symbols are provided by the linker. The exact names are not defined by
// a standard.
extern uintptr_t __stack;
extern uintptr_t __data_source[];
extern uintptr_t __data_start[];
extern uintptr_t __data_size[];
extern uintptr_t __bss_start[];
extern uintptr_t __bss_size[];
} // extern "C"

namespace LIBC_NAMESPACE_DECL {

[[noreturn]] void do_start() {
  // Perform the equivalent of scatterloading
  LIBC_NAMESPACE::memcpy(__data_start, __data_source,
                         reinterpret_cast<uintptr_t>(__data_size));
  LIBC_NAMESPACE::memset(__bss_start, '\0',
                         reinterpret_cast<uintptr_t>(__bss_size));
  __libc_init_array();

  _platform_init();
  LIBC_NAMESPACE::atexit(&__libc_fini_array);
  LIBC_NAMESPACE::exit(main(0, 0));
}
} // namespace LIBC_NAMESPACE_DECL

extern "C" {
[[gnu::section(".text.init.enter"), gnu::naked]]
void _start() {
  asm volatile("la sp, __stack");
  asm volatile("call %0" : : "X"(LIBC_NAMESPACE::do_start));
}
} // extern "C"
