# 2026-04-04 Project 2 Scorecard

## Goal
Grade Project 2 (Fake Health Tracker iOS App) on all 9 Vidux doctrines after the death-drill resume, build-failure/process-fix exercise, harness review, and contract verification.

## Sources
- [Source: `/Users/leokwan/Development/ai/skills/vidux/projects/vidux-endurance/PLAN.md`] Project 2 task flow, Surprises, and Progress entries.
- [Source: `/Users/leokwan/Development/ai/skills/vidux/projects/vidux-endurance/evidence/2026-04-04-health-tracker-session-death-drill.md`] Mid-task checkpoint plan for the session-death drill.
- [Source: `/Users/leokwan/Development/ai/skills/vidux/projects/vidux-endurance/evidence/2026-04-04-health-tracker-resume-proof.md`] File-only resume verification and dependency-matcher bug analysis.
- [Source: `/Users/leokwan/Development/ai/skills/vidux/projects/vidux-endurance/evidence/2026-04-04-health-tracker-build-failure-drill.md`] Real compile failure, verified `/tmp` code fix, and Doctrine-6 process fix.
- [Source: `/Users/leokwan/Development/ai/skills/vidux/projects/vidux-endurance/evidence/2026-04-04-health-tracker-harness-review.md`] Evergreen harness prompt plus Doctrine-8 self-review.
- [Source: `python3 -m unittest discover -s /Users/leokwan/Development/ai/skills/vidux/tests -p 'test_*.py' -q`, executed 2026-04-04] Contract suite passed 63/63 tests with the same known `ResourceWarning` on `PLAN.md`.

## Findings

### 1. Doctrine 1 — Plan is the store: pass
Project 2 resumed, verified, and graded entirely from `PLAN.md` plus evidence files. No alternate tracker or ad hoc scratch state became authoritative.

### 2. Doctrine 2 — Unidirectional flow: pass
The lane followed gather -> resume proof -> build-failure drill -> harness review -> contract verification -> scorecard. Even the loop-script bug and compiler-environment noise were routed back into evidence before scoring.

### 3. Doctrine 3 — 50/30/20 split: friction
Project 2 contained more real execution than Project 1 because the `/tmp` Swift fixture produced a concrete compile/fix/re-verify loop. It still skewed planning-heavy overall, so the split is closer to target than Project 1 but not yet balanced.

### 4. Doctrine 4 — Evidence over instinct: pass
Every major claim cites a file, command, or compiler/test output. The scorecard is grounded in observed failures and recoveries rather than generic confidence language.

### 5. Doctrine 5 — Design for death: pass
Task 2.1 successfully resumed from disk-only state after an intentional stop. The file-backed cues were enough to continue without chat memory, which is the core requirement of the doctrine.

### 6. Doctrine 6 — Process fixes > code fixes: pass
Project 2 produced both sides of the doctrine: an immediate `/tmp` code repair and a reusable process fix that normalizes fake iOS compile drills with a `/tmp` module cache plus a required verification rerun.

### 7. Doctrine 7 — Bug tickets are investigations: friction
This project focused on death-drill and build-failure mechanics, not a multi-ticket surface investigation. Doctrine 7 was respected in spirit by refusing to jump from noisy compiler output straight to scoring, but it was not meaningfully stress-tested here.

### 8. Doctrine 8 — Cron prompts are harnesses, not snapshots: pass
The candidate harness prompt stayed evergreen: it names mission, authority, role, DNA, and guardrails without embedding task numbers, branch names, cycle state, or transient blockers.

### 9. Doctrine 9 — Subagent coordinator pattern: friction
No subagent fan-out was needed for Project 2, so Doctrine 9 remained mostly unexercised in this slice. That is acceptable for the fake project, but it means Project 3 and the final aggregate score still need to carry more of the coordinator-pattern burden.

## Recommendations
- Treat Project 2 as the strongest validation so far for Doctrines 5, 6, and 8.
- Keep the `vidux-loop.sh` dependency self-match bug and incomplete worktree-handoff coverage on the v2.3.0 priority list; they are the main Project 2 friction points.
- Use Project 3 to stress the still-under-tested enforcement doctrines: stuck-loop, Decision Log, and Q-gating.
