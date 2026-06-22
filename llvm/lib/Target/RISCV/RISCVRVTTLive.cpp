//===- RISCVRVTTLive.cpp - SFPU live-value (predication merge) lowering ---===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Lowers the SFPU predication-merge marker int_riscv_rvtt_sfpassign_lv into the
// tied "_lv" form of its producing op. A reassignment of an SFPU vector under
// the CC (lane-enable) stack only updates enabled lanes; disabled lanes keep
// the prior value. SFPI marks this as
//
//     %merged = sfpassign_lv(%live, %computed)
//
// meaning "%computed in enabled lanes, %live in disabled lanes". This pass folds
// it into the _lv variant of the op that produced %computed, e.g.
//
//     %computed = sfpadd(%a, %b, mod)
//     %merged   = sfpassign_lv(%live, %computed)
//   =>
//     %merged   = sfpadd_lv(%live, %a, %b, mod)   ; %merged tied to %live's reg
//
// When %computed is not a single-use foldable op, the marker becomes a
// predicated copy sfpmov_lv(%live, %computed, 0), which is always correct.
//
// This folding is correct independent of the actual CC nesting: the _lv tie
// preserves disabled lanes in every case. A later refinement (the CC-level
// liveness analysis, mirroring GCC's gimple-rvtt-live break_liveness) prunes
// _lv ties that are provably unnecessary; that is not done here. See
// docs/tensix-backend.md §11.
//
//===----------------------------------------------------------------------===//

#include "RISCV.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/IntrinsicsRISCV.h"
#include "llvm/InitializePasses.h"
#include "llvm/Pass.h"

using namespace llvm;

#define DEBUG_TYPE "riscv-rvtt-live"

namespace {

class RISCVRVTTLive : public FunctionPass {
public:
  static char ID;

  RISCVRVTTLive() : FunctionPass(ID) {}

  bool runOnFunction(Function &F) override;

  void getAnalysisUsage(AnalysisUsage &AU) const override {
    AU.setPreservesCFG();
  }

  StringRef getPassName() const override {
    return "RISC-V SFPU live-value lowering";
  }
};

} // end anonymous namespace

// Map a base SFPU value intrinsic to its _lv form (live operand at index 0).
// Returns not_intrinsic when there is no _lv form to fold into.
static Intrinsic::ID getLiveForm(Intrinsic::ID Base) {
  switch (Base) {
  case Intrinsic::riscv_rvtt_sfpmad:
    return Intrinsic::riscv_rvtt_sfpmad_lv;
  case Intrinsic::riscv_rvtt_sfpmul:
    return Intrinsic::riscv_rvtt_sfpmul_lv;
  case Intrinsic::riscv_rvtt_sfpadd:
    return Intrinsic::riscv_rvtt_sfpadd_lv;
  case Intrinsic::riscv_rvtt_sfpmov:
    return Intrinsic::riscv_rvtt_sfpmov_lv;
  default:
    return Intrinsic::not_intrinsic;
  }
}

bool RISCVRVTTLive::runOnFunction(Function &F) {
  // Collect the markers first; we mutate as we go.
  SmallVector<IntrinsicInst *, 16> Assigns;
  for (BasicBlock &BB : F)
    for (Instruction &I : BB)
      if (auto *II = dyn_cast<IntrinsicInst>(&I))
        if (II->getIntrinsicID() == Intrinsic::riscv_rvtt_sfpassign_lv)
          Assigns.push_back(II);

  if (Assigns.empty())
    return false;

  Module *M = F.getParent();
  for (IntrinsicInst *AI : Assigns) {
    Value *Live = AI->getArgOperand(0);
    Value *Computed = AI->getArgOperand(1);
    IRBuilder<> B(AI);

    auto *Prod = dyn_cast<IntrinsicInst>(Computed);
    Intrinsic::ID LV =
        Prod ? getLiveForm(Prod->getIntrinsicID()) : Intrinsic::not_intrinsic;

    if (LV != Intrinsic::not_intrinsic && Prod->hasOneUse()) {
      // Fold into the producer's _lv form: lv(live, <producer args...>).
      SmallVector<Value *, 6> Args;
      Args.push_back(Live);
      for (Value *A : Prod->args())
        Args.push_back(A);
      Function *Fn = Intrinsic::getOrInsertDeclaration(M, LV);
      CallInst *New = B.CreateCall(Fn, Args);
      New->setDebugLoc(AI->getDebugLoc());
      AI->replaceAllUsesWith(New);
      AI->eraseFromParent();
      Prod->eraseFromParent();
    } else {
      // Catch-all: a predicated copy of the computed value.
      Function *Fn =
          Intrinsic::getOrInsertDeclaration(M, Intrinsic::riscv_rvtt_sfpmov_lv);
      CallInst *New = B.CreateCall(Fn, {Live, Computed, B.getInt32(0)});
      New->setDebugLoc(AI->getDebugLoc());
      AI->replaceAllUsesWith(New);
      AI->eraseFromParent();
    }
  }

  return true;
}

char RISCVRVTTLive::ID = 0;

INITIALIZE_PASS(RISCVRVTTLive, DEBUG_TYPE, "RISC-V SFPU live-value lowering",
                false, false)

FunctionPass *llvm::createRISCVRVTTLivePass() { return new RISCVRVTTLive(); }
