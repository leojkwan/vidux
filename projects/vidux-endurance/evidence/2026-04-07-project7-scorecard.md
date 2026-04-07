# 2026-04-07 Project 7 Scorecard

## Goal
Grade Project 7 (Fake Municipal Permit Intake Board) on all 9 Vidux doctrines after the harness/ownership contract, forced-resume coordinator drill, and fresh contract-suite rerun.

## Sources
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/PLAN.md`] Project 7 scope, checkpoint history, and the explicit Task 7.1-7.3 requirements.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project7-harness-ownership.md`] The evergreen harness and explicit ownership contract.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project7-forced-resume-drill.md`] Recovery proof, ownership audit, and duplicate-worktree verification.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project7-slice-intake-completeness.md`] Worker A's bounded permit-intake slice.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project7-slice-routing-status.md`] Worker B's bounded routing/status slice.
- [Source: `python3 -m unittest discover -s /Users/leokwan/Development/vidux/tests -p 'test_*.py' -q`, executed 2026-04-07] Vidux contract suite passed 92/92 tests in 15.003s.

## Findings

### 1. Doctrine 1 -- Plan is the store: pass
Task 7.2 was checkpointed in `PLAN.md` before recovery, the worker-file paths lived in the task line, and the coordinator reread the plan before fan-in. No critical Project 7 state depended on chat memory.

### 2. Doctrine 2 -- Unidirectional flow: pass
The lane stayed clean: gather doctrine requirements, write the harness/ownership plan artifact, checkpoint the fan-out, recover from disk, fan in the worker slices, rerun contracts, then checkpoint the scorecard.

### 3. Doctrine 3 -- 50/30/20 split: minimal exercise
Project 7 was intentionally a control-plane drill with no `/tmp` implementation step. That makes it useful for D5/D8/D9, but it does not seriously stress the planning/code/last-mile balance the way Project 6 did.

### 4. Doctrine 4 -- Evidence over instinct: pass
The closeout claims are grounded in disk artifacts: the harness note, the two worker evidence files, the forced-resume synthesis, the worktree inventory, the write audit, the unchanged memory timestamp, and the fresh contract rerun.

### 5. Doctrine 5 -- Design for completion: pass
This is the strongest D5 result in the endurance set so far. The coordinator survived a deliberate mid-fan-out checkpoint, reread the plan from disk, rediscovered the owned evidence paths, and resumed without opening a duplicate worktree.

### 6. Doctrine 6 -- Process fixes > code fixes: minimal exercise
Project 7 was not a code/process-fix lane. It improved coordinator process discipline, but it did not run the full "immediate code fix plus durable process fix" pattern.

### 7. Doctrine 7 -- Bug tickets are investigations: minimal exercise
No nested bug investigation was required here. The project stayed on harness and coordinator control-plane behavior rather than on a multi-ticket root-cause surface.

### 8. Doctrine 8 -- Cron prompts are harnesses, not snapshots: pass
The Project 7 prompt stayed evergreen: it includes only mission, authority, role boundary, design DNA, guardrails, and skills. The worker-file ownership details remained outside the harness in a separate evidence note, which is the right split.

### 9. Doctrine 9 -- Subagent coordinator pattern: pass with friction
This was a clear improvement over Project 5. The coordinator stayed thin, each worker returned one bounded evidence file, and no ownership leak occurred. The remaining friction is that enforcement is still post-hoc; Vidux does not yet mechanically prevent a worker from writing outside its contract.

## Summary Table

| Doctrine | Grade | Notes |
|----------|-------|-------|
| D1: Plan is the store | pass | Recovery paths lived in the plan, not in chat memory |
| D2: Unidirectional flow | pass | Harness -> checkpoint -> recover -> synthesize -> verify -> scorecard |
| D3: 50/30/20 split | minimal exercise | Control-plane drill, not a code-heavy lane |
| D4: Evidence over instinct | pass | Claims backed by files, worktree inventory, and fresh tests |
| D5: Design for completion | pass | Disk-only resume succeeded without duplicate worktree creation |
| D6: Process fixes > code fixes | minimal exercise | No immediate code/process pair in this project |
| D7: Bug tickets are investigations | minimal exercise | No nested investigation surface here |
| D8: Cron harnesses not snapshots | pass | Harness stayed stateless; ownership details lived outside the prompt |
| D9: Subagent coordinator | pass with friction | Clean ownership result, but still enforced by audit rather than tooling |

## Verification Notes
- The two worker files were present at the recorded paths during the recovery hop.
- The automation memory file remained at its prior timestamp during fan-out, so the Project 5 ownership leak did not recur.
- Vidux contract suite is fresh to this run and now stands at 92/92 passing in 15.003s.

## Strength Surfaced
- A single checkpoint line plus an explicit ownership table was enough for a disk-only resume to recover a live fan-out cleanly and avoid both duplicate worktrees and out-of-scope worker writes.

## Friction Surfaced
- The successful result still depends on the coordinator auditing touched files after the run. Vidux does not yet mechanically sandbox or verify worker write scopes during execution.

## Recommendations
- Use Project 7 as the reference slice for D5 + D8 + D9 working together in one clean control-plane drill.
- Seed the next endurance project around the remaining soft spots: machine-verifiable process-fix enforcement and machine-verifiable ownership auditing.
