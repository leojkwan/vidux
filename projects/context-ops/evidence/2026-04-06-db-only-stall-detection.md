# 2026-04-06 DB-Only Stall Detection

## Why this slice
The previous DB-only repair normalized timestamps and seeded `next_run_at`, but that alone did not prove the hidden local fleet could actually dispatch. The control plane still lacked a machine-auditable check for active scheduler rows that stay overdue with zero runs, which let the public story over-claim health after the timestamp fix.

## Facts gathered
- [Source: `~/.codex/sqlite/codex-dev.db` table `automations`, audit 2026-04-06 21:26-21:31 EDT] The live scheduler still contains `34` rows total: `27` shared repo-backed IDs plus `7` DB-only active rows (`strongyes-backend`, `strongyes-content-scraper`, `strongyes-email`, `strongyes-problem-builder`, `strongyes-product`, `strongyes-ux`, `vidux-meta`).
- [Source: `~/.codex/sqlite/codex-dev.db` left join of `automations` and `automation_runs`, audit 2026-04-06 21:29 EDT] All `7` DB-only active rows still have `0` recorded runs and null `last_run_at`, while their `next_run_at` values are already overdue by `30-48` minutes local time.
- [Source: `~/.agent-ledger/activity.jsonl`, audit 2026-04-06 21:28 EDT] Recent Codex live entries still exist for `strongyes-web` and `vidux`, so the machine is not generally idle; the silent seam is specific to these scheduler rows, not a total Codex shutdown.
- [Source: `/Users/leokwan/Development/vidux/scripts/vidux-doctor.sh`, read 2026-04-06 21:27 EDT] The public doctor already checked worktrees, active-plan collisions, orphan automation dirs, watch-harness scope, browser pressure, and Codex thread pressure, but it had no scheduler-row audit for active overdue zero-run rows.

## Change shipped
1. Added `--automation-db` to `/Users/leokwan/Development/vidux/scripts/vidux-doctor.sh` so runtime-health checks can inspect a chosen Codex automation SQLite file instead of depending on the machine default.
2. Added a new doctor check, `stalled_active_automation_rows`, that warns when `ACTIVE` rows have no runs, no `last_run_at`, and `next_run_at` older than a 10-minute grace window. The check reports whether each row is repo-backed or DB-only.
3. Added a contract test in `/Users/leokwan/Development/vidux/tests/test_vidux_contracts.py` that seeds a temp SQLite DB with an overdue zero-run active row and asserts the doctor emits the new warning.
4. Verified the live doctor run against `~/.codex/sqlite/codex-dev.db` now surfaces the real `7`-row stalled DB-only cluster instead of treating the fleet as scheduler-healthy by omission.

## Remaining exposure
- This run did not mutate the `7` stalled DB-only rows again. The previous timestamp re-arm already happened, and redoing row-level writes without isolating the dispatch path would violate the anti-loop rule.
- The next control-plane slice should decide whether these `7` DB-only rows are intentionally local-only but scheduler-ineligible, whether the DB-only rebuild flow is missing another required field/write, or whether the rows should be promoted into repo truth or retired.
