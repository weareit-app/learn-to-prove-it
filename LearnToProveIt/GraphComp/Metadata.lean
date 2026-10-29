module

public import LearnToProveIt.Metadata

/-!
# Metadata for the graph-composition family

The three exercises about composing a relation with a function's graph, as
data. The prompts and criteria are written for this repository. The tests check
every declaration name and statement here against the Lean modules in
`LearnToProveIt.GraphComp`.
-/

namespace LearnToProveIt.GraphComp

open Lean

/-- Competency IDs, proposed in this repository's namespace. -/
def explainGraph := "learn-to-prove-it:explain-function-graph"
def unpackComposition := "learn-to-prove-it:unpack-relational-composition"
def substituteWitness := "learn-to-prove-it:eliminate-witness-by-substitution"
def restrictAlongInclusion := "learn-to-prove-it:restrict-relation-along-inclusion"

/-- The criterion every exercise shares: the Lean checker accepts a formal
answer. -/
def formalProof : Criterion where
  id := "formal-proof"
  description := "A Lean proof of the obligation is accepted by the checker. This shows the \
    mathematics of the formal answer is correct, and nothing about the learner's explanation."
  decidedBy := .leanChecker

/-- Exercise 1: the graph of a function as a relation. -/
public def comprehension : Exercise where
  id := "graph-comp.comprehension"
  version := "1.0.0"
  stage := .comprehension
  order := 1
  title := "The graph of a function"
  prompt := "Let f be the function on the natural numbers with f(n) = 2n + 1. Its graph is the \
    relation that holds between a and b exactly when f(a) = b. Is the pair (3, 7) in the graph? \
    Is (3, 8)? Explain why exactly one natural number is related to 3."
  mathematicalTarget := "The graph of f relates a to b exactly when f(a) = b, so it relates each \
    input to exactly one output: f(a)."
  parameters := [
    { name := "f", value := "fun n : ℕ => 2 * n + 1", constraint := "any function" },
    { name := "a", value := "3", constraint := "any input" },
    { name := "b", value := "7", constraint := "f a = b" },
    { name := "b'", value := "8", constraint := "f a ≠ b'" }]
  obligation := `LearnToProveIt.GraphComp.Comprehension.obligation
  statement := "((3 : ℕ), 7) ∈ Function.graph (fun n : ℕ => 2 * n + 1) ∧
    ((3 : ℕ), 8) ∉ Function.graph (fun n : ℕ => 2 * n + 1) ∧
    ∃! y, ((3 : ℕ), y) ∈ Function.graph (fun n : ℕ => 2 * n + 1)"
  referenceSolution := `LearnToProveIt.GraphComp.Comprehension.solution
  familySoundness := some `LearnToProveIt.GraphComp.Comprehension.family_sound
  criteria := [formalProof,
    { id := "explains-membership"
      description := "Explains that (a, b) is in the graph exactly when f(a) = b."
      decidedBy := .learningEngine },
    { id := "classifies-pairs"
      description := "Computes f(3) = 7, and so puts (3, 7) in the graph and (3, 8) outside it."
      decidedBy := .learningEngine },
    { id := "explains-unique-output"
      description := "Explains that f(3) is related to 3, and any b related to 3 equals f(3)."
      decidedBy := .learningEngine }]
  targets := [explainGraph]
  context := []
  suppliedFacts := []
  revealing := []
  status := { familySoundness := "lean-kernel-checked" }

/-- Exercise 2: composition with a function's graph is substitution. -/
public def reasoning : Exercise where
  id := "graph-comp.reasoning"
  version := "1.0.0"
  stage := .reasoning
  order := 2
  title := "Composing with a graph is substitution"
  prompt := "Let f : A → B be a function and R a relation from B to C. The composite of the \
    graph of f with R relates a to c when there is some b with f(a) = b and R(b, c). Explain \
    why this holds exactly when R(f(a), c). Say what the intermediate b must be in each \
    direction."
  mathematicalTarget := "(graph f ; R)(a, c) ↔ ∃ b, f(a) = b ∧ R(b, c) ↔ R(f(a), c): the \
    equation f(a) = b lets b be replaced by f(a), and f(a) is the witness for the converse."
  parameters := []
  obligation := `LearnToProveIt.GraphComp.Reasoning.obligation
  statement := "∀ {α : Type u} {β : Type v} {γ : Type w} (f : α → β) (r : β → γ → Prop) \
    (a : α) (c : γ), Relation.Comp (fun x y => f x = y) r a c ↔ r (f a) c"
  referenceSolution := `LearnToProveIt.GraphComp.Reasoning.solution
  familySoundness := none
  criteria := [formalProof,
    { id := "unpacks-existential"
      description := "States that the composite relates a to c exactly when some b has \
        f(a) = b and R(b, c)."
      decidedBy := .learningEngine },
    { id := "substitutes-forward"
      description := "From f(a) = b and R(b, c), replaces b by f(a) to conclude R(f(a), c)."
      decidedBy := .learningEngine },
    { id := "supplies-witness"
      description := "For the converse, names f(a) as the intermediate element, with \
        f(a) = f(a)."
      decidedBy := .learningEngine }]
  targets := [unpackComposition, substituteWitness]
  context := [explainGraph]
  suppliedFacts := []
  revealing := [`Relation.fun_eq_comp, `LearnToProveIt.graph_comp_iff]
  status := { familySoundness := "not-applicable" }

/-- Exercise 3: restricting a relation along an inclusion. -/
public def transfer : Exercise where
  id := "graph-comp.transfer"
  version := "1.0.0"
  stage := .transfer
  order := 3
  title := "Restricting along an inclusion"
  prompt := "Let E be the set of even natural numbers, and i : E → ℕ the function that sends \
    each even number to itself. Compose the graph of i with divisibility on ℕ. Which pairs \
    does the composite relate? Is 4 related to 12? Is 4 related to 6? Explain."
  mathematicalTarget := "Composing the graph of a subset's inclusion with a relation R \
    restricts R to the subset: x is related to z exactly when R(x, z)."
  parameters := [
    { name := "S", value := "{n : ℕ | Even n}", constraint := "any subset" },
    { name := "r", value := "(· ∣ ·)", constraint := "any relation" },
    { name := "s", value := "4", constraint := "an element of S" },
    { name := "c", value := "12", constraint := "r s c" },
    { name := "c'", value := "6", constraint := "¬ r s c'" }]
  obligation := `LearnToProveIt.GraphComp.Transfer.obligation
  statement := "(∀ (x : {n : ℕ | Even n}) (z : ℕ),
      Relation.Comp (fun (x : {n : ℕ | Even n}) y => (x : ℕ) = y) (· ∣ ·) x z ↔ (x : ℕ) ∣ z) ∧
    Relation.Comp (fun (x : {n : ℕ | Even n}) y => (x : ℕ) = y) (· ∣ ·)
      ⟨4, (⟨2, rfl⟩ : Even 4)⟩ 12 ∧
    ¬ Relation.Comp (fun (x : {n : ℕ | Even n}) y => (x : ℕ) = y) (· ∣ ·)
      ⟨4, (⟨2, rfl⟩ : Even 4)⟩ 6"
  referenceSolution := `LearnToProveIt.GraphComp.Transfer.solution
  familySoundness := some `LearnToProveIt.GraphComp.Transfer.family_sound
  criteria := [formalProof,
    { id := "identifies-inclusion"
      description := "Identifies the function as the inclusion, which sends each even number \
        to itself."
      decidedBy := .learningEngine },
    { id := "states-restriction"
      description := "Concludes that the composite relates an even x to z exactly when x \
        divides z."
      decidedBy := .learningEngine },
    { id := "decides-instances"
      description := "Shows 4 divides 12 and 4 does not divide 6, so 4 is related to 12 and \
        not to 6."
      decidedBy := .learningEngine }]
  targets := [restrictAlongInclusion]
  context := [explainGraph, unpackComposition, substituteWitness]
  suppliedFacts := [`LearnToProveIt.graph_comp_iff]
  revealing := []
  status := { familySoundness := "lean-kernel-checked" }

/-- The family. -/
public def graphComp : ExerciseFamily where
  id := "learn-to-prove-it:graph-comp"
  version := "0.1.0"
  title := "Composing a relation with a function's graph"
  scope := "Mathematical correctness only. Lean checks each obligation's reference solution, \
    and the checker decides whether a submitted Lean proof is correct. Nothing here asserts \
    anything about a learner's comprehension or mastery: criteria decided by the learning \
    engine are for it to evaluate, with its own attribution of the evidence."
  environment := {
    lean := "leanprover/lean4:v4.35.0"
    mathlib := "v4.35.0"
    mathlibCommit := "56a005855ea17e0b0958f73ec801ae140b0a1679"
    package := "learn_to_prove_it" }
  checker := {
    declaration := `LearnToProveIt.checkSubmission
    input := "The obligation's name, and Lean source for a term (a `by` block is a term) \
      that proves it."
    allowedAxioms := [`propext, `Classical.choice, `Quot.sound]
    verdicts := ["accepted", "unknown obligation", "unparsable", "ill-typed", "incomplete",
      "kernel rejected", "disallowed axioms"]
    sandbox := "Elaborating a submission runs arbitrary Lean. Real learner input goes through \
      a sandboxed runner (lean-on-it), never a public service." }
  provenance := {
    transformation := "independently_derived"
    licence := "Apache-2.0"
    design := "prove.how v0.6 first theorem test, track A, and its learning-evidence trial"
    inspiration := "Jencel Panic, Category Theory Illustrated, as instructional inspiration \
      only. No text or illustrations are copied." }
  mathlibReuse := [
    { declaration := `Relation.fun_eq_comp
      use := "States the reasoning exercise's result as an equation of relations. \
        graph_comp_iff is its pointwise form, kept as a reference solution, not a new result." },
    { declaration := `Relation.Comp
      use := "Relational composition, used directly." },
    { declaration := `Function.graph
      use := "The graph of a function, used directly in the comprehension exercise." },
    { declaration := `Function.mem_graph
      use := "Membership in a graph is the equation f a = b." },
    { declaration := `SetRel.restrictDomain
      use := "The restriction of a relation to a subtype, for relations as sets of pairs. \
        The transfer exercise's composite is the same restriction for predicates." }]
  competencies := [
    { id := explainGraph
      statement := "Explain the graph of a function as a relation that relates each input to \
        exactly one output." },
    { id := unpackComposition
      statement := "Unpack a relational composite into an existential statement about an \
        intermediate element." },
    { id := substituteWitness
      statement := "Eliminate an existential witness by substituting along an equation, and \
        supply a witness explicitly." },
    { id := restrictAlongInclusion
      statement := "Recognise composing with an inclusion's graph as restricting a relation to \
        a subset, and apply it to an unseen example." }]
  exercises := [comprehension, reasoning, transfer]

end LearnToProveIt.GraphComp
