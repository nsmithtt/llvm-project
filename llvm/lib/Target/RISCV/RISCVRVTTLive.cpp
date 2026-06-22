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
// Folding is correct independent of CC nesting. Before folding, a CC-level
// liveness analysis (mirroring GCC's gimple-rvtt-live) prunes merges that are
// provably unnecessary: if the live value was defined at a CC depth no shallower
// than the merge point, %computed already covers every lane the live value did,
// so the merge is dropped and %computed used directly. The analysis is applied
// conservatively -- any ambiguity (unknown/PHI/loop def, or a block re-entered
// at a different CC level) keeps the merge (folds to _lv), which is always safe;
// only the optimization opportunity, never correctness, is lost. See
// docs/tensix-backend.md §11.
//
//===----------------------------------------------------------------------===//

#include "RISCV.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/IntrinsicsRISCV.h"
#include "llvm/InitializePasses.h"
#include "llvm/Pass.h"
#include <optional>
#include <vector>

using namespace llvm;

#define DEBUG_TYPE "riscv-rvtt-live"

// SFPPUSHC mod value selecting "replace top of CC stack" (sfpi_constants.h).
static constexpr uint64_t SFPPUSHC_MOD1_REPLACE = 1;

namespace {

// CC liveness recorded per SFPU op: the CC nesting depth (Level, one per setcc),
// the predicate "generation" (one per non-cascading pushc), and Force, set when
// the op's block is re-entered at a higher CC level (analysis ambiguous there).
struct Liveness {
  unsigned Level = 0;
  unsigned Generation = 0;
  bool Force = false;
};

struct BlockData {
  bool Visited = false;
  unsigned CCLevel = 0;
  bool Live = false; // all ops in the block forced live (re-entered higher)
  unsigned StackDepth = 0;
};

class RISCVRVTTLive : public FunctionPass {
  DenseMap<const IntrinsicInst *, Liveness> LV;
  DenseMap<const BasicBlock *, BlockData> BD;

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

private:
  void analyze(BasicBlock *BB, Liveness Cur, bool Cascading, unsigned GenCount,
               std::vector<Liveness> Stack);
  std::optional<Liveness> chaseDefLiveness(Value *V) const;
};

} // end anonymous namespace

// Is this an SFPU (rvtt) intrinsic call?
static bool isRvtt(const IntrinsicInst *II) {
  return II->getCalledFunction() &&
         II->getCalledFunction()->getName().starts_with("llvm.riscv.rvtt.");
}

static bool isPushC(const IntrinsicInst *II) {
  return II->getIntrinsicID() == Intrinsic::riscv_rvtt_sfppushc;
}
static bool isPopC(const IntrinsicInst *II) {
  return II->getIntrinsicID() == Intrinsic::riscv_rvtt_sfppopc;
}
// setcc deepens the CC nesting (encc does not, per GCC).
static bool isSetCC(const IntrinsicInst *II) {
  switch (II->getIntrinsicID()) {
  case Intrinsic::riscv_rvtt_sfpsetcc_i:
  case Intrinsic::riscv_rvtt_sfpsetcc_v:
    return true;
  default:
    return false;
  }
}
// An op whose result carries a prior "live" value in arg 0 (chased during the
// def-liveness walk). At this point the only such marker is sfpassign_lv, but
// the folded _lv forms are included for robustness.
static bool isLiveForm(const IntrinsicInst *II) {
  switch (II->getIntrinsicID()) {
  case Intrinsic::riscv_rvtt_sfpassign_lv:
  case Intrinsic::riscv_rvtt_sfpmad_lv:
  case Intrinsic::riscv_rvtt_sfpmul_lv:
  case Intrinsic::riscv_rvtt_sfpadd_lv:
  case Intrinsic::riscv_rvtt_sfpmov_lv:
    return true;
  default:
    return false;
  }
}

// Map a base SFPU value intrinsic to its _lv form (live operand at index 0).
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

