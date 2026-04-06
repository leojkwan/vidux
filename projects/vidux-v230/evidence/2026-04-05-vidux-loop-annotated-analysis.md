# Task 0.2: Annotated Analysis of vidux-loop.sh (Lines 115-200)

**Date:** 2026-04-05
**Goal:** Map every code path in the dependency matching, Q-gating, action decision, and stuck-loop detection sections. Document what each path does, known bugs from endurance testing, and fix candidates.

## Sources

- [Source: `skills/vidux/scripts/vidux-loop.sh`] The script under analysis (242 lines, v2.2.0).
- [Source: `evidence/2026-04-05-two-machine-convergence.md`] Two-machine convergence table for bug cross-referencing.
- [Source: `projects/vidux-endurance/evidence/2026-04-05-final-endurance-scorecard.md`] Aggregate endurance findings and v2.3.0 priority recommendations.
- [Source: `projects/vidux-endurance/evidence/2026-04-05-q-gating-mechanical-test.md`] Q-gating test with `[Depends: none]` false-positive discovery.
- [Source: `projects/vidux-endurance/evidence/2026-04-05-stuck-loop-mechanical-test.md`] Stuck-loop mechanical verification (4/4 checks green, plus `hot_tasks` ordering note).
- [Source: `projects/vidux-endurance/evidence/2026-04-05-decision-log-contradiction-test.md`] Decision Log surfacing test and contradiction gap.
- [Source: other-computer stuck-loop precheck] `/Users/leokwan/Desktop/vidux-endurance/evidence/2026-04-05-live-radar-and-stuck-loop-precheck.md` -- text-fragility finding on first-40-char match.

---

## Section 1: HOT_TASKS Computation (Line 42)

### Code

```bash
# Line 42
HOT_TASKS="$(grep -cE '^\- (\[ \]|\[(pending|in_progress)\]) ' "$PLAN" || true)"
```

### What it does

Counts all pending and in_progress tasks. This count is emitted in the JSON output so consumers know the task landscape.

### Bug: Pre-mutation ordering

**Bug ID:** HOT-TASKS-ORDERING
**Convergence:** PARTIAL (this-computer only)
**Evidence:** `stuck-loop-mechanical-test.md` finding #4: "The `hot_tasks` count is 2 (not 1). This is because `hot_tasks` is computed at the top of the script *before* the stuck-loop enforcement mutates the file."

The stuck-loop enforcement at line 177 can flip `[in_progress]` to `[blocked]`, which reduces the hot task count by 1. But `HOT_TASKS` was already computed at line 42. The JSON output reports a stale count.

**Impact:** Low. An LLM consumer reading `hot_tasks: 2` when one task was just auto-blocked may misjudge the task landscape. The `auto_blocked: true` field partially compensates, but requires the consumer to mentally adjust.

### Fix candidate

Move `HOT_TASKS` computation to after the stuck-loop section (after line 201), or re-compute it at JSON output time. Minimal risk; the variable is read-only after line 42 and only consumed in the final output block.

---

## Section 2: Decision Log Parsing (Lines 56-64)

### Code

```bash
# Lines 56-64
DL_COUNT=0; DL_ENTRIES=""; DL_WARNING=false
if grep -q '^## Decision Log' "$PLAN" 2>/dev/null; then
  DL_BLOCK="$(awk '/^## Decision Log/{found=1; next} found && /^## /{found=0} found{print}' "$PLAN")"
  DL_ENTRIES="$(printf '%s' "$DL_BLOCK" | grep -E '^\- \[(DELETION|RATE-LIMIT|DIRECTION)\]' || true)"
  if [ -n "$DL_ENTRIES" ]; then
    DL_COUNT="$(printf '%s\n' "$DL_ENTRIES" | grep -c '.' || true)"
    DL_WARNING=true
  fi
fi
```

### What it does

1. Uses `awk` to extract the `## Decision Log` section (everything between that heading and the next `##` heading).
2. Filters for tagged entries: `[DELETION]`, `[RATE-LIMIT]`, `[DIRECTION]`.
3. Sets `DL_WARNING=true` and a count if any tagged entries exist.
4. The entries and warning are passed through to the JSON output for the LLM consumer.

