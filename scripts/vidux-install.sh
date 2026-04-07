#!/usr/bin/env bash
set -euo pipefail

# vidux-install.sh — Install, upgrade, verify, and diagnose Vidux across machines.
#
# Usage:
#   vidux-install.sh install   — first-time setup (symlinks, hooks, config)
#   vidux-install.sh upgrade   — git pull + re-verify + re-install hooks if changed
#   vidux-install.sh version   — print version, git hash, sync status
#   vidux-install.sh doctor    — full health check (PASS/FAIL for each probe)
#
# All operations are idempotent. Safe to re-run.

# ── Colors (match bootstrap.sh) ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

ok()   { echo -e "  ${GREEN}✓${RESET} $*"; }
warn() { echo -e "  ${YELLOW}!${RESET} $*"; }
fail() { echo -e "  ${RED}✗${RESET} $*"; }
info() { echo -e "  ${DIM}$*${RESET}"; }

# ── Locate the repo (works regardless of clone path) ──
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VIDUX_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO="$VIDUX_ROOT"

VERSION_FILE="$VIDUX_ROOT/VERSION"
CONFIG_FILE="$VIDUX_ROOT/vidux.config.json"
HOOKS_JSON="$VIDUX_ROOT/hooks/hooks.json"

# ── Helpers ──

read_version() {
  if [[ -f "$VERSION_FILE" ]]; then
    head -1 "$VERSION_FILE"
  else
    echo "unknown"
  fi
}

ensure_repo() {
  if [[ ! -d "$REPO/.git" ]]; then
    fail "Not a git repo: $REPO"
    echo "  Expected this Vidux directory to be a git checkout."
    exit 1
  fi
}