// CC-level DFS. Each path carries its own (Cur, Cascading, GenCount, Stack) by
// value, mirroring GCC's process_block. Records Liveness for every non-push/pop
// rvtt op; marks Force when a block is re-entered at a higher CC level.
void RISCVRVTTLive::analyze(BasicBlock *BB, Liveness Cur, bool Cascading,
                            unsigned GenCount, std::vector<Liveness> Stack) {
  BlockData &Bd = BD[BB];
  if (Bd.Visited) {
    if (!Bd.Live && Cur.Level > Bd.CCLevel) {
      Bd.Live = true;
      for (Instruction &I : *BB)
        if (auto *II = dyn_cast<IntrinsicInst>(&I))
          if (isRvtt(II) && !isPushC(II) && !isPopC(II)) {
            auto It = LV.find(II);
            if (It != LV.end())
              It->second.Force = true;
          }
    }
    return;
  }

  Bd.Visited = true;
  Bd.CCLevel = Cur.Level;
  Bd.StackDepth = Stack.size();

  for (Instruction &I : *BB) {
    auto *II = dyn_cast<IntrinsicInst>(&I);
    if (!II || !isRvtt(II))
      continue;

    if (isPushC(II)) {
      bool IsReplace = false;
      if (auto *C = dyn_cast<ConstantInt>(II->getArgOperand(0)))
        IsReplace = C->getZExtValue() == SFPPUSHC_MOD1_REPLACE;
      if (IsReplace && !Stack.empty())
        Stack.pop_back();
      Stack.push_back(Cur);
      if (!Cascading) {
        GenCount++;
        Cascading = true;
      }
      Cur.Generation = GenCount;
    } else if (isPopC(II)) {
      if (!Stack.empty()) {
        Cur = Stack.back();
        Stack.pop_back();
      }
      Cascading = false;
    } else {
      LV[II] = Cur;
      if (isSetCC(II))
        Cur.Level++;
    }
  }

  for (BasicBlock *Succ : successors(BB))
    analyze(Succ, Cur, Cascading, GenCount, Stack);
}

// Walk back from a live value to the liveness of its definition, chasing through
// _lv/assign markers. Returns nullopt on anything we can't resolve (function
// arg, PHI, loop, or a non-recorded op) so the caller keeps the merge.
std::optional<Liveness> RISCVRVTTLive::chaseDefLiveness(Value *V) const {
  SmallPtrSet<Value *, 8> Seen;
  while (true) {
    auto *II = dyn_cast<IntrinsicInst>(V);
    if (!II || !isRvtt(II))
      return std::nullopt;
    if (!Seen.insert(II).second)
      return std::nullopt; // cycle
    if (isLiveForm(II)) {
      V = II->getArgOperand(0); // chase the prior (live) value
      continue;
    }
    auto It = LV.find(II);
    if (It == LV.end())
      return std::nullopt;
    return It->second;
  }
}

bool RISCVRVTTLive::runOnFunction(Function &F) {
  LV.clear();
  BD.clear();

  // Collect the markers; bail early if there are none.
  SmallVector<IntrinsicInst *, 16> Assigns;
  for (BasicBlock &BB : F)
    for (Instruction &I : BB)
      if (auto *II = dyn_cast<IntrinsicInst>(&I))
        if (II->getIntrinsicID() == Intrinsic::riscv_rvtt_sfpassign_lv)
          Assigns.push_back(II);

  if (Assigns.empty())
    return false;

  // Phase 1: CC-level liveness analysis.
  analyze(&F.getEntryBlock(), Liveness{}, /*Cascading=*/true, /*GenCount=*/0,
          /*Stack=*/{});

  Module *M = F.getParent();

  // Phase 2: decide remove (provably unnecessary) vs keep/fold for each marker.
  for (IntrinsicInst *AI : Assigns) {
    Value *Live = AI->getArgOperand(0);
    Value *Computed = AI->getArgOperand(1);

    // Break: drop the merge when the live value's definition is at a CC depth no
    // shallower (and same generation) than this merge -- %computed already
    // covers every lane the live value did. Conservative: keep on any ambiguity.
    auto CurIt = LV.find(AI);
    std::optional<Liveness> Def = chaseDefLiveness(Live);
    if (CurIt != LV.end() && Def && !CurIt->second.Force &&
        CurIt->second.Level <= Def->Level &&
        CurIt->second.Generation <= Def->Generation) {
      AI->replaceAllUsesWith(Computed);
      AI->eraseFromParent();
      continue;
    }

    // Keep: fold into the producer's _lv form, or a predicated-move catch-all.
    IRBuilder<> B(AI);
    auto *Prod = dyn_cast<IntrinsicInst>(Computed);
    Intrinsic::ID LVForm =
        Prod ? getLiveForm(Prod->getIntrinsicID()) : Intrinsic::not_intrinsic;

    if (LVForm != Intrinsic::not_intrinsic && Prod->hasOneUse()) {
      SmallVector<Value *, 6> Args;
      Args.push_back(Live);
      for (Value *A : Prod->args())
        Args.push_back(A);
      Function *Fn = Intrinsic::getOrInsertDeclaration(M, LVForm);
      CallInst *New = B.CreateCall(Fn, Args);
      New->setDebugLoc(AI->getDebugLoc());
      AI->replaceAllUsesWith(New);
      AI->eraseFromParent();
      Prod->eraseFromParent();
    } else {
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
