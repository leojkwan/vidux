#!/bin/bash
# install-hooks.sh — Install Vidux enforcement hooks for Claude Code
#
# Usage: bash install-hooks.sh [project-dir]
#
# Installs prompt-type hooks that guide agents to follow the Vidux protocol:
#   - SessionStart: "Read PLAN.md first"
#   - PreToolUse (Write/Edit): "Is this file in the plan?"
#   - PostToolUse (Write/Edit): "Did you drift from the plan?"
#   - Stop: "Did you checkpoint?"
#
# These are PROMPT hooks (suggestions injected into context), not COMMAND hooks
# (which would hard-block). See ENFORCEMENT.md for rationale.
#
# Company-agnostic. Works for any project.

set -euo pipefail

PROJECT_DIR="${1:-.}"
CLAUDE_DIR="$PROJECT_DIR/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.local.json"

# Ensure .claude directory exists
mkdir -p "$CLAUDE_DIR"

# The hooks to install
VIDUX_HOOKS='{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "VIDUX RESUME: You are a stateless agent. Read PLAN.md first. Find the first unchecked task. Read the last Progress entry to understand where the previous agent left off. Do not start work until you understand the plan."
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "VIDUX CHECK: Before writing code, verify this file is covered by a task in PLAN.md. If not, update PLAN.md first with a new task entry (with evidence). The plan is the store; code is a derived view."
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "VIDUX DRIFT CHECK: Does this change match the current task in PLAN.md? If you deviated, update PLAN.md Surprises section."
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "VIDUX CHECKPOINT: Update PLAN.md Progress section with what you did, what is next, and blockers. Commit your changes. The next agent knows nothing except what is in the files."
          }
        ]
      }
    ]
  }
}'

# If settings file exists, merge hooks into it
if [ -f "$SETTINGS_FILE" ]; then
  if command -v jq >/dev/null 2>&1; then
    EXISTING=$(cat "$SETTINGS_FILE")
    MERGED=$(printf '%s' "$EXISTING" | jq --argjson new "$VIDUX_HOOKS" '. * $new')
    printf '%s\n' "$MERGED" > "$SETTINGS_FILE"
    echo "Vidux hooks merged into existing $SETTINGS_FILE"
  else
    echo "Warning: jq not found. Cannot merge into existing settings."
    echo "Please manually add Vidux hooks from ENFORCEMENT.md to $SETTINGS_FILE"
    exit 1
  fi
else
  # Create new settings file with hooks
  printf '%s\n' "$VIDUX_HOOKS" > "$SETTINGS_FILE"
  echo "Vidux hooks installed to $SETTINGS_FILE"
fi

echo ""
echo "Installed 4 prompt hooks:"
echo "  SessionStart  — Read PLAN.md first"
echo "  PreToolUse    — Is this file in the plan?"
echo "  PostToolUse   — Did you drift from the plan?"
echo "  Stop          — Did you checkpoint?"
echo ""
echo "These are prompt hooks (suggestions), not command hooks (blockers)."
echo "See ENFORCEMENT.md for details."
