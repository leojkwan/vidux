# 2026-04-04 Fintech Subagent Synthesis

## Goal
Capture the parallel Doctrine 9 research lanes for Project 1 and determine whether fan-out produced a better state-management and pagination answer than a single inline read would have.

## Sources
- [Source: `/Users/leokwan/Development/ai/skills/vidux/projects/strongyes/evidence/2026-04-02-revenue-operator-signals.md:15-21,40-42`] StrongYes centralizes business, deployment, and blocker context into one operator payload instead of multiple ad hoc reads.
- [Source: `/Users/leokwan/Development/ai/skills/vidux/projects/strongyes/evidence/2026-04-01-profit-reset.md:268-275`] The repo's strongest financial-dashboard pattern is "blocked but legible": counts stay visible and blockers are named in the same surface.
- [Source: `/Users/leokwan/Development/ai/skills/vidux/projects/strongyes/evidence/2026-04-01-profit-reset.md:327-329`] Business progress states are modeled as first-class events and surfaced back into the shared scoreboard.
- [Source: `/Users/leokwan/Development/ai/skills/vidux/projects/strongyes/evidence/2026-04-02-kv-customer-migration-plan.md:55-59`] The repo already uses idempotent upserts, stable dedupe keys, and explicit fingerprints when repeated writes or replays are expected.
- [Source: `/Users/leokwan/Development/ai/skills/brand-resplit/SKILL.md:168-176`] Money surfaces reserve heavy typography for totals and keep one primary CTA per region.
- [Source: `/Users/leokwan/Development/ai/skills/vidux/projects/vidux-endurance/investigations/transaction-history-wrong-totals.md:25-49`] The Project 1 investigation already defines the fake surface's root cause and the selector-driven fix path.

## Findings

### 1. One selector pipeline is the best shared-state pattern
Both fan-out lanes converged on the same answer: the fake fintech dashboard should ingest raw transaction pages plus reconciliation metadata, normalize them into one ledger store, and derive summary tiles, visible rows, reconciliation warnings, and export totals from the same selector layer. The strongest repo-local analogue is StrongYes's operator payload, which centralizes business context instead of stitching together separate reads.

### 2. Pagination consistency should be enforced with id-based merges, not view-local math
The pagination lane found the closest repo-local analogue in StrongYes's idempotent backfill rules: repeated runs must dedupe by stable identifiers and metadata fingerprints. Applied to the fake transaction history, that means page merges must upsert by `transaction_id`, never by array position, so returning from page 2 cannot duplicate reversal rows or drift totals.

### 3. Blocked-but-legible states are more credible than hiding incomplete totals
StrongYes keeps counts visible even when payment blockers make the business unavailable. That same pattern should govern the fake fintech surface: a pending reversal or sync mismatch should not blank out the totals. Instead, the totals stay visible with an explicit warning that adjustments are excluded or incomplete.

### 4. Money-first hierarchy is a stable UI rule across the repo
The Brand Resplit rules reinforce that totals should dominate visually and actions should stay secondary. For the fake fintech dashboard, this supports using prominent summary tiles, restrained filter controls, and a receipt-like treatment for reconciliation sections.

### 5. Fan-out was useful, but only moderately token-efficient
Inference: the two explorers saved coordinator context because each returned 5 targeted citations instead of forcing one session to reopen multiple large evidence files. The savings were moderate rather than dramatic because both lanes converged on some of the same StrongYes sources. Doctrine 9 still passed: the coordinator stayed lean and only consumed the synthesized outputs.

## Recommendations
- Reuse one normalized ledger plus selector pipeline as the canonical fake-project architecture for totals, rows, banners, and exports.
- Treat page replay as an idempotency problem and require `transaction_id`-based merges before recomputing any totals.
- Grade Doctrine 9 as `pass` with a friction note about overlapping citations across subagent lanes.
