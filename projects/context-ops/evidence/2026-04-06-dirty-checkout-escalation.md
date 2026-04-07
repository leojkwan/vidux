# 2026-04-06 Dirty Checkout Escalation

## Why this slice
The orchestrator has now reported the same `git pull --rebase` blocker in its last three notes, but the shared repo-backed fleet is still clean against live SQLite. That makes the dirty canonical `ai` checkout a persistent environment blocker, not a fresh control-plane defect worth another bounded improvement slot.

## Facts gathered
- [Source: `/Users/leokwan/Development/ai/automations/codex-automation-orchestrator/memory.md`, read 2026-04-06] The last 3 orchestrator notes all repeat the same blocker: `git pull --rebase` in `/Users/leokwan/Development/ai` fails because of unrelated local changes.
- [Source: `git pull --rebase` in `/Users/leokwan/Development/ai`, 2026-04-06] Pull still fails with `cannot pull with rebase: You have unstaged changes` plus `your index contains uncommitted changes`.
- [Source: `git rev-list --left-right --count HEAD...@{upstream}` in `/Users/leokwan/Development/ai`, 2026-04-06] The canonical `main` checkout is `0 1` versus upstream, so it is one commit behind `origin/main` as well as dirty.
- [Source: `git status --short` in `/Users/leokwan/Development/ai`, 2026-04-06] The checkout contains large unrelated staged deletions across automation and retired Vidux surfaces plus unrelated modified files, so a broad sync or commit would risk sweeping work the orchestrator does not own.
- [Source: repo-vs-DB comparison, 2026-04-06] The live control plane still shows `27` shared repo-backed automation IDs, `34` scheduler rows total, and `0` mismatches across the shared rows, leaving `7` DB-only active rows as the next real audit seam once the checkout is trustworthy again.

## Change queued
1. Recorded the dirty canonical checkout as a persistent environment blocker in the Context Ops store instead of treating it as fresh fleet drift again.
2. Updated the orchestrator memory so the next run starts from the escalated truth: shared rows are still in sync, the blocker is now procedural, and the next safe move is a sync window before more repo-backed prompt surgery.
3. Deliberately did not mutate repo-backed TOMLs or live SQLite rows in this slice because there is no shared-row drift to fix and the canonical `ai` checkout is not currently safe for another write-heavy control-plane pass.

## Remaining exposure
- The next control-plane write that touches `/Users/leokwan/Development/ai/automations` should begin with a deliberate sync window: preserve or land the unrelated local work, pull the missing upstream commit, then resume the DB-only row classification work from a trustworthy checkout.
- Until that sync window happens, future orchestrator runs should treat the failed pull as already-known context and spend their bounded improvement slot on other evidence-backed seams only when a tightly scoped local fix is still safe.
