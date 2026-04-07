# 2026-04-07 — D3 Ledger Integrity And Recheck

## Goal
Re-run Task 4.2 honestly after the watch/burst contract landed: verify whether enough fresh automation cycles accumulated to judge D3, and fix the measurement surface first if the ledger query was still contaminated.

## Sources
- [Source: watch/burst contract verification, 2026-04-07] `/Users/leokwan/Development/vidux/projects/vidux-v230/evidence/2026-04-07-watch-burst-contract-verification.md`
- [Source: this-computer endurance scorecard, 2026-04-05] `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-05-final-endurance-scorecard.md`
- [Source: other-computer batch scorecard, 2026-04-05] `/Users/leokwan/Desktop/vidux-endurance/evidence/2026-04-05-batch-1-scorecard-and-vnext.md`
- [Source: live ledger, queried 2026-04-07] `~/.agent-ledger/activity.jsonl`
- [Source: `scripts/lib/ledger-query.sh`, read 2026-04-07] repo-wide bimodal classifier
- [Source: contract suite, 2026-04-07] `python3 -m unittest tests/test_vidux_contracts.py`

## Findings

### 1. The old D3 runtime query was polluted by Codex live snapshots
The pre-fix `ledger_bimodal_distribution` grouped repo rows by `automation_id // agent_id` and measured durations from consecutive events. On a Codex-driven automation this is wrong in two ways:

- raw `codex/...` rows without `automation_id` were treated as their own automations
- repeated `live` snapshots inside one real run were treated as multiple separate runs

Fresh minimal repro:

- one real `vidux-v230-planner` run (`live -> stop`, 1 minute)
- one raw `codex/noise` pair (`live -> stop`, 4 minutes)

Before the fix, that fixture produced `total_runs=2`, `mid=1`, `bimodal_score=50` even though only one real automation run existed.

### 2. The fix is to classify automation runs, not event gaps
The query now:

- ignores rows that lack `automation_id`
- groups by `automation_id`
- recovers one run per `agent_id` stream inside that automation
- uses `vidux_loop_start/end` when available
- otherwise falls back to `first_ts -> last_ts` inside that run
- drops zero-duration singleton groups instead of counting them as fake automations

This keeps the measurement aligned with actual automation invocations.

### 3. Fresh post-fix D3 measurement says the runtime shape is still bad
Live 168-hour recheck after the query fix:

- repo totals: `14 runs`, `2 quick`, `0 deep`, `11 mid`, `1 normal`, `bimodal_score=14`
- `vidux-v230-planner`: `6 runs`, `1 quick`, `5 mid`, `0 normal`, `0 deep`
- `vidux-endurance`: `7 runs`, `1 quick`, `5 mid`, `1 normal`, `0 deep`

So D3 does **not** graduate. The old apparent shape (`vidux-v230-planner` mid `0 / 19`) was a measurement artifact, not evidence of healthy runtime bimodality.

## Fresh Verification

### New contract tests
- Added `test_ledger_bimodal_distribution_ignores_non_automation_noise`
- Added `test_ledger_bimodal_distribution_collapses_live_snapshots_into_one_run`
- Result: both new tests pass

### Full contract suite
- `python3 -m unittest tests/test_vidux_contracts.py`
- Result: **94/94 pass**
- Delta vs 2026-04-07 watch/burst run: **89/89 -> 94/94**

### Live ledger recheck
- `source scripts/lib/ledger-query.sh && ledger_bimodal_distribution vidux 168 | jq .`
- Result: honest automation-only distribution above, with `vidux-v230-planner` now clearly mid-heavy

## Baseline Delta

### What improved measurably
- The D3 runtime measurement is now machine-safe against raw Codex noise and repeated `live` snapshots.
- Contract coverage increased from `89` to `94`.

### What did not improve
- D3 runtime shape itself.
- Fresh honest read is worse than the apparent 2026-04-07 baseline because the old baseline was contaminated.

## Verdict
Task 4.2 is now answerable: enough fresh cycles exist, and the honest answer is **no, D3 still needs scheduler or harness changes**.

The next deliberate lane is not more measurement. It is to redesign the planner/endurance automation shape so runs either stay under 2 minutes or push into true deep work instead of lingering in the 3-8 minute dead zone.
