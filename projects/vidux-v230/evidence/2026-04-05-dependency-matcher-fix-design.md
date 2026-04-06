# Task 0.3: Dependency Matcher Fix Design

**Date:** 2026-04-05
**Task:** Design the fix for DEP-MATCHER-TRIPLE (P0) and DL-STUCK-TAG-BLIND (P1)
**Target file:** `skills/vidux/scripts/vidux-loop.sh`

## Sources

- [Source: `evidence/2026-04-05-vidux-loop-annotated-analysis.md`] Annotated line-by-line analysis with three failure modes documented.
- [Source: `evidence/2026-04-05-two-machine-convergence.md`] Two-machine convergence confirming DEP-MATCHER-TRIPLE as STRONG convergence, P0.
- [Source: `projects/vidux-endurance/evidence/2026-04-05-q-gating-mechanical-test.md`] `[Depends: none]` false-positive discovery (Failure 3).
- [Source: `projects/vidux-endurance/PLAN.md` Surprises] Cycle 5 self-match on `[Depends: 1.4]`, Cycle 6 stalls on completed `2.4`.
- [Source: `vidux-loop.sh`] Lines 59, 116-127 — the code under modification.
- [Source: Real PLAN.md files] vidux-v230/PLAN.md, vidux-stress-test/PLAN.md, vidux-endurance/PLAN.md — used to derive task ID conventions.

---

## Bug Summary

### DEP-MATCHER-TRIPLE (Lines 119-127)

Line 124 runs `grep -qi "$DEP_TARGET"` against the full text of every non-completed task line. Three failure modes:

| # | Failure | Example | Root cause |
|---|---------|---------|------------|
| 1 | Self-match on own `[Depends:]` text | Task with `[Depends: Task B]` always self-matches because its own line contains "Task B" | Grep searches ALL non-completed lines including the current task |
| 2 | Partial text match on peer tasks | `[Depends: 1.4]` matches a peer task containing "Scale to 2.4x" or "Task 14" | Grep does substring match on full task text, not identifier match |
| 3 | `[Depends: none]` matches "none" in peers | Two tasks with `[Depends: none]` false-block each other | "none" is treated as a dependency target instead of a sentinel |

### DL-STUCK-TAG-BLIND (Line 59)

The stuck-loop enforcement at line 181 writes `[STUCK]` entries to the Decision Log. But the parser at line 59 only matches `DELETION|RATE-LIMIT|DIRECTION`. The script cannot read back its own stuck-loop mutations.

---

## Fix 1: DL-STUCK-TAG-BLIND (one-line change)

### old_string (line 59)

```bash
  DL_ENTRIES="$(printf '%s' "$DL_BLOCK" | grep -E '^\- \[(DELETION|RATE-LIMIT|DIRECTION)\]' || true)"
```

### new_string

```bash
  DL_ENTRIES="$(printf '%s' "$DL_BLOCK" | grep -E '^\- \[(DELETION|RATE-LIMIT|DIRECTION|STUCK)\]' || true)"
```

### Rationale

The script writes `[STUCK]` entries at line 181. The parser must recognize them so that `DL_COUNT` and `DL_ENTRIES` include stuck-loop events on subsequent cycles. Without this, a stuck-loop auto-block creates a Decision Log entry that the script itself ignores, which is a self-awareness gap.

### Backward compatibility

No impact. `[STUCK]` entries only exist if the stuck-loop enforcement wrote them. Plans without stuck entries are unaffected. The grep still uses `||true` so zero matches produce no error.

---

## Fix 2: DEP-MATCHER-TRIPLE (lines 116-127)

### Design approach

Hybrid: short-circuit "none" + match against extracted task identifiers only.

This is the approach directed by the v2.3.0 PLAN.md Decision Log entry: "Fix dependency matcher by extracting task IDs into a separate matching step, not by patching the grep."

### Task identifier conventions observed in real plans

From studying real PLAN.md files across vidux-v230, vidux-stress-test, and vidux-endurance:

| Pattern | Example | Where seen |
|---------|---------|------------|
| `Task N.N:` | `Task 0.3: Design the dependency matcher fix` | vidux-v230/PLAN.md |
| `Task N:` | `Task 1: Research modern AI agent orchestration` | vidux-stress-test/PLAN.md |
| `Task N.N:` | `Task 1.4: Grade Project 1 on all 9 doctrines` | vidux-endurance/PLAN.md |
| Bare numeric `N.N` | `[Depends: 0.2]`, `[Depends: 1.4]` | All plans (in Depends annotations) |
| Bare numeric `N` | `[Depends: Task 1]` | vidux-stress-test/PLAN.md |

