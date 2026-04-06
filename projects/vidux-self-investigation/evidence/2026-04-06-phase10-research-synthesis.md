# Phase 10 Research Synthesis — 5-Agent Fan-Out

**Date:** 2026-04-06
**Method:** Tier 1 parallel research (5 agents), Tier 2 synthesis (this doc)

## Agent Reports

### 1. `/vidux-manager` Design (manager-design agent)

**Key decisions:**
- 4 subcommands: `diagnose`, `test`, `investigate`, `fleet-health`
- `diagnose` wraps vidux-doctor.sh with AI-powered analysis (bimodal quality, prompt discipline, memory analysis)
- `test` creates isolated e2e test projects (nextjs, ios, react-native, python), measures plan quality against 17-19/20 baseline from self-investigation
- `investigate` does meta-research on vidux itself: framework-drift, nested-plans, automation-quality, prompt-evolution, checkpoint-protocol
- `fleet-health` provides continuous bimodal distribution monitoring and handoff gap detection
- Hard rule: diagnostics are read-only, tests create isolated projects in `tests/e2e/`
- Improvement feedback loop: diagnose -> investigate -> test -> checkpoint

### 2. Stage Indicators (stage-indicators agent)

**Key decisions:**
- 5 primary stages with emoji: GATHER (🔍), PLAN (📐), EXECUTE (⚡), VERIFY (✅), CHECKPOINT (📌)
- 3 meta-stages: INVESTIGATE (🔎), COORDINATE (🚀), RESEARCH (🧠)
- Depth notation: `[L1]` root, `[L2:tag]` investigation, `[L3:tag]` sub-investigation
- Breadcrumb format: `🔍→📐→⚡→✅→📌 [L1] | Task: "Feature X" | 7/10 ready`
- Stage transitions shown inline in Progress entries
- Works in terminal (ANSI), IDE (breadcrumb), CI (compact status line)
- Max 4 levels deep (L1-L4), beyond = refactor into separate PLAN.md

### 3. Dashboard / Plan Hierarchy (dashboard-design agent)

**Key decisions:**
- 3-source discovery: local projects/, ~/.codex/automations/, ~/.claude/ + external roots
- Tree view with ├─ └─ │ connectors, status indicators per plan
- Max depth: 3 levels (configurable in vidux.config.json)
- Plan identity = absolute path from root to PLAN.md
- Dashboard state index at `$PLAN_STORAGE_ROOT/dashboard.index.json` (machine-local, not git-backed)
- Metadata cache: `$PLAN_STORAGE_ROOT/plans/{hash}.metadata.json`
- Plans travel with code (git-backed); dashboard index is local aggregation
- `vidux status --dashboard` for cross-plan view, `vidux status` for single plan
- Footer summary: count by phase, context budget, stale check

### 4. Ledger Integration (ledger-design agent)

**Key decisions:**
- 4 event types: AGENT_LANE (lane claim), CHECKPOINT (task transition), PLAN_MODIFIED (decision log), LOOP_START/LOOP_END (cycle boundaries)
- Read ledger at loop start for conflict detection, during contradiction detection, at stuck-loop detection
- Centralized at `~/.agent-ledger/activity.jsonl` (single source across all tools/worktrees)
- Location resolution: `$AGENT_LEDGER_PATH` env → `$XDG_DATA_HOME` → `~/.agent-ledger/` → local fallback
- Portability layer: `scripts/lib/ledger-config.sh` sourced by all ledger scripts
- Migration: extract 12 scripts from ~/Development/ai/, replace ~20 hardcoded paths
- Non-vidux awareness: ledger tracks manual work, other tools' checkpoints, cross-worktree activity
- Graceful degradation: ledger is optional, vidux continues with warning if unavailable

### 5. Backpressure & Pruning (backpressure-design agent)

**Key decisions:**
- `vidux-prune.sh` with subcommands: plans, worktrees, ledger, all
- Plan pruning: archive completed tasks at threshold (default 50), stale blocked after 90 days, decision log rotation at 180 days
- Worktree lifecycle: active (<2h) → stale (2-24h) → orphaned (>24h) → cleanup
- Max concurrent worktrees: 3 (configurable)
- Circuit breaker: 3 failures in 5 cycles → task auto-blocked for 3 cycles
- Pressure scoring: 0-10 scale based on agent pool, browser instances, blocked tasks, stuck loops
- Escalation: <5 normal, 5-7 reduce parallelization, >=8 pause + diagnose
- Ledger compaction: hot window 7 days / 1000 entries, cold archive monthly JSONL
- PLAN.md size cap: 100KB warn, auto-archive at threshold
- Dry-run mode (`--simulate`) for all operations
- Cron integration: weekly full prune, daily ledger compact, post-checkpoint worktree check

## Dependency Graph

```
vidux.config.json extensions (foundation)
  ├─ Stage indicators (no deps, can go first)
  ├─ Ledger integration (reads config)
  │   ├─ Dashboard (reads ledger + config)
  │   └─ Backpressure/pruning (writes ledger compaction)
  └─ vidux-manager (depends on all above)
```

## Implementation Order

1. **vidux.config.json** — extend with plan_storage_root, dashboard, ledger, pruning configs
2. **Stage indicators** — embed into /vidux command (no deps, immediate UX win)
3. **Ledger integration** — portable config, event emission, conflict detection
4. **Dashboard** — plan discovery, tree view, cross-tool status
5. **Backpressure** — vidux-prune.sh, pressure scoring, circuit breaker
6. **vidux-manager** — wraps all above into self-diagnostic intelligence
7. **Contract tests** — cover all new scripts and commands
