import LearnToProveIt
import LearnToProveItTest.Summary
import LearnToProveItTest.Wrappers

/-!
# Checker tests in a full environment

Not a `module`: a plain `import` loads the bodies of every imported declaration,
so the checker can follow a proof's dependencies all the way down, and its
citations are complete. A runner checking real submissions should build its
environment this way.
-/

open LearnToProveIt GraphComp

/-! A revealing result reached through two wrapper theorems in another module. -/

/-- info: "accepted; axioms: []; cites: [LearnToProveIt.graph_comp_iff]" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Reasoning.obligation
  "fun f r a c => LearnToProveItTest.renamedTwice f r a c" reasoning.watched.toArray

/-! A proof from scratch cites nothing, and the check is complete. -/

/-- info: "accepted; axioms: []; cites: []" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Reasoning.obligation
  "fun f r a c => ⟨fun ⟨b, hb, h⟩ => hb ▸ h, fun h => ⟨f a, rfl, h⟩⟩" reasoning.watched.toArray

/-! A Mathlib result is followed too. -/

/-- info: "accepted; axioms: [propext, Quot.sound]; cites: [Relation.fun_eq_comp]" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Reasoning.obligation
  "by intro α β γ f r a c; rw [Relation.fun_eq_comp]" reasoning.watched.toArray

/-! The transfer exercise's soundness theorem uses the reasoning exercise's
result, so citing it reports both. -/

/-- info: "accepted; axioms: [propext]; cites: [LearnToProveIt.graph_comp_iff, LearnToProveIt.GraphComp.Transfer.family_sound]" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Transfer.obligation
  "Transfer.family_sound _ _ _ _ _ (by decide) (by decide)" transfer.watched.toArray
