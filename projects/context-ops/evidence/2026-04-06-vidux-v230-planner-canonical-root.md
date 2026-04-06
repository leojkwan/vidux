# 2026-04-06 Vidux v2.3.0 Planner Canonical Root

## Why this slice
`vidux-v230-planner` is still an active automation, but its harness says to improve Vidux in `/Users/leokwan/Development/ai` and reads all authority files through `skills/vidux/...`. That was true before canonical unification; it is no longer the public repo story.

## Facts gathered
- `/Users/leokwan/Development/vidux/PLAN.md` says the public `leojkwan/vidux` repo is now the canonical home for Vidux and the copy in `ai/skills/vidux/` is retired.
- `/Users/leokwan/Development/ai/automations/vidux-v230-planner/automation.toml` still points its mission, authority store, evidence, code paths, and `cwds` at `/Users/leokwan/Development/ai` plus `skills/vidux/...`.
- `/Users/leokwan/Development/ai/skills/vidux` is currently a symlink to `/Users/leokwan/Development/vidux`, so the old harness still works locally on this machine, but only through hidden path indirection.
- The live SQLite row for `vidux-v230-planner` matches repo truth on prompt-bearing fields, so fixing the repo-backed harness requires a matching scheduler prompt + `cwds` update in the same run.
- `automation_runs` currently has no rows for `vidux-v230-planner` or `vidux-endurance`, so the broader missing-run scheduler drift is real, but rewriting `next_run_at` without root-cause evidence would be guesswork.

## Change shipped
1. Repointed `vidux-v230-planner` from `/Users/leokwan/Development/ai` to `/Users/leokwan/Development/vidux`.
2. Replaced legacy `skills/vidux/...` authority and evidence paths with direct public-repo paths.
3. Synced the live scheduler row's `prompt` and `cwds` to the same canonical-root contract without manually forcing a scheduler timestamp.

## Remaining exposure
- `vidux-endurance`, `resplit-android`, `resplit-nurse`, and `resplit-vidux` still carry ai-hosted Vidux project-store paths.
- The cold `ACTIVE` rows for `vidux-v230-planner` and `vidux-endurance` still need a separate scheduler-drift investigation if they do not resume after prompt normalization.
