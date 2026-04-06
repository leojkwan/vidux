# 2026-04-05 Final Endurance Test Scorecard

## Goal
Aggregate all 3 projects across all 9 Vidux v2.2.0 doctrines into a final evaluation. Identify strengths, friction points, bugs, and v2.3.0 priorities.

## Sources
- [Source: `evidence/2026-04-04-project1-scorecard.md`] Project 1 (Fake Fintech Dashboard) doctrine grades.
- [Source: `evidence/2026-04-04-project2-scorecard.md`] Project 2 (Fake Health Tracker iOS App) doctrine grades.
- [Source: `evidence/2026-04-05-project3-scorecard.md`] Project 3 (Mechanical Enforcement Suite) doctrine grades.
- [Source: `evidence/2026-04-04-fintech-dashboard-baseline.md`] Nia fallback and evidence discipline.
- [Source: `evidence/2026-04-04-fintech-subagent-synthesis.md`] Subagent coordinator pattern validation.
- [Source: `evidence/2026-04-04-health-tracker-resume-proof.md`] Death-drill resume and dependency-matcher bug discovery.
- [Source: `evidence/2026-04-04-health-tracker-build-failure-drill.md`] Code fix + process fix pairing.
- [Source: `evidence/2026-04-04-health-tracker-harness-review.md`] Evergreen harness prompt validation.
- [Source: `evidence/2026-04-05-stuck-loop-mechanical-test.md`] Stuck-loop auto-blocking verification.
- [Source: `evidence/2026-04-05-decision-log-contradiction-test.md`] Decision Log surfacing and `[Depends: none]` bug.
- [Source: `evidence/2026-04-05-q-gating-mechanical-test.md`] Task-linked Q-gating and independent bug confirmation.
- [Source: Contract tests, 2026-04-05] 63/63 passed, known ResourceWarning.

## Aggregate Doctrine Matrix

| Doctrine | P1 (Fintech) | P2 (Health) | P3 (Enforcement) | Aggregate |
|----------|:---:|:---:|:---:|:---:|
| D1: Plan is the store | pass | pass | pass | **PASS** |
| D2: Unidirectional flow | pass | pass | pass | **PASS** |
| D3: 50/30/20 split | friction | friction | minimal | **FRICTION** |
| D4: Evidence over instinct | pass | pass | pass | **PASS** |
| D5: Design for death | friction | pass | minimal | **PASS** |
| D6: Process fixes > code fixes | friction | pass | pass | **PASS** |
| D7: Bug tickets are investigations | pass | friction | pass | **PASS** |
| D8: Cron harnesses not snapshots | friction | pass | minimal | **PASS** |
| D9: Subagent coordinator | pass | friction | minimal | **PASS** |

**Overall: 8 of 9 doctrines PASS. 1 doctrine (D3: 50/30/20 split) remains at FRICTION.**

### Grading rationale

- **PASS** requires at least one clean pass across the three projects, with no project producing a failure (friction + minimal exercise elsewhere is acceptable when the doctrine was genuinely tested and passed in at least one project).
- **FRICTION** means the doctrine was tested in multiple projects and never achieved a clean pass. D3 showed friction in both projects that could exercise it (P1 and P2) and was not testable in P3.
- **Minimal exercise** is not a failure -- it means the project shape did not create conditions to test the doctrine. These are excluded from aggregate scoring.

## Findings

### Top 3 Strengths

1. **D1 + D2: Plan-as-store and unidirectional flow are rock-solid.** All 3 projects passed cleanly on both. The PLAN.md authority model held under Nia failures (P1), session death (P2), and mechanical enforcement mutations (P3). No competing state leaked in anywhere.

2. **D4: Evidence discipline is the strongest cultural outcome.** Every finding across 11 evidence files cites specific JSON output, file diffs, line numbers, or compiler output. The Nia failure in P1 was the hardest test -- when the external knowledge source went down, the system fell back to repo-local evidence rather than fabricating claims. This is the doctrine working exactly as intended.

3. **D7: Investigation pattern works across different bug shapes.** P1 handled a multi-ticket surface investigation (three transaction-history bugs with shared root cause). P3 handled a multi-manifestation mechanical bug (dependency matcher triple-bug converging on line 124). Both followed the "one root cause, multiple surfaces" investigation model instead of filing disconnected fixes.

### Top 3 Friction Points

