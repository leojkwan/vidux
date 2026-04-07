# Vidux — Build Plan

## Purpose
Create a net-new plan-first orchestration system that makes quarter-long iOS projects completable in a week via overnight cron loops. Vidux = Vibe + Redux. The plan is the store, code is the view.

## Evidence
- [Source: 9 research agents, 2026-03-31] SDD (Spec-Driven Development) is 2025-2026's defining practice. Plan-first improves success by ~33%.
- [Source: SlopCodeBench, arxiv 2603.24755] Agent code degradation is monotonic. Erosion in 80% of trajectories. "Coding while thinking" is empirically bad.
- [Source: OpenAI harness engineering] "The harness is the 80% factor." Swapping models = 10-15% change. Swapping harness = works or doesn't.
- [Source: Martin Fowler on SDD tools] "Agents frequently don't follow instructions." Enforcement gap is real.
- [Source: Gastown v0.13.0, 13.3K stars] Git-backed state + persistent agent identity + multi-tool support is production-proven at 20-30 agent scale.
- [Source: Jeffrey Lee-Chan /harness PR #265] Dual five-whys + three-strike gate + contract tests is a working plugin in production.
- [Source: swiftify-v4 session] Combine rework happened because plan didn't capture team conventions. 50/30/20 would have caught it.
- [Source: Factory.ai] Anchored iterative summarization (structured > freeform) scores 3.70 vs 3.44.
- [Source: Arize pattern] Planning-as-tool-calls with hard finish gate. Can't mark done with pending tasks.
- [Source: Multi-agent research] Coordination gains plateau at ~4 agents. 17x error amplification beyond that without hierarchy.
- [Source: Anthropic] "Agents plan by doing" for simple tasks. "Scale effort to complexity" for big ones. Both modes needed.
- [Source: lkwan feedback] "We're not planning enough. We're coding while thinking." Vidux doctrine is the response.
- [Source: open source survey, 26 tools] Key ingredients: PAUL's Execute/Qualify/Unify loop (603 stars), tick-md's markdown-native coordination (18 stars but exact pattern match), spec-kit's three-doc chain (84K stars), GSD's stuck-loop detection (46K stars), opslane/verify's one-agent-per-AC model (100 stars), adversarial-spec's multi-LLM debate (517 stars).
- [Source: superpowers, 128K stars] Dominant skill framework. Chains: brainstorm -> plan -> execute -> verify. Subagent dispatch model. Already installed in our env.
- [Source: Chachamaru127/claude-code-harness, 383 stars] 5-verb workflow: Setup -> Plan -> Work -> Review -> Release. TypeScript guardrail engine. 4-perspective review (Security, Performance, Quality, A11y).

## Constraints
- ALWAYS: Work on Claude Code, Cursor, AND Codex (model/tool interop is #1 priority)
- ALWAYS: Simple to install and debug (one command bootstrap)
- ALWAYS: Keep existing skills untouched (Vidux is additive, not a rewrite)
- ALWAYS: Company-agnostic — no references to any employer's internal tools
- ASK FIRST: Before changing Captain's bootstrap or sync scripts
- NEVER: Typed YAML schemas (user feedback: natural language markdown only)
- NEVER: More than 4 coding agents in parallel (research: diminishing returns)
- Reviewer preference (lkwan): Sports analogies (point guard, ref), not political ones (mayor)

## Decisions
- [2026-03-31] Decision: Vidux is a skill first, plugin packaging later. Rationale: Skills work NOW across all tools. Plugins are Claude-only. Can wrap in plugin manifest later.
- [2026-03-31] Decision: PLAN.md lives in the branch, not globally. Rationale: Travels with code, visible in PRs, any machine gets it on git fetch.
- [2026-03-31] Decision: Fan-out/fan-in for plan refinement, not 20 agents editing one file. Rationale: Research shows 17x error amplification. 4-agent groups with one synthesizer is the sweet spot.
- [2026-03-31] Decision: Two modes — Pilot for Mode A (small), Vidux for Mode B (quarter-long). Don't try to make one system do both.
- [2026-03-31] Decision: Channel Yegge (git-backed state, propulsion) and jlee (harness, dual five-whys) as advisor philosophies. Not literal framework adoption.
- [2026-04-06] Decision: Publish the portable Vidux core in its own public repo (`leojkwan/vidux`) instead of exposing the entire `ai` skills repo. Rationale: the core is reusable, while `ai/` carries personal and project-specific wiring.
- [2026-04-06] Decision: This repo is the canonical home for Vidux. The copy in `ai/skills/vidux/` is retired. All framework development happens here.

## Tasks

### Phase 1: Core Doctrine — COMPLETE

### Phase 2: Loop Implementation — COMPLETE

### Phase 3: Enforcement — COMPLETE

### Phase 4: Plugin Packaging — COMPLETE

### Phase 5: Integration

### Phase 6: V1 Finalization — Harness + Guides

### Phase 7: Open Source Publication — COMPLETE

### Phase 8: Canonical Unification — IN PROGRESS

### Phase 9: Automation Quality — COMPLETE
- [completed] Create example fleet configs for a reference project (writer + 2 radars + coordinator, staggered schedule). [Done: 2026-04-06] [Evidence: examples/fleet-reference/]
- [completed] End-to-end test: ran /vidux from scratch on NextJS (17/20) and iOS (19/20). Both created compound task investigations. Plan quality validated. [Done: 2026-04-06] [Evidence: projects/vidux-self-investigation/evidence/2026-04-06-e2e-plan-quality.md]

### Phase 10: Visibility, Intelligence & Health — IN PROGRESS

**Goal:** Make vidux self-aware, visible, and self-healing. Clear stage indicators, cross-tool dashboard, ledger-powered coordination, backpressure, and a manager that can diagnose and test itself.

[Evidence: 5-agent fan-out research synthesis at `projects/vidux-self-investigation/evidence/2026-04-06-phase10-research-synthesis.md`]

- [completed] **10.1 Stage indicators** — 6 primary stages (🔍 GATHER, 📐 PLAN, ⚡ EXECUTE, ✅ VERIFY, 📌 CHECKPOINT, 🏁 COMPLETE) + 3 meta-stages + depth tracking [L1/L2/L3]. Embedded in /vidux command. "DIE" renamed to "COMPLETE" across 9 files. "Design for yield" renamed to "Design for completion." [Done: 2026-04-06]
- [completed] **10.2 vidux.config.json extensions** — Added `external_plan_roots[]`, `dashboard.*`, `ledger.*`, `pruning.*`, `backpressure.*` config sections with documented defaults. Backward-compatible. [Done: 2026-04-07] [Evidence: phase10-research-synthesis.md specs, existing script consumers validated]
- [completed] **10.3 Ledger integration** — Built 3-file integration layer: ledger-config.sh (discovery + fallback), ledger-emit.sh (vidux_loop_start/end, checkpoint, plan_modified, fleet_health events), ledger-query.sh (bimodal_distribution, automation_runs, handoff_gaps, fleet_health, conflict_check). Wired into vidux-loop.sh and vidux-checkpoint.sh. vidux-manager.md updated to use ledger queries. Validated against real production ledger (3205 entries, 14 automations). [Done: 2026-04-06]
- [completed] **10.4 /vidux-dashboard command** — 3-source plan discovery (local projects/, ~/.codex/automations/, ~/.claude/ + external roots). Tree view with status, health, last activity. JSON mode. 205 lines. [Done: 2026-04-06]
- [completed] **10.5 vidux-prune.sh** — Subcommands: plans, worktrees, ledger, all, pressure. Plan archival at threshold. Worktree lifecycle. Ledger compaction. Circuit breaker. Pressure scoring 0-10. Dry-run mode. 387 lines. [Done: 2026-04-06]
- [completed] **10.6 /vidux-manager command** — 4 modes: diagnose, test, investigate, fleet-health. Stage indicators integrated. Quality scoring against 17-19/20 baseline. 312 lines. [Done: 2026-04-06]
- [completed] **10.7 Contract tests** — 30 new tests added (138 total) covering ledger libs, vidux-prune.sh, vidux-fleet-quality.sh, dashboard/manager/recipes commands, DOCTRINE.md 12-principle check, SKILL.md dispatch/reduce/bimodal/bounded-recursion terms. [Done: 2026-04-07] [Evidence: test-agent swarm commit 0f85e02]

### Phase 11: Dispatch/Reduce Structural Enforcement + Fleet Hardening

**Goal:** Make the bimodal distribution structural (not just prompt discipline), integrate Vercel toolbar for mobile QA, harden the Codex DB write pattern, and bake the three new doctrine tenets into the open-source docs.

[Evidence: `projects/vidux-v230/evidence/2026-04-06-burst-vs-watch-mode-insight.md`, nia research 2026-04-07 (agentic patterns + Vercel integration + closure-bias workarounds), evening fleet data (resplit-asc 71m burst, resplit-web 33m burst — burst doctrine confirmed working)]

- [completed] **11.1 Bake dispatch/reduce/self-extending doctrine into DOCTRINE.md** — Added Loop Discipline section (principles 10-12), Dispatch/Reduce section with Redux analogy and flow diagram. Updated header to 12 principles. Zero burst/watch terminology. [Done: 2026-04-07] [Evidence: doctrine-agent commit 82fa88b, 108 tests pass]
- [completed] **11.2 vidux-dispatch.sh** — 230-line dispatch assessment script. Dry-run + full mode. Dispatch protocol (stop_conditions, forbidden, required). Exit criteria gate. Stuck detection. Ledger integration. Subagent spawning is agent-side behavior, protocol surface exposed in JSON. [Done: 2026-04-07] [Evidence: valid JSON output, 15 pending tasks detected, 138/138 tests pass]
- [completed] **11.3 Tighten vidux-loop.sh to explicit reduce mode** — All JSON output uses mode:reduce. next_action uses dispatch|none. Added reduce_contract block: read_only, 120s budget, forbidden/allowed actions. [Done: 2026-04-07] [Evidence: prune-agent rename + reduce_contract addition, 138/138 tests pass]
- [x] **11.4 Exit-criteria hook** — Add a machine-verifiable `## Exit Criteria` section to PLAN.md template. Hook rejects agent "done" signal if criteria aren't met. Community-validated pattern (Claude Code #30150). [Evidence: nia research — "append grep-testable conditions, reject done signal if unmet"] [Done: 2026-04-06]
- [blocked] **11.5 Vercel toolbar → task queue bridge** — [Blocker: requires Vercel MCP access + live strongyes project context. Cannot implement in vidux core repo alone.]
- [completed] **11.6 Codex DB write resilience** — Built reusable `scripts/lib/codex-db.sh` lib: codex_db_stop_app, codex_db_write (refuses if app running), codex_db_query, codex_db_epoch_ms. Kill→write→verify pattern extracted from fleet-rebuild.sh. WAL mode won't fix the in-memory cache overwrite — app-stop is the canonical pattern. [Done: 2026-04-07] [Evidence: tested against live Codex (app running detected)]
- [completed] **11.7 Prune stale references** — 9 files changed: burst→dispatch, watch→reduce across scripts/tests/commands/SKILL.md. Removed vidux-amp ref, pruned RALPH.md from live constraints. Historical entries preserved. [Done: 2026-04-07] [Evidence: prune-agent commit 4e1b5fd, merge ddb31d8]
- [completed] **11.8 JSON task queue experiment** — Built `scripts/lib/queue-jsonl.sh`: queue_sync (PLAN.md→QUEUE.jsonl), queue_next (first actionable), queue_count (status breakdown). QUEUE.jsonl is gitignored (derived index). 70 tasks synced, status counts match loop.sh. [Done: 2026-04-07] [Evidence: tested against live PLAN.md, 138/138 tests pass]
- [completed] **11.9 Lifecycle hooks integration** — Added beforeTask (vidux-doctor.sh --json) and afterTask (vidux-checkpoint.sh) to hooks/hooks.json. 5 hooks total. Users wire these in Claude Code settings.json or Codex lifecycle config. [Done: 2026-04-07] [Evidence: hooks.json valid, 138/138 tests pass]

### Phase 12: Continuous Feedback Loop
- [completed] Task 12.1: Add merge-gate to vidux-dispatch.sh — `--merge-gate` mode: detects worktree, tries ff-merge (Tier 1), regular merge (Tier 2), or creates PR on conflict (Tier 3). Proper worktree detection via resolved absolute paths. [Done: 2026-04-07] [Evidence: tested from non-worktree (skip) + merge-gate-harness-fix.md design]
- [completed] Task 12.2: Add auto-pause to vidux-loop.sh — checks last 3 Progress entries for unproductive patterns (blocked, proof-refresh only, nothing to do, escalate). Outputs `auto_pause_recommended` and `unproductive_streak` in JSON. Callers read these to adjust cadence. [Done: 2026-04-07] [Evidence: tested with empty/productive Progress, pipefail-safe]
- [completed] Task 12.3: Add bimodal enforcement to vidux-loop.sh — reads `backpressure.bimodal_critical_threshold` from config (default 70). Queries ledger_bimodal_distribution. If score < threshold, sets `bimodal_gate: blocked` and refuses to fire dispatch. Outputs bimodal_score and bimodal_gate in JSON. [Done: 2026-04-07] [Evidence: tested with no ledger (pass-through), config integration verified]
- [completed] Task 12.4: Build vidux-witness.sh — 300-line fleet health observer. Per-plan task counts, git freshness, ledger mid-zone detection, automation memory scanning, fleet A-F grade, JSON output. [Done: 2026-04-07] [Evidence: witness-agent commit c5ee920, 138 tests pass]
- [completed] Task 12.5: Add self-extension quality metric to vidux-manager diagnose — step 5 in diagnose flow. Counts tasks added vs completed, computes ratio. Healthy ≤1.5, warning 1.5-3.0, recursive overload >3.0. Supports [Added-by:] tags and Progress fallback. [Done: 2026-04-07] [Evidence: added to vidux-manager.md diagnose steps, 138/138 tests pass]
- [completed] Task 12.6: Contract tests for Phase 12 — 11 new tests (149 total): merge-gate mode, auto-pause fields, bimodal gate, reduce contract, codex-db lib, queue-jsonl lib, witness script, lifecycle hooks, config backpressure/pruning, self-extension metric. [Done: 2026-04-07]

### Phase 13: Hardening & Coverage — COMPLETE

**Goal:** Fix security/correctness bugs found by self-audit, close test coverage gaps, and improve cross-platform portability. Evidence-driven: every task traces to audit findings.

[Evidence: `projects/vidux-self-investigation/evidence/2026-04-07-hardening-audit.md`, `projects/vidux-self-investigation/evidence/2026-04-07-coverage-gaps.md`]

- [completed] **13.1 Harden json_escape** — Added `\r` escape handling across 5 scripts. Attempted python3 delegation but reverted due to ~80ms/call overhead causing 4 test timeouts. Process fix: never spawn subprocesses in hot-path JSON helpers. [Done: 2026-04-07] [Evidence: hardening-audit.md#2]
- [completed] **13.2 Fix config path injection** — All 15 `python3 -c "...open('$CONFIG')..."` calls across 6 scripts now pass path via sys.argv[1]. vidux-doctor.sh batched 8 calls into 1. [Done: 2026-04-07] [Evidence: hardening-audit.md#5]
- [completed] **13.3 Fix checkpoint sed metacharacter handling** — Used grep -Fn line addressing instead of sed regex. No regex in the task text path. [Done: 2026-04-07] [Evidence: commit f30b05a]
- [completed] **13.4 Add portability layer for stat/date** — scripts/lib/compat.sh created (60 lines): file_mtime_epoch, dir_newest_mtime, parse_date_epoch, parse_iso_epoch. OS detection once at source-time. vidux-prune.sh and vidux-witness.sh both source it, no raw stat -f/date -j calls remain. [Done: 2026-04-07] [Evidence: hardening-audit.md#4]
- [completed] **13.5 Batch config reads into single python3 call** — Merged into 13.2: vidux-doctor.sh now reads all 8 config values in one python3 call. [Done: 2026-04-07] [Evidence: hardening-audit.md#9]
- [completed] **13.6 Contract tests: witness.sh functional tests** — 2 tests: JSON validity + fleet_grade is A-F letter. [Done: 2026-04-07] [Evidence: coverage-gaps.md#1]
- [completed] **13.7 Contract tests: test-all.sh self-test** — 1 test: --json produces valid JSON with overall and sections array. [Done: 2026-04-07] [Evidence: coverage-gaps.md#3]
- [completed] **13.8 Contract tests: compound task / investigation docs** — 2 tests: SKILL.md Compound Tasks section + investigation template required sections. [Done: 2026-04-07] [Evidence: coverage-gaps.md#5]
- [completed] **13.9 Contract tests: doctrine content contracts** — 4 tests: Principle 5 (compaction in SKILL.md), 7 (investigation/nested), 8 (harness/stateless), 9 (coordinator/subagent). [Done: 2026-04-07] [Evidence: coverage-gaps.md#7,12]
- [completed] **13.10 Contract tests: edge cases** — 1 test: empty Tasks → valid JSON with hot_tasks=0. [Done: 2026-04-07] [Evidence: coverage-gaps.md#9]

### Phase 14: Fleet Restructuring — Cadence, REDUCE Gates, Dead Lane Cleanup

**Goal:** Fix the structural problems exposed by overnight fleet data: cadence-runtime mismatches, missing REDUCE gates, blocked lanes burning cycles, and ghost automations.

[Evidence: `projects/vidux-v230/evidence/2026-04-07-fleet-overnight-diagnosis.md`]

- [completed] **14.1 Fix cadence-runtime mismatches** — All active automations moved to 1x/hr with staggered BYMINUTE values. Fleet: 46 runs/hr → 12 runs/hr. [Done: 2026-04-07]
- [completed] **14.2 Design and ship REDUCE gate prompt block** — Both variants (with-vidux + standalone) designed and shipped to DOCTRINE.md, best-practices.md, and all 12 active automation TOMLs. [Done: 2026-04-07]
- [completed] **14.3 PAUSE blocked lanes** — resplit-android PAUSED (Play Store blocked), 14 total automations paused then cleaned. StrongYes radars later unpaused after domain fix. [Done: 2026-04-07]
- [completed] **14.4 Kill ghost fleet rows** — 22 paused/ghost rows deleted from Codex DB. Dashboard clean: 12 active, 0 paused. [Done: 2026-04-07]
- [completed] **14.5 Clean stale worktrees and browser processes** — 229 worktrees pruned (11GB), 750 browser processes killed (20GB RAM). [Done: 2026-04-07]
- [completed] **14.6 Add cadence-runtime health check to vidux-doctor.sh** — CHECK 12 added. Reads rrule BYMINUTE count + memory file runtimes. Doctor now has 14 checks. [Done: 2026-04-07]
- [completed] **14.7 Fleet restructuring contract tests** — 8 new tests (168 total): cadence-runtime check existence, 14+ doctor checks, REDUCE gate in DOCTRINE.md + best-practices.md, compat.sh functions, prune/witness use compat not raw stat/date. [Done: 2026-04-07]

### Phase 15: Fleet Intelligence & Self-Healing — IN PROGRESS

**Goal:** Make vidux fleets self-healing based on real runtime data. Fix the 32% mid-zone problem, add circuit breakers, implement idle-churn detection, and template the radar pattern.

[Evidence: `projects/vidux-self-investigation/evidence/2026-04-07-fleet-loop-analysis.md`, `projects/vidux-self-investigation/evidence/2026-04-07-agentic-patterns-research.md`]

- [completed] **15.1 Add circuit breaker to vidux-loop.sh** — Scans last N Progress entries for shipping signals (shipped/commit/fixed/merged/etc). If none found, sets `circuit_breaker: open` and blocks dispatch. Configurable via `backpressure.circuit_breaker_threshold` (default 3). 2 contract tests added. [Done: 2026-04-07] [Evidence: agentic-patterns-research.md#5, fleet-loop-analysis.md#4]
- [pending] **15.2 Add idle-churn detection to vidux-witness.sh** — Flag automations where >50% of runs produce no file changes. Use ledger data (commit counts per automation). Output `idle_churn_pct` per automation. [Evidence: fleet-loop-analysis.md#4] [P]
- [pending] **15.3 Radar template pattern** — Create a shared radar harness template in guides/vidux/ that the 4 StrongYes radars (and future radars) can reference. Each radar prompt becomes ~800 chars: shared REDUCE block ref + unique mission + unique execution. Saves ~4K chars fleet-wide. [Evidence: fleet-loop-analysis.md#5, prompt analysis]
- [pending] **15.4 Mid-zone enforcement in harness prompts** — Add a "mid-zone kill" instruction to DOCTRINE.md and best-practices.md: if a cycle has been running >3min with no file write and no pending research, checkpoint and exit. Target: reduce 32% mid-zone to <15%. [Evidence: fleet-loop-analysis.md#3]
- [completed] **15.5 Contract tests for circuit breaker** — 2 tests: circuit_breaker field exists and is open/closed, idle progress triggers open + blocks dispatch. Merged into 15.1 delivery. [Done: 2026-04-07] [Evidence: coverage-gaps pattern]

### Phase 10 Open Questions
- [x] Q6: Max plan nesting depth = 3, 4th allowed but flagged. Enforced by dashboard. [Decision Log entry exists.] [Done: 2026-04-07]
- [x] Q7: Dashboard refresh = on-demand. Config added in 10.2 (`dashboard.refresh_mode: "on-demand"`). [Done: 2026-04-07]
- [x] Q8: Ledger = vendored in scripts/lib/. Extract if community adopts. [Done: 2026-04-07]

## Open Questions
- [x] Q1: EARS for acceptance criteria only, not tasks/constraints/evidence. Add optional `[Done-When: EARS statement]` per task or phase-level acceptance criteria blocks. Current task format (checkbox + evidence + depends) is better for agent execution. Kiro validates: EARS for specs, free-form for tasks. [Done: 2026-04-01]
- [x] Q2: Plan readiness = 10-point checklist in LOOP.md. 5 required gates + 5 quality points. Score >= 7 to code, < 7 means refine the plan. [Done: 2026-04-01]
- [x] Q3: SKILL.md alone is sufficient for all 3 tools (agentskills.io open standard). Plugin manifests are for marketplace distribution only, not cross-tool compat. Captain symlinks handle discovery. [Done: 2026-04-01]
- [x] Q4: Agent subagents (not Teams) for fan-out. Teams persist across sessions (violates stateless doctrine), add coordination overhead, and risk orphaned state if cron dies. Subagents are fire-and-forget, perfect for embarrassingly parallel research. Teams reserved for future multi-turn critic debates. [Done: 2026-04-01]
- [ ] Q5: Should the public repo ship example automation harnesses, or stay focused on the skill and loop contract first? -> Action: gather feedback from Issues after first publish.

## Surprises
- [2026-03-31] obra/superpowers (128K stars) already installed in our env. Its brainstorm->plan->execute->verify chain is close to Vidux's gather->plan->execute->verify. Could be a companion rather than competitor.
- [2026-03-31] tick-md (18 stars) uses a single TICK.md file as Git-backed multi-agent task board — structurally identical to what Vidux PLAN.md does. Low stars but exact pattern match.
- [2026-03-31] PAUL (603 stars) has Execute/Qualify/Unify loop with escalation statuses (DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, BLOCKED). The UNIFY step (reconcile planned vs actual) is a gap in our design — should add.
- [2026-04-01] Previous session already landed pilot-ledger-emit.sh + project build recipe + env vars on main (commit 1c8c0f9). Merged into vidux branch. Phase 5 integration is partially done for free.
- [2026-04-01] All 5 swarm agents completed successfully in parallel. Phase 1 + Phase 2 + contract tests all done in one burst. 10/10 tests passing.
- [2026-04-06] The first scaffold pass accidentally mirrored internal root plan files. Impact: public repo would have leaked the wrong story.
- [2026-04-06] Self-investigation revealed: ~/.claude/skills/vidux was a stale DIRECTORY copy, not a symlink. Fixed. But 14 automation prompts hardcode `ai/skills/vidux/SKILL.md`, bypassing all symlinks. Every automation run loads stale vidux with Ralph, old paths, and "smallest slice" language.
- [2026-04-06] Prompt quality audit: strongyes-release-train is 56 lines, 73% restated doctrine. resplit-nurse is ~120 lines. Lean version is 13 lines with 100% project-specific signal density.
- [2026-04-06] Ralph skill was never deleted in Phase 8 — stale copies persisted at ~/.claude/skills/ralph/ and ~/.codex/skills/ralph/ (6157 bytes each, dated Mar 28). Also found resplit-nurse codex automation (7816 bytes, ACTIVE, runs every 20min) still referencing RALPH.md.
- [2026-04-06] vidux-checkpoint.sh had no git repo guard — running on a plan outside a git repo produced raw git `fatal:` error (exit 128). Fixed with rev-parse check.
- [2026-04-06] Claude Code has 3 tiers of scheduling: /loop (ephemeral, 1min), Desktop Scheduled Tasks (persistent, local, 1min), Cloud Scheduled Tasks (Anthropic infra, 1hr). Desktop tasks are the Claude equivalent of Codex automations.
- [2026-04-07] Overnight fleet data reveals structural bimodal failure: resplit-asc fires every 20min but takes 63min per run. 37 resplit-android runs restated "still blocked" at 2-7min each. The REDUCE gate vidux designed (Phase 11) was never actually deployed to live automation prompts — the doctrine exists but the enforcement is missing.

## Decision Log
- [DIRECTION] [2026-04-06] Stage indicators use emoji prefixes (🔍📐⚡✅📌) not color-only. Reason: works in terminal, IDE, CI, and copy-paste. Do not switch to color-only.
- [DIRECTION] [2026-04-06] Max plan nesting depth = 3, with L4 allowed but flagged. Reason: research shows 17x error amplification beyond 4 agents; 3-deep keeps coordination manageable.
- [DIRECTION] [2026-04-06] Ledger is centralized at ~/.agent-ledger/ (not per-project). Reason: single source of truth for cross-tool, cross-worktree coordination. Dashboard reads one location.
- [DIRECTION] [2026-04-06] Dashboard index is machine-local (not git-backed). Reason: plans travel with code via git; dashboard aggregation is local concern. No pollution of repos.
- [DIRECTION] [2026-04-06] vidux-prune.sh has dry-run (--simulate) by default for destructive ops. Reason: pruning completed plans is irreversible without git history spelunking.
- [DIRECTION] [2026-04-06, corrected 2026-04-07] The DB-only fleet rebuild was a local experiment, not a durable default. On the current machine, the live control plane still runs from repo-backed `/Users/leokwan/Development/ai/automations` plus `~/.codex/sqlite/codex-dev.db` until a verified DB-only cutover actually exists. Evidence: `projects/context-ops/evidence/2026-04-07-public-vidux-control-plane-drift.md`. Do not describe DB-only storage as present-tense truth without a fresh fleet audit.
- [DIRECTION] [2026-04-07] Phase 12 addresses the merge-gate gap: automations must land work on the default branch, not just in worktrees. The old launch-loop role was correctly deleted (too complex) but its merge responsibility must be distributed into dispatch mode and each harness.
- [DELETION] [2026-04-06, corrected 2026-04-07] A temporary local pass removed `ai/automations/` and treated the orchestrator as retired, but that did not remain the canonical live state on this machine. Current fleet truth still includes repo-backed `ai/automations/` plus an active `codex-automation-orchestrator` row. Evidence: `projects/context-ops/evidence/2026-04-07-public-vidux-control-plane-drift.md`. Do not cite the temporary removal as current truth.
- [DIRECTION] [2026-04-06] Fleet rebuilt: 33 automations → 12 (4 resplit, 6 strongyes, 1 vidux-meta, 1 media-studio). All harnesses use burst-mode doctrine, 30-min cadences, and self-extending plans. Reason: old writer/radar split was for overnight cycles; new fleet organized by work stream. Evidence: `projects/context-ops/evidence/2026-04-06-fleet-rebuild-final.md`.
- [DIRECTION] [2026-04-06] All harnesses must include MODE: DISPATCH block. Structural bimodal enforcement — quick (<2min) or deep (drain queue), mid-zone (3-8min) is forbidden. Evidence: `projects/vidux-v230/evidence/2026-04-06-burst-vs-watch-mode-insight.md`.
- [DIRECTION] [2026-04-06] Automations self-extend plans. Every automation can add tasks to PLAN.md. No writer/reader distinction. Bounded by three-strike rule to prevent recursive overload.

## Progress
- [2026-04-07] Cycle 34: 🔍→📐→⚡ FULL LOOP — 3-agent fan-out (fleet memory analysis, ledger runtime patterns, prompt quality audit). Wrote comprehensive fleet loop analysis evidence. Planned Phase 15 (5 tasks). Shipped 15.1 (circuit breaker — scans Progress for shipping signals, blocks dispatch after 3 idle cycles) + 15.5 (2 contract tests). Evidence: `fleet-loop-analysis.md`. Key finding: 32% mid-zone rate, strongyes-content 60% idle churn. Next: 15.2-15.4.
- [2026-04-07] Cycle 33: ⚡→📌 CHECKPOINT — Phase 13 COMPLETE (10/10 tasks). compat.sh portability layer confirmed done (hooks-created). All PLAN tasks synced to completed state. 159 tests, all scripts portable. Research evidence (MCO, OpenSpec, circuit breakers) committed. Next: Phase 14 (fleet restructuring) or Phase 15 (research-driven: circuit breaker, task DAG, lease ownership from agentic-patterns-research.md).
- [2026-04-07] Cycle 32: ⚡ EXECUTE — Phase 13 dispatch. Shipped 13.3 (checkpoint sed metachar fix — grep -nF by line number, _mark_task helper), 13.6-13.10 (10 new contract tests: witness JSON validity, compound task docs, doctrine content validation, empty-plan edge case, test-all self-test). 159 total tests. Next: 13.4 (portability layer).
- [2026-04-07] Cycle 31: 🔍→📐→⚡ FULL LOOP — 3-agent fan-out (agentic patterns, coverage audit, hardening audit). Synthesized into Phase 13 (10 tasks). Shipped 13.1 (json_escape +\r, learned python3 per-call too slow), 13.2 (config path injection — 15 instances/6 scripts), 13.5 (doctor 8→1 python3 calls). 149/149 tests pass. Evidence: `2026-04-07-hardening-audit.md`, `2026-04-07-coverage-gaps.md`. Next: 13.3-13.10.
- [2026-04-07] Cycle 30: 📐 PLAN — Fleet overnight diagnosis complete. Cadence-runtime mismatch is critical: 150+ runs across 4 resplit lanes when 30-40 would ship the same work. Phase 14 added with 7 tasks. Evidence at `projects/vidux-v230/evidence/2026-04-07-fleet-overnight-diagnosis.md`. Next: fix cadences, add REDUCE gates, pause dead lanes.
- [2026-04-07] Cycle 29: 📐 PLAN — Public Vidux docs had drifted back to a stale DB-only retirement story even though the live machine still runs `26` repo-backed TOMLs plus `34` SQLite rows with an active orchestrator. Added `projects/context-ops/evidence/2026-04-07-public-vidux-control-plane-drift.md` and corrected the Decision Log so the 2026-04-06 DB-only cutover is treated as a historical experiment instead of current truth. Next: return to the `8` DB-only active rows for an explicit archive/promotion decision once a safe approval path exists.
- [2026-04-06] Cycle 28: ⚡ EXECUTE — Fleet rebuild complete. Deleted 22 old automations, created 11 new burst-mode harnesses (4 resplit + 6 strongyes + 1 vidux-meta). All 30-min cadence except vidux-meta (1hr). Prompts ~2.5-3K chars (down from 5-7K). Burst doctrine, self-extending plans, $picasso + product-taste focus baked into every harness. DB race with Codex app daemon discovered and fixed (close app before writes). Evidence: `projects/context-ops/evidence/2026-04-06-fleet-rebuild-final.md`. Next: verify automations run clean against live plans.
- [2026-04-06] Cycle 27: ⚡ EXECUTE — Retired repo-backed automation source control. Captured full fleet snapshot (13 active automations, topology, patterns, per-automation essence) into evidence. Deleted ai/automations/ from disk. Added gitignore entry. Decision Log entries recorded. Orchestrator role transferred to interactive Leo + Claude sessions. Next: clean up 11 paused DB rows, investigate endurance/v230 scheduler drift.
- [2026-04-06] Cycle 27: ⚡ EXECUTE → ✅ VERIFY — Ledger integration complete (Task 10.3). Built 3-file integration layer in scripts/lib/ (ledger-config.sh, ledger-emit.sh, ledger-query.sh). Wired into vidux-loop.sh (loop_start event, conflict check, ledger_available/ledger_conflicts in JSON output) and vidux-checkpoint.sh (checkpoint event after commit). Updated vidux-manager.md fleet-health and diagnose to use ledger queries. Validated against real production ledger: 3205 entries, 14 automations, bimodal scores computed (resplit-ios: 70% critical). 83/83 tests pass. Next: automation recipes command, then testing.
- [2026-04-06] Cycle 26: ⚡ EXECUTE → ✅ VERIFY — Phase 8 retirement complete. Fixed 9 automation.toml files (old ai/skills/vidux path → canonical /Users/leokwan/Development/vidux). Removed dead ralph refs from orchestrator, dead vidux-amp from media-studio, converted resplit-android relative paths to absolute. Symlink at ai/skills/vidux removed. Next: Phase 10 remaining tasks (10.2, 10.3, 10.7).
- [2026-04-06] Cycle 25: ⚡ EXECUTE → ✅ VERIFY — Phase 10 Tasks 10.1, 10.4, 10.5, 10.6 complete. Stage indicators embedded in /vidux command (6 stages + 3 meta + depth). "DIE" → "COMPLETE" across 9 files. Dashboard command (205 lines), manager command (312 lines), prune script (387 lines) all delivered by team agents. Ralph skill deleted from ~/.claude and ~/.codex. "nursing" → "maintenance" in SKILL.md. Checkpoint.sh git guard added. 83/83 tests pass. 11 agents fanned out total. Next: 10.2 config extensions, 10.3 ledger integration, 10.7 contract tests.
- [2026-04-06] Cycle 24: 📐 PLAN — Phase 10 designed via 5-agent fan-out. Stage indicators, dashboard, ledger integration, backpressure, vidux-manager all specified. 7 tasks, 3 open questions. Evidence synthesis written. 7 additional research agents launched (audit, platform comparison, radar-writer architecture, plan store protection).
- [2026-04-06] Cycle 23: Fleet quality inspector built (vidux-fleet-quality.sh). Scans 15 automations, classifies run durations, reports bimodal verdict. Phase 9 Tasks 1+2+3 done. Next: Phase 9 Task 4 (e2e test) — already validated via self-investigation.
- [2026-04-06] Cycle 22: Example fleet configs created (examples/fleet-reference/). 4 automations: writer + 2 radars + coordinator, staggered slots, lean prompts. Phase 9 Tasks 1+3 done. Next: quality inspector and e2e test.
- [2026-04-06] Cycle 21: Bimodal runtime enforcement added to vidux-doctor.sh (CHECK 11). Self-investigation 5/5 tasks COMPLETE. Phase 9 Task 1 done. 83/83 tests passing, 11/11 doctor checks. Next: Phase 9 remaining tasks (quality inspector, fleet configs, e2e test).
- [2026-04-06] Cycle 20: E2e results collected. NextJS 17/20, iOS 19/20. Both created compound task investigations. Plan quality validated across web and mobile. Self-investigation 4/5 tasks complete. Committing all Phase 8 work. Next: bimodal runtime simulation, then Phase 9.
- [2026-04-06] Cycle 19: Self-investigation launched. Fixed stale skill directory (was copy, now symlink). Discovered 14 automations hardcode old path. Prompt quality audit: most prompts 3-7x too long. E2e test agents swarming on NextJS and iOS — both creating compound task investigations (good). Next: collect e2e results, update investigation PLAN.md, fix automation paths.
- [2026-04-06] Cycle 18: Canonical unification — restored full build history, brought over vidux-development evidence, retired ai/skills/vidux copy. This repo is now the single source of truth.
- [2026-04-06] Cycle 17.5: Published open source repo (leojkwan/vidux). Added README, LICENSE, CONTRIBUTING, guides, .github templates. Rewired all paths to standalone.
- [2026-04-01] Cycle 17: Final session wrap. Hot/cold window in loop script. Archive mode in checkpoint. Tagline aligned. 4-agent audit fixed 12 mismatches. Backed up to lkwan/ai (PR #1). 34/34 tests. V1 COMPLETE.
- [2026-04-01] Cycle 16: V1 finalization complete. Expanded harness (10 -> 34 tests, all passing). 3 guides written (quickstart 88 lines, architecture 181 lines, best practices 187 lines). All 4 scripts verified working. Symlinks verified across 3 tool mounts. Phase 6 complete. Next: cross-tool test (human-blocked). Blocker: none.
- [2026-04-01] Cycle 15: Test cycle: verified scripts work. Next: Add PreToolUse hook guidance: check if target file is in PLAN.md [Evidence: needed]. Blocker: none.
- [2026-03-31 20:15] Cycle 0: Initial SKILL.md + PLAN.md + DOCTRINE.md created. 9 research agents completed. Doctrine established. Cron set up.
- [2026-03-31 20:45] Cycle 1: Open source survey complete (26 tools). Top ingredients identified. Evidence + surprises added to plan. Next: LOOP.md.
- [2026-04-01 00:15] Cycle 2: Architecture refined (two data structures: doc tree + work queue). Company-agnostic layer separation added.
- [2026-04-01 00:30] Cycle 3: 5-agent swarm completed Phase 1 + Phase 2 + contract tests. INGREDIENTS.md, vidux-loop.sh, vidux-checkpoint.sh, vidux-gather.sh, test_vidux_contracts.py all landed. Merged main (pilot improvements). 10/10 tests pass. Next: Phase 3 enforcement + Phase 4 plugin packaging.
- [2026-04-01 01:00] Cycle 4: 3-agent swarm for Phase 3+4. Plugin packaging landed (manifest + 3 commands + hooks.json). ENFORCEMENT.md landed (389 lines, 4 hooks, three-strike gate, enforcement gradient). E2E tests 5/5 pass. Phase 1-4 COMPLETE. Next: Phase 5 integration (Captain install, cross-tool test).
- [2026-04-01 05:07] Cycle 5: Captain install wiring. Surprise: no Captain changes needed — auto-installs via existing symlinks. Added install-hooks.sh (optional enforcement). Next: cross-tool test. Blocker: none.
- [2026-04-01 06:07] Cycle 6: Answered Q2 — plan readiness checklist. Upgraded LOOP.md with 10-point scoring system (5 required + 5 quality). Threshold: 7/10 to code, below = refine plan. Next: Q3 (plugin format).
- [2026-04-01 07:07] Cycle 7: Answered Q3 — SKILL.md alone is the cross-tool format (agentskills.io standard). Plugin manifests NOT needed for interop. Surprise: Phase 4 was over-engineered. Next: Q4.
- [2026-04-01 08:07] Cycle 8: Answered Q4 — Agent subagents beat Teams for cron fan-out. Teams violate stateless doctrine. Next: Q1 (EARS notation).
- [2026-04-01 09:07] Cycle 9: Answered Q1 — EARS for acceptance criteria only (Done-When tags). All 4 open questions now answered. All 5 phases complete except 2 human-blocked tasks. Vidux 1.0 autonomous build is DONE. Remaining: Leo tests cross-tool and cross-machine manually.
<!-- 39 tasks archived to ARCHIVE.md -->
