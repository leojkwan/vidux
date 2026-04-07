# 2026-04-07 -- Continuous Feedback Loop Research for Vidux Phase 12

## Goal

Research how to close the feedback loop in vidux's automation fleet. Three diagnosed problems drive this: (1) automations ship code to worktrees but nobody merges to master or cuts a build, (2) stuck automations burn cycles saying "still blocked" with no auto-pause, (3) self-extending plans (Doctrine 11) have no quality gate on whether extensions are valuable or recursive polish.

## Sources

- [Source: Gastown README + AGENTS.md, github.com/steveyegge/gastown] Witness is a per-rig lifecycle manager that monitors polecats, detects stuck agents, triggers recovery, manages session cleanup. Deacon runs continuous patrol across all rigs. Three-tier watchdog: Daemon (Go, heartbeat every 3 min) -> Boot (AI, intelligent triage) -> Deacon (AI, continuous patrol) -> Witness (per-rig).
- [Source: paddo.dev/blog/gastown-two-kinds-of-multi-agent] Gastown separates Polecats (cattle, ephemeral) from Crew (pets, persistent). Duration is structural, not judgmental.
- [Source: softwareengineeringdaily.com/2026/02/12/gas-town-beads-and-the-rise-of-agentic-development] Beads are chained sequences of small tasks stored in Git. Each step has explicit acceptance criteria. Nondeterministic idempotence: different paths, convergent outcomes.
- [Source: cogentinfo.com/resources/when-ai-agents-collide] "You cannot ask an agent if it is in a loop; you must prove it mathematically." Circuit breakers detect linguistic signatures of stuck agents (polite repetition, hallucination consensus).
- [Source: futureagi.substack.com/p/why-do-multi-agent-llm-systems-fail] Structured critique loops: generate, evaluate, optionally regenerate -- bounded by quality threshold and max attempt count.
- [Source: factory.ai + fritz.ai/factory-ai-review] Factory.ai delivers full-code PRs ready to review and merge. CI monitoring with auto-fix on failure. Most production teams keep human-in-the-loop at merge stage.
- [Source: leocardz.com/2026/04/01/agent-factory-that-ships-code] Factory Factory runs dozens of agents across isolated worktrees. PRs monitored every minute. CI fail -> agent fixes. Merge conflict -> agent resolves.
- [Source: augmentcode.com/guides/autonomous-quality-gates] Autonomous quality gates: AI-powered code review as merge prerequisite.
- [Source: docs.gitlab.com/user/project/merge_requests/auto_merge] GitLab auto-merge: merge when pipeline succeeds + required approvals met.
- [Source: medium.com/@sohamghosh_23912/self-correcting-multi-agent-ai-systems] Self-correction via structured critique: agent reviews quality of own actions, triggers memory rewrite or peer review.
- [Source: microsoft.com/en-us/dynamics-365/blog/.../ai-agent-performance-measurement] Agent ROI requires tracking four dimensions: technical performance, business impact, safety/compliance, user experience.
- [Source: scripts/vidux-loop.sh:259-301] Vidux already auto-blocks tasks after 3+ Progress entries without completing. Flips [in_progress] -> [blocked] and logs to Decision Log.
- [Source: scripts/lib/ledger-query.sh:38-131] Bimodal distribution scoring computes quick/deep/mid/normal buckets with fleet-wide bimodal_score. Currently measurement-only, not enforcement.
- [Source: scripts/vidux-fleet-quality.sh] Fleet quality inspector classifies runs by duration from memory.md files. Reports per-automation and fleet-wide bimodal scores.
- [Source: projects/vidux-v230/evidence/2026-04-06-burst-vs-watch-mode-insight.md] Prior research establishing the watch/burst structural separation. Watch mode decides whether to fire burst; burst runs to completion.

## Findings

### 1. Merge-Gate Pattern: PR-First with Conditional Auto-Merge

**Problem:** Automations complete work in git worktrees but the code never reaches master.

