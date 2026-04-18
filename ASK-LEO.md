# ASK-LEO — vidux

Durable queue of questions the fleet has for Leo. Lanes write `[ASK-LEO Q<N>]` entries in their memory.md pointing at a row here. Leo answers inline (fill the `Answer:` line). On the next cycle, the lane reads the answer, acts, and logs `[ACTED Q<N>]`.

Why this exists: memory.md cycles are ephemeral. Durable questions live here so they accumulate state, not re-summaries.

---

## Q1 — Bypass Greptile-wait on vidux repo?
Opened: 2026-04-18T02:16Z | Status: pending | Lane: vidux-ship-coordinator
PR #25 precedent is OWNER-merge (merged 2026-04-13 without Greptile review row). Greptile is not configured on `leojkwan/vidux`. Vidux-ship prompt §5 Phase A requires Greptile, which will never fire here.
Options:
  a) Authorize OWNER-merge on #26 (matches PR #25 precedent)
  b) Require explicit "ship it" comment from you on each PR
  c) Gate on a different reviewer (Sentry / Claude-code-review / none)
Answer:

## Q2 — PR #27 scope-split: accept bundle or split?
Opened: 2026-04-18T09:45Z | Status: pending | Lane: vidux-ship-coordinator
PR #27 branch `claude/vidux-recipes-split` now carries 3 releases stacked: 2.10.0 (refactor) + 2.11.0 (/vidux-status + [ETA: Xh]) + 2.12.0 (mandatory ETA + [FREEFORM]/[METER]) + 2.13.0 (scope TBD, see this doc's commit). PR title still reads "refactor(2.10.0)".
Options:
  a) Accept combined — retitle #27 to cover all 4 releases, ship together after Q1 resolves
  b) Force-push revert on `claude/vidux-recipes-split` down to 2.10.0, cherry-pick 2.11/2.12/2.13 onto fresh branch, open PR #29
  c) Leave as-is, ship as-is with unfortunate title
Answer:
