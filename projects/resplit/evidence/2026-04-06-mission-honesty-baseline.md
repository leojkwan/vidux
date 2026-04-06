# Resplit Mission Honesty Baseline

## Purpose
Capture the current control-plane reason Resplit can sound “mostly done” while the broader product still feels far from finished.

## Findings
- [Source: `/Users/leokwan/Development/resplit-ios/RALPH.md`, read 2026-04-06] The repo queue still spans many active surfaces: App Store/TestFlight feedback, hot launch blockers, receipt-detail parity, release readiness, screenshots, observability, and remaining launch polish.
- [Source: `/Users/leokwan/Development/resplit-ios/.cursor/plans/resplit-nurse.log.md`, read 2026-04-06] The current durable release wall is build `1107`, blocked by GitHub Actions billing/spending and the missing ASC auth key. That is one important blocker, but it is only the release lane.
- [Source: `/Users/leokwan/Development/ai/automations/resplit-nurse/automation.toml` and `/Users/leokwan/Development/ai/automations/resplit-vidux/automation.toml`, read 2026-04-06] Both recurring prompts were still reading `/Users/leokwan/Development/ai/skills/vidux/projects/resplit/PLAN.md` even though the public Resplit store no longer existed after Vidux canonicalization.
- [Source: `/Users/leokwan/.codex/automations/resplit-nurse/memory.md` and `/Users/leokwan/.codex/automations/resplit-vidux/memory.md`, read 2026-04-06] Recent runs honestly shipped small slices and corrected stale branch residue, but the summaries mostly describe current slice and build-boundary truth. Without a durable public mission store, the loops have no reliable place to carry the larger remaining-gap inventory.
- [Source: user directive, 2026-04-06] The user explicitly reports that the product feels closer to `20%` complete than `90%`. Treat that mismatch as a real control-plane defect until the store can enumerate the remaining user-visible gaps concretely.

## Decision
- Recover the public Resplit mission store.
- Force recurring loops to separate current slice, release boundary, and overall mission completion.
- Rebaseline the remaining mission gaps from repo truth instead of inferring them from the latest shipped slice.