### Bug: Warning-only, no mechanical contradiction detection

**Bug ID:** DL-NO-CONTRADICTION
**Convergence:** STRONG (both machines)
**Evidence:** `decision-log-contradiction-test.md` finding #2: "Contradicting tasks are NOT mechanically blocked (by design)." Task 2 ("Re-add --verbose flag") directly contradicted a `[DELETION]` entry but got `action: "execute"` anyway.

The script surfaces entries so the LLM "cannot claim ignorance," but there is zero mechanical block on contradicting a logged direction. Under high context load, an LLM may miss a contradiction.

### Also missing: `[STUCK]` tag parsing

The stuck-loop enforcement at line 181 writes `[STUCK]` entries to the Decision Log. But the parsing at line 59 only matches `DELETION|RATE-LIMIT|DIRECTION`. A `[STUCK]` entry will not appear in `DL_ENTRIES` or increment `DL_COUNT`. This means:

- A stuck-loop auto-block creates a Decision Log entry that the script itself cannot read back.
- The `[STUCK]` entry is visible to a human reading PLAN.md but invisible to the script's own output JSON on subsequent cycles.

This is a latent inconsistency, not a crash bug, but it means the script's Decision Log awareness has a blind spot to its own mutations.

### Fix candidates

1. **Minimal (v2.3.0):** Add `STUCK` to the grep pattern on line 59: `'^\- \[(DELETION|RATE-LIMIT|DIRECTION|STUCK)\]'`. This closes the self-awareness gap.
2. **Medium (v2.3.0):** Implement keyword-overlap contradiction detection. For each pending task, check if its description contains keywords from any `[DELETION]` entry. If overlap exceeds a threshold, set a `contradiction_warning` field in the JSON. This is feasible in bash with `comm` or word-intersection logic. Task 0.4 will design this.
3. **Heavy (deferred):** Semantic similarity scoring. Requires Python. Overkill for a bash script.

---

## Section 3: Dependency Matching (Lines 119-127)

### Code

