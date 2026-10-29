#!/bin/sh
# Every check this repository has; CI runs the same. Fetch Mathlib's build
# cache first with `lake exe cache get`.
set -eu
lake build
lake test
# The committed prove.how fixture matches the metadata in Lean.
lake exe export-exercise-metadata --check fixtures/prove-how/graph-comp.exercise-family.json
node tools/skills-sync/sync-skills.mjs --check
node tools/decision-records/check-no-adr-folder.mjs
node tools/action-pins/check-action-pins.mjs
