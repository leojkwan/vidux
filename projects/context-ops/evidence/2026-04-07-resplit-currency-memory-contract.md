# 2026-04-07 Resplit Currency Memory Contract

## Why this slice
`resplit-currency` was still an active live-root outlier in the fleet: the prompt read only a fixed `~/.codex/...` memory path and the memory file had accreted four full run recaps even though the lane only needs a rolling last-3 checkpoint window.

## Facts gathered
- [Source: live fleet audit, 2026-04-07] The mounted live automation root at `/Users/leokwan/Development/ai/automations` currently contains `26` repo-backed automation definitions, while `~/.codex/sqlite/codex-dev.db` contains `33` rows with only one live-root mismatch (`resplit-super-team-hourly` paused `cwds`). `resplit-currency` itself is clean on status/cadence/model fields.
- [Source: `/Users/leokwan/Development/ai/automations/resplit-currency/automation.toml`, read 2026-04-07] The active harness still reads `/Users/leokwan/.codex/automations/resplit-currency/memory.md` as a single fixed path and does not tell future runs how to keep memory compact.
- [Source: `/Users/leokwan/.codex/automations/resplit-currency/memory.md`, read 2026-04-07] The live memory file had `12` bullet notes / `8748` bytes, representing `4` full run recaps with long command and artifact transcripts.
- [Source: `automation_runs` for `resplit-currency`, queried 2026-04-07] The lane is healthy and active: the latest archived runs shipped visible picker, row-pill, and workbench UX proof, while one newer run is currently in progress.
- [Source: centralized ledger tail, read 2026-04-07] A current live `resplit-currency` run is already active in a detached Resplit iOS worktree, so the safest bounded change is prompt and memory normalization only, not cadence or scope churn.

## Change shipped
1. Tightened the shared `resplit-currency` harness so memory rehydration checks `$CODEX_HOME/...`, then `~/.codex/...`, then repo fallback.
2. Added an explicit checkpoint rule: keep only the last 3 concise timestamped notes and store the shipped UX delta, proof summary, and next seam instead of full transcript dumps.
3. Trimmed the live `resplit-currency` memory file to the latest 3 concise notes.
4. Synced the live SQLite `prompt` field for `resplit-currency` to the same repo-backed text without changing cadence, model, reasoning, or status.

## Remaining exposure
- The currently in-progress `resplit-currency` run started before this patch, so it may append one last verbose old-contract checkpoint before the tightened harness takes effect on the next cycle.
- The detached ai worktree used by this orchestrator is still a stale partial copy of the fleet (`14` TOMLs vs `26` in the mounted live root), so self-audit must keep preferring the mounted live root plus SQLite until that workspace is refreshed deliberately.
- The `7` DB-only active rows (`6` StrongYes burst lanes plus `vidux-meta`) remain the main fleet-level drift cluster once active memory-contract outliers are exhausted.