```bash
# Lines 119-127
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

### What it does

1. Extracts the `[Depends: X]` annotation from the current task description.
2. Strips brackets to get the raw dependency target string (e.g., "0.1", "Task A", "none").
3. Greps all non-completed task lines for the dependency target string (case-insensitive).
4. If any non-completed task line contains the target string, the current task is marked `blocked`.

### Bug: Triple-failure dependency matcher (THE P0 bug)

**Bug ID:** DEP-MATCHER-TRIPLE
**Convergence:** STRONG (both machines independently discovered the same root cause)
**Evidence:** `final-endurance-scorecard.md` Bug #1, `q-gating-mechanical-test.md` Surprise Finding, `decision-log-contradiction-test.md` finding #3.

Line 124 runs `grep -qi "$DEP_TARGET"` against the full text of every non-completed task line. This produces three distinct failure modes:

#### Failure 1: Self-match on completed dependency IDs

A task with `[Depends: 2.4]` will match against any pending task whose full text contains "2.4" -- including tasks like "Task 2.4: Do something" that is the dependency itself. But the grep also matches tasks that merely contain "2.4" anywhere in their text (e.g., "Scale factor to 2.4x").

Worse, the grep runs against non-completed tasks, so if Task 2.4 is still pending, the dependency is correctly detected as unresolved. But if a DIFFERENT task happens to contain "2.4" in its text, it creates a false positive.

#### Failure 2: Self-match on own `[Depends:]` text

Consider two pending tasks:
```
- [pending] Task A: Build widget [Depends: Task B]
- [pending] Task B: Design widget
```

Task A's `DEP_TARGET` is "Task B". The grep searches all non-completed lines including Task A's own line. Task A's own line contains "Task B" (inside the `[Depends: Task B]` annotation). If Task B is completed but Task A's text still says `[Depends: Task B]`, the grep matches Task A's own annotation text against itself.

This failure mode requires the dep target text to appear in the current task's own line, which always happens because the `[Depends: X]` annotation literally contains the target.

**Critical detail:** The grep on line 124 pipes ALL non-completed task lines into `grep -qi "$DEP_TARGET"`. This includes the current task's own line (if it is pending/in_progress). So the current task's `[Depends: X]` annotation will always self-match, because the text "X" appears in its own line. This means: **any task with a `[Depends:]` annotation will always be marked blocked, even if the dependency is completed**, as long as the current task itself is still pending/in_progress.

Wait -- re-reading the grep chain: line 124 greps for pending/in_progress tasks, then searches those for `DEP_TARGET`. If the current task is the one being evaluated, and it is pending/in_progress, then yes -- it is in the first grep's output. And its own line contains `DEP_TARGET` inside the `[Depends: DEP_TARGET]` text. So it self-matches.

The only reason this does not cause 100% false-blocking in practice is that tasks with a dependency that IS completed would have been manually resolved by the LLM (removing the `[Depends:]` annotation or completing the task). But the mechanical check is broken for the general case.

#### Failure 3: `[Depends: none]` matches "none" in peer tasks

When `DEP_TARGET` is "none" (from `[Depends: none]`), the case-insensitive grep matches the literal string "none" in any other pending task that also has `[Depends: none]`. With 2+ pending tasks using this annotation, they all false-positive block each other.

**Evidence from Q-gating test:**
```json
{
  "task": "Task A: Implement feature X [Evidence: test] [Depends: none]",
  "blocked": true,
  "action": "blocked",
  "context": "Waiting on: none"
}
```

### Fix candidates (ranked)

1. **Short-circuit `[Depends: none]`:** Immediate, zero-risk fix. Add before line 124:
   ```bash
   if [[ "${DEP_TARGET,,}" == "none" ]]; then
     : # no dependency, skip check
   else
     # existing grep logic
   fi
   ```
   This fixes Failure 3 only. Fast to ship but does not address Failures 1 and 2.

2. **Exclude the current task line from the grep:** Add `grep -v` to filter out the current task line number. This fixes Failure 2 (self-match) but not Failure 1 (partial text match) or Failure 3.
   ```bash
   if sed -n "${LINE_NUM}d" <(grep -nE '^\- (\[ \]|\[(pending|in_progress)\]) ' "$PLAN") | grep -qi "$DEP_TARGET"; then
   ```
   Fragile; line numbers can shift.

3. **Match against task identifiers only (RECOMMENDED):** Extract structured task IDs (e.g., "0.1", "Task A") from the task list and match `DEP_TARGET` against those identifiers, not against full task line text. This fixes all three failure modes. Requires a convention for task IDs (the v2.3.0 plan already uses "Task N.N:" format consistently).

   Design sketch:
   ```bash
   # Extract task IDs from non-completed task lines
   # Convention: "Task N.N:" at start of description after FSM prefix
   PENDING_IDS="$(grep -E '^\- (\[ \]|\[(pending|in_progress)\]) ' "$PLAN" \
     | sed -E 's/^- \[([^]]*)\] //' \
     | grep -oE '^Task [0-9]+\.[0-9]+' || true)"
   # Check if DEP_TARGET matches any pending task ID
   if echo "$PENDING_IDS" | grep -qiF "$DEP_TARGET"; then
     BLOCKED=true
   fi
   ```
   Task 0.3 will produce the final design for this approach.

4. **Hybrid: short-circuit + ID matching:** Combine fixes 1 and 3. Short-circuit "none" immediately (handles the common LLM placeholder), then do ID-based matching for real dependencies. This is the approach the v2.3.0 plan Decision Log directs: "Fix dependency matcher by extracting task IDs into a separate matching step, not by patching the grep."

---

## Section 4: Q-Gating (Lines 129-142)

### Code

```bash
# Lines 129-142
TASK_OPEN_QS=0; TASK_OPEN_REFS=""
Q_REFS_IN_TASK="$(echo "$TASK_DESC" | grep -oE 'Q[0-9]+' | sort -u || true)"
if [ -n "$Q_REFS_IN_TASK" ]; then
  while IFS= read -r QREF; do
    [ -z "$QREF" ] && continue
    # Question is open if it appears as "- [ ] Qn:" in the plan
    if grep -qE "^\- \[ \] ${QREF}[: ]" "$PLAN" 2>/dev/null; then
      TASK_OPEN_QS=$((TASK_OPEN_QS + 1))
      TASK_OPEN_REFS="${TASK_OPEN_REFS:+$TASK_OPEN_REFS, }$QREF"
    fi
  done <<< "$Q_REFS_IN_TASK"
