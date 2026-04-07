#!/usr/bin/env bash
# vidux-loop.sh — stateless cycle script
# Usage:  bash vidux-loop.sh <plan-path>              # READ + ASSESS -> JSON
#         bash vidux-loop.sh <plan-path> --checkpoint  # Mark current task done
#
# Supports both v1 checkbox format and v2 FSM states:
#   v1: - [ ] pending task    - [x] completed task
#   v2: - [pending], - [in_progress], - [completed], - [blocked]
# v2 takes priority in detection; v1 checkpoint output stays as - [x].
set -euo pipefail

PLAN="${1:-}"; MODE="${2:-read}"

# --- read config defaults (if vidux.config.json exists nearby) ------------ #
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$SCRIPT_DIR/../vidux.config.json"
ARCHIVE_THRESHOLD=30; CONTEXT_WARNING_LINES=200
if [ -f "$CONFIG" ]; then
  ARCHIVE_THRESHOLD=$(python3 -c "import json;print(json.load(open('$CONFIG')).get('defaults',{}).get('archive_threshold',30))" 2>/dev/null) || true
  if [ -z "$ARCHIVE_THRESHOLD" ]; then echo "WARNING: Could not parse vidux.config.json. Using defaults." >&2; ARCHIVE_THRESHOLD=30; fi
  CONTEXT_WARNING_LINES=$(python3 -c "import json;print(json.load(open('$CONFIG')).get('defaults',{}).get('context_warning_lines',200))" 2>/dev/null || echo 200)
fi

# --- ledger integration (optional) ----------------------------------------- #
_LEDGER_LIB="$SCRIPT_DIR/lib/ledger-emit.sh"
if [ -f "$_LEDGER_LIB" ]; then
  # shellcheck source=lib/ledger-emit.sh
  source "$_LEDGER_LIB" 2>/dev/null || true
fi

die()  { echo "{\"error\": \"$1\"}" >&2; exit 1; }
json() { printf '%s\n' "$1"; }
json_escape() {
  local s="$1"; s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; s="${s//$'\t'/\\t}"; s="${s//$'\n'/\\n}"
  printf '%s' "$s"
}
# Platform-aware sed -i
sedi() { if [[ "$(uname)" == "Darwin" ]]; then sed -i '' "$@"; else sed -i "$@"; fi; }

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
      case " $CD_STOP " in *" $w "*) continue ;; esac
      printf '%s\n' "$w"
    done
}

# --- guards ---------------------------------------------------------------- #
[ -z "$PLAN" ] && die "usage: vidux-loop.sh <plan-path> [--checkpoint]"
if [ ! -f "$PLAN" ]; then
  json '{"mode":"watch","error":"no plan found","action":"create_plan","next_action":"none"}'; exit 0
fi
PLAN_DIR="$(cd "$(dirname "$PLAN")" && pwd)"
PROJECT_NAME="$(basename "$PLAN_DIR")"

# --- emit loop start event ------------------------------------------------- #
if type vidux_emit_loop_start &>/dev/null; then
  vidux_emit_loop_start "$PROJECT_NAME" "$PLAN" "" 2>/dev/null || true
fi

# --- hot/cold window (read-only context budget awareness) ----------------- #
# HOT = pending + in_progress (v1 and v2)
HOT_TASKS="$(grep -cE '^\- (\[ \]|\[(pending|in_progress)\]) ' "$PLAN" || true)"
# COLD = completed (v1 and v2)
COLD_TASKS="$(grep -cE '^\- (\[x\]|\[completed\]) ' "$PLAN" || true)"
TOTAL_LINES="$(wc -l < "$PLAN" | tr -d ' ')"
CONTEXT_WARNING=false; CONTEXT_NOTE=""
if [ "$TOTAL_LINES" -gt "$CONTEXT_WARNING_LINES" ] || [ "$COLD_TASKS" -gt "$ARCHIVE_THRESHOLD" ]; then
  CONTEXT_WARNING=true
  CONTEXT_NOTE="PLAN.md has $COLD_TASKS completed tasks ($TOTAL_LINES lines). Consider archiving with vidux-checkpoint.sh --archive"
fi

