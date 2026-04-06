# 2026-04-06 Remaining Gap Rebaseline

## Why This Pass Happened

The repo queue is still release-blocked, but active `resplit-nurse` lanes already own the support/marketing follow-through and the release-control-plane repair. This radar pass needed to answer a narrower question from fresh repo truth: which user-visible gaps are still real, which ones are already closed or external, and which stale notes should stop steering future loops.

## Fresh Repo Truth

- `git fetch origin --prune && git symbolic-ref refs/remotes/origin/HEAD` still resolves the canonical remote default branch to `refs/remotes/origin/master`.
- Attached-root status is still not a safe ship lane: `git status --short --branch` reports `## master...origin/master [behind 18]` plus local edits in `.agent-ledger/hot-files.md`, `.cursor/plans/app-store-feedback.plan.md`, `.cursor/plans/resplit-nurse.log.md`, and `RALPH.md`.
- The recent ledger window is dominated by live `resplit-nurse` work, but compaction is straightforward:
  - `codex/019d64a1` is repairing control-plane/store honesty and release reporting, not shipping a user-facing surface.
  - `codex/019d64bd` already landed the `PrimaryFeatures` master replay and is sitting on the unchanged billing/ASC-key wall.
  - `codex/019d64c3` is actively replaying the support-page follow-through on `main`.
- `git -C resplit-web status --short --branch` resolves to the same attached root, so there is no separate nested-web repo state to treat as an independent ownership signal from this checkout.

## Surface Reclassification

### Closed On Trunk, Do Not Reopen

- `ADkEbuf2oy4YeQ3fkfp8KEY` is not a fresh missing surface. The tracker already maps it to the existing trip-summary disclosure family and cites merged-trunk proof for `df58508a` (`fix: restore trip summary disclosure`) with focused UI coverage at `/tmp/resplit-trip-summary-disclosure-master-20260402.xcresult`.
- The same closure is reinforced by `.agent-ledger/hot-files.md`, which explicitly says `ADkE...` still maps to the already-fixed trip-summary disclosure family unless raw ASC assets disprove it.

### External Or Process-Only, Not A Repo Code Lane

- `AKOYEOOzMFxRbMh_gAVRvUs` remains blocked on apex-host / associated-domain ownership, not repo code. Current proof still shows `www` serving AASA and `/join` with `HTTP/2 200` while `https://resplit.app/...` redirects with `HTTP/2 307`.
- `ABv07GVF5uP60qjSef2fBqk` already has its architecture doc at `docs/features/receipt-ocr-polling-architecture.md`; it is a post-release product/system design lane, not a same-run launch fix.
- `AFw7znl8OBqhoP0Ja9Vybbc` (geocoding + business matching) and `AKigU4RhvC1Lvbv5Ig-596g` (OCR key-value extraction) are backlog feature/investigation requests, not honest launch-polish slices.

### Still Launch-Adjacent

- `AP539ClB0F16Az7Cv-DkwXA` remains the only still-live launch-adjacent iOS UX complaint in this cluster: the screenshot still points at the row-end amount/edit affordance, and the current tracker note still says a visual decision may need to ship before the next uploaded build.
- But its routing notes are stale and internally contradictory:
  - `RALPH.md` and fresh git preflight say the remote default branch is `origin/master`.
  - the feedback row and old proof breadcrumbs still talk about `origin/main` as the default-branch reopen point.
  - `.agent-ledger/hot-files.md` warns that the attached-root AP539 lane is stale and must not be reopened from this dirty root.
- Fresh proof narrowed AP539 to a real product choice, not a proof-room failure:
  - `/tmp/resplit-ap539-proof-hook-20260406-1048.xcresult` passed the focused title-wrap and price-tap tests after `7b0b5593` stabilized the test hook.
  - `/tmp/resplit-ap539-wrap-artifacts/long-title-wrap.png` and `/tmp/resplit-ap539-wrap-artifacts/app-ui-hierarchy.txt` show the row rendering correctly even where the earlier harness failed.

## Inventory Outcome

The honest remaining-gap picture from this cluster is:

1. Active shipper work is already elsewhere: release-control-plane honesty, support-page follow-through on `main`, and the just-landed `PrimaryFeatures` replay on `master`.
2. Trip-summary disclosure is already closed on trunk and should not keep showing up as a missing UX seam.
3. Deep-link parity is external host/domain configuration, not repo-code backlog.
4. OCR polling, geocoding, and OCR key-value extraction are real backlog items, but not honest launch-polish work for the next shipper slice.
5. AP539 is the only remaining launch-adjacent UX decision in this set, but branch-truth/routing notes must be normalized before anyone reopens it.

## Next Ship-Ready Slice

If the release wall is still externally blocked on the next pass and an iOS proof room is actually free, the next honest slice from this cluster is:

- reopen `AP539ClB0F16Az7Cv-DkwXA` only from a clean canonical default-branch worktree after rewriting stale `origin/main` "default branch" language in repo-local checkpoints
- keep `ADkE...`, `AKOY...`, `ABv07...`, `AFw7...`, and `AKig...` out of the fallback code queue unless new proof contradicts the current classification