fi
```

### What it does

1. Extracts all `Q[0-9]+` references from the current task description (e.g., "Q1", "Q3").
2. For each Q-ref, checks if a matching `- [ ] Qn:` line exists in the plan's Open Questions section.
3. Counts how many of the task's Q-refs are still unresolved.
4. If any are unresolved and the task type is "code", the action decision (line 150) switches to "refine" instead of "execute".

This implements LOOP.md:39 doctrine: "no items blocking the NEXT task specifically." A question is only a blocker if the current task explicitly references it.

### Assessment: No bugs found. Well-designed.

**Convergence:** STRONG (both machines confirmed Q-gating works correctly)
**Evidence:** `q-gating-mechanical-test.md` Scenarios 1 and 2 both passed. Task A (no Q-refs) got `action: "execute"` even with Q1 unresolved. Task B (refs Q1) correctly got `action: "refine"`.

**Edge case note:** The Q-ref regex `Q[0-9]+` will match "Q1" inside words like "QA" only if followed by a digit. It will NOT match "QA" (no digit after Q). It WILL match "Q10" but also "Q1" inside "Q10" -- however, `sort -u` deduplicates. The grep on line 137 anchors to `- [ ] Q1[: ]` which prevents partial matching (Q1 won't match Q10's open question line because "Q10" does not match the pattern `Q1[: ]`).

The one theoretical gap: if a task description contains "Q1" as part of a non-question reference (e.g., "fiscal Q1 report"), it would be treated as a Q-ref. In practice, Vidux plans use "Q1" exclusively for Open Questions, so this is not a real concern.

### Fix candidate

None needed for v2.3.0. This section is sound.

---

## Section 5: Action Decision (Lines 144-154)

### Code

```bash
# Lines 144-154
ACTION="execute"; CONTEXT="Ready to execute"
if [ "$IS_RESUMING" = true ]; then
  ACTION="execute"; CONTEXT="Resuming in_progress task"
elif [ "$BLOCKED" = true ]; then
  ACTION="blocked"; CONTEXT="$(json_escape "$BLOCKER_NOTE")"
elif [ "$TASK_OPEN_QS" -gt 0 ] && [ "$TYPE" = "code" ]; then
  ACTION="refine"; CONTEXT="$TASK_OPEN_QS task-linked open question(s) (${TASK_OPEN_REFS}); resolve before executing"
elif [ "$HAS_EVIDENCE" = false ] && [ "$TYPE" = "code" ]; then
  ACTION="gather_evidence"; CONTEXT="Task lacks evidence; gather before executing"
