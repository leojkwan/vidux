# 2026-04-07 Project 6 D3 Boundary Audit

## Goal
Decide whether Project 6 stayed inside a real Doctrine 3 boundary or started drifting into unrelated library-ops polish.

## Sources
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/PLAN.md`] Task 6.3 requires an explicit D3 boundary audit and queue prune if the lane drifts.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/investigations/circulation-exception-session-projection.md`] The investigation defines one shared circulation surface and one shared fix path.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project6-circulation-fixture.md`] The fixture drill proves what code and verification work actually happened.
- [Source: `/tmp/vidux-endurance-library/circulation_projection.py`] Final `/tmp` code surface for the lane.
- [Source: `/tmp/vidux-endurance-library/test_circulation_projection.py`] Final `/tmp` verification surface for the lane.

## Findings

### 1. The lane stayed on one shared surface
Project 6 never widened beyond the circulation-session projector. The only code work lived in one `/tmp` module plus one test file, and every repo-side write stayed in the investigation, evidence, scorecard, or parent plan. That is strong evidence that the lane remained a single-surface expedition instead of turning into fake-product development theater.

### 2. Several tempting side quests were explicitly excluded
The work could have drifted into patron email copy, kiosk messaging, fine-policy rules, or hold-shelf UI polish. None of those change the shared replay model that caused the three tickets. Keeping them out of scope preserved the D3 balance instead of letting the lane dissolve into library-ops backlog grooming.

### 3. No queue prune was needed because the boundary held early
The investigation named the shared root cause before any `/tmp` work started, which made the code slice naturally narrow. Planning stayed heavier than code, but the cycle still included real implementation and last-mile verification: one red gate, one green gate, one boundary audit, and one fresh Vidux contract rerun.

## Recommendations
- Use the "one investigation, one `/tmp` module, one regression pack" pattern for future D3-sensitive endurance projects.
- If a future Project 6-style lane cannot be phrased as a state-transition or replay fix, stop and prune before new tasks are added.
