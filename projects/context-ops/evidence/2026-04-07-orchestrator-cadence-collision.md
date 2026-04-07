# 2026-04-07 Orchestrator Cadence Collision

## Why this slice
The repo-backed fleet and live scheduler are currently aligned on their shared rows, so the next high-leverage control-plane defect is the orchestrator itself running too often for the amount of work it is doing. A control-plane loop that overlaps its own runtime creates thread pressure and churn before it can reduce either elsewhere.

## Facts gathered
- [Source: `/Users/leokwan/Development/ai/automations/codex-automation-orchestrator/automation.toml`, read 2026-04-07 00:15-00:25 EDT] The shared harness was still `ACTIVE` on `FREQ=HOURLY;INTERVAL=1;BYMINUTE=4,24,44`, which fires every 20 minutes.
- [Source: `~/.codex/sqlite/codex-dev.db` table `automation_runs`, queried 2026-04-07 00:21 EDT] The last `12` `codex-automation-orchestrator` runs were spaced `19.98` minutes apart on average (`1200213`, `1200202`, `1183205`, `1200296`, `1200283`, `1200180`, `1200225`, `1200206`, `1200197`, `1200185`, `1200227` ms gaps).
- [Source: `/Users/leokwan/Development/ai/automations/codex-automation-orchestrator/memory.md`, read 2026-04-07 00:10-00:20 EDT] The last 3 retained orchestrator notes reported runtimes of `~25m`, `~23m`, and `~27m`, all at or above the 20-minute interval.
- [Source: `~/.codex/sqlite/codex-dev.db` table `automations`, queried 2026-04-07 00:15 EDT] The current fleet still reads `26` repo-backed TOMLs against `33` live scheduler rows with `7` DB-only active rows.
- [Source: `/Users/leokwan/Development/ai` git status, read 2026-04-07 00:16 EDT] The canonical `ai` checkout is still dirty and `0 1` behind `origin/main`, so the safe move is a narrowly scoped live-root patch rather than a broader sync pass.

## Change shipped
1. Tightened the shared orchestrator harness so runtime-at-or-above-interval counts as unhealthy density that must be fixed before another fleet-facing tweak.
2. Slowed `/Users/leokwan/Development/ai/automations/codex-automation-orchestrator/automation.toml` from `4,24,44` to a single hourly minute-`14` slot.
3. Synced the live SQLite row's `prompt`, `rrule`, `updated_at`, and `next_run_at` to the same repo-backed truth.

## Remaining exposure
- The `7` DB-only active rows are still outside repo truth and remain the next fleet-level drift cluster once the orchestrator proves it can run cleanly on the slower cadence.
- The canonical `ai` checkout still cannot be pulled cleanly, so broader repo sync and commit/push work remain blocked on an explicit human cleanup window.
