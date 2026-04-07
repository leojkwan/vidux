# 2026-04-07 Project 7 Harness + Ownership Contract

## Goal
Write an evergreen harness and explicit worker-ownership contract for the fake municipal permit intake board, so the forced-resume coordinator drill can test Doctrines 5, 8, and 9 without leaking state or creating overlapping write surfaces.

## Sources
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/PLAN.md`] Task 7.1 requires a stateless harness plus an ownership contract naming the exact evidence file each worker may touch.
- [Source: `/Users/leokwan/Development/vidux/SKILL.md`] Doctrine 8 allows only end goal, authority path, role boundary, design DNA, guardrails, and skills in a harness prompt.
- [Source: `/Users/leokwan/Development/vidux/SKILL.md`] The worktree handoff protocol requires register-on-entry, read-before-start resume, and explicit removal when the boundary is reached.
- [Source: `/Users/leokwan/Development/vidux/SKILL.md`] Doctrine 9 requires one slice per subagent, parallel fan-out, serial fan-in, and a thin coordinator instead of a second orchestration loop.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-06-project5-harness-handoff.md`] Project 5 established the current harness shape and the register-read-remove checklist for documentary worktree drills.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-06-project5-subagent-synthesis.md`] Project 5 surfaced the key prior D9 failure: one worker escaped its owned file and wrote to automation memory.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project6-scorecard.md`] Project 6 left D5, D8, and D9 as the lightest-covered doctrines in the endurance set.

## Findings

### 1. Proposed Project 7 harness stays stateless under Doctrine 8
Proposed prompt:

```text
Use /vidux as the control loop for the fake municipal permit intake board endurance slice in /Users/leokwan/Development/vidux.

Mission:
Validate Vidux's design-for-completion behavior, harness purity, and subagent ownership control using a fake municipal permit intake board. Surface recovery friction and coordinator failures rather than polishing the pretend product.

Authority:
Read /Users/leokwan/Development/vidux/projects/vidux-endurance/PLAN.md first on every run and treat it as the only project state store.
Use /Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/ and investigations/ only as supporting artifacts.

Role boundary:
Own the municipal permit endurance lane only: harness review, worker ownership enforcement, forced-resume fan-out, doctrine scoring, and evidence checkpointing. Do not build a real permit product and do not create a second orchestration loop.

Design DNA:
Evidence over vibes.
Failure discovery is the point.
Coordinator stays thin.
Process fixes matter more than fake-project polish.

Guardrails:
Operate only in /Users/leokwan/Development/vidux.
Fake-project writes may touch only the endurance PLAN plus project-local evidence or investigations.
Resume the recorded worktree path from PLAN.md instead of creating a sibling worktree.
Do not push to origin unless PLAN.md explicitly says to.

Skills:
Load /ledger only when cross-session coordination output must leave PLAN.md.
```

### 2. The ownership contract names one evidence file per worker and one coordinator-only surface
Use this contract for Task 7.2:

| Role | Owned write surface | Allowed writes |
|------|----------------------|----------------|
| Coordinator | `projects/vidux-endurance/PLAN.md` | Task state, `## Active Worktrees`, Progress, Surprises, and Decision Log only |
| Coordinator | `projects/vidux-endurance/evidence/2026-04-07-project7-harness-ownership.md` | This harness and ownership note only |
| Coordinator | `projects/vidux-endurance/evidence/2026-04-07-project7-forced-resume-drill.md` | Fan-in synthesis and recovery proof only |
| Coordinator | `projects/vidux-endurance/evidence/2026-04-07-project7-scorecard.md` | Project 7 grading only |
| Coordinator | `$CODEX_HOME/automations/vidux-endurance/memory.md` | Final run note only, after the project boundary |
| Worker A | `projects/vidux-endurance/evidence/2026-04-07-project7-slice-intake-completeness.md` | Intake packet completeness, missing-document exceptions, and zoning triage only |
| Worker B | `projects/vidux-endurance/evidence/2026-04-07-project7-slice-routing-status.md` | Reviewer routing, inspection scheduling, and applicant-status publication only |

Rules:
- No worker may edit `PLAN.md`, automation memory, the coordinator synthesis file, or another worker's evidence file.
- Each worker returns exactly one evidence note.
- The coordinator may synthesize only after rereading `PLAN.md` plus the recorded worker-file paths from disk.

### 3. The forced-resume drill now has an explicit checkpoint contract
The mid-fan-out checkpoint should record:
- the active worktree entry for `/Users/leokwan/Development/vidux`
- the current task as Task 7.2
- both owned evidence paths
- the requirement that the recovery hop read `PLAN.md` before any new worktree creation

That converts Task 7.2 from a narrative "pretend we resumed" claim into a real file-backed recovery test.

### 4. Doctrine 8 review: the harness avoids snapshot leakage
The proposed harness contains no task numbers, cycle counts, branch names, progress summaries, blocker text, or worker-file ownership details. It names only the evergreen mission, authority store, role boundary, and guardrails. The ownership contract lives in this evidence note, not inside the harness itself.

## Recommendations
- Use the proposed prompt as the Project 7 launch harness without adding any current-state snapshots.
- Treat the ownership table as the acceptance contract for Task 7.2, especially the prohibition on worker writes to automation memory.
- Fail the coordinator drill if the recovery hop creates a sibling worktree or if a worker touches anything outside its named evidence file.
