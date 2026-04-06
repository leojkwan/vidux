#!/usr/bin/env bash
# vidux-checkpoint.sh — structured checkpoint for the Vidux loop.
# Pure bash. No dependencies beyond sed, grep, date, git.
#
# Supports both v1 checkbox format and v2 FSM states:
#   v1: - [ ] pending task    - [x] completed task
#   v2: - [pending], - [in_progress], - [completed], - [blocked]
#
# --status flag distinguishes checkpoint outcomes:
#   done             (default) — task complete, verified
#   done_with_concerns         — works but has caveats (adds [concerns noted] to Progress)
#   blocked                    — external dependency; marks task [blocked], not [completed]
set -euo pipefail

# Platform-aware sed -i (macOS vs Linux)
sedi() { if [[ "$(uname)" == "Darwin" ]]; then sed -i '' "$@"; else sed -i "$@"; fi; }

usage() {
  cat <<'USAGE'
Usage:
  vidux-checkpoint.sh <plan-path> <task-description> <summary> [--blocker <text>] [--status <done|done_with_concerns|blocked>]
  vidux-checkpoint.sh <plan-path> --archive
USAGE
  exit 1
}

[[ $# -lt 2 ]] && usage

PLAN="$1"
[[ ! -f "$PLAN" ]] && { echo "Error: plan not found: $PLAN"; exit 1; }

# Guard: ensure plan is inside a git repo
if ! git -C "$(dirname "$PLAN")" rev-parse --show-toplevel &>/dev/null; then
  echo "Error: $PLAN is not inside a git repository. Checkpoint requires git." >&2
  exit 1
fi

# --- ledger integration (optional) ----------------------------------------- #
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
_LEDGER_LIB="$SCRIPT_DIR/lib/ledger-emit.sh"
if [ -f "$_LEDGER_LIB" ]; then
  # shellcheck source=lib/ledger-emit.sh
  source "$_LEDGER_LIB" 2>/dev/null || true
fi

DATE=$(date +%Y-%m-%d)
PLAN_DIR=$(dirname "$PLAN")

# =============================================================================
# --archive mode: move old completed tasks to ARCHIVE.md
# =============================================================================
if [[ "${2:-}" == "--archive" ]]; then
  ARCHIVE="${PLAN_DIR}/ARCHIVE.md"

  # Read archive_threshold from config (same pattern as vidux-loop.sh)
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  CONFIG="$SCRIPT_DIR/../vidux.config.json"
  KEEP=30  # fallback default
  if [ -f "$CONFIG" ]; then
    KEEP=$(python3 -c "import json;print(json.load(open('$CONFIG')).get('defaults',{}).get('archive_threshold',30))" 2>/dev/null || echo 30)
  fi

  # Collect all completed task lines: v1 [x] and v2 [completed] (preserving file order = oldest first)
  COMPLETED_LINES=$(grep -nE '^[[:space:]]*-\ (\[x\]|\[completed\]) ' "$PLAN" || true)
  if [[ -z "$COMPLETED_LINES" ]]; then
    COMPLETED_COUNT=0
  else
    COMPLETED_COUNT=$(echo "$COMPLETED_LINES" | wc -l | tr -d ' ')
  fi

  if (( COMPLETED_COUNT <= KEEP )); then
    echo "Only ${COMPLETED_COUNT} completed tasks (threshold: >${KEEP}). Nothing to archive."
    exit 0
  fi

  ARCHIVE_COUNT=$(( COMPLETED_COUNT - KEEP ))

  # Extract the lines to archive (oldest = first in file order)
  # || true: head closes pipe after N lines; echo gets SIGPIPE; pipefail would propagate 141
  LINES_TO_ARCHIVE=$(echo "$COMPLETED_LINES" | head -n "$ARCHIVE_COUNT") || true

  # Idempotency: if we already archived this exact set, skip.
  if grep -qF "<!-- ${ARCHIVE_COUNT} tasks archived to ARCHIVE.md -->" "$PLAN" 2>/dev/null; then
    echo "Already archived. Skipping."
    exit 0
  fi

  # --- Build the text block to append to ARCHIVE.md ---
  ARCHIVE_BLOCK=$(echo "$LINES_TO_ARCHIVE" | sed 's/^[0-9]*://')

  # --- Append to ARCHIVE.md (create if needed) ---
  if [[ ! -f "$ARCHIVE" ]]; then
    cat > "$ARCHIVE" <<'HEADER'
# Archived Tasks

Tasks completed and archived from PLAN.md to keep context lean.
HEADER
  fi

  {
    echo ""
    echo "## Archived ${DATE}"
    echo "$ARCHIVE_BLOCK"
  } >> "$ARCHIVE"

  # --- Remove archived lines from PLAN.md (by line number, highest first) ---
  LINE_NUMBERS=$(echo "$LINES_TO_ARCHIVE" | cut -d: -f1 | sort -rn)
  for LN in $LINE_NUMBERS; do
    sedi "${LN}d" "$PLAN"
  done

  # --- Add archive comment at end of Tasks section ---
  # Remove any previous archive comment first to stay idempotent
  sedi '/<!-- [0-9]* tasks archived to ARCHIVE.md -->/d' "$PLAN"

  # Insert after the last remaining completed or unchecked task line
  LAST_TASK_LINE=$(grep -n '^[[:space:]]*-\ \[' "$PLAN" | tail -1 | cut -d: -f1 || true)
  if [[ -n "$LAST_TASK_LINE" ]]; then
    sedi "${LAST_TASK_LINE}a\\
<!-- ${ARCHIVE_COUNT} tasks archived to ARCHIVE.md -->
" "$PLAN"
  else
    echo "<!-- ${ARCHIVE_COUNT} tasks archived to ARCHIVE.md -->" >> "$PLAN"
  fi

  # --- Commit ---
  git add "$PLAN" "$ARCHIVE"
  if ! git commit -m "vidux: archive ${ARCHIVE_COUNT} completed tasks to ARCHIVE.md"; then
    echo "Error: git commit failed — archive not saved" >&2
    exit 1
  fi

  echo "Archived ${ARCHIVE_COUNT} completed tasks to ${ARCHIVE}"
  exit 0
fi

# =============================================================================
# Normal checkpoint mode
# =============================================================================
[[ $# -lt 3 ]] && usage

TASK="$2"
SUMMARY="$3"
BLOCKER="none"
STATUS="done"
OUTCOME=""

shift 3
while [[ $# -gt 0 ]]; do
  case "$1" in
    --blocker) BLOCKER="$2"; shift 2 ;;
    --status) STATUS="$2"; shift 2 ;;
    --outcome) OUTCOME="$2"; shift 2 ;;
    *) usage ;;
  esac
done

case "$STATUS" in
  done|done_with_concerns|blocked) ;;
  *) echo "Error: --status must be done, done_with_concerns, or blocked" >&2; exit 1 ;;
