# 2026-04-04 Health Tracker Session Death Drill

## Goal
Start Project 2 in a way that intentionally survives session loss: define the fake health-tracker scenario, checkpoint the exact next move to disk, and leave the lane resumable from files only.

## Sources
- [Source: `/Users/leokwan/Development/ai/skills/vidux/projects/vidux-endurance/PLAN.md`] Project 2 requires a simulated session death and resume test for Doctrine 5.
- [Source: `/Users/leokwan/Development/ai/skills/vidux/SKILL.md`] Doctrine 5 requires state to live in files, not memory, and says every cycle must be resumable from `PLAN.md` plus evidence on disk.
- [Source: `bash /Users/leokwan/Development/ai/skills/vidux/scripts/vidux-loop.sh /Users/leokwan/Development/ai/skills/vidux/projects/vidux-endurance/PLAN.md`, executed 2026-04-04] The readback falsely blocked Task 2.1 on completed dependency `1.4`, which means the resume drill must rely on task status in `PLAN.md`, not the current dependency matcher output alone.

## Findings

### 1. The fake project brief is small enough to survive real context loss
The Project 2 slice can be resumed from four file-backed facts only:
- app domain: fake health tracker iOS app
- goal: test design-for-death via an intentional mid-task stop and resume
- current task: Task 2.1 is the only active lane
- next move: write the concrete "session death" checkpoint and then resume from disk on the next run

### 2. A good death drill needs one authoritative next action
The next run should not reconstruct intent from chat history. It should re-read `PLAN.md`, this evidence file, and any related Project 2 artifact, then continue by writing the simulated post-death resume note as if prior conversational context were gone.

### 3. The current dependency matcher is noisy enough that the drill should use `in_progress` status as the resume key
Because `vidux-loop.sh` false-blocked Task 2.1 despite completed dependency `1.4`, the safest resume cue is the task FSM state in `PLAN.md`. Marking Task 2.1 `in_progress` is therefore part of the drill, not just administrative bookkeeping.

## Recommendations
- Leave Task 2.1 as `in_progress` at the end of this run.
- On the next run, resume Project 2 by reading only `PLAN.md` and this evidence file before writing any new Project 2 artifact.
- Treat the dependency false-block as a Vidux bug to capture in later endurance scoring, not as a blocker to the design-for-death drill itself.
