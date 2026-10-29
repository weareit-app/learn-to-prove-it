module

public import LearnToProveIt.GraphComp.Reasoning
public import Mathlib.Algebra.Group.Nat.Even

/-!
# Exercise 3 (transfer): restricting a relation along an inclusion

For a subset `S` of `α`, the inclusion `S → α` sends each element to itself.
Composing its graph with a relation `r` on `α` gives `r` restricted to `S`: by
the reasoning exercise, `x` is related to `z` exactly when `r x z`.

The published instance changes the function (an inclusion), the relation
(divisibility) and the domain (the even naturals) from what the earlier
exercises showed. Mathlib's `SetRel.restrictDomain` is the same restriction for
relations as sets of pairs.
-/

namespace LearnToProveIt.GraphComp.Transfer

/-- The exercise family. For a subset `S`, a relation `r`, an element `s` of `S`
and two candidates: composing the inclusion's graph with `r` is `r` restricted
to `S`, `s` is related to `c`, and `s` is not related to `c'`. -/
@[expose] public def family {α γ : Type*} (S : Set α) (r : α → γ → Prop) (s : S)
    (c c' : γ) : Prop :=
  (∀ (x : S) (z : γ), Relation.Comp (fun (x : S) y => (x : α) = y) r x z ↔ r x z) ∧
    Relation.Comp (fun (x : S) y => (x : α) = y) r s c ∧
    ¬ Relation.Comp (fun (x : S) y => (x : α) = y) r s c'

/-- Soundness of the family: every instance whose parameters satisfy `r s c`
and `¬ r s c'` is provable. -/
public theorem family_sound {α γ : Type*} (S : Set α) (r : α → γ → Prop) (s : S)
    (c c' : γ) (hc : r s c) (hc' : ¬ r s c') : family S r s c c' :=
  have h := graph_comp_iff (Subtype.val : S → α) r
  ⟨h, (h s c).2 hc, fun h' => hc' ((h s c').1 h')⟩

/-- The published instance, stated in full: the even naturals, divisibility,
the element `4`, and the candidates `12` and `6`. -/
@[expose] public def obligation : Prop :=
  (∀ (x : {n : ℕ | Even n}) (z : ℕ),
      Relation.Comp (fun (x : {n : ℕ | Even n}) y => (x : ℕ) = y) (· ∣ ·) x z ↔ (x : ℕ) ∣ z) ∧
    Relation.Comp (fun (x : {n : ℕ | Even n}) y => (x : ℕ) = y) (· ∣ ·) ⟨4, (⟨2, rfl⟩ : Even 4)⟩ 12 ∧
    ¬ Relation.Comp (fun (x : {n : ℕ | Even n}) y => (x : ℕ) = y) (· ∣ ·) ⟨4, (⟨2, rfl⟩ : Even 4)⟩ 6

/-- The reference solution: the instance's parameters satisfy the family's
constraints. -/
public theorem solution : obligation :=
  family_sound {n : ℕ | Even n} (· ∣ ·) ⟨4, (⟨2, rfl⟩ : Even 4)⟩ 12 6 (by decide) (by decide)

end LearnToProveIt.GraphComp.Transfer
