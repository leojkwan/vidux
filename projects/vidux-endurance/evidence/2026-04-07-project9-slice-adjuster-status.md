# 2026-04-07 Project 9 Worker B Evidence Note

## Goal
Document the endurance findings for the fake insurance claims catastrophe desk, limited to adjuster assignment, field-inspection dependency, and claimant-status publication.

## Sources
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/PLAN.md`] Project 9 scope, task boundary, and resume context.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project9-harness-ownership.md`] Worker B ownership contract and the allowed write surface for this slice.
- [Source: `/Users/leokwan/Development/vidux/SKILL.md`] Vidux doctrine guidance for plan-first execution, completion, and coordinator discipline.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project8-scorecard.md`] Prior ownership leak evidence that motivated the external-surface boundary.

## Findings

### 1. Adjuster assignment stays single-owner and lane-local
The worker slice is cleanest when the adjuster is assigned from the catastrophe-desk lane itself, with one owned evidence note and no spill into coordinator state. That keeps the assignment legible for forced resume and preserves the one-worker-one-file rule in the harness contract.

### 2. Field-inspection dependency is a hard gate, not a soft suggestion
The field-inspection dependency should be treated as a required precondition for the adjuster flow in this endurance slice. If the inspection is not available, the claim should remain in the dependency-wait state rather than pretending the assignment is complete.

### 3. Claimant-status publication is the bounded outward-facing output
Status publication belongs at the end of this slice and should only reflect the current claim state that is already supported by assignment and inspection dependency handling. The note should not expand into first-notice-of-loss intake, fraud handling, reserve logic, payout logic, or any UI concerns.

### 4. The ownership boundary is the main control-plane lesson
Project 8 showed that a worker can satisfy the local deliverable and still fail the drill by writing outside the owned surface. For Project 9, the useful evidence is that Worker B remains inside the assigned evidence file while the coordinator handles any broader fan-in or external-path checks.

## Recommendations
- Keep the Project 9 drill narrow: adjuster assignment, inspection dependency, and claimant-status publication only.
- Treat any inspection-missing case as a dependency block, not a completion signal.
- Preserve the external-surface ownership rule from the harness contract and use Project 8 as the regression warning for off-surface writes.
