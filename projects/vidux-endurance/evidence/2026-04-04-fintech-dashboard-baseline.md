# 2026-04-04 Fintech Dashboard Baseline

## Goal
Document the highest-signal repo-local patterns that can ground the fake fintech dashboard after the Nia MCP server failed to initialize in this automation runtime.

## Sources
- [Source: Nia MCP probe, 2026-04-04] `list_mcp_resources(server="nia")` and `list_mcp_resource_templates(server="nia")` both failed during MCP initialize with `connection closed: initialize response`.
- [Source: `/Users/leokwan/Development/ai/skills/vidux/projects/strongyes/evidence/2026-04-02-revenue-operator-signals.md:9-42`] StrongYes already has a repo-side operator audit and a private revenue scoreboard that combines blocker visibility, business metrics, deployment context, and next-action guidance.
- [Source: `/Users/leokwan/Development/ai/skills/vidux/projects/strongyes/evidence/2026-04-01-profit-reset.md:268-285`] The scoreboard pattern is "blocked but legible": it keeps zero-state counts visible, separates public and private surfaces, and names the exact blocker instead of hiding the dashboard behind a generic failure.
- [Source: `/Users/leokwan/Development/ai/skills/vidux/projects/strongyes/evidence/2026-04-01-profit-reset.md:327-333`] StrongYes tracks buyer activation as a distinct business event and threads that state back into the operator surface instead of inferring progress from UI navigation alone.
- [Source: `/Users/leokwan/Development/ai/skills/brand-resplit/SKILL.md:168-176`] Monetary surfaces reserve heavy typography for key totals, keep one primary CTA per region, and use receipt/money-specific visual treatment instead of generic separators.

## Findings

### 1. Good financial dashboards keep totals and blockers visible at the same time
The StrongYes operator surface does not hide when revenue is blocked. It keeps counts, readiness state, and exact blockers in one view. For the fake fintech dashboard, the transaction history should work the same way: summary totals, reconciliation status, and "why this number is incomplete" warnings must share one source of truth instead of rendering independently.

### 2. Summary cards need the same business ledger as the detailed table
The repo-local revenue scoreboard combines ledger entities, latest timestamps, 7-day and 30-day rollups, and deployment context in one payload. That is a strong grounding pattern for a fake fintech dashboard: account-level totals, transaction rows, and reconciliation badges should all be derived from the same normalized ledger state rather than from separate ad hoc queries.

### 3. Progress events matter as much as balances
StrongYes added explicit activation events and then surfaced them in the scoreboard so operators can distinguish "buyer exists" from "buyer started the sprint." The fake fintech dashboard should mirror that principle: cleared, pending, reversed, and disputed transactions are distinct state transitions, not cosmetic row styles.

### 4. Money-first UI hierarchy is a real repo convention here
Brand Resplit's non-negotiables reserve heavy typography for key totals and enforce one primary CTA per region. Even though this endurance project is fake, those conventions give a credible financial-dashboard baseline: primary summary values should dominate, filters/actions should stay subordinate, and receipt-like sections should visually telegraph that they are monetary records.

### 5. Nia failure is itself evidence and must be checkpointed
The task asked for Nia-backed research, but the Nia MCP server is not operational in this runtime. The correct Vidux move is to record that failure explicitly, use repo-local evidence only, and avoid claiming external research coverage that did not happen.

## Recommendations
- Ground the fake fintech dashboard in a shared-ledger pattern: summary tiles, transaction table, and reconciliation warnings should all derive from one normalized transaction store.
- Keep a blocked-but-legible operator state in the fake surface so totals remain visible even when filters, pending reversals, or sync errors make them incomplete.
- Do not claim Nia-backed findings in this project unless the MCP server actually initializes in a later run.
