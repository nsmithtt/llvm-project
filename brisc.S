.section .text
.globl _start
.globl stack_top
.globl kernel_main
.globl exit

_start:
    la sp, stack_top
    call kernel_main
    call exit
loop:
    j loop
