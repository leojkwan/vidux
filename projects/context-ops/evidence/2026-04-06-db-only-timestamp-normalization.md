# 2026-04-06 DB-Only Timestamp Normalization

## Why this slice
The shared repo-backed fleet is currently clean against live SQLite, so the next bounded defect is the `7` DB-only active rows that still sit outside repo truth. They are marked `ACTIVE`, but they have null `next_run_at`, zero recorded runs, and timestamp fields written in seconds instead of the milliseconds used by the live scheduler schema.

## Facts gathered
- [Source: `/Users/leokwan/Development/vidux/projects/context-ops/PLAN.md`, read 2026-04-06 20:26 EDT] The last recorded next move after the dirty-checkout escalation was to classify the `6` StrongYes burst lanes plus `vidux-meta`, not to spend another cycle rediscovering the canonical repo sync blocker.
- [Source: `~/.codex/sqlite/codex-dev.db` table `automations`, audit 2026-04-06 20:20-20:26 EDT] The live scheduler currently contains `34` rows: `27` shared repo-backed IDs plus `7` DB-only active rows (`strongyes-backend`, `strongyes-content-scraper`, `strongyes-email`, `strongyes-problem-builder`, `strongyes-product`, `strongyes-ux`, `vidux-meta`).
- [Source: repo-vs-DB comparison against `/Users/leokwan/Development/ai/automations`, audit 2026-04-06 20:20 EDT] The `27` shared IDs have zero mismatches on `status`, `rrule`, `model`, `reasoning_effort`, `cwds`, or `prompt`, so the live defect is isolated to the DB-only cluster.
- [Source: `~/.codex/sqlite/codex-dev.db` table `automations`, audit 2026-04-06 20:26 EDT] All `7` DB-only rows have `created_at = updated_at = 1775517838`, which decodes to `2026-04-06 19:23:58` when interpreted as seconds but to `1970-01-21` when interpreted as milliseconds. Shared active rows use millisecond timestamps like `1775442860568`.
- [Source: `~/.codex/sqlite/codex-dev.db` table `automations`, audit 2026-04-06 20:20 EDT] Those same `7` rows all have null `next_run_at` and null `last_run_at` even though `status='ACTIVE'` and each row has a valid hourly RRULE.
- [Source: `~/.codex/sqlite/codex-dev.db` table `automation_runs`, audit 2026-04-06 20:20 EDT] The `7` DB-only rows have no recorded runs at all, unlike neighboring active shared rows that are already producing `IN_PROGRESS`, `PENDING_REVIEW`, or `ARCHIVED` entries.
- [Source: `/Users/leokwan/Development/vidux/scripts/vidux-fleet-rebuild.sh`, read 2026-04-06 20:27 EDT] The public rebuild script still writes `updated_at=strftime('%s','now')`, which stores seconds in a schema that otherwise uses millisecond epochs. This is a public writer-side bug even though the exact insert path for `created_at` was not confirmed in this run.

## Change shipped
1. Patched `/Users/leokwan/Development/vidux/scripts/vidux-fleet-rebuild.sh` so its cadence/status writes now stamp `updated_at` in milliseconds instead of seconds.
2. Normalized the live DB-only cluster in `~/.codex/sqlite/codex-dev.db`: converted `created_at` from `1775517838` to `1775517838000`, refreshed `updated_at` to current millisecond time, and seeded `next_run_at` from each row's existing hourly RRULE without changing mission, model, reasoning effort, or `cwds`.
3. Re-verified that all `7` rows now keep their previous cadence/model fields and have future local next-run slots: `strongyes-ux` `20:42:58`, `strongyes-content-scraper` `20:45:58`, `strongyes-product` `20:48:58`, `strongyes-backend` `20:51:58`, `strongyes-email` `20:54:58`, `strongyes-problem-builder` `20:57:58`, and `vidux-meta` `21:00:58` on 2026-04-06.

## Remaining exposure
- The exact creation path that wrote second-based `created_at` for these DB-only rows was not isolated in this run; the shipped public fix covers the visible `updated_at` writer surface and the live cluster is now repaired, but any other private/manual writer that still stamps seconds could recreate this drift later.
- These `7` rows remain DB-only rather than repo-backed. A later slice should decide whether they should stay intentionally local-only, be promoted into shared repo truth, or be retired once the StrongYes/Vidux fleet shape stabilizes.