# --- Decision Log awareness (READ step) ------------------------------------ #
# Parse ## Decision Log section. Cron agents MUST read entries before executing
# to avoid contradicting intentional deletions, rate limits, or directions.
# Contradiction detection requires LLM judgment — this surfaces the raw entries.
DL_COUNT=0; DL_ENTRIES=""; DL_WARNING=false
if grep -q '^## Decision Log' "$PLAN" 2>/dev/null; then
  DL_BLOCK="$(awk '/^## Decision Log/{found=1; next} found && /^## /{found=0} found{print}' "$PLAN")"
  DL_ENTRIES="$(printf '%s' "$DL_BLOCK" | grep -E '^\- \[(DELETION|RATE-LIMIT|DIRECTION|STUCK)\]' || true)"
  if [ -n "$DL_ENTRIES" ]; then
    DL_COUNT="$(printf '%s\n' "$DL_ENTRIES" | grep -c '.' || true)"
    DL_WARNING=true
  fi
fi

# Initialize contradiction detection fields (populated after task description is extracted)
CONTRADICTION_WARNING=false; CONTRADICTION_MATCHES=""; CONTRADICTS_TAG=""
PROCESS_FIX_DECLARED=""

# --- read: find first actionable task ------------------------------------- #
# Priority 1: resume an in_progress task (session may have died mid-task)
TASK_LINE="$(grep -nE '^\- \[in_progress\] ' "$PLAN" | head -1 || true)"
IS_RESUMING=false
if [ -n "$TASK_LINE" ]; then
  IS_RESUMING=true
fi

# Priority 2: first pending task (v2 FSM or v1 checkbox)
if [ -z "$TASK_LINE" ]; then
  TASK_LINE="$(grep -nE '^\- (\[ \]|\[pending\]) ' "$PLAN" | head -1 || true)"
fi

if [ -z "$TASK_LINE" ]; then
  # Check if there are blocked tasks left (not "done" — escalate)
  BLOCKED_COUNT="$(grep -cE '^\- \[blocked\] ' "$PLAN" || true)"
  if [ "$BLOCKED_COUNT" -gt 0 ]; then
    json "{\"mode\":\"watch\", \"cycle\": 0, \"task\": \"none\", \"type\": \"all_blocked\", \"action\": \"escalate\", \"next_action\": \"none\", \"context\": \"$BLOCKED_COUNT task(s) blocked — escalate blockers to human\", \"hot_tasks\": $HOT_TASKS, \"cold_tasks\": $COLD_TASKS, \"context_warning\": $CONTEXT_WARNING, \"context_note\": \"$(json_escape "$CONTEXT_NOTE")\", \"decision_log_count\": $DL_COUNT, \"decision_log_warning\": $DL_WARNING, \"decision_log_entries\": \"$(json_escape "$DL_ENTRIES")\", \"contradiction_warning\": $CONTRADICTION_WARNING, \"contradiction_matches\": \"$(json_escape "$CONTRADICTION_MATCHES")\", \"contradicts_tag\": \"$(json_escape "$CONTRADICTS_TAG")\", \"process_fix_declared\": \"$(json_escape "$PROCESS_FIX_DECLARED")\"}"
    exit 0
  fi
  # Check if there are ANY tasks at all (any FSM state)
  HAS_TASKS="$(grep -cE '^\- (\[.\]|\[(pending|in_progress|completed|blocked)\]) ' "$PLAN" || true)"
  if [ "$HAS_TASKS" -gt 0 ]; then
    json "{\"mode\":\"watch\", \"cycle\": 0, \"task\": \"none\", \"type\": \"done\", \"action\": \"complete\", \"next_action\": \"none\", \"context\": \"All tasks done\", \"hot_tasks\": $HOT_TASKS, \"cold_tasks\": $COLD_TASKS, \"context_warning\": $CONTEXT_WARNING, \"context_note\": \"$(json_escape "$CONTEXT_NOTE")\", \"decision_log_count\": $DL_COUNT, \"decision_log_warning\": $DL_WARNING, \"decision_log_entries\": \"$(json_escape "$DL_ENTRIES")\", \"contradiction_warning\": $CONTRADICTION_WARNING, \"contradiction_matches\": \"$(json_escape "$CONTRADICTION_MATCHES")\", \"contradicts_tag\": \"$(json_escape "$CONTRADICTS_TAG")\", \"process_fix_declared\": \"$(json_escape "$PROCESS_FIX_DECLARED")\"}"
  else
    json "{\"mode\":\"watch\", \"cycle\": 0, \"task\": \"none\", \"type\": \"empty\", \"action\": \"create_tasks\", \"next_action\": \"none\", \"context\": \"Plan has no tasks\", \"hot_tasks\": $HOT_TASKS, \"cold_tasks\": $COLD_TASKS, \"context_warning\": $CONTEXT_WARNING, \"context_note\": \"$(json_escape "$CONTEXT_NOTE")\", \"decision_log_count\": $DL_COUNT, \"decision_log_warning\": $DL_WARNING, \"decision_log_entries\": \"$(json_escape "$DL_ENTRIES")\", \"contradiction_warning\": $CONTRADICTION_WARNING, \"contradiction_matches\": \"$(json_escape "$CONTRADICTION_MATCHES")\", \"contradicts_tag\": \"$(json_escape "$CONTRADICTS_TAG")\", \"process_fix_declared\": \"$(json_escape "$PROCESS_FIX_DECLARED")\"}"
  fi
  exit 0
