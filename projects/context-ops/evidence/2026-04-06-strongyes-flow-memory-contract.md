# 2026-04-06 StrongYes Flow Memory Contract

## Why this slice
The shared repo-vs-DB automation truth is still clean for every repo-backed row, so the next safe control-plane defect is stale memory bloat on an active shared loop. `strongyes-flow-radar` is the largest active shared memory file, but its harness still only points at `$CODEX_HOME/...` paths even though this machine runs with `CODEX_HOME` unset.

## Facts gathered
- [Source: `printenv CODEX_HOME`, read 2026-04-06 22:05 EDT] `CODEX_HOME` is unset in the shell used for this run.
- [Source: `/Users/leokwan/Development/ai/automations/strongyes-flow-radar/automation.toml`, read 2026-04-06 22:05 EDT] `strongyes-flow-radar` is `ACTIVE` and its authority chain still reads self and sibling memory only from `$CODEX_HOME/automations/...`, with no explicit fallback to `~/.codex/automations/...` or a repo path when `CODEX_HOME` is absent.
- [Source: `/Users/leokwan/.codex/automations/strongyes-flow-radar/memory.md`, read 2026-04-06 22:05 EDT] The live shared memory file contained `8` retained checkpoints and `12351` bytes.
- [Source: `/Users/leokwan/Development/strongyes-web/vidux/ux-overhaul/PLAN.md` plus `evidence/2026-04-07-t70-live-shell-recheck.md`, read 2026-04-06 22:05 EDT] The newest flow-radar checkpoints mostly restate the same already-stored `T70` buyer-shell drift, so retaining eight full notes adds prompt weight faster than it adds new executable state.
- [Source: `realpath /Users/leokwan/.codex/automations/strongyes-flow-radar/memory.md`, run 2026-04-06 22:05 EDT] The live scheduler memory path resolves to `/Users/leokwan/Development/ai/automations/strongyes-flow-radar/memory.md`, so trimming the shared repo file also fixes the live memory source on this machine.
- [Source: repo-vs-DB comparison plus `~/.codex/sqlite/codex-dev.db`, audit 2026-04-06 22:05 EDT] The fleet currently shows `27` repo-backed IDs, `34` live scheduler rows, `7` DB-only active rows, and no shared-row mismatch for `strongyes-flow-radar` aside from this harness-memory contract drift.

## Change shipped
1. Tightened `/Users/leokwan/Development/ai/automations/strongyes-flow-radar/automation.toml` so self and sibling memory reads explicitly fall back to `~/.codex/automations/...` when `$CODEX_HOME` is unset, with repo memory only as a last fallback.
2. Added an explicit checkpoint rule that `strongyes-flow-radar` must keep only the last 3 notes in memory and should checkpoint only the changed proof delta when the seam is otherwise unchanged in the store.
3. Trimmed `/Users/leokwan/Development/ai/automations/strongyes-flow-radar/memory.md` down to the latest 3 checkpoints and synced the live SQLite prompt row to the updated repo truth.

## Remaining exposure
- Other active shared radars, especially `strongyes-content` and `strongyes-ux-radar`, still carry oversized memory files and should be normalized one lane at a time.
- The `7` DB-only active rows remain stalled and outside repo truth; this slice deliberately did not churn them again because that ownership decision is still separate from memory-contract cleanup.
