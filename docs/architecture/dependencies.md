# Dependencies

Versions are pinned exactly. A new or upgraded dependency is the newest release at least two weeks old, unless a note here says why not. Review a new dependency's source, licence and install scripts before adding it, and record it here.

- Lean `leanprover/lean4:v4.35.0`, pinned in `lean-toolchain` and installed by `elan`.
- Mathlib tag `v4.35.0`, commit `56a005855ea17e0b0958f73ec801ae140b0a1679`; `lake-manifest.json` pins its transitive packages at exact commits.
- Node 24 runs only the repository-check scripts in `tools/`; there are no npm dependencies.
