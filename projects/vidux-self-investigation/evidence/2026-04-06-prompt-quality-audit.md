# 2026-04-06 Automation Prompt Quality Audit

## Goal
Compare the existing strongyes-release-train automation prompt (56 lines) against what /vidux-loop would generate (target: under 15 lines). Identify what's restated doctrine vs what's project-specific.

## Sources
- [Source: automations/strongyes-release-train/automation.toml] 56-line prompt, existing production automation
- [Source: commands/vidux-loop.md] Writer prompt template, Doctrine 8 compliance

## Findings

### 1. Current prompt breakdown (56 lines)
| Category | Lines | Should be in prompt? |
|----------|-------|---------------------|
| Skill references + mission | 4 | YES — project-specific |
| Authority and read order | 8 | YES — tells vidux where to find state |
| Role boundary | 3 | YES — project-specific |
| Execution model | 4 | NO — vidux knows writers use worktrees |
| "land the smallest verified slice" | 1 | NO — this is the anti-pattern Leo flagged |
| Operating priorities | 4 | PARTIAL — "Revenue first" is project DNA, rest is generic |
| Guardrails | 5 | NO — vidux doctrine already covers this |
| Checkpoint protocol | 5 | NO — vidux handles checkpointing |
| "Never discard work you didn't create" | 2 | NO — vidux doctrine |
| "Ask first before destructive cleanup" | 1 | NO — and Leo explicitly said STOP asking |

**Result: 15 lines are project-specific. 41 lines restate vidux doctrine.**

### 2. Lean version (/vidux-loop would generate)

```
Use [$vidux](/Users/leokwan/Development/vidux/SKILL.md) as writer for strongyes-web.

Mission: Make StrongYes a revenue-bearing web product with a trustworthy paid funnel.

Authority store: /Users/leokwan/Development/strongyes-web/vidux/ux-overhaul/PLAN.md
Harness: /Users/leokwan/Development/strongyes-web/vidux/ux-overhaul/HARNESS.md

Role: writer — only automation that ships StrongYes web code, merges, or deploys.
Siblings: strongyes-flow-radar, strongyes-content, strongyes-ux-radar, strongyes-revenue-radar

Design DNA:
- Revenue first. Evidence over instinct.
- Keep working through the queue until a real boundary.
- Full e2e per task: ideate → plan → dev → test → QA → commit.
```

**13 lines. Everything else is handled by vidux SKILL.md when the agent loads it.**

### 3. What the old prompt gets WRONG
- "land the smallest verified slice" — directly contradicts Leo's feedback
- "Ask first before destructive cleanup" — Leo said stop asking for permission
- "Never discard or overwrite work you did not create" — restates vidux doctrine unnecessarily
- Execution model section — vidux already knows writers use worktrees
- Checkpoint protocol — vidux already handles this in LOOP.md
- The 56-line prompt makes the agent spend context reading process instructions instead of doing work

### 4. Scoring
| Metric | Old (56 lines) | New (13 lines) | 
|--------|----------------|----------------|
| Doctrine 8 compliance | FAIL (41 lines of restated doctrine) | PASS |
| "Smallest slice" language | PRESENT | ABSENT |
| Permission-asking language | PRESENT | ABSENT |
| Project-specific signal density | 27% (15/56) | 100% (13/13) |
| Context budget waste | ~800 tokens on process | ~200 tokens total |

## Recommendations
- All existing automations should be retrofitted to the lean template.
- /vidux-loop validate should flag prompts over 15 lines and prompts containing "smallest slice" or "ask first."
