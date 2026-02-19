#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "usage: ./compile.sh SOURCE_FILE"
    exit 1
fi

set -x
set -e

SOURCE=$1

ROOT=${PWD}/build

CC=${ROOT}/bin/clang
LD=${ROOT}/bin/ld.lld
OBJDUMP=${ROOT}/bin/llvm-objdump

ENABLE_LIBC=true

if ${ENABLE_LIBC}; then
  LIBC_INCLUDES="-I${ROOT}/runtimes/runtimes-riscv32-none-eabi-bins/libc/include/ -I${ROOT}/lib/clang/22/include"
  LIBC_LIB="${ROOT}/runtimes/runtimes-riscv32-none-eabi-bins/libc/lib/libc.a"
else
  LIBC_INCLUDES=""
  LIBC_LIB=""
fi

C_FLAGS="-O3 -flto --target=riscv32 -mcpu=tt-tensix-brisc -menable-experimental-extensions -nostdinc -nostdlib ${LIBC_INCLUDES}"
LD_FLAGS="-fuse-ld=lld -flto -nostdinc -nostdlib -Xlinker -T -Xlinker brisc.ld"

${CC} ${C_FLAGS} -c ${SOURCE} -o ${SOURCE}.o
${CC} ${C_FLAGS} -c rt.c -o rt.o
${CC} ${C_FLAGS} -c brisc.S -o brisc.o
${CC} ${LD_FLAGS} ${SOURCE}.o rt.o brisc.o ${LIBC_LIB} -o clang.out
${OBJDUMP} -d clang.out

#/opt/tenstorrent/sfpi/compiler/bin/riscv32-tt-elf-objdump -d clang.out
