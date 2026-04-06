# 2026-04-06 Stale Path Audit

## Goal
Determine how many automations still reference the old ai/skills/vidux path instead of the canonical /Users/leokwan/Development/vidux.

## Sources
- [Source: grep across automations/*/automation.toml] 14 automation configs reference old path

## Findings

### 1. All automations load stale vidux
Every automation prompt uses `[$vidux](/Users/leokwan/Development/ai/skills/vidux/SKILL.md)` which reads the OLD copy directly, bypassing the fixed symlinks at ~/.claude/skills/ and ~/.codex/skills/.

Affected automations (14):
- codex-automation-orchestrator (MASSIVE — 120+ line prompt, also references ralph)
- resplit-android
- resplit-launch-loop
- resplit-nurse (MASSIVE — 100+ line prompt with full specialist routing tables)
- resplit-oversight (deprecated but still exists)
- resplit-vidux
- strongyes-content
- strongyes-flow-radar
- strongyes-release-train
- strongyes-revenue-radar
- strongyes-ux-radar
- vidux-endurance
- vidux-v230-planner

### 2. Prompt size distribution
| Automation | Prompt lines | Doctrine 8 compliant? |
|------------|-------------|----------------------|
| resplit-nurse | ~120 | NO — full specialist routing, anti-thrash rules, proof rules |
| codex-automation-orchestrator | ~100 | NO — full per-run method, role boundary, guardrails |
| resplit-android | ~40 | PARTIAL — lean-ish but restates execution model |
| strongyes-release-train | ~56 | NO — 41 lines of restated doctrine |
| strongyes-*-radar | ~20 each | CLOSE — but still restate checkpoint protocol |
| vidux-endurance | ~15 | YES |
| vidux-v230-planner | ~15 | YES |

### 3. The fix
All paths need to change from:
`/Users/leokwan/Development/ai/skills/vidux/SKILL.md`
to:
`/Users/leokwan/Development/vidux/SKILL.md`

Additionally, all project plan references need updating:
`/Users/leokwan/Development/ai/skills/vidux/projects/` → project-specific inline plans or this repo's `projects/`

### 4. Priority
This is the #1 blocker for canonical unification. Until these paths are fixed, every automation run loads stale vidux with Ralph references, old paths, and the "smallest slice" language.

## Recommendations
- Fix all automation paths in one pass (ai/ repo change)
- While fixing paths, also retrofit bloated prompts to Doctrine 8 lean template
- The orchestrator automation should be the one that does this — but it's also loading stale vidux, creating a chicken-and-egg problem. Fix the orchestrator FIRST manually.
