# 2026-04-04 Health Tracker Build Failure Drill

## Goal
Exercise Doctrine 6 with a real compile failure: capture the failure, apply an immediate code fix in `/tmp`, and decide whether the paired process fix would actually prevent the same class of mistake next time.

## Sources
- [Source: `/Users/leokwan/Development/ai/skills/vidux/projects/vidux-endurance/PLAN.md`] Task 2.2 requires a simulated build failure with both a code fix and a process fix.
- [Source: `/tmp/vidux-endurance-health/HealthSummaryFormatter.swift`] Temporary fake-project Swift fixture used for the drill.
- [Source: `swiftc -typecheck /tmp/vidux-endurance-health/HealthSummaryFormatter.swift`, executed 2026-04-04] Initial attempt failed on a sandboxed module cache path under `~/.cache`, which was environment noise rather than the intended source failure.
- [Source: `swiftc -module-cache-path /tmp/vidux-endurance-health/ModuleCache -typecheck /tmp/vidux-endurance-health/HealthSummaryFormatter.swift`, executed 2026-04-04] Reproduced the real source failure: `binary operator '+' cannot be applied to operands of type 'Int' and 'String'`.
- [Source: `swiftc -module-cache-path /tmp/vidux-endurance-health/ModuleCache -typecheck /tmp/vidux-endurance-health/HealthSummaryFormatter.swift`, executed 2026-04-04 after patch] Verified the temp-file code fix: typecheck passed with exit code 0.

## Findings

### 1. The first failure was environmental noise, not the doctrine target
Running `swiftc` without a redirected module cache tried to write under `~/.cache/clang/ModuleCache`, which is not writable in this sandbox. That would have polluted the drill if it were mistaken for a fake-project source failure.

### 2. The real source failure was a type-mixing formatter bug
The fake health-tracker formatter built badge text with `summary.restingHeartRate + " bpm"`, which produced a concrete compiler error because the lane mixed an `Int` and `String` directly.

### 3. The code fix is small and fully verified
Changing the formatter to `"\(summary.restingHeartRate) bpm"` made the temp fixture typecheck cleanly. That satisfies the immediate code-fix half of Doctrine 6.

### 4. The process fix is to normalize fake iOS build drills before scoring them
For future endurance runs, fake iOS compile drills should always:
- pin `swiftc` module cache output into `/tmp`
- treat environment-permission failures as setup issues, not source findings
- require one verified re-run after the code fix

This process fix would have prevented the misleading first failure and forced the lane to separate tool noise from actual source breakage.

## Recommendations
- Count Task 2.2 as completed with a real code fix plus a credible process fix.
- Score Doctrine 6 as a pass with minor environment friction, because the lane produced both artifacts and verified the code repair.
- Carry the `/tmp` module-cache rule into future fake iOS drills rather than editing canonical Vidux code from the endurance lane.
