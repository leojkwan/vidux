# 2026-04-07 Project 9 FNOL + Severity Slice

## Goal
Capture the minimum endurance-research evidence for a fake insurance claims catastrophe desk: first-notice-of-loss completeness, catastrophe severity routing, and fraud-hold triggers only.

## Sources
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/PLAN.md`] Project 9 is a forced-resume external-path ownership drill, and the worker boundary for this slice is limited to FNOL completeness, catastrophe severity routing, and fraud-hold triggers.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project9-harness-ownership.md`] The harness and ownership contract explicitly assign this file to Worker A and exclude adjuster assignment, field inspection, claimant messaging, payout policy, and UI details.
- [Source: `/Users/leokwan/Development/vidux/SKILL.md`] Doctrine 8 requires an evergreen harness; Doctrine 9 requires one owned deliverable per worker and thin fan-in coordination.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project8-scorecard.md`] Project 8 showed that ownership can fail even when the primary drill succeeds, so external-surface discipline remains part of the endurance target.

## Findings

### 1. FNOL completeness needs a hard minimum before anything else
For this endurance slice, the useful completeness check is whether the intake captures enough to classify the loss event without jumping into downstream handling. The minimum evidence-backed fields are loss date/time, loss location, peril type, what happened, affected property or exposure, reporter identity and relationship, and whether the loss is still unfolding. If any of those are missing, the desk cannot reliably decide whether the claim belongs in the catastrophe lane.

### 2. Catastrophe severity routing should key off event scale, not claim sentiment
The routing signal should come from the event context around the loss, not from how urgent the caller sounds. A cat routing decision is justified when the FNOL indicates widespread event impact, multi-claim exposure from the same incident, a declared catastrophe event, or geographic concentration consistent with a large-loss cluster. That keeps the lane focused on severity triage instead of later claim handling.

### 3. Fraud-hold triggers belong at intake, but only as hold signals
The relevant research boundary is the presence of intake facts that justify a fraud review hold, not any investigation workflow after that. Strong triggers are inconsistent loss timing, mismatched reporter or policyholder identity, exposure facts that conflict with the described event, repeated submissions for the same incident, or other obvious internal inconsistencies at FNOL. The right outcome for this slice is a hold flag, not any messaging or assignment decision.

### 4. The stop line is explicit and should stay there
This lane should stop once FNOL completeness, cat severity routing, and fraud-hold triggers are established. Anything involving adjuster assignment, field inspection, claimant communication, payout logic, or UI behavior is out of scope for this worker note and would turn the research into product design.

## Recommendations
- Treat FNOL completeness as the gating check for all later routing.
- Use catastrophe routing only for event-scale severity signals, not downstream workflow preferences.
- Keep fraud handling at the intake hold level in this slice and do not extend into investigation process design.
- Preserve the Worker A boundary exactly as written in the ownership contract so the coordinator can fan in without scope drift.
