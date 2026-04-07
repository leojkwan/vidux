# 2026-04-06 StrongYes Release Memory Contract

## Why this slice
The shared repo-vs-DB automation truth is still clean for every repo-backed row, so the next safe control-plane defect is stale memory bloat on an active shared loop. `strongyes-release-train` is an active writer automation whose harness already depends on reading only the latest sibling radar notes, but its own `memory.md` kept seven full checkpoints instead of the intended rolling window.

## Facts gathered
- [Source: `/Users/leokwan/Development/ai/automations/strongyes-release-train/automation.toml`, read 2026-04-06 21:46 EDT] `strongyes-release-train` is `ACTIVE`, reads sibling radar memory as part of its authority chain, and tells the run to update its own memory before stopping, but it never explicitly says to keep only the last 3 notes or what to do when `$CODEX_HOME` is unset.
- [Source: `/Users/leokwan/Development/ai/automations/strongyes-release-train/memory.md`, read 2026-04-06 21:46 EDT] The live shared memory file contained `7` retained checkpoints and `11141` bytes, including four superseded pre-`T70` notes beyond the current working set.
- [Source: `/Users/leokwan/Development/strongyes-web/vidux/ux-overhaul/PLAN.md`, read 2026-04-06 21:46 EDT] The current release-train lane is still blocked on the same operator-owned `T70` custom-domain re-home, so retaining older pre-blocker checkpoints adds context weight without adding a new executable slice.
- [Source: repo-vs-DB comparison, audit 2026-04-06 21:35-21:46 EDT] The shared fleet still has `27` repo-backed IDs, `34` live scheduler rows, `7` DB-only active stalled rows, and `0` shared-row mismatches on `status`, `rrule`, `model`, `reasoning_effort`, `cwds`, or `prompt`.
- [Source: `realpath /Users/leokwan/.codex/automations/strongyes-release-train/memory.md`, run 2026-04-06 21:47 EDT] The live scheduler memory path resolves to `/Users/leokwan/Development/ai/automations/strongyes-release-train/memory.md`, so trimming the shared repo file also fixes the live memory source on this machine.

## Change shipped
1. Tightened `/Users/leokwan/Development/ai/automations/strongyes-release-train/automation.toml` so sibling memory reads explicitly fall back to `~/.codex/automations/...` when `$CODEX_HOME` is unset.
2. Tightened the same harness checkpoint rule so `strongyes-release-train` must keep only the last 3 notes in its own memory file.
3. Trimmed `/Users/leokwan/Development/ai/automations/strongyes-release-train/memory.md` down to the latest 3 checkpoints and synced the live SQLite prompt row to the updated repo truth.

## Remaining exposure
- Other active shared loops, especially the StrongYes radars, still have oversized memory files and should be normalized one lane at a time instead of waiting for them to bloat further.
- The `7` DB-only active rows remain stalled and outside repo truth; this slice deliberately did not churn them again because the current failure mode is already surfaced by the doctor and still needs a separate ownership decision.
