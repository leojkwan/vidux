# Vidux Doctrine

> If an agent reads one file, this is it. 11 principles, each battle-tested across 28+ cycles building Vidux itself, a 10-automation fleet across Resplit and StrongYes, and overnight cron loops that run unsupervised.

## 1. Plan is the store

PLAN.md is the single source of truth. Code is a derived view. If the code is wrong, the plan is wrong. Fix the plan first. An agent that edits code without a corresponding plan entry is mutating state outside the reducer.

*Why this matters: The Resplit iOS fleet drifted 400+ lines from spec in 6 cycles before this rule existed. SlopCodeBench confirms it -- agent code degradation is monotonic.*

## 2. Unidirectional flow

Gather -> Plan -> Execute -> Verify -> Checkpoint -> Gather. Never skip a step. To change code in a way the plan does not specify, update the plan first. The cost of skipping is invisible per-cycle but devastating over a multi-day project.

*Why this matters: swiftify-v4 skipped evidence gathering and built a Combine implementation the team wanted in async/await. Three full reworks.*

## 3. 50/30/20 split

50% plan refinement. 30% code. 20% last mile. If you are coding more than planning, stop.

```
|  50% PLAN REFINEMENT     |  30% CODE     |  20% LM  |
|  gather, synthesize,     |  one task     |  build,  |
|  prune, update PLAN.md   |  per cycle    |  CI,     |
|                          |  derived      |  review  |
   <-- front-load thinking --> <mechanical> <- tail ->
```

*Why this matters: Vidux built itself in 56/25/19. swiftify-v4 inverted the ratio. Guess which one shipped clean.*

## 4. Evidence over instinct

Every plan entry cites a source. No source = no entry. Sources: MCP queries, codebase greps with file:line, design doc quotes, PR review history. A guess costs 15-60 minutes of rework. Evidence costs 2-5 minutes.

*Why this matters: A Resplit automation assumed the currency API returned ISO codes. It returned integers. Three downstream tasks built on the wrong assumption.*

## 5. Design for completion

Dispatches end. Context is lost. Auth expires. The store persists. State lives in files, not memory. Every cycle reads fresh. Checkpoints are structured. Any agent can resume from the last checkpoint. Tool state (.claude/, .cursor/) lives outside the working tree.

*Why this matters: A StrongYes overnight loop lost auth at 3am. The next cron fire committed recovered work and continued. Zero human intervention.*

## 6. Process fixes > code fixes

Every failure produces two artifacts: a code fix (table stakes) and a process fix (the valuable one -- a new constraint, test, hook, or skill update). Without process fixes, the same error class recurs across cycles with 17x amplification through dependent tasks.

*Why this matters: The drift detection hook, checkpoint enforcement, and three-strike gate all came from failures that were analyzed, not just patched.*

## 7. Bug tickets are nested investigations

When 2+ tickets hit the same surface, or 3+ atomic fixes fail on the same surface, bundle them into one `[Investigation: investigations/<slug>.md]`. Atomic fixes to compound problems contradict each other. The investigation file finds the root cause before committing to a fix direction.

*Why this matters: Three separate Resplit agents applied contradictory fixes to the same payment flow. One investigation would have found the shared root cause in 15 minutes.*

## 8. Cron prompts are harnesses, not snapshots

A harness encodes the end goal and project DNA. PLAN.md holds the state. The harness tells the agent what kind of work to do; the plan tells it which specific work is next. Never put transient state in the harness. Never put project DNA in the plan.

*Why this matters: A StrongYes harness that hard-coded "fix the auth flow" kept trying to fix auth after auth was done. Harness = what kind of work. Plan = which work.*

## 9. Subagent coordinator pattern

Fan out research (4 parallel agents, each writes its own file). Fan in through one synthesizer. Cap coding agents at 4 with a point guard. Research agents can go wider (read-only, no merge conflicts). Never have N agents write the same file.

*Why this matters: 17x error amplification beyond 4 parallel agents without hierarchy. The Vidux build ran 9 research agents successfully because they were read-only.*

## 10. Dispatch/Reduce -- loop duration is structural, not judgmental

DISPATCH = deep work, drain the queue, ship code, no upper time bound. REDUCE = read-only, feed evidence back into the store, under 2 minutes. The cron fires REDUCE. REDUCE decides whether to fire DISPATCH. Mid-zone (3-8 min) is structurally eliminated -- the agent never decides when to stop because the mode already decided.

This IS the Redux cycle: `dispatch(action)` fires a long execution; `reducer(state, action)` reads the result and produces new state. DISPATCH yields only on queue drain, hard blocker, or context budget. REDUCE yields always.

```
Cron
 |
 v
REDUCE (<2 min, read-only)
 |
 +--> nothing pending? --> checkpoint, exit
 |
 +--> work pending? --> fire DISPATCH
                         |
                         v
                    DISPATCH (15+ min, real work)
                         |
                         +--> drain queue until:
                              - queue empty
                              - hard blocker
                              - context budget hit
                         |
                         v
                    checkpoint, exit
```

*Why this matters: Claude Code #34238 -- agents have a learned closure bias. They hit the first natural milestone and invent reasons to quit. Bimodal enforcement kills the mid-zone where stuck agents masquerade as polite ones.*

## 11. Self-extending plans with bounded recursion

Automations add tasks to PLAN.md themselves -- do not wait for the human. When you fix a bug, log the related bugs you saw. When you add a feature, log the polish and edge-cases. Think N steps ahead.

The brake: three-strike rule. If a surface already has 3+ queued polish tasks, ship the most impactful one and move on. Self-extension without a brake becomes recursive optimization forever. A good automation knows when a surface is honestly good and stops adding work to its own queue.

*Why this matters: A Resplit automation discovered 14 polish tasks on a single view controller. Without the three-strike brake it would still be polishing. With the brake it shipped the top 3 and moved to the next gap in the mission.*

---

## The Redux Analogy

| Redux | Vidux |
|-------|-------|
| Store | PLAN.md |
| Actions | Plan amendments (require evidence) |
| Reducers | REDUCE mode -- read store, produce new state |
| dispatch() | DISPATCH mode -- deep work, drain the queue |
| View | Code (derived, never independent) |
| DevTools | Git log + Ledger (reconstruct any mission) |

---

## When Vidux vs When Pilot

| Signal | Use |
|--------|-----|
| Quick bug fix, single file, < 2 hours | Pilot (Mode A) |
| PR nursing, CI fixes, review responses | Pilot |
| Multi-day feature, 8+ files, multi-session | **Vidux (Mode B)** |
| Quarter-long project compressed to a week | **Vidux (Mode B)** |
| "We need to plan this" | **Vidux** |
| "Just do it" | Pilot |
