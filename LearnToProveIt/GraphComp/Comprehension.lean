module

public import Mathlib.Basic.Rel

/-!
# Exercise 1 (comprehension): the graph of a function as a relation

The graph of `f : α → β` is the relation that holds between `a` and `b` exactly
when `f a = b`. Read as a relation, it relates each input to exactly one output:
`f a` itself.

The graph is Mathlib's `Function.graph`, a set of pairs; `Function.mem_graph`
unfolds membership to the equation.
-/

namespace LearnToProveIt.GraphComp.Comprehension

/-- The exercise family. For a function `f`, an input `a`, and two candidate
outputs: `(a, b)` is in the graph, `(a, b')` is not, and exactly one output is
related to `a`. -/
@[expose] public def family {α β : Type*} (f : α → β) (a : α) (b b' : β) : Prop :=
  (a, b) ∈ f.graph ∧ (a, b') ∉ f.graph ∧ ∃! y, (a, y) ∈ f.graph

/-- Soundness of the family: every instance whose parameters satisfy
`f a = b` and `f a ≠ b'` is provable. -/
public theorem family_sound {α β : Type*} (f : α → β) (a : α) (b b' : β)
    (hb : f a = b) (hb' : f a ≠ b') : family f a b b' :=
  ⟨hb, hb', f a, rfl, fun _ h => h.symm⟩

/-- The published instance, stated in full: for `f n = 2n + 1`, the input `3`,
and the candidate outputs `7` and `8`. -/
@[expose] public def obligation : Prop :=
  ((3 : ℕ), 7) ∈ Function.graph (fun n : ℕ => 2 * n + 1) ∧
    ((3 : ℕ), 8) ∉ Function.graph (fun n : ℕ => 2 * n + 1) ∧
    ∃! y, ((3 : ℕ), y) ∈ Function.graph (fun n : ℕ => 2 * n + 1)

/-- The reference solution: the instance's parameters satisfy the family's
constraints. -/
public theorem solution : obligation :=
  family_sound (fun n : ℕ => 2 * n + 1) 3 7 8 rfl (by decide)

end LearnToProveIt.GraphComp.Comprehension
