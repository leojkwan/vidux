# 2026-04-07 Public Vidux Control-Plane Drift

## Why this slice
The public `vidux/PLAN.md` still described the control plane as a completed DB-only cutover with no repo-backed TOMLs and no orchestrator role, but the current machine still runs the fleet from repo-backed `/Users/leokwan/Development/ai/automations` plus live SQLite. That stale public story sits inside the orchestrator's authority chain and can reintroduce self-drift even when the live fleet is otherwise stable.

## Facts gathered
- [Source: `/Users/leokwan/Development/vidux/PLAN.md`, read 2026-04-07] The public Decision Log still said "Automations are DB-only. No repo-backed TOMLs." and the next line still claimed `ai/automations/` plus the orchestrator role were removed.
- [Source: filesystem audit, 2026-04-07] `find /Users/leokwan/Development/ai/automations -mindepth 2 -maxdepth 2 -name automation.toml` returned `26` repo-backed automation definitions currently present on disk.
- [Source: `~/.codex/sqlite/codex-dev.db` table `automations`, queried 2026-04-07] Live SQLite currently contains `34` rows with `20` active rows, including an active `codex-automation-orchestrator` row.
- [Source: `~/.codex/sqlite/codex-dev.db` left join of `automations` and `automation_runs`, queried 2026-04-07] The `8` DB-only active rows (`strongyes-backend`, `strongyes-content-scraper`, `strongyes-email`, `strongyes-problem-builder`, `strongyes-product`, `strongyes-ux`, `vidux-meta`, `vidux-test-grader`) still have `0` recorded runs and null `last_run_at` / `next_run_at`, so the DB-only cluster is still stalled rather than authoritative.
- [Source: `git pull --rebase` in `/Users/leokwan/Development/ai`, attempted 2026-04-07] The canonical ai checkout is still dirty and `behind 1`, so today is not a safe moment for broad fleet restructuring or another experimental source-of-truth swing.

## Change shipped
1. Corrected the public `vidux/PLAN.md` Decision Log so the 2026-04-06 DB-only cutover and orchestrator retirement are explicitly treated as a historical experiment, not present-tense truth.
2. Added a fresh public progress note that the current control plane on this machine remains repo-backed `ai/automations` plus live SQLite until a verified DB-only cutover actually exists.

## Remaining exposure
- The `8` DB-only active rows are still outside repo truth and still need an explicit archive, promotion, or approval-backed retirement decision.
- The canonical `/Users/leokwan/Development/ai` checkout still cannot satisfy Captain's pull-before-edit contract cleanly because of unrelated local changes, so repo-backed fleet edits must remain narrowly scoped.