The `[Depends: X]` target can be:
1. A bare numeric ID: `0.2`, `1.4`, `2.4`
2. A full task reference: `Task 1`, `Task B`
3. A comma-separated list: `0.3, 0.4, 0.5, 0.6` (seen in Task 0.7)
4. The sentinel `none`

### Algorithm

```
1. Extract DEP_TARGET from [Depends: X]
2. If DEP_TARGET is "none" (case-insensitive) -> skip, not blocked
3. Split DEP_TARGET on comma to handle multi-dep lists
4. For each dep in the list:
   a. Trim whitespace
   b. Extract task identifiers from all non-completed task lines
      (the identifier is the "Task N.N" or "Task N" prefix of the description)
   c. Match the dep against extracted identifiers using word-boundary-safe matching
   d. If any identifier matches -> blocked
5. If no identifiers match any dep -> not blocked
```

### Identifier extraction

From each non-completed task line, strip the FSM/checkbox prefix and extract the task identifier:

```bash
# Input:  "- [pending] Task 0.3: Design the dependency matcher fix [Evidence: ...] [Depends: 0.2]"
# Step 1: Strip prefix -> "Task 0.3: Design the dependency matcher fix [Evidence: ...] [Depends: 0.2]"
# Step 2: Extract ID  -> "Task 0.3"
```

The identifier regex: `^Task [0-9]+(\.[0-9]+)?` — matches "Task 1", "Task 0.3", "Task 14", etc.

### Matching rules

The dep target can be in two forms:
- **Full form:** `Task 0.3` — match directly against extracted identifiers
- **Short form:** `0.3` — match against the numeric portion of identifiers

For short-form matching, the critical requirement is preventing partial matches:
- `1.4` must NOT match `Task 14` (no dot in "14")
- `1.4` must NOT match `Task 2.14` (different number before dot)
- `1.4` must NOT match `Task 1.42` (different number after dot)
- `1.4` MUST match `Task 1.4`

This is achieved by matching the dep target against the numeric suffix of each identifier with word boundaries. In practice: extract the numeric part from the identifier (`0.3` from `Task 0.3`) and compare it exactly to the dep target. Exact string comparison, not substring grep.

### old_string (lines 116-127)

```bash
# Blocker check: [Depends: X] where X still has incomplete tasks
# Note: tasks with [blocked] FSM state are filtered out of TASK_LINE selection entirely,
# so they never reach here. This check handles [Depends:] annotations on pending/in_progress tasks.
BLOCKED=false; BLOCKER_NOTE=""
DEP="$(echo "$TASK_DESC" | grep -o '\[Depends: [^]]*\]' || true)"
if [ -n "$DEP" ]; then
  DEP_TARGET="${DEP#\[Depends: }"; DEP_TARGET="${DEP_TARGET%\]}"
  # Blocked if dep target appears in any non-completed task (v1 or v2)
  if grep -E '^\- (\[ \]|\[(pending|in_progress)\]) ' "$PLAN" | grep -qi "$DEP_TARGET"; then
    BLOCKED=true; BLOCKER_NOTE="Waiting on: $DEP_TARGET"
  fi
fi
```

### new_string (lines 116-127 replacement)

