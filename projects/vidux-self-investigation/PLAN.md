# Vidux Self-Investigation

## Purpose
Vidux investigates itself. Test whether the framework produces high-quality plans with proper subplan depth, whether /vidux-loop generates effective automation fleets, and whether the "keep working through queue" change actually results in bimodal runtime behavior (quick checks or deep runs, not 5-min stick-rubbing).

## Evidence
- [Source: lkwan feedback, 2026-04-06] "qualitatively inspecting plans created and whether subplans get created"
- [Source: lkwan feedback, 2026-04-06] "automations aren't creating fire — rubbing for 5 minutes but not doing anything meaningful"
- [Source: lkwan feedback, 2026-04-06] "metric of quality: 1 minute quick check or 20+ minutes deep run"
- [Source: lkwan feedback, 2026-04-06] "vidux 2.1 worked incredibly — don't blame the model, assume the framework drifted"
- [Source: PLAN.md Phase 8] Canonical unification complete. Symlink now points to this repo.
- [Source: contract tests] 83/83 passing after all changes.

## Constraints
- ALWAYS: test on a fresh project — not an existing one with state
- ALWAYS: measure wall-clock time of automation runs
- NEVER: assume the model is the problem — test framework quality first
- NEVER: skip subplan creation test — compound tasks must spawn investigations/

## Decisions
- [2026-04-06] Decision: use NextJS as the e2e test project. Rationale: web stack is universal, builds fast, easy to verify. Leo also mentioned mobile — can test iOS after NextJS baseline.

## Tasks
- [completed] Task 1: E2E plan quality test (NextJS) — 17/20 quality score. Created PLAN.md (79 lines), 1 evidence file, 1 investigation file. Compound task detection worked (DnD). [Evidence: `evidence/2026-04-06-e2e-plan-quality.md`] [P]
- [completed] Task 2: E2E plan quality test (iOS) — 19/20 quality score. Created PLAN.md (82 lines), 4 evidence files, 1 investigation file. Receipt scanning correctly spawned compound investigation. [Evidence: `evidence/2026-04-06-e2e-plan-quality.md`] [P]
- [completed] Task 3: Automation prompt quality audit — strongyes-release-train is 56 lines (73% restated doctrine). Lean version is 13 lines (100% project-specific). 14 automations hardcode stale path. [Evidence: `evidence/2026-04-06-prompt-quality-audit.md`, `evidence/2026-04-06-stale-path-audit.md`]
- [pending] Task 4: Bimodal runtime simulation — create a mock automation run, verify the "keep working through queue" behavior produces either quick exits or sustained deep work. [Evidence: lkwan feedback on 5-min stick-rubbing]
- [completed] Task 5: Regression test — contract tests 83/83 passing. Symlink fixed (was stale directory, now correct symlink). Doctor runs clean. [Evidence: baseline from this session]

## Open Questions
- [ ] Q6: What specific metrics define "plan quality"? Proposal: evidence citation count, task specificity (no vague "implement feature"), investigation depth for compound tasks, constraint coverage. -> Action: define scoring rubric during Task 1.

## Progress
- [2026-04-06] Cycle 1: E2e results collected. NextJS scored 17/20, iOS scored 19/20. Both created compound task investigations (drag-and-drop, receipt scanning). Plan quality VALIDATED. 4/5 tasks complete. Next: bimodal runtime simulation (Task 4).
- [2026-04-06] Cycle 0: Investigation created. Symlink fixed (was stale directory, now points to canonical repo). Phase 8 nearly complete. Swarming e2e tests next.