# Resolve the real path of a file/dir, following all symlinks.
resolve_real() { python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$1" 2>/dev/null; }

# Check if vidux is reachable at a path — either via direct symlink or
# via a parent-level symlink (e.g. ~/.codex/skills -> /path/to/skills
# which makes vidux accessible at ~/.codex/skills/vidux as a subdirectory).
vidux_reachable() {
  local link="$1"
  local target="$2"

  if [[ ! -e "$link" ]]; then
    return 1
  fi

  local real_link real_target
  real_link="$(resolve_real "$link")"
  real_target="$(resolve_real "$target")"

  [[ "$real_link" == "$real_target" ]]
}

# Create or fix a symlink. Returns 0 on success.
# Handles the parent-level symlink pattern: if the parent dir is already
# symlinked such that vidux is reachable, skip creating a nested symlink.
ensure_symlink() {
  local target="$1"  # what the link points TO (e.g. .../skills/vidux)
  local link="$2"    # where the link lives (e.g. ~/.codex/skills/vidux)
  local label="$3"   # display name

  # Already reachable (direct symlink OR parent-level symlink)?
  if vidux_reachable "$link" "$target"; then
    if [[ -L "$link" ]]; then
      ok "$label (direct symlink)"
    else
      ok "$label (via parent symlink)"
    fi
    return 0
  fi

  local parent
  parent="$(dirname "$link")"
  mkdir -p "$parent"

  if [[ -L "$link" ]]; then
    # Symlink exists but points to wrong target
    rm -f "$link"
    ln -sf "$target" "$link"
    ok "$label (fixed -> $target)"
    return 0
  elif [[ -e "$link" ]]; then
    warn "$label exists but does not resolve to vidux — manual cleanup needed"
    return 1
  else
    ln -sf "$target" "$link"
    ok "$label (created)"
    return 0
  fi
}

# Check if a symlink is valid. Returns 0 if correct, 1 if broken/missing.
# Accepts both direct symlinks and parent-level symlinks that make vidux reachable.
check_symlink() {
  local target="$1"
  local link="$2"
  local label="$3"

  if vidux_reachable "$link" "$target"; then
    if [[ -L "$link" ]]; then
      ok "$label (direct symlink)"
    else
      ok "$label (via parent symlink)"
    fi
    return 0
  elif [[ -e "$link" ]]; then
    fail "$label exists but does not resolve to vidux"
    return 1
  else
    fail "$label missing"
    return 1
  fi
}

# Merge vidux hooks into ~/.claude/settings.json
install_hooks_to_settings() {
  local settings="$HOME/.claude/settings.json"
  local install_hooks_script="$VIDUX_ROOT/scripts/install-hooks.sh"

  if [[ ! -f "$HOOKS_JSON" ]]; then
    warn "hooks/hooks.json not found — skipping hook install"
    return 1
  fi

  # The install-hooks.sh script handles the actual hook installation
  # into per-project settings. For global Claude settings, we verify
  # the compaction hooks from SETUP_NEW_MACHINE.md are present.
  mkdir -p "$HOME/.claude"

  if [[ ! -f "$settings" ]]; then
    # Create minimal settings with compaction hooks
    cat > "$settings" <<'SETTINGS'
{
  "env": {
    "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "50",
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "hooks": {
    "PreCompact": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Compaction imminent. Critical context should already be in files (PLAN.md, .agent-ledger/). If working in a loop, ensure current iteration state is checkpointed to disk before compaction summarizes conversation history.'"
          }
        ]
      }
    ],
    "PostCompact": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Context compacted. Rehydrate from repo files: PLAN.md, CLAUDE.md, .agent-ledger/activity.jsonl. Do not rely on pre-compaction conversation details — they are lossy summaries now.'"
          }
        ]
      }
    ]
  }
}
SETTINGS
    ok "Created ~/.claude/settings.json with compaction hooks"
    return 0
  fi

  # Settings file exists — verify compaction hooks are present
  if ! command -v jq &>/dev/null; then
    warn "jq not found — cannot verify hooks in settings.json"
    return 1
  fi

  local has_precompact has_postcompact
  has_precompact=$(jq -r '.hooks.PreCompact // empty' "$settings" 2>/dev/null)
  has_postcompact=$(jq -r '.hooks.PostCompact // empty' "$settings" 2>/dev/null)

  if [[ -n "$has_precompact" && -n "$has_postcompact" ]]; then
    ok "Compaction hooks present in ~/.claude/settings.json"
  else
    # Merge compaction hooks into existing settings
    local tmp
    tmp=$(mktemp)
    jq '
      .env["CLAUDE_AUTOCOMPACT_PCT_OVERRIDE"] //= "50" |
      .env["CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS"] //= "1" |
      .hooks.PreCompact //= [{"matcher":"","hooks":[{"type":"command","command":"echo '\''Compaction imminent. Critical context should already be in files (PLAN.md, .agent-ledger/).'\''"}]}] |
      .hooks.PostCompact //= [{"matcher":"","hooks":[{"type":"command","command":"echo '\''Context compacted. Rehydrate from repo files: PLAN.md, CLAUDE.md, .agent-ledger/activity.jsonl.'\''"}]}]
    ' "$settings" > "$tmp" 2>/dev/null && mv "$tmp" "$settings"
    ok "Merged compaction hooks into ~/.claude/settings.json"
  fi
  return 0
}

# Check if hooks.json has changed since last install (by comparing git hash)
hooks_changed_since_last() {
  local marker="$VIDUX_ROOT/.hooks_installed_hash"
  local current_hash
  current_hash=$(cd "$REPO" && git log -1 --format=%H -- hooks/hooks.json 2>/dev/null || echo "none")

  if [[ -f "$marker" ]] && [[ "$(cat "$marker")" == "$current_hash" ]]; then
    return 1  # not changed
  fi
  return 0  # changed (or first run)
}

mark_hooks_installed() {
  local marker="$VIDUX_ROOT/.hooks_installed_hash"
  local current_hash
  current_hash=$(cd "$REPO" && git log -1 --format=%H -- hooks/hooks.json 2>/dev/null || echo "none")
  echo "$current_hash" > "$marker"
}

# ── Commands ──

