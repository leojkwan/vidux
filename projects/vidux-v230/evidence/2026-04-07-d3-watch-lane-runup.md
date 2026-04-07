# 2026-04-07 — D3 Watch Lane Runup

## Goal
Run the brief planner watch pass again, verify whether the live D3 lane or blocker changed, and checkpoint only the new facts that matter for Task 4.8.

## Sources
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-v230/PLAN.md`] Active lane and blocker state for Task 4.8.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-v230/evidence/2026-04-07-d3-watch-lane-quick-gain.md`] Prior watch checkpoint and runtime baseline.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/`, read 2026-04-07] This machine now has fresh Project 8 and Project 9 evidence beyond the 2026-04-05 baseline.
- [Source: `/Users/leokwan/Desktop/vidux-endurance/evidence/`, read 2026-04-07] Other-machine evidence remains cold; newest file on disk is still `2026-04-05-batch-1-scorecard-and-vnext.md`.
- [Source: `source /Users/leokwan/Development/vidux/scripts/lib/ledger-query.sh && ledger_bimodal_distribution vidux 168 | jq .`, executed 2026-04-07 02:44:21Z] Fresh runtime distribution.
- [Source: `bash /Users/leokwan/Development/vidux/scripts/vidux-doctor.sh --json --repo /Users/leokwan/Development/vidux --automations-dir /Users/leokwan/.codex/automations`, executed 2026-04-07 02:44:21Z] Fresh watch harness scope audit.
- [Source: `/Users/leokwan/.codex/automations/vidux-v230-planner/automation.toml`, read 2026-04-07] Live planner harness still declares watch mode and the under-2-minute boundary.

## Findings

### 1. Task 4.8 is still the active lane
`PLAN.md` still points at the D3 re-measurement lane. No replacement slice surfaced, so the authority store does not need a lane swap.

### 2. Prompt scope is still clean
The live planner harness still carries the watch contract, and the fresh doctor run again excludes both `vidux-v230-planner` and `vidux-endurance` from the `watch_harness_scope` warning list. The remaining warnings are unrelated automation debt.

### 3. Runtime shape improved again, but it is still not enough
Fresh 168-hour ledger read:

- `vidux-v230-planner`: `11 total`, `4 quick`, `7 mid`, `0 normal`, `0 deep`
- `vidux-endurance`: `14 total`, `3 quick`, `8 mid`, `3 normal`, `0 deep`
- repo total: `26 total`, `7 quick`, `16 mid`, `3 normal`, `0 deep`, `bimodal_score=26`

Relative to the prior quick-gain checkpoint:

- planner improved from `3 quick / 10 total` to `4 quick / 11 total`
- endurance improved from `2 quick / 13 total` to `3 quick / 14 total`
- repo quick count improved from `5` to `7`
- repo mid count stayed flat at `16`
- `bimodal_score` improved from `20` to `26`

That is real D3 movement in the right direction. It is still not enough to graduate because the distribution remains mid-heavy and there are still zero deep runs.

### 4. Two-machine confirmation is still absent
The other-machine endurance folder still has no post-2026-04-05 artifacts. That means the measured gain is still single-machine only and cannot yet replace the original two-machine baseline.

## Baseline Delta

### Improved versus 2026-04-05 baseline
- This machine continues to hold materially stronger D5, D6, D8, and D9 evidence than the 2026-04-05 scorecards.
- The live Vidux watch harnesses remain mechanically clean after the rewrite.
- D3 runtime moved measurably since the earlier post-rewrite checkpoints: more quick runs, no additional mid runs, and a higher `bimodal_score`.

### Still waiting on more runs
- D3 is still dominated by mid-zone executions rather than a clear quick/deep split.
- The second machine remains cold, so the two-machine convergence story for D3 is unchanged.

## Verdict
Keep Task 4.8 as the active lane and keep the store hot.

The next deliberate move is still `next_action=burst`, but the burst should stay narrow: rerun the D3 ledger comparison only after more rewritten watch cycles accumulate or after the second machine produces new endurance evidence.
