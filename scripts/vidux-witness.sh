#!/usr/bin/env bash
# vidux-witness.sh — lightweight read-only fleet health observer
#
# Modes:
#   bash vidux-witness.sh PLAN1 PLAN2 ...      # Observe specific plans
#   bash vidux-witness.sh --all                 # Auto-discover plans + automations
#   bash vidux-witness.sh --dir PATH            # Scan automation memory.md files
#
# Detects: stuck tasks (3+ cycles), mid-zone waste (3-8 min), handoff gaps,
#          stale branches, idle automations.
#
# Read-only: never modifies any file.
# Output: one JSON status line per plan/automation, then a fleet summary object.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- helpers ---------------------------------------------------------------- #
json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; s="${s//$'\t'/\\t}"; s="${s//$'\n'/\\n}"; s="${s//$'\r'/\\r}"
  printf '%s' "$s"
}

die() { echo "{\"error\": \"$1\"}" >&2; exit 1; }

# --- arg parsing ------------------------------------------------------------ #
PLANS=(); AUTO_DIR=""; ALL_MODE=false; IDLE_HOURS=4; STUCK_THRESHOLD=3

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)             ALL_MODE=true; shift ;;
    --dir)             AUTO_DIR="$2"; shift 2 ;;
    --idle-hours)      IDLE_HOURS="$2"; shift 2 ;;
    --stuck-threshold) STUCK_THRESHOLD="$2"; shift 2 ;;
    -*)                die "unknown flag: $1" ;;
    *)                 PLANS+=("$1"); shift ;;
  esac
done

