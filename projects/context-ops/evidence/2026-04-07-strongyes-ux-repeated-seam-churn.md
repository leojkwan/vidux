# 2026-04-07 StrongYes UX Repeated-Seam Churn

## Why this slice
`strongyes-ux-radar` was no longer a memory-contract problem. The live seam was already durable in `PLAN.md`, the UX constraint, and release-train memory, but the lane was still dispatching every 20 minutes and opening the same blocked review item with new wording.

## Facts gathered
- [Source: `/Users/leokwan/Development/ai/automations/strongyes-ux-radar/automation.toml`, read 2026-04-07] The shared harness still ran on `FREQ=HOURLY;INTERVAL=1;BYMINUTE=1,21,41` even though it already said unchanged seams should checkpoint only the changed proof delta.
- [Source: `~/.codex/sqlite/codex-dev.db` `automation_runs`, queried 2026-04-07] The last `12` `strongyes-ux-radar` runs averaged a `20.0` minute gap.
- [Source: `~/.codex/sqlite/codex-dev.db` `automation_runs`, queried 2026-04-07] The last `6` `strongyes-ux-radar` runs all ended `PENDING_REVIEW` with the same blocked pricing-auth/domain seam and equivalent restore-domain-access next moves.
- [Source: `/Users/leokwan/Development/ai/automations/strongyes-ux-radar/memory.md`, read 2026-04-07] The last `3` retained UX notes all re-proved the same public pricing/auth/domain seam already represented by blocked `T70` / `T75`, while runtimes were `~6m`, `~7m`, and `~18m`.
- [Source: `/Users/leokwan/Development/ai/automations/strongyes-release-train/memory.md`, read 2026-04-07] Release-train already keeps the same public auth/domain ownership seam blocked and explicitly says no code or deploy move is honest until domain access changes.
- [Source: `/Users/leokwan/Development/strongyes-web/vidux/ux-overhaul/PLAN.md`, read 2026-04-07] The current StrongYes store already carries blocked `T70` and `T75`, so the UX lane was not discovering a new queue truth.

## Change shipped
1. Slowed `strongyes-ux-radar` from three passes per hour to one hourly pass so the lane monitors the blocked seam without flooding browser worktrees and review inboxes.
2. Tightened the shared UX harness so when the same blocked public pricing/auth seam is already durable in `PLAN.md`, the UX constraint, and release-train memory, the lane performs only one lightweight probe bundle and keeps the inbox framing stable unless proof or ownership changes.
3. Synced the live SQLite row's `prompt`, `rrule`, `updated_at`, and `next_run_at` back to the same repo-backed truth.

## Remaining exposure
- The cooled DB-only `8`-row governance seam is still unchanged and remains out of scope until approval or scheduler state changes.
- If the hourly UX radar still reopens the same unchanged seam after this cadence reduction, the next fix should target inbox/output phrasing or consider pausing the lane until the owner-side domain access changes.
