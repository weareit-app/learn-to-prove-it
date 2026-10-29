# Exercise family: composing a relation with a function's graph

Three exercises in progression, comprehension, then reasoning, then transfer, about one fact: composing the graph of a function `f` with a relation `R` is substitution,

```text
(graph f ; R)(a, c)  ↔  ∃ b, f(a) = b ∧ R(b, c)  ↔  R(f(a), c).
```

Mathlib already has this fact as `Relation.fun_eq_comp`. Here it is a learner exercise and a regression test, not a new result.

The Lean lives in `LearnToProveIt/GraphComp/`, the checker in `LearnToProveIt/Checker.lean`, and the metadata in `LearnToProveIt/GraphComp/Metadata.lean`. prove.how reads the exported fixture, [`fixtures/prove-how/graph-comp.exercise-family.json`](../../fixtures/prove-how/graph-comp.exercise-family.json).

## Mathematics and learning are separate judgments

The checker decides one thing: whether a Lean proof of an exercise's obligation is correct. An accepted proof validates the mathematics. It does not show that the learner understands it. The proof may cite a library result that states the answer, or the learner may have had help. A rejected proof is not a correct proof *as written in Lean*, and a slip in the Lean need not be a slip in the learner's reasoning. Every criterion about the learner's explanation is marked `learning-engine`. The learning engine decides those, and decides what any verdict says about a particular learner.

## The exercises

### 1. Comprehension: the graph of a function

- **Target.** The graph of `f` relates `a` to `b` exactly when `f(a) = b`, so it relates each input to exactly one output, `f(a)`.
- **Parameters.** A function `f`, an input `a`, a member `b` with `f a = b`, and a non-member `b'` with `f a ≠ b'`. Published instance: `f n = 2n + 1` on ℕ, `a = 3`, `b = 7`, `b' = 8`.
- **Obligation** (`GraphComp.Comprehension.obligation`). `(3, 7)` is in `Function.graph f`, `(3, 8)` is not, and `∃! y, (3, y) ∈ Function.graph f`.
- **Valid solution.** `⟨rfl, (fun h => nomatch h), ⟨7, rfl, fun _ h => h.symm⟩⟩`. The reference solution goes through `family_sound`, which proves every instance whose parameters meet the constraints.
- **Representative rejections.** Claiming `(3, 8)` is in the graph. Giving `8` as the unique output. Existence without uniqueness. Deciding the non-membership with `native_decide` (disallowed axiom).
- **Criteria.** `formal-proof` (checker). `explains-membership`, `classifies-pairs` and `explains-unique-output` (engine).
- **Competency.** Targets `explain-function-graph`.

### 2. Reasoning: composing with a graph is substitution

- **Target.** Unfold the composite into an existential. Forwards, the equation `f(a) = b` lets `b` be replaced by `f(a)`. Backwards, `f(a)` is the witness.
- **Parameters.** None: the statement holds for all types, functions, relations and elements, so the learner must handle arbitrary ones.
- **Obligation** (`GraphComp.Reasoning.obligation`). `∀ f r a c, Relation.Comp (fun x y => f x = y) r a c ↔ r (f a) c`, universe-polymorphic.
- **Valid solution.** `fun f r a c => ⟨fun ⟨b, hb, h⟩ => hb ▸ h, fun h => ⟨f a, rfl, h⟩⟩`, or the tactic proof of `graph_comp_iff`.
- **Representative rejections.** The witness `a` instead of `f a`. `Iff.rfl` (skipping the existential: the sides are not definitionally equal). The forward direction only. A `sorry` in the converse. A `native_decide` anywhere in the term.
- **Accepted with a citation.** `rw [Relation.fun_eq_comp]` is a correct proof, so the checker accepts it and reports that it cites a revealing declaration.
- **Criteria.** `formal-proof` (checker). `unpacks-existential`, `substitutes-forward` and `supplies-witness` (engine).
- **Competency.** Targets `unpack-relational-composition` and `eliminate-witness-by-substitution`, with `explain-function-graph` as context.

### 3. Transfer: restricting along an inclusion

