# 2026-04-04 Project 1 Scorecard

## Goal
Grade Project 1 (Fake Fintech Dashboard) on all 9 Vidux doctrines after the Task 1.1-1.3 evidence, investigation, and subagent work completed.

## Sources
- [Source: `/Users/leokwan/Development/ai/skills/vidux/projects/vidux-endurance/PLAN.md`] Project 1 task flow, Decision Log, Surprises, and Progress entries.
- [Source: `/Users/leokwan/Development/ai/skills/vidux/projects/vidux-endurance/evidence/2026-04-04-fintech-dashboard-baseline.md`] Repo-local fintech baseline and Nia fallback.
- [Source: `/Users/leokwan/Development/ai/skills/vidux/projects/vidux-endurance/investigations/transaction-history-wrong-totals.md`] Three-ticket compound investigation with Root Cause, Impact Map, Fix Spec, and tests.
- [Source: `/Users/leokwan/Development/ai/skills/vidux/projects/vidux-endurance/evidence/2026-04-04-fintech-subagent-synthesis.md`] Doctrine 9 parallel fan-out synthesis and token-savings assessment.

## Findings

### 1. Doctrine 1 — Plan is the store: pass
All meaningful state changes for Project 1 landed in `PLAN.md`, `evidence/`, and `investigations/`. No competing tracker or side doc was created.

### 2. Doctrine 2 — Unidirectional flow: pass
The lane followed gather -> plan update -> nested investigation -> subagent synthesis -> verify. Even the Nia failure was routed back through evidence and Decision Log before more execution happened.

### 3. Doctrine 3 — 50/30/20 split: friction
Project 1 skewed heavily toward planning and evidence because the work was a doctrine exercise and the Nia blocker removed any realistic code lane. The cycle was productive, but it did not resemble a balanced 50/30/20 mix.

### 4. Doctrine 4 — Evidence over instinct: pass
Every nontrivial move cited either repo files, project evidence, or the Nia initialize failure. No external claims were smuggled in after Nia failed.

### 5. Doctrine 5 — Design for death: friction
Checkpoint discipline was good: each task boundary was written back to the authority store. But Project 1 did not actually simulate compaction or session death, so the doctrine was only partially exercised here.

### 6. Doctrine 6 — Process fixes > code fixes: friction
The Nia blocker produced a real process fix: the Decision Log now forbids pretending external Nia coverage when the MCP server is down. That is useful, but there was no paired code fix because the failure was environmental rather than in repo code.

### 7. Doctrine 7 — Bug tickets are investigations: pass
The three-ticket totals bug was handled as one surface-level investigation with a shared root cause and Impact Map instead of three disconnected fixes.

### 8. Doctrine 8 — Cron prompts are harnesses, not snapshots: friction
Project 1 did not author or revise a harness prompt, so this doctrine remains mostly untested in this domain slice.

### 9. Doctrine 9 — Subagent coordinator pattern: pass
The coordinator stayed thin, two narrow explorers ran in parallel, and only synthesized citations came back into the main lane. Friction existed because the explorers overlapped on StrongYes sources, but the pattern still reduced coordinator context load enough to count as a pass.

## Recommendations
- Treat Project 1 as a strong validation of Doctrines 1, 2, 4, 7, and 9.
- Use Project 2 to stress the currently weaker doctrines: 5, 6, and 8.
- Keep recording environmental failures as process fixes in the Decision Log; that prevents future remediation loops.