# --- auto-discover plans in --all mode -------------------------------------- #
if [[ "$ALL_MODE" = true && ${#PLANS[@]} -eq 0 ]]; then
  # Look for PLAN.md in common project locations
  for d in "$HOME/Development"/*/PLAN.md \
           "$HOME/Development"/*/*/PLAN.md \
           "$SCRIPT_DIR/../projects"/*/PLAN.md; do
    [[ -f "$d" ]] && PLANS+=("$d")
  done
fi

# --- auto-discover automations directory ------------------------------------ #
if [[ -z "$AUTO_DIR" ]]; then
  for c in "$HOME/.codex/automations" \
           "$SCRIPT_DIR/../automations" \
           "./automations"; do
    [[ -d "$c" ]] && { AUTO_DIR="$c"; break; }
  done
fi

# Bail early if nothing to observe
if [[ ${#PLANS[@]} -eq 0 && ( -z "$AUTO_DIR" || ! -d "${AUTO_DIR:-}" ) ]]; then
  echo '{"error":"nothing to observe — pass plan paths, --all, or --dir PATH","plans":[],"automations":[],"fleet_grade":"F"}'
  exit 0
fi

# --- plan observation helpers ----------------------------------------------- #

# Count tasks by FSM state in a plan file (excludes Exit Criteria section)
_count_tasks() {
  local plan="$1" pattern="$2"
  local ec_start=0 ec_end=0
  if grep -q '^## Exit Criteria' "$plan" 2>/dev/null; then
    ec_start="$(grep -n '^## Exit Criteria' "$plan" | head -1 | cut -d: -f1)"
    ec_end="$(awk -v start="$ec_start" 'NR>start && /^## /{print NR; exit}' "$plan")"
    [[ -z "$ec_end" ]] && ec_end="$(( $(wc -l < "$plan" | tr -d ' ') + 1 ))"
  fi
  local lines count
  lines="$(grep -nE "$pattern" "$plan" 2>/dev/null || true)"
  [[ -z "$lines" ]] && { echo 0; return; }
  if [[ "$ec_start" -gt 0 ]]; then
    lines="$(printf '%s\n' "$lines" | while IFS= read -r l; do
      [[ -z "$l" ]] && continue
      local num="${l%%:*}"
      [[ "$num" -ge "$ec_start" && "$num" -lt "$ec_end" ]] && continue
      printf '%s\n' "$l"
    done)"
  fi
  [[ -z "$lines" ]] && { echo 0; return; }
  count="$(printf '%s\n' "$lines" | grep -c '.' 2>/dev/null || true)"
  echo "${count:-0}"
}

# Detect stuck tasks: same task appearing in 3+ Progress entries
_plan_stuck_tasks() {
  local plan="$1" threshold="$2"
  local prog_block stuck_names=""
  grep -q '^## Progress' "$plan" 2>/dev/null || { echo 0; return; }
  prog_block="$(awk '/^## Progress/{f=1; next} f && /^## /{f=0} f{print}' "$plan")"

  # Check each in_progress task against progress block
  local ip_tasks count=0
  ip_tasks="$(grep -E '^\- \[in_progress\] ' "$plan" 2>/dev/null || true)"
  [[ -z "$ip_tasks" ]] && { echo 0; return; }

  while IFS= read -r task_line; do
    [[ -z "$task_line" ]] && continue
    local desc
    desc="$(echo "$task_line" | sed -E 's/^- \[in_progress\] //' | head -c 40)"
    local hits
    hits="$(printf '%s\n' "$prog_block" | grep -cF "$desc" 2>/dev/null || true)"
    [[ "$hits" -ge "$threshold" ]] && count=$((count + 1))
  done <<< "$ip_tasks"
  echo "$count"
}

# Check git commit recency for a plan's project directory
_git_freshness() {
  local plan_dir="$1"
  local repo_root
  repo_root="$(git -C "$plan_dir" rev-parse --show-toplevel 2>/dev/null || echo "")"
  [[ -z "$repo_root" ]] && { echo "no_repo"; return; }

  # Count commits in last 24h
  local recent_commits
  recent_commits="$(git -C "$repo_root" log --since='24 hours ago' --oneline 2>/dev/null | wc -l | tr -d ' ')"

  # Last commit age in hours
  local last_ts now_epoch last_epoch age_hours
  last_ts="$(git -C "$repo_root" log -1 --format='%ct' 2>/dev/null || echo 0)"
  now_epoch="$(date +%s)"
  if [[ "$last_ts" -gt 0 ]]; then
    age_hours=$(( (now_epoch - last_ts) / 3600 ))
  else
    age_hours=999
  fi

  # Classify: active (<6h, 2+ commits), stale (>48h), normal
  if [[ "$age_hours" -gt 48 ]]; then
    echo "stale"
  elif [[ "$recent_commits" -ge 2 && "$age_hours" -lt 6 ]]; then
    echo "active"
  else
    echo "normal"
  fi
}

# --- automation memory helpers (preserved from v1) -------------------------- #

_extract_timestamp() {
  local line="$1" ts
  ts="$(echo "$line" | grep -oE '20[0-9]{2}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z' | head -1)"
  if [[ -n "$ts" ]]; then echo "$ts"; return; fi
  ts="$(echo "$line" | grep -oE '20[0-9]{2}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}' | head -1)"
  if [[ -n "$ts" ]]; then echo "${ts// /T}:00Z"; return; fi
  echo ""
}

_extract_runtime_minutes() {
  local rt
  rt="$(echo "$1" | grep -ioE 'runtime[=: ]+~?[0-9]+m' | head -1 | grep -oE '[0-9]+' | head -1)"
  echo "${rt:-0}"
}

_is_shipping() {
  echo "$1" | grep -qiE 'commit[: ]|shipped|deployed|merged|created|added|published|cut.*build|promoted|uploaded'
}

_detect_stuck_memory() {
  local file="$1" threshold="$2" entries count
  entries="$(grep '^- ' "$file" 2>/dev/null | tail -n "$threshold")"
  count="$(echo "$entries" | grep -c '^- ' || true)"
  [[ "$count" -lt "$threshold" ]] && { echo "false"; return; }
  local fingerprints=""
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local fp
    fp="$(echo "$line" | sed 's/^- [0-9T: ~(EDTPSTCSTMSTruntime]*//;s/^[^a-zA-Z]*//' | head -c 80 | tr '[:upper:]' '[:lower:]')"
    fingerprints="${fingerprints}${fp}"$'\n'
  done <<< "$entries"
  local unique
  unique="$(echo "$fingerprints" | grep -v '^$' | sort -u | wc -l | tr -d ' ')"
  [[ "$unique" -le 1 ]] && echo "true" || echo "false"
}

_classify_memory() {
  local mem_file="$1" idle_hours="$2" stuck_threshold="$3" last_entry ts
  last_entry="$(grep '^- ' "$mem_file" 2>/dev/null | tail -1)"
  [[ -z "$last_entry" ]] && { echo "IDLE"; return; }
  # IDLE check
  ts="$(_extract_timestamp "$last_entry")"
  if [[ -n "$ts" ]]; then
    local now_epoch entry_epoch
    now_epoch="$(date +%s 2>/dev/null)"
    entry_epoch="$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$ts" +%s 2>/dev/null || \
                   date -d "$ts" +%s 2>/dev/null || echo "0")"
    if [[ "$entry_epoch" -gt 0 && "$now_epoch" -gt 0 ]]; then
      local diff_hours=$(( (now_epoch - entry_epoch) / 3600 ))
      [[ "$diff_hours" -ge "$idle_hours" ]] && { echo "IDLE"; return; }
    fi
  fi
  # STUCK check
  [[ "$(_detect_stuck_memory "$mem_file" "$stuck_threshold")" = "true" ]] && { echo "STUCK"; return; }
  # SHIPPING check
  _is_shipping "$last_entry" && { echo "SHIPPING"; return; }
  # MID-ZONE check
  local rt; rt="$(_extract_runtime_minutes "$last_entry")"
  [[ "$rt" -ge 3 && "$rt" -le 8 ]] && { echo "MID-ZONE"; return; }
  echo "SHIPPING"
}

# --- ledger mid-zone check (optional) -------------------------------------- #
_LEDGER_LIB="$SCRIPT_DIR/lib/ledger-query.sh"
LEDGER_OK=false
if [[ -f "$_LEDGER_LIB" ]]; then
  source "$SCRIPT_DIR/lib/ledger-emit.sh" 2>/dev/null || true
  source "$_LEDGER_LIB" 2>/dev/null || true
  if type ledger_bimodal_distribution &>/dev/null 2>&1; then
    LEDGER_OK=true
  fi
fi

_ledger_mid_zone_count() {
  local repo="$1"
  [[ "$LEDGER_OK" = false ]] && { echo 0; return; }
  local result
  result="$(ledger_bimodal_distribution "$repo" 24 2>/dev/null || echo '{}')"
  printf '%s' "$result" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('totals',{}).get('mid',0))" 2>/dev/null || echo 0
}

