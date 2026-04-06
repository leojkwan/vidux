# Evidence — LiveSessionControlSheet Awaiting-State Reframe

Date: 2026-04-06

## Why this note exists

Release blockers are unchanged on this host, so the fallback queue moved to `remaining-work.plan.md` row `p0-native-readiness`. The first repo-owned fallback still named `live-split-prod-ready.plan.md` `pr5-lock-editing-behavior`, but that wording needed a fresh truth check before a new code lane opened.

## Repo truth

- `remaining-work.plan.md` and `.cursor/plans/resplit-nurse.log.md` still point the next fallback slice at `live-split-prod-ready.plan.md` `pr5-lock-editing-behavior`.
- `docs/features/live-split-mega-plan.md` is the canonical Live Split board and explicitly says:
  - "`waiting`, `lock editing`, `recent activity` ... are not part of the main MVP path."
  - "`lock editing` is old and should not be in the main MVP path."
  - the obsolete control-sheet `lock editing` scaffolding was already removed from the main runtime path.
- Current runtime code shows the user-facing contract already depends on live-session state, not a separate lock feature:
  - `ReceiptDetailShellContent.swift` passes `isEditingLocked: liveSessionPhase.isSessionAlive` into `ReceiptDetailView`.
  - `ParticipantScrollView.swift` and `ParticipantPopoverView.swift` disable mutating actions when `isEditingLocked` is true.
  - `ReceiptActionFooterView.swift` suppresses the footer Live Split CTA and settle actions when `isEditingLocked` is true.
  - `LiveSessionViewModel.surfacePhase` maps `state.locked` to `.awaitingGuestDecisions(...)`.
- The missing visibility seam is inside `LiveSessionControlSheet.swift`:
  - it renders share hero, participants, progress, and wrap-up dock
  - it does not read `state.locked` or `viewModel.surfacePhase`
  - it therefore gives no explicit explanation when the receipt is locked because the session is waiting on guest decisions / wrap-up resolution
- `LiveSessionBar.swift` already knows about `.awaitingGuestDecisions` and surfaces a warm-state pill (`visitorsToResolve(...)`), which confirms the product language is now wrap-up/awaiting-state oriented rather than a generic "lock editing" feature.

## Current conclusion

The clean shipper lane proved the remaining truth is narrower than the first reframe:

- `ReceiptDetailShellView.handleLiveSessionPhaseChange(_:)` closes `LiveSessionControlSheet` and presents `WrapUpSheet` as soon as the session enters `.awaitingGuestDecisions`.
- `LiveSessionPinnedBarHost.handleTap()` also routes an awaiting-session bar tap straight to `WrapUpSheet`, not back into the control sheet.

That means the honest awaiting-state explanation surface is the wrap-up flow itself, not a control-sheet card.

The smallest honest shipped slice was:

1. add a stable accessibility seam for the existing `WrapUpSheet` subtitle copy (`LiveSplitWrapUpSubtitle`),
2. prove the live host flow with the seeded `liveGuestResolution` UI test after finalize,
3. stop treating `pr5-lock-editing-behavior` as a valid fallback code story.

The control-sheet card experiment was dropped because it was not on the real user path.

## Files cited

- `/Users/leokwan/Development/resplit-ios/.cursor/plans/remaining-work.plan.md`
- `/Users/leokwan/Development/resplit-ios/.cursor/plans/live-split-prod-ready.plan.md`
- `/Users/leokwan/Development/resplit-ios/.cursor/plans/resplit-nurse.log.md`
- `/Users/leokwan/Development/resplit-ios/docs/features/live-split-mega-plan.md`
- `/Users/leokwan/Development/resplit-ios/ResplitCore/ReceiptDetail/ReceiptDetailShellContent.swift`
- `/Users/leokwan/Development/resplit-ios/ResplitCore/ReceiptDetail/Contacts Header/ParticipantScrollView.swift`
- `/Users/leokwan/Development/resplit-ios/ResplitCore/ReceiptDetail/Contacts Header/ParticipantPopoverView.swift`
- `/Users/leokwan/Development/resplit-ios/ResplitCore/ReceiptDetail/ReceiptActionFooterView.swift`
- `/Users/leokwan/Development/resplit-ios/ResplitCore/UI/LiveSplit/LiveSessionControlSheet.swift`
- `/Users/leokwan/Development/resplit-ios/ResplitCore/UI/LiveSplit/LiveSessionBar.swift`
- `/Users/leokwan/Development/resplit-ios/ResplitCore/UI/LiveSplit/WrapUpSheet.swift`
- `/Users/leokwan/Development/resplit-ios/ResplitUITests/ReceiptDetailUITests.swift`
