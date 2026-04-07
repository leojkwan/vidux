# Vidux Best Practices

Lessons from 28+ cycles where Vidux built itself, managed a 10-automation fleet across Resplit and StrongYes, and ran overnight cron loops unsupervised. This is not theory. Everything here was learned the hard way.

---

## 1. Writing a Good PLAN.md

The plan is the single most important artifact. Not the code. The plan. If the plan is wrong, everything downstream is wrong.

**Purpose:** One paragraph, user-visible goal only. No implementation details. The Vidux build plan says: "Create a net-new plan-first orchestration system that makes quarter-long iOS projects completable in a week via overnight cron loops." No mention of hooks, scripts, or files. Just the outcome.

**Evidence** is the backbone. Every bullet cites a source with `[Source: ...]`. No source means it is a guess. Remove it or go find evidence.

Good evidence entry:
```
- [Source: SlopCodeBench, arxiv 2603.24755] Agent code degradation is monotonic.
  Erosion in 80% of trajectories. "Coding while thinking" is empirically bad.
```

Bad evidence entry:
```
- Agents probably drift from the plan over time. We should add checks.
```
No source. "Probably" means guessing. Does not belong in the plan.

**Constraints** use the ALWAYS / ASK FIRST / NEVER format:
- ALWAYS: invariants. "ALWAYS work across Claude Code, Cursor, and Codex."
- ASK FIRST: human-gated. "ASK FIRST before changing installer or bootstrap behavior."
- NEVER: hard prohibitions. "NEVER run more than 4 coding agents in parallel."

Include reviewer preferences grounded in real PR comments.

**The 10-point readiness checklist.** Score 7+ to code:

Required (all must be true or score is 0):
1. Purpose section filled
2. Evidence has 3+ cited sources with `[Source:]` markers
3. Constraints has at least one ALWAYS and one NEVER
4. At least one task with evidence cited
5. No open questions blocking the next task

Quality (each adds 1):
6. Evidence includes an external source (not just codebase greps)
7. Constraints include a stakeholder preference
8. Tasks have `[Depends:]` markers where applicable
9. Decisions section has an entry with alternatives and rationale
10. No vague task descriptions

**What happens when you skip this:** swiftify-v4 coded without capturing team conventions. Result: a Combine implementation reworked because the team preferred async/await. A 30-minute evidence pass through PR reviews would have caught it. The plan scored maybe 4/10.

---

## 2. The 50/30/20 Rule

50% refining the plan. 30% writing code. 20% last mile (build errors, CI, reviewer feedback, merges).

```
|  50% PLAN REFINEMENT     |  30% CODE     |  20% LM  |
|  gather, synthesize,     |  one task     |  build,  |
|  prune, update PLAN.md   |  per cycle    |  CI,     |
|                          |  derived      |  review  |
   <-- front-load thinking --> <mechanical> <- tail ->
```

If you are coding more than planning, stop. The Vidux build: of 16 early cycles, 9 were plan refinement, 4 code execution, 3 last mile. Roughly 56/25/19. It shipped clean. swiftify-v4 inverted this. Heavy coding, light planning. Multiple reworks.

---

## 3. The Closure Bias Defense

