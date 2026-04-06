# 2026-04-06 Orchestrator Authority Drift Audit

## Why this slice
The control plane kept treating repo-backed automation truth as missing or retired, but the current machine still has a live shared automation tree plus matching scheduler rows. The actual drift was the orchestrator's own authority chain: one dead file reference, one stale public retirement story, and a legacy assumption about the scheduler schema.

## Facts gathered
- [Source: filesystem audit, 2026-04-06] `find /Users/leokwan/Development/ai/automations -maxdepth 2 -name automation.toml` returned `27` repo-backed automation definitions currently present on disk.
- [Source: SQLite audit, 2026-04-06] `~/.codex/sqlite/codex-dev.db` currently contains `33` automation rows: `27` IDs shared with the repo tree and `6` DB-only active StrongYes rows: `strongyes-backend`, `strongyes-content-scraper`, `strongyes-email`, `strongyes-problem-builder`, `strongyes-product`, and `strongyes-ux`.
- [Source: repo-vs-DB comparison, 2026-04-06] The `27` shared IDs have zero mismatches on `status`, `rrule`, `model`, `reasoning_effort`, `cwds`, or `prompt`.
- [Source: filesystem audit, 2026-04-06] `/Users/leokwan/Development/ai/automations/README.md` is absent, so the orchestrator prompt's current read order includes a dead authority file.
- [Source: `/Users/leokwan/Development/vidux/PLAN.md`, read 2026-04-06] The public Vidux plan still says repo-backed automations were retired and the orchestrator role was removed, but that is not the live control-plane truth on this machine today.
- [Source: SQLite schema, 2026-04-06] The live `automations` table contains `id`, `name`, `prompt`, `status`, `next_run_at`, `last_run_at`, `cwds`, `rrule`, `created_at`, `updated_at`, `model`, and `reasoning_effort`; there is no `execution_env` column on this machine.
- [Source: `git pull --rebase` in `/Users/leokwan/Development/ai`, 2026-04-06] Pull is still blocked by unrelated staged and unstaged changes, so the safe move is a tightly scoped control-plane patch rather than a broad repo sync pass.

## Change shipped
1. Updated the public Context Ops store and Vidux plan to treat repo-backed `ai/automations` plus live SQLite as the current live control plane until an explicit DB-only cutover is actually shipped and verified.
2. Tightened the orchestrator prompt to drop the missing README dependency, cite the real SQLite schema, and prefer current filesystem + SQLite evidence over stale retrospective notes when authority sources disagree.
3. Synced the live `codex-automation-orchestrator` scheduler prompt to the same repo-backed text.

## Remaining exposure
- The DB-only StrongYes cluster remains active outside repo truth and shows null `next_run_at` in SQLite. A later slice should decide whether these rows should be documented, archived, or promoted into repo truth before they create more invisible scheduler drift.
- The ai repo still cannot `git pull --rebase` cleanly because of unrelated local changes, so broader fleet restructuring still needs an explicit sync window.
