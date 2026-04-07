# 2026-04-07 Loop Health Review

## Scope
- Deep loop review requested after the orchestrator cadence fix, with explicit focus on overall fleet health, Resplit web duplication, and whether live automation state still matched repo truth.

## Evidence
- Repo-backed TOMLs under `/Users/leokwan/Development/ai/automations`: `26`.
- Live SQLite rows in `~/.codex/sqlite/codex-dev.db` table `automations`: `34`.
- Live active rows: `20`.
- DB-only active rows: `8`.
  - `strongyes-backend`
  - `strongyes-content-scraper`
  - `strongyes-email`
  - `strongyes-problem-builder`
  - `strongyes-product`
  - `strongyes-ux`
  - `vidux-meta`
  - `vidux-test-grader`
- Live active repo-backed rows are still dispatching with recent `last_run_at` and `next_run_at` values. The DB-only active cluster still shows null runtime timestamps, so those rows remain active in name but not healthy in practice.
- `resplit-web` is the only live active Resplit web shipper and is still running from `/Users/leokwan/Development/resplit-ios`.
- `resplit-nurse` and `resplit-vidux` are paused, but both prompts still mentioned the web app shell and marketing site as regular recurring ownership surfaces instead of parity-only inspection or handoff.
- Before this repair, repo-backed TOMLs had already been normalized to `reasoning_effort = "high"`, but the live scheduler still carried `7` active DB-only rows at `xhigh`.
- The canonical `/Users/leokwan/Development/ai` checkout remains dirty and `behind 1` relative to `origin/main`, so direct repo cleanup or a clean pull/push window is still blocked.

## Decision
- Treat this cycle as a loop-health normalization pass instead of a DB-only retirement pass.
- Normalize all live rows to `reasoning_effort = "high"` for a clear fleet baseline.
- Tighten Resplit ownership so pure web and marketing shipping belongs only to `resplit-web`; keep `resplit-nurse` and `resplit-vidux` on parity, radar, and handoff duties there.

## Remaining Exposure
- The `8` DB-only active rows are still outside repo truth and still not dispatching.
- Dirty canonical repo state still blocks a clean pull/rebase/commit sync on `/Users/leokwan/Development/ai`.
