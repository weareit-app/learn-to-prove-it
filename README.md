# learn-to-prove-it

Verified mathematical exercise generators and checkers built on Mathlib.

Status: one exercise family. [Composing a relation with a function's graph](docs/exercises/graph-comp.md) has three Lean-checked exercises (comprehension, reasoning, transfer), a checker for learners' Lean proofs, and the metadata prove.how reads, exported to [`fixtures/prove-how/graph-comp.exercise-family.json`](fixtures/prove-how/graph-comp.exercise-family.json).

A Lean-checked solution validates the mathematics. What it says about a learner is for the learning engine to decide.

## Getting started

```sh
lake exe cache get
./scripts/check.sh
```

`./scripts/check.sh` runs `lake build`, `lake test` (the Lean tests in `LearnToProveItTest`) and the skills-sync, decision-record and action-pin checks (Node 24 runs the last three).

## Licence

- Repository: Apache-2.0.
