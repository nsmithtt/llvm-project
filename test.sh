#!/bin/bash
set -x
#./llvm/build/bin/clang --target=riscv32 -### -c tmp.c -mcpu=tt-tensix-brisc -menable-experimental-extensions

C_FLAGS="--target=riscv32 -mcpu=tt-tensix-brisc -menable-experimental-extensions -nostdlib"
LD_FLAGS="-T brisc.ld"

./llvm/build/bin/clang ${C_FLAGS} -c tmp.c -o tmp.o
./llvm/build/bin/clang ${C_FLAGS} -c brisc.S -o brisc.o
./llvm/build/bin/ld.lld ${LD_FLAGS} brisc.o tmp.o -o clang.out
#/opt/tenstorrent/sfpi/compiler/bin/riscv32-tt-elf-gcc tmp.c -o gcc.out
./llvm/build/bin/llvm-objdump -d clang.out
/opt/tenstorrent/sfpi/compiler/bin/riscv32-tt-elf-objdump -d clang.out
