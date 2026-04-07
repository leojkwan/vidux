# 2026-04-06 Project 5 Slice: Incident Response and Volunteer Reassignment

## Goal
Create one bounded evidence snapshot for the fake community event ops console, focused on incident response, volunteer reassignment, and public-status coordination. The slice should be useful to the main coordinator for Task 5.3 without introducing new orchestration state.

## Sources
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/PLAN.md`] Task 5.3 requires two bounded research slices and a serial synthesis for the fake community event ops console.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-06-project5-harness-handoff.md`] The Project 5 harness and handoff checklist already define the evergreen prompt shape and the explicit worktree register-read-remove loop.
- [Source: `/Users/leokwan/Development/vidux/SKILL.md`] Doctrine 8 forbids state snapshots in harness prompts; Doctrine 9 requires fan-out/fan-in with one slice per subagent; the worktree handoff protocol requires register, read before start, remove on completion, and stale detection.

## Findings

### 1. Incident response is the right slice boundary
For Project 5, incident response is the best bounded surface because it naturally couples three separate behaviors: deciding what changed, reallocating volunteers, and publishing a public status update. That makes it a clean stress test for the coordinator without drifting into pretend product polish.

### 2. Volunteer reassignment and public status should stay decoupled
The handoff checklist already shows the repo wants explicit state transitions, not implied ones. Applied to this slice, volunteer reassignment should be treated as a private coordination step, while public status remains a separate outward-facing artifact. That split reduces the chance that one update silently overwrites the other.

### 3. The handoff protocol gives Task 5.3 a mechanical control surface
The Project 5 checklist is already specific enough to support a two-hop drill: register the active worktree, checkpoint mid-task, resume only from the recorded path, then remove the entry at the real boundary. That means the coordinator can measure drift and duplicate-work risk instead of narrating it.

### 4. Task 5.3 should stay thin and serial
The sources point to a narrow operating model: each subagent owns one slice, returns one evidence file, and the coordinator synthesizes after fan-in. For this slice, that means one agent can focus on incident response/public comms and another on volunteer reassignment/capacity effects, with no shared writing surface.

## Recommendations
- Use this slice as the Task 5.3 incident-response lane and keep the output evidence-only.
- Treat volunteer reassignment as an internal decision and public status as a separate release artifact.
- Preserve the worktree register/remove contract as the measurable part of the drill.
- Grade the coordinator on overlap, token savings, and whether it stayed thin enough to avoid becoming a second loop.