# --- observe plans ---------------------------------------------------------- #
PLAN_ENTRIES=""; PLAN_FIRST=true
P_SHIPPING=0; P_STUCK=0; P_IDLE=0; P_BLOCKED=0; P_TOTAL=0

for plan in ${PLANS[@]+"${PLANS[@]}"}; do
  [[ -f "$plan" ]] || continue
  P_TOTAL=$((P_TOTAL + 1))
  plan_dir="$(cd "$(dirname "$plan")" && pwd)"
  project="$(basename "$plan_dir")"

  pending=$(_count_tasks "$plan" '^\- (\[ \]|\[pending\]) ')
  in_progress=$(_count_tasks "$plan" '^\- \[in_progress\] ')
  blocked=$(_count_tasks "$plan" '^\- \[blocked\] ')
  completed=$(_count_tasks "$plan" '^\- (\[x\]|\[completed\]) ')
  stuck=$(_plan_stuck_tasks "$plan" "$STUCK_THRESHOLD")
  git_health=$(_git_freshness "$plan_dir")

  # Ledger mid-zone (best-effort)
  mid_zone=0
  if [[ "$LEDGER_OK" = true ]]; then
    repo_name="$(basename "$(git -C "$plan_dir" rev-parse --show-toplevel 2>/dev/null || echo "$project")")"
    mid_zone=$(_ledger_mid_zone_count "$repo_name")
  fi

  # Classify plan health
  if [[ "$stuck" -gt 0 ]]; then
    status="STUCK"; P_STUCK=$((P_STUCK + 1))
  elif [[ "$pending" -eq 0 && "$in_progress" -eq 0 && "$blocked" -eq 0 ]]; then
    if [[ "$completed" -gt 0 ]]; then
      status="DONE"; P_SHIPPING=$((P_SHIPPING + 1))
    else
      status="EMPTY"; P_IDLE=$((P_IDLE + 1))
    fi
  elif [[ "$blocked" -gt 0 && "$pending" -eq 0 && "$in_progress" -eq 0 ]]; then
    status="ALL_BLOCKED"; P_BLOCKED=$((P_BLOCKED + 1))
  elif [[ "$git_health" = "stale" ]]; then
    status="STALE"; P_IDLE=$((P_IDLE + 1))
  elif [[ "$mid_zone" -ge 3 ]]; then
    status="MID-ZONE"; P_IDLE=$((P_IDLE + 1))
  else
    status="SHIPPING"; P_SHIPPING=$((P_SHIPPING + 1))
  fi

  entry="{\"type\":\"plan\",\"id\":\"$(json_escape "$project")\",\"plan\":\"$(json_escape "$plan")\",\"status\":\"$status\",\"pending\":$pending,\"in_progress\":$in_progress,\"blocked\":$blocked,\"completed\":$completed,\"stuck_tasks\":$stuck,\"git_health\":\"$git_health\",\"mid_zone_runs\":$mid_zone}"
  [[ "$PLAN_FIRST" = true ]] && { PLAN_ENTRIES="$entry"; PLAN_FIRST=false; } || PLAN_ENTRIES="$PLAN_ENTRIES,$entry"
