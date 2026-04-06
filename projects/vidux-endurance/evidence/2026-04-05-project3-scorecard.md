# 2026-04-05 Project 3 Scorecard

## Goal
Grade Project 3 (Vidux Mechanical Enforcement Suite) on all 9 Vidux doctrines after the stuck-loop, Decision Log contradiction, and Q-gating tests completed.

## Sources
- [Source: `evidence/2026-04-05-stuck-loop-mechanical-test.md`] Stuck-loop detection and auto-blocking verification (Task 3.1).
- [Source: `evidence/2026-04-05-decision-log-contradiction-test.md`] Decision Log surfacing, contradiction design gap, and `[Depends: none]` bug (Task 3.2).
- [Source: `evidence/2026-04-05-q-gating-mechanical-test.md`] Task-linked Q-gating verification and independent `[Depends: none]` confirmation (Task 3.3).
- [Source: `python3 -m unittest discover -s skills/vidux/tests -p 'test_*.py' -q`, executed 2026-04-05] Contract suite passed 63/63 tests. Known `ResourceWarning` on unclosed `PLAN.md` file handle persists.

## Findings

### 1. Doctrine 1 -- Plan is the store: pass
All three tasks operated exclusively on synthetic PLAN.md files as the authority store. Stuck-loop detection mutated the plan in-place (flipping `[in_progress]` to `[blocked]`, injecting `[STUCK]` into Decision Log). Q-gating reads the plan's Open Questions section to determine gate status. No side state or external tracker was used.

### 2. Doctrine 2 -- Unidirectional flow: pass
Each task followed a clean gather -> execute -> verify -> write-evidence flow. The stuck-loop test created a synthetic plan, ran the script, diffed before/after, and recorded findings. The Decision Log test ran two scenarios (non-contradicting and contradicting tasks) sequentially. The Q-gating test ran three scenarios (no Q-refs, with Q-refs, with `[Depends: none]`). No backward loops or ad hoc restarts occurred.

### 3. Doctrine 3 -- 50/30/20 split: minimal exercise
Project 3 was entirely verification-focused: run script, check output, record evidence. There was no planning phase or code-authoring phase to balance against. The doctrine was not meaningfully testable in this project shape.

### 4. Doctrine 4 -- Evidence over instinct: pass
Every finding is grounded in specific JSON output fields, before/after plan diffs, and line-number citations from `vidux-loop.sh`. The `[Depends: none]` bug was discovered empirically (unexpected `blocked: true` in JSON output) and traced to line 124 of the script. No claims were made without mechanical evidence.

### 5. Doctrine 5 -- Design for death: minimal exercise
Project 3 tasks were single-session, single-script executions. No session death was simulated and no checkpoint-resume was tested. The doctrine was not stressed here.

### 6. Doctrine 6 -- Process fixes > code fixes: pass
Task 3.2 identified a design gap (contradiction detection is LLM judgment, not mechanical) and documented it as an acknowledged limitation rather than a bug to fix. Task 3.3 independently confirmed the `[Depends: none]` bug and proposed both a workaround (omit the annotation) and a code fix (short-circuit when `DEP_TARGET` is "none"). The project produced process-level recommendations for v2.3.0 rather than just pointing at broken lines.

### 7. Doctrine 7 -- Bug tickets are investigations: pass
The dependency matcher bug was treated as one root cause with three surface manifestations (self-match on completed IDs, self-match on own `[Depends: X]` text, literal "none" match). Tasks 3.2 and 3.3 independently converged on the same root cause (line 124's `grep -qi "$DEP_TARGET"` matching full task text instead of task identifiers), which is exactly the investigation pattern the doctrine requires.

### 8. Doctrine 8 -- Cron prompts are harnesses, not snapshots: minimal exercise
No harness prompt was authored or reviewed in Project 3. The doctrine was not tested.

### 9. Doctrine 9 -- Subagent coordinator pattern: minimal exercise
No subagent fan-out was needed for the mechanical enforcement tests. Each task was a self-contained script run. The doctrine was not tested.

## Summary Table

| Doctrine | Grade | Notes |
|----------|-------|-------|
| D1: Plan is the store | pass | Script mutates plan as authority store |
| D2: Unidirectional flow | pass | Clean gather-execute-verify-evidence flow |
| D3: 50/30/20 split | minimal exercise | Verification-only project shape |
| D4: Evidence over instinct | pass | All findings cite JSON output and line numbers |
| D5: Design for death | minimal exercise | No session death simulated |
| D6: Process fixes > code fixes | pass | Design gap documented, root cause traced, v2.3.0 recs produced |
| D7: Bug tickets are investigations | pass | Triple-bug converged to single root cause |
| D8: Cron harnesses not snapshots | minimal exercise | No harness authored |
| D9: Subagent coordinator | minimal exercise | No fan-out needed |

## Contract Test Results
63/63 passed. Known issue: `ResourceWarning: unclosed file` on `PLAN.md` in `test_vidux_contracts.py:983`. This is a test-level resource leak, not a functional failure. Should be fixed in v2.3.0 with a `with open()` context manager.

## Recommendations
- Project 3 is the strongest validation of Doctrines 1, 4, 6, and 7 across the endurance test.
- The four "minimal exercise" doctrines (3, 5, 8, 9) were adequately covered by Projects 1 and 2. Project 3's focused scope was the right call.
- The dependency matcher triple-bug is the highest-priority mechanical fix for v2.3.0.