After completing any task, agents have a learned impulse to checkpoint and exit. "Context is getting tight." "This is a good stopping point." This is closure bias (Claude Code #34238). It is the single most common failure mode in unattended cron loops.

**The rule: after completing any task, scan the queue before checkpointing.**

```
Task completed, build passes
     |
     v
DO NOT CHECKPOINT YET
     |
     v
Open PLAN.md, scan for unchecked tasks
     |
     +--> More tasks pending? --> execute the next one
     |
     +--> Queue empty? --> NOW checkpoint
     |
     +--> Hard blocker? --> checkpoint with blocker noted
```

The "I am done" feeling is unreliable. The queue is truth.

**Real failure:** A Resplit automation completed a payment flow fix, checkpointed, and exited at 4.7 minutes. Six more tasks were pending. The next cron fire spent 2 minutes bootstrapping context just to pick up where the last one could have continued. Multiply this by every run in a 10-automation fleet running overnight and the waste is substantial.

**How dispatch/reduce fixes this structurally:** REDUCE mode exits in under 2 minutes (nothing to do). DISPATCH mode has no exit until queue drain or hard blocker. There is no middle ground. The agent never decides "should I keep going?" because the mode already decided. See the architecture guide, Section 2.

---

## 4. Self-Extending Plans

Automations add tasks to PLAN.md themselves. Do not wait for the human to enumerate work.

When you fix a bug, log the related bugs you saw on the same surface. When you add a feature, log the polish and edge-cases you spotted. When you fix /pricing, check /plans too -- the same bug class often lives on adjacent pages. Think N steps ahead.

**The brake: three-strike rule.** If a surface already has 3+ queued polish tasks, ship the most impactful one and move on. Self-extension without a brake becomes recursive optimization forever. A good automation knows when a surface is honestly good and stops adding work to its own queue.

**Real failure:** A Resplit automation discovered 14 polish tasks on a single view controller. Without the three-strike brake it would still be polishing. With the brake it shipped the top 3 and moved to the next gap in the mission.

**Mission honesty rule:** Separate "current slice status" from "release boundary" from "overall mission completion." If the overall mission has gaps elsewhere, polish on a done surface is procrastination. Only re-extend plans when investigation reveals new surfaces, not when you find one more pixel to align on a surface you already touched.

---

## 5. Product Taste Over Functional Correctness

Functional code is table stakes. The build passes, the tests are green -- that is the floor, not the ceiling. What separates a good automation from a great one is taste: anticipating the next ask, catching visual issues before the human sees them, and knowing when "works correctly" is not the same as "works well."

**Visual proof, not just green builds.** For any UI work, definition of done is a simulator screenshot or before/after comparison, not "the build passes." Load `$picasso` (or equivalent) for visual evaluation. A payment form that compiles but has 4px misaligned labels is not done.

**Anticipate the next ask.** When you fix /pricing, also check /plans -- same bug class, adjacent page. When you add a new API endpoint, check that the error states render correctly, not just the happy path. The automation that does this saves the human a round-trip of "now fix the other one."

**Before/after screenshots as proof.** When a UI task is complete, capture before and after. This is not documentation -- it is evidence that the change is an improvement. An agent that says "I fixed the layout" without visual proof is asking the human to trust. An agent that shows the screenshots is showing.

**Real example from Resplit:** An automation fixed the currency conversion display -- build passed, tests green. But the formatted amount was clipped by the container on small screens. A `$picasso` visual check caught it in the same cycle. Without taste-level checking, it would have shipped broken to 320px devices and required a second cycle to diagnose and fix.

**Real example from StrongYes:** An automation built the interview prep timer. Functionally correct -- it counted down, it beeped. But the font was 12px on a component that needed to be glanceable from arm's length. Product taste means catching this in the same cycle, not three cycles later when the human notices.

---

## 6. Fan-Out Research Pattern

Never have 20 agents write one file. 17x error amplification beyond 4 parallel agents without hierarchy.

```
          +----------+  +----------+  +----------+  +----------+
TIER 1    | Agent A  |  | Agent B  |  | Agent C  |  | Agent D  |
(parallel)| team chat|  | codebase |  | rules    |  | issues   |
          +----+-----+  +----+-----+  +----+-----+  +----+-----+
               |              |              |              |
               v              v              v              v
          evidence/      arch/        constraints/   tasks/
               |              |              |              |
               +---------+---+--------------+--------------+
                         |
                         v
                   +-----------+
TIER 2 (serial)    | Synthesizer|  reads all 4, writes one PLAN.md
                   +-----------+
                         |
                         v
                   +-----------+
TIER 3 (serial)    |   Critic   |  challenges assumptions
                   +-----------+
```

**Tier 1** -- 4 research agents, all parallel. Each writes to its own file.

**Tier 2** -- One synthesizer reads all four, writes unified PLAN.md.

**Tier 3** -- One critic challenges assumptions, checks for contradictions and scope creep.

Cap coding agents at 4 with a point guard plus workers model. Research agents can go wider because they are read-only. The Vidux build ran 9 research agents in Cycle 0 successfully.

Why subagents, not Teams? Teams persist across sessions (violates stateless doctrine), add coordination overhead, and risk orphaned state if the cron dies. Subagents are fire-and-forget.

---

## 7. Running Overnight Cron Loops

Each cycle is stateless: REDUCE reads the store, optionally fires DISPATCH, checkpoint, exit. The next cycle is a fresh agent that knows nothing except what is in the files.

**30-minute cadence for fleet automations.** The Resplit/StrongYes fleet uses 30-minute cron intervals. REDUCE fires every 30 min. If work is pending, DISPATCH runs until the queue is drained. If nothing is pending, REDUCE exits in under 2 minutes.

**Expect auth expiry.** Tokens expire, MCP servers disconnect. A crashed session loses at most one cycle. The next cycle commits recovered work first.

**Commit is the checkpoint, not push.** Solo computer workflow. Commit after every cycle. Push when ready. Commit message: `vidux: [what you did]` with structured body (Plan, Evidence, Next, Blocker).

**Environment variables for ledger:** `AGENT_LANE` (work track) and `AGENT_SKILLS` (loaded skills).

---

## 8. Common Mistakes

**Coding without a plan entry.** Number one mistake. Every code change traces to a PLAN.md task. The PreToolUse hook reminds you, but it is a safety net, not a substitute. During the Vidux build, agents kept making "quick cleanups" to unplanned files. Each cleanup was small. The cumulative drift was not.

**Checkpointing after one task when more are pending.** Number two mistake. This is closure bias in action. Scan the queue. If there is more work, keep going. DISPATCH mode exists to enforce this structurally.

**Carrying context between sessions.** The next agent remembers nothing. Write it to PLAN.md or it does not exist.

**Too many parallel coding agents.** Four is the cap. Research agents can go wider (read-only).

**Forgetting to checkpoint.** No commit means the next session starts blind. Even plan-only refinement gets a commit.

**Plan without evidence.** An uncited entry is a guess. The readiness checklist requires 3+ cited sources to start coding.

**Self-extending without the brake.** Adding polish tasks is good. Adding 14 polish tasks to one surface while the mission has gaps elsewhere is procrastination. Three-strike rule: 3+ queued tasks on one surface means ship the best and move on.

**Functional correctness without taste.** Build passes, tests green, but the UI is broken on small screens. Load visual evaluation tools for UI work. Before/after screenshots are not optional.

---

## 9. When to Use Vidux vs Pilot

```
How big is the work?
     |
     +--> Under 2 hours, single file --> Pilot (Mode A)
     |
     +--> PR nursing, CI fix --> Pilot + Sloth
     |
     +--> Multi-session, 8+ files --> Vidux (Mode B)
     |
     +--> "We need to plan this" --> Vidux
     |
     +--> "Just do it" --> Pilot
```

**Rule of thumb:** "Will a second agent need to pick this up later?" If yes, Vidux. The plan makes handoff possible.

---

## 10. Debugging a Stuck Plan

```
Task stuck 3+ cycles
     |
     v
Check readiness score
     |
     +--> Below 7? --> Stop coding, refine the plan
     |
     +--> 7+? --> Task too large?
                    |
                    +--> Yes --> Break into sub-tasks
                    |
                    +--> No --> Evidence missing?
                                 |
                                 +--> Yes --> Gather evidence
                                 |
                                 +--> No --> External blocker?
                                              |
                                              +--> Yes --> Mark BLOCKED, move on
                                              |
                                              +--> No --> Run dual five-whys
```

**Most common cause:** Plan was not ready and agents are flailing. Check readiness score first.

**Stuck-loop detection:** same task in 3+ consecutive cycles means task is too large (break it), evidence is missing (gather it), or it is externally blocked (mark BLOCKED).

**Dual five-whys:** Two chains on every failure. Why did the error happen (technical)? Why did the agent make that mistake (process)? The process chain is more valuable -- it produces process fixes.

**Three-strike gate:** 3+ fixes on the same surface without resolution means the problem is in the design, not the code. Stop patching. Move up one abstraction layer.

---

## 11. The Failure Protocol

```
Build/test fails
     |
     v
Retry once (read error, form hypothesis, apply targeted fix)
     |
     +--> Pass? --> Continue, log surprise
     |
     +--> Fail? --> Dual five-whys
                     |
                     +--> Error chain (what broke technically)
                     +--> Behavior chain (why did the agent do that)
                     |
                     v
                3+ fixes on same surface?
                     |
                     +--> Yes --> Move up one abstraction layer
                     +--> No --> Produce two artifacts:
                                   1. Code fix (immediate repair)
                                   2. Process fix (constraint/hook/test)
                     |
                     v
                Update PLAN.md surprises
```

The code fix is table stakes. The process fix is the valuable output. Over the Vidux build, the drift detection hook, checkpoint enforcement, and three-strike gate itself all came from failures that were analyzed, not just patched.

---

## 12. REDUCE Gate Pattern

The REDUCE gate is a copy-paste block inserted at the top of every automation harness prompt. It forces the agent to evaluate whether there is actionable work *before* loading skills, reading authority files, or doing any other work. The gate is the enforcement mechanism for Doctrine 10 (bimodal runs) -- it structurally eliminates mid-zone exits by making the "nothing to do" path fast and cheap.

**Expected impact:** REDUCE exits drop from ~2 minutes to under 30 seconds. Agents that have nothing to do never load skills or read the authority chain. Over a 10-automation fleet running 30-minute cron intervals, this saves hundreds of wasted agent-minutes per day.

### With-Vidux variant (~850 chars)

Use this when the automation loads `$vidux` and has access to `vidux-loop.sh`. This is the standard variant for all Resplit and StrongYes automations.

```
REDUCE gate (run FIRST, before any other work):
1. Run: bash /Users/leokwan/Development/vidux/scripts/vidux-loop.sh <plan-path>
2. Read the JSON output. If ANY of these are true, checkpoint and exit immediately:
   - action is "blocked" or "auto_blocked" or "stuck" or "all_blocked"
   - action is "complete" or type is "done" or "empty"
   - auto_pause_recommended is true
   - bimodal_gate is "blocked"
   - next_action is "none"
   Write a 1-line memory note: "[REDUCE] <date> <reason>. No dispatch."
   Do NOT read authority files, load skills, or do any other work. Exit now.
3. Read the last 3 memory notes. If the top note is a [REDUCE] exit with the
   same reason as this run's JSON, exit with: "[REDUCE] <date> unchanged. No dispatch."
4. If next_action is "dispatch": proceed to full execution below.
Budget: steps 1-3 must complete in under 60 seconds. If you are still in REDUCE
after 60 seconds, you are in the mid-zone. Checkpoint what you know and exit.
```

### Standalone variant (~800 chars)

Use this when the automation does not have `vidux-loop.sh` or operates outside the vidux plan-store model. The agent reads its own memory and primary state file directly.

```
REDUCE gate (run FIRST, before any other work):
1. Read the last 3 notes from this automation's memory file.
2. If the most recent note says any of: "blocked", "nothing to do", "unchanged",
   "no pending", "waiting on human", "same blocker" -- and it was written less
   than 2 hours ago -- exit immediately with a 1-line note:
   "[REDUCE] <date> Same state as last run (<quote reason>). No dispatch."
   Do NOT read authority files, load skills, or gather evidence. Exit now.
3. Read the single primary state file (plan, queue, or tracker). Count actionable
   items. If zero actionable items and no new items since the last note, exit with:
   "[REDUCE] <date> No new work. No dispatch."
4. If actionable work exists: proceed to full execution below.
Budget: steps 1-3 must complete in under 60 seconds.
```

### Insertion point guidance

The REDUCE gate block goes **inside** the prompt string, immediately after the mission and skill-loading lines, and **before** the authority chain or read order. The agent must hit the gate before it starts reading authority files. The gate text is literal -- copy it verbatim, replacing only `<plan-path>` with the automation's actual plan path.

### When to use which variant

| Automation type | Variant |
|-----------------|---------|
| Loads `$vidux`, has a PLAN.md | With-Vidux |
| No vidux, has its own queue/tracker file | Standalone |
| Pure reader/radar with no plan file | Standalone (use memory file as primary state) |

---

## 13. Quick Reference

**Before coding:** Readiness score 7+? If not, refine the plan.

**Before editing a file:** Covered by a PLAN.md task? If not, update plan first.

**After completing a task:** Scan the queue. More work pending? Keep going. Do not checkpoint yet.

**Before checkpoint:** Progress section updated? Tasks checked off? Committed?

**Before stopping:** Can a stranger pick up from the files alone?

**On failure:** Retry once. Dual five-whys. Three-strike check. Always produce a process fix alongside the code fix.

**On stuck plan:** Readiness score. Break large tasks. Gather missing evidence. Mark blockers. Escalate with five-whys.

**On UI work:** Visual proof required. Before/after screenshots. Load $picasso or equivalent.

**Commit is the checkpoint.** Not push. Every cycle. Always.
