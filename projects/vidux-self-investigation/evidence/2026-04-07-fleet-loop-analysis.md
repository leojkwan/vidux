# 2026-04-07 Fleet Loop Analysis — Codex Automations Over Time

## Goal
Comprehensive analysis of what the Codex automation fleet has been doing: runtime patterns, memory quality, prompt compliance, and anti-patterns.

## Sources
- [Source: ~/.codex/sqlite/codex-dev.db] 24 automations (10 active, 14 paused)
- [Source: ~/.codex/automations/*/memory.md] Per-automation memory files
- [Source: ~/.agent-ledger/activity.jsonl] 29,429 entries over 181 days (2025-10-10 to 2026-04-07)
- [Source: automation prompts] All active + top 3 paused by size

## Findings

### 1. Fleet Composition
- 10 ACTIVE: 1 orchestrator, 4 resplit, 5 strongyes
- 14 PAUSED: legacy experiments, oversized prompts, blocked lanes
- All ACTIVE prompts are gpt-5.4, hourly cadence, staggered minutes
- Total active prompt budget: ~32,813 chars

### 2. Tier Classification (from memory analysis)
**Tier 1 — Shipping real work (3 automations):**
- resplit-asc: 3 cycles, ASC bugs closed with before/after proof, 17-63min runtimes
- resplit-currency: 3 cycles, FX picker polish with screenshots + tests
- resplit-web: 3 cycles, error pages + landing hero + Playwright proof

**Tier 2 — Blocked but honest (1):**
- resplit-launch-loop: 3 cycles repeating same blocker (missing AuthKey .p8)

**Tier 3 — Spinning idle / repeating (5):**
- strongyes-content: 3 cycles, zero code shipped, re-confirms "Nia MCP timeout" each time
- strongyes-flow-radar: auto-paused after detecting unproductive streak
- strongyes-ux-radar: auto-paused (correct behavior)
- strongyes-release-train: auto-paused (correct behavior)
- strongyes-revenue-radar: auto-paused (correct behavior)

**Meta (1):**
- codex-automation-orchestrator: security sweeps, fleet config, meta-work

### 3. Ledger Runtime Patterns (29,429 entries, 181 days)
- **Quick (<2min): 24.1%** — healthy
- **Mid-zone (3-8min): 32.3%** — RED FLAG, doctrine says minimize
- **Deep (>15min): 15.5%** — substantive work
- 32% mid-zone rate means nearly 1/3 of Codex sessions are waste

### 4. Idle Churn (high no-files %)
- vidux-endurance-test: 74% of 196 runs produced nothing → retire
- strongyes-content-radar: 60% idle across 294 runs → needs REDUCE gate or pause
- vidux-v2-rebuild: 50% idle across 66 runs → retire (v2 already shipped)
- strongyes-flow-radar / media-studio: ~40% idle → auto-pause working

### 5. Prompt Quality Scorecard
All 10 active prompts are doctrine-compliant (D8 harness, not snapshot). All have REDUCE gates and PLAN.md refs.

**Issues:**
- StrongYes 4 radars are near-clones (~300 chars unique each, ~750-980 chars shared REDUCE boilerplate)
- resplit-super-team-hourly (PAUSED, 14K chars): 70% restated process, violates D8 severely
- resplit-nurse (PAUSED, 7.8K chars): 40% generic vidux process duplication
- strongyes-release-train (5.6K chars): largest active prompt, some process duplication

### 6. Scheduling Patterns
- 30-50 hour max gaps on several automations (weekend dropouts)
- No stuck-loop patterns (no task retried 3+ times)
- Fleet is young — all memory entries from 2026-04-07 (single day of operation)

## Recommendations
1. **PAUSE strongyes-content** — burning 20min/cycle to re-confirm nothing changed
2. **PAUSE resplit-launch-loop** — repeating same blocked-key finding, needs human action
3. **Retire** vidux-endurance-test, vidux-v2-rebuild (74% and 50% idle, legacy)
4. **Template the radar quartet** — share REDUCE block, ~300 chars unique per radar
5. **Fix 32% mid-zone** — add stricter bimodal enforcement to Codex harnesses
6. **Rewrite resplit-super-team-hourly** if ever reactivated (14K → 2K target)
