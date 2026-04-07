# 2026-04-07 Project 7 Routing + Status Slice

## Goal
Capture a bounded evidence slice for the fake municipal permit intake board that only covers reviewer routing, inspection scheduling, and applicant-status publication. This is an endurance research slice, not product design, and it should stay small enough to serialize cleanly into the later Task 7.2 fan-in.

## Sources
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/PLAN.md`] Task 7.2 explicitly splits Project 7 into worker-owned evidence files and requires the recovery hop to resume from recorded paths, not from memory.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project7-harness-ownership.md`] The ownership contract assigns this file to Worker B and limits the scope to reviewer routing, inspection scheduling, and applicant-status publication.
- [Source: `/Users/leokwan/Development/vidux/SKILL.md`] Doctrine 8 keeps harnesses stateless and role-bounded; Doctrine 9 requires one slice per subagent with thin fan-in.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-06-project5-subagent-synthesis.md`] Prior D9 fan-out showed that ownership leaks can happen even when the research content is good, so the write boundary matters as much as the slice boundary.

## Findings

### 1. Reviewer routing is the narrowest useful control-plane slice
The routing surface only needs to answer which reviewer receives which permit file and when a reassignment is justified. That stays in the control plane if the note records queue movement, assignment rules, and handoff triggers, but it becomes product design if it starts specifying reviewer policy, staffing optimization, or permit approval criteria.

### 2. Inspection scheduling belongs in the same slice, but only as a dependency on routing
Scheduling is relevant here because a routed reviewer may need an inspection slot before status can advance. The useful boundary is the scheduling handoff itself: who booked the inspection, what dependency blocked booking, and what event unblocked it. The slice should not expand into calendar UX, inspector capacity planning, or municipal scheduling policy.

### 3. Applicant-status publication is the public-facing output, not the whole workflow
Status publication is the last visible step in this slice because it reflects routing and inspection outcomes back to the applicant. The note should capture what status becomes visible, when it becomes visible, and which upstream state change triggered it. It should not drift into notification templates, applicant messaging tone, or portal layout decisions.

### 4. The main friction is semantic overlap, not technical complexity
Routing, scheduling, and publication all touch the same lifecycle, so it is easy for a writer to accidentally collapse them into one generic "permit process" narrative. That would hide the control-plane boundaries that Project 7 is supposed to test. The earlier Project 5 ownership leak shows why the boundary has to be explicit even when the content is otherwise correct.

## Recommendations
- Keep this slice limited to queue assignment, inspection booking handoff, and applicant-visible status transitions.
- Treat any move into intake completeness, permit policy, or UI/notification design as out of scope for Worker B.
- In the fan-in note, preserve the three-step chain: routing decision, inspection dependency, status publication, with no broader product narrative.