**What others do:**
- Factory.ai creates full PRs with diffs ready for human review. CI monitoring auto-fixes failures. Most production teams keep human-in-the-loop at the merge stage.
- Factory Factory monitors PRs every minute. CI fail triggers agent fix. Merge conflicts trigger agent resolution.
- GitLab's auto-merge pattern: merge automatically when pipeline succeeds AND required approvals are met.
- Gastown's Polecats produce "merge requests" as their output artifact, not direct merges.

**Synthesis for vidux:**
The merge gate should be a two-tier system:

- **Tier 1 (auto-merge eligible):** Changes that pass all of: (a) CI green, (b) no new files created (only modifications), (c) diff < 200 lines, (d) no changes to public API surface. These can auto-merge to master if the automation's PLAN.md task was marked [completed] with evidence.
- **Tier 2 (PR required):** Everything else. The automation creates a PR with a structured body (task description from PLAN.md, evidence cited, diff summary). A human or a reviewer automation approves.

**Implementation:** Add a `vidux-merge-gate.sh` script that runs after `vidux-loop.sh --checkpoint`. It inspects the worktree diff against master, classifies it as Tier 1 or Tier 2, and either auto-merges or creates a PR via `gh pr create`. The PLAN.md Decision Log gets a [MERGE] entry either way.

### 2. Auto-Pause for Stuck Automations: N-of-M Memory Scoring

**Problem:** resplit-android runs every 20 minutes, takes 5 minutes each time saying "still blocked." The system can see this (bimodal mid-zone, memory logs) but cannot act on it.

**What others do:**
- Gastown's Witness detects stuck agents per-rig. Configurable thresholds (moved to agent config). Recovery actions: nudge (retry), handoff (refresh context). Three-tier escalation: Witness -> Deacon -> human.
- Cogent's 2026 failure playbook: "You cannot ask an agent if it is in a loop; you must prove it mathematically." Circuit breakers detect linguistic stuck signatures (polite repetition, same-state acknowledgment).
- Budget exhaustion as a hard backstop: kill the process, revoke tool access, throw BudgetExhaustionException.
- Vidux already auto-blocks tasks after 3+ Progress entries (vidux-loop.sh:259-301). But this is per-task, not per-automation.

**Synthesis for vidux:**
Auto-pause should operate at the automation level, not just the task level. The threshold:

- **N-of-M rule:** If the last N out of M memory entries for an automation contain any of: "blocked", "still blocked", "proof-refresh only", "no actionable work", "waiting on" -- AND the bimodal classification of those N runs is 100% mid-zone -- then pause the automation.
- **Recommended defaults:** N=3, M=5 (3 out of last 5 runs are stuck + mid-zone).
- **Pause mechanism:** Write a `PAUSED` sentinel file to the automation directory. `vidux-loop.sh` checks for this file before firing burst. Log a [PAUSE] entry to Decision Log with reason.
- **Unpause mechanism:** (a) Human removes the PAUSED file, (b) the blocker resolves (detected by a lightweight watch-only check that runs even when paused, every 4x the normal cadence), (c) scheduled auto-review after 24 hours.
- **Escalation:** Paused automations surface in `vidux-doctor.sh` health checks and `vidux-fleet-quality.sh` reports.

### 3. Bimodal Enforcement as Live Metric: Fleet-Wide Gate

**Problem:** Bimodal score is computed by ledger-query.sh but not enforced. The fleet can degrade to all-mid-zone with no consequence.

**What others do:**
- Gastown structurally prevents mid-zone by separating agent classes (Polecats vs Crew). Duration is a property of the role, not the agent's judgment.
- Vidux already has this structural separation (watch mode vs burst mode, per 2026-04-06 evidence). But it is not enforced at the fleet level.

**Synthesis for vidux:**
Bimodal enforcement should be a circuit breaker on burst mode, not a hard block on individual runs.

