# 2026-04-07 Project 8 Scorecard

## Goal
Grade Project 8 (Fake Airport Baggage Exception Desk) on all 9 Vidux doctrines after the machine-auditable process-fix drill, the two-role ownership test, and a fresh Vidux contract-suite rerun.

## Sources
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/PLAN.md`] Project 8 scope, contract checkpoint, and closeout requirements.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project8-lane-contract.md`] The owned write surfaces, required test names, and proof command.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project8-process-audit.md`] Worker B's process-audit note from verified disk evidence.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project8-drill.md`] Coordinator synthesis of the code repair, audit proof, and ownership leak.
- [Source: `python3 -m unittest discover -s /Users/leokwan/Development/vidux/tests -p 'test_*.py' -q`, executed 2026-04-07] Vidux contract suite passed 94/94 tests in 21.799s.

## Findings

### 1. Doctrine 1 -- Plan is the store: pass
The lane contract was written into evidence and checkpointed in `PLAN.md` before any `/tmp` implementation began. The coordinator used the plan plus disk artifacts to control the slice; the stray automation-memory write did not become authoritative state for the lane.

### 2. Doctrine 2 -- Unidirectional flow: pass
Project 8 followed the full loop: gather prior endurance gaps, write the contract, execute one bounded `/tmp` fix plus one bounded audit note, rerun the green gate and audit command, then rerun the repo contract suite and checkpoint the result.

### 3. Doctrine 3 -- 50/30/20 split: pass
This project balanced all three phases better than several prior slices: enough planning to define ownership and machine audit, enough code to prove a real red-to-green fix, and enough last-mile verification to surface the cross-surface leak instead of declaring victory early.

### 4. Doctrine 4 -- Evidence over instinct: pass
The closeout rests on concrete artifacts: red and green test logs, the rerunnable JSON audit proof, the worker audit note, the coordinator drill note, and the fresh 94/94 contract-suite rerun.

### 5. Doctrine 5 -- Design for completion: minimal exercise
Project 8 was not a resume or handoff drill. The plan-backed state discipline still held, but this slice did not materially advance the explicit design-for-death evidence the way Projects 2, 5, and 7 did.

### 6. Doctrine 6 -- Process fixes > code fixes: pass
This is the strongest Doctrine 6 proof in the endurance plan so far. The code fix repaired the fake baggage reconciler, and the durable process rule is now enforced by a rerunnable disk command that checks the required test names and emits a JSON proof artifact before closure.

### 7. Doctrine 7 -- Bug tickets are investigations: minimal exercise
No nested investigation was required. Project 8 intentionally stayed on one bounded defect plus one process-audit rule.

### 8. Doctrine 8 -- Cron prompts are harnesses, not snapshots: minimal exercise
The slice used a lane contract rather than a new evergreen harness. That was appropriate for the goal, but it means Project 8 adds little new evidence on harness purity.

### 9. Doctrine 9 -- Subagent coordinator pattern: fail
Worker A respected the `/tmp` boundary and Worker B produced the expected process-audit note, but Worker B also wrote to `/Users/leokwan/.codex/automations/vidux-endurance/memory.md`, which was explicitly reserved for the coordinator. That means the key acceptance criterion for the drill -- no out-of-scope file writes -- failed on the exact surface Project 8 was meant to harden.

## Summary Table

| Doctrine | Grade | Notes |
|----------|-------|-------|
| D1: Plan is the store | pass | Contract and checkpoints lived in the plan before implementation |
| D2: Unidirectional flow | pass | Contract -> bounded work -> verify -> scorecard |
| D3: 50/30/20 split | pass | Good balance across planning, code, and verification |
| D4: Evidence over instinct | pass | Claims backed by logs, JSON proof, and fresh tests |
| D5: Design for completion | minimal exercise | No deliberate resume or handoff drill |
| D6: Process fixes > code fixes | pass | First rerunnable machine-audit proof of a process fix |
| D7: Bug tickets are investigations | minimal exercise | No investigation tree needed |
| D8: Cron harnesses not snapshots | minimal exercise | No new harness slice here |
| D9: Subagent coordinator | fail | Worker escaped its owned surface and wrote automation memory |

## Verification Notes
- `/tmp` baggage fixture: red proof captured in `red-unittest.log`, green gate rerun passed 2/2 tests.
- Process-fix audit rerun produced `required_tests_present: true` in `/tmp/vidux-endurance-baggage/proof/process_fix_audit.json`.
- Vidux contract suite is fresh to this run and now stands at 94/94 passing in 21.799s.

## Strength Surfaced
- Vidux can now carry a genuine Doctrine 6 process fix that is machine-checkable from disk instead of merely described in an evidence note.

## Friction Surfaced
- Worker ownership is still porous across off-repo surfaces. A narrow repo-local audit is not enough when the subagent can still mutate automation memory or other external state.

## Recommendations
- Use Project 8 as the reference slice for Doctrine 6 machine-audit enforcement.
- Treat Project 8 as a Doctrine 9 regression test that currently fails until ownership checks include off-repo paths like automation memory.
- Seed the next endurance project on the remaining light and failing control-plane risks: explicit resume evidence (D5), harness purity (D8), and ownership checks that span repo plus Codex home surfaces.
