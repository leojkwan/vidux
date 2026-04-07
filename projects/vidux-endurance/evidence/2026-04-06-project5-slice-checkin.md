# 2026-04-06 Project 5 Slice Check-in

## Goal
Create a bounded research slice for the fake community event ops console focused on attendee check-in, late arrivals, and capacity overflow handling, so Task 5.3 can exercise Doctrine 9 without turning into a broad planning loop.

## Sources
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/PLAN.md`] Project 5 is explicitly about Doctrines 3, 5, 8, 9 plus explicit worktree handoff, and Task 5.3 asks for two bounded research slices with serial synthesis.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-06-project5-harness-handoff.md`] The Project 5 harness is meant to stay evergreen, and the handoff checklist requires register -> read -> remove-stale behavior.
- [Source: `/Users/leokwan/Development/vidux/SKILL.md`] Doctrine 3 punishes planning/code imbalance, Doctrine 8 forbids snapshot-laden harnesses, Doctrine 9 requires thin coordinator fan-out with serial fan-in, and the worktree protocol requires explicit active-worktree tracking.

## Findings

### 1. These three scenarios form one coherent operational slice
Attendee check-in, late arrivals, and capacity overflow all sit on the same event-intake state machine. That makes them a good endurance slice because the coordinator can study one surface without widening into unrelated event-console work like ticketing, venue setup, or post-event analytics.

### 2. The slice is a good Doctrine 9 test if the fan-out stays narrow
This naturally splits into two bounded subproblems: front-door intake behavior and overflow/exception policy. That gives the coordinator something real to synthesize serially, while still keeping each subagent thin enough that overlap is observable instead of hand-waved.

### 3. The slice is a Doctrine 3 stress point if it grows past the three states
The main failure mode is scope creep. If the run starts pulling in waitlists, badge reissue, seating charts, or volunteer dispatch, it stops being a tight endurance slice and becomes the exact planning-heavy drift Doctrine 3 is supposed to catch.

### 4. Doctrine 8 still applies at the harness boundary, not inside the slice
The slice itself can be specific, but the prompt that launches it must stay evergreen. The harness should name the authority store and role boundary only; it should not carry current task numbers, progress snapshots, branch names, or any session-specific worktree detail.

### 5. Worktree handoff matters most at the overflow boundary
If this slice spans sessions, the recorded worktree path must be the resume key. Overflow handling is where duplicate-worktree risk is highest, because it is easy to open a second branch of analysis when the first pass feels incomplete.

## Recommendations
- Split Task 5.3 into two subagents: one for attendee check-in and late arrivals, one for capacity overflow and exception handling.
- Keep each subagent evidence-only and require the coordinator to synthesize them serially into one note.
- Stop the slice at the three-state boundary unless the evidence proves a real shared root cause that justifies a follow-on slice.
- Preserve the worktree protocol exactly as written in the harness handoff note when this slice crosses a session boundary.
