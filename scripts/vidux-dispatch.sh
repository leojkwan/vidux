#!/usr/bin/env bash
# vidux-dispatch.sh — Dispatch mode: drain the queue, don't stop until empty.
#
# The structural counterpart of vidux-loop.sh (reduce mode).
# - Reduce mode (vidux-loop.sh): <2 min, read state, decide whether to fire dispatch.
# - Dispatch mode (this script):   no time limit, keep executing until queue drains.
#
# Usage:
#   bash vidux-dispatch.sh <plan-path>              # Run dispatch: pop tasks until queue empty
#   bash vidux-dispatch.sh <plan-path> --dry-run    # Show what would be done, don't execute
#
# Output: JSON with dispatch results (slices_completed, surprises, next_dispatch_recommended)
#
# Doctrine 10: Run quick or run deep — never in between.
# Doctrine 12: Bounded recursion — stop when good enough.
set -euo pipefail

PLAN="${1:-}"; MODE="${2:-dispatch}"

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
  local s="$1"
  s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; s="${s//$'\t'/\\t}"; s="${s//$'\n'/\\n}"; s="${s//$'\r'/\\r}"
  printf '%s' "$s"
}

# --- Exit Criteria parsing -------------------------------------------------- #
# Count unchecked `- [ ]` lines inside the ## Exit Criteria section.
# Also computes EC_LINE_START/END so task searches can exclude EC lines.
EC_LINE_START=0; EC_LINE_END=0
parse_exit_criteria() {
  local ec_pending=0 ec_total=0
  if grep -q '^## Exit Criteria' "$PLAN" 2>/dev/null; then
    EC_LINE_START="$(grep -n '^## Exit Criteria' "$PLAN" | head -1 | cut -d: -f1)"
    EC_LINE_END="$(awk -v start="$EC_LINE_START" 'NR>start && /^## /{print NR; exit}' "$PLAN")"
    [ -z "$EC_LINE_END" ] && EC_LINE_END="$(( $(wc -l < "$PLAN" | tr -d ' ') + 1 ))"
    local ec_block
    ec_block="$(awk '/^## Exit Criteria/{found=1; next} found && /^## /{found=0} found{print}' "$PLAN")"
    ec_total=$(printf '%s\n' "$ec_block" | grep -cE '^\- \[[ x]\] ' || true)
    ec_pending=$(printf '%s\n' "$ec_block" | grep -cE '^\- \[ \] ' || true)
  fi
  EXIT_CRITERIA_TOTAL="${ec_total:-0}"
  EXIT_CRITERIA_PENDING="${ec_pending:-0}"
  if [ "$EXIT_CRITERIA_PENDING" -gt 0 ]; then
    EXIT_CRITERIA_MET="false"
  else
    EXIT_CRITERIA_MET="true"
  fi
}

# Helper: filter out Exit Criteria line range from grep -n output
_exclude_ec_lines() {
  if [ "$EC_LINE_START" -gt 0 ]; then
    while IFS= read -r line; do
      local lnum="${line%%:*}"
      if [ "$lnum" -ge "$EC_LINE_START" ] && [ "$lnum" -lt "$EC_LINE_END" ]; then
        continue
      fi
      printf '%s\n' "$line"
    done
  else
    cat
  fi
}

# --- Count pending tasks (v1 + v2) — excludes Exit Criteria lines ---------- #
count_pending() {
  local count
  count=$(grep -nE '^[[:space:]]*-\ (\[ \]|\[pending\]) ' "$PLAN" 2>/dev/null | _exclude_ec_lines | grep -c '.' || true)
  echo "${count:-0}"
}

# --- Count in-progress tasks ----------------------------------------------- #
count_in_progress() {
  local count
  count=$(grep -nE '^[[:space:]]*-\ \[in_progress\] ' "$PLAN" 2>/dev/null | _exclude_ec_lines | grep -c '.' || true)
  echo "${count:-0}"
}

