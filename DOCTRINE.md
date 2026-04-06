# Vidux Doctrine

> Six principles. Memorize them. Everything else follows.

## 1. Plan is the store
PLAN.md is the single source of truth. Code is a derived view.
If the code is wrong, the plan is wrong.

## 2. Unidirectional flow
Gather -> Plan -> Execute -> Verify -> Checkpoint -> Gather.
Never skip. Never code without a plan entry. To deviate, update the plan first.

## 3. 50/30/20
50% plan refinement. 30% code. 20% last mile.
If you're coding more than planning, stop.

## 4. Evidence over instinct
Every plan entry cites a source. No source = no entry.
MCP queries, codebase greps, design docs, team conventions.

## 5. Design for completion
Dispatches end. Context is lost. Auth expires.
The store persists. State lives in files. Every cycle reads fresh. Any agent can resume.

## 6. Process fixes > code fixes
Every failure produces two things: a code fix and a process fix.
The process fix (new constraint, test, hook, or skill update) is the valuable one.

---

## The Redux Analogy

| Redux | Vidux |
|-------|-------|
| Store | PLAN.md |
| Actions | Plan amendments (require evidence) |
| Reducers | Gather + synthesize + critique |
| View | Code (derived, never independent) |
| Dispatch | Must go through the plan |
| DevTools | Ledger (reconstruct any mission) |

---

## When Vidux vs When Pilot

| Signal | Use |
|--------|-----|
| Quick bug fix, single file, < 2 hours | Pilot (Mode A) |
| PR nursing, CI fixes, review responses | Pilot |
| Multi-day feature, 8+ files, multiple concerns | **Vidux (Mode B)** |
| Quarter-long project compressed to a week | **Vidux (Mode B)** |
| "We need to plan this" | **Vidux** |
| "Just do it" | Pilot |
