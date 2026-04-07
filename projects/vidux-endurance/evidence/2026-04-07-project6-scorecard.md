# 2026-04-07 Project 6 Scorecard

## Goal
Grade Project 6 (Fake Library Circulation Exception Desk) on all 9 Vidux doctrines after the nested investigation, bounded `/tmp` replay drill, D3 audit, and fresh contract-suite rerun.

## Sources
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/PLAN.md`] Project 6 scope, Surprises, and completion checkpoint.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/investigations/circulation-exception-session-projection.md`] The nested investigation, shared root cause, fix spec, regression tests, and checked gate.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project6-circulation-fixture.md`] `/tmp` reproduction, red-to-green verification, and explicit process fix.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project6-d3-boundary-audit.md`] Scope-control audit for Doctrine 3.
- [Source: `python3 -m unittest discover -s /Users/leokwan/Development/vidux/tests -p 'test_*.py' -q`, executed 2026-04-07] Vidux contract suite passed 89/89 tests in 14.160s.

## Findings

### 1. Doctrine 1 -- Plan is the store: pass
Project 6 started from the endurance plan, wrote the investigation before any `/tmp` code, and closed through evidence plus a scorecard. No state lived only in chat memory.

### 2. Doctrine 2 -- Unidirectional flow: pass
The cycle was clean: gather the doctrine requirements, write the investigation, execute the bounded replay fix in `/tmp`, verify the fixture gate, audit the boundary, rerun contracts, and checkpoint the result back into `PLAN.md`.

### 3. Doctrine 3 -- 50/30/20 split: pass
This was the best-balanced fake project in the endurance set so far. Planning and investigation still dominated, but the lane included real code, a real failing test run, a real fix, and explicit last-mile verification without drifting into backlog theater.

### 4. Doctrine 4 -- Evidence over instinct: pass
Every closeout claim is anchored to the investigation, the `/tmp` fixture, the D3 audit, or the fresh contract rerun. The score is based on artifacts, not confidence.

### 5. Doctrine 5 -- Design for completion: minimal exercise
Project 6 remained resumable because the investigation and parent plan stayed current, but it did not run an explicit death-drill or worktree-handoff exercise the way Projects 2 and 5 did.

### 6. Doctrine 6 -- Process fixes > code fixes: pass
The code fix repaired the fake projector, but the durable output is the replay-oriented process rule: future circulation drills must prove duplicate-delivery and out-of-order handling before they close. That process fix is what makes the next run smarter.

### 7. Doctrine 7 -- Bug tickets are investigations: pass
Project 6 is a strong Doctrine 7 proof. Three linked circulation tickets were bundled into one investigation, one shared root cause, one fix spec, and one regression pack rather than being treated as three isolated tasks.

### 8. Doctrine 8 -- Cron prompts are harnesses, not snapshots: minimal exercise
This project did not write or audit a new harness. It inherited the endurance harness and stayed inside it, but D8 was not the primary doctrine under test here.

### 9. Doctrine 9 -- Subagent coordinator pattern: minimal exercise
Project 6 stayed intentionally single-threaded. That helped D3, but it means the slice added little new evidence about coordinator thinness or worker ownership.

## Summary Table

| Doctrine | Grade | Notes |
|----------|-------|-------|
| D1: Plan is the store | pass | Investigation and closeout both anchored to the authority plan |
| D2: Unidirectional flow | pass | Investigation -> `/tmp` fix -> verification -> checkpoint stayed intact |
| D3: 50/30/20 split | pass | Best balance so far between planning, code, and last mile |
| D4: Evidence over instinct | pass | Every claim backed by disk artifacts and fresh tests |
| D5: Design for completion | minimal exercise | Resumable, but no explicit death drill this cycle |
| D6: Process fixes > code fixes | pass | Replay-test rule is now part of the lane contract |
| D7: Bug tickets are investigations | pass | Three tickets resolved through one nested investigation |
| D8: Cron harnesses not snapshots | minimal exercise | No new harness authored in this project |
| D9: Subagent coordinator | minimal exercise | No new fan-out evidence in this project |

## Verification Notes
- `/tmp` fixture gate moved from 3 failing tests to 3 passing tests on the same regression pack.
- Vidux contract suite is fresh to this run and now stands at 89/89 passing in 14.160s.

## Strength Surfaced
- A single investigation-backed replay fix handled three linked circulation failures without letting the lane sprawl beyond one shared surface.

## Friction Surfaced
- The Project 6 process fix is explicit and credible, but its enforcement is still documentary. Vidux does not yet have a machine-level check that a lane actually added the required replay cases before closure.

## Recommendations
- Treat Project 6 as the current reference slice for D3 + D6 + D7 working together in one bounded fake project.
- Seed the next endurance lane around the still-light control-plane doctrines: D5, D8, and D9.