done

# --- observe automations ---------------------------------------------------- #
AUTO_ENTRIES=""; AUTO_FIRST=true
A_SHIPPING=0; A_STUCK=0; A_IDLE=0; A_MID_ZONE=0; A_TOTAL=0

if [[ -n "${AUTO_DIR:-}" && -d "${AUTO_DIR:-}" ]]; then
  for auto_dir in "$AUTO_DIR"/*/; do
    [[ -d "$auto_dir" ]] || continue
    name="$(basename "$auto_dir")"; mem_file="$auto_dir/memory.md"
    A_TOTAL=$((A_TOTAL + 1))

    if [[ ! -f "$mem_file" ]]; then
      a_status="IDLE"; last_run=""; summary="no memory.md"
    else
      a_status="$(_classify_memory "$mem_file" "$IDLE_HOURS" "$STUCK_THRESHOLD")"
      local_last="$(grep '^- ' "$mem_file" 2>/dev/null | tail -1 || true)"
      last_run="$(_extract_timestamp "$local_last")"
      summary="$(json_escape "${local_last#- }")"
      [[ ${#summary} -gt 120 ]] && summary="${summary:0:120}..."
    fi

    case "$a_status" in
      SHIPPING) A_SHIPPING=$((A_SHIPPING + 1)) ;;
      STUCK)    A_STUCK=$((A_STUCK + 1)) ;;
      IDLE)     A_IDLE=$((A_IDLE + 1)) ;;
      MID-ZONE) A_MID_ZONE=$((A_MID_ZONE + 1)) ;;
    esac

    entry="{\"type\":\"automation\",\"id\":\"$(json_escape "$name")\",\"status\":\"$a_status\",\"last_run\":\"$last_run\",\"summary\":\"$summary\"}"
    [[ "$AUTO_FIRST" = true ]] && { AUTO_ENTRIES="$entry"; AUTO_FIRST=false; } || AUTO_ENTRIES="$AUTO_ENTRIES,$entry"
  done
fi

# --- fleet grade ------------------------------------------------------------ #
TOTAL=$((P_TOTAL + A_TOTAL))
SHIPPING=$((P_SHIPPING + A_SHIPPING))
STUCK_TOTAL=$((P_STUCK + A_STUCK))
IDLE_TOTAL=$((P_IDLE + A_IDLE + P_BLOCKED))

GRADE="F"
if [[ "$TOTAL" -gt 0 ]]; then
  SHIP_PCT=$((SHIPPING * 100 / TOTAL))
  IDLE_PCT=$((IDLE_TOTAL * 100 / TOTAL))
  if [[ "$SHIPPING" -eq 0 ]]; then GRADE="F"
  elif [[ "$STUCK_TOTAL" -ge 3 || "$IDLE_PCT" -gt 50 ]]; then GRADE="D"
  elif [[ "$SHIP_PCT" -gt 80 && "$STUCK_TOTAL" -eq 0 ]]; then GRADE="A"
  elif [[ "$SHIP_PCT" -gt 60 && "$STUCK_TOTAL" -le 1 ]]; then GRADE="B"
  elif [[ "$SHIP_PCT" -gt 40 && "$STUCK_TOTAL" -le 2 ]]; then GRADE="C"
  else GRADE="D"; fi
fi

# --- output ----------------------------------------------------------------- #
cat <<ENDJSON
{
  "plans": [${PLAN_ENTRIES}],
  "automations": [${AUTO_ENTRIES}],
  "fleet_grade": "$GRADE",
  "counts": {
    "total": $TOTAL,
    "shipping": $SHIPPING,
    "stuck": $STUCK_TOTAL,
    "idle": $IDLE_TOTAL,
    "mid_zone": $((A_MID_ZONE)),
    "plans_observed": $P_TOTAL,
    "automations_observed": $A_TOTAL
  },
  "ledger_available": $LEDGER_OK
}
ENDJSON
