# 2026-04-06 Project 5 Scorecard

## Goal
Grade Project 5 (Fake Community Event Ops Console) on all 9 Vidux doctrines after the harness review, explicit worktree handoff drill, bounded subagent fan-out, and fresh contract verification.

## Sources
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/PLAN.md`] Project 5 tasks, Surprises, Decision Log, and Cycle 10-12 Progress checkpoints.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-06-project5-harness-handoff.md`] Evergreen harness validation and explicit worktree protocol checklist.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-06-project5-worktree-handoff-drill.md`] Two-hop handoff proof plus the manual-resume friction surfaced by the drill.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-06-project5-slice-checkin.md`] Bounded research slice for check-in, late arrivals, and capacity overflow.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-06-project5-slice-incident.md`] Bounded research slice for incident response, volunteer reassignment, and public-status coordination.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-06-project5-subagent-synthesis.md`] Serial fan-in verdict on overlap, token savings, coordinator thinness, and worker ownership leakage.
- [Source: `python3 -m unittest discover -s /Users/leokwan/Development/vidux/tests -p 'test_*.py' -q`, executed 2026-04-06] Vidux contract suite passed 84/84 tests in 18.896s.

## Findings

### 1. Doctrine 1 -- Plan is the store: pass
Project 5 lived entirely in the endurance authority store. The active-worktree registration, mid-drill checkpoint, handoff proof, fan-out checkpoint, and final grading all flowed through `PLAN.md` plus dated evidence files rather than chat memory or a side tracker.

### 2. Doctrine 2 -- Unidirectional flow: pass
The project followed gather -> checkpoint -> resume -> synthesize -> verify -> scorecard cleanly. The most important proof is that the handoff drill and the subagent drill both wrote evidence before the final grade and contract rerun.

### 3. Doctrine 3 -- 50/30/20 split: friction
Project 5 was intentionally doctrine-heavy and code-light. The slice stayed honest, but it still spent most of its time on harness, handoff, and research mechanics rather than a balanced plan/code/last-mile cycle. This remains the doctrine most resistant to the endurance format.

### 4. Doctrine 4 -- Evidence over instinct: pass
Every claim in the closeout is anchored to the authority plan, the handoff note, the handoff drill, the two subagent outputs, the synthesis note, or the fresh contract run. The scorecard is built from disk artifacts, not inferred confidence.

### 5. Doctrine 5 -- Design for completion: pass
The two-hop worktree drill succeeded because the path, status, and next-hop instruction were all recorded in files. The second hop resumed from the plan, not from memory, and the store cleaned itself up at the boundary with `- none active` plus a `[WORKTREE]` log line.

### 6. Doctrine 6 -- Process fixes > code fixes: pass
Project 5 found two real process fixes that matter more than fake-product polish: surface active-worktree metadata in machine-readable tooling, and tighten worker write ownership so subagents cannot silently leak into memory. These are exactly the kinds of durable improvements endurance work is supposed to find.

### 7. Doctrine 7 -- Bug tickets are investigations: minimal exercise
Project 5 did not center on a multi-ticket bug surface or a nested investigation file. It surfaced control-plane failures, but it was not primarily an investigation-pattern project.

### 8. Doctrine 8 -- Cron prompts are harnesses, not snapshots: pass
Task 5.1 produced and reviewed a harness that stayed evergreen: mission, authority path, role boundary, design DNA, guardrails, and optional skills only. No task numbers, progress summaries, branch names, or transient blocker state leaked into the harness.

### 9. Doctrine 9 -- Subagent coordinator pattern: friction
The fan-out was materially useful and the coordinator stayed thin, but one worker wrote outside its assigned file and touched automation memory. That turns Project 5 into a good-but-not-clean Doctrine 9 proof: the pattern works, yet write isolation is still enforced by policy instead of tooling.

## Summary Table

| Doctrine | Grade | Notes |
|----------|-------|-------|
| D1: Plan is the store | pass | Entire lane resolved through PLAN.md + dated evidence |
| D2: Unidirectional flow | pass | Handoff drill, fan-out, contracts, and scorecard all chained cleanly |
| D3: 50/30/20 split | friction | Doctrine-heavy endurance slice stayed planning-centric |
| D4: Evidence over instinct | pass | All claims anchored to plan, evidence notes, and fresh contracts |
| D5: Design for death | pass | Two-hop resume worked from recorded file state |
| D6: Process fixes > code fixes | pass | Surfaced tooling/process upgrades worth more than fake polish |
| D7: Bug tickets are investigations | minimal exercise | No nested bug investigation anchored this project |
| D8: Cron harnesses not snapshots | pass | Harness stayed evergreen and state-free |
| D9: Subagent coordinator | friction | Fan-out worked, but worker ownership leaked into memory |

## Verification Notes
- Contract suite rerun is fresh to this closeout: 84/84 passing in 18.896s.
- The worktree handoff proof is also fresh to this run and was captured directly in the endurance store, not reconstructed from prior memory.

## Strength Surfaced
- Vidux can now prove both evergreen-harness discipline and file-backed worktree handoff in the same fake project, which is stronger D5/D8 coverage than any earlier lane produced.

## Friction Surfaced
- `vidux-loop.sh` still does not expose active-worktree metadata, and worker ownership is still soft enough for a subagent to mutate automation memory outside its brief.

## Recommendations
- Treat Project 5 as the strongest current validation for D5 and D8.
- Carry the active-worktree metadata gap and worker-ownership leak forward as the next D9 tooling priorities.
- Use the next fake project to hit the doctrines still least-tested after Project 5: D3 balance, D6 enforceable process fixes, and D7 nested investigations.
