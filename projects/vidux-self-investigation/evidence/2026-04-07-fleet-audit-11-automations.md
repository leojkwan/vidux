# 2026-04-07 Fleet Audit — 11 Active Automations

## Goal
Diagnose why 8/11 active Codex automations are failing to ship, identify root causes via 5 Whys, and plan optimizations.

## Sources
- [Source: Codex DB] `~/.codex/sqlite/codex-dev.db` — 20 automation rows, 11 active
- [Source: automation.toml × 11] `/Users/leokwan/Development/ai/automations/*/automation.toml`
- [Source: memory.md × 11] per-automation memory files with last 3 run notes
- [Source: git log] resplit-ios, strongyes-web, ai repos — last 6 hours
- [Source: PLAN.md × 4] StrongYes UX Overhaul, Resplit Mission, Resplit Web, Context Ops
- [Source: vidux-loop.sh] Line-by-line analysis of SIGPIPE-causing patterns

## Fleet Scorecard (Last 6 Hours)

| # | Automation | Target | Status | Runs (6h) | Shipping? |
|---|---|---|---|---|---|
| 1 | resplit-asc | resplit-ios | SHIPPING | 3 (20m, 1h39m, 1h28m) | YES — closing ASC tickets with UI proofs |
| 2 | resplit-currency | resplit-ios | SHIPPING | 3 (10m, 99m, 31m) | YES — FX trust notes, share provenance |
| 3 | codex-orchestrator | ai | META-WORK | 3 (8m, 64m, 6m) | NO — tightening sibling prompts, not shipping product |
| 4 | resplit-launch-loop | resplit-ios | BLOCKED | 5 (63m, 5m, 5m, 13m, 8m) | NO — same missing ASC key for 6+ hours |
| 5 | resplit-web | resplit-ios | CRASHED | 3 (<1m × 3) | NO — vidux-loop.sh exit 141 SIGPIPE |
| 6 | resplit-android | resplit-ios | BLOCKED | 3 (4m, 15m, 5m) | NO — Play Store owner-blocked |
| 7 | strongyes-flow-radar | strongyes-web | CRASHED/EMPTY | 3 (<2m × 3) | NO — SIGPIPE + empty queue |
| 8 | strongyes-ux-radar | strongyes-web | CRASHED/EMPTY | 3 (<1m × 3) | NO — SIGPIPE + empty queue |
| 9 | strongyes-content | strongyes-web | EMPTY | 3 (<3m × 3) | NO — empty queue, auto_pause |
| 10 | strongyes-revenue-radar | strongyes-web | EMPTY | 3 (<2m × 3) | NO — empty queue, auto_pause |
| 11 | strongyes-release-train | strongyes-web | EMPTY | 3 (<4m × 3) | NO — empty queue, bimodal_gate blocked |

**Fleet health: 2/11 shipping (18%). 1 meta-work. 8 wasting cycles.**

## 5 Whys Analysis

### Why 1: Why are 8/11 automations not shipping code?
Three failure modes: (a) vidux-loop.sh crashes with exit 141 before emitting gate JSON (resplit-web, strongyes-flow-radar, strongyes-ux-radar), (b) PLAN.md task queues are genuinely empty (all 5 StrongYes + resplit-web), (c) same blocker repeated for hours with no escalation (resplit-launch-loop, resplit-android).

### Why 2: Why does vidux-loop.sh crash with exit 141?
`set -euo pipefail` at line 10 + `grep ... | head -1` patterns at lines 87, 146, 154, 183, 278, 319, 356, 440. SIGPIPE (signal 13) fires when grep writes more data after head closes the pipe. Under pipefail, the non-zero exit propagates and kills the script before it emits any JSON. Exit code = 128 + 13 = 141. Every automation using the REDUCE gate inherits this crash.

### Why 3: Why are StrongYes queues permanently empty?
All 5 StrongYes automations run `vidux-loop.sh` against the SAME PLAN.md: `/Users/leokwan/Development/strongyes-web/vidux/ux-overhaul/PLAN.md`. That plan has all tasks as `[x]` (T24-T32 completed). Only 3 deferred items remain (testimonials, analytics, expand worktrees) — these are conditional on external triggers, not executable. The 4 radars are explicitly "read-only" and CANNOT create tasks. The release-train writer REDUCE-exits before ever reading radar observations. **The feedback loop is circular deadlock: radars can't write → queue stays empty → writer exits → nothing changes.**

