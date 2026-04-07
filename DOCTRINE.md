# Vidux Doctrine

> The short form of the 12 principles in `SKILL.md`. Read this in 5 minutes; everything else follows.
> Principles 7-12 (investigations, harnesses, subagents, loop discipline) live in `SKILL.md` — they apply when the situation calls for them.

## 1. Plan is the store

**PLAN.md is the single source of truth. Code is a derived view.**

If the code is wrong, the plan is wrong. Fix the plan first, then fix the code. An agent that edits code without a corresponding plan entry is mutating the store outside the reducer — it makes the system unpredictable.

## 2. Unidirectional flow

**Gather -> Plan -> Execute -> Verify -> Checkpoint -> Gather. Never skip a step.**

You never code without a plan entry. To change code in a way the plan does not specify, you MUST update the plan first. The cost of skipping a step is invisible in any single cycle but devastating over a multi-day project.

## 3. 50/30/20 split

**50% plan refinement. 30% code. 20% last mile. If you are coding more than planning, stop.**

```
┌──────────────────────────┬───────────────┬──────────┐
│  50% PLAN REFINEMENT     │  30% CODE     │  20% LM  │
│  gather evidence,        │  one task     │  build,  │
│  synthesize, prune,      │  per cycle,   │  CI,     │
│  update PLAN.md          │  derived      │  review  │
└──────────────────────────┴───────────────┴──────────┘
   ◄─── front-load thinking ────► ◄─ mechanical ─► ◄ tail ►
```

If your git history is >30% code commits, the plan was not good enough. Inverting this ratio causes rework that costs more than the planning overhead.

## 4. Evidence over instinct

**Every plan entry cites a source. No source = no entry.**

Sources are MCP queries, codebase greps with file:line, design doc quotes, or team conventions cited from PR review history. A plan entry without evidence is a guess. Guesses cause rework. Gathering evidence adds 2-5 minutes per task; a wrong assumption costs 15-60 minutes plus ripple effects.

## 5. Design for completion

**Dispatches end. Context is lost. Auth expires. The store persists.**

State lives in files (PLAN.md, git branch), not in memory. Every cycle reads fresh from disk and never carries context forward. Checkpoints are structured, not freeform summaries. Any agent can resume from the last checkpoint. Tool state (`.claude/`, `.cursor/`) lives outside the working tree.

## 6. Process fixes > code fixes

**Every failure produces two artifacts: a code fix and a process fix. The process fix is the valuable one.**

The code fix is the immediate repair. The process fix is a new constraint, test, hook, or skill update — it makes the system smarter for next time. Without process fixes, the same class of error recurs across cycles and a single bad assumption propagates exponentially through dependent tasks.

---

## Loop Discipline

**Run quick or run deep, never in between. Self-extend the plan with taste. Stop when good enough is good enough.**

Healthy automation runs are bimodal: reduce (<2 min, read-only, checkpoint and exit) or dispatch (15+ min, real work, full e2e cycle). Mid-zone exits are stuck agents quitting at the first natural milestone. Inside a dispatch run, the agent should self-extend the plan as it spots related bugs, polish, and edge-cases — don't wait for the user to enumerate work. But self-extension needs the three-strike brake (Doctrine 11): when a surface has 3+ queued polish tasks, ship the most impactful and move on. See Doctrines 10-11 below and `SKILL.md` principles 10, 11, 12 for full text.

## 10. Dispatch/Reduce — loop duration is structural, not judgmental

**DISPATCH mode = deep work, drain the queue, no upper time bound. REDUCE mode = read-only, feed evidence back into the store, <2 min.**

The cron fires REDUCE. REDUCE decides whether to fire DISPATCH. Mid-zone (3-8 min) is structurally eliminated — the agent never has to decide when to stop because the mode already decided. This is the Redux cycle: `dispatch(action)` fires a long execution; `reducer(state, action)` reads the result and produces new state. DISPATCH yields only on queue drain, hard blocker, or context budget. REDUCE yields always — it is a pure function of the current store.

## 11. Self-extending plans with bounded recursion

**Every automation can add tasks to PLAN.md — do not wait for Leo. But know when good enough: three-strike rule prevents recursive overload.**

Agents that spot related bugs, edge cases, or polish opportunities during execution should add them to the plan immediately. The brake: if a surface already has 3+ queued polish tasks, ship the most impactful one and move on. This prevents the recursive trap where an agent endlessly discovers work faster than it ships. The goal is net progress, not exhaustive coverage.

---

## The Redux Analogy

| Redux | Vidux |
|-------|-------|
| Store | PLAN.md |
| Actions | Plan amendments (require evidence) |
| Reducers | Gather + synthesize + critique |
| View | Code (derived, never independent) |
| Dispatch | Must go through the plan |
| DevTools | Ledger (reconstruct any mission) |

---

## When Vidux vs When Pilot

| Signal | Use |
|--------|-----|
| Quick bug fix, single file, < 2 hours | Pilot (Mode A) |
| PR nursing, CI fixes, review responses | Pilot |
| Multi-day feature, 8+ files, multiple concerns | **Vidux (Mode B)** |
| Quarter-long project compressed to a week | **Vidux (Mode B)** |
| "We need to plan this" | **Vidux** |
| "Just do it" | Pilot |