fi

LINE_NUM="${TASK_LINE%%:*}"
TASK_REST="${TASK_LINE#*:}"
# Strip the FSM/checkbox prefix: - [ ] , - [pending] , - [in_progress] , etc.
TASK_DESC="$(echo "$TASK_REST" | sed -E 's/^- \[([^]]*)\] //')"
PROCESS_FIX_DECLARED="$(echo "$TASK_DESC" | grep -oE '\[ProcessFix: ?[a-z_]+\]' | head -1 | sed -E 's/\[ProcessFix: ?([a-z_]+)\]/\1/' || true)"

# --- contradiction detection (keyword overlap + explicit tag) -------------- #
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

# --- assess ---------------------------------------------------------------- #
CYCLE_COUNT="$(grep -c 'Cycle [0-9]' "$PLAN" 2>/dev/null || true)"
NEXT_CYCLE=$((CYCLE_COUNT + 1))

# Task type
TYPE="code"
case "$TASK_DESC" in
  *Write*\.md*|*PLAN*|*DOCTRINE*|*LOOP*|*INGREDIENTS*|*README*|*doc*|*spec*) TYPE="doc" ;;
  *[Gg]ather*|*[Rr]esearch*|*[Ss]urvey*) TYPE="research" ;;
esac

# Evidence check
HAS_EVIDENCE=false
echo "$TASK_DESC" | grep -qi '\[Evidence\|evidence:\|Source:' && HAS_EVIDENCE=true

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

# Open questions — per-task-specific: only gate on Qn refs mentioned in THIS task's description
# LOOP.md:39 doctrine: "no items blocking the NEXT task specifically"
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

# Decide action
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

# --- stuck-loop detection -------------------------------------------------- #
# Uses Progress section (not git log) — survives commit message wording changes
# and LLM compaction. A task appearing in 3+ Progress entries without [completed] = stuck.
STUCK=false; STUCK_HITS=0; AUTO_BLOCKED=false
TASK_SHORT="$(echo "$TASK_DESC" | cut -c1-40)"
if grep -q '^## Progress' "$PLAN" 2>/dev/null; then
  PROG_BLOCK="$(awk '/^## Progress/{found=1; next} found && /^## /{found=0} found{print}' "$PLAN")"
  STUCK_HITS="$(printf '%s\n' "$PROG_BLOCK" | grep -cF "$TASK_SHORT" 2>/dev/null || true)"
  if [ "$STUCK_HITS" -ge 3 ]; then
    STUCK=true; ACTION="stuck"
    CONTEXT="Task in $STUCK_HITS Progress entries without completing; possible stuck loop"

    # --- mechanical enforcement: auto-block after 3+ cycles on same task --- #
    # Only act on [in_progress] tasks (pending tasks haven't been started yet)
    if [ "$IS_RESUMING" = true ] && [ -n "$LINE_NUM" ]; then
      TODAY="$(date +%Y-%m-%d)"
      # Grab the last progress entry mentioning this task for the reason
      LAST_PROG="$(printf '%s\n' "$PROG_BLOCK" | grep -F "$TASK_SHORT" | tail -1 || true)"
      LAST_PROG_ESCAPED="$(json_escape "${LAST_PROG:-no progress entry found}")"

      # Flip [in_progress] -> [blocked] on the task line
      sedi -E "${LINE_NUM}s/^- \[in_progress\] /- [blocked] /" "$PLAN" 2>/dev/null && AUTO_BLOCKED=true || true

      if [ "$AUTO_BLOCKED" = true ]; then
        # Append to Decision Log (create section if missing)
        DL_ENTRY="- [STUCK] [$TODAY] Task stuck for ${STUCK_HITS}+ cycles. Auto-blocked. Reason: ${LAST_PROG_ESCAPED}"
        if grep -q '^## Decision Log' "$PLAN" 2>/dev/null; then
          sedi "/^## Decision Log/a\\