```bash
# Blocker check: [Depends: X] where X still has incomplete tasks
# Note: tasks with [blocked] FSM state are filtered out of TASK_LINE selection entirely,
# so they never reach here. This check handles [Depends:] annotations on pending/in_progress tasks.
# Fix (v2.3.0): matches against task identifiers only, not full task text.
# Handles [Depends: none], multi-dep lists, and numeric ID partial-match safety.
BLOCKED=false; BLOCKER_NOTE=""
DEP="$(echo "$TASK_DESC" | grep -o '\[Depends: [^]]*\]' || true)"
if [ -n "$DEP" ]; then
  DEP_TARGET="${DEP#\[Depends: }"; DEP_TARGET="${DEP_TARGET%\]}"
  # Short-circuit: "none" is a sentinel, not a dependency (fixes [Depends: none] false-positive)
  if [[ "${DEP_TARGET,,}" != "none" ]]; then
    # Extract task identifiers from all non-completed task lines (exclude current task line)
    # Each identifier is "Task N" or "Task N.N" from the start of the task description
    PENDING_IDS="$(grep -nE '^\- (\[ \]|\[(pending|in_progress)\]) ' "$PLAN" \
      | grep -v "^${LINE_NUM}:" \
      | sed -E 's/^[0-9]+:- \[([^]]*)\] //' \
      | grep -oE '^Task [0-9]+(\.[0-9]+)?' || true)"
    # Split DEP_TARGET on comma for multi-dep support (e.g., [Depends: 0.3, 0.4, 0.5])
    IFS=',' read -ra DEP_PARTS <<< "$DEP_TARGET"
    for DEP_PART in "${DEP_PARTS[@]}"; do
      DEP_PART="$(echo "$DEP_PART" | xargs)"  # trim whitespace
      [ -z "$DEP_PART" ] && continue
      # Match against each pending task identifier
      while IFS= read -r TASK_ID; do
        [ -z "$TASK_ID" ] && continue
        # Full form: "Task 0.3" matches identifier "Task 0.3"
        if [[ "$TASK_ID" == "$DEP_PART" ]]; then
          BLOCKED=true; BLOCKER_NOTE="Waiting on: $DEP_PART"; break 2
        fi
        # Short form: "0.3" matches the numeric part of "Task 0.3"
        TASK_NUM="${TASK_ID#Task }"
        if [[ "$TASK_NUM" == "$DEP_PART" ]]; then
          BLOCKED=true; BLOCKER_NOTE="Waiting on: $DEP_PART"; break 2
        fi
      done <<< "$PENDING_IDS"
    done
  fi
fi
```

### Line-by-line rationale

1. **`[[ "${DEP_TARGET,,}" != "none" ]]`** — Bash 4+ lowercase comparison. Short-circuits "none", "None", "NONE". Fixes Failure 3.

2. **`grep -nE ... | grep -v "^${LINE_NUM}:"`** — Exclude the current task's own line from the candidate set. This eliminates Failure 2 (self-match) at the source. We use `grep -n` to prefix line numbers, then filter out the current task's line number. This is more robust than the alternative of filtering post-extraction, because it prevents the current task's `[Depends: X]` text from ever entering the candidate pool.

3. **`sed -E 's/^[0-9]+:- \[([^]]*)\] //'`** — Strip the line number prefix (from `grep -n`) and the FSM/checkbox prefix to get the raw task description. The `[0-9]+:` prefix comes from `grep -n`.

4. **`grep -oE '^Task [0-9]+(\.[0-9]+)?'`** — Extract only the structured task identifier. This is the key fix for Failure 1: we match against "Task 0.3", not against "Task 0.3: Design the dependency matcher fix [Evidence: ...] [Depends: 0.2]". Full task text never enters the comparison.

5. **`IFS=',' read -ra DEP_PARTS`** — Handle comma-separated dep lists like `[Depends: 0.3, 0.4, 0.5, 0.6]` (seen in Task 0.7 of vidux-v230/PLAN.md).

6. **`[[ "$TASK_ID" == "$DEP_PART" ]]`** — Exact string comparison, not substring grep. "Task 1.4" matches only "Task 1.4", never "Task 14" or "Task 2.14". This fixes Failure 1 completely.

7. **`TASK_NUM="${TASK_ID#Task }"`** — Extract numeric portion for short-form matching. "Task 0.3" becomes "0.3". Then `[[ "$TASK_NUM" == "$DEP_PART" ]]` does exact comparison: "0.3" matches "0.3" but not "10.3" or "0.31".

8. **`break 2`** — Exit both the inner (`while`) and outer (`for`) loops on first match. One unresolved dependency is enough to block.

### Backward compatibility

**v1 checkbox format:** The `grep -nE '^\- (\[ \]|\[(pending|in_progress)\]) '` still matches v1 `- [ ]` lines. No change.

**v2 FSM format:** Same grep pattern matches `- [pending]` and `- [in_progress]`. No change.

