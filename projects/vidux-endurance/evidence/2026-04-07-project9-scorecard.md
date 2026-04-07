# 2026-04-07 Project 9 Scorecard

## Goal
Grade Project 9 (Fake Insurance Claims Catastrophe Desk) on all 9 Vidux doctrines after the external-surface harness contract, forced-resume coordinator drill, and fresh Vidux contract-suite rerun.

## Sources
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/PLAN.md`] Project 9 scope, checkpoint history, and closeout requirements.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project9-harness-ownership.md`] The evergreen harness, canonical off-repo path resolution, and ownership contract.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project9-forced-resume-drill.md`] Recovery proof, repo-plus-off-repo machine audit, and duplicate-worktree verification.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project9-slice-fnol-severity.md`] Worker A's bounded catastrophe-intake slice.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project9-slice-adjuster-status.md`] Worker B's bounded adjuster/status slice.
- [Source: `python3 -m unittest discover -s /Users/leokwan/Development/vidux/tests -p 'test_*.py' -q`, executed 2026-04-07] Vidux contract suite passed 96/96 tests in 27.848s.

## Findings

### 1. Doctrine 1 -- Plan is the store: pass
Project 9 only closed after the coordinator checkpointed the harness contract, the active worktree, and the worker-file paths into `PLAN.md`. The recovery hop then reread the plan to find the worker outputs, so no authoritative state lived in chat memory.

### 2. Doctrine 2 -- Unidirectional flow: pass
The lane stayed clean: gather the Project 8 failure, write the contract, checkpoint Task 9.2, fan out two owned slices, rerun the recovery and write-scope audit from disk, rerun the contract suite, then checkpoint the scorecard.

### 3. Doctrine 3 -- 50/30/20 split: minimal exercise
Project 9 was a control-plane drill rather than a code-heavy slice. It materially advanced completion and ownership evidence, but it did not seriously stress the planning/code/last-mile balance the way Projects 6 or 8 did.

### 4. Doctrine 4 -- Evidence over instinct: pass
The closeout is grounded in machine outputs and files: realpath resolution, the baseline write-scope audit, the unchanged automation-memory timestamp, unchanged worktree inventory, the two worker notes, and the fresh 96/96 contract rerun.

### 5. Doctrine 5 -- Design for completion: pass
This is now the strongest explicit off-repo D5 result in the endurance set. The coordinator survived a deliberate mid-fan-out checkpoint, resumed from `PLAN.md`, found both worker files from disk, and confirmed no duplicate worktree was created while doing it.

### 6. Doctrine 6 -- Process fixes > code fixes: minimal exercise
Project 9 improved control-plane process enforcement, but it did not pair a code fix with a durable process fix the way Projects 6 and 8 did.

### 7. Doctrine 7 -- Bug tickets are investigations: minimal exercise
No nested bug investigation was required. The project stayed on harness purity and external-path ownership rather than on a shared root-cause bug surface.

### 8. Doctrine 8 -- Cron prompts are harnesses, not snapshots: pass
The Project 9 prompt stayed evergreen. It names mission, authority, role boundary, design DNA, guardrails, and skills only; the resolved off-repo ownership details live in the separate evidence contract, not in the harness itself.

### 9. Doctrine 9 -- Subagent coordinator pattern: pass with friction
This is the cleanest ownership result so far because the coordinator audited both repo-local writes and the canonical automation-memory path in one window. The remaining friction is that the check still runs after the workers finish; Vidux detects bad writes here but does not yet prevent them live.

## Summary Table

| Doctrine | Grade | Notes |
|----------|-------|-------|
| D1: Plan is the store | pass | Recovery paths and worker-file targets lived in `PLAN.md` |
| D2: Unidirectional flow | pass | Contract -> checkpoint -> fan-out -> recover -> verify -> scorecard |
| D3: 50/30/20 split | minimal exercise | Control-plane drill, not a code-heavy lane |
| D4: Evidence over instinct | pass | Claims backed by path-resolution, audits, and fresh tests |
| D5: Design for completion | pass | Disk-only resume succeeded with no duplicate worktree |
| D6: Process fixes > code fixes | minimal exercise | No immediate code/process-fix pair in this project |
| D7: Bug tickets are investigations | minimal exercise | No investigation tree needed |
| D8: Cron harnesses not snapshots | pass | Harness stayed stateless; ownership detail stayed outside the prompt |
| D9: Subagent coordinator | pass with friction | Repo + off-repo audit passed, but enforcement is still post-hoc |

## Verification Notes
- Repo files touched after the fan-out baseline: exactly the two owned worker evidence files.
- Canonical automation memory at `/Users/leokwan/Development/ai/automations/vidux-endurance/memory.md` did not change during the worker drill.
- Worktree inventory before and after the drill matched exactly.
- Vidux contract suite is fresh to this run and now stands at 96/96 passing in 27.848s.

## Strength Surfaced
- Vidux can now run a clean coordinator drill where the machine audit spans both repo-local ownership and the real off-repo automation-memory surface that caused the prior regression.

## Friction Surfaced
- The control plane still relies on post-run detection. Project 9 proves broader ownership auditing, not true write-set sandboxing.

## Recommendations
- Use Project 9 as the new reference slice for D5 + D8 + D9 when off-repo surfaces are part of the contract.
- Keep realpath normalization mandatory whenever a worker contract mentions symbolic paths like `$CODEX_HOME`.
- Seed the next endurance project on the least-refreshed doctrine risks: D3 balance plus D7 investigation depth under a coordinator fan-out.