# --- Get the current task description -------------------------------------- #
current_task() {
  # First: any in_progress task (excluding Exit Criteria section)
  local task line
  line=$(grep -nE '^[[:space:]]*-\ \[in_progress\] ' "$PLAN" | _exclude_ec_lines | head -1 || true)
  if [[ -n "$line" ]]; then
    task=$(printf '%s' "$line" | sed -E 's/^[0-9]+:[[:space:]]*-\ \[in_progress\] //')
    echo "$task"
    return
  fi
  # Otherwise: first pending task (excluding Exit Criteria section)
  line=$(grep -nE '^[[:space:]]*-\ (\[ \]|\[pending\]) ' "$PLAN" | _exclude_ec_lines | head -1 || true)
  if [[ -n "$line" ]]; then
    task=$(printf '%s' "$line" | sed -E 's/^[0-9]+:[[:space:]]*-\ (\[ \]|\[pending\]) //')
    echo "$task"
    return
  fi
  echo ""
}

# --- Check Decision Log for contradictions --------------------------------- #
check_decision_log() {
  local dl_count
  dl_count=$(grep -cE '^\- \[(DELETION|DIRECTION|RATE-LIMIT|STUCK|WORKTREE)\]' "$PLAN" 2>/dev/null || true)
  echo "${dl_count:-0}"
}

# --- Emit dispatch start event --------------------------------------------- #
DISPATCH_START=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Parse exit criteria FIRST — count_pending/count_in_progress depend on EC line range
parse_exit_criteria

PENDING_AT_START=$(count_pending)
IN_PROGRESS_AT_START=$(count_in_progress)
DECISION_LOG_COUNT=$(check_decision_log)

if type vidux_emit_loop_start &>/dev/null 2>&1; then
  vidux_emit_loop_start "$PROJECT_NAME" "$PLAN" "dispatch" 2>/dev/null || true
fi

