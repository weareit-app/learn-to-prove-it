# Architecture decisions

The one record of this repository's decisions, newest last within each section. Changing an agreed choice in `AGENTS.md` adds a dated entry here.

## Starting point

Decided when the repository was generated (see its first commit).

- Visibility: public.
- Licence. Repository: Apache-2.0.
- Lean `leanprover/lean4:v4.35.0` with Mathlib `v4.35.0` (commit `56a005855ea17e0b0958f73ec801ae140b0a1679`), the factory's verified pair. Lean files use the module system (`module`, `public import`). Upgrading Lean or Mathlib is an explicit change made in this repository.
- No dependency on private lean-to-it.
- `lean-to` is a planned dependency: the architecture intends it, but it is not in the package files yet. Adding it is a recorded integration milestone, once `lean-to` publishes a version to pin.
- Decisions live in this file; `docs/adr/` is not used, and `tools/decision-records/check-no-adr-folder.mjs` fails if it exists.

## Changes

- 2026-10-28: Issues and specs move from local Markdown under `.scratch/` to GitHub Issues on `weareit-app/learn-to-prove-it`, with the five default triage labels created there. `docs/agents/issue-tracker.md` is the GitHub template from `setup-matt-pocock-skills`.
- 2026-10-28: Lean tests live in the `LearnToProveItTest` library, as `#guard_msgs` checks. `lake test` builds them, and `./scripts/check.sh` (so CI) runs `lake test`.
- 2026-10-28: An exercise's proof obligation is a named, `@[expose]`d `Prop` definition, so importers and the checker see its statement. Learners' Lean proofs are checked by `checkSubmission`: elaborate, kernel-check in a throwaway environment, allow only `propext`, `Classical.choice` and `Quot.sound`. Its verdict is about the mathematics only, never the learner.
- 2026-10-28: Exercise metadata is this repository's own export format, `learn-to-prove-it/exercise-family-export` `0.1.0`, written as Lean data in a module without Mathlib and printed by `lake exe export-exercise-metadata`. The committed fixture under `fixtures/prove-how/` must match it (`./scripts/check.sh` checks), and tests check it against the Lean declarations it names. It follows prove.how's logical `ExerciseFamily` and `AssessmentDesign` roles but does not copy `@learn-it/contracts`, which is unpublished. Competency IDs are proposals in the `learn-to-prove-it:` namespace.
- 2026-10-28: A verdict's citations are the watched declarations in the proof's whole dependency closure, with a flag saying whether the closure was complete. Under the module system imported proofs are hidden, so citations there are partial. A checking environment should use plain imports, and `LearnToProveItTest/FullEnvironment.lean` is a non-module test for that case (the test library builds by glob, since no module may import it). A missing citation is never evidence of independent derivation.
- 2026-10-28: The checker is not a sandbox. No executable, server or tool in this repository runs it on untrusted input; that waits for the `lean-on-it` integration.
- 2026-10-28: The checker never trusts kernel checks made during elaboration, since a submission can set `debug.skipKernelTC` for its own auxiliary declarations. It re-checks every declaration elaboration added, and then the proof, with a synchronous kernel pass from the caller's environment that forces checking on. Runtime limits become a `limit exceeded` rejection, and `let rec`/`where` are rejected as unsupported.
- 2026-10-28: The checker restores the message log, trace state, info trees and snapshot tasks. It cannot restore process-wide state, such as Lean's realization cache, nor bound a submission that lifts `maxHeartbeats`, so the `lean-on-it` runner must check each submission in a fresh process with wall-clock and memory limits.
