.section .text
.globl _start
.globl stack_top
.globl kernel_main

_start:
    la sp, stack_top
    call kernel_main
loop:
    j loop
