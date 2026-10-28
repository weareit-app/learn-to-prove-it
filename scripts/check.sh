#!/bin/sh
# Every check this repository has; CI runs the same. Fetch Mathlib's build
# cache first with `lake exe cache get`.
set -eu
lake build
node tools/skills-sync/sync-skills.mjs --check
node tools/decision-records/check-no-adr-folder.mjs
node tools/action-pins/check-action-pins.mjs
