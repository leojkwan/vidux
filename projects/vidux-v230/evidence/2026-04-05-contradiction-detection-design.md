# Task 0.4: Mechanical Contradiction Detection Design

**Date:** 2026-04-05
**Goal:** Design a bash-implementable contradiction detection mechanism for the Decision Log in vidux-loop.sh. The detector must flag when a pending task's description overlaps with a `[DELETION]` or `[DIRECTION]` entry, adding a warning to the JSON output without blocking execution (v2.3.0 calibration phase).

## Sources

- [Source: `vidux-loop.sh` lines 56-64] Current Decision Log parsing -- surfaces entries, sets `decision_log_warning`, but performs zero contradiction checking.
- [Source: `evidence/2026-04-05-vidux-loop-annotated-analysis.md` Section 2] Annotated analysis confirming Bug ID DL-NO-CONTRADICTION. "The script surfaces entries so the LLM 'cannot claim ignorance,' but there is zero mechanical block on contradicting a logged direction."
- [Source: `evidence/2026-04-05-two-machine-convergence.md` Bug #3] STRONG convergence: both machines independently confirmed contradiction detection is warning-only with no mechanical check.
- [Source: `vidux-endurance/evidence/2026-04-05-decision-log-contradiction-test.md`] Synthetic test proving Task 2 ("Re-add --verbose flag") got `action: "execute"` despite directly contradicting `[DELETION] Removed legacy --verbose flag... Do not re-add.`
- [Source: `SKILL.md` lines 476-479] Decision Log format contract: `[DELETION]`, `[RATE-LIMIT]`, `[DIRECTION]` entries with date and free-text description.
- [Source: `test_vidux_contracts.py` lines 514-582] Existing contract tests for `decision_log_count`, `decision_log_warning`, `decision_log_entries` fields.

---

## The Gap

vidux-loop.sh line 59 parses Decision Log entries:

```bash
DL_ENTRIES="$(printf '%s' "$DL_BLOCK" | grep -E '^\- \[(DELETION|RATE-LIMIT|DIRECTION)\]' || true)"
```

These entries are emitted as raw text in the JSON output. The consuming LLM is expected to read them and exercise judgment about contradictions. Under high context load or long sessions, this judgment fails silently -- the LLM misses a `[DELETION]` entry and re-introduces the deleted feature.

The contradiction test proved this concretely: a task explicitly named "Re-add --verbose flag" passed through as `action: "execute"` with a `[DELETION]` entry reading "Removed legacy --verbose flag... Do not re-add" sitting right there in the JSON.

---

## Three Approaches Evaluated

### Approach A: Keyword Overlap

**Mechanism:** Extract significant words from each `[DELETION]`/`[DIRECTION]` entry's description. Extract significant words from the pending task description. Compute the intersection. If the overlap exceeds a threshold, flag a contradiction warning.

**Shell logic:**

```bash
# --- contradiction detection ------------------------------------------------ #
CONTRADICTION_WARNING=false; CONTRADICTION_MATCHES=""

# Stop words to exclude from matching (common English + Vidux structural words)
STOP_WORDS="the a an is are was were be been being have has had do does did
will would shall should may might can could must need dare ought to of in for
on at by with from as into through during before after above below between
about against this that these those it its they them their we our you your
not no nor and but or if then else when where which what who whom how all
each every both few more most other some such any only own same than too
very just because so task removed reason do added chose over unless evidence
changes date limited per day action do not"

# Function: extract significant words from a string (lowercase, deduplicated)
extract_keywords() {
  local text="$1"
  # Lowercase, strip punctuation, split on whitespace, remove stop words
  printf '%s' "$text" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]-' '\n' \
    | sort -u | while IFS= read -r word; do
      [ ${#word} -lt 3 ] && continue  # skip 1-2 char words
      echo "$STOP_WORDS" | grep -qw "$word" && continue
      printf '%s\n' "$word"
    done
}

if [ "$DL_WARNING" = true ] && [ -n "$TASK_DESC" ]; then
  # Extract keywords from the current task
  TASK_KEYWORDS="$(extract_keywords "$TASK_DESC")"

  # Check each DL entry for keyword overlap
  while IFS= read -r DL_LINE; do
    [ -z "$DL_LINE" ] && continue
    # Extract the tag type
    DL_TAG="$(printf '%s' "$DL_LINE" | grep -oE '\[(DELETION|DIRECTION)\]' || true)"
    [ -z "$DL_TAG" ] && continue  # skip RATE-LIMIT (not subject-based)

    DL_KEYWORDS="$(extract_keywords "$DL_LINE")"

    # Compute intersection using comm on sorted word lists
    OVERLAP="$(comm -12 \
      <(printf '%s\n' "$TASK_KEYWORDS" | sort) \
      <(printf '%s\n' "$DL_KEYWORDS" | sort) 2>/dev/null || true)"

    OVERLAP_COUNT=0
    if [ -n "$OVERLAP" ]; then
      OVERLAP_COUNT="$(printf '%s\n' "$OVERLAP" | grep -c '.' || true)"
    fi

    # Threshold: 2+ keyword overlap = warning
    if [ "$OVERLAP_COUNT" -ge 2 ]; then
      CONTRADICTION_WARNING=true
      OVERLAP_WORDS="$(printf '%s\n' "$OVERLAP" | tr '\n' ',' | sed 's/,$//')"
      MATCH_ENTRY="$DL_TAG overlaps on: $OVERLAP_WORDS"
      CONTRADICTION_MATCHES="${CONTRADICTION_MATCHES:+$CONTRADICTION_MATCHES; }$MATCH_ENTRY"
    fi
  done <<< "$DL_ENTRIES"
fi
```

**False positive risk:** MEDIUM. Common domain words will match across unrelated entries. A `[DELETION] Removed the payment retry logic` and a task "Add payment webhook handler" share "payment" -- one keyword overlap, below the threshold=2 minimum. But "Add payment retry handler" shares "payment" + "retry" = flagged. That is arguably correct (re-introducing retry logic near a deletion of retry logic warrants a glance), but it is not a true semantic contradiction.

**False negative risk:** LOW-MEDIUM for `[DELETION]` entries (the subject is usually named explicitly). MEDIUM-HIGH for `[DIRECTION]` entries (which often describe architectural choices with abstract language that may not overlap with task keywords).

**Backward compat:** No breakage. Adds new JSON fields, does not modify any existing fields or PLAN.md format.

**Works alongside existing output:** Yes. Adds `contradiction_warning` and `contradiction_matches` fields to the JSON. Existing `decision_log_*` fields are untouched.

**Bash feasibility:** Yes. `comm`, `sort`, `tr`, `grep` are POSIX. The `extract_keywords` function is the heaviest part but runs in milliseconds on typical Decision Log sizes (1-10 entries, each under 200 chars). Process substitution (`<(...)`) works in bash but not POSIX sh -- acceptable since the script already uses `[[ ]]` bashisms.

---

### Approach B: Explicit Tags

**Mechanism:** Require tasks to declare `[Contradicts: DL-N]` when they knowingly override a Decision Log entry. The script checks for the tag's presence. If a task has no `[Contradicts:]` tag, no contradiction is flagged -- detection is opt-in by the task author.

**Shell logic:**

```bash
# --- contradiction detection (tag-based) ----------------------------------- #
CONTRADICTION_WARNING=false; CONTRADICTION_MATCHES=""
CONTRADICTS_TAG="$(echo "$TASK_DESC" | grep -oE '\[Contradicts: [^]]+\]' || true)"
if [ -n "$CONTRADICTS_TAG" ]; then
  CONTRADICTION_WARNING=true
  CONTRADICTION_MATCHES="$(json_escape "$CONTRADICTS_TAG")"
fi
```

**False positive risk:** ZERO. Only fires when the task author explicitly declares a contradiction.

**False negative risk:** VERY HIGH. This is the fatal problem. The entire point of mechanical contradiction detection is to catch cases where the LLM (or human) does NOT realize they are contradicting a Decision Log entry. An opt-in tag requires the author to already know the contradiction exists -- which is the exact awareness gap this feature is supposed to fill. Under high context load, the LLM will not add the tag because it does not realize the contradiction.

**Backward compat:** Adds a new annotation format (`[Contradicts:]`) to the PLAN.md vocabulary. Existing plans without the tag work fine (no false positives). But new plans must adopt the convention for the feature to have any value.

**Works alongside existing output:** Yes, trivially.

**Bash feasibility:** Trivial. One grep.

**Verdict:** Approach B solves the wrong problem. It catches deliberate overrides (which are fine -- the author knows what they are doing). It misses accidental contradictions (the real danger). Rejected as a standalone approach. However, it has value as a companion signal -- see hybrid design below.

---

### Approach C: Pattern Matching (Subject Extraction)

**Mechanism:** Parse the grammatical subject of each `[DELETION]`/`[DIRECTION]` entry using patterns like "Removed X", "Chose X over Y", "Deleted X". Then check if the task description references the same subject.

**Shell logic (sketch):**

```bash
# Extract subject from DELETION entry
# Pattern: "Removed <subject>." or "Removed <subject>. Reason:"
DL_SUBJECT="$(printf '%s' "$DL_LINE" \
  | sed -E 's/.*Removed ([^.]+)\..*/\1/' \
  | tr '[:upper:]' '[:lower:]')"

# Check if task desc contains the subject
if printf '%s' "$TASK_DESC_LOWER" | grep -qiF "$DL_SUBJECT"; then
  CONTRADICTION_WARNING=true
fi
```

**False positive risk:** LOW for `[DELETION]` with "Removed X" pattern (the subject is well-bounded). HIGH for free-form entries that do not follow the "Removed X" template. A `[DIRECTION]` entry saying "Chose SQLite over Postgres for local storage" -- what is the subject? "SQLite"? "Postgres"? "local storage"? The extraction pattern would need to handle "Chose X over Y" and flag tasks mentioning Y (the rejected option), not X (the chosen one).

**False negative risk:** HIGH. The approach depends on Decision Log entries following a strict grammatical template. Real-world entries from the codebase prove they do not:
- `"This plan improves Vidux itself."` -- no "Removed" or "Chose" verb.
- `"Phase 0 must complete 5+ iterations before Phase 1 begins."` -- no extractable subject.
- `"Control-plane hygiene checks are implementation work, not just documentation."` -- abstract.

Only 2 of the 30+ real Decision Log entries in this repo would match a "Removed X" or "Chose X over Y" template. The rest are free-form directives.

**Backward compat:** No breakage. Pure read-only analysis.

**Bash feasibility:** Yes for simple patterns. But the number of sed patterns needed to cover real-world entries makes this fragile and high-maintenance.

**Verdict:** Too brittle. Works only for the narrow case where entries follow a "Removed X" template. The keyword overlap approach (Approach A) covers this case and many others without requiring grammatical parsing.

---

## Recommended Design: Hybrid (A + B)

Combine keyword overlap detection (catches accidental contradictions) with explicit tag recognition (surfaces deliberate overrides). The two mechanisms serve different purposes and do not conflict.

### Why this hybrid

| Scenario | Keyword overlap (A) | Explicit tag (B) | Hybrid |
|----------|:---:|:---:|:---:|
| Accidental re-add of deleted feature | CATCHES | misses | CATCHES |
| Deliberate override with justification | may flag (harmless warning) | CATCHES | CATCHES (clean signal) |
| Unrelated task, shared domain words | may false-positive | silent | false-positive (warning only, not blocking) |
| Abstract `[DIRECTION]` entry | may miss (low keyword overlap) | misses unless tagged | may miss (acceptable -- these are hard even for humans) |

The hybrid covers the primary danger (accidental contradiction of `[DELETION]` entries) while also providing a clean signal for deliberate overrides. The false-positive risk on `[DIRECTION]` entries is acceptable because the output is warning-only.

### Design constraints met

1. **Works in bash:** Yes. `comm`, `sort`, `tr`, `grep` are standard. No Python required.
2. **Default to warning, not blocking:** Yes. Adds `contradiction_warning: true/false` and `contradiction_matches: "..."` to the JSON. Does NOT change `action`. The consuming LLM sees the warning and decides whether to proceed.
3. **Does not break PLAN.md format:** Yes. No changes to how PLAN.md is written. The `[Contradicts:]` tag is optional -- plans that omit it work identically to today.
4. **Adds new JSON fields:** Yes. Three new fields (see Output Contract below).
5. **Works alongside existing output:** Yes. Existing `decision_log_count`, `decision_log_warning`, `decision_log_entries` fields are untouched.

---

## Answer to Q2: Is Bash Sufficient?

**Yes, with calibration.**

Bash is sufficient for keyword-overlap contradiction detection at the scale Vidux operates (1-10 Decision Log entries, task descriptions under 200 characters, stop word list under 100 words). The `comm`/`sort`/`tr` pipeline processes this in single-digit milliseconds.

Bash is NOT sufficient for:
- Semantic similarity (would need embeddings -- requires Python + a model).
- Grammatical parsing (would need NLP -- requires Python + spaCy or similar).
- Fuzzy matching with edit distance (possible in bash with `agrep` but not portable).

None of these are needed for v2.3.0. The keyword overlap approach catches the primary danger case (accidental re-introduction of explicitly deleted features) and the threshold=2 minimum keeps false positives manageable. If calibration data from Phase 3 testing shows the threshold needs adjustment, it is a single integer change.

The one bash limitation worth noting: the stop word list is static. A more sophisticated system would weight words by TF-IDF or domain relevance. But for a Decision Log with 1-10 entries in a single PLAN.md, the static list is adequate. The alternative (shipping a Python helper for a 10-line word intersection) violates the script's design principle of bash-only stateless operation.

**Q2 status: ANSWERED. Bash is sufficient for keyword overlap. Semantic similarity is out of scope for v2.3.0.**

---

## Implementation Spec

### Where it goes in vidux-loop.sh

Insert after the existing Decision Log parsing block (line 64) and before the task-finding block (line 66). The contradiction check needs both `DL_ENTRIES` (from lines 56-64) and `TASK_DESC` (from line 99), so it must actually go after line 99 -- between task description extraction and the action decision block.

**Insertion point: after line 99 (task description extracted), before line 101 (assess block).**

This matches the script's flow: READ (parse plan) -> FIND TASK (get description) -> DETECT CONTRADICTIONS (new) -> ASSESS (type, evidence, blockers, Q-gate) -> DECIDE ACTION.

### Stop word list

The stop word list lives inline in the script (not an external file) to maintain the stateless single-file design. It contains:
- Standard English stop words (the, a, is, are, was, etc.)
- Vidux structural words that appear in every Decision Log entry by convention (task, removed, reason, evidence, changes, date, action, limited, chose)
- Threshold: skip words with fewer than 3 characters

The list can be tuned after Phase 3 calibration testing.

### Keyword extraction function

```bash
# Contradiction detection: stop words (inline, no external file)
CD_STOP="the a an is are was were be been being have has had do does did
will would shall should may might can could must need to of in for on at
by with from as into through during before after above below between about
against this that these those it its they them their we our you your not
no nor and but or if then else when where which what who whom how all each
every both few more most other some such any only own same than too very
just because so task removed reason added chose over unless evidence changes
date limited per day action plan do"

# Extract significant keywords from a string: lowercase, dedup, skip stops
_cd_keywords() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]-' '\n' \
    | sort -u | while IFS= read -r w; do
      [ ${#w} -lt 3 ] && continue
      # Word-boundary check against stop list
      case " $CD_STOP " in *" $w "*) continue ;; esac
      printf '%s\n' "$w"
    done
}
```

**Design note on the stop word check:** Using `case` with space-delimited matching instead of `grep -qw` for each word. This avoids spawning a subprocess per word, which matters when processing 20+ keywords. The `case` pattern `*" $w "*` provides exact word-boundary matching within the space-padded stop list.

### Contradiction detection block

```bash
# --- contradiction detection (keyword overlap + explicit tag) -------------- #
CONTRADICTION_WARNING=false; CONTRADICTION_MATCHES=""; CONTRADICTS_TAG=""

# Check for explicit [Contradicts: ...] tag first
CONTRADICTS_TAG="$(echo "$TASK_DESC" | grep -oE '\[Contradicts: [^]]+\]' || true)"
if [ -n "$CONTRADICTS_TAG" ]; then
  CONTRADICTION_WARNING=true
  CONTRADICTION_MATCHES="explicit: $CONTRADICTS_TAG"
fi

# Keyword overlap check against DELETION and DIRECTION entries
if [ "$DL_WARNING" = true ] && [ -n "$TASK_DESC" ]; then
  TASK_KW="$(_cd_keywords "$TASK_DESC")"
  if [ -n "$TASK_KW" ]; then
    while IFS= read -r DL_LINE; do
      [ -z "$DL_LINE" ] && continue
      # Only check DELETION and DIRECTION entries (RATE-LIMIT is quantity-based, not subject-based)
      DL_TAG="$(printf '%s' "$DL_LINE" | grep -oE '\[(DELETION|DIRECTION)\]' || true)"
      [ -z "$DL_TAG" ] && continue

      DL_KW="$(_cd_keywords "$DL_LINE")"
      [ -z "$DL_KW" ] && continue

      # Intersection via comm on sorted lists
      OVERLAP="$(comm -12 <(printf '%s\n' "$TASK_KW" | sort) <(printf '%s\n' "$DL_KW" | sort) 2>/dev/null || true)"
      OVERLAP_COUNT=0
      [ -n "$OVERLAP" ] && OVERLAP_COUNT="$(printf '%s\n' "$OVERLAP" | grep -c '.' || true)"

      if [ "$OVERLAP_COUNT" -ge 2 ]; then
        CONTRADICTION_WARNING=true
        OVERLAP_CSV="$(printf '%s\n' "$OVERLAP" | tr '\n' ',' | sed 's/,$//')"
        MATCH_NOTE="$DL_TAG overlap(${OVERLAP_COUNT}): ${OVERLAP_CSV}"
        CONTRADICTION_MATCHES="${CONTRADICTION_MATCHES:+$CONTRADICTION_MATCHES; }$MATCH_NOTE"
      fi
    done <<< "$DL_ENTRIES"
  fi
fi
```

### Output contract (new JSON fields)

Three new fields added to the JSON output block:

```json
{
  "contradiction_warning": false,
  "contradiction_matches": "",
  "contradicts_tag": ""
}
```

| Field | Type | Description |
|-------|------|-------------|
| `contradiction_warning` | boolean | `true` if keyword overlap >= 2 with any `[DELETION]`/`[DIRECTION]` entry, OR if task has `[Contradicts:]` tag |
| `contradiction_matches` | string | Semicolon-separated match descriptions. Format: `[TAG] overlap(N): word1,word2` for keyword matches, `explicit: [Contradicts: DL-N]` for tags. Empty string if no matches. |
| `contradicts_tag` | string | Raw `[Contradicts:]` tag text if present in task description, empty string otherwise. Allows consumers to distinguish deliberate overrides from accidental overlaps. |

**Backward compatibility:** These fields are additive. Existing consumers that do not check for them are unaffected. The existing `decision_log_*` fields remain unchanged.

**Relationship to `action`:** The contradiction detection does NOT modify the `action` field. A task with `contradiction_warning: true` still gets `action: "execute"` (or whatever the existing logic determines). This is deliberate: v2.3.0 is calibration phase. Blocking on contradiction requires calibration data from Phase 3 to set the right threshold. The warning gives the consuming LLM a mechanical signal it previously lacked.

### Changes to the output block (lines 220-241)

Add three new lines to the heredoc:

```bash
cat <<ENDJSON
{
  "cycle": $NEXT_CYCLE,
  "task": "$(json_escape "$TASK_DESC")",
  "type": "$TYPE",
  "has_evidence": $HAS_EVIDENCE,
  "blocked": $BLOCKED,
  "stuck": $STUCK,
  "auto_blocked": $AUTO_BLOCKED,
  "is_resuming": $IS_RESUMING,
  "task_open_questions": $TASK_OPEN_QS,
  "action": "$ACTION",
  "context": "$(json_escape "$CONTEXT")",
  "hot_tasks": $HOT_TASKS,
  "cold_tasks": $COLD_TASKS,
  "context_warning": $CONTEXT_WARNING,
  "context_note": "$(json_escape "$CONTEXT_NOTE")",
  "decision_log_count": $DL_COUNT,
  "decision_log_warning": $DL_WARNING,
  "decision_log_entries": "$(json_escape "$DL_ENTRIES")",
  "contradiction_warning": $CONTRADICTION_WARNING,
  "contradiction_matches": "$(json_escape "$CONTRADICTION_MATCHES")",
  "contradicts_tag": "$(json_escape "$CONTRADICTS_TAG")"
}
ENDJSON
```

The three new fields also need to appear in the early-exit JSON blocks (lines 83, 89, 91) for the `all_blocked`, `done`, and `empty` cases. In those cases, `CONTRADICTION_WARNING=false`, `CONTRADICTION_MATCHES=""`, `CONTRADICTS_TAG=""` (no task to check).

---

## Threshold Rationale

**Threshold = 2 keyword overlap.**

Why not 1: A single shared keyword produces too many false positives. "payment" appears in many tasks and many Decision Log entries in a payments-related project. One-word overlap would flag nearly every task.

Why not 3: The endurance test's canonical example -- `[DELETION] Removed legacy --verbose flag` vs task "Re-add --verbose flag" -- shares exactly 2 significant keywords after stop word removal: "verbose" and "flag". A threshold of 3 would miss this case. Since this is the motivating example from the convergence data, the threshold must be <= 2.

Why 2 is correct for calibration: Two shared non-stop words between a Decision Log entry and a task description indicates topical overlap strong enough to warrant a human glance. False positives are acceptable in warning-only mode -- the cost is one extra line in the JSON output that the LLM reads and dismisses. False negatives (missing a real contradiction) are more expensive.

**Future tuning:** Phase 3 testing (Task 3.2) will run synthetic plans with known contradictions and known non-contradictions through the detector. If the false positive rate exceeds 30% of flagged tasks, increase the threshold to 3. If the false negative rate exceeds 20% of known contradictions, decrease to 1 or expand the keyword extraction to include bigrams.

---

## Edge Cases

### 1. No Decision Log section
`DL_WARNING=false` -> contradiction check is skipped entirely. `contradiction_warning=false`. No cost.

### 2. Decision Log exists but has only `[RATE-LIMIT]` entries
The keyword overlap loop skips `[RATE-LIMIT]` entries (they are quantity-based constraints, not subject-based). `contradiction_warning=false` unless the task has an explicit `[Contradicts:]` tag.

### 3. Task description is very short (< 3 significant words)
`_cd_keywords` may return 0-1 keywords after stop word removal. With 0-1 task keywords, `comm -12` will produce 0-1 overlap at most, which is below threshold=2. Short tasks will not trigger false positives. They may produce false negatives if the task is genuinely contradictory but too terse to match. This is acceptable -- a 3-word task like "Add verbose flag" yields keywords "add", "verbose", "flag" (3 keywords, "add" is not a stop word). Against `[DELETION] Removed legacy --verbose flag`, the DL keywords include "legacy", "verbose", "flag". Overlap = "verbose", "flag" = 2. Caught correctly.

### 4. Task has `[Contradicts:]` tag AND keyword overlap
Both mechanisms fire. `contradiction_matches` will contain both the explicit tag note and the keyword overlap note, separated by semicolons. This is the correct behavior -- the consuming LLM sees that the override is both deliberate (tagged) and mechanically confirmed (keyword match).

### 5. Unicode or special characters in task descriptions
`tr -cs '[:alnum:]-' '\n'` strips everything except alphanumeric characters and hyphens. This handles most UTF-8 gracefully (accented characters pass through `[:alnum:]`). Emoji or CJK characters may not tokenize correctly, but Vidux plans are written in English.

### 6. `[STUCK]` entries in the Decision Log
Currently not parsed (Bug DL-STUCK-TAG-BLIND, to be fixed separately by adding `STUCK` to line 59's grep pattern). Once parsed, `[STUCK]` entries would appear in `DL_ENTRIES`. The contradiction detector's `DL_TAG` extraction only matches `DELETION|DIRECTION`, so `[STUCK]` entries are correctly skipped by the keyword overlap check. Stuck entries describe process state ("Task stuck for 3+ cycles"), not domain subjects, so keyword overlap would be meaningless.

### 7. Multiple contradictions in one cycle
The `while` loop iterates over all DL entries. If a task contradicts two different entries, both matches are recorded in `contradiction_matches`, semicolon-separated. `contradiction_warning` is set to `true` on the first match and stays true.

---

## Performance

Decision Log sizes in the codebase: 1-5 entries typical, 10 entries maximum observed. Task descriptions: 20-100 words. Stop word list: ~80 words.

For each DL entry:
- `_cd_keywords` on the entry: one `tr | tr | sort -u | while` pipeline = ~2ms
- `comm -12` on two sorted word lists: ~1ms
- Total per entry: ~3ms

For a plan with 5 DL entries: ~15ms total for the contradiction check. Negligible compared to the existing `grep` and `awk` operations in the script.

No external dependencies. No temporary files. No network calls.

---

## Contract Test Additions (for Task 3.1)

The following new contract tests should be added:

1. **`test_contradiction_fields_present`**: Verify `contradiction_warning`, `contradiction_matches`, `contradicts_tag` appear in JSON output.
2. **`test_contradiction_keyword_overlap_fires`**: Synthetic plan with `[DELETION] Removed legacy --verbose flag` and task "Re-add --verbose flag". Assert `contradiction_warning: true` and "verbose" + "flag" appear in `contradiction_matches`.
3. **`test_contradiction_no_overlap_below_threshold`**: Task shares 0-1 keywords with DL entry. Assert `contradiction_warning: false`.
4. **`test_contradiction_explicit_tag`**: Task with `[Contradicts: DL-1]`. Assert `contradiction_warning: true` and `contradicts_tag` is populated.
5. **`test_contradiction_rate_limit_skipped`**: Only `[RATE-LIMIT]` entries in DL. Assert `contradiction_warning: false` regardless of keyword overlap.
6. **`test_contradiction_no_dl_section`**: Plan without `## Decision Log`. Assert all three fields are false/empty.
7. **`test_contradiction_direction_entry_overlap`**: `[DIRECTION] Chose SQLite over Postgres` and task "Migrate to Postgres". Assert overlap on "postgres" triggers warning.

These tests are specified here for Task 3.1 to implement. They do not exist yet and should not be created during the Phase 0 planning phase.

---

## Diff Preview

The implementation (Task 2.1) will modify vidux-loop.sh in three locations:

**Location 1: After line 31 (helper functions)** -- add `_cd_keywords` function and `CD_STOP` word list.

**Location 2: After line 99 (task description extraction)** -- add the contradiction detection block (explicit tag check + keyword overlap loop).

**Location 3: Lines 220-241 (JSON output)** -- add three new fields. Also update lines 83, 89, 91 (early-exit JSON blocks) with the same three fields defaulting to false/empty.

Estimated diff size: ~50 lines added, 0 lines modified, 0 lines deleted. Pure additive change.

---

## Summary

| Approach | Catches accidental | Catches deliberate | False positive risk | Bash-native | Chosen |
|----------|:---:|:---:|:---:|:---:|:---:|
| A: Keyword overlap | YES | partially | MEDIUM | YES | YES (primary) |
| B: Explicit tags | no | YES | ZERO | YES | YES (companion) |
| C: Pattern matching | partially | no | LOW-HIGH | YES (fragile) | NO |
| **Hybrid A+B** | **YES** | **YES** | **MEDIUM** | **YES** | **RECOMMENDED** |

The hybrid approach (keyword overlap + explicit tags) is the recommended design for v2.3.0. It catches the primary danger case (accidental contradiction of `[DELETION]` entries) with a mechanical signal, while also providing a clean path for deliberate overrides via `[Contradicts:]` tags. The output is warning-only, adding three new JSON fields without modifying `action` or any existing fields. Bash is sufficient. No Python required. Q2 is answered.
