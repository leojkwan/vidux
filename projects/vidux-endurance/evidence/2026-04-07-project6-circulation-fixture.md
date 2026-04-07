# 2026-04-07 Project 6 Circulation Fixture Drill

## Goal
Reproduce the shared circulation-projection failure in `/tmp`, apply one code fix plus one process fix, and verify both against the Project 6 investigation gate.

## Sources
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/PLAN.md`] Task 6.2 requires a minimal `/tmp` fixture plus one immediate code fix and one explicit process fix.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/investigations/circulation-exception-session-projection.md`] The investigation defined one shared projection bug, the replay-based fix spec, three regression tests, and the gate.
- [Source: `/tmp/vidux-endurance-library/circulation_projection.py`] Temporary fake-project projector used for the drill.
- [Source: `/tmp/vidux-endurance-library/test_circulation_projection.py`] Regression suite covering duplicate overdue delivery, returned-loan mismatch, and hold-release race.
- [Source: `python3 -m unittest discover -s /tmp/vidux-endurance-library -p 'test_*.py' -q`, executed 2026-04-07 before patch] Initial red gate: 3 failures across all three circulation tickets.
- [Source: `python3 -m unittest discover -s /tmp/vidux-endurance-library -p 'test_*.py' -q`, executed 2026-04-07 after patch] Verified the session-aware replay fix: 3 tests passed.

## Findings

### 1. All three fake tickets collapsed to one projection defect
The intentionally buggy fixture kept one mutable `copy_id` slot, replayed deliveries in arrival order, and ignored duplicate `event_id` values. The first test run failed exactly where the investigation predicted: duplicate overdue notices were emitted twice, a late return marked the wrong active loan as returned, and a late `hold_expired` delivery cleared a newer ready hold.

### 2. One session-aware replay fix cleared the full ticket bundle
The patch replaced the copy-slot projector with a session-aware replay model keyed by `loan_id` and `hold_id`, deduplicated deliveries by `event_id`, and sorted the replay by `occurred_at` before deriving the desk summary. Re-running the unchanged regression suite turned the lane green immediately, which is the strongest proof that the investigation mapped the right shared root cause.

### 3. The explicit process fix is now part of the lane contract
Project 6 now carries a concrete future-rule for circulation drills: duplicate-delivery and out-of-order replay tests are mandatory before a lane can close. That process fix matters because the broken projector looked plausible until the replay-oriented test pack forced the three ticket classes into one shared gate.

## Recommendations
- Reuse the Project 6 replay-test pattern whenever a fake queue depends on event delivery order or idempotency.
- Treat session identity (`loan_id`, `hold_id`) as the default modeling boundary for circulation-like fake projects instead of starting from a mutable copy slot.
