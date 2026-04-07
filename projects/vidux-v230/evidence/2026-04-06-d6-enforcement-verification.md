# 2026-04-06 — D6 Enforcement Verification

## Goal
Close the remaining Doctrine 6 gap from the two-machine endurance baseline and Project 6 by making process-fix claims machine-checkable at checkpoint time instead of documentary prose.

## Sources
- [Source: other-machine batch scorecard, 2026-04-05] `/Users/leokwan/Desktop/vidux-endurance/evidence/2026-04-05-batch-1-scorecard-and-vnext.md`
- [Source: this-machine baseline scorecard, 2026-04-05] `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-05-final-endurance-scorecard.md`
- [Source: D6 enforcement design, 2026-04-05] `/Users/leokwan/Development/vidux/projects/vidux-v230/evidence/2026-04-05-d6-enforcement-design.md`
- [Source: Project 6 scorecard, 2026-04-07] `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project6-scorecard.md`
- [Source: `scripts/vidux-checkpoint.sh`, read 2026-04-06] Current checkpoint stages only `PLAN.md`, so staged-only artifact scans would miss typical code/test fixes.
- [Source: fresh contract run, 2026-04-06] `python3 -m unittest discover -s /Users/leokwan/Development/vidux/tests -p 'test_*.py' -q`
- [Source: fresh `/tmp` D6 replay drill, 2026-04-06] temp repo under `/tmp/vidux-d6-main-qB9qJr`

## Findings

### 1. The April 5 D6 design was directionally right but operationally incomplete
The hybrid design in the original D6 spec still holds: Vidux needs both a declared process-fix type and an artifact check. The operational gap was the data source. `vidux-checkpoint.sh` only stages `PLAN.md`, so a cached-only scan would falsely warn even when the lane added a real regression test or script.

### 2. The enforceable D6 surface is now additive and backward-compatible
Implemented in this run:

- `vidux-loop.sh` now exposes `process_fix_declared` for the current task
- `vidux-checkpoint.sh` now scans repo working-tree deltas plus untracked files for matching process-fix artifacts
- tagged fix tasks now emit a warning when no matching artifact exists
- untagged fix tasks now emit an advisory instead of silently closing

Legacy plans remain valid because `[ProcessFix: ...]` is optional and the checkpoint behavior is warn-only.

### 3. Fresh verification proved the exact gap closed
Contract suite:

- result: `92/92` pass
- baseline delta: `89/89 -> 92/92`

New coverage added:

- watch mode surfaces `process_fix_declared`
- checkpoint warns when `[ProcessFix: test]` closes without a matching test artifact
- checkpoint accepts an untracked regression test as a valid process-fix artifact

Fresh `/tmp` proof:

1. Documentary close attempt
   - task: `Task 1: Fix replay bug [ProcessFix: test] [Evidence: fixture]`
   - repo changes: `PLAN.md`, `src.py`
   - result: checkpoint completed but emitted `PROCESS-FIX WARNING`
2. Artifact-backed close attempt
   - same task, but with `tests/test_replay_regression.py`
   - result: checkpoint completed with no process-fix warning

## Before / After

### Before
- D6 process-fix claims were visible only in prose or manual scorecards
- Project 6 could state "replay tests are required" but Vidux could not check that claim at closure
- checkpoint had no machine signal for documentary closes

### After
- the current task can declare its process-fix type in watch-mode JSON
- checkpoint now evaluates whether the repo actually contains a matching process-fix artifact
- documentary bugfix closes now fail loud on stderr without breaking backward compatibility

## Baseline Delta
- Doctrine 6 is measurably stronger than the 2026-04-05 baseline because the system now distinguishes documentary closes from artifact-backed closes.
- The measurable deltas from this run are:
  - contract coverage: `89 -> 92`
  - one new watch-mode field: `process_fix_declared`
  - one new checkpoint enforcement path: warn on missing process-fix artifact
  - one fresh `/tmp` before/after drill proving the warning disappears once the regression artifact exists

## Verdict
This run upgrades D6 from "credible but documentary" to "machine-checked at checkpoint" for the common local case. The next deliberate move remains Task 4.2: gather enough new automation cycles to measure whether the D3 runtime-distribution fix changed live behavior beyond the 2026-04-07 ledger baseline.
