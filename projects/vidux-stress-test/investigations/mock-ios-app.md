# Investigation: Mock iOS App Validation

## Reporter Says
"test-team finding that investigation template was never exercised for iOS" — swarm analysis, 2026-04-04

## Evidence
- Test agent created realistic PLAN.md at /tmp/vidux-test-ios/PLAN.md with 3 tasks (2 compound, 1 atomic)
- Popover investigation (3-strike): /tmp/vidux-test-ios/investigations/popover-amount-editor.md — 155 lines, all 7 sections filled
- Assignment labels investigation: /tmp/vidux-test-ios/investigations/assignment-labels.md — stub created
- 3 cycles executed: GATHER → popover investigation (evidence + root cause) → popover investigation (impact map + fix spec)
- Three-strike escalation triggered correctly for 3-ticket surface

## Root Cause
N/A — validation test, not a bug.

## Impact Map
- Three-strike escalation → Impact Map required before code: VALIDATED
- Compound vs atomic routing in ASSESS tree: VALIDATED
- Investigation template works for iOS/SwiftUI bugs: VALIDATED
- Status propagation for multi-cycle compound task: VALIDATED

## Fix Spec
N/A — no code changes needed.

## Tests
- Test 1: Three-strike escalation triggers for 3+ tickets on same surface — PASS
- Test 2: Impact Map required before Fix Spec per Doctrine 7 — PASS
- Test 3: Atomic tasks correctly identified vs compound — PASS
- Test 4: Investigation template actionable for iOS-specific bugs — PASS
- Test 5: Status propagation across multiple investigation cycles — PASS

## Gate
- [x] All 5 test assertions pass
- [x] 3-strike investigation has full Impact Map
- [x] Git history shows 3 clean cycle commits

## Friction Found
1. [in_progress] too broad for compound tasks — no distinction investigating vs executing
2. Atomic tasks starve behind multi-cycle compound tasks
3. No clear rule on WHEN to create investigation stubs (GATHER vs pickup)
4. No device/OS test matrix section for iOS investigations
