# 2026-04-06 Project 5 Harness + Handoff Review

## Goal
Write a stateless harness prompt plus an explicit worktree handoff checklist for the fake community event ops console, then verify the prompt stays clean under Doctrine 8.

## Sources
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/PLAN.md`] Task 5.1 defines the Project 5 harness and handoff requirement.
- [Source: `/Users/leokwan/Development/vidux/SKILL.md`] Doctrine 8 says harness prompts may include only end goal, authority path, role boundary, design DNA, guardrails, and skills, and may never include task numbers, cycle counts, progress, branch names, file lists, blockers, or other state snapshots.
- [Source: `/Users/leokwan/Development/vidux/SKILL.md`] The worktree handoff protocol requires `## Active Worktrees` registration on entry, read-before-start resume behavior, explicit removal on completion, and stale detection after 3 no-progress cycles.
- [Source: `/Users/leokwan/Development/vidux/guides/vidux/best-practices.md`] The failure protocol and quick reference reinforce that the checkpoint must leave enough file state for a stranger to resume from disk alone.

## Findings

### 1. Proposed Project 5 harness stays evergreen
Proposed prompt:

```text
Use /vidux as the control loop for the fake community event ops console endurance slice in /Users/leokwan/Development/vidux.

Mission:
Validate Vidux's harness purity, explicit worktree handoff protocol, and subagent coordinator behavior against a fake community event ops console. The point is to surface doctrine gaps and recovery friction, not to polish the pretend product.

Authority:
Read /Users/leokwan/Development/vidux/projects/vidux-endurance/PLAN.md first on every run and treat it as the only project state store.

Role boundary:
Own the community event ops endurance lane only: fake-project planning, evidence synthesis, worktree handoff drills, doctrine scoring, and scorecard updates. Do not build a real product and do not create a second orchestration loop.

Design DNA:
Evidence over vibes.
Failure discovery is the point.
Process fixes matter more than fake-project polish.

Guardrails:
Operate only in /Users/leokwan/Development/vidux.
Fake-project writes may touch plans, evidence, and investigations only.
Resume recorded worktrees from PLAN.md instead of inventing new ones.
Do not push to origin unless the plan explicitly says to.

Skills:
Load /ledger only when cross-session coordination output needs to leave PLAN.md.
```

### 2. The handoff checklist is explicit enough to drive a two-hop resume drill
Use this checklist whenever Project 5 enters a fresh worktree:

1. Create or enter the worktree for the current Project 5 task.
2. Add or update `## Active Worktrees` in `projects/vidux-endurance/PLAN.md` with branch, worktree path, task description, and `status: in_progress|blocked`.
3. Add a Progress entry describing what changed on this hop and what the next hop must read first.
4. On the next cycle, read `## Active Worktrees` before any new worktree creation and resume the recorded path if it matches the task.
5. When the task reaches a real boundary, remove the `## Active Worktrees` entry and add a `[WORKTREE]` Decision Log line saying whether the worktree was merged or abandoned and why.
6. If the same entry survives 3 cycles with no progress, mark the task blocked for stale worktree drift and log a Surprise.

### 3. Doctrine 8 review: the harness avoids snapshot leakage
The prompt contains no task numbers, cycle counts, progress summaries, blocker text, branch names, or worktree-specific paths. It names the authority file and repo root, but it does not embed any current state from Project 5. That keeps the harness evergreen while still constraining the lane.

### 4. The checklist closes the Project 2 partial-coverage gap
Project 2 proved disk-only resume works, but it did not prove that an explicit worktree protocol can prevent duplicate worktrees or ambiguous resumes. This checklist upgrades Doctrine 5 coverage from implied resume behavior to a concrete register-read-remove-stale loop that Task 5.3 can test mechanically.

## Recommendations
- Use this exact harness shape as the Project 5 control prompt.
- Treat the checklist as the acceptance contract for Task 5.3 rather than as optional guidance.
