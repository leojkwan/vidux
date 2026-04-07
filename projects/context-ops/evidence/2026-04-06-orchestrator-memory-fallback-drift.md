# 2026-04-06 Orchestrator Memory Fallback Drift

## Why this slice
The orchestrator's live harness and the clean repo worktree drifted apart again, and the newer harness still skipped the freshest local memory path when `CODEX_HOME` was unset. That left the control-plane loop able to rehydrate from stale repo notes even though newer durable checkpoints already existed under `~/.codex/automations/`.

## Facts gathered
- [Source: `printenv CODEX_HOME`, read 2026-04-06 21:08 EDT] `CODEX_HOME` is unset in the shell used for this run.
- [Source: `~/.codex/automations/codex-automation-orchestrator/memory.md`, read 2026-04-06 21:08 EDT] The live local memory file exists and already contains newer checkpoints at `2026-04-06 20:49 EDT` and `2026-04-06 20:15 EDT`.
- [Source: `/Users/leokwan/.codex/worktrees/afa3/ai/automations/codex-automation-orchestrator/memory.md`, read 2026-04-06 21:08 EDT] The clean worktree copy still held older notes from `17:11`, `16:12`, and `14:08 EDT`, so repo fallback would miss the freshest self-audit state.
- [Source: `/Users/leokwan/Development/ai/automations/codex-automation-orchestrator/automation.toml`, read 2026-04-06 21:08 EDT] The live-root harness already moved to the public Vidux authority chain and `BYMINUTE=4,24,44`, but its memory read order still jumped from `$CODEX_HOME/...` straight to repo memory.
- [Source: `/Users/leokwan/.codex/worktrees/afa3/ai/automations/codex-automation-orchestrator/automation.toml`, read 2026-04-06 21:08 EDT] The clean repo worktree was still on the older Ralph-era prompt, `BYMINUTE=5,35`, and `execution_environment = "local"`, so the shared repo view no longer matched live scheduler truth.
- [Source: `~/.codex/sqlite/codex-dev.db` row `codex-automation-orchestrator`, read 2026-04-06 21:06 EDT] The live scheduler prompt already uses the public Vidux path and current cadence, so the bounded defect is self-drift in repo truth plus the missing `~/.codex` memory fallback, not a broader fleet mismatch.

## Change shipped
1. Synced the orchestrator TOML in both the clean repo worktree and the live automation root to the current public-Vidux harness, current cadence, and current execution-environment metadata.
2. Tightened the harness authority chain so memory rehydration checks `$CODEX_HOME/...` when set, then `~/.codex/automations/...`, then repo `memory.md`.
3. Normalized the orchestrator `memory.md` in both locations to the last 3 notes so repo fallback remains usable when local runtime state is unavailable.
4. Synced the live SQLite `prompt` field to the same fallback-aware harness text without changing scheduler cadence, status, model, or reasoning.

## Remaining exposure
- The fleet still has `7` DB-only active rows (`6` StrongYes burst lanes plus `vidux-meta`) outside repo truth, which remains the next control-plane classification slice once this self-drift is closed.
- The canonical `/Users/leokwan/Development/ai` checkout is still dirty and one commit behind `origin/main`, so broader repo cleanup still needs a deliberate sync window.
