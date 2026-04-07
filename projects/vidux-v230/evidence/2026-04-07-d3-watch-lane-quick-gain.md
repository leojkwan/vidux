# 2026-04-07 — D3 Watch Lane Quick Gain

## Goal
Run the brief planner watch pass again, verify whether the live D3 lane changed after two more scheduled cycles, and record only the delta that matters for Task 4.8.

## Sources
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-v230/PLAN.md`] Active lane and blocker state for Task 4.8.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-v230/evidence/2026-04-07-d3-watch-lane-recheck.md`] Prior watch checkpoint and runtime baseline.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project8-scorecard.md`] Strong D6 proof and D9 regression context on this machine.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project9-scorecard.md`] Strong D5/D8/D9 recovery context on this machine.
- [Source: `/Users/leokwan/Desktop/vidux-endurance/evidence/`, read 2026-04-07] Other-machine evidence remains cold; newest file on disk is still the 2026-04-05 batch scorecard.
- [Source: `source /Users/leokwan/Development/vidux/scripts/lib/ledger-query.sh && ledger_bimodal_distribution vidux 168 | jq .`, executed 2026-04-07 02:24:22Z] Fresh runtime distribution.
- [Source: `bash /Users/leokwan/Development/vidux/scripts/vidux-doctor.sh --json --repo /Users/leokwan/Development/vidux --automations-dir /Users/leokwan/.codex/automations`, executed 2026-04-07 02:24:22Z] Fresh watch harness scope audit.
- [Source: `/Users/leokwan/.codex/automations/vidux-v230-planner/automation.toml`, read 2026-04-07] Live planner harness still declares watch mode and the under-2-minute boundary.

## Findings

### 1. Task 4.8 is still the active lane
`PLAN.md` still points at the D3 re-measurement lane and no replacement slice surfaced. The blocker is narrower than before: runtime shape is improving, but the evidence bar is still not met.

### 2. Prompt scope stays clean
The live planner harness still carries the watch contract, and the fresh doctor run again excludes both `vidux-v230-planner` and `vidux-endurance` from the `watch_harness_scope` warning list. Remaining doctor warnings are unrelated repo debt.

### 3. Runtime shape improved again, but it is still not enough
Fresh 168-hour ledger read:

- `vidux-v230-planner`: `10 total`, `3 quick`, `7 mid`, `0 normal`, `0 deep`
- `vidux-endurance`: `13 total`, `2 quick`, `8 mid`, `3 normal`, `0 deep`
- repo total: `24 total`, `5 quick`, `16 mid`, `3 normal`, `0 deep`, `bimodal_score=20`

Relative to the prior recheck:

- planner improved from `2 quick / 9 total` to `3 quick / 10 total`
- endurance improved from `1 quick / 12 total` to `2 quick / 13 total`
- repo quick count improved from `3` to `5`
- repo mid count stayed flat at `16`
- `bimodal_score` improved from `13` to `20`

That is a real D3 movement in the right direction. It is still not enough to graduate because the distribution remains mid-heavy and there are still zero deep runs.

### 4. Two-machine confirmation is still absent
The other-machine endurance folder still has no post-2026-04-05 artifacts. That means the measured gain is currently single-machine only and cannot yet replace the original two-machine baseline.

## Baseline Delta

### Improved versus 2026-04-05 baseline
- This machine now has materially stronger D5, D6, D8, and D9 scorecards than the 2026-04-05 baseline.
- The live Vidux watch harnesses remain mechanically clean after the rewrite.
- D3 runtime moved measurably since the prior watch checkpoint: more quick runs, no additional mid runs, and a higher `bimodal_score`.

### Still waiting on more runs
- D3 is still dominated by mid-zone executions rather than a clear quick/deep split.
- The second machine remains cold, so the two-machine convergence story for D3 is unchanged.

## Verdict
Keep Task 4.8 as the active lane and keep the store hot.

The next deliberate move is still `next_action=burst`, but the burst should stay narrow: rerun the D3 ledger comparison only after more rewritten watch cycles accumulate or after the second machine produces new endurance evidence.