fi
```

### What it does

Cascading priority decision:

1. **Resume** (highest): If the task is `[in_progress]` from a prior session, execute immediately. This overrides all other gates -- the assumption is that a task already in progress has passed all gates in a previous cycle.
2. **Blocked**: If the dependency matcher flagged the task, block it.
3. **Q-gate**: If the task references unresolved Open Questions and is a "code" type task, redirect to "refine" (resolve questions first).
4. **Evidence gate**: If the task has no evidence marker and is a "code" type task, redirect to "gather_evidence".
5. **Default**: Execute.

### Design note: Resume overrides stuck-loop

The resume check at line 146 takes priority over all gates. But the stuck-loop detection at lines 156-201 runs AFTER this decision block and can override the action to "stuck" or "auto_blocked". This means the decision cascade is actually:

```
action_decision (lines 144-154) -> stuck_override (lines 156-201) -> final output
```

The stuck-loop check is a post-decision override, not part of the cascade. This is correct: stuck detection needs to fire even on resumed tasks (especially on resumed tasks -- they are the ones most likely to be stuck).

### Bug: `blocked` vs `auto_blocked` have no unified contract

**Bug ID:** BLOCKED-DUAL-FIELD
**Convergence:** PARTIAL (this-computer only)
**Evidence:** `final-endurance-scorecard.md` Bug #3, `stuck-loop-mechanical-test.md` finding #3.

The `blocked` field in the JSON output only reflects dependency-based blocking (line 148). The stuck-loop sets `auto_blocked` (line 177) and overrides `ACTION` to "auto_blocked" (line 196). But `blocked` remains `false`.

An LLM consumer must check both fields to understand the full picture:
```json
{
  "blocked": false,      // <-- dependency blocker? no
  "auto_blocked": true,  // <-- stuck-loop blocker? yes
  "action": "auto_blocked"
}
```

This is confusing. A consumer checking only `blocked` will miss stuck-loop blocks.

### Fix candidates

1. **Unify into one field:** Replace both `blocked` and `auto_blocked` with a single `blocked` boolean and a `blocked_reason` string: `"dependency"`, `"stuck_loop"`, or `null`.
2. **Document the contract:** Add explicit documentation in SKILL.md stating that consumers must check both fields. Lower effort but does not fix the API confusion.
3. **Add a compound field:** Add `any_blocked: true` as a convenience field that is the OR of `blocked` and `auto_blocked`. Backward-compatible.

---

## Section 6: Stuck-Loop Detection (Lines 156-201)

### Code

```bash
# Lines 156-201
STUCK=false; STUCK_HITS=0; AUTO_BLOCKED=false
TASK_SHORT="$(echo "$TASK_DESC" | cut -c1-40)"                            # <-- LINE 160
if grep -q '^## Progress' "$PLAN" 2>/dev/null; then
  PROG_BLOCK="$(awk '/^## Progress/{found=1; next} found && /^## /{found=0} found{print}' "$PLAN")"
  STUCK_HITS="$(printf '%s\n' "$PROG_BLOCK" | grep -cF "$TASK_SHORT" 2>/dev/null || true)"  # <-- LINE 163
  if [ "$STUCK_HITS" -ge 3 ]; then
    STUCK=true; ACTION="stuck"
    CONTEXT="Task in $STUCK_HITS Progress entries without completing; possible stuck loop"

    # --- mechanical enforcement: auto-block after 3+ cycles on same task ---
    if [ "$IS_RESUMING" = true ] && [ -n "$LINE_NUM" ]; then              # <-- LINE 170
      TODAY="$(date +%Y-%m-%d)"
      LAST_PROG="$(printf '%s\n' "$PROG_BLOCK" | grep -F "$TASK_SHORT" | tail -1 || true)"
      LAST_PROG_ESCAPED="$(json_escape "${LAST_PROG:-no progress entry found}")"

      # Flip [in_progress] -> [blocked] on the task line
      sedi -E "${LINE_NUM}s/^- \[in_progress\] /- [blocked] /" "$PLAN" 2>/dev/null && AUTO_BLOCKED=true || true  # <-- LINE 177

      if [ "$AUTO_BLOCKED" = true ]; then
        # Append to Decision Log (create section if missing)
        DL_ENTRY="- [STUCK] [$TODAY] Task stuck for ${STUCK_HITS}+ cycles. Auto-blocked. Reason: ${LAST_PROG_ESCAPED}"
        if grep -q '^## Decision Log' "$PLAN" 2>/dev/null; then
          sedi "/^## Decision Log/a\\
$DL_ENTRY" "$PLAN"                                                        # <-- LINE 183-184
        else
          if grep -q '^## Tasks' "$PLAN" 2>/dev/null; then
            sedi "/^## Tasks/i\\
## Decision Log\\
$DL_ENTRY\\
" "$PLAN"                                                                  # <-- LINE 188-191
          else
            printf '\n## Decision Log\n%s\n' "$DL_ENTRY" >> "$PLAN"
          fi
        fi
        ACTION="auto_blocked"
        CONTEXT="Task stuck for ${STUCK_HITS}+ cycles. Auto-blocked in PLAN.md. Human must unblock."
      fi
    fi
  fi