# --- Merge-gate mode ------------------------------------------------------- #
# After dispatch completes in a worktree, merge work to the default branch.
# Tier 1 (fast-forward): auto-merge + push.
# Tier 2 (conflicts): create PR for human review.
if [[ "$MODE" == "--merge-gate" ]]; then
  # Detect worktree vs main repo
  GIT_TOPLEVEL="$(git -C "$PLAN_DIR" rev-parse --show-toplevel 2>/dev/null || echo "")"
  GIT_COMMONDIR="$(git -C "$PLAN_DIR" rev-parse --git-common-dir 2>/dev/null || echo "")"
  IS_WORKTREE="false"
  WORKTREE_BRANCH=""
  if [[ -n "$GIT_TOPLEVEL" && -n "$GIT_COMMONDIR" ]]; then
    REAL_COMMONDIR="$(cd "$PLAN_DIR" && cd "$GIT_COMMONDIR" && pwd 2>/dev/null || echo "")"
    RAW_GITDIR="$(git -C "$PLAN_DIR" rev-parse --git-dir 2>/dev/null || echo "")"
    # Resolve to absolute path for comparison
    if [[ -d "$RAW_GITDIR" ]]; then
      REAL_GITDIR="$(cd "$RAW_GITDIR" && pwd 2>/dev/null || echo "")"
    else
      REAL_GITDIR="$RAW_GITDIR"
    fi
    if [[ "$REAL_GITDIR" != "$REAL_COMMONDIR" ]]; then
      IS_WORKTREE="true"
      WORKTREE_BRANCH="$(git -C "$PLAN_DIR" branch --show-current 2>/dev/null || echo "detached")"
    fi
  fi

  if [[ "$IS_WORKTREE" == "false" ]]; then
    cat <<MGEOF
{"merge_gate": "skip", "reason": "not_in_worktree", "plan": "$PLAN"}
MGEOF
    exit 0
  fi

  # Find the default branch from the main repo
  MAIN_REPO_DIR="$(cd "$PLAN_DIR" && cd "$(git rev-parse --git-common-dir)/.." && pwd)"
  DEFAULT_BRANCH="$(git -C "$MAIN_REPO_DIR" symbolic-ref --short HEAD 2>/dev/null || echo "main")"

  # Check for uncommitted changes in worktree
  if ! git -C "$PLAN_DIR" diff --quiet 2>/dev/null || ! git -C "$PLAN_DIR" diff --cached --quiet 2>/dev/null; then
    cat <<MGEOF
{"merge_gate": "blocked", "reason": "uncommitted_changes", "worktree_branch": "$WORKTREE_BRANCH", "plan": "$PLAN"}
MGEOF
    exit 1
  fi

  # Count commits ahead of default branch
  COMMITS_AHEAD="$(git -C "$PLAN_DIR" rev-list --count "${DEFAULT_BRANCH}..HEAD" 2>/dev/null || echo "0")"
  if [[ "$COMMITS_AHEAD" -eq 0 ]]; then
    cat <<MGEOF
{"merge_gate": "skip", "reason": "nothing_to_merge", "worktree_branch": "$WORKTREE_BRANCH", "default_branch": "$DEFAULT_BRANCH"}
MGEOF
    exit 0
  fi

  # Tier 1: Try fast-forward merge in the main repo
  cd "$MAIN_REPO_DIR"
  if git merge --ff-only "$WORKTREE_BRANCH" 2>/dev/null; then
    # Push if remote exists
    PUSHED="false"
    if git remote | grep -q origin; then
      git push origin "$DEFAULT_BRANCH" 2>/dev/null && PUSHED="true" || PUSHED="failed"
    fi
    cat <<MGEOF
{"merge_gate": "merged", "tier": 1, "method": "fast_forward", "worktree_branch": "$WORKTREE_BRANCH", "default_branch": "$DEFAULT_BRANCH", "commits": $COMMITS_AHEAD, "pushed": "$PUSHED"}
MGEOF
    exit 0
  fi

  # Tier 2: Try regular merge
  if git merge --no-edit "$WORKTREE_BRANCH" 2>/dev/null; then
    PUSHED="false"
    if git remote | grep -q origin; then
      git push origin "$DEFAULT_BRANCH" 2>/dev/null && PUSHED="true" || PUSHED="failed"
    fi
    cat <<MGEOF
{"merge_gate": "merged", "tier": 2, "method": "merge_commit", "worktree_branch": "$WORKTREE_BRANCH", "default_branch": "$DEFAULT_BRANCH", "commits": $COMMITS_AHEAD, "pushed": "$PUSHED"}
MGEOF
    exit 0
  fi

  # Tier 3: Merge failed — abort and create PR if gh available
  git merge --abort 2>/dev/null || true
  PR_URL=""
  if command -v gh &>/dev/null; then
    cd "$PLAN_DIR"
    git push -u origin "$WORKTREE_BRANCH" 2>/dev/null || true
    PR_URL="$(gh pr create --base "$DEFAULT_BRANCH" --head "$WORKTREE_BRANCH" --title "Dispatch: merge $WORKTREE_BRANCH" --body "Auto-created by vidux merge-gate. Manual conflict resolution needed." 2>/dev/null || echo "pr_creation_failed")"
  fi
  cat <<MGEOF
{"merge_gate": "conflict", "tier": 3, "worktree_branch": "$WORKTREE_BRANCH", "default_branch": "$DEFAULT_BRANCH", "commits": $COMMITS_AHEAD, "pr_url": "$(json_escape "$PR_URL")"}
MGEOF
  exit 1
fi

