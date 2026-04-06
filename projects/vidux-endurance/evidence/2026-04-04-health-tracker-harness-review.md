# 2026-04-04 Health Tracker Harness Review

## Goal
Write an evergreen harness prompt for the fake health tracker project, then check it against Doctrine 8's anti-snapshot rules.

## Sources
- [Source: `/Users/leokwan/Development/ai/skills/vidux/projects/vidux-endurance/PLAN.md`] Task 2.3 requires a project-specific harness review.
- [Source: `/Users/leokwan/Development/ai/skills/vidux/SKILL.md`] Doctrine 8 defines what must and must not go into a Vidux harness prompt.
- [Source: `/Users/leokwan/Development/ai/skills/vidux-amp/SKILL.md`] HARNESS mode shows the target shape: end goal, authority, role, design DNA, guardrails, and skills.

## Findings

### 1. The drafted harness is evergreen and authority-first
Proposed prompt:

```text
Use /vidux as the control loop for the fake health tracker iOS slice in /Users/leokwan/Development/ai.

End goal:
Validate Vidux's design-for-death, process-fix, and harness-discipline behavior against a fake health tracker app. The point is to surface doctrine failures and recovery gaps, not to build a polished product.

Authority:
Read /Users/leokwan/Development/ai/skills/vidux/projects/vidux-endurance/PLAN.md first on every run and treat it as the only state store.

Role boundary:
Own the health-tracker endurance lane only: fake-project planning, failure drills, doctrine scoring, and evidence updates. Do not build real app code or create a second orchestration loop.

Design DNA:
Evidence over vibes.
Process fixes matter more than fake app polish.
Failure discovery is the point.

Guardrails:
Operate only in /Users/leokwan/Development/ai.
Write only plan, evidence, and investigation artifacts for this fake project.
Do not push to origin unless the plan explicitly says to.

Skills:
Load /ledger only when coordination output needs to be checkpointed outside PLAN.md.
```

### 2. The prompt avoids snapshot leakage
The draft contains no task numbers, cycle counts, branch names, progress summaries, blocker state, or implementation inventory. It tells the loop where to read state, not what the current state already is.

### 3. The prompt is still specific enough to steer the lane
Despite being stateless, the harness keeps the mission tight: it names the exact authority file, the fake-project boundary, the design values, and the no-product-build rule. That is enough context for a day-1 or day-90 run to behave the same way.

## Recommendations
- Score Doctrine 8 as a pass for Project 2.
- Reuse this harness shape for later endurance domains that need a project-specific lane without embedding transient state.
