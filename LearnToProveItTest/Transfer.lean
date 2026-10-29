module

public meta import LearnToProveIt.Checker
public meta import LearnToProveIt.GraphComp.Metadata
public import LearnToProveIt.GraphComp.Transfer
public import LearnToProveItTest.Summary

/-!
# Checker tests: the transfer exercise

Composing the graph of the inclusion of the even naturals with divisibility is
divisibility restricted to the evens; `4` is related to `12` and not to `6`.
-/

open LearnToProveIt GraphComp

/-! ## The published instance belongs to its family -/

example : Transfer.obligation = Transfer.family {n : ℕ | Even n} (· ∣ ·) ⟨4, (⟨2, rfl⟩ : Even 4)⟩ 12 6 :=
  rfl

/-! ## Accepted -/

/-! Using the reasoning exercise's result, a supplied fact here, is reported as a
citation like any other listed declaration. -/

/-- info: "accepted; axioms: [propext]; cites: [LearnToProveIt.graph_comp_iff]" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Transfer.obligation
  "⟨fun x z => graph_comp_iff Subtype.val (· ∣ ·) x z, ⟨4, rfl, by decide⟩,
    fun ⟨b, hb, h⟩ => by subst hb; exact absurd h (by decide)⟩"
  transfer.watched.toArray

/-! Reasoning from scratch, without the earlier result. -/

/-- info: "accepted; axioms: [propext]; cites: []" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Transfer.obligation "by
  refine ⟨fun x z => ⟨?_, fun h => ⟨x, rfl, h⟩⟩, ⟨4, rfl, by decide⟩, ?_⟩
  · rintro ⟨b, rfl, h⟩
    exact h
  · rintro ⟨b, rfl, h⟩
    revert h
    decide" transfer.watched.toArray

/-! ## Rejected -/

/-! Claiming `4` is related to `6`. -/

/-- info: "rejected: ill-typed" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Transfer.obligation
  "⟨fun x z => graph_comp_iff Subtype.val (· ∣ ·) x z, ⟨4, rfl, by decide⟩, ⟨4, rfl, by decide⟩⟩"

/-! The wrong witness: the inclusion sends `4` to `4`, not to `12`. -/

/-- info: "rejected: ill-typed" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Transfer.obligation
  "⟨fun x z => graph_comp_iff Subtype.val (· ∣ ·) x z, ⟨12, rfl, dvd_refl 12⟩,
    fun ⟨b, hb, h⟩ => by subst hb; exact absurd h (by decide)⟩"

/-! The general identity left as a hole. -/

/-- info: "rejected: incomplete" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Transfer.obligation
  "⟨fun x z => sorry, ⟨4, rfl, by decide⟩,
    fun ⟨b, hb, h⟩ => by subst hb; exact absurd h (by decide)⟩"