fi
```

### What it does

1. **Line 160:** Takes the first 40 characters of the task description as a fingerprint (`TASK_SHORT`).
2. **Line 162:** Extracts the `## Progress` section using `awk`.
3. **Line 163:** Counts how many Progress lines contain `TASK_SHORT` (fixed-string match, `grep -cF`).
4. **Lines 164-166:** If 3+ matches, set `stuck=true` and override action to "stuck".
5. **Lines 170-198:** Mechanical enforcement (only for `[in_progress]` tasks):
   - Flip the task from `[in_progress]` to `[blocked]` in the plan file.
   - Write a `[STUCK]` entry to the Decision Log with the date and the last Progress line as the reason.
   - Override action to "auto_blocked".

### Bug: First-40-character fingerprint is text-fragile

**Bug ID:** STUCK-TEXT-FRAGILE
**Convergence:** STRONG (complementary findings -- this-computer proved it works when text matches; other-computer proved it fails when text is paraphrased)
**Evidence:** Other-computer finding: "first-40-char match, paraphrased Progress lines miss."

The stuck-loop detector uses a 40-character prefix of the task description as the matching key. This works when Progress lines reproduce the task description verbatim (as the checkpoint script does). It fails when:

1. **LLM paraphrases the task in Progress entries.** An LLM writing "Working on the payment gateway integration" instead of "Working on Integrate payment gateway with Stripe API..." will not match the 40-char prefix of the task description.
2. **Task descriptions are short.** A task "Fix bug" has only 7 characters. `cut -c1-40` returns "Fix bug". Any Progress entry containing "Fix bug" matches -- including entries about different bugs. False positives.
3. **Task descriptions are reworded after starting.** If a human edits the task description mid-cycle, the fingerprint changes and prior Progress entries no longer match. The stuck counter resets to zero.

The 40-character cutoff is arbitrary. It was presumably chosen to avoid matching too broadly (full description matching would catch irrelevant substrings in long task descriptions). But it creates a brittleness window where the matching is neither precise (ID-based) nor fuzzy (semantic).

### Bug: `hot_tasks` computed before stuck-loop mutation (repeat of Section 1)

Line 177 flips `[in_progress]` to `[blocked]`, reducing the actual hot task count. But `HOT_TASKS` was computed at line 42. See Section 1 above.

### Bug: Auto-block only fires for `[in_progress]` tasks

Line 170 gates auto-blocking on `IS_RESUMING=true`. A `[pending]` task stuck in a loop (repeatedly selected but never transitioned to `[in_progress]`) will get `action: "stuck"` but will NOT be auto-blocked. The task stays `[pending]` and will be selected again next cycle -- the exact loop the enforcement is supposed to break.

This is probably intentional (a pending task has never been started, so "stuck" is less meaningful). But the Progress block could still accumulate entries for a pending task if the LLM logs progress without transitioning to `[in_progress]`. In that case, the stuck detector fires but the enforcement does not, creating a "soft stuck" state where the script reports stuck but cannot break the loop.

### Bug: `[STUCK]` tag not parsed by Decision Log reader

As noted in Section 2, line 181 writes `[STUCK]` entries but line 59 only parses `DELETION|RATE-LIMIT|DIRECTION`. The script's own stuck entries are invisible to its Decision Log awareness.

### Fix candidates (ranked)

1. **Use a structured task ID instead of 40-char text prefix (RECOMMENDED).** If tasks follow a `Task N.N:` convention, extract the ID and match Progress entries against it. This is immune to paraphrasing and description edits.
   ```bash
   TASK_ID="$(echo "$TASK_DESC" | grep -oE '^Task [0-9]+\.[0-9]+' || true)"
   if [ -n "$TASK_ID" ]; then
     STUCK_HITS="$(printf '%s\n' "$PROG_BLOCK" | grep -cF "$TASK_ID" || true)"
   else
     # Fallback to current 40-char matching for unstructured plans
     TASK_SHORT="$(echo "$TASK_DESC" | cut -c1-40)"
     STUCK_HITS="$(printf '%s\n' "$PROG_BLOCK" | grep -cF "$TASK_SHORT" || true)"
   fi
   ```

