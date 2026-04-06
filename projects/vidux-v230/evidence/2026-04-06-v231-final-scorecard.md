# 2026-04-06 v2.3.1 Final Scorecard

## Goal
Measure whether Vidux v2.3.1 is meaningfully better than the 2026-04-05 v2.2.0 endurance baseline using fresh verification, not cached grades.

## Baseline
- 2026-04-05 local scorecard: 8/9 doctrines pass, D3 remains friction.
- 2026-04-05 other-machine scorecard: D1-D4 stable, D6 weakest, control-plane hygiene still soft.

## Fresh Verification Set
- Contract suite: **84/84 pass**
- Fresh `/tmp` Phase 3 bundle: **8/8 pass**
- Fresh extra contradiction + mixed-format bundle: **8/8 pass**
- Live plans exercised today:
  - `projects/vidux-v230/PLAN.md`
  - `projects/resplit-android/PLAN.md`
  - `projects/context-ops/PLAN.md`
- Historical plan check:
  - `projects/perf-investigation/PLAN.md` no longer exists; loop returns `create_plan`

## Before / After Doctrine Read

| Doctrine | 2026-04-05 baseline | 2026-04-06 refresh |
|----------|----------------------|--------------------|
| D1: Plan is the store | PASS | PASS |
| D2: Unidirectional flow | PASS | PASS |
| D3: 50/30/20 split | FRICTION | FRICTION |
| D4: Evidence over instinct | PASS | PASS |
| D5: Design for death | PASS with control-plane fragility | PASS, stronger — temp-repo doctor path now tested |
| D6: Process fixes > code fixes | PASS but weak on other machine | PASS, stronger — new bug became code fix + contract + evidence |
| D7: Bug tickets are investigations | PASS | PASS |
| D8: Cron harnesses not snapshots | PASS | PASS |
| D9: Subagent coordinator / multi-lane orchestration | PASS | PASS |

## Measurable Delta

1. Contract coverage improved from **63 tests** to **84 tests** with zero warnings.
2. A new control-plane bug (`vidux-doctor.sh --repo` scanning the wrong `projects/`) was found and fixed today.
3. That bug is now mechanically enforced by contract test instead of relying on human memory.
4. Live-plan execution remains healthy on three current plans, and `resplit-android` now correctly stops at a task-linked question rather than over-claiming readiness.
5. The only doctrine still showing friction is D3, which remains a test-shape problem rather than a new regression.

## Verdict

**v2.3.1 is measurably better than the 2026-04-05 baseline.**

The improvement is not just "more green":

- stronger contract suite
- new `/tmp` pressure verification
- a newly discovered control-plane hole fixed and locked down
- fresher live-plan evidence from current repo state

Remaining gap: D3 still needs a real multi-day project lane to judge the planning/code balance honestly.
