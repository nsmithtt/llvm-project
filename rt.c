// __llvm_libc_stdin_cookie
// __llvm_libc_stdout_cookie
// __llvm_libc_stderr_cookie
// __llvm_libc_stdio_read
// __llvm_libc_stdio_write
// __llvm_libc_exit
// __llvm_libc_errno

#include <stdio.h>

struct __llvm_libc_stdio_cookie {
  int fileno;
};
struct __llvm_libc_stdio_cookie __llvm_libc_stdin_cookie = {.fileno = 0};
struct __llvm_libc_stdio_cookie __llvm_libc_stdout_cookie = {.fileno = 1};
struct __llvm_libc_stdio_cookie __llvm_libc_stderr_cookie = {.fileno = 2};

static ssize_t stdio_syscall(long const syscall, void *cookie, char *buf,
                             size_t size) {
  struct __llvm_libc_stdio_cookie const *stdio =
      (struct __llvm_libc_stdio_cookie const *)cookie;

  register long a0 __asm__("a0") = (long)stdio->fileno; // fd
  register long a1 __asm__("a1") = (long)buf;           // buf
  register long a2 __asm__("a2") = (long)size;          // size
  register long a7 __asm__("a7") = syscall;

  __asm__ volatile("ecall"
                   : "+r"(a0) // a0 = return value (in-place)
                   : "r"(a1), // a1 = buf
                     "r"(a2), // a2 = size
                     "r"(a7)  // a7 = syscall number
                   : "memory");
}

ssize_t __llvm_libc_stdio_read(void *cookie, char *buf,
                                          size_t size) {
  return stdio_syscall(0, cookie, buf, size);
}

ssize_t __llvm_libc_stdio_write(void *cookie, const char *buf,
                                           size_t size) {
  return stdio_syscall(1, cookie, buf, size);
}

[[noreturn]] void __llvm_libc_exit(int code) {
  for (;;)
    ;
  __builtin_unreachable();
}

int err = 0;
int *__llvm_libc_errno() { return &err; }
