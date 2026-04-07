# 2026-04-06 Vidux Endurance Memory Contract

## Why this slice
The shared repo-vs-DB truth is still clean for every repo-backed automation ID, so the next safe control-plane defect is prompt-state drift inside an active public Vidux meta lane. `vidux-endurance` was still reading an ambiguous relative `memory.md` path and had started accreting repetitive watch-mode notes even though the queue and proof bundle were unchanged.

## Facts gathered
- [Source: `~/.codex/automations -> /Users/leokwan/Development/ai/automations`, read 2026-04-06] The live automation root on this machine is the shared ai repo, not the detached worktree copy.
- [Source: `/Users/leokwan/Development/ai/automations/vidux-endurance/automation.toml`, read 2026-04-06] The active harness said to use "this automation's `memory.md`" only as supporting context, but it did not name the real memory path, did not mention `$CODEX_HOME` or `~/.codex` fallback, and did not require rolling last-3 retention.
- [Source: `/Users/leokwan/Development/ai/automations/vidux-endurance/memory.md`, read 2026-04-06] The live shared memory file contained `6` retained entries, with the latest `4` all describing the same unchanged Project 10 Task 10.1 `next_action=burst` handoff in slightly different words.
- [Source: `~/.codex/sqlite/codex-dev.db` table `automation_runs`, queried 2026-04-06] The latest `4` `vidux-endurance` runs all landed `PENDING_REVIEW` with the same queue-hot outcome: `Project 10 burst queued` or `Endurance burst queued`, and each inbox summary still pointed at the same appeals investigation for `D3`, `D7`, and `D9`.
- [Source: repo-vs-DB comparison, 2026-04-06] The live scheduler row for `vidux-endurance` already matches the shared repo-backed TOML on status, cadence, model, reasoning, cwd, and prompt except for the contract change shipped in this slice, so a prompt-and-memory cleanup is safe to sync directly.

## Change shipped
1. Tightened `/Users/leokwan/Development/ai/automations/vidux-endurance/automation.toml` so the lane reads the last 3 notes from the real automation root using `$CODEX_HOME/automations/...` when available, otherwise `~/.codex/automations/...`, otherwise the repo-backed path.
2. Added an explicit watch-mode rule that unchanged `next_action=burst` handoffs should stay terse instead of appending a fourth synonymous queue-hot summary when `PLAN.md` and the proof bundle did not move.
3. Updated the checkpoint contract so the live `vidux-endurance` memory file must keep only the last 3 concise timestamped notes.
4. Trimmed `/Users/leokwan/Development/ai/automations/vidux-endurance/memory.md` to the latest 3 entries and prepared the matching live SQLite prompt sync.

## Remaining exposure
- `resplit-android` still has repeated owner-blocked proof-refresh notes with no explicit fallback or rolling last-3 memory contract.
- The `7` DB-only active rows remain outside repo truth and still need an explicit ownership decision once the environment blocker around the dirty canonical ai checkout is cleared.
