# 2026-04-06 StrongYes UX Memory Contract

## Why this slice
`strongyes-ux-radar` was the remaining active StrongYes radar whose harness still read self and release-train memory only from `$CODEX_HOME/...` even though `CODEX_HOME` is unset on this machine. That left the radar able to miss its freshest sibling context while its shared live memory file had already drifted past the intended rolling last-3 window.

## Facts gathered
- [Source: `printenv CODEX_HOME`, read 2026-04-06 23:31 EDT] `CODEX_HOME` is unset in the shell used for this run.
- [Source: `/Users/leokwan/Development/ai/automations/strongyes-ux-radar/automation.toml`, read 2026-04-06 23:27 EDT] Authority lines 5 and 6 only pointed at `$CODEX_HOME/automations/...` for the UX radar and release-train memory, and the prompt had no explicit checkpoint rule requiring last-3 retention.
- [Source: `~/.codex/sqlite/codex-dev.db` row `strongyes-ux-radar`, read 2026-04-06 23:30 EDT] The live scheduler prompt matched the same single-path memory contract, so the safe fix is a narrow harness and memory sync, not broader cadence or model churn.
- [Source: `/Users/leokwan/Development/ai/automations/strongyes-ux-radar/memory.md`, read 2026-04-06 23:26 EDT] The live shared memory file contained 4 retained notes even though the latest seam had already cooled and the lane only needs the most recent 3 checkpoints.
- [Source: `/Users/leokwan/Development/ai/automations/strongyes-flow-radar/automation.toml`, `/Users/leokwan/Development/ai/automations/strongyes-revenue-radar/automation.toml`, read 2026-04-06 23:28 EDT] Other active StrongYes radars already require `$CODEX_HOME` or `~/.codex` fallback plus explicit rolling-last-3 memory retention, so `strongyes-ux-radar` was the remaining contract outlier inside that radar cluster.
- [Source: `git -C /Users/leokwan/Development/ai rev-list --left-right --count HEAD...origin/main`, read 2026-04-06 23:18 EDT] The canonical ai checkout remains `0 1` behind `origin/main` with unrelated staged deletes and edits, so this run should stay a narrow live-root patch instead of claiming a clean git-sync pass.

## Change shipped
1. Tightened `strongyes-ux-radar` so self and release-train memory read from `$CODEX_HOME/...` when set and otherwise `~/.codex/...`, with repo-backed fallback only as a last resort.
2. Added an explicit checkpoint rule to keep the live UX-radar memory file trimmed to the last 3 notes and compress unchanged seam restatement into delta-only checkpoints.
3. Trimmed the live shared memory file to the newest 3 notes, then re-trimmed once after one in-flight UX-radar run appended a final checkpoint under the old retention contract, and synced the matching SQLite prompt row back to repo truth.

## Remaining exposure
- The fleet still has `7` DB-only active rows outside repo truth, and they remain the bigger scheduler-health issue once these active radar memory contracts stop drifting.
- The canonical ai checkout is still dirty and one commit behind `origin/main`, so broader repo cleanup and push hygiene remain blocked on a deliberate sync window.