- **Target.** Composing the graph of a subset's inclusion with a relation restricts the relation to the subset. The published instance changes the function, the relation and the domain from what the learner has seen.
- **Parameters.** A subset `S`, a relation `r`, an element `s ∈ S`, a related `c` (`r s c`) and an unrelated `c'` (`¬ r s c'`). Published instance: the even naturals, divisibility, `4`, `12`, `6`.
- **Obligation** (`GraphComp.Transfer.obligation`). For every even `x` and every `z`, the composite relates `x` to `z` iff `x ∣ z`. `4` is related to `12`, and `4` is not related to `6`.
- **Valid solution.** Either use the reasoning exercise's result, which is a supplied fact here: `⟨fun x z => graph_comp_iff Subtype.val (· ∣ ·) x z, ⟨4, rfl, by decide⟩, fun ⟨b, hb, h⟩ => by subst hb; exact absurd h (by decide)⟩`. Or reason from scratch.
- **Representative rejections.** Claiming `4` is related to `6`. Giving the witness `12` instead of `4`. Leaving the general identity as `sorry`.
- **Criteria.** `formal-proof` (checker). `identifies-inclusion`, `states-restriction` and `decides-instances` (engine).
- **Competency.** Targets `restrict-relation-along-inclusion`, with the other three as context. Passing it is joint evidence, not independent mastery of each context competency.

## The checker

`LearnToProveIt.checkSubmission obligation source watched` parses `source` as a Lean term (a `by` block is a term) and elaborates it against the obligation's proposition. It adds the result as a theorem to a throwaway copy of the environment, so the kernel checks it, and collects its axioms. The verdict is one of:

| Verdict | Meaning |
|---|---|
| `accepted` | A correct proof, with its axioms, the `watched` declarations it depends on, and whether that citation list is complete |
| `unknown obligation` | The name is not an exposed definition (a caller error) |
| `unparsable` | The text is not a Lean term |
| `ill-typed` | The term does not elaborate to a proof of the obligation |
| `incomplete` | The term contains `sorry` or an unfilled hole |
| `kernel rejected` | The kernel refused the elaborated proof |
| `disallowed axioms` | The proof uses an axiom other than `propext`, `Classical.choice`, `Quot.sound` (for example through `native_decide`) |

### What citations cover

`cited` lists the watched declarations in the proof's whole dependency closure, directly or through other theorems, matched by declaration identity. The closure can only be followed where the environment holds the bodies. Under the module system an imported theorem's proof is hidden (it appears as an axiom), so the verdict's `citationsComplete` flag is false whenever the closure reaches one, and a watched declaration behind it would be missed. A checking environment built with plain (non-module) imports holds every body and gives complete citations; `LearnToProveItTest/FullEnvironment.lean` tests this, including a revealing result reached through two wrapper theorems.

Even complete citations cover only what is on the watched list. A proof that re-proves a result inline, or uses an unlisted result that states the same thing, cites nothing. A missing citation is therefore not evidence that the learner derived the proof independently.

### Untrusted input

Elaborating a submission runs arbitrary Lean, tactics included, with effects outside Lean's environment. Restoring the environment afterwards is not a security boundary. Real learner input goes through a sandboxed runner (`lean-on-it`). Until that integration lands, nothing in this repository exposes the checker to untrusted input: the only executable prints metadata.

## The exported metadata

`lake exe export-exercise-metadata` prints the JSON. `./scripts/check.sh` fails if the committed fixture differs from it. The Lean tests check every declaration name and statement in it against the Lean that defines them. The format is `learn-to-prove-it/exercise-family-export`, version `0.1.0`. It is this repository's own format: its fields follow the roles of prove.how's logical `ExerciseFamily` and `AssessmentDesign` records, but it is not a `@learn-it/contracts` schema. When that package publishes, a mapping goes in the consuming repository.

### Family fields

| Field | Meaning |
|---|---|
| `schema`, `schemaVersion` | The format and its version |
| `id`, `version`, `title` | The family's identity |
| `scope` | What the export asserts (mathematical correctness) and does not (anything about a learner) |
| `environment` | Lean and Mathlib pins the obligations are checked in |
| `checker` | The checker's declaration, input, allowed axioms, verdicts, what citations cover, and the sandbox requirement |
| `provenance` | `independently_derived`, the licence, the design source, and `sources`: one record per external source edition consulted |
| `mathlibReuse` | Mathlib declarations reused, and how (validation gate G3) |
| `competencies` | Proposed competency IDs in the `learn-to-prove-it:` namespace, each with `status: proposed` |
| `exercises` | The exercises, in order |

### Exercise fields

