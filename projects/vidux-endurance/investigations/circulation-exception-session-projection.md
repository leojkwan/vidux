# Investigation: Circulation Exception Session Projection

## Reporter Says
- [LIB-401] "One loan sent two overdue notices after the desk reopened the same copy."
- [LIB-417] "The kiosk says the book was returned, but the exception desk still shows that loan as missing."
- [LIB-426] "A hold was released as expired even though the copy had just been checked in for the waiting patron."

## Evidence
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/PLAN.md`] Project 6 explicitly targets one shared circulation surface and requires the investigation to exist before any `/tmp` implementation drill begins.
- [Source: `/Users/leokwan/Development/vidux/SKILL.md`] Doctrine 7 requires bundling 2+ tickets on the same surface into one investigation with Root Cause, Impact Map, Fix Spec, Tests, and Gate before code.
- Simulated surface owner files for this fake project:
  - `/tmp/vidux-endurance-library/circulation_projection.py`
  - `/tmp/vidux-endurance-library/test_circulation_projection.py`
- Related tickets on the same surface: LIB-401, LIB-417, LIB-426. Three tickets on one circulation surface triggers the three-strike investigation rule.
- Recent commits: none. This endurance lane is a fresh fake-project reproduction.
- Repro:
  1. Replay one checkout, one duplicate overdue delivery, one return for the same loan, and one hold-ready/hold-expired pair for the same copy.
  2. Inspect the exception desk projection after replay.
  3. Compare the projected notice queue, loan status, and hold shelf status against the expected circulation session state.

## Root Cause
The fake exception desk collapses all circulation activity into one mutable record per `copy_id` and replays webhook deliveries in arrival order without deduplicating `event_id`. That shared projection loses the identity of individual loan and hold sessions. Duplicate overdue deliveries append a second notice for the same loan, a late return can clear or mismatch the wrong loan because only the copy slot is tracked, and a late `hold_expired` event can wipe a newer ready hold because the desk stores one hold slot instead of session-specific hold state.

## Impact Map
- Other desk paths that depend on this surface:
  - overdue notice queue for patron outreach
  - returned-item reconciliation panel
  - hold shelf readiness board
- Other tickets fixed or broken by this change:
  - Fixing duplicate notices alone would still leave LIB-417 and LIB-426 broken because the projection would still collapse multiple sessions into one copy slot.
  - Fixing only return reconciliation would still let duplicate overdue deliveries and late hold-expired events corrupt the desk.
  - A correct fix should also protect future "stale exception" tickets because the shared replay rules become session-aware and idempotent.
- State flow:
  - circulation event deliveries -> projection replay -> exception desk summary
  - projection replay -> overdue notice queue
  - projection replay -> hold shelf readiness

## Fix Spec
- `/tmp/vidux-endurance-library/circulation_projection.py` — replace the copy-slot projection with session-aware maps keyed by `loan_id` and `hold_id`, while still grouping summaries by `copy_id` for desk display.
- `/tmp/vidux-endurance-library/circulation_projection.py` — deduplicate deliveries by `event_id` before replay and sort by `occurred_at` so late arrivals do not override newer circulation state.
- `/tmp/vidux-endurance-library/circulation_projection.py` — derive overdue notices from loan sessions exactly once per loan and clear the missing-return exception only for the matching `loan_id`.
- `/tmp/vidux-endurance-library/circulation_projection.py` — clear or retain holds by `hold_id`, not by wiping the entire copy-level hold slot.
- [Evidence: `/Users/leokwan/Development/vidux/SKILL.md`] This keeps the lane inside one shared surface: a single projection pipeline drives every ticket instead of three disconnected fixes.

## Regression Tests
- Test 1: Duplicate overdue delivery for one `loan_id` yields one overdue notice and one overdue exception.
- Test 2: A return closes only the matching `loan_id` and removes the returned-book mismatch without touching a different checkout on the same copy.
- Test 3: Out-of-order `hold_ready` and `hold_expired` deliveries preserve the newest active hold for the copy.

## Gate
- [x] `python3 -m unittest discover -s /tmp/vidux-endurance-library -p 'test_*.py' -q` passes after the fix.
- [x] The same test suite fails against the initial buggy projection before the fix.
- [x] One explicit process fix is recorded for future circulation drills: duplicate-delivery and out-of-order replay cases are mandatory before closing the lane.
- [x] The lane stays scoped to the shared circulation projection and does not expand into unrelated library-ops polish.