**Unstructured tasks (no "Task N.N:" prefix):** If a plan uses free-form task descriptions without the `Task N:` convention, `PENDING_IDS` will be empty (the `grep -oE` finds no matches). In this case, the dep check produces no match, so `BLOCKED` stays `false`. This is a behavioral change: previously, unstructured tasks with `[Depends: X]` would incorrectly self-match (always blocked). Now they silently skip the dependency check. This is strictly better: a false negative (not blocking when it should) is less harmful than a false positive (blocking when it should not), and the `[Depends:]` annotation itself serves as a signal to the LLM consumer. A consumer that sees `[Depends: fix the widget]` in the task text can apply judgment even if the mechanical check does not fire.

**`[Depends: none]` sentinel:** Previously always self-matched and caused false blocking. Now short-circuited. This is a correctness fix, not a behavioral change.

**`${DEP_TARGET,,}` requires Bash 4+:** macOS ships Bash 3.2 by default, but the shebang is `#!/usr/bin/env bash`. If the user has Homebrew bash (Bash 5+), this works. If they are on stock macOS Bash 3.2, the `,,` lowercase operator is unavailable. Mitigation: add a Bash 4 guard or use `tr '[:upper:]' '[:lower:]'` instead. See "Bash 3.2 compatibility" below.

### Bash 3.2 compatibility note

The `${var,,}` lowercase expansion requires Bash 4+. Stock macOS has Bash 3.2. Two options:

**Option A (recommended):** Replace `[[ "${DEP_TARGET,,}" != "none" ]]` with:
```bash
if ! echo "$DEP_TARGET" | grep -qi '^none$'; then
```
This is POSIX-compatible and works on any bash version. The `grep -qi '^none$'` anchors to the full string so "none" matches but "nonesuch" does not.

**Option B:** Add a bash version check at the top of the script. Heavier, not worth it for one usage.

Recommendation: Use Option A. The final `new_string` above should use `grep -qi '^none$'` instead of `${DEP_TARGET,,}`. Updated line:

```bash
  if ! echo "$DEP_TARGET" | grep -qi '^none$'; then
```

### Final new_string (Bash 3.2 safe)

```bash
# Blocker check: [Depends: X] where X still has incomplete tasks
# Note: tasks with [blocked] FSM state are filtered out of TASK_LINE selection entirely,
# so they never reach here. This check handles [Depends:] annotations on pending/in_progress tasks.
# Fix (v2.3.0): matches against task identifiers only, not full task text.
# Handles [Depends: none], multi-dep lists, and numeric ID partial-match safety.
BLOCKED=false; BLOCKER_NOTE=""
DEP="$(echo "$TASK_DESC" | grep -o '\[Depends: [^]]*\]' || true)"
if [ -n "$DEP" ]; then
  DEP_TARGET="${DEP#\[Depends: }"; DEP_TARGET="${DEP_TARGET%\]}"
  # Short-circuit: "none" is a sentinel, not a dependency (fixes [Depends: none] false-positive)
  if ! echo "$DEP_TARGET" | grep -qi '^none$'; then
    # Extract task identifiers from all non-completed task lines (exclude current task line)
    # Each identifier is "Task N" or "Task N.N" from the start of the task description
    PENDING_IDS="$(grep -nE '^\- (\[ \]|\[(pending|in_progress)\]) ' "$PLAN" \
      | grep -v "^${LINE_NUM}:" \
      | sed -E 's/^[0-9]+:- \[([^]]*)\] //' \
      | grep -oE '^Task [0-9]+(\.[0-9]+)?' || true)"
    # Split DEP_TARGET on comma for multi-dep support (e.g., [Depends: 0.3, 0.4, 0.5])
    IFS=',' read -ra DEP_PARTS <<< "$DEP_TARGET"
    for DEP_PART in "${DEP_PARTS[@]}"; do
      DEP_PART="$(echo "$DEP_PART" | xargs)"  # trim whitespace
      [ -z "$DEP_PART" ] && continue
      # Match against each pending task identifier
      while IFS= read -r TASK_ID; do
        [ -z "$TASK_ID" ] && continue
        # Full form: "Task 0.3" matches identifier "Task 0.3"
        if [[ "$TASK_ID" == "$DEP_PART" ]]; then
          BLOCKED=true; BLOCKER_NOTE="Waiting on: $DEP_PART"; break 2
        fi
        # Short form: "0.3" matches the numeric part of "Task 0.3"
        TASK_NUM="${TASK_ID#Task }"
        if [[ "$TASK_NUM" == "$DEP_PART" ]]; then
          BLOCKED=true; BLOCKER_NOTE="Waiting on: $DEP_PART"; break 2
        fi
      done <<< "$PENDING_IDS"
    done
  fi
fi
```

