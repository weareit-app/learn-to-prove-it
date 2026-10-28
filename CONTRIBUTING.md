# Contributing

## Setup

```sh
lake exe cache get
```

## Checks

```sh
./scripts/check.sh
```

runs `lake build` and the skills-sync and decision-record checks (Node 24 runs the last two). CI runs the same checks on every pull request.

## Pull requests

Explain the problem, the change, and how you checked it. Record any changed decision in `docs/architecture/decisions.md`. Don't add tests for unrelated code.
