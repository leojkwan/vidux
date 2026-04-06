# Evidence — Live Split Control-Sheet Lane Boundary

Date: 2026-04-06

## Why this note exists

Task 6 is still the next honest UX radar slice, but fresh repo truth says the surface is already warm in the attached root. This pass should not rewrite repo-local Live Split plans just to restate the same `lock editing` reframe from a dirty checkout.

## Fresh repo truth

- `git symbolic-ref refs/remotes/origin/HEAD` still returns `refs/remotes/origin/master`.
- `git status --short --branch` from `/Users/leokwan/Development/resplit-ios` shows `## master...origin/master [behind 22]` plus modified repo-owned coordination files and deleted legacy `ai/skills/vidux/...` files in the attached root.
- The "web repo" status resolves to the same top-level git root, `/Users/leokwan/Development/resplit-ios`, so there is no separate clean web checkout to use as a safer write target for this surface.
- The latest compacted ledger window already contains a fresh live row on the same Live Split plan + code surface:
  - `2026-04-06T22:30:53.000Z [live] codex/019d64e7`
  - touched files include `.cursor/plans/live-split-prod-ready.plan.md`, `.cursor/plans/remaining-work.plan.md`, `ResplitCore/UI/LiveSplit/LiveSessionControlSheet.swift`, `ResplitCore/UI/LiveSplit/LiveSessionBar.swift`, `ResplitCore/UI/LiveSplit/LiveSessionViewModel.swift`, and `docs/features/live-split-mega-plan.md`
- Repo-local `.agent-ledger/hot-files.md` does not currently claim `LiveSessionControlSheet.swift` or the two repo-local plan files; the only Live Split hot-files row still visible there is a merged finalize-diagnostics entry on `LiveSessionViewModel.swift`.
- Existing evidence in `evidence/2026-04-06-live-controlsheet-awaiting-state.md` already proves the product-side reframe: stale `pr5-lock-editing-behavior` wording is obsolete, and the real user-facing seam is the awaiting/wrap-up explanation inside `LiveSessionControlSheet`.

## Current conclusion

- The surface is warm enough that UX radar should not rewrite repo-local Live Split plans from the dirty attached root, even though hot-files is silent on the specific control-sheet files.
- The correct move for this pass is to strengthen the public Vidux routing rule and leave repo-local wording/code updates to the next clean `origin/master` shipper lane.
- The next ship-ready slice is unchanged:
  1. from a clean `origin/master` worktree, add a small control-sheet awaiting/wrap-up affordance, or
  2. if runtime proof shows the control sheet is already clear enough, rewrite the stale repo queue wording there so future loops stop naming `lock editing`

## Files cited

- `/Users/leokwan/Development/vidux/projects/resplit/PLAN.md`
- `/Users/leokwan/Development/vidux/projects/resplit/evidence/2026-04-06-live-controlsheet-awaiting-state.md`
- `/Users/leokwan/Development/resplit-ios/.agent-ledger/hot-files.md`
- `/Users/leokwan/Development/resplit-ios/.cursor/plans/remaining-work.plan.md`
- `/Users/leokwan/Development/resplit-ios/.cursor/plans/live-split-prod-ready.plan.md`
- `/Users/leokwan/Development/resplit-ios/docs/features/live-split-mega-plan.md`
