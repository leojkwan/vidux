# 2026-04-07 Fleet Overnight Diagnosis

## Goal
Diagnose overnight automation fleet health and identify structural fixes for cadence-runtime mismatches, blocked-lane waste, and missing REDUCE gates.

## Sources
- [Source: Codex DB automation_runs] April 7 run counts per lane
- [Source: automation memory files] Runtime estimates from memory.md timestamps
- [Source: vidux-doctor.sh --json] 4/13 pass, 38 stale worktrees, 340 browser processes
- [Source: human observation] "too much data" — signal-to-noise ratio too low

## Findings

### 1. Cadence-Runtime Mismatch (Critical)
Active Resplit lanes fire every 20 minutes but work takes 35-63 minutes:
- resplit-asc: 20min cadence, 63min avg runtime → 3x overlap
- resplit-currency: 20min cadence, 40min avg runtime → 2x overlap  
- resplit-web: 20min cadence, 16min runtime → tight but workable
- resplit-android: 20min cadence, 2-7min runtime → blocked, pure waste
Total: ~150 runs across 4 resplit lanes on April 7 alone when ~30-40 would ship the same work.

### 2. Blocked Lanes Burning Cycles (High)
resplit-android: 37 runs today, each restating "still blocked on Play Store inputs" in 2-7 minutes.
resplit-launch-loop: blocked on missing ASC key + GitHub Actions billing.
Estimated waste: 2.5+ hours of API time on April 7 alone from just these two lanes.

### 3. Missing REDUCE Gate (High)
No automation has a reduce-first assessment step. Every fire is a full dispatch.
This violates vidux bimodal doctrine: quick (<2min) or deep (15+min), mid-zone forbidden.
The orchestrator itself ran 6m28s doing one memory file normalization — textbook mid-zone.

### 4. StrongYes Ghost Fleet (Medium)
8 DB-only rows (strongyes-backend, strongyes-content-scraper, strongyes-email, strongyes-problem-builder, strongyes-product, strongyes-ux, vidux-meta, vidux-test-grader) show 0 runs ever. Dead weight.

### 5. Resource Pressure (Medium)
- 38 stale Codex worktrees for vidux alone
- 340 browser processes (69 stale Playwright controllers) using 18.4GB RAM
- Worktree accumulation is a direct consequence of cadence-runtime mismatch

## Recommendations
1. Fix cadences: rule = max(avg_runtime * 1.5, 60min)
2. Add REDUCE gate to every harness prompt
3. PAUSE blocked lanes, add "resume when" conditions
4. Kill ghost fleet rows
5. Clean stale worktrees and browser processes
