# 2026-04-06 Resplit Historical Path Drift

## Why this slice
The active Resplit loops already read the recovered public store at `/Users/leokwan/Development/vidux/projects/resplit/`, but retained control-plane copy still pointed at the legacy `ai/skills/vidux/projects/resplit/...` path. That left the fleet audit with stale recovery guidance even after the live writer and radar loops were fixed.

## Facts gathered
- `/Users/leokwan/Development/ai/automations/resplit-nurse/automation.toml` and `/Users/leokwan/Development/ai/automations/resplit-vidux/automation.toml` already reference `/Users/leokwan/Development/vidux/projects/resplit/...`.
- `/Users/leokwan/Development/ai/automations/resplit-oversight/automation.toml` still referenced `/Users/leokwan/Development/ai/skills/vidux/projects/resplit/PLAN.md` even though it is a paused historical definition.
- `/Users/leokwan/Development/ai/automations/README.md` still documented the Resplit external store and inventory under the same legacy `ai/skills/vidux/projects/resplit/...` path.
- `~/.codex/sqlite/codex-dev.db` still had the legacy Resplit store path in paused legacy rows `resplit-hourly-mayor`, `resplit-ios-ux-lab`, `resplit-oversight`, and `resplit-super-nurse-hourly`; only `resplit-oversight` is repo-backed today.
- All four stale SQLite rows are `PAUSED`, so the safe bounded fix in this run is the repo-backed paused definition plus shared documentation, not a wider rewrite of DB-only history.

## Change shipped
1. Updated `/Users/leokwan/Development/ai/automations/resplit-oversight/automation.toml` to point at the public Resplit store in `/Users/leokwan/Development/vidux/projects/resplit/PLAN.md`.
2. Updated `/Users/leokwan/Development/ai/automations/README.md` so the documented Resplit store and inventory paths match the live active prompts.
3. Synced the live SQLite prompt for `resplit-oversight` to the repo-backed prompt so paused historical repo truth and scheduler truth no longer drift.

## Remaining exposure
- DB-only paused legacy Resplit rows still carry the old `ai/skills/vidux/projects/resplit/...` path. They are inactive, but they should eventually be archived, documented, or normalized in one historical-cleanup slice so future audits stop rediscovering them.
- `vidux-endurance` and `vidux-v230-planner` remain the hotter scheduler issue because both are `ACTIVE` with past `next_run_at` and no `automation_runs`. This run intentionally did not rewrite those timestamps without root-cause proof.
