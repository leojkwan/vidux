# QA: Dependency Matcher Torture Test (Task 3.2a)

**Date:** 2026-04-05
**Script under test:** `skills/vidux/scripts/vidux-loop.sh` (v2.3.0 dependency matcher)
**Test harness:** `/tmp/vidux-qa-deps/test-{1..7}/PLAN.md`
**Executor:** Claude Code (automated)

## Summary

**7 / 7 PASS**

## Pass/Fail Table

| # | Scenario | Expected `blocked` | Actual `blocked` | Result |
|---|----------|-------------------|-----------------|--------|
| 1 | Two tasks with `[Depends: none]` — must NOT block each other | `false` | `false` | PASS |
| 2 | Completed Task 1 + pending Task 2 `[Depends: Task 1]` — must NOT self-match | `false` | `false` | PASS |
| 3 | Completed Task 1.4 + pending Task 2 `[Depends: 1.4]` + pending Task 14 — must NOT partial-match | `false` | `false` | PASS |
| 4 | Pending Task 0.7 `[Depends: 0.3]` + pending Task 0.3 — MUST block | `true` | `true` | PASS |
| 5 | Multi-dep: completed 0.3/0.5/0.6, pending 0.4, pending Task 0.7 `[Depends: 0.3, 0.4, 0.5, 0.6]` — MUST block on 0.4 | `true` | `true` | PASS |
| 6 | v1 checkbox: `[x] Task 1` + `[ ] Task 2 [Depends: 1]` — must NOT block | `false` | `false` | PASS |
| 7 | Unstructured: completed "Fix the bug" + pending "Add reset `[Depends: Fix the bug]`" — must NOT block (graceful degradation) | `false` | `false` | PASS |

## Test Design Notes

- **Tests 4 and 5** require the *dependent* task to be listed before its blocker in the PLAN.md. `vidux-loop.sh` picks the first pending task by line order, so the task with the `[Depends:]` annotation must come first for the blocker check to fire on that task. The test plans are structured accordingly.
- **Test 5** verifies that the multi-dep comma-split logic (`IFS=',' read -ra DEP_PARTS`) correctly iterates all deps and short-circuits on the first unresolved one. The JSON output confirmed `context: "Waiting on: 0.4"` — it skipped 0.3 (completed) and caught 0.4 (pending).
- **Test 3** is the key partial-match regression test. The v2.3.0 fix extracts `Task N` or `Task N.N` identifiers via `grep -oE '^Task [0-9]+(\.[0-9]+)?'` and compares them with exact `==` matching, preventing "1.4" from matching "14".
- **Test 7** confirms that free-form dependency names (not matching `Task N` pattern) are silently ignored rather than causing errors or false blocks.

## Raw JSON Output

### Test 1
```json
{
  "cycle": 1,
  "task": "Task 1 — Build the widget [Depends: none]",
  "blocked": false,
  "action": "gather_evidence"
}
```

### Test 2
```json
{
  "cycle": 1,
  "task": "Task 2 — Run integration tests [Depends: Task 1]",
  "blocked": false,
  "action": "gather_evidence"
}
```

### Test 3
```json
{
  "cycle": 1,
  "task": "Task 2 — Validate parser output [Depends: 1.4]",
  "blocked": false,
  "action": "gather_evidence"
}
```

### Test 4
```json
{
  "cycle": 1,
  "task": "Task 0.7 — Implement API client [Depends: 0.3]",
  "blocked": true,
  "action": "blocked",
  "context": "Waiting on: 0.3"
}
```

### Test 5
```json
{
  "cycle": 1,
  "task": "Task 0.7 — End-to-end integration [Depends: 0.3, 0.4, 0.5, 0.6]",
  "blocked": true,
  "action": "blocked",
  "context": "Waiting on: 0.4"
}
```

### Test 6
```json
{
  "cycle": 1,
  "task": "Task 2 — Deploy to staging [Depends: 1]",
  "blocked": false,
  "action": "gather_evidence"
}
```

### Test 7
```json
{
  "cycle": 1,
  "task": "Add reset button [Depends: Fix the bug]",
  "blocked": false,
  "action": "gather_evidence"
}
```
