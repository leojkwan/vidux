#!/usr/bin/env bash
# vidux-witness.sh — lightweight read-only fleet health witness
# Usage:  bash vidux-witness.sh [--dir PATH] [--idle-hours N] [--stuck-threshold N]
#
# Reads automation memory.md files, classifies each automation's health,
# and writes a fleet-status summary as JSON to stdout.
#
# Statuses: SHIPPING | STUCK | IDLE | MID-ZONE
# Read-only: never modifies any file.
set -euo pipefail

AUTOMATIONS_DIR=""; IDLE_HOURS=4; STUCK_THRESHOLD=3

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)             AUTOMATIONS_DIR="$2"; shift 2 ;;
    --idle-hours)      IDLE_HOURS="$2"; shift 2 ;;
    --stuck-threshold) STUCK_THRESHOLD="$2"; shift 2 ;;
    *)                 echo '{"error":"unknown argument: '"$1"'"}'; exit 2 ;;
  esac
done

# Auto-discover automations directory
if [[ -z "$AUTOMATIONS_DIR" ]]; then
  for c in "$HOME/.codex/automations" \
           "$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)/automations" \
           "./automations"; do
    [[ -d "$c" ]] && { AUTOMATIONS_DIR="$c"; break; }
  done
fi
if [[ -z "$AUTOMATIONS_DIR" ]] || [[ ! -d "$AUTOMATIONS_DIR" ]]; then
  echo '{"error":"no automations directory found","automations":[],"fleet_grade":"F"}'
  exit 0
fi

# --- helpers ---------------------------------------------------------------- #
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

_detect_stuck() {
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

_classify() {
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
  [[ "$(_detect_stuck "$mem_file" "$stuck_threshold")" = "true" ]] && { echo "STUCK"; return; }
  # SHIPPING check
  _is_shipping "$last_entry" && { echo "SHIPPING"; return; }
  # MID-ZONE check
  local rt; rt="$(_extract_runtime_minutes "$last_entry")"
  [[ "$rt" -ge 3 && "$rt" -le 8 ]] && { echo "MID-ZONE"; return; }
  echo "SHIPPING"
}

_json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; s="${s//$'\n'/\\n}"; s="${s//$'\r'/}"; s="${s//$'\t'/\\t}"
  echo "$s"
}

_truncate() {
  local s="$1" m="${2:-120}"
  [[ "${#s}" -gt "$m" ]] && echo "${s:0:$m}..." || echo "$s"
}

# --- main scan -------------------------------------------------------------- #
AUTOS=""; FIRST=true
SHIPPING=0; STUCK=0; IDLE=0; MID_ZONE=0; TOTAL=0

for auto_dir in "$AUTOMATIONS_DIR"/*/; do
  [[ -d "$auto_dir" ]] || continue
  name="$(basename "$auto_dir")"; mem_file="$auto_dir/memory.md"
  TOTAL=$((TOTAL + 1))

  if [[ ! -f "$mem_file" ]]; then
    status="IDLE"; last_run=""; summary="no memory.md"
  else
    status="$(_classify "$mem_file" "$IDLE_HOURS" "$STUCK_THRESHOLD")"
    local_last="$(grep '^- ' "$mem_file" 2>/dev/null | tail -1 || true)"
    last_run="$(_extract_timestamp "$local_last")"
    summary="$(_truncate "$(_json_escape "$local_last")" 120)"
    summary="${summary#- }"
  fi

  case "$status" in
    SHIPPING) SHIPPING=$((SHIPPING + 1)) ;;
    STUCK)    STUCK=$((STUCK + 1)) ;;
    IDLE)     IDLE=$((IDLE + 1)) ;;
    MID-ZONE) MID_ZONE=$((MID_ZONE + 1)) ;;
  esac

  entry="{\"id\":\"$(_json_escape "$name")\",\"status\":\"$status\",\"last_run\":\"$last_run\",\"summary\":\"$summary\"}"
  [[ "$FIRST" = true ]] && { AUTOS="$entry"; FIRST=false; } || AUTOS="$AUTOS,$entry"
done

# --- fleet grade ------------------------------------------------------------ #
# A=>80% ship 0 stuck, B=>60% <=1, C=>40% <=2, D=>=3 stuck or >50% idle, F=0 ship
GRADE="F"
if [[ "$TOTAL" -gt 0 ]]; then
  SHIP_PCT=$((SHIPPING * 100 / TOTAL)); IDLE_PCT=$((IDLE * 100 / TOTAL))
  if [[ "$SHIPPING" -eq 0 ]]; then GRADE="F"
  elif [[ "$STUCK" -ge 3 || "$IDLE_PCT" -gt 50 ]]; then GRADE="D"
  elif [[ "$SHIP_PCT" -gt 80 && "$STUCK" -eq 0 ]]; then GRADE="A"
  elif [[ "$SHIP_PCT" -gt 60 && "$STUCK" -le 1 ]]; then GRADE="B"
  elif [[ "$SHIP_PCT" -gt 40 && "$STUCK" -le 2 ]]; then GRADE="C"
  else GRADE="D"; fi
fi

echo "{\"automations\":[$AUTOS],\"fleet_grade\":\"$GRADE\",\"counts\":{\"total\":$TOTAL,\"shipping\":$SHIPPING,\"stuck\":$STUCK,\"idle\":$IDLE,\"mid_zone\":$MID_ZONE}}"
