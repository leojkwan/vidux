# QA Evidence: Stuck-Loop, Doctor, Merge Conflict, Live Plan Execution

**Date:** 2026-04-05
**Scripts tested:** vidux-loop.sh, vidux-doctor.sh
**Tester:** Claude (automated QA run)

---

## Task 3.2c: Stuck-Loop Torture Test

**Setup:** `/tmp/vidux-qa-stuck/PLAN.md` with:
- `[in_progress] Task 1: Build the widget with full integration support`
- 4 Progress entries all containing the first 40 chars of the task description

### Run 1 (trigger auto-block)

| Field | Expected | Actual | Pass? |
|-------|----------|--------|-------|
| stuck | true | true | PASS |
| auto_blocked | true | true | PASS |
| action | "auto_blocked" | "auto_blocked" | PASS |
| is_resuming | true | true | PASS |

**Side effects verified:**
- Task flipped from `[in_progress]` to `[blocked]` in PLAN.md
- `## Decision Log` section created with `[STUCK]` entry
- Context message: "Task stuck for 4+ cycles. Auto-blocked in PLAN.md. Human must unblock."

### Run 2 (DL-STUCK-TAG-BLIND fix verification)

| Field | Expected | Actual | Pass? |
|-------|----------|--------|-------|
| decision_log_count | 1 | 1 | PASS |
| decision_log_warning | true | true | PASS |
| decision_log_entries contains [STUCK] | yes | yes | PASS |
| Next task picked | Task 2 | Task 2 | PASS |

**Task 3.2c Result: 8/8 PASS**

---

## Task 3.2e: vidux-doctor.sh Validation

### Human-Readable Mode

| Check | Expected | Actual | Pass? |
|-------|----------|--------|-------|
| Total checks | 7 | 7 | PASS |
| Structured categories (Worktrees, Automations, Plans) | yes | yes | PASS |
| Color-coded output (ok/warn/BLOCK) | yes | yes | PASS |
| Summary line present | yes | yes (6/7 pass, 1 warning) | PASS |

### JSON Mode (`--json`)

| Check | Expected | Actual | Pass? |
|-------|----------|--------|-------|
| Valid JSON | yes | yes | PASS |
| checks array length | 7 | 7 | PASS |
| Each check has `id` | yes | yes | PASS |
| Each check has `category` | yes | yes | PASS |
| Each check has `status` | yes | yes | PASS |
| version/host/timestamp present | yes | yes | PASS |

**Check IDs found:**
1. `detached_same_head` (category: worktrees, status: pass)
2. `worktree_count` (category: worktrees, status: pass)
3. `dual_active_automations` (category: automations, status: pass)
4. `orphan_automations` (category: automations, status: pass)
5. `stale_in_progress` (category: plans, status: warn)
6. `missing_active_worktrees` (category: plans, status: pass)
7. `plan_merge_conflicts` (category: plans, status: pass)

**Task 3.2e Result: 10/10 PASS**

---

## Task 3.2f: Merge Conflict Detection

**Setup:** `/tmp/vidux-qa-conflict-repo/skills/vidux/projects/test-conflict/PLAN.md` with `<<<<<<< HEAD`, `=======`, `>>>>>>> feature-branch` markers. Doctor script copied into matching directory structure. Git repo initialized.

| Check | Expected | Actual | Pass? |
|-------|----------|--------|-------|
| Exit code | 1 | 1 | PASS |
| plan_merge_conflicts status | "block" | "block" | PASS |
| Human-readable shows BLOCK | yes | yes | PASS |
| JSON details contains file path | yes | yes | PASS |
| Other 6 checks still pass | yes | yes (6/7 pass) | PASS |

**Task 3.2f Result: 5/5 PASS**

---

## Task 3.3: Live Plan Execution

### Plan 1: vidux-v230/PLAN.md

| Check | Expected | Actual | Pass? |
|-------|----------|--------|-------|
| Valid JSON | yes | yes | PASS |
| No crash | yes | yes | PASS |
| contradiction_warning present | yes | yes (false) | PASS |
| contradiction_matches present | yes | yes ("") | PASS |
| contradicts_tag present | yes | yes ("") | PASS |

Output summary: cycle=7, action="execute", hot_tasks=17, cold_tasks=19, decision_log_count=3

### Plan 2: resplit-android/PLAN.md

| Check | Expected | Actual | Pass? |
|-------|----------|--------|-------|
| Valid JSON | yes | yes | PASS |
| No crash | yes | yes | PASS |
| contradiction_warning present | yes | yes (false) | PASS |
| contradiction_matches present | yes | yes ("") | PASS |
| contradicts_tag present | yes | yes ("") | PASS |

Output summary: cycle=11, action="gather_evidence", hot_tasks=10, cold_tasks=11, context_warning=true (244 lines)

### Plan 3: perf-investigation/PLAN.md

| Check | Expected | Actual | Pass? |
|-------|----------|--------|-------|
| Valid JSON | yes | yes | PASS |
| No crash | yes | yes | PASS |
| contradiction_warning present | yes | yes (true) | PASS |
| contradiction_matches present | yes | yes ("[DIRECTION] overlap(4): chrome,playwright,processes,zombie") | PASS |
| contradicts_tag present | yes | yes ("") | PASS |

Output summary: cycle=3, action="execute", hot_tasks=21, cold_tasks=0, decision_log_count=2, contradiction detected via keyword overlap

**Task 3.3 Result: 15/15 PASS**

---

## Grand Total

