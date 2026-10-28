module

public import Mathlib.Logic.Relation

/-!
# Skeleton check: composing a function's graph with a relation

The verified fact behind a first exercise: composing the graph of `f` with a
relation `r` is substitution. It is already in Mathlib (`Relation.fun_eq_comp`
states a form of it), so this is a worked check that the build and imports work,
not a new result. Replace it with real exercise generators and checkers.
-/

namespace LearnToProveIt

/-- Composing a function's graph with a relation is substitution. -/
public theorem graph_comp_iff {α β γ : Type*} (f : α → β) (r : β → γ → Prop)
    (a : α) (c : γ) : Relation.Comp (fun x y => f x = y) r a c ↔ r (f a) c := by
  constructor
  · rintro ⟨b, rfl, h⟩
    exact h
  · intro h
    exact ⟨f a, rfl, h⟩

end LearnToProveIt
