# 2026-04-06 Resplit Android Memory Contract

## Goal
Confirm whether `resplit-android` is still paying repeat proof-refresh cost after the lane became purely owner-blocked, and decide whether the harness should compact unchanged blocked-state checkpoints instead.

## Sources
- [Source: `/Users/leokwan/Development/ai/automations/resplit-android/automation.toml`, read 2026-04-06] The active harness reads a fixed `~/.codex/automations/resplit-android/memory.md` path and only says "Update this automation's `memory.md` with one concise note," with no explicit runtime fallback or rolling-last-3 retention rule.
- [Source: `/Users/leokwan/Development/ai/automations/resplit-android/memory.md`, read 2026-04-06] The live memory file retained 7 notes, and the latest 6 notes all describe the same owner-blocked Play submission boundary with only wording-level changes.
- [Source: `~/.codex/sqlite/codex-dev.db` table `automation_runs`, queried 2026-04-06] The last 6 archived `resplit-android` runs all ended on the same blocked handoff, with inbox summaries that only vary between "owner-blocked," "still blocked," and "proof refreshed."
- [Source: `~/.agent-ledger/activity.jsonl`, queried 2026-04-06] No recent centralized ledger rows were present for `repo=\"ai\"` plus `lane=\"resplit-android\"`, so the lane's durable truth is currently the automation memory plus run history rather than the shared ledger.

## Findings

### 1. The harness still treats blocked-state memory as an unbounded append log
The active `resplit-android` prompt never tells the lane to keep only the latest 3 notes or to retry a runtime memory fallback when `~/.codex/...` is absent. That makes the memory file the de facto long-term state store even though the actual project authority already lives in `/Users/leokwan/Development/vidux/projects/resplit-android/PLAN.md`.

### 2. The lane is restating one unchanged owner blocker instead of adding new proof
The latest memory notes repeatedly confirm the same boundary: privacy page exists, offline audit still passes, build proof still passes, and the missing input is still owner-provided Play signing or submission configuration. Recent automation runs echo the same message with only title wording changes, which is churn rather than new control-plane information.

### 3. The safe fix is harness compaction, not another proof-refresh loop
This lane is not missing launch proof; it is missing a tighter blocked-state contract. The control-plane repair is to read memory from the live runtime root, keep only the last 3 concise notes, and checkpoint unchanged owner-blocked state tersely unless new proof or a plan delta appears.

## Recommendations
- Tighten `resplit-android` so memory reads use `$CODEX_HOME/...` when present, otherwise `~/.codex/...`, with repo fallback only as a last resort.
- Make the checkpoint contract explicit: keep only the last 3 concise timestamped notes.
- When the same owner-blocked Play boundary is unchanged across recent notes and the plan did not move, checkpoint the unchanged blocker tersely instead of rerunning a full proof-refresh loop.
