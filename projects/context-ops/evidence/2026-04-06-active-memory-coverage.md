# 2026-04-06 Active Memory Coverage Audit

## Why this slice
The shared control plane is currently clean on repo-vs-DB fields for every repo-backed automation row, so the next bounded defect is missing durable memory on active shared loops whose prompts explicitly depend on `memory.md`.

## Facts gathered
- [Source: `/Users/leokwan/Development/ai/automations`, audit 2026-04-06 19:47 EDT] The canonical shared automation root currently contains `27` repo-backed `automation.toml` files on disk.
- [Source: `~/.codex/sqlite/codex-dev.db` table `automations`, audit 2026-04-06 19:47 EDT] The live scheduler currently contains `34` rows: `27` shared IDs plus `7` DB-only active rows (`strongyes-backend`, `strongyes-content-scraper`, `strongyes-email`, `strongyes-problem-builder`, `strongyes-product`, `strongyes-ux`, `vidux-meta`).
- [Source: repo-vs-DB comparison, audit 2026-04-06 19:47 EDT] The `27` shared IDs have zero mismatches on `status`, `rrule`, `model`, `reasoning_effort`, `cwds`, or `prompt`.
- [Source: `/Users/leokwan/Development/ai/automations/resplit-asc/automation.toml`, read 2026-04-06 19:47 EDT] `resplit-asc` is `ACTIVE` and its authority chain explicitly reads `/Users/leokwan/.codex/automations/resplit-asc/memory.md`, but no shared `memory.md` file existed in the canonical automation root.
- [Source: `/Users/leokwan/Development/ai/automations/resplit-currency/automation.toml`, read 2026-04-06 19:47 EDT] `resplit-currency` is `ACTIVE` and its authority chain explicitly reads `/Users/leokwan/.codex/automations/resplit-currency/memory.md`, but no shared `memory.md` file existed in the canonical automation root.
- [Source: `~/.codex/sqlite/codex-dev.db` table `automation_runs`, read 2026-04-06 19:47 EDT] Recent `resplit-asc` and `resplit-currency` runs exist, but the rows carry no inbox title or summary, so there was no alternate durable note surface compensating for the missing memory files.
- [Source: `git pull --rebase` in `/Users/leokwan/Development/ai`, attempted 2026-04-06 19:47 EDT] Pull is still blocked by unrelated local changes, so the safe move is a narrowly scoped memory bootstrap instead of broader repo cleanup.

## Change shipped
1. Added `/Users/leokwan/Development/ai/automations/resplit-asc/memory.md` with a bootstrap note describing the missing-memory repair and the next required checkpoint shape.
2. Added `/Users/leokwan/Development/ai/automations/resplit-currency/memory.md` with the same durable-memory bootstrap for the currency lane.
3. Left SQLite rows untouched because the shared repo and live scheduler already match for both prompts and all other shared fields.

## Remaining exposure
- The `7` DB-only active rows are still outside repo truth and all have null `next_run_at`, so the next control-plane slice should decide whether they are intentional local-only lanes, repo-backing candidates, or retirement targets.
- Several paused historical shared loops still have no `memory.md`, but that is lower priority than active-lane memory coverage.
