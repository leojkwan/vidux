#!/usr/bin/env bash
# vidux-prune.sh — backpressure, pruning, and archival system
# Usage: bash vidux-prune.sh <subcommand> [flags]
#
# Subcommands:
#   plans       Archive completed tasks, compact decision log, check depth
#   worktrees   Discover, classify, and clean up stale git worktrees
#   ledger      Compact hot window, archive old entries
#   all         Run plans + worktrees + ledger + pressure in sequence
#   pressure    Calculate and report current pressure score
#
# Flags:
#   --simulate  Dry-run mode (show what would change, modify nothing)
#   --auto      Apply changes without prompting
#   --json      Output as JSON
set -euo pipefail

# --- defaults --------------------------------------------------------------- #
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VIDUX_ROOT="$SCRIPT_DIR/.."
CONFIG="$VIDUX_ROOT/vidux.config.json"
PROJECTS_DIR="$VIDUX_ROOT/projects"

SIMULATE=false; AUTO=false; JSON_MODE=false
ARCHIVE_THRESHOLD=50; DECISION_LOG_MAX_DAYS=180; MAX_NESTING=3
LEDGER_PATH="${AGENT_LEDGER_PATH:-$HOME/.agent-ledger/activity.jsonl}"
LEDGER_MAX_ENTRIES=1000; LEDGER_MAX_AGE_DAYS=7

# Read config overrides
if [ -f "$CONFIG" ]; then
  ARCHIVE_THRESHOLD=$(python3 -c "import json;print(json.load(open('$CONFIG')).get('defaults',{}).get('archive_threshold',50))" 2>/dev/null || echo 50)
fi

# --- parse args ------------------------------------------------------------- #
SUBCMD="${1:-}"; shift 2>/dev/null || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --simulate) SIMULATE=true; shift ;;
    --auto)     AUTO=true; shift ;;
    --json)     JSON_MODE=true; shift ;;
    *) echo "Unknown flag: $1" >&2; exit 2 ;;
  esac
done

[[ -z "$SUBCMD" ]] && { echo "Usage: vidux-prune.sh <plans|worktrees|ledger|all|pressure> [--simulate] [--auto] [--json]" >&2; exit 2; }

# --- helpers ---------------------------------------------------------------- #
json_escape() {
  local s="$1"; s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; s="${s//$'\t'/\\t}"; s="${s//$'\n'/\\n}"
  printf '%s' "$s"
}
sedi() { if [[ "$(uname)" == "Darwin" ]]; then sed -i '' "$@"; else sed -i "$@"; fi; }
_log() { [[ "$JSON_MODE" = false ]] && echo "  $1" || true; }
_now_epoch() { date +%s; }

