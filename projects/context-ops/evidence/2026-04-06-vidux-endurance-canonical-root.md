# 2026-04-06 Vidux Endurance Canonical Root

## Why this slice
`vidux-endurance` is still an active automation, but its harness still treats the ai repo as the Vidux home. After canonical unification, that leaves one cold active lane depending on hidden `ai/skills/vidux -> /Users/leokwan/Development/vidux` indirection instead of the public repo it is supposed to validate.

## Facts gathered
- `/Users/leokwan/Development/vidux/PLAN.md` says the public `leojkwan/vidux` repo is the canonical Vidux home and the ai copy is retired.
- `/Users/leokwan/Development/ai/automations/vidux-endurance/automation.toml` still points its mission text, authority paths, checkpoint paths, and `cwds` at `/Users/leokwan/Development/ai` plus `skills/vidux/...`.
- The live SQLite row for `vidux-endurance` matches repo truth on the fields the scheduler actually stores (`prompt`, `cwds`, `status`, `rrule`, `model`, `reasoning_effort`), so fixing the repo-backed harness requires the same prompt + `cwds` change in SQLite.
- `~/.codex/sqlite/codex-dev.db` does not store `execution_environment`, and `automation_runs` currently has no rows for `vidux-endurance`; this slice should remove prompt/cwd drift, not guess at scheduler timestamps.
- `/Users/leokwan/Development/ai` is currently a dirty shared repo checkout, so keeping a Vidux-self-validation lane anchored there is unnecessary control-plane coupling even before the separate missing-run investigation.

## Change shipped
1. Repointed `vidux-endurance` from `/Users/leokwan/Development/ai` to `/Users/leokwan/Development/vidux`.
2. Replaced legacy `skills/vidux/...` authority and checkpoint paths with direct public-repo paths.
3. Synced the live scheduler row's `prompt` and `cwds` to the same canonical-root contract without manually forcing `next_run_at`.
4. Refreshed the lane memory so future audits can see that canonical-root drift was removed and scheduler drift is still the next diagnostic boundary if the row stays cold.

## Remaining exposure
- `vidux-endurance` is still an `ACTIVE` row with zero `automation_runs`; if it stays cold after this canonical-root fix, the next slice should investigate scheduler discovery or run gating rather than rewriting timestamps blindly.
- `resplit-android` still carries ai-hosted Vidux project-store paths for its external plan and could be normalized in a later control-plane run if it becomes the highest-leverage remaining drift.
