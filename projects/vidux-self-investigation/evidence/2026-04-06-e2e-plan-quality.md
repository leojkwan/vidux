# 2026-04-06 E2E Plan Quality Test Results

## Goal
Test whether vidux produces high-quality plans with proper subplan depth when given real projects from scratch.

## Sources
- [Source: e2e-nextjs agent] Fresh NextJS project, mission: "task management app with auth, CRUD, drag-and-drop, analytics dashboard"
- [Source: e2e-ios agent] Fresh iOS/SwiftUI project, mission: "personal finance tracker with receipt scanning, categories, budgets, charts"

## Findings

### 1. NextJS Plan Quality (scored by agent)

| Criterion | Score | Notes |
|-----------|-------|-------|
| Evidence depth | 4/5 | 12 citations with [Source:] markers, all real file paths. Deducted: no external/live evidence (no npm queries). |
| Task specificity | 5/5 | Every task specifies exact file paths (e.g., `lib/db.ts`, `app/actions/tasks.ts`), functions, and gate conditions. No vague tasks. |
| Compound task depth | 4/5 | DnD reordering correctly spawned `investigations/drag-and-drop-reordering.md` with full shape (Evidence, Impact Map, Fix Spec, Tests, Gate). Auth arguably should have been compound too. |
| Constraint coverage | 4/5 | 6 ALWAYS + 5 NEVER rules. Grounded in real evidence (AGENTS.md, Next.js 16 docs). Missing: no stakeholder prefs (expected for greenfield). |

**Total: 17/20**

Files produced:
- PLAN.md (79 lines, 14KB)
- evidence/2026-04-06-nextjs-codebase-analysis.md (80 lines, 10 findings)
- investigations/drag-and-drop-reordering.md (44 lines)

### 2. iOS Plan Quality (scored by agent)

| Criterion | Score | Notes |
|-----------|-------|-------|
| Evidence depth | 5/5 | 10 citations, 4 separate evidence snapshots with full Goal/Sources/Findings/Recommendations format. Sources: codebase greps, Apple Developer Docs, WWDC sessions. |
| Task specificity | 5/5 | All 10 tasks name specific SwiftUI views, SwiftData models, service classes. Task 7 specifies exact chart types (SectorMark, BarMark, LineMark). |
| Compound task depth | 5/5 | Receipt scanning correctly spawned `investigations/receipt-scanning-pipeline.md` with all required sections. |
| Constraint coverage | 4/5 | 7 ALWAYS + 4 NEVER + 2 ASK FIRST. No stakeholder prefs (expected for greenfield solo). |

**Total: 19/20 (estimated — subplan readiness score truncated)**

Readiness checklist: 9/10 (all required checks PASS, missing stakeholder preference)

Files produced:
- PLAN.md (82 lines)
- evidence/2026-04-06-codebase-baseline.md
- evidence/2026-04-06-ios-receipt-scanning-research.md
- evidence/2026-04-06-swiftdata-budget-modeling.md
- evidence/2026-04-06-swift-charts-dashboard.md
- investigations/receipt-scanning-pipeline.md

### 3. Key Validation Points
- Both plans follow the full PLAN.md template (Purpose, Evidence, Constraints, Decisions, Tasks, Open Questions, Surprises, Progress)
- Both correctly identify compound tasks and create investigation files
- Evidence citations are real (file paths, grep results, framework docs) — not hallucinated
- Constraint sections are grounded in actual project state
- Tasks have dependency markers, parallelization flags, and gate conditions
- iOS plan produced 4 separate evidence snapshots — proper research depth
- Readiness checklist scoring works (both scored 9/10, expected gap is stakeholder prefs)

### 4. Areas for Improvement
- NextJS agent didn't use external evidence sources (MCP, web search) — plan quality would improve with live queries
- Auth task in NextJS should have been flagged as compound (multi-file, middleware + actions + UI)
- Neither plan had a Progress section entry (no cycle had run yet — expected but template should note this)

## Recommendations
- Vidux plan quality is VALIDATED for both web and mobile stacks
- Compound task detection and investigation creation work as designed
- Consider adding guidance for when to auto-compound tasks (> 5 files touched = compound)
- The readiness checklist scoring is effective — 9/10 threshold matches real-world gaps