esac

if [[ -n "$OUTCOME" ]]; then
  case "$OUTCOME" in
    useful|busy|blocked_clarified) ;;
    *) echo "Error: --outcome must be useful, busy, or blocked_clarified" >&2; exit 1 ;;
  esac
fi

# --- Idempotency: skip if task is already in a terminal FSM state ---
# Terminal states: v2 [completed] or [blocked]; v1 [x]
if grep -qF "[x] ${TASK}" "$PLAN" || grep -qF "[completed] ${TASK}" "$PLAN" || grep -qF "[blocked] ${TASK}" "$PLAN"; then
  echo "Task already in terminal state. Skipping."
  exit 0
fi

# --- Escape sed special chars in the task description ---
ESCAPED_TASK=$(printf '%s\n' "$TASK" | sed 's/[&/\]/\\&/g; s/[][]/\\&/g')

# --- Mark the task based on --status ---
if [[ "$STATUS" == "blocked" ]]; then
  # v2: pending -> blocked
  sedi "s/^[[:space:]]*- \[pending\] ${ESCAPED_TASK}/- [blocked] ${ESCAPED_TASK} [Blocked: ${DATE}]/" "$PLAN"
  # v2: in_progress -> blocked
  sedi "s/^[[:space:]]*- \[in_progress\] ${ESCAPED_TASK}/- [blocked] ${ESCAPED_TASK} [Blocked: ${DATE}]/" "$PLAN"
  # v1: [ ] -> [blocked] (no native v1 equivalent; use [blocked] for semantic clarity)
  sedi "s/^[[:space:]]*- \[ \] ${ESCAPED_TASK}/- [blocked] ${ESCAPED_TASK} [Blocked: ${DATE}]/" "$PLAN"
