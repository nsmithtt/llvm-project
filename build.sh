#!/bin/bash

TRIPLE=riscv32-none-eabi

cmake -S llvm -G Ninja -B build \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_INSTALL_PREFIX=/opt/riscv-toolchain \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_TARGETS_TO_BUILD="X86;RISCV" \
  -DLLVM_DEFAULT_TARGET_TRIPLE=${TRIPLE} \
  -DLLVM_ENABLE_ASSERTIONS=ON \
  -DLLVM_ENABLE_RUNTIMES="libc" \
  -DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=OFF \
  -DLLVM_LIBC_FULL_BUILD=ON \
  -DLIBC_TARGET_TRIPLE=${TRIPLE} \
  -DRUNTIMES_${TRIPLE}_LIBC_COMPILE_OPTIONS_DEFAULT="-mcpu=tt-wh-brisc;-menable-experimental-extensions;-Wno-atomic-alignment" \
  -DLLVM_RUNTIME_TARGETS=${TRIPLE}

cmake --build build
cmake --build build --target libc
#cmake --install build