$DL_ENTRY" "$PLAN"
        else
          # Insert Decision Log section before ## Tasks (or append to end)
          if grep -q '^## Tasks' "$PLAN" 2>/dev/null; then
            sedi "/^## Tasks/i\\
## Decision Log\\
$DL_ENTRY\\
" "$PLAN"
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

# --- recompute hot_tasks after mutations (stuck-loop may have auto-blocked) - #
HOT_TASKS="$(grep -cE '^\- (\[ \]|\[(pending|in_progress)\]) ' "$PLAN" || true)"

# --- checkpoint mode ------------------------------------------------------- #
if [ "$MODE" = "--checkpoint" ]; then
  TODAY="$(date +%Y-%m-%d)"
  # v1 checkbox → [x]
  sedi "${LINE_NUM}s/^- \[ \] /- [x] /" "$PLAN"
  # v2 FSM → [completed]
  sedi -E "${LINE_NUM}s/^- \[(pending|in_progress)\] /- [completed] /" "$PLAN"
  PROGRESS="- [$TODAY] Cycle $NEXT_CYCLE: Done: $(json_escape "$TASK_DESC"). Next: check plan."
  if grep -q '^## Progress' "$PLAN"; then
    sedi "/^## Progress/a\\
$PROGRESS" "$PLAN"
  fi
  # Emit checkpoint event
  if type vidux_emit_checkpoint &>/dev/null; then
    local_commit=$(git -C "$PLAN_DIR" rev-parse HEAD 2>/dev/null || echo "")
    vidux_emit_checkpoint "$PROJECT_NAME" "$PLAN" "$local_commit" "done" 2>/dev/null || true
  fi
  json "{\"checkpoint\": true, \"cycle\": $NEXT_CYCLE, \"task\": \"$(json_escape "$TASK_DESC")\", \"status\": \"done\"}"
  exit 0
fi

# --- ledger conflict check ------------------------------------------------- #
LEDGER_CONFLICTS=""; LEDGER_CONFLICT_COUNT=0
if type ledger_conflict_check &>/dev/null 2>&1; then
  # Source query lib (emit already sourced config)
  _QUERY_LIB="$SCRIPT_DIR/lib/ledger-query.sh"
  [ -f "$_QUERY_LIB" ] && source "$_QUERY_LIB" 2>/dev/null || true
  if type ledger_conflict_check &>/dev/null 2>&1; then
    _REPO_NAME="$(basename "$(git -C "$PLAN_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$PLAN_DIR")")"
    _CONFLICT_JSON=$(ledger_conflict_check "$_REPO_NAME" "[\"$PLAN\"]" 2 2>/dev/null || echo '[]')
    LEDGER_CONFLICT_COUNT=$(printf '%s' "$_CONFLICT_JSON" | jq 'length' 2>/dev/null || echo 0)
    [ "$LEDGER_CONFLICT_COUNT" -gt 0 ] && LEDGER_CONFLICTS="$_CONFLICT_JSON"
  fi
fi

# --- output ---------------------------------------------------------------- #
# Field semantics: blocked vs auto_blocked
#   blocked     = dependency-gated: task's [Depends: X] references an unresolved task
#   auto_blocked = stuck-loop enforcement: task was in_progress for 3+ cycles, script
#                  flipped it to [blocked] in PLAN.md. Human must unblock.
#   Both are booleans. A task can be auto_blocked=true with blocked=false (stuck, not dep-gated).
NEXT_ACTION="none"
case "$ACTION" in
  execute|gather_evidence|refine) NEXT_ACTION="burst" ;;
esac
cat <<ENDJSON
{
  "mode": "watch",
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
  "next_action": "$NEXT_ACTION",
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
  "contradicts_tag": "$(json_escape "$CONTRADICTS_TAG")",
  "process_fix_declared": "$(json_escape "$PROCESS_FIX_DECLARED")",
  "ledger_available": $([ "${LEDGER_AVAILABLE:-false}" = "true" ] && echo true || echo false),
  "ledger_conflicts": ${LEDGER_CONFLICT_COUNT:-0}
}
ENDJSON