2. **Increase fingerprint length to 80 characters.** Reduces false positives from short descriptions. Does NOT fix the paraphrasing problem. Cheap fix with limited value.

3. **Move `HOT_TASKS` computation to post-mutation.** See Section 1.

4. **Add `STUCK` to the Decision Log parser pattern.** One-line fix on line 59.

5. **Consider auto-blocking `[pending]` tasks too (deferred).** Needs design thought -- a pending task stuck in Progress could be a planning issue, not a code issue. May warrant a different action (e.g., "stuck_pending" with a recommendation to re-scope).

---

## Section 7: Cross-Cutting Concern -- `blocked` vs `auto_blocked` Field Contract

### The two blocking mechanisms

| Mechanism | Set by | JSON field | When |
|-----------|--------|-----------|------|
| Dependency blocking | Lines 119-127 | `blocked: true` | Task has `[Depends: X]` and X is non-completed |
| Stuck-loop auto-blocking | Lines 177, 196 | `auto_blocked: true` | Task appears in 3+ Progress entries, is `[in_progress]` |

### The problem

These two mechanisms use different JSON fields with no unified interface. A consumer checking `if result.blocked` will miss stuck-loop blocks. A consumer checking `if result.auto_blocked` will miss dependency blocks. There is no single field that answers "should this task be skipped?"

The `action` field partially compensates: it will be "blocked" for dependency blocks and "auto_blocked" for stuck-loop blocks. But there is no guaranteed exhaustive check -- a consumer would need to check `action in ("blocked", "auto_blocked", "stuck")`.

### Fix candidates

See Section 5 above.

---

## Fix Candidates Ranked by Impact

| Rank | Fix | Lines | Bug IDs | Impact | Risk | Effort |
|------|-----|-------|---------|--------|------|--------|
| **1** | Fix dependency matcher: short-circuit `[Depends: none]` + match against task IDs instead of full text | 119-127 | DEP-MATCHER-TRIPLE | **HIGH** -- eliminates all 3 failure modes of the only P0 bug | Medium (needs task ID convention) | Medium |
| **2** | Use structured task ID for stuck-loop fingerprint instead of `cut -c1-40` | 160, 163 | STUCK-TEXT-FRAGILE | **HIGH** -- eliminates paraphrasing and short-description failures in stuck detection | Low (fallback to current behavior for unstructured plans) | Low-Medium |
| **3** | Move `HOT_TASKS` computation to after stuck-loop enforcement | 42 | HOT-TASKS-ORDERING | **LOW-MEDIUM** -- JSON output reflects actual post-mutation state | Very Low | Very Low |
| **4** | Add `STUCK` to Decision Log parser grep pattern | 59 | DL-STUCK-TAG-BLIND | **LOW-MEDIUM** -- script becomes self-aware of its own stuck entries | Very Low | Very Low (one-line change) |
| **5** | Unify `blocked` / `auto_blocked` into single field with reason enum | 119-127, 177, 196, 219-241 | BLOCKED-DUAL-FIELD | **MEDIUM** -- cleaner consumer API | Medium (backward-compat concern) | Medium |
| **6** | Add mechanical contradiction detection for Decision Log | 56-64 | DL-NO-CONTRADICTION | **MEDIUM** -- closes LLM-judgment-only gap | Medium (keyword overlap approach needs design) | Medium-High |
| **7** | Auto-block `[pending]` tasks stuck in Progress | 170 | (new) | **LOW** -- edge case, pending-stuck is usually a planning issue | Medium (needs new action type) | Low |

### Recommended implementation order for v2.3.0

**Phase 1 (P0):** Fix 1 (dependency matcher) -- this is the only bug causing incorrect task blocking in real plans.

**Phase 2 (P1):** Fixes 2, 3, 4 -- all low-risk improvements to stuck-loop accuracy and JSON output fidelity.

**Phase 3 (P1):** Fixes 5, 6 -- API unification and contradiction detection require more design work (Tasks 0.4, 0.5).

**Deferred:** Fix 7 -- needs real-world data on how often pending-stuck occurs.
