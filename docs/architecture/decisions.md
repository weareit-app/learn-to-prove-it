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
