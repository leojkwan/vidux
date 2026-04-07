# 2026-04-07 Orchestrator Repeat-Blocker Cooldown

## Why this slice
The orchestrator already escalated the `8` DB-only active rows as a governance blocker, but the harness still only said to "escalate" repeated blockers. It did not tell future runs to cool that seam and pick a different fleet-health slice once the escalation was already recorded.

## Facts gathered
- [Source: `/Users/leokwan/Development/ai/automations/codex-automation-orchestrator/automation.toml`, read 2026-04-07] The current guardrail says "If the same blocker repeats across the last 3 orchestrator notes, escalate the process fix in Context Ops instead of brute-forcing it again," but it does not ban immediate reselection of the same unchanged seam after escalation.
- [Source: `~/.codex/automations/codex-automation-orchestrator/memory.md`, read 2026-04-07] The last `3` retained notes all kept the same `8` DB-only active rows in the hot path, with two consecutive next moves asking for the same archive-vs-promote classification and the latest note escalating the same seam as a governance blocker.
- [Source: `~/.codex/sqlite/codex-dev.db` table `automation_runs`, queried 2026-04-07] The last user-facing orchestrator inbox titles were `Public Vidux story corrected` and `DB-only automation cluster needs decision`, which shows the unresolved DB-only cluster is still dominating consecutive orchestrator runs even after the public-doc drift was fixed.
- [Source: `/Users/leokwan/Development/vidux/projects/context-ops/PLAN.md`, read 2026-04-07] Cycle `19` already records the process fix: stop row-level retries on the `8` DB-only rows without explicit archive-vs-promote approval.

## Change shipped
1. Tightened the orchestrator harness so a blocker that already repeated across the last `3` notes and has been escalated must go cold until a source file, scheduler field, or approval state changes.
2. Synced the live SQLite prompt row for `codex-automation-orchestrator` to the same cooldown-aware contract.
3. Recorded the cooldown rule in the public Context Ops store so future runs can cite a stable process decision instead of rediscovering it.

## Remaining exposure
- The `8` DB-only active rows still need explicit owner approval to archive or promote them; this slice only prevents the orchestrator from spending more unchanged runs on that same governance seam.
- The canonical `/Users/leokwan/Development/ai` checkout remains dirty and `1` commit behind `origin/main`, so broader repo synchronization is still an environment blocker rather than a control-plane decision.
