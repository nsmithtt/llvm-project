// __llvm_libc_stdin_cookie
// __llvm_libc_stdout_cookie
// __llvm_libc_stderr_cookie
// __llvm_libc_stdio_read
// __llvm_libc_stdio_write
// __llvm_libc_exit
// __llvm_libc_errno

#include <stdio.h>

struct __llvm_libc_stdio_cookie {
  int foo;
};
struct __llvm_libc_stdio_cookie __llvm_libc_stdin_cookie;
struct __llvm_libc_stdio_cookie __llvm_libc_stdout_cookie;
struct __llvm_libc_stdio_cookie __llvm_libc_stderr_cookie;

ssize_t __llvm_libc_stdio_read(void *cookie, char *buf,
                                          size_t size) {}

ssize_t __llvm_libc_stdio_write(void *cookie, const char *buf,
                                           size_t size) {}

[[noreturn]] void __llvm_libc_exit(int) {
  for (;;)
    ;
  __builtin_unreachable();
}

int err = 0;
int *__llvm_libc_errno() { return &err; }
