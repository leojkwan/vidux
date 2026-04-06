# 2026-04-06 Missing Automation Root Audit

## Goal
Explain why the control plane could no longer trust repo-backed automation truth enough to keep mutating live scheduler rows.

## Sources
- [Source: shell audit, 2026-04-06] `ls -la /Users/leokwan/Development/ai` showed no `automations/` directory in the live worktree.
- [Source: shell audit, 2026-04-06] `git status --short` in `/Users/leokwan/Development/ai` listed every tracked `automations/*` file as deleted.
- [Source: git tree, 2026-04-06] `git ls-tree -r --name-only HEAD automations` still listed 29 tracked files, including 14 `automation.toml` definitions.
- [Source: symlink audit, 2026-04-06] `ls -ld ~/.codex/automations ~/.Codex/automations` showed both live roots still pointing at `/Users/leokwan/Development/ai/automations`.
- [Source: git divergence check, 2026-04-06] `git rev-list --left-right --count HEAD...origin/main` returned `0 1`, so the local repo is also one commit behind remote.
- [Source: SQLite audit, 2026-04-06] `automations` still contained 24 live rows, including active `vidux-endurance` and `vidux-v230-planner` rows with past `next_run_at`, `last_run_at = NULL`, and zero `automation_runs`.
- [Source: filesystem follow-up, 2026-04-06] After recreating the orchestrator memory path, `find /Users/leokwan/Development/ai/automations -maxdepth 3 -type f` still showed only two memory files and none of the tracked `automation.toml` definitions, so the shared tree is only partially present.

## Findings

### 1. The live automation root is broken
At audit start, the scheduler selectors still pointed at `/Users/leokwan/Development/ai/automations`, but that directory did not exist in the current worktree. This run recreated only the orchestrator memory path, which means the shared tree is still effectively broken: the root is now partial, not recovered.

### 2. Repo truth is not safely recoverable mid-run
`HEAD` still tracks the shared automation tree, but the repo is dirty and behind `origin/main`. Pulling would cross unrelated local deletions, so this run could not honestly promote `HEAD` as authoritative repo truth.

### 3. Row-level scheduler repair would be premature
The cold active Vidux rows are real, but mutating them before the shared root is recovered would only patch symptoms. Until the shared tree is restored or intentionally relocated, repo-vs-DB sync claims are mechanically untrustworthy.

## Recommendations
- Recover the shared `ai/automations/` tree or deliberately repoint the live automation symlinks before the next scheduler-sync slice.
- After root recovery, rerun the repo-vs-DB audit and then decide whether `vidux-endurance` and `vidux-v230-planner` need re-arming, recreation, or a deeper scheduler diagnosis.