---

## Test Plan

Each test creates a temporary PLAN.md fixture, runs `vidux-loop.sh` against it, and asserts on the JSON output. This matches the existing test pattern in `test_vidux_contracts.py`.

### Test 1: `[Depends: none]` does not block (Failure 3 fix)

**Fixture:**
```markdown
# Test Plan
## Tasks
- [pending] Task 1: Build feature X [Depends: none]
- [pending] Task 2: Build feature Y [Depends: none]
```

**Expected:** `blocked: false`, `action: "execute"` (or "gather_evidence" depending on evidence gate). The key assertion is that `blocked` is `false`.

**What it proves:** The "none" sentinel is short-circuited. Neither task blocks the other despite both containing the text "none".

### Test 2: Self-match on own `[Depends:]` text does not block (Failure 2 fix)

**Fixture:**
```markdown
# Test Plan
## Tasks
- [completed] Task 1: Setup infrastructure
- [pending] Task 2: Build widget [Depends: Task 1]
```

**Expected:** `blocked: false`. Task 1 is completed, so Task 2's dependency is satisfied. The old code would self-match because Task 2's own line contains "Task 1" inside `[Depends: Task 1]`.

**What it proves:** The current task line is excluded from the candidate set via `grep -v "^${LINE_NUM}:"`.

### Test 3: Numeric ID partial match safety (Failure 1 fix)

**Fixture:**
```markdown
# Test Plan
## Tasks
- [completed] Task 1.4: Build payment gateway
- [pending] Task 2: Scale factor to 2.4x [Depends: 1.4]
- [pending] Task 14: Unrelated infrastructure work
```

**Expected:** `blocked: false`. Task 1.4 is completed. Neither "Task 14" nor "Scale factor to 2.4x" should match the dep target "1.4".

**What it proves:** Exact identifier matching prevents "1.4" from substring-matching inside "14" or "2.4".

### Test 4: Legitimate blocking still works

**Fixture:**
```markdown
# Test Plan
## Tasks
- [pending] Task 1: Setup infrastructure
- [pending] Task 2: Build on infrastructure [Depends: 1]
```

**Expected:** `blocked: true`, `action: "blocked"`, `context` contains "Waiting on: 1".

**What it proves:** When the dependency is genuinely pending, the task is correctly blocked. The fix did not break the happy path.

### Test 5: Legitimate blocking with dotted ID

**Fixture:**
```markdown
# Test Plan
## Tasks
- [pending] Task 0.7: Review all designs [Depends: 0.3]
- [pending] Task 0.3: Design the dependency matcher
```

**Expected:** Task 0.7 is blocked because Task 0.3 is pending. `blocked: true`, `blocker_note` references "0.3".

Note: vidux-loop.sh picks the first pending task (Task 0.7) because it appears first. We need Task 0.7 to be the one evaluated, so it must come first in the file.

Actually, re-reading the script: line 76 picks the first pending task. Task 0.7 appears first, so it gets selected. Its dep "0.3" matches the pending "Task 0.3". Correct.

**What it proves:** Dotted numeric IDs are correctly matched in short form.

### Test 6: Multi-dep list with partial resolution

**Fixture:**
```markdown
# Test Plan
## Tasks
- [completed] Task 0.3: Design dep matcher
- [pending] Task 0.4: Design contradiction detection
- [pending] Task 0.7: Review all designs [Depends: 0.3, 0.4, 0.5, 0.6]
```

**Expected:** Task 0.4 is selected (first pending without complex deps). But if we want to test Task 0.7's multi-dep, we need it to be the first pending task. Revised fixture:

```markdown
# Test Plan
## Tasks
- [completed] Task 0.3: Design dep matcher
- [completed] Task 0.5: Design hygiene checks
- [completed] Task 0.6: Design D6 enforcement
- [pending] Task 0.7: Review all designs [Depends: 0.3, 0.4, 0.5, 0.6]
- [pending] Task 0.4: Design contradiction detection
```

**Expected:** Task 0.7 is selected (first pending). Its dep list is "0.3, 0.4, 0.5, 0.6". Tasks 0.3, 0.5, 0.6 are completed but 0.4 is pending. So Task 0.7 is blocked. `blocked: true`, blocker note references "0.4".