# --- plans ------------------------------------------------------------------ #
prune_plans() {
  local results=() plan_files total_completed=0 total_archived=0
  local dl_old=0 depth_violations=0

  plan_files=("$PROJECTS_DIR"/*/PLAN.md)
  if [[ "${plan_files[0]}" == "$PROJECTS_DIR/*/PLAN.md" ]]; then
    plan_files=()
  fi

  for plan in "${plan_files[@]}"; do
    [[ -f "$plan" ]] || continue
    local proj_dir; proj_dir="$(dirname "$plan")"
    local proj_name; proj_name="$(basename "$proj_dir")"

    # Count completed tasks (v1 + v2)
    local completed; completed="$(grep -cE '^\- (\[x\]|\[completed\]) ' "$plan" || true)"
    total_completed=$((total_completed + completed))

    # Check nesting depth: count heading levels > MAX_NESTING
    local deep_headings; deep_headings="$(grep -cE "^#{$((MAX_NESTING + 1)),} " "$plan" || true)"
    if [[ "$deep_headings" -gt 0 ]]; then
      depth_violations=$((depth_violations + deep_headings))
      _log "depth: $proj_name has $deep_headings headings exceeding depth $MAX_NESTING"
    fi

    # Check decision log age
    if grep -q '^## Decision Log' "$plan" 2>/dev/null; then
      local dl_dates; dl_dates="$(awk '/^## Decision Log/{f=1;next} f&&/^## /{f=0} f{print}' "$plan" \
        | grep -oE '\[20[0-9]{2}-[0-9]{2}-[0-9]{2}\]' | tr -d '[]' | sort | head -1 || true)"
      if [[ -n "$dl_dates" ]]; then
        local oldest_epoch; oldest_epoch="$(date -j -f "%Y-%m-%d" "$dl_dates" "+%s" 2>/dev/null || date -d "$dl_dates" "+%s" 2>/dev/null || echo 0)"
        local now_epoch; now_epoch="$(_now_epoch)"
        local age_days=$(( (now_epoch - oldest_epoch) / 86400 ))
        if [[ "$age_days" -gt "$DECISION_LOG_MAX_DAYS" ]]; then
          dl_old=$((dl_old + 1))
          _log "decision-log: $proj_name has entries older than ${DECISION_LOG_MAX_DAYS}d ($age_days days)"
        fi
      fi
    fi

    # Archive if over threshold
    if [[ "$completed" -gt "$ARCHIVE_THRESHOLD" ]]; then
      local archive_file="$proj_dir/ARCHIVE.md"
      local to_archive=$((completed - ARCHIVE_THRESHOLD / 2))
      _log "plans: $proj_name has $completed completed tasks (threshold: $ARCHIVE_THRESHOLD), $to_archive candidates"

      if [[ "$AUTO" = true ]] && [[ "$SIMULATE" = false ]]; then
        # Move oldest completed tasks to ARCHIVE.md
        [[ -f "$archive_file" ]] || echo "# Archive" > "$archive_file"
        echo "" >> "$archive_file"
        echo "## Archived $(date +%Y-%m-%d)" >> "$archive_file"
        grep -E '^\- (\[x\]|\[completed\]) ' "$plan" | head -"$to_archive" >> "$archive_file"
        # Remove those lines from PLAN.md (delete first N matching lines)
        local count=0
        local tmpfile; tmpfile="$(mktemp)"
        while IFS= read -r line; do
          if [[ "$count" -lt "$to_archive" ]] && echo "$line" | grep -qE '^\- (\[x\]|\[completed\]) '; then
            count=$((count + 1))
          else
            echo "$line"
          fi
        done < "$plan" > "$tmpfile"
        mv "$tmpfile" "$plan"
        total_archived=$((total_archived + to_archive))
        _log "plans: archived $to_archive tasks from $proj_name"
      fi
    fi

    results+=("{\"project\":\"$proj_name\",\"completed\":$completed,\"depth_violations\":$deep_headings}")
  done

  if [[ "$JSON_MODE" = true ]]; then
    local projects_json; projects_json="$(printf '%s,' "${results[@]}" | sed 's/,$//')"
    printf '{"subcommand":"plans","simulate":%s,"total_completed":%d,"total_archived":%d,"decision_log_old":%d,"depth_violations":%d,"projects":[%s]}\n' \
      "$SIMULATE" "$total_completed" "$total_archived" "$dl_old" "$depth_violations" "$projects_json"
  else
    _log "plans: $total_completed completed across ${#plan_files[@]} plans, $total_archived archived, $dl_old stale decision logs, $depth_violations depth violations"
  fi
}

# --- worktrees -------------------------------------------------------------- #
prune_worktrees() {
  local wt_count=0 active=0 stale=0 orphaned=0
  local results=()
  local now_epoch; now_epoch="$(_now_epoch)"

  if ! command -v git &>/dev/null; then
    _log "worktrees: git not found"; return
  fi

  local porcelain; porcelain="$(git -C "$VIDUX_ROOT" worktree list --porcelain 2>/dev/null || true)"
  if [[ -z "$porcelain" ]]; then
    if [[ "$JSON_MODE" = true ]]; then
      echo '{"subcommand":"worktrees","simulate":'"$SIMULATE"',"count":0,"active":0,"stale":0,"orphaned":0,"worktrees":[]}'
    else
      _log "worktrees: no worktrees found"
    fi
    return
  fi

  local wt_path="" wt_branch="" wt_bare=false
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^worktree\ (.+) ]]; then
      # Process previous entry
      if [[ -n "$wt_path" ]] && [[ "$wt_bare" = false ]]; then
        _classify_worktree "$wt_path" "$wt_branch"
      fi
      wt_path="${BASH_REMATCH[1]}"; wt_branch=""; wt_bare=false
    elif [[ "$line" =~ ^branch\ (.+) ]]; then
      wt_branch="${BASH_REMATCH[1]}"
    elif [[ "$line" == "bare" ]]; then
      wt_bare=true
    fi
  done <<< "$porcelain"
  # Process last entry
  if [[ -n "$wt_path" ]] && [[ "$wt_bare" = false ]]; then
    _classify_worktree "$wt_path" "$wt_branch"
  fi

  if [[ "$JSON_MODE" = true ]]; then
    local wt_json; wt_json="$(printf '%s,' "${results[@]}" | sed 's/,$//')"
    printf '{"subcommand":"worktrees","simulate":%s,"count":%d,"active":%d,"stale":%d,"orphaned":%d,"worktrees":[%s]}\n' \
      "$SIMULATE" "$wt_count" "$active" "$stale" "$orphaned" "${wt_json:-}"
  else
    _log "worktrees: $wt_count total, $active active, $stale stale, $orphaned orphaned"
  fi
}