cmd_install() {
  echo ""
  echo -e "${CYAN}${BOLD}  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${RESET}"
  echo -e "${CYAN}${BOLD}  ┃          Vidux Install                          ┃${RESET}"
  echo -e "${CYAN}${BOLD}  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${RESET}"
  echo ""
  echo -e "  Repo:    ${BOLD}$REPO${RESET}"
  echo -e "  Host:    ${BOLD}$(hostname -s)${RESET}"
  echo -e "  Version: ${BOLD}$(read_version)${RESET}"
  echo ""

  local errors=0

  # 1. Verify repo
  echo -e "${BOLD}== 1. Verify repo ==${RESET}"
  ensure_repo
  ok "Git repo at $REPO"
  echo ""

  # 2. Create symlinks
  echo -e "${BOLD}== 2. Symlinks ==${RESET}"
  ensure_symlink "$VIDUX_ROOT" "$HOME/.codex/skills/vidux" "codex/skills/vidux" || ((errors++)) || true
  ensure_symlink "$VIDUX_ROOT" "$HOME/.cursor/skills/vidux" "cursor/skills/vidux" || ((errors++)) || true
  ensure_symlink "$VIDUX_ROOT" "$HOME/.claude/skills/vidux" "claude/skills/vidux" || ((errors++)) || true
  echo ""

  # 3. Install hooks
  echo -e "${BOLD}== 3. Hooks ==${RESET}"
  install_hooks_to_settings || ((errors++)) || true
  mark_hooks_installed
  echo ""

  # 4. Verify config
  echo -e "${BOLD}== 4. Config ==${RESET}"
  if [[ -f "$CONFIG_FILE" ]]; then
    if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$CONFIG_FILE" 2>/dev/null; then
      ok "vidux.config.json valid"
    else
      fail "vidux.config.json is not valid JSON"
      ((errors++)) || true
    fi
  else
    fail "vidux.config.json not found"
    ((errors++)) || true
  fi
  echo ""

  # 5. Verify scripts are executable
  echo -e "${BOLD}== 5. Scripts ==${RESET}"
  for script in vidux-install.sh vidux-loop.sh vidux-checkpoint.sh vidux-gather.sh install-hooks.sh; do
    local spath="$VIDUX_ROOT/scripts/$script"
    if [[ -f "$spath" ]]; then
      if [[ ! -x "$spath" ]]; then
        chmod +x "$spath"
        ok "$script (fixed permissions)"
      else
        ok "$script"
      fi
    else
      info "$script not found (optional)"
    fi
  done
  echo ""

  # Summary
  echo -e "${CYAN}${BOLD}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  if [[ "$errors" -eq 0 ]]; then
    echo -e "  ${GREEN}${BOLD}Install complete — Vidux $(read_version)${RESET}"
  else
    echo -e "  ${YELLOW}${BOLD}Install complete — $errors warning(s)${RESET}"
  fi
  echo -e "${CYAN}${BOLD}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo ""
  echo -e "  ${BOLD}Next steps:${RESET}"
  echo -e "    Verify:  ${DIM}bash $SCRIPT_DIR/vidux-install.sh doctor${RESET}"
  echo -e "    Use:     ${DIM}/vidux in Claude Code${RESET}"
  echo ""
}

