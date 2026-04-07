# 2026-04-06 StrongYes Revenue Memory Contract

## Why this slice
`strongyes-revenue-radar` was the remaining active StrongYes radar whose prompt still read self and sibling memory only from `$CODEX_HOME/...` even though `CODEX_HOME` is unset on this machine. That left the radar able to miss fresh release-train or revenue checkpoints and let its own shared memory drift past the intended rolling window.

## Facts gathered
- [Source: `printenv CODEX_HOME`, read 2026-04-06 23:07 EDT] `CODEX_HOME` is unset in the shell used for this run.
- [Source: `/Users/leokwan/Development/ai/automations/strongyes-revenue-radar/automation.toml`, read 2026-04-06 23:00 EDT] Authority lines 4 and 5 only pointed at `$CODEX_HOME/automations/...` for revenue and release-train memory, and the prompt had no explicit checkpoint rule to keep memory trimmed to the last 3 notes.
- [Source: `/Users/leokwan/Development/ai/automations/strongyes-revenue-radar/memory.md`, read 2026-04-06 23:00 EDT] The live shared memory file contained 4 retained notes, so the lane had already drifted outside the intended rolling window.
- [Source: `/Users/leokwan/Development/ai/automations/strongyes-content/automation.toml`, `/Users/leokwan/Development/ai/automations/strongyes-flow-radar/automation.toml`, read 2026-04-06 23:01 EDT] Other active StrongYes radars already require `$CODEX_HOME` or `~/.codex` fallback plus explicit `keep only the last 3 notes` memory retention.
- [Source: `~/.codex/sqlite/codex-dev.db` row `strongyes-revenue-radar`, read 2026-04-06 23:07 EDT] The live scheduler prompt still matched the repo-backed single-path text, so the safe fix is a narrow prompt and memory sync, not broader row churn.
- [Source: `git fetch --quiet` in `/Users/leokwan/Development/ai`, read 2026-04-06 22:58 EDT] Fetch is currently blocked with `cannot open '.git/FETCH_HEAD': No space left on device`, so this run should stay a narrow live-root patch instead of claiming a clean git-sync pass.

## Change shipped
1. Tightened `strongyes-revenue-radar` so self and release-train memory read from `$CODEX_HOME/...` when set and otherwise `~/.codex/...`.
2. Added an explicit checkpoint rule to keep only the last 3 revenue-radar notes.
3. Trimmed the live shared memory file to the last 3 notes and synced the matching SQLite prompt row back to repo truth.

## Remaining exposure
- `strongyes-ux-radar` still uses `$CODEX_HOME/...`-only memory paths, but its current live memory already fits the 3-note window, so it can wait for a separate bounded slice.
- The `7` DB-only active rows still remain outside repo truth and still show zero runs in `automation_runs`.
