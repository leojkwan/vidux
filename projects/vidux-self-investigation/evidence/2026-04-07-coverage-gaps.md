# 2026-04-07 Contract Test Coverage Gap Analysis

## Goal
Identify untested surfaces in vidux's 149-test contract test suite.

## Sources
- [Source: codebase audit] tests/test_vidux_contracts.py (2312 lines, 149 tests)
- [Source: codebase audit] All scripts, commands, DOCTRINE.md, SKILL.md, LOOP.md

## Findings

### 1. vidux-witness.sh — zero functional tests
Only existence/executable check. No tests for JSON output, --all mode, stuck-task detection, fleet summary. Read-only observer with completely untested output contract.

### 2. vidux-install.sh — zero tests
22KB script absent from expected-scripts list (line 316). No existence, executable, or functional tests.

### 3. vidux-test-all.sh — zero tests
Meta-runner with --json and --fix flags but no contract tests validating its own output format.

### 4. vidux-fleet-rebuild.sh — zero tests
Destructive operation with zero coverage. No --dry-run flag exists.

### 5. SKILL.md "Compound Tasks & Investigations" — untested
Investigation template, [Investigation: ...] marker syntax, status propagation rules all untested. "investigation" doesn't appear in any test.

### 6. LOOP.md scorecard schema — untested
6-field scorecard (outcome, blocker_age, retry, evidence, proof, control_plane) not validated.

### 7. DOCTRINE.md Principle 5 "Compaction survival" — untested
"compaction" doesn't appear in any test. Load-bearing for multi-tool environments.

### 8. Commands vidux-loop.md and vidux-version.md — no frontmatter tests
Present in commands/ but omitted from test_commands_have_frontmatter list.

### 9. vidux-loop.sh — empty Tasks section not tested
Zero-task plan is a degenerate input that could cause unexpected JSON.

### 10. vidux-checkpoint.sh — fuzzy match failure not tested
No test covers task string that doesn't match any line in plan.

### 11. scripts/lib/ledger-emit.sh — emitters never invoked
Only sources/function-name checks. No actual JSONL output validation.

### 12. DOCTRINE.md Principles 7-9 — header-only tests
Content contracts not validated (investigation/nested, harness/stateless, coordinator/subagent).

### 13. vidux-dispatch.sh --merge-gate with conflicts — untested
No test provides merge markers to validate conflict/blocked return.

### 14. scripts/lib/queue-jsonl.sh — only existence tested
No push/pop/peek/drain functional coverage.

## Recommendations
- Priority 1: Add witness.sh functional tests (operator-facing, untested output)
- Priority 2: Add test-all.sh self-test (meta-runner should validate itself)
- Priority 3: Add compound task / investigation doc tests
- Priority 4: Add empty-input edge cases for loop and checkpoint
