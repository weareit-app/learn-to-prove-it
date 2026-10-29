module

public import Mathlib.Logic.Relation

/-!
# Exercise 2 (reasoning): composition with a function's graph is substitution

For `f : α → β` and a relation `r : β → γ → Prop`, the composite of the graph of
`f` with `r` relates `a` to `c` exactly when `r (f a) c`. Unfolded, the left side
says there is some `b` with `f a = b` and `r b c`. Going forwards, the equation
`f a = b` lets us substitute `f a` for `b`. Going backwards, `f a` itself is the
witness.

This is not a new result: Mathlib states it as `Relation.fun_eq_comp`, an
equation between relations. Here it is a learner exercise and a regression test.
-/

namespace LearnToProveIt

/-- Composing a function's graph with a relation is substitution. The reference
solution of the reasoning exercise. -/
public theorem graph_comp_iff {α β γ : Type*} (f : α → β) (r : β → γ → Prop)
    (a : α) (c : γ) : Relation.Comp (fun x y => f x = y) r a c ↔ r (f a) c := by
  constructor
  · rintro ⟨b, rfl, h⟩
    exact h
  · intro h
    exact ⟨f a, rfl, h⟩

namespace GraphComp.Reasoning

universe u v w

/-- The proof obligation: for every function and relation, composing the
function's graph with the relation is substitution. Exposed, so that importers
(and the checker) see the statement. -/
@[expose] public def obligation : Prop :=
  ∀ {α : Type u} {β : Type v} {γ : Type w} (f : α → β) (r : β → γ → Prop) (a : α) (c : γ),
    Relation.Comp (fun x y => f x = y) r a c ↔ r (f a) c

/-- The reference solution proves the obligation. -/
public theorem solution : obligation.{u, v, w} := fun f r a c => graph_comp_iff f r a c

end GraphComp.Reasoning

end LearnToProveIt
