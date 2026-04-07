# Vidux Doctrine

> If an agent reads one file, this is it. 12 principles, each battle-tested across 28+ cycles building Vidux itself, a 10-automation fleet across Resplit and StrongYes, and overnight cron loops that run unsupervised.

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

---

## Loop Discipline (Principles 10-12)

These three principles form a closed loop: 10 defines the two execution modes, 11 says agents must extend the plan as they work, and 12 brakes self-extension before it becomes recursive optimization. Together they eliminate the two failure modes of autonomous agents -- quitting too early and never quitting at all.

## 10. Run quick or run deep -- never in between

Healthy runs are bimodal: <2 min (nothing to do, checkpoint and exit) or 15+ min (real work, full e2e cycle). Mid-zone runs (3-8 min) are the disease. Agents have a learned closure bias: they hit the first natural milestone (a commit, a sub-task, a build pass) and invent reasons to quit. The bimodal distribution model eliminates this structurally -- the mode decides when to stop, not the agent.

Every harness must say "if you checkpoint in under 5 minutes and pending work remains, you stopped too early -- pick up the next task." Quick exits are healthy when nothing is pending; mid-zone exits are stuck agents masquerading as polite ones.

*Why this matters: Claude Code #34238 documents the closure bias pattern. Gastown's dispatch/reduce research found the same bimodal shape: short reduce cycles that find nothing, or long dispatch runs that finish real work, with very little in between.*

## 11. Self-extending plans with taste

Don't wait for the user to enumerate work. Think N steps ahead, add tasks you spot, and apologize later if wrong. When you fix a bug, log the related bugs you saw on the same surface and queue them. When you add a feature, log the polish and edge-cases you spotted. If you are not extending the plan, you are not paying attention.

Agents are good at functional code (Stripe wiring, schema migrations, build configs). They are bad at taste -- anticipating what the user wants without being told, noticing the related polish on the same surface, thinking two or three steps past the current task. Vidux automations are the *amp* for product taste, not just a build runner.

*Why this matters: Readers AND writers can self-extend the plan as they discover things. Definition of done for UI work is a simulator screenshot or visual proof, never just "the build passes."*

## 12. Bounded recursion -- know when good enough is good enough

Self-extension without a brake becomes recursive optimization forever. A good automation knows when a surface is honestly good and stops adding work to its own queue. Three-strike rule: if a surface already has 3+ queued polish tasks, ship the most impactful one and move on. Don't optimize already-good surfaces. If overall mission has gaps elsewhere, polish on a done surface is procrastination.

*Why this matters: A Resplit automation discovered 14 polish tasks on a single view controller. Without the three-strike brake it would still be polishing. With the brake it shipped the top 3 and moved to the next gap in the mission.*

---

## Dispatch / Reduce

The two execution modes follow the Redux analogy exactly.

**DISPATCH** = deep work mode. Fire actions, drain the queue, ship code. No upper time bound. DISPATCH yields only on queue drain, hard blocker, or context budget. This is `dispatch(action)` -- it fires a long execution.

**REDUCE** = feedback mode. Read results, feed evidence back into the store, improve the plan. Under 2 minutes, always read-only. The cron fires REDUCE. REDUCE decides whether to fire DISPATCH. This is `reducer(state, action)` -- it reads the result and produces new state.

Mid-zone (3-8 min) is structurally eliminated -- the agent never decides when to stop because the mode already decided.

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

**Terminology:** DISPATCH and REDUCE only. Never "burst" or "watch" -- those terms are rejected. The Redux metaphor is load-bearing.

### REDUCE Gate

The REDUCE gate is a literal text block inserted at the top of every automation harness prompt. It forces the agent to evaluate actionable work *before* loading skills or reading authority files. The gate is how Principle 10 (bimodal runs) gets enforced in practice -- agents that have nothing to do never enter the mid-zone because they exit before doing any real work.

Two variants exist: **with-vidux** (runs `vidux-loop.sh`, reads JSON, exits on blocked/complete/stuck) and **standalone** (reads memory + primary state file directly). Both enforce the same contract: steps 1-3 complete in under 60 seconds, and an agent that finds no actionable work writes a one-line `[REDUCE]` memory note and exits immediately.

See `guides/vidux/best-practices.md` Section 12 for the full copy-paste gate blocks and insertion guidance.

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