_classify_worktree() {
  local path="$1" branch="$2"
  wt_count=$((wt_count + 1))
  local class="active" age_hours=0

  # Determine age from most recent file modification in worktree
  local latest_mod=0
  if [[ -d "$path" ]]; then
    latest_mod="$(find "$path" -maxdepth 2 -type f -newer "$path/.git" -print0 2>/dev/null \
      | xargs -0 stat -f '%m' 2>/dev/null | sort -rn | head -1 || \
      stat -f '%m' "$path" 2>/dev/null || echo 0)"
    [[ -z "$latest_mod" ]] && latest_mod="$(stat -f '%m' "$path" 2>/dev/null || echo 0)"
  fi

  if [[ "$latest_mod" -gt 0 ]]; then
    age_hours=$(( (now_epoch - latest_mod) / 3600 ))
  fi

  if [[ "$age_hours" -lt 2 ]]; then
    class="active"; active=$((active + 1))
  elif [[ "$age_hours" -lt 24 ]]; then
    class="stale"; stale=$((stale + 1))
  else
    class="orphaned"; orphaned=$((orphaned + 1))
  fi

  local short_branch="${branch##refs/heads/}"
  _log "worktrees: $(basename "$path") [$class] age=${age_hours}h branch=$short_branch"

  if [[ "$AUTO" = true ]] && [[ "$SIMULATE" = false ]] && [[ "$class" != "active" ]]; then
    # Check if branch is merged before removing
    local merged=false
    if git -C "$VIDUX_ROOT" branch --merged main 2>/dev/null | grep -q "$short_branch"; then
      merged=true
    fi
    if [[ "$merged" = true ]]; then
      git -C "$VIDUX_ROOT" worktree remove "$path" --force 2>/dev/null && \
        _log "worktrees: removed $path (merged)" || \
        _log "worktrees: failed to remove $path"
    else
      _log "worktrees: skipping $path (unmerged branch: $short_branch)"
    fi
  fi

  results+=("{\"path\":\"$(json_escape "$path")\",\"branch\":\"$(json_escape "$short_branch")\",\"class\":\"$class\",\"age_hours\":$age_hours}")
}

