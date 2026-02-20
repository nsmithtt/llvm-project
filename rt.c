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

static ssize_t syscall(long const num, long arg0, long arg1, long arg2) {
  register long a0 __asm__("a0") = arg0;
  register long a1 __asm__("a1") = arg1;
  register long a2 __asm__("a2") = arg2;
  register long a7 __asm__("a7") = num;

  __asm__ volatile("ecall" : "+r"(a0) : "r"(a1), "r"(a2), "r"(a7) : "memory");
}

ssize_t __llvm_libc_stdio_read(void *cookie, char *buf, size_t size) {
  struct __llvm_libc_stdio_cookie const *stdio =
      (struct __llvm_libc_stdio_cookie const *)cookie;
  return syscall(63, (long)stdio->fileno, (long)buf, (long)size);
}

ssize_t __llvm_libc_stdio_write(void *cookie, const char *buf,
                                           size_t size) {
  struct __llvm_libc_stdio_cookie const *stdio =
      (struct __llvm_libc_stdio_cookie const *)cookie;
  return syscall(64, (long)stdio->fileno, (long)buf, (long)size);
}

[[noreturn]] void __llvm_libc_exit(int code) {
  syscall(93, 0, 0, 0);
  __builtin_unreachable();
}

int err = 0;
int *__llvm_libc_errno() { return &err; }