| Field | Meaning |
|---|---|
| `id`, `version`, `title`, `stage`, `order` | Identity and place in the progression |
| `prompt` | What the learner is asked, written for this repository |
| `mathematicalTarget` | The mathematics, in plain words |
| `parameters` | Each instance parameter's value, and the constraint the soundness theorem needs |
| `obligation`, `statement` | The Lean proposition a formal answer must prove: its name (the checker's input) and its source text |
| `referenceSolution` | A Lean theorem proving the obligation |
| `familySoundness` | The theorem that every instance meeting the constraints is provable, or `null` when there are no parameters |
| `criteria` | Evaluation criteria, each `decidedBy` `lean-checker` or `learning-engine` |
| `targets`, `context` | Competencies the exercise gives evidence about, and those it only relies on |
| `suppliedFacts` | Earlier results the learner may use |
| `revealing` | Results that already state the answer: library results, and the exercise's own reference solution and soundness theorem |
| `status` | Typed statuses: `referenceSolution`, `familySoundness`, `statementFidelity` (`not-reviewed` until an independent review). There is no single `verified` flag |

Pass `suppliedFacts` and `revealing` as the checker's `watched` list: an accepted verdict then reports which of them the proof depends on (see [What citations cover](#what-citations-cover)).

### Source edition fields

Each record in `provenance.sources` identifies one edition precisely. The web edition and the EPUB of a book are separate records, and only the edition consulted is recorded. The record is provenance, not a licence grant.

| Field | Meaning |
|---|---|
| `title`, `author`, `edition` | The work and which edition of it |
| `url` | The edition's canonical address |
| `locator`, `locatorUrl` | The chapter and sections consulted |
| `licence`, `licenceUrl`, `licenceEvidence` | The licence the edition states, as stated, and where it states it |
| `revision`, `retrieved` | The revision consulted, as precisely as it can be pinned, and when |
| `transformation` | How the family relates to it (`independently_derived`) |
| `use` | What was taken (instructional inspiration) and what was not (no text, illustrations or exercises) |

The family records one source: the **web edition** of Jencel Panic's *Category Theory Illustrated* (<https://abuseofnotation.github.io/category-theory-illustrated/>). The consulted parts are chapter "Sets", sections "Functions" and "Functions and Subsets". The site states CC BY-NC 4.0, and the source repository was at commit `8378ac8` on 2026-10-28.

### Example: the reasoning exercise as exported

```json
{
  "context": ["learn-to-prove-it:explain-function-graph"],
  "criteria": [
    {
      "decidedBy": "lean-checker",
      "description": "A Lean proof of the obligation is accepted by the checker. This shows the mathematics of the formal answer is correct, and nothing about the learner's explanation.",
      "id": "formal-proof"
    },
    {
      "decidedBy": "learning-engine",
      "description": "States that the composite relates a to c exactly when some b has f(a) = b and R(b, c).",
      "id": "unpacks-existential"
    },
    {
      "decidedBy": "learning-engine",
      "description": "From f(a) = b and R(b, c), replaces b by f(a) to conclude R(f(a), c).",
      "id": "substitutes-forward"
    },
    {
      "decidedBy": "learning-engine",
      "description": "For the converse, names f(a) as the intermediate element, with f(a) = f(a).",
      "id": "supplies-witness"
    }
  ],
  "familySoundness": null,
  "id": "graph-comp.reasoning",
  "obligation": "LearnToProveIt.GraphComp.Reasoning.obligation",
  "order": 2,
  "parameters": [],
  "referenceSolution": "LearnToProveIt.GraphComp.Reasoning.solution",
  "revealing": [
    "Relation.fun_eq_comp",
    "LearnToProveIt.graph_comp_iff",
    "LearnToProveIt.GraphComp.Reasoning.solution"
  ],
  "stage": "reasoning",
  "statement": "∀ {α : Type u} {β : Type v} {γ : Type w} (f : α → β) (r : β → γ → Prop) (a : α) (c : γ), Relation.Comp (fun x y => f x = y) r a c ↔ r (f a) c",
  "status": {
    "familySoundness": "not-applicable",
    "referenceSolution": "lean-kernel-checked",
    "statementFidelity": "not-reviewed"
  },
  "suppliedFacts": [],
  "targets": [
    "learn-to-prove-it:unpack-relational-composition",
    "learn-to-prove-it:eliminate-witness-by-substitution"
  ],
  "title": "Composing with a graph is substitution",
  "version": "1.0.0"
}
```

The `prompt` and `mathematicalTarget` fields are left out above. The fixture has them, and the full family.