1. **D3: 50/30/20 split never achieved a balanced cycle.** P1 skewed planning-heavy due to Nia failure removing the code lane. P2 was closer but still planning-heavy. P3 was verification-only. The endurance test format (fake projects, doctrine exercises) inherently resists a balanced split. This doctrine may need different test conditions -- a real multi-day project with actual code output -- to validate properly.

2. **Decision Log contradiction detection is LLM judgment only.** The script surfaces entries so the LLM cannot claim ignorance, but there is no mechanical block on contradicting tasks. This is acknowledged as by-design in v2.2.0, but it means contradiction prevention depends entirely on the LLM reading the entries and refusing to proceed. In high-pressure or high-context-load situations, an LLM might miss a contradiction.

3. **`hot_tasks` count in JSON reflects pre-mutation state.** When `vidux-loop.sh` auto-blocks a stuck task, the `hot_tasks` field still reports the count from before the mutation. An LLM consumer reading the JSON might misinterpret the task landscape. Low severity but worth aligning in v2.3.0.

### Top 3 Bugs Found

1. **Dependency matcher triple-bug (HIGH priority).** Line 124 of `vidux-loop.sh` uses `grep -qi "$DEP_TARGET"` against full task line text instead of matching against task identifiers. This produces three failure modes:
   - Self-match on completed dependency IDs (e.g., "2.4" matches task text containing "2.4")
   - Self-match on active task's own `[Depends: X]` text
   - Literal "none" in `[Depends: none]` matches other tasks also containing `[Depends: none]`
   - **Found in:** P2 (Task 2.1) and P3 (Tasks 3.2, 3.3)
   - **Fix:** Match against task identifiers only, or at minimum add a `[Depends: none]` short-circuit

2. **ResourceWarning on unclosed PLAN.md file handle (LOW priority).** `test_vidux_contracts.py:983` uses `open(plan).read()` without a context manager. Functional tests pass, but the warning is noise in every test run.
   - **Found in:** P2 contract run and P3 contract run
   - **Fix:** Replace with `with open(plan) as f: content = f.read()`

3. **vidux-loop.sh reporting inconsistency: `blocked` vs `auto_blocked` (LOW priority).** The `blocked` JSON field only reflects dependency-based blocking. Stuck-loop auto-blocking sets `auto_blocked` and `action: auto_blocked` but leaves `blocked: false`. An LLM consumer must check both fields to understand the full blocking picture.
   - **Found in:** P3 (Task 3.1)
   - **Fix:** Either unify into a single `blocked` field with a `blocked_reason` enum, or document the two-field contract explicitly in SKILL.md

## v2.3.0 Priority Recommendations

### P0 -- Must fix before next endurance test

1. **Fix the dependency matcher (line 124).** This is the only bug that causes incorrect blocking of valid tasks in real plans. Recommended approach: extract task identifiers into a separate matching step, and short-circuit when `DEP_TARGET` is "none" (case-insensitive).

2. **Fix the ResourceWarning.** One-line change (`with open()` context manager). Eliminates noise from every contract test run.

### P1 -- Should fix for v2.3.0

3. **Align `hot_tasks` count with post-mutation state.** Move the `hot_tasks` computation to after stuck-loop enforcement so the JSON output reflects the actual task landscape.

4. **Document the `blocked` vs `auto_blocked` contract.** Either unify the fields or add an explicit note in SKILL.md explaining that consumers must check both.

5. **Consider mechanical contradiction guardrails for Decision Log.** Even a lightweight check -- flagging tasks whose description contains keywords from `[DELETION]` entries -- would add a safety net beyond pure LLM judgment.

### P2 -- Nice to have

6. **Revisit D3 (50/30/20 split) testing methodology.** The endurance test format cannot validate this doctrine. Consider adding a "real mini-project" lane in the next endurance test that produces actual committed code.

7. **Add a `--dry-run` flag to vidux-loop.sh.** Would allow testing stuck-loop and Q-gating without mutating the plan file, making evidence collection cleaner.

## Final Verdict

**Vidux v2.2.0 passes the endurance test: 8/9 doctrines PASS, 1 FRICTION (D3), 0 FAIL.**

The framework's core mechanical enforcement (stuck-loop, Q-gating, plan-as-store) is sound. The dependency matcher triple-bug is the most impactful defect found -- it affects real plan execution and should be the first fix in v2.3.0. The single friction doctrine (50/30/20 split) is a testing-methodology gap rather than a framework deficiency.

Contract suite: 63/63 tests passing. The framework is ready for real project use with the dependency matcher bug as a known limitation.