# --- ledger ----------------------------------------------------------------- #
prune_ledger() {
  local entry_count=0 oldest_age_days=0 archive_candidates=0

  if [[ ! -f "$LEDGER_PATH" ]]; then
    if [[ "$JSON_MODE" = true ]]; then
      echo '{"subcommand":"ledger","simulate":'"$SIMULATE"',"path":"'"$(json_escape "$LEDGER_PATH")"'","exists":false,"entries":0}'
    else
      _log "ledger: $LEDGER_PATH not found"
    fi
    return
  fi

  entry_count="$(wc -l < "$LEDGER_PATH" | tr -d ' ')"

  # Find oldest entry timestamp
  local oldest_ts; oldest_ts="$(head -1 "$LEDGER_PATH" | python3 -c "import sys,json;print(json.load(sys.stdin).get('ts',''))" 2>/dev/null || true)"
  if [[ -n "$oldest_ts" ]]; then
    local oldest_epoch; oldest_epoch="$(date -j -f "%Y-%m-%dT%H:%M:%S" "${oldest_ts%%.*}" "+%s" 2>/dev/null || \
      date -d "${oldest_ts}" "+%s" 2>/dev/null || echo 0)"
    if [[ "$oldest_epoch" -gt 0 ]]; then
      local now_epoch; now_epoch="$(_now_epoch)"
      oldest_age_days=$(( (now_epoch - oldest_epoch) / 86400 ))
    fi
  fi

  local needs_compact=false
  if [[ "$entry_count" -gt "$LEDGER_MAX_ENTRIES" ]] || [[ "$oldest_age_days" -gt "$LEDGER_MAX_AGE_DAYS" ]]; then
    needs_compact=true
    archive_candidates=$((entry_count > LEDGER_MAX_ENTRIES ? entry_count - LEDGER_MAX_ENTRIES / 2 : entry_count / 2))
    _log "ledger: $entry_count entries, oldest ${oldest_age_days}d — $archive_candidates candidates for archival"

    if [[ "$AUTO" = true ]] && [[ "$SIMULATE" = false ]]; then
      local archive_dir; archive_dir="$(dirname "$LEDGER_PATH")/archive"
      mkdir -p "$archive_dir"
      local archive_file="$archive_dir/activity-$(date +%Y%m%d-%H%M%S).jsonl"
      head -"$archive_candidates" "$LEDGER_PATH" > "$archive_file"
      local tmpfile; tmpfile="$(mktemp)"
      tail -n +"$((archive_candidates + 1))" "$LEDGER_PATH" > "$tmpfile"
      mv "$tmpfile" "$LEDGER_PATH"
      _log "ledger: archived $archive_candidates entries to $archive_file"
    fi
  else
    _log "ledger: $entry_count entries, oldest ${oldest_age_days}d — within limits"
  fi

  if [[ "$JSON_MODE" = true ]]; then
    printf '{"subcommand":"ledger","simulate":%s,"path":"%s","exists":true,"entries":%d,"oldest_age_days":%d,"needs_compact":%s,"archive_candidates":%d}\n' \
      "$SIMULATE" "$(json_escape "$LEDGER_PATH")" "$entry_count" "$oldest_age_days" "$needs_compact" "$archive_candidates"
  fi
}