### Why 4: Why doesn't the system detect queue starvation?
vidux-loop.sh has circuit breaker (blocks after N idle cycles) and auto_pause_recommended, but these are SYMPTOMS not CURES. They correctly say "nothing to do" but nothing generates new work. Doctrine 11 (self-extending plans) exists in text but has no mechanical enforcement. The radars cannot promote observations into tasks. The orchestrator cannot inject tasks into project PLAN.md files. There's no "queue refill" mechanism.

### Why 5: Why do blocked automations keep running?
`resplit-launch-loop` reported the missing ASC key 5 times in 6 hours. Each run reads the same blocker, writes the same memory note, and exits. The REDUCE gate checks for `blocked` status but the task is already `[blocked]` in PLAN.md — it should skip instantly. Instead, the automation does 5-63 minutes of reading authority files, checking git state, and re-confirming what it already knows. There's no "blocker dedup" gate: "if your last 3 memory notes report the same blocker, PAUSE yourself."

## Root Causes (3 systemic, 2 local)

### Systemic 1: vidux-loop.sh SIGPIPE (affects ALL automations)
The `grep | head -1` pattern under `set -euo pipefail` is a known bash antipattern. Must be fixed with `{ grep ... || true; } | head -1` or by assigning to a variable first. Affects ~8 pipe patterns across the script.

### Systemic 2: No radar→writer task promotion pipeline
Radars observe the live product (flow, UX, content, revenue) but have no mechanism to create tasks in the PLAN.md. The release-train writer has the ability to write but REDUCE-exits before reading radar observations. The fix is either: (a) let radars write `[pending]` tasks directly, or (b) have the writer consume radar memory notes as a task source during its READ step.

### Systemic 3: No blocker dedup / auto-pause escalation
Automations that hit the same blocker N times should auto-pause, not keep burning cycles. The `auto_pause_recommended` field exists in vidux-loop.sh JSON output but automations don't act on it mechanically — they write it to memory and keep running next hour.

### Local 1: Missing ASC key (blocks resplit-launch-loop, partially blocks resplit-asc)
`/Users/leokwan/.private_keys/AuthKey_32D626LB6H.p8` does not exist. The `.private_keys` directory itself is absent. This blocks all TestFlight upload paths. Human action required.

### Local 2: StrongYes is in maintenance mode (all tasks done)
The UX Overhaul PLAN.md has genuinely completed its scope. The product shipped: Stripe checkout works, production deploy is current, webhook/profile wiring is live. The radars are watching a product that doesn't need more work right now. The honest move might be to PAUSE the fleet, not feed it busywork.

## Optimization Plan

### Immediate (fix within this session)
1. **Fix SIGPIPE in vidux-loop.sh** — Wrap all `grep | head` patterns to survive pipefail
2. **Add blocker dedup gate** — If last 3 memory notes have same blocker keyword, emit `auto_pause: true` in JSON and have REDUCE gate respect it
3. **PAUSE StrongYes radars** — If the product is shipped and working, 4 read-only radars watching an empty queue is waste

### Short-term (next 1-2 sessions)
4. **Radar→writer task promotion** — Option A: radars write findings as `[observation]` tags in memory, writer consumes these in READ step and promotes to `[pending]` if actionable. Option B: radars can append to a separate `INBOX.md` that the writer processes.
5. **Queue starvation detection** — vidux-loop.sh should detect "all tasks completed but mission not done" and emit `queue_starved: true` instead of generic `action: none`

### Strategic (requires design)
6. **Orchestrator role redesign** — Instead of tightening individual prompts one-by-one, the orchestrator should detect fleet-level patterns (6 idle automations, 1 stuck blocker) and take fleet-level action (pause cluster, create escalation ticket, redistribute work)
7. **Sub-plan trees** — Leo's question about task queue depth. Currently PLAN.md is flat. Sub-investigations exist but aren't mechanically connected to the parent queue. Need a `[spawns: investigations/foo.md]` tag that vidux-loop.sh can traverse.

## Recommendations
1. Fix SIGPIPE NOW — it's a 10-line fix that unblocks every automation's REDUCE gate
2. PAUSE the StrongYes radar cluster until new product work is planned
3. Add blocker dedup to REDUCE gate template (if same blocker 3×, auto-pause)
4. Design radar→writer inbox pattern for next phase
5. Redesign orchestrator from "prompt editor" to "fleet health manager"
