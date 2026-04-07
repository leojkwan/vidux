#!/usr/bin/env bash
# vidux-dispatch.sh — Dispatch mode: drain the queue, don't stop until empty.
#
# The structural counterpart of vidux-loop.sh (watch mode).
# - Watch mode (vidux-loop.sh): <2 min, read state, decide whether to fire dispatch.
# - Dispatch mode (this script):   no time limit, keep executing until queue drains.
#
# Usage:
#   bash vidux-dispatch.sh <plan-path>              # Run burst: pop tasks until queue empty
#   bash vidux-dispatch.sh <plan-path> --dry-run    # Show what would be done, don't execute
#
# Output: JSON with dispatch results (slices_completed, surprises, next_dispatch_recommended)
#
# Doctrine 10: Run quick or run deep — never in between.
# Doctrine 12: Bounded recursion — stop when good enough.
set -euo pipefail

PLAN="${1:-}"; MODE="${2:-burst}"

[[ -z "$PLAN" ]] && { echo '{"error": "Usage: vidux-dispatch.sh <plan-path> [--dry-run]"}'; exit 1; }
[[ ! -f "$PLAN" ]] && { echo "{\"error\": \"Plan not found: $PLAN\"}"; exit 1; }

# --- Common setup (reuse vidux-loop.sh's config + ledger integration) ------- #
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$SCRIPT_DIR/../vidux.config.json"

# Source ledger if available
_LEDGER_LIB="$SCRIPT_DIR/lib/ledger-emit.sh"
if [ -f "$_LEDGER_LIB" ]; then
  source "$_LEDGER_LIB" 2>/dev/null || true
fi

PLAN_DIR=$(dirname "$PLAN")
PROJECT_NAME="$(basename "$PLAN_DIR")"

# JSON helpers
json_escape() {
  local s="$1"; s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; s="${s//$'\t'/\\t}"; s="${s//$'\n'/\\n}"
  printf '%s' "$s"
}

# --- Count pending tasks (v1 + v2) ----------------------------------------- #
count_pending() {
  local count
  count=$(grep -cE '^[[:space:]]*-\ (\[ \]|\[pending\]) ' "$PLAN" 2>/dev/null || true)
  echo "${count:-0}"
}

# --- Count in-progress tasks ----------------------------------------------- #
count_in_progress() {
  local count
  count=$(grep -cE '^[[:space:]]*-\ \[in_progress\] ' "$PLAN" 2>/dev/null || true)
  echo "${count:-0}"
}

# --- Get the current task description -------------------------------------- #
current_task() {
  # First: any in_progress task
  local task
  task=$(grep -E '^[[:space:]]*-\ \[in_progress\] ' "$PLAN" | head -1 | sed -E 's/^[[:space:]]*-\ \[in_progress\] //' || true)
  if [[ -n "$task" ]]; then
    echo "$task"
    return
  fi
  # Otherwise: first pending task
  task=$(grep -E '^[[:space:]]*-\ (\[ \]|\[pending\]) ' "$PLAN" | head -1 | sed -E 's/^[[:space:]]*-\ (\[ \]|\[pending\]) //' || true)
  echo "$task"
}

# --- Check Decision Log for contradictions --------------------------------- #
check_decision_log() {
  local dl_count
  dl_count=$(grep -cE '^\- \[(DELETION|DIRECTION|RATE-LIMIT|STUCK|WORKTREE)\]' "$PLAN" 2>/dev/null || true)
  echo "${dl_count:-0}"
}

# --- Emit burst start event ------------------------------------------------ #
DISPATCH_START=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
PENDING_AT_START=$(count_pending)
IN_PROGRESS_AT_START=$(count_in_progress)
DECISION_LOG_COUNT=$(check_decision_log)

if type vidux_emit_loop_start &>/dev/null 2>&1; then
  vidux_emit_loop_start "$PROJECT_NAME" "$PLAN" "dispatch" 2>/dev/null || true
fi

