module

public meta import LearnToProveIt.Checker
public meta import LearnToProveIt.GraphComp.Metadata
public import LearnToProveIt.GraphComp.Comprehension
public import LearnToProveItTest.Summary

/-!
# Checker tests: the comprehension exercise

The graph of `f n = 2n + 1`: `(3, 7)` is in it, `(3, 8)` is not, and exactly one
output is related to `3`.
-/

open LearnToProveIt GraphComp

/-! ## The published instance belongs to its family -/

example : Comprehension.obligation = Comprehension.family (fun n : ℕ => 2 * n + 1) 3 7 8 := rfl

/-! ## Accepted -/

/-! Matching on the numeral equation `7 = 8` goes through `propext`. -/

/-- info: "accepted; axioms: [propext]; cites: [] (citations partial)" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Comprehension.obligation
  "⟨rfl, (fun h => nomatch h), ⟨7, rfl, fun _ h => h.symm⟩⟩"

/-- info: "accepted; axioms: [propext]; cites: [] (citations partial)" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Comprehension.obligation
  "⟨rfl, by simp, 7, rfl, fun y h => by simpa using h.symm⟩"

/-! ## Rejected -/

/-! Claiming the wrong pair is in the graph: `f 3 = 7`, not `8`. -/

/-- info: "rejected: ill-typed" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Comprehension.obligation
  "⟨(rfl : 2 * 3 + 1 = 8), (fun h => nomatch h), ⟨7, rfl, fun _ h => h.symm⟩⟩"

/-! Citing the exercise's own answer key is accepted and reported. -/

/-- info: "accepted; axioms: []; cites: [LearnToProveIt.GraphComp.Comprehension.solution] (citations partial)" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Comprehension.obligation "Comprehension.solution"
  comprehension.watched.toArray

/-! The wrong output as the unique one. -/

/-- info: "rejected: ill-typed" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Comprehension.obligation
  "⟨rfl, (fun h => nomatch h), ⟨8, rfl, fun _ h => h.symm⟩⟩"

/-! Existence without uniqueness. -/

/-- info: "rejected: ill-typed" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Comprehension.obligation
  "⟨rfl, (fun h => nomatch h), ⟨7, rfl⟩⟩"

/-! Deciding the non-membership with `native_decide`. -/

/-- info: "rejected: disallowed axioms" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Comprehension.obligation
  "⟨rfl, fun h => (by native_decide : 2 * 3 + 1 ≠ 8) h, ⟨7, rfl, fun _ h => h.symm⟩⟩"
