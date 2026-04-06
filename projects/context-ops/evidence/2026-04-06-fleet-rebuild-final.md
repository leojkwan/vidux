# 2026-04-06 Fleet Rebuild — Final State

## Goal
Document the complete fleet rebuild: from 33 automations (20 ACTIVE + 13 PAUSED) down to 12 clean ACTIVE automations, all with burst-mode doctrine, 30-minute cadences, and product-taste focus.

## Sources
- [Source: DB query] `SELECT id, status FROM automations` before and after rebuild
- [Source: Leo direction] "delete strongyes now and start over", "emphasis on the correct UI", "not enough fire per session", "set most of them to half hour spreaded, and the meta one per hour"
- [Source: evidence] `projects/context-ops/evidence/2026-04-06-fleet-snapshot-before-retirement.md` — pre-retirement snapshot
- [Source: evidence] `projects/vidux-v230/evidence/2026-04-06-burst-vs-watch-mode-insight.md` — structural bimodal insight
- [Source: memory] `feedback_vidux_automation_doctrine.md` — three tenets (no mid-zone, taste, bounded recursion)

## Final Fleet (12 automations)

### Resplit (4 automations)
| Automation | Cadence | Chars | Focus |
|-----------|---------|-------|-------|
| resplit-web | :00,:30 | 3040 | Web app UI/UX, Playwright proof, responsive |
| resplit-asc | :03,:33 | 2992 | ASC bug fixes, investigation-first, simulator proof |
| resplit-currency | :06,:36 | 2830 | Currency/FX feature UX, picker, rates, editing |
| resplit-android | :09,:39 | 2920 | Android parity, Material 3 + Compose, offline-only |

### StrongYes (6 automations)
| Automation | Cadence | Chars | Focus |
|-----------|---------|-------|-------|
| strongyes-ux | :12,:42 | 2903 | Site-wide UI/UX, buyer path, trust |
| strongyes-content-scraper | :15,:45 | 2633 | $nia-driven scraping, editorial, /learn |
| strongyes-product | :18,:48 | 2578 | DSA solver, study plans, problems, playbook |
| strongyes-backend | :21,:51 | 2483 | Sentry/Supabase/Stripe/auth/observability |
| strongyes-email | :24,:54 | 2378 | Resend templates, drips, deliverability |
| strongyes-problem-builder | :27,:57 | 2500 | Docker + DO catalog, codify /skills |

### Meta (1 automation)
| Automation | Cadence | Chars | Focus |
|-----------|---------|-------|-------|
| vidux-meta | :00 (1hr) | 2615 | Fleet QA, bimodal grading, self-fix |

### Unchanged (1 automation)
| Automation | Cadence | Chars | Focus |
|-----------|---------|-------|-------|
| hourly-media-studio | :05,:25,:45 | 5772 | FCP workflow (separate project) |

## What Was Deleted (22 automations)

### Old Resplit fleet (8)
resplit-nurse (7389 chars), resplit-vidux (5337), resplit-launch-loop (5362), resplit-hourly-mayor, resplit-ios-ux-lab, resplit-oversight, resplit-super-nurse-hourly, resplit-super-team-hourly

### Old StrongYes fleet (6)
strongyes-release-train (4514), strongyes-flow-radar (2264), strongyes-content (2282), strongyes-revenue-radar (2362), strongyes-ux-radar (2423), strongyes-vidux (1186)

### Old Vidux meta (7)
codex-automation-orchestrator (6268), vidux-endurance (2849), vidux-v230-planner (3744), vidux-endurance-test, vidux-hourly-doctor-2, vidux-stress-lab, vidux-v2-rebuild

### Other (1)
dji-regrade-loop (6616)

## Doctrine Baked Into Every Harness

All 11 product harnesses include the BURST block:
```
MODE: BURST. This is a long-running deep-work harness, not a quick check.
Drain the queue. Do not stop after one task. Stop only when the queue is
empty, you hit a hard external blocker, or context budget forces a
structured checkpoint.
```

Plus:
- Self-extending plan rule (add tasks yourself, don't wait for Leo)
- Bounded recursion (know when good enough)
- Closure-bias defense (scan queue BEFORE checkpointing)
- Product taste ($picasso loaded for all UI-touching automations)

## Cadence Strategy
- Product automations: 30-minute intervals, staggered by 3 minutes to avoid scheduler collisions
- vidux-meta: hourly (once per hour at :00)
- hourly-media-studio: unchanged (20-min intervals)
- All: GPT-5.4, Extra High reasoning, Worktree mode

## Design Decisions
1. Organized by work stream (web/asc/currency) instead of by role (writer/radar/release)
2. Every automation can self-extend the plan — no writer/reader distinction
3. Prompt sizes ~2.5-3K chars (down from 5-7K) — $vidux skill carries the doctrine
4. DB race condition discovered: Codex app daemon reverts SQLite changes. Fixed by closing app before writes.