**What it proves:** Comma-separated dependency lists are correctly split and each part is checked independently. One unresolved dep is enough to block.

### Test 7: `[Depends: none]` case-insensitive variants

**Fixture:**
```markdown
# Test Plan
## Tasks
- [pending] Task 1: Build feature [Depends: None]
```

**Expected:** `blocked: false`.

**Additional fixture for "NONE":**
```markdown
# Test Plan
## Tasks
- [pending] Task 1: Build feature [Depends: NONE]
```

**Expected:** `blocked: false`.

**What it proves:** The `grep -qi '^none$'` handles case-insensitive matching of the sentinel.

### Test 8: DL-STUCK-TAG-BLIND fix — `[STUCK]` entries are parsed

**Fixture:**
```markdown
# Test Plan
## Decision Log
- [STUCK] [2026-04-05] Task stuck for 3+ cycles. Auto-blocked.
- [DIRECTION] [2026-04-05] Do not skip planning.
## Tasks
- [pending] Task 1: Build feature
```

**Expected:** `decision_log_count: 2`, `decision_log_warning: true`, `decision_log_entries` contains both "STUCK" and "DIRECTION".

**What it proves:** The parser now recognizes `[STUCK]` entries alongside the original three tag types.

### Test 9: Unstructured task descriptions (no "Task N:" prefix)

**Fixture:**
```markdown
# Test Plan
## Tasks
- [completed] Fix the login bug
- [pending] Add password reset [Depends: Fix the login bug]
```

**Expected:** `blocked: false`. The identifier extraction (`grep -oE '^Task [0-9]+(\.[0-9]+)?'`) finds no match for either task because they lack the `Task N:` prefix. The dep check silently skips.

**What it proves:** Plans without structured task IDs degrade gracefully. No false positives, no crashes. This is a known limitation documented in the backward compatibility section.

### Test 10: v1 checkbox format backward compatibility

**Fixture:**
```markdown
# Test Plan
## Tasks
- [x] Task 1: Setup infrastructure
- [ ] Task 2: Build widget [Depends: 1]
```

**Expected:** `blocked: false`. Task 1 is completed (v1 `[x]`). Task 2's dep "1" matches "Task 1" but Task 1 is not in the pending set (it is `[x]`, which the pending grep does not match).

**What it proves:** v1 checkbox format is still recognized. Completed v1 tasks are correctly excluded from the pending candidate set.

---

## Edge Cases Considered but Not Tested (Low Priority)

1. **Empty `[Depends: ]`:** DEP_TARGET is empty string. The `grep -qi '^none$'` does not match empty, so it falls through to the ID extraction. `IFS=',' read` on empty string produces one empty part, which is skipped by `[ -z "$DEP_PART" ]`. Result: not blocked. Correct behavior.

2. **`[Depends: Task 1, none]`:** Mixed sentinel and real dep. "Task 1" is checked; "none" (after trim) would also be checked as a dep. If no pending task ID matches "none" (and why would one), it produces no match. The short-circuit only fires when the entire DEP_TARGET is "none". This is acceptable: `[Depends: Task 1, none]` is a malformed annotation and the matcher's job is not to validate annotation grammar.

3. **Multiple `[Depends:]` annotations in one task:** The `grep -o` extracts only the first match. If a task has `[Depends: A] [Depends: B]`, only "A" is checked. This is a pre-existing limitation. Not in scope for this fix.

4. **`[blocked]` tasks in the pending set:** The grep pattern `(pending|in_progress)` excludes `[blocked]` tasks, so they never appear in PENDING_IDS. A blocked dependency does not unblock the current task — but it also does not count as a pending blocker. This is correct: a blocked task is not actively preventing progress, it is waiting on its own blockers.

---

## Implementation Checklist

1. Apply Fix 1 (DL-STUCK-TAG-BLIND) — one-line regex change on line 59
2. Apply Fix 2 (DEP-MATCHER-TRIPLE) — replace lines 116-127
3. Run existing contract tests: `python3 -m unittest discover -s skills/vidux/tests -p 'test_*.py' -q` — all 63 must pass
4. Add new tests (Tests 1-10 above) to `test_vidux_contracts.py`
5. Run full suite again — 63 + 10 = 73 must pass
6. Manual smoke test: run `vidux-loop.sh` against `vidux-v230/PLAN.md` and verify Task 0.3 is not falsely blocked
