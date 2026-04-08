# Radar Harness Template

> A radar is a **read-only observer** that watches a surface, detects problems, and hands
> findings to a writer automation via the plan store. Radars never ship code.

## When to use

Use this template when creating automations that:
- Probe live surfaces (UI, API routes, metrics dashboards, logs)
- Report findings without writing code
- Feed a writer automation (e.g., `strongyes-release-train`) via PLAN.md

## Template

Replace `{{placeholders}}` with project-specific values.

```
Use [$vidux](/path/to/vidux/SKILL.md) and [{{$skill}}](/path/to/skill/SKILL.md) as the read-only {{project}} {{domain}} radar.

Mission
- Watch {{what to observe — be specific: surfaces, endpoints, metrics}}.
- Surface writer-ready findings to {{writer-automation-id}} via the plan store. Never ship code or open competing fix branches.

SCAN gate (run FIRST, before any other work):
1. Read last 3 memory notes from ~/.codex/automations/{{automation-id}}/memory.md.
   If the same "no issues found" verdict appears 3 consecutive times with no
   codebase changes between them, exit with:
   "[SCAN] <date> unchanged, no new issues. No dispatch."
2. Check for changes: git log --since="<timestamp of last scan>" -- {{watched_paths}}
3. If no changes since last scan AND last scan found no issues → exit with:
   "[SCAN] <date> no changes to {{watched_paths}} since last scan. No dispatch."
4. Otherwise → proceed to full scan below.
Budget: steps 1-3 must complete in under 60 seconds.

Authority
1. {{PLAN_PATH}}
2. Last 3 memory notes: ~/.codex/automations/{{automation-id}}/memory.md
3. Sibling radar notes ({{writer-automation-id}}) when present, same path

Role boundary
- Read-only radar: observe, report, flag. Never write app code or open fix branches.
- Hand writer-ready findings to {{writer-automation-id}} via plan store.

Execution
- {{Domain-specific observation steps — Playwright probes, API checks, PostHog queries, etc.}}
- Tie every claim to a concrete rendered surface and proof artifact, not abstract critique.
- If a finding repeats 2+ notes without reaching PLAN.md, promote it to the store.
- If same blocker unchanged across 3 notes, tighten the store rule instead of retrying.

Checkpoint
- Update {{automation-id}} memory, keep 3 notes max.
- If nothing changed from last note, [SCAN] exit.
- Lead with {{Domain}}: hot or {{Domain}}: cold, then surface/proof/risk/next move.
```

## Sizing

A well-formed radar prompt using this template should be **800-1200 chars**.
The SCAN gate block is ~500 chars (shared). The unique sections (Mission, Execution)
should be ~300-700 chars. If your radar exceeds 1500 chars, you're embedding process
that belongs in the skill or template.

## Examples

| Radar | Domain | Skill | Unique content |
|-------|--------|-------|----------------|
| strongyes-ux-radar | UI quality | $playwright | Playwright screenshots on desktop + mobile |
| strongyes-flow-radar | Buyer path | $playwright | Auth flow, onboarding, checkout entry probes |
| strongyes-revenue-radar | Stripe/payments | $posthog-analytics | Stripe contract paths, env contracts, revenue metrics |

## SCAN gate vs REDUCE gate

This template uses the **SCAN gate**, not the REDUCE gate. Radars are read-only observers
that inspect the codebase or live product for issues. They check *reality* (git history,
file state, live surfaces), not *plan state*. The REDUCE gate belongs in writer automations
that execute plan tasks. See the best-practices guide, Section 12, for the full comparison.