else
  # done or done_with_concerns: mark completed
  # v2: pending -> completed
  sedi "s/^[[:space:]]*- \[pending\] ${ESCAPED_TASK}/- [completed] ${ESCAPED_TASK} [Done: ${DATE}]/" "$PLAN"
  # v2: in_progress -> completed
  sedi "s/^[[:space:]]*- \[in_progress\] ${ESCAPED_TASK}/- [completed] ${ESCAPED_TASK} [Done: ${DATE}]/" "$PLAN"
  # v1: [ ] -> [x]
  sedi "s/^[[:space:]]*- \[ \] ${ESCAPED_TASK}/- [x] ${ESCAPED_TASK} [Done: ${DATE}]/" "$PLAN"
fi

# --- Verify the substitution worked ---
if ! grep -qF "[x] ${TASK}" "$PLAN" && ! grep -qF "[completed] ${TASK}" "$PLAN" && ! grep -qF "[blocked] ${TASK}" "$PLAN"; then
  echo "Error: could not find task in plan after substitution: ${TASK}" >&2
  exit 1
fi

# --- Determine cycle number (count existing Progress entries + 1) ---
PROGRESS_COUNT=$(grep -cE '^[[:space:]]*-\ \[[0-9]{4}-' "$PLAN" 2>/dev/null || true)
PROGRESS_COUNT=${PROGRESS_COUNT:-0}
CYCLE=$(( PROGRESS_COUNT + 1 ))

# --- Determine next task (first pending task — v1 or v2) ---
NEXT_TASK=$(grep -E '^[[:space:]]*-\ (\[ \]|\[pending\]) ' "$PLAN" | head -1 | sed -E 's/^[[:space:]]*-\ (\[ \]|\[pending\]) //' || true)
if [[ -z "$NEXT_TASK" ]]; then
  NEXT_TASK="all tasks complete"
fi

# --- Build progress entry ---
STATUS_NOTE=""
[[ "$STATUS" == "done_with_concerns" ]] && STATUS_NOTE=" [concerns noted]"
[[ "$STATUS" == "blocked" ]] && STATUS_NOTE=" [BLOCKED]"
OUTCOME_NOTE=""
[[ -n "$OUTCOME" ]] && OUTCOME_NOTE=" outcome=${OUTCOME}"
PROGRESS_LINE="- [${DATE}] Cycle ${CYCLE}: ${SUMMARY}${STATUS_NOTE}${OUTCOME_NOTE}. Next: ${NEXT_TASK}. Blocker: ${BLOCKER}."

# --- Idempotency: don't double-append the same cycle summary ---
if grep -qF "Cycle ${CYCLE}: ${SUMMARY}" "$PLAN"; then
  echo "Progress entry already exists. Skipping append."
else
  sedi "/^## Progress$/a\\
${PROGRESS_LINE}
" "$PLAN"
fi

# --- Commit (propagate failures — a failed commit means the checkpoint did not land) ---
git add "$PLAN"
if ! git commit -m "vidux: ${SUMMARY}"; then
  echo "Error: git commit failed — checkpoint not saved" >&2
  exit 1
fi

# --- emit ledger checkpoint event ------------------------------------------ #
if type vidux_emit_checkpoint &>/dev/null 2>&1; then
  _COMMIT_HASH=$(git -C "$PLAN_DIR" rev-parse HEAD 2>/dev/null || echo "")
  _PROJECT_NAME="$(basename "$PLAN_DIR")"
  vidux_emit_checkpoint "$_PROJECT_NAME" "$PLAN" "$_COMMIT_HASH" "$STATUS" 2>/dev/null || true
fi

echo "Checkpoint complete. Cycle ${CYCLE}: ${SUMMARY}${STATUS_NOTE}"
echo "Next: ${NEXT_TASK}"
[[ "$BLOCKER" != "none" ]] && echo "Blocker: ${BLOCKER}"
exit 0
