# 2026-04-06 Camera Routing Drift

## Why This Pass Happened

The active `resplit-nurse` lane is already consuming the AP539 receipt-detail follow-through and the repo-local branch-truth cleanup, so this radar pass needed a different unowned surface. Fresh repo truth showed a narrower issue: an obsolete scratch file still names `camera UX and the App Store camera screenshot` as an open launch bucket even though the canonical receipt-detail and screenshot plans already mark that camera cluster as shipped.

## Fresh Repo Truth

- `.cursor/plans/receipt-detail-ux-parity.plan.md` marks all four camera work items complete:
  - `camera-volume-shutter`
  - `camera-cta-clarity`
  - `camera-receipt-assist`
  - `camera-app-store-screenshot`
- The same canonical plan records the shipped camera-proof chain:
  - `CameraViewController` volume-button shutter landed.
  - confirm/retake CTAs now use icon-first `Label` affordances.
  - `ReceiptFramingGuide` shipped as the capture assist overlay.
  - `ScreenshotCameraScene` plus marketing capture `02_Camera` were added for App Store assets.
  - follow-through ship note: canonical `master` commit `a2ef2826` (`fix: harden camera preview teardown`) plus TestFlight build `2.0.0 (549)`.
- `.cursor/plans/app-store-screenshots.plan.md` no longer treats camera capture as the blocker:
  - the checked-in screenshot path is already aligned on `02_Camera`, not the older `02_Scan`
  - the current blocker is provenance/manual review plus launch-locale scope for non-English assets
- `.cursor/plans/resplit-loop-state.md` still says the remaining launch buckets include `camera UX and the App Store camera screenshot`, but the repo instructions explicitly mark that file as obsolete scratch rather than canonical state.

## Coordination Outcome

- Camera/onboarding is not an honest remaining mission-gap bucket from current repo truth.
- The real screenshot/release risk is now provenance, locale scope, and current-build/manual verification, not missing camera UX work.
- Future loops should treat obsolete scratch files as evidence of coordination drift only. They may not reopen already-shipped camera work when the canonical receipt-detail and screenshot plans disagree.

## Next Ship-Ready Slice

- Keep camera UX closed unless fresh current-build/manual/Sentry proof contradicts the shipped behavior.
- If screenshot work reopens, route it through `.cursor/plans/app-store-screenshots.plan.md` and current build truth, not through the deprecated loop-state scratch file.
