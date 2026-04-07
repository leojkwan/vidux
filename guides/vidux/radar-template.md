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

REDUCE gate (run FIRST, before any other work):
1. Run: bash /path/to/vidux/scripts/vidux-loop.sh {{PLAN_PATH}}
2. Read the JSON output. If ANY of these are true, checkpoint and exit immediately:
   - next_action is "none"
   - auto_pause_recommended is true
   - circuit_breaker is "open"
   - bimodal_gate is "blocked"
   Write a 1-line memory note: "[REDUCE] <date> <reason>. No dispatch."
   Do NOT read authority files, load skills, or do any other work. Exit now.
3. Read the last 3 memory notes. If the top note is a [REDUCE] exit with the
   same reason as this run's JSON, exit with: "[REDUCE] <date> unchanged. No dispatch."
4. If next_action is "dispatch": proceed to full execution below.
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
- If nothing changed from last note, [REDUCE] exit.
- Lead with {{Domain}}: hot or {{Domain}}: cold, then surface/proof/risk/next move.
```

## Sizing

A well-formed radar prompt using this template should be **800-1200 chars**.
The REDUCE gate block is ~600 chars (shared). The unique sections (Mission, Execution)
should be ~200-600 chars. If your radar exceeds 1500 chars, you're embedding process
that belongs in the skill or template.

## Examples

| Radar | Domain | Skill | Unique content |
|-------|--------|-------|----------------|
| strongyes-ux-radar | UI quality | $playwright | Playwright screenshots on desktop + mobile |
| strongyes-flow-radar | Buyer path | $playwright | Auth flow, onboarding, checkout entry probes |
| strongyes-revenue-radar | Stripe/payments | $posthog-analytics | Stripe contract paths, env contracts, revenue metrics |

## REDUCE gate updates

This template includes the `circuit_breaker` field (added in Phase 15.1). Older radar
prompts that check only `bimodal_gate` should be updated to also check `circuit_breaker`.