# --- Dry-run mode ---------------------------------------------------------- #
if [[ "$MODE" == "--dry-run" ]]; then
  TASK=$(current_task)
  # Dry-run recommendation: fire if pending tasks exist OR exit criteria unmet
  if [[ "$PENDING_AT_START" -gt 0 ]]; then
    DRY_RUN_REC="fire_dispatch"
  elif [[ "$EXIT_CRITERIA_MET" == "false" ]]; then
    DRY_RUN_REC="exit_criteria_pending"
  else
    DRY_RUN_REC="nothing_pending"
  fi
  cat <<EOF
{
  "mode": "dry_run",
  "plan": "$PLAN",
  "project": "$PROJECT_NAME",
  "pending": $PENDING_AT_START,
  "in_progress": $IN_PROGRESS_AT_START,
  "decision_log_entries": $DECISION_LOG_COUNT,
  "exit_criteria_met": $EXIT_CRITERIA_MET,
  "exit_criteria_pending": $EXIT_CRITERIA_PENDING,
  "next_task": "$(json_escape "${TASK:-none}")",
  "recommendation": "$DRY_RUN_REC"
}
EOF
  exit 0
fi

# --- Dispatch assessment --------------------------------------------------- #
# This script does NOT execute tasks itself. It produces the assessment that
# an agent (Claude Code, Codex, Cursor) uses to decide how to run.
# The agent reads this JSON and follows the dispatch protocol.

TASK=$(current_task)
BLOCKED_COUNT=$(grep -nE '^[[:space:]]*-\ \[blocked\] ' "$PLAN" 2>/dev/null | _exclude_ec_lines | grep -c '.' || true)
COMPLETED_COUNT=$(grep -nE '^[[:space:]]*-\ (\[x\]|\[completed\]) ' "$PLAN" 2>/dev/null | _exclude_ec_lines | grep -c '.' || true)

# Check if any task is stuck (appeared in 3+ Progress entries while in_progress)
STUCK="false"
if [[ "$IN_PROGRESS_AT_START" -gt 0 ]]; then
  IP_DESC=$(grep -nE '^[[:space:]]*-\ \[in_progress\] ' "$PLAN" | _exclude_ec_lines | head -1 | sed -E 's/^[0-9]+:[[:space:]]*-\ \[in_progress\] //' | head -c 60)
  if [[ -n "$IP_DESC" ]]; then
    MENTION_COUNT=$(grep -cF "$IP_DESC" "$PLAN" 2>/dev/null || true)
    [[ "$MENTION_COUNT" -ge 4 ]] && STUCK="true"
  fi
fi

# Determine dispatch action
if [[ "$STUCK" == "true" ]]; then
  ACTION="stuck_detected"
elif [[ "$IN_PROGRESS_AT_START" -gt 0 ]]; then
  ACTION="resume_in_progress"
elif [[ "$PENDING_AT_START" -gt 0 ]]; then
  ACTION="execute_dispatch"
elif [[ "$PENDING_AT_START" -eq 0 && "$BLOCKED_COUNT" -gt 0 ]]; then
  ACTION="all_blocked"
elif [[ "$PENDING_AT_START" -eq 0 && "$BLOCKED_COUNT" -eq 0 && "$EXIT_CRITERIA_MET" == "true" ]]; then
  ACTION="queue_empty"
elif [[ "$PENDING_AT_START" -eq 0 && "$BLOCKED_COUNT" -eq 0 && "$EXIT_CRITERIA_MET" == "false" ]]; then
  ACTION="exit_criteria_pending"
else
  ACTION="checkpoint_only"
fi

# Emit dispatch end event
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
  "exit_criteria_met": $EXIT_CRITERIA_MET,
  "exit_criteria_pending": $EXIT_CRITERIA_PENDING,
  "dispatch_protocol": {
    "stop_conditions": ["queue_empty_and_exit_criteria_met", "hard_external_blocker", "context_budget_exceeded"],
    "forbidden": ["mid_zone_exit", "stop_after_one_task", "stop_at_natural_milestone", "ignore_exit_criteria"],
    "required": ["checkpoint_per_task", "self_extend_plan", "screenshot_proof_for_ui"]
  },
  "ledger_available": $([ "${LEDGER_AVAILABLE:-false}" = "true" ] && echo true || echo false)
}
EOF
