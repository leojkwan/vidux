# Resplit — Ship to App Store

## Purpose
Get Resplit iOS into users' hands. Fix the remaining ASC bugs, close localization gaps, nail the screenshots, and cut a clean TestFlight build. Every cycle moves the product closer to a real App Store release.

## Evidence
- [Source: app-store-feedback.plan.md, 2026-04-08] 71 open ASC items: 6 new, 4 triaged, 56 fixed-unverified, 5 blocked
- [Source: remaining-work.plan.md, 2026-04-08] 5 pending P0/P1 items: native readiness, migration triage, FX ops, web parity, release evidence
- [Source: app-store-screenshots.plan.md, 2026-04-08] 7 unchecked success criteria, 4 NOT STARTED dependencies
- [Source: fx-canonical-gateway.plan.md, 2026-04-08] 1 in_progress item (canonical-primary docs)
- [Source: resplit-ios git log, 2026-04-08] Active development — recent commits on custom tip indicator and summary popover
- [Source: fleet audit, 2026-04-08] Previous automation fleet was 100% REDUCE-exiting because this plan had 0 pending tasks

## Constraints
- ALWAYS: Repo-local .cursor/plans choose the active slice; this plan tracks the backlog and mission accounting
- ALWAYS: Separate current slice status, release/upload status, and overall mission completion
- ALWAYS: Bug fixes require investigation before code (Doctrine 7) — bundle 2+ bugs on same surface
- NEVER: Skip screenshot proof for UI bug fixes ($xcodebuild + $picasso required)
- NEVER: Do release upload work in the ASC lane — hand off to resplit-launch-loop

## Decision Log
- [DIRECTION] [2026-04-08] This plan replaces the old mission-accounting-only store. It now contains real pending tasks imported from Cursor plans so vidux automations can find work. Cursor plans remain the detailed authority; this plan is the vidux-parseable queue.
- [DIRECTION] [2026-04-08] resplit-currency automation paused — only 1 doc task left (canonical-primary), folded into task 7 below.
- [DIRECTION] [2026-04-06] Canonical release path is local fastlane: testflight_upload for F&F. ASC_KEY_ID=32D626LB6H.
- [DIRECTION] [2026-04-06] Repo default branch is origin/master (not main).

## Tasks

### ASC Bug Fixes (resplit-asc lane)
- [pending] **1. Triage and fix 6 new ASC bugs** — ANPcvAj_ ("Who is you owe?" text), AJDdbC_e (custom keypad open), AFV83_09 (keypad sizing), AK6h1AIE (receipt image loading), AJkFJKVk (unknown surface UX), AM8FNewE (older new item). [Evidence: app-store-feedback.plan.md ## Open, status=new] [P]
- [pending] **2. Fix 4 triaged ASC bugs** — Items with status=triaged in app-store-feedback.plan.md. Read the plan for current IDs. [Evidence: app-store-feedback.plan.md ## Open, status=triaged] [P]
- [pending] **3. Trunk-verify 56 fixed ASC bugs** — Items with status=fixed need trunk verification and screenshot proof. Batch in groups of 5-10 by surface. [Evidence: app-store-feedback.plan.md ## Open, status=fixed] [P]
- [pending] **4. Unblock 5 blocked ASC bugs** — Investigate blockers, research unblock paths, fix or escalate. [Evidence: app-store-feedback.plan.md ## Open, status=blocked]

### Release Readiness (resplit-launch-loop lane)
- [pending] **5. Cut TestFlight build from clean trunk** — Rebase on fresh origin/master, archive, upload via fastlane testflight_upload, distribute to F&F. [Evidence: remaining-work.plan.md p0-native-readiness, local-fastlane-release-contract.md]
- [pending] **6. Generate screenshot matrix and metadata** — 6 polished screenshots per locale, 54 total (9 locales x 1 device), upload to ASC. [Evidence: app-store-screenshots.plan.md success criteria]

### Operational (cross-lane)
- [pending] **7. Close FX canonical-primary docs** — Update resplit-currency-api README/RUNBOOK with canonical /api/fx contract. Last item from fx-canonical-gateway Phase 2. [Evidence: fx-canonical-gateway.plan.md canonical-primary in_progress]
- [pending] **8. Migration branch triage** — Re-cut migration-safety-hardening into cherry-picks for clean trunk. [Evidence: remaining-work.plan.md p0-migration-branch-triage]
- [pending] **9. Web marketing parity review** — Final marketing/claim visual parity between iOS and web. [Evidence: remaining-work.plan.md p1-web-marketing-parity]

## Progress
- [2026-04-08] Plan rewritten with real pending work imported from 4 Cursor plan files. Previous plan was mission-accounting-only with 0 actionable tasks, causing all automations to REDUCE-exit for 24+ hours. Now: 9 pending tasks across 3 lanes. [Evidence: fleet watchdog 2026-04-08]