# --- Dry-run mode ---------------------------------------------------------- #
if [[ "$MODE" == "--dry-run" ]]; then
  TASK=$(current_task)
  cat <<EOF
{
  "mode": "dry_run",
  "plan": "$PLAN",
  "project": "$PROJECT_NAME",
  "pending": $PENDING_AT_START,
  "in_progress": $IN_PROGRESS_AT_START,
  "decision_log_entries": $DECISION_LOG_COUNT,
  "next_task": "$(json_escape "${TASK:-none}")",
  "recommendation": "$([ "$PENDING_AT_START" -gt 0 ] && echo "fire_dispatch" || echo "nothing_pending")"
}
EOF
  exit 0
fi

# --- Burst assessment ------------------------------------------------------ #
# This script does NOT execute tasks itself. It produces the assessment that
# an agent (Claude Code, Codex, Cursor) uses to decide how to run.
# The agent reads this JSON and follows the burst protocol.

TASK=$(current_task)
BLOCKED_COUNT=$(grep -cE '^[[:space:]]*-\ \[blocked\] ' "$PLAN" 2>/dev/null || true)
COMPLETED_COUNT=$(grep -cE '^[[:space:]]*-\ (\[x\]|\[completed\]) ' "$PLAN" 2>/dev/null || true)

# Check if any task is stuck (appeared in 3+ Progress entries while in_progress)
STUCK="false"
if [[ "$IN_PROGRESS_AT_START" -gt 0 ]]; then
  IP_DESC=$(grep -E '^[[:space:]]*-\ \[in_progress\] ' "$PLAN" | head -1 | sed -E 's/^[[:space:]]*-\ \[in_progress\] //' | head -c 60)
  if [[ -n "$IP_DESC" ]]; then
    MENTION_COUNT=$(grep -cF "$IP_DESC" "$PLAN" 2>/dev/null || true)
    [[ "$MENTION_COUNT" -ge 4 ]] && STUCK="true"
  fi
fi

# Determine burst action
if [[ "$STUCK" == "true" ]]; then
  ACTION="stuck_detected"
elif [[ "$IN_PROGRESS_AT_START" -gt 0 ]]; then
  ACTION="resume_in_progress"
elif [[ "$PENDING_AT_START" -gt 0 ]]; then
  ACTION="execute_dispatch"
elif [[ "$PENDING_AT_START" -eq 0 && "$BLOCKED_COUNT" -gt 0 ]]; then
  ACTION="all_blocked"
elif [[ "$PENDING_AT_START" -eq 0 && "$BLOCKED_COUNT" -eq 0 ]]; then
  ACTION="queue_empty"
else
  ACTION="checkpoint_only"
fi

# Emit burst end event
if type vidux_emit_loop_end &>/dev/null 2>&1; then
  vidux_emit_loop_end "$PROJECT_NAME" "$PLAN" "$ACTION" "dispatch" "$TASK" 2>/dev/null || true
fi

# --- Output JSON ----------------------------------------------------------- #
cat <<EOF
{
  "mode": "dispatch",
  "plan": "$PLAN",
  "project": "$PROJECT_NAME",
  "dispatch_start": "$DISPATCH_START",
  "action": "$ACTION",
  "pending": $PENDING_AT_START,
  "in_progress": $IN_PROGRESS_AT_START,
  "blocked": ${BLOCKED_COUNT:-0},
  "completed": ${COMPLETED_COUNT:-0},
  "stuck": $STUCK,
  "decision_log_entries": $DECISION_LOG_COUNT,
  "current_task": "$(json_escape "${TASK:-none}")",
  "dispatch_protocol": {
    "stop_conditions": ["queue_empty", "hard_external_blocker", "context_budget_exceeded"],
    "forbidden": ["mid_zone_exit", "stop_after_one_task", "stop_at_natural_milestone"],
    "required": ["checkpoint_per_task", "self_extend_plan", "screenshot_proof_for_ui"]
  },
  "ledger_available": $([ "${LEDGER_AVAILABLE:-false}" = "true" ] && echo true || echo false)
}
EOF
