module

public meta import LearnToProveIt.Checker
public import LearnToProveIt.GraphComp.Reasoning
public import LearnToProveItTest.Summary

/-!
# Checker tests: adversarial submissions

Submissions that try to get a wrong proof accepted, or to escape the checker.
Each case came from an independent review of the checker.
-/

open LearnToProveIt GraphComp

/-- An obligation no correct proof can meet. -/
def falseObligation : Prop := False

/-! ## Turning the kernel off

A submission can set `debug.skipKernelTC` for the declarations its own
elaboration adds, such as the auxiliary lemma `decide +kernel` creates. That
lemma, `1 = 2`, would then never be kernel-checked. -/

/-- info: "rejected: kernel rejected" -/
#guard_msgs in
#eval summary <$> checkSubmission ``falseObligation
  "set_option debug.skipKernelTC true in absurd (by decide +kernel : (1 : Nat) = 2) (by decide)"

/-- info: "rejected: kernel rejected" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Reasoning.obligation
  "set_option debug.skipKernelTC true in
    fun f r a c => absurd (by decide +kernel : (1 : Nat) = 2) (by decide)"

/-! The caller's options do not weaken the check either: elaboration runs with
kernel checking on, so the false lemma is caught there. -/

/-- info: "rejected: ill-typed" -/
#guard_msgs in
set_option debug.skipKernelTC true in
#eval summary <$> checkSubmission ``falseObligation
  "absurd (by decide +kernel : (1 : Nat) = 2) (by decide)"

/-! Without the option the kernel catches the false lemma during elaboration. -/

/-- info: "rejected: ill-typed" -/
#guard_msgs in
#eval summary <$> checkSubmission ``falseObligation
  "absurd (by decide +kernel : (1 : Nat) = 2) (by decide)"

/-! ## Resource limits become rejections

Running out of recursion depth is a runtime exception, which an ordinary
`try … catch` does not catch. -/

/-- info: "rejected: limit exceeded" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Reasoning.obligation
  ("set_option maxRecDepth 40 in fun f r a c => " ++
    String.join (List.replicate 200 "id (") ++ "graph_comp_iff f r a c" ++
    String.join (List.replicate 200 ")"))

/-! ## Nothing leaks to the caller

A trace the submission turns on stays inside the check: `#guard_msgs` here sees
only the verdict. -/

/-- info: "accepted; axioms: [propext, Quot.sound]; cites: [] (citations partial)" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Reasoning.obligation
  "set_option trace.Meta.Tactic.simp.rewrite true in by intro f r a c; simp [Relation.Comp]"

/-! ## `let rec` is not supported

A local recursive definition is lifted to a declaration only when a whole
command is elaborated, which a submission is not. -/

/-- info: "rejected: ill-typed" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Reasoning.obligation
  "fun f r a c => let rec g : Nat → Nat | 0 => 0 | n + 1 => g n; graph_comp_iff f r a c"
