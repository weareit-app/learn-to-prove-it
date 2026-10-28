# learn-to-prove-it

Verified mathematical exercise generators and checkers built on Mathlib.

Status: a new skeleton. The stack and checks are in place; the real functionality is still to be built.

## Getting started

```sh
lake exe cache get
./scripts/check.sh
```

`./scripts/check.sh` runs `lake build` and the skills-sync and decision-record checks (Node 24 runs the last two).

## Licence

- Repository: Apache-2.0.