- **Fleet-level gate:** Before `vidux-loop.sh` emits `next_action: burst`, check the fleet bimodal score from the last 24 hours. If below 70%, downgrade to `next_action: watch_only` with a `fleet_degraded: true` flag. This prevents compounding bad runs.
- **Per-automation gate:** If a specific automation's bimodal score drops below 50% (majority mid-zone), that automation cannot fire burst until its score recovers. Watch cycles still run (they are quick by design).
- **Cadence adjustment:** When fleet bimodal score is 70-85% (warning zone), double the watch interval. When below 70% (critical), quadruple it. This creates backpressure that forces the system toward either quick exits or genuine deep work.
- **Recovery:** Scores are rolling 24-hour windows. One good deep run or several clean quick exits raise the score naturally. No manual intervention needed for recovery.

### 4. Self-Extension Quality: Task Delta Scoring

**Problem:** Automations self-extend PLAN.md (Doctrine 11) but some extensions are valuable (real bugs found during implementation) while others are recursive polish (reformatting, re-testing already-passing code, adding docs to internal utilities).

**What others do:**
- Microsoft's agent performance measurement framework tracks four dimensions: technical performance, business impact, safety/compliance, user experience. Self-extension maps to "business impact" -- did the new task produce user-visible value?
- Gastown's Beads have explicit acceptance criteria per step. A self-extended task without acceptance criteria is structurally incomplete.
- The structured critique loop pattern (generate, evaluate, regenerate) applies: self-extensions should be evaluated before they enter the queue.

**Synthesis for vidux:**
A **Task Delta Score** measures self-extension quality by comparing the added task to the mission purpose:

- **High-value extensions (score 3):** Bug found during implementation, failing test discovered, security issue, missing error handling that would cause production failure. Signal: references a specific file:line, cites a test failure, or links to an external issue.
- **Medium-value extensions (score 2):** Refactoring that unblocks a downstream task, documentation that a handoff partner needs, test coverage for an untested public API. Signal: references another task in PLAN.md by ID.
- **Low-value extensions (score 1):** Polish (rename variables, reformat), documentation for internal implementation details, additional tests for already-covered paths, "nice to have" improvements. Signal: no external reference, no downstream dependency, description contains "also", "while we are at it", "might as well".
- **Enforcement:** Self-extended tasks with score 1 go to a `## Backlog` section, not the active task queue. They are never auto-executed. Score 2-3 enter the queue normally. The scoring is done by `vidux-loop.sh` at read time using keyword heuristics (not LLM judgment -- keep the loop stateless and fast).
- **Measurement:** Track the ratio of score-3 to score-1 extensions per automation over time. A healthy automation self-extends mostly at score 2-3. An automation that generates >50% score-1 tasks is in recursive polish mode and should be flagged.

### 5. Witness Pattern: Centralized Witness, Not Self-Witness

**Problem:** Should each automation self-witness (detect its own stuck state), or should there be a dedicated witness?

**What Gastown does:**
- Witness is a dedicated per-rig agent, separate from the workers. Workers do NOT self-witness.
- Three-tier watchdog: Daemon (heartbeat, 3 min) -> Boot (AI triage) -> Deacon (continuous patrol across all rigs) -> Witness (per-rig lifecycle).
- The rationale is explicit: "You cannot ask an agent if it is in a loop; you must prove it mathematically." Self-diagnosis is unreliable because the mechanism needed for the answer is what is currently broken.

**What vidux already has:**
- `vidux-loop.sh` has stuck-loop detection (3+ Progress entries = auto-block). This is self-witnessing at the task level.
- `vidux-doctor.sh` has fleet-wide health checks. This is a manual witness (human runs it).
- `vidux-fleet-quality.sh` classifies run quality. This is measurement, not witness.

**Synthesis for vidux:**
Vidux should NOT add a full Witness automation (too much infrastructure for a single-developer fleet of 3-6 automations). Instead, elevate the existing watch mode into a lightweight witness role:

- **Watch-as-witness:** Every watch cycle already reads PLAN.md and computes stuck/blocked/bimodal state. Extend it to also read the last 3 memory entries of peer automations and flag anomalies. This is 30 seconds of extra work per watch cycle.
- **Anomaly flags:** (a) Automation has not run in >2x its expected cadence (stale), (b) last 3 runs all mid-zone (stuck), (c) worktree has uncommitted changes >4 hours old (crashed session), (d) PLAN.md has [in_progress] task with no Progress entry in >2 hours (abandoned).
- **Escalation path:** Anomalies logged to a shared `fleet-health.json` file. `vidux-doctor.sh` reads this file and surfaces anomalies. If anomaly count exceeds threshold (3+ across fleet), doctor emits a Slack/notification webhook.
- **Why not a dedicated Witness automation:** At vidux's scale (3-6 automations), a dedicated Witness is overhead. The watch cycle already runs every 10-20 minutes per automation. Having each watch cycle spend 30 seconds checking peers gives N witness checks per hour for free. A dedicated Witness only becomes worth it at 10+ automations.

## Recommendations

### R1: Ship vidux-merge-gate.sh (closes the biggest gap)

The merge-gate is the highest-priority fix because it closes the "last mile" problem. All the intelligence in the system is wasted if code never reaches master. Implementation: a new script that runs post-checkpoint, classifies diffs as Tier 1 (auto-merge) or Tier 2 (PR), and acts accordingly. Estimated effort: 1 session. Add a [MERGE] or [PR] entry type to the Decision Log schema.

### R2: Add auto-pause with N-of-M memory scoring to vidux-loop.sh

This is the second-highest priority because it stops the waste. The N=3, M=5 rule with PAUSED sentinel file is simple, stateless, and reversible. Add it as a new section in vidux-loop.sh between stuck-loop detection and the output JSON. Add a `paused` field to the JSON output. Add PAUSED file detection to vidux-doctor.sh health checks. Estimated effort: 1 session.

### R3: Add fleet bimodal gate before burst firing

Modify vidux-loop.sh to call `ledger_bimodal_distribution` before emitting `next_action: burst`. If fleet score < 70%, downgrade to `next_action: watch_only`. This is 10 lines of code but requires ledger-query.sh to be sourced in the loop (it already is for conflict checks). Add the `fleet_bimodal_score` and `fleet_degraded` fields to the JSON output. Estimated effort: 30 minutes.

### R4: Add Task Delta Score heuristic for self-extensions

Add a keyword-based scoring function to vidux-loop.sh that classifies self-extended tasks. Tasks with score 1 (polish) get routed to ## Backlog instead of the active queue. This prevents recursive polish from consuming burst cycles. Track the score distribution in the ledger for fleet health reporting. Estimated effort: 1 session.

### R5: Elevate watch mode to witness role (peer health checks)

Extend vidux-loop.sh watch mode to read peer automation state (last 3 memory entries, worktree status, cadence staleness). Write anomalies to fleet-health.json. This is the lowest priority because vidux-doctor.sh already covers most of this manually, but automating it closes the "nobody is watching the watchers" gap. Estimated effort: 1-2 sessions.

### R6: Do NOT add a dedicated Witness automation yet

At current fleet scale (3-6 automations), the overhead of a dedicated Witness exceeds its value. Revisit when the fleet exceeds 10 automations or when the watch-as-witness pattern proves insufficient.

## Priority Order

1. R1 (merge-gate) -- highest impact, closes the biggest gap
2. R2 (auto-pause) -- stops active waste
3. R3 (bimodal gate) -- prevents compounding degradation
4. R4 (task delta score) -- improves self-extension quality
5. R5 (watch-as-witness) -- completes the feedback loop
6. R6 (no dedicated witness) -- deliberate non-action

## Decision (proposed)

Adopt R1-R5 as Phase 12 of vidux-v230. Ship R1 and R2 first (they address the diagnosed problems directly). R3 is a quick follow-on. R4 and R5 are stretch goals for the phase. Add Doctrine 13: "Feedback is structural, not aspirational" to codify the principle that measurement without enforcement is waste.