cmd_upgrade() {
  echo ""
  echo -e "${CYAN}${BOLD}  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${RESET}"
  echo -e "${CYAN}${BOLD}  ┃          Vidux Upgrade                          ┃${RESET}"
  echo -e "${CYAN}${BOLD}  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${RESET}"
  echo ""

  local old_version
  old_version="$(read_version)"
  echo -e "  Current:  ${BOLD}$old_version${RESET}"
  echo ""

  local errors=0

  # 1. Pull latest
  echo -e "${BOLD}== 1. Pull latest ==${RESET}"
  ensure_repo
  cd "$REPO"
  if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
    warn "Dirty tree — skipping pull (commit or stash first)"
  else
    git fetch origin 2>/dev/null || true
    if git diff --quiet HEAD origin/main 2>/dev/null; then
      ok "Already up to date"
    else
      git pull --rebase origin main
      ok "Pulled latest changes"
    fi
  fi
  echo ""

  local new_version
  new_version="$(read_version)"

  # 2. What's new (changelog between versions)
  echo -e "${BOLD}== 2. What's new ==${RESET}"
  if [[ "$old_version" != "$new_version" ]]; then
    ok "Upgraded: $old_version -> $new_version"
    # Show commits that touched vidux since the old version tag
    local changelog
    changelog=$(cd "$REPO" && git log --oneline --since="7 days ago" -- . 2>/dev/null | head -10)
    if [[ -n "$changelog" ]]; then
      echo -e "  ${DIM}Recent changes:${RESET}"
      echo "$changelog" | while read -r line; do
        echo -e "    ${DIM}$line${RESET}"
      done
    fi
  else
    ok "Version unchanged: $new_version"
  fi
  echo ""

  # 3. Clean stale siblings
  echo -e "${BOLD}== 3. Clean stale siblings ==${RESET}"
  local cleaned=0
  for stale_name in vidux_v1 vidux-v1 vidux_v2 vidux-v2; do
    local stale_path="$REPO/$stale_name"
    if [[ -e "$stale_path" ]]; then
      rm -rf "$stale_path"
        ok "Removed stale: $stale_name"
      ((cleaned++)) || true
    fi
  done
  if [[ "$cleaned" -eq 0 ]]; then
    ok "No stale siblings found"
  fi
  echo ""

  # 4. Re-verify symlinks
  echo -e "${BOLD}== 4. Verify symlinks ==${RESET}"
  ensure_symlink "$VIDUX_ROOT" "$HOME/.codex/skills/vidux" "codex/skills/vidux" || ((errors++)) || true
  ensure_symlink "$VIDUX_ROOT" "$HOME/.cursor/skills/vidux" "cursor/skills/vidux" || ((errors++)) || true
  ensure_symlink "$VIDUX_ROOT" "$HOME/.claude/skills/vidux" "claude/skills/vidux" || ((errors++)) || true
  echo ""

  # 5. Re-install hooks if changed
  echo -e "${BOLD}== 5. Hooks ==${RESET}"
  if hooks_changed_since_last; then
    install_hooks_to_settings || ((errors++)) || true
    mark_hooks_installed
    ok "Hooks updated"
  else
    ok "Hooks unchanged since last install"
  fi
  echo ""

  # 6. Codex agents
  echo -e "${BOLD}== 6. Codex agents ==${RESET}"
  local agents_dir="$REPO/.codex/agents"
  if [[ -d "$agents_dir" ]]; then
    local agent_count
    agent_count=$(ls "$agents_dir"/vidux-*.toml 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$agent_count" -gt 0 ]]; then
      ok "$agent_count Codex agent definition(s) found"
    else
      info "No vidux-*.toml agents found in .codex/agents/"
    fi
  else
    info "No .codex/agents/ directory (Codex subagents not configured)"
  fi
  echo ""

  # 7. Run contract tests
  echo -e "${BOLD}== 7. Contract tests ==${RESET}"
  local test_dir="$VIDUX_ROOT/tests"
  if [[ -d "$test_dir" ]] && ls "$test_dir"/test_*.py &>/dev/null; then
    if python3 -m unittest discover -s "$test_dir" -p 'test_*.py' -q 2>&1; then
      ok "Contract tests passed"
    else
      fail "Contract tests failed"
      ((errors++)) || true
    fi
  else
    info "No contract tests found"
  fi
  echo ""

  # Summary
  echo -e "${CYAN}${BOLD}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  if [[ "$errors" -eq 0 ]]; then
    echo -e "  ${GREEN}${BOLD}Upgrade complete — Vidux $new_version${RESET}"
  else
    echo -e "  ${YELLOW}${BOLD}Upgrade complete — $errors warning(s)${RESET}"
  fi
  echo -e "${CYAN}${BOLD}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo ""

  # Doctrines summary
  local doctrine_count
  doctrine_count=$(grep -c '^### [0-9]\+\.' "$VIDUX_ROOT/SKILL.md" 2>/dev/null || echo "?")
  echo -e "  ${BOLD}Vidux $new_version${RESET} — $doctrine_count doctrines"
  echo -e "  ${DIM}Run 'vidux-install.sh doctor' for full health check${RESET}"
  echo ""
}

cmd_version() {
  local version
  version="$(read_version)"

  local git_hash="unknown"
  local sync_status="unknown"

  if [[ -d "$REPO/.git" ]]; then
    git_hash=$(cd "$REPO" && git log -1 --format=%h -- . 2>/dev/null || echo "unknown")

    cd "$REPO"
    git fetch origin 2>/dev/null || true
    local local_hash remote_hash
    local_hash=$(git log -1 --format=%H -- . 2>/dev/null || echo "none")
    remote_hash=$(git log -1 --format=%H origin/main -- . 2>/dev/null || echo "none")

    if [[ "$local_hash" == "$remote_hash" ]]; then
      sync_status="up-to-date"
    elif git merge-base --is-ancestor "$remote_hash" "$local_hash" 2>/dev/null; then
      sync_status="local is AHEAD of origin"
    elif git merge-base --is-ancestor "$local_hash" "$remote_hash" 2>/dev/null; then
      sync_status="local is BEHIND origin (run: vidux-install.sh upgrade)"
    else
      sync_status="diverged"
    fi
  fi

  echo ""
  echo -e "  ${BOLD}Vidux${RESET} $version"
  echo -e "  ${DIM}Commit:${RESET} $git_hash"
  echo -e "  ${DIM}Sync:${RESET}   $sync_status"
  echo -e "  ${DIM}Repo:${RESET}   $REPO"
  echo -e "  ${DIM}Host:${RESET}   $(hostname -s)"
  echo ""
}

cmd_doctor() {
  echo ""
  echo -e "${CYAN}${BOLD}  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${RESET}"
  echo -e "${CYAN}${BOLD}  ┃          Vidux Doctor                           ┃${RESET}"
  echo -e "${CYAN}${BOLD}  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${RESET}"
  echo ""
  echo -e "  Version: ${BOLD}$(read_version)${RESET}"
  echo -e "  Host:    ${BOLD}$(hostname -s)${RESET}"
  echo ""

  local pass=0
  local total=0

  # 1. Symlinks
  echo -e "${BOLD}== Symlinks ==${RESET}"

  ((total++)) || true
  if check_symlink "$VIDUX_ROOT" "$HOME/.codex/skills/vidux" "codex/skills/vidux"; then
    ((pass++)) || true
  fi

  ((total++)) || true
  if check_symlink "$VIDUX_ROOT" "$HOME/.cursor/skills/vidux" "cursor/skills/vidux"; then
    ((pass++)) || true
  fi

  ((total++)) || true
  if check_symlink "$VIDUX_ROOT" "$HOME/.claude/skills/vidux" "claude/skills/vidux"; then
    ((pass++)) || true
  fi
  echo ""

  # 2. Hooks installed
  echo -e "${BOLD}== Hooks ==${RESET}"
  ((total++)) || true
  if [[ -f "$HOME/.claude/settings.json" ]]; then
    if command -v jq &>/dev/null; then
      local has_precompact has_postcompact
      has_precompact=$(jq -r '.hooks.PreCompact // empty' "$HOME/.claude/settings.json" 2>/dev/null)
      has_postcompact=$(jq -r '.hooks.PostCompact // empty' "$HOME/.claude/settings.json" 2>/dev/null)
      if [[ -n "$has_precompact" && -n "$has_postcompact" ]]; then
        ok "Compaction hooks in settings.json"
        ((pass++)) || true
      else
        fail "Compaction hooks missing from settings.json"
      fi
    else
      warn "jq not available — cannot verify hooks"
    fi
  else
    fail "~/.claude/settings.json not found"
  fi

  ((total++)) || true
  if [[ -f "$HOOKS_JSON" ]]; then
    ok "hooks/hooks.json exists"
    ((pass++)) || true
  else
    fail "hooks/hooks.json missing"
  fi
  echo ""

  # 3. Config
  echo -e "${BOLD}== Config ==${RESET}"
  ((total++)) || true
  if [[ -f "$CONFIG_FILE" ]]; then
    if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$CONFIG_FILE" 2>/dev/null; then
      ok "vidux.config.json valid JSON"
      ((pass++)) || true
    else
      fail "vidux.config.json is not valid JSON"
    fi
  else
    fail "vidux.config.json not found"
  fi
  echo ""

  # 4. Merge conflict markers
  echo -e "${BOLD}== Merge conflicts ==${RESET}"
  ((total++)) || true
  local conflict_files
  conflict_files=$(cd "$VIDUX_ROOT" && grep -rlE '^(<{7}|>{7}|={7})' --include='*.md' --include='*.json' --include='*.sh' --include='*.py' . 2>/dev/null || true)
  if [[ -z "$conflict_files" ]]; then
    ok "No merge conflict markers"
    ((pass++)) || true
  else
    fail "Merge conflict markers found in:"
    echo "$conflict_files" | while read -r f; do
      echo "       $f"
    done
  fi
  echo ""

  # 5. Stale sibling directories
  echo -e "${BOLD}== Stale siblings ==${RESET}"
  ((total++)) || true
  local stale_found=false
  for stale_name in vidux_v1 vidux-v1 vidux_v2 vidux-v2; do
    local stale_path="$REPO/skills/$stale_name"
    if [[ -e "$stale_path" ]]; then
      fail "Stale directory: skills/$stale_name"
      stale_found=true
    fi
  done
  if [[ "$stale_found" == "false" ]]; then
    ok "No stale vidux sibling directories"
    ((pass++)) || true
  fi
  echo ""

  # 6. VERSION file
  echo -e "${BOLD}== VERSION ==${RESET}"
  ((total++)) || true
  if [[ -f "$VERSION_FILE" ]]; then
    local ver
    ver=$(head -1 "$VERSION_FILE")
    if [[ "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      ok "VERSION file: $ver"
      ((pass++)) || true
    else
      fail "VERSION file first line is not semver: $ver"
    fi
  else
    fail "VERSION file missing"
  fi
  echo ""

  # 7. Codex agents
  echo -e "${BOLD}== Codex agents ==${RESET}"
  ((total++)) || true
  local agents_dir="$REPO/.codex/agents"
  if [[ -d "$agents_dir" ]]; then
    local agent_count
    agent_count=$(ls "$agents_dir"/vidux-*.toml 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$agent_count" -gt 0 ]]; then
      ok "$agent_count vidux agent definition(s) in .codex/agents/"
      ((pass++)) || true
    else
      info "No vidux-*.toml agents (optional)"
      ((pass++)) || true
    fi
  else
    info "No .codex/agents/ directory (optional)"
    ((pass++)) || true
  fi
  echo ""

  # 8. Core files
  echo -e "${BOLD}== Core files ==${RESET}"
  for corefile in SKILL.md LOOP.md DOCTRINE.md ENFORCEMENT.md; do
    ((total++)) || true
    if [[ -f "$VIDUX_ROOT/$corefile" ]]; then
      ok "$corefile"
      ((pass++)) || true
    else
      fail "$corefile missing"
    fi
  done
  echo ""

  # Summary
  echo -e "${CYAN}${BOLD}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  if [[ "$pass" -eq "$total" ]]; then
    echo -e "  ${GREEN}${BOLD}PASS  $pass/$total checks${RESET}"
  else
    local failed=$((total - pass))
    echo -e "  ${YELLOW}${BOLD}FAIL  $pass/$total checks ($failed failed)${RESET}"
  fi
  echo -e "${CYAN}${BOLD}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo ""

  [[ "$pass" -eq "$total" ]] && return 0 || return 1
}

# ── Main dispatch ──

CMD="${1:-}"

case "$CMD" in
  install)  cmd_install ;;
  upgrade)  cmd_upgrade ;;
  version)  cmd_version ;;
  doctor)   cmd_doctor ;;
  *)
    echo ""
    echo "Usage: vidux-install.sh <command>"
    echo ""
    echo "Commands:"
    echo "  install   First-time setup (symlinks, hooks, config)"
    echo "  upgrade   Pull latest, re-verify, re-install hooks if changed"
    echo "  version   Print version, git hash, sync status"
    echo "  doctor    Full health check (PASS/FAIL for each probe)"
    echo ""
    exit 1
    ;;
esac
