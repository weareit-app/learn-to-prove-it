module

public meta import LearnToProveIt.Checker
public meta import LearnToProveIt.GraphComp.Metadata
public import LearnToProveIt.GraphComp.Reasoning
public import LearnToProveItTest.Summary
public import LearnToProveItTest.Wrappers

/-!
# Checker tests: the reasoning exercise

Composition with a function's graph is substitution. Each case is a learner's
submission, as source text, and the checker's verdict on it.
-/

open LearnToProveIt GraphComp

/-- The declarations whose use the checker reports: here, results that already
state the answer. -/
meta def revealing : Array Lean.Name := reasoning.watched.toArray

/-! ## Accepted -/

/-- info: "accepted; axioms: []; cites: [] (citations partial)" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Reasoning.obligation
  "fun f r a c => ⟨fun ⟨b, hb, h⟩ => hb ▸ h, fun h => ⟨f a, rfl, h⟩⟩"

/-- info: "accepted; axioms: []; cites: []" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Reasoning.obligation "by
  intro α β γ f r a c
  constructor
  · rintro ⟨b, rfl, h⟩
    exact h
  · intro h
    exact ⟨f a, rfl, h⟩"

/-! Under the module system, imported proofs are hidden, so a citation behind
one could be missed: an acceptance whose proof reaches one is marked "citations
partial". The tactic proof above reaches none.

Citing the library result that already states the answer is correct
mathematics. The checker accepts it and reports the citation; what that says
about the learner is for the learning engine to decide. -/

/-- info: "accepted; axioms: [propext, Quot.sound]; cites: [Relation.fun_eq_comp] (citations partial)" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Reasoning.obligation
  "by intro α β γ f r a c; rw [Relation.fun_eq_comp]" revealing

/-- info: "accepted; axioms: []; cites: [LearnToProveIt.graph_comp_iff] (citations partial)" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Reasoning.obligation
  "fun f r a c => graph_comp_iff f r a c" revealing

/-! Citing a revealing result through a wrapper theorem defined in another
module. These tests run under the module system, which hides imported proofs,
so the checker cannot see that the wrapper uses `graph_comp_iff`. It reports no
citation, and says its citations are partial. `FullEnvironment` checks the same
submission where the bodies are available. -/

/-- info: "accepted; axioms: []; cites: [] (citations partial)" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Reasoning.obligation
  "fun f r a c => LearnToProveItTest.renamedTwice f r a c" revealing

/-! ## Rejected -/

/-! The witness must be `f a`, an element of the codomain, not `a`. (Here no
other element of the codomain is in scope; the transfer tests give a wrong
witness of the right type.) -/

/-- info: "rejected: ill-typed" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Reasoning.obligation
  "fun f r a c => ⟨fun ⟨b, hb, h⟩ => hb ▸ h, fun h => ⟨a, rfl, h⟩⟩"

/-! Skipping the existential: the two sides are not definitionally equal. -/

/-- info: "rejected: ill-typed" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Reasoning.obligation "fun f r a c => Iff.rfl"

/-! Only the forward direction. -/

/-- info: "rejected: ill-typed" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Reasoning.obligation
  "fun f r a c => fun ⟨b, hb, h⟩ => hb ▸ h"

/-- info: "rejected: incomplete" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Reasoning.obligation
  "fun f r a c => ⟨fun ⟨b, hb, h⟩ => hb ▸ h, sorry⟩"

/-! `native_decide` trusts the compiler through an axiom of its own. -/

/-- info: "rejected: disallowed axioms" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Reasoning.obligation
  "have _ : 2 + 2 = 4 := by native_decide
  fun f r a c => ⟨fun ⟨b, hb, h⟩ => hb ▸ h, fun h => ⟨f a, rfl, h⟩⟩"

/-- info: "rejected: unparsable" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Reasoning.obligation
  "fun f r a c => ⟨fun ⟨b, hb, h⟩ => hb ▸ h"

/-! ## Caller errors and hygiene -/

/-- info: "rejected: unknown obligation" -/
#guard_msgs in
#eval summary <$> checkSubmission `LearnToProveIt.GraphComp.Reasoning.nope "trivial"

/-! A check leaves no declaration behind in the caller's environment. -/

/-- info: false -/
#guard_msgs in
#eval show Lean.CoreM Bool from do
  discard <| checkSubmission ``Reasoning.obligation "fun f r a c => graph_comp_iff f r a c"
  return (← Lean.getEnv).contains submissionName

/-! A declaration already named like the checker's throwaway theorem does not
stop a correct proof being accepted. -/

theorem _learnToProveIt_submission : True := trivial

/-- info: "accepted; axioms: []; cites: [] (citations partial)" -/
#guard_msgs in
#eval summary <$> checkSubmission ``Reasoning.obligation "fun f r a c => graph_comp_iff f r a c"