| Task | Sub-tests | Pass | Fail |
|------|-----------|------|------|
| 3.2c Stuck-loop torture | 8 | 8 | 0 |
| 3.2e Doctor validation | 10 | 10 | 0 |
| 3.2f Merge conflict detection | 5 | 5 | 0 |
| 3.3 Live plan execution | 15 | 15 | 0 |
| **TOTAL** | **38** | **38** | **0** |

**Overall: 38/38 PASS -- all sub-tests green.**

---

## Raw Outputs

### 3.2c Run 1 (stuck auto-block)

```json
{
  "cycle": 5,
  "task": "Task 1: Build the widget with full integration support",
  "type": "code",
  "has_evidence": false,
  "blocked": false,
  "stuck": true,
  "auto_blocked": true,
  "is_resuming": true,
  "task_open_questions": 0,
  "action": "auto_blocked",
  "context": "Task stuck for 4+ cycles. Auto-blocked in PLAN.md. Human must unblock.",
  "hot_tasks": 1,
  "cold_tasks": 0,
  "context_warning": false,
  "context_note": "",
  "decision_log_count": 0,
  "decision_log_warning": false,
  "decision_log_entries": "",
  "contradiction_warning": false,
  "contradiction_matches": "",
  "contradicts_tag": ""
}
```

### 3.2c Run 2 (DL-STUCK visible)

```json
{
  "cycle": 6,
  "task": "Task 2: Write unit tests for the widget",
  "type": "code",
  "has_evidence": false,
  "blocked": false,
  "stuck": false,
  "auto_blocked": false,
  "is_resuming": false,
  "task_open_questions": 0,
  "action": "gather_evidence",
  "context": "Task lacks evidence; gather before executing",
  "hot_tasks": 1,
  "cold_tasks": 0,
  "context_warning": false,
  "context_note": "",
  "decision_log_count": 1,
  "decision_log_warning": true,
  "decision_log_entries": "- [STUCK] [2026-04-05] Task stuck for 4+ cycles. Auto-blocked. Reason: - [2026-04-04] Cycle 4: Done: Task 1: Build the widget with full integration support — still not compiling",
  "contradiction_warning": false,
  "contradiction_matches": "",
  "contradicts_tag": ""
}
```

### 3.2c PLAN.md after mutations

```markdown
# Stuck Loop Test Plan

## Decision Log
- [STUCK] [2026-04-05] Task stuck for 4+ cycles. Auto-blocked. Reason: - [2026-04-04] Cycle 4: Done: Task 1: Build the widget with full integration support — still not compiling

## Tasks
- [blocked] Task 1: Build the widget with full integration support
- [pending] Task 2: Write unit tests for the widget

## Progress
- [2026-04-01] Cycle 1: Done: Task 1: Build the widget with full integration support — started scaffolding
- [2026-04-02] Cycle 2: Done: Task 1: Build the widget with full integration support — still working on scaffolding
- [2026-04-03] Cycle 3: Done: Task 1: Build the widget with full integration support — tried different approach
- [2026-04-04] Cycle 4: Done: Task 1: Build the widget with full integration support — still not compiling
```

### 3.3 vidux-v230 output

```json
{
  "cycle": 7,
  "task": "Task 3.2a: Create fake project 1 in /tmp ...",
  "type": "code",
  "has_evidence": true,
  "blocked": false,
  "stuck": false,
  "auto_blocked": false,
  "is_resuming": false,
  "task_open_questions": 0,
  "action": "execute",
  "context": "Ready to execute",
  "hot_tasks": 17,
  "cold_tasks": 19,
  "context_warning": false,
  "context_note": "",
  "decision_log_count": 3,
  "decision_log_warning": true,
  "decision_log_entries": "- [DIRECTION] [2026-04-05] This plan improves Vidux itself...",
  "contradiction_warning": false,
  "contradiction_matches": "",
  "contradicts_tag": ""
}
```

### 3.3 resplit-android output

```json
{
  "cycle": 11,
  "task": "Task C5: Bring folder/trip lifecycle to parity...",
  "type": "code",
  "has_evidence": false,
  "blocked": false,
  "stuck": false,
  "auto_blocked": false,
  "is_resuming": false,
  "task_open_questions": 0,
  "action": "gather_evidence",
  "context": "Task lacks evidence; gather before executing",
  "hot_tasks": 10,
  "cold_tasks": 11,
  "context_warning": true,
  "context_note": "PLAN.md has 11 completed tasks (244 lines). Consider archiving with vidux-checkpoint.sh --archive",
  "decision_log_count": 0,
  "decision_log_warning": false,
  "decision_log_entries": "",
  "contradiction_warning": false,
  "contradiction_matches": "",
  "contradicts_tag": ""
}
```

### 3.3 perf-investigation output

```json
{
  "cycle": 3,
  "task": "Task 1: Check if Playwright leaves zombie Chrome processes...",
  "type": "code",
  "has_evidence": true,
  "blocked": false,
  "stuck": false,
  "auto_blocked": false,
  "is_resuming": false,
  "task_open_questions": 0,
  "action": "execute",
  "context": "Ready to execute",
  "hot_tasks": 21,
  "cold_tasks": 0,
  "context_warning": false,
  "context_note": "",
  "decision_log_count": 2,
  "decision_log_warning": true,
  "decision_log_entries": "- [DIRECTION] [2026-04-05] The primary suspects are...",
  "contradiction_warning": true,
  "contradiction_matches": "[DIRECTION] overlap(4): chrome,playwright,processes,zombie",
  "contradicts_tag": ""
}
```