# --- pressure --------------------------------------------------------------- #
calc_pressure() {
  local score=0 signals=()

  # 1. Active agent processes
  local agent_procs; agent_procs="$(ps aux 2>/dev/null | grep -cE '(claude|codex|cursor)' || true)"
  agent_procs=$((agent_procs > 1 ? agent_procs - 1 : 0))  # subtract grep itself
  if [[ "$agent_procs" -gt 5 ]]; then
    score=$((score + 3)); signals+=("agents:$agent_procs(+3)")
  elif [[ "$agent_procs" -gt 2 ]]; then
    score=$((score + 1)); signals+=("agents:$agent_procs(+1)")
  else
    signals+=("agents:$agent_procs(+0)")
  fi

  # 2. Worktree count
  local wt_total; wt_total="$(git -C "$VIDUX_ROOT" worktree list 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
  if [[ "$wt_total" -gt 5 ]]; then
    score=$((score + 2)); signals+=("worktrees:$wt_total(+2)")
  elif [[ "$wt_total" -gt 3 ]]; then
    score=$((score + 1)); signals+=("worktrees:$wt_total(+1)")
  else
    signals+=("worktrees:$wt_total(+0)")
  fi

  # 3. Blocked tasks across all plans
  local blocked=0
  for plan in "$PROJECTS_DIR"/*/PLAN.md; do
    [[ -f "$plan" ]] || continue
    local b; b="$(grep -cE '^\- \[blocked\] ' "$plan" || true)"
    blocked=$((blocked + b))
  done
  if [[ "$blocked" -gt 3 ]]; then
    score=$((score + 3)); signals+=("blocked:$blocked(+3)")
  elif [[ "$blocked" -gt 0 ]]; then
    score=$((score + 1)); signals+=("blocked:$blocked(+1)")
  else
    signals+=("blocked:$blocked(+0)")
  fi

  # 4. Recent failures in ledger
  local recent_fails=0
  if [[ -f "$LEDGER_PATH" ]]; then
    recent_fails="$(tail -50 "$LEDGER_PATH" | grep -c '"status":"fail"' 2>/dev/null || true)"
  fi
  if [[ "$recent_fails" -gt 5 ]]; then
    score=$((score + 2)); signals+=("recent_fails:$recent_fails(+2)")
  elif [[ "$recent_fails" -gt 0 ]]; then
    score=$((score + 1)); signals+=("recent_fails:$recent_fails(+1)")
  else
    signals+=("recent_fails:$recent_fails(+0)")
  fi

  # Clamp to 10
  [[ "$score" -gt 10 ]] && score=10

  local level="normal"
  if [[ "$score" -ge 8 ]]; then level="critical"
  elif [[ "$score" -ge 5 ]]; then level="warning"
  fi

  local signals_str; signals_str="$(IFS=','; echo "${signals[*]}")"

  if [[ "$JSON_MODE" = true ]]; then
    printf '{"subcommand":"pressure","score":%d,"level":"%s","signals":"%s"}\n' \
      "$score" "$level" "$(json_escape "$signals_str")"
  else
    _log "pressure: score=$score/10 level=$level"
    _log "  signals: $signals_str"
  fi
}

# --- all -------------------------------------------------------------------- #
run_all() {
  if [[ "$JSON_MODE" = true ]]; then
    local p w l s
    p="$(SIMULATE=$SIMULATE AUTO=$AUTO JSON_MODE=true prune_plans)"
    w="$(SIMULATE=$SIMULATE AUTO=$AUTO JSON_MODE=true prune_worktrees)"
    l="$(SIMULATE=$SIMULATE AUTO=$AUTO JSON_MODE=true prune_ledger)"
    s="$(SIMULATE=$SIMULATE AUTO=$AUTO JSON_MODE=true calc_pressure)"
    printf '{"subcommand":"all","simulate":%s,"plans":%s,"worktrees":%s,"ledger":%s,"pressure":%s}\n' \
      "$SIMULATE" "$p" "$w" "$l" "$s"
  else
    _log "=== vidux-prune: all ==="
    _log ""
    prune_plans
    _log ""
    prune_worktrees
    _log ""
    prune_ledger
    _log ""
    calc_pressure
  fi
}

# --- dispatch --------------------------------------------------------------- #
case "$SUBCMD" in
  plans)    prune_plans ;;
  worktrees) prune_worktrees ;;
  ledger)   prune_ledger ;;
  pressure) calc_pressure ;;
  all)      run_all ;;
  *) echo "Unknown subcommand: $SUBCMD" >&2; echo "Usage: vidux-prune.sh <plans|worktrees|ledger|all|pressure> [--simulate] [--auto] [--json]" >&2; exit 2 ;;
esac
