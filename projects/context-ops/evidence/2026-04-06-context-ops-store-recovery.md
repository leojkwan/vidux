# 2026-04-06 Context Ops Store Recovery

## Why this slice
The active `codex-automation-orchestrator` loop still listed `projects/context-ops` as its first authority source, but the public `vidux` repo no longer contained that directory after canonical unification. The shared fleet audit loop was therefore asking future runs to read files that did not exist.

## Facts gathered
- `git rev-list --left-right --count HEAD...origin/main` in `/Users/leokwan/Development/ai` returned `0 0`.
- `git pull --rebase` in `/Users/leokwan/Development/ai` failed because the repo has unrelated unstaged changes, so the safe path was a narrowly scoped edit rather than a broader sync pass.
- `/Users/leokwan/Development/ai/skills/vidux` is now a symlink to `/Users/leokwan/Development/vidux`.
- `/Users/leokwan/Development/vidux/projects/` did not contain `context-ops/` at all before this fix.
- `~/.codex/automations` and `~/.Codex/automations` both point to `/Users/leokwan/Development/ai/automations`, so the repo-backed memory file is also the live automation memory on this machine.
- The live scheduler row for `codex-automation-orchestrator` already matched repo truth on cadence/model fields; the broken part was the prompt's missing authority store, not repo-vs-DB field drift.

## Change shipped
1. Added `/Users/leokwan/Development/vidux/projects/context-ops/PLAN.md` as the new canonical public Context Ops store.
2. Added this evidence note so the scheduler prompt can cite a real current recovery record.
3. Updated `/Users/leokwan/Development/ai/automations/codex-automation-orchestrator/automation.toml` to read from the new public Context Ops files, then synced the live SQLite prompt for the same automation row.
4. Updated `/Users/leokwan/Development/ai/automations/README.md` so the documented authority store and cadence match the current orchestrator contract.

## Remaining exposure
- The broader fleet still has other automation prompts that mention `ai/skills/vidux/...` project-store paths. Some of those may now resolve to missing public-repo paths after canonical unification.
- This run fixed the orchestrator only. The next control-plane slice should classify the remaining path dependencies instead of assuming symlink compatibility is sufficient everywhere.
