# 2026-04-06 — Burst vs Watch Mode: Structural Bimodal Enforcement

## Goal
Capture a structural insight from the /vidux swarm session: vidux currently relies on prompt discipline to enforce bimodal distribution, but the bimodal failure mode is so persistent it deserves a structural fix — two distinct execution modes instead of one cron pattern.

## Sources
- [Source: research agent gastown-research, 2026-04-06] Gastown separates Polecats (cattle, ephemeral, parallelizable work) from Crew (pets, persistent, judgment-heavy work). Different agents for different durations — never one agent doing both.
- [Source: research agent claude-loop-research, 2026-04-06] Claude Code issue #34238: agents have a learned closure bias and quit at natural milestones even when work remains. Issue #40125: persistent /loop sessions are 10x more efficient than spawning fresh processes.
- [Source: scripts/lib/ledger-query.sh:38-126] Vidux already computes bimodal distribution (quick/deep/mid/normal buckets) but only as a *measurement*, not an *enforcement*. The system can SEE mid-zone runs but cannot PREVENT them.
- [Source: feedback_vidux_automation_doctrine.md] Leo's Rule 1: "either we stop or we truly go as long as we can." Mid-zone is the disease.
- [Source: projects/resplit/PLAN.md] Resplit's peak fleet (writer + radars + launch-loop + nurse) was 4 automations all running on the same cron schedule. None of them were structurally distinguished by duration.

## Findings

### 1. The current model is one-mode, prompt-enforced

Vidux today has exactly one execution pattern: stateless cron cycle. Every cycle:
1. Reads PLAN.md fresh from disk
2. Decides what to do (refine plan or pop a task)
3. Executes one slice
4. Checkpoints
5. Yields

Whether the cycle takes 90 seconds (no work to do) or 25 minutes (real implementation) is determined entirely by the agent's judgment in the moment. There is no structural mechanism that says "this cycle is supposed to be a quick check" vs "this cycle is supposed to do deep work."

The bimodal distribution model in `ledger-query.sh` measures the result, but the system has no way to enforce the bimodal shape. Mid-zone runs (3-8 min) happen because agents start work, hit a closure trigger, and quit before crossing into deep territory.

### 2. Gastown solved this with two agent classes, not one

The Gastown research showed that Steve Yegge's system explicitly separates:
- **Polecats** (cattle): ephemeral workers, well-specified task, execute and terminate. Short-lived by design.
- **Crew** (pets): long-lived agents for design, review, sustained collaborative work. Accumulate context.

The key insight: **the loop duration is a property of the agent class, not the agent's judgment.** A Polecat can't "decide" to become a Crew. The structural separation eliminates the mid-zone failure mode because there is no "in between" state to fall into.

Vidux today expects one agent class to handle both modes. That's why mid-zone happens.

### 3. Vidux should have two execution modes

**Burst mode** — long persistent session, runs as long as work exists
- Triggered by: user, or watch mode finding queue depth > 0
- Duration: until queue is empty OR a hard external blocker hits OR context budget exceeded
- Use for: active development, e2e implementation, deep investigations
- Stop conditions: queue empty (good), unresolvable blocker (bad), context budget hit (forced — checkpoint and spawn fresh)
- Maps to: Gastown Polecats running until done

**Watch mode** — stateless cron, fires every N minutes, expected to be quick
- Triggered by: cron schedule
- Duration: < 2 minutes by design
- Use for: detecting new work, reading state, deciding whether to fire a burst
- Stop conditions: any work found → either pop one tiny task OR fire a burst session and exit
- Maps to: Gastown Witness role (detects work, doesn't do work)

The two modes have completely different stop conditions, which eliminates the mid-zone judgment call. A watch cycle that takes 7 minutes is a bug. A burst cycle that runs 25 minutes is healthy.

### 4. Implementation sketch

**Watch mode** (existing vidux-loop.sh, slightly tightened):
- Hard time budget: 2 minutes
- Allowed actions: read PLAN.md, check ledger, read git log, write checkpoint
- Forbidden actions: code changes, evidence gathering, plan refinement
- Output: JSON with `next_action: burst|none`

**Burst mode** (NEW, vidux-burst.sh or similar):
- Hard time budget: until queue drains, no upper limit (but context budget enforced via subagent fan-out)
- Allowed actions: everything
- Required: explicit "keep working through the queue" directive in the prompt
- Output: JSON with `slices_completed`, `surprises_logged`, `next_burst_recommended`

The cron schedules **only watch mode**. Watch mode decides whether to fire burst. Burst mode runs to completion, then exits cleanly.

### 5. Why this isn't just "longer timeouts"

The naive fix would be: tell agents to run longer. But Issue #34238 shows that doesn't work — the closure bias is in the model's reflexes, not its config. The agent will quit at the next milestone regardless of timeout.

The structural fix is: don't ask the same agent to do both quick checks and deep work. Use two different agents with two different prompts and two different success criteria. The agent doing burst work has no choice but to keep going because that's its only mode. The agent doing watch work has no choice but to be brief because that's its only mode.

This is also why Gastown works at 20-30 agent scale: nobody is making per-cycle judgment calls about "should I quit now?" — the role itself defines the answer.

## Recommendations

1. **Add `vidux-burst.sh`** to the scripts/ directory. Mirror vidux-loop.sh's structure but with the explicit "keep working" semantics and no time budget.
2. **Update `vidux-loop.sh`** to be explicit watch mode. Add a hard 2-minute budget. Add `next_action` to JSON output.
3. **Add `/vidux-burst` command** that humans can fire manually to drain a queue. Codex automations should fire it from watch mode.
4. **Update Doctrine 8** (cron prompts are harnesses) with a section on watch vs burst. Each harness must declare its mode.
5. **Update Doctrine 5** (design for yield) — yield is for watch mode. Burst mode yields only on completion or hard blocker.
6. **Add a new doctrine** if structural separation isn't covered: "Doctrine 10: Loop duration is structural, not judgmental."

## Decision (proposed)

Adopt the burst/watch separation as a v2.4.0 feature. Land in vidux-v230 project as Phase 11. Refactor vidux-loop.sh + add vidux-burst.sh + update doctrine. Resplit fleet should use burst mode for all 3 harnesses (web, asc, currency) with watch-mode triggers.
