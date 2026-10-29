# Contributing

## Setup

```sh
lake exe cache get
```

## Checks

```sh
./scripts/check.sh
```

runs `lake build`, `lake test` (the Lean tests in `LearnToProveItTest`) and the skills-sync, decision-record and action-pin checks (Node 24 runs the last three). CI runs the same checks on every pull request.

## Pull requests

Explain the problem, the change, and how you checked it. Record any changed decision in `docs/architecture/decisions.md`. Don't add tests for unrelated code.
