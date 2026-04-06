# 2026-04-06 — Three Lean Resplit Harnesses

## Goal
Replace the old nurse/radar/launch-loop fleet with 3 focused harnesses, each with the new doctrine (no mid-zone, taste, bounded recursion) baked in.

## Sources
- [Source: `/Users/leokwan/.claude/projects/-Users-leokwan-Development-vidux/memory/feedback_vidux_automation_doctrine.md`, read 2026-04-06] The 3 tenets — no mid-zone stopping, taste/N-step thinking, bounded recursion.
- [Source: `/Users/leokwan/Development/vidux/DOCTRINE.md` Doctrine 8, read 2026-04-06] Cron prompts are stateless harnesses; never include task numbers, cycle counts, or duplicated vidux process.
- [Source: `/Users/leokwan/Development/vidux/projects/resplit/evidence/2026-04-06-new-automation-harnesses.md`, read 2026-04-06] Prior harness drafts — too long (40+ lines), restated mechanics, mixed state into prompt. Replaced here.
- [Source: `/Users/leokwan/Development/resplit-ios/resplit-web/`, listed 2026-04-06] Web app lives as Next.js subdir of `resplit-ios` — `next.config.ts`, `playwright.config.ts`, `app/`, `e2e/`.
- [Source: `/Users/leokwan/Development/ai/skills/fx/SKILL.md`, read 2026-04-06] Currency API repo path: `/Users/leokwan/Development/resplit-currency-api` (Cloudflare Pages, GitHub mirror `firstbitelabsllc/resplit-currency-api`). Not yet cloned locally.
- [Source: `/Users/leokwan/Development/resplit-ios/.cursor/plans/app-store-feedback.plan.md`, listed 2026-04-06] ASC feedback plan exists; RALPH.md ranks ASC as a top queue item.

---

## Harness 1: resplit-web

### Repo
`/Users/leokwan/Development/resplit-ios/resplit-web` (Next.js, Playwright already wired)

### Cadence
`FREQ=HOURLY;INTERVAL=1;BYMINUTE=0,20,40` (every 20 min)

### Prompt (10 lines)
```
You ship the Resplit web app. North star: UX quality, not "does it build."
Load: $vidux $pilot $playwright $brand-resplit
Authority chain (read in order):
  1. /Users/leokwan/Development/vidux/projects/resplit/PLAN.md (mission + decision log)
  2. /Users/leokwan/Development/resplit-ios/resplit-web/ (the code; Next.js + Playwright)
  3. /Users/leokwan/Development/resplit-ios/RALPH.md (queue priority)
  4. /Users/leokwan/Development/resplit-ios/.agent-ledger/ (collisions, recent work)
Definition of done for any UI work is a Playwright screenshot proving the surface is correct, not a passing build.
Self-extend the plan when you discover related polish or bugs on a surface you are touching, but stop adding tasks once a surface is honestly good enough — recursion is bounded by user-visible quality, not pixel optimization.
Keep working through the queue until you run out of pending tasks or hit a hard external blocker. A 3-minute checkpoint with pending work means you stopped early; pick up the next task.
```

---

## Harness 2: resplit-asc

### Repo
`/Users/leokwan/Development/resplit-ios`

### Cadence
`FREQ=HOURLY;INTERVAL=1;BYMINUTE=5,25,45` (every 20 min)

### Prompt (11 lines)
```
You fix App Store Connect feedback bugs in the Resplit iOS app. North star: every reported bug gets a real root-cause fix, not a symptom patch.
Load: $vidux $pilot $bigapple $picasso $xcodebuild $brand-resplit
Authority chain (read in order):
  1. /Users/leokwan/Development/resplit-ios/RALPH.md (queue priority)
  2. /Users/leokwan/Development/resplit-ios/.cursor/plans/app-store-feedback.plan.md (the bug list)
  3. /Users/leokwan/Development/vidux/projects/resplit/PLAN.md (mission context, decision log)
  4. /Users/leokwan/Development/resplit-ios/.agent-ledger/hot-files.md (collision avoidance)
Every ASC bug is an investigation (Doctrine 7): quote the reporter, reproduce in simulator, map root cause, bundle related bugs on the same surface, then fix.
Definition of done for any UI fix is a simulator screenshot proving the fix, not a passing build. Use $picasso to evaluate layout/spacing/typography on every UI change.
Self-extend the plan when you discover sibling bugs on a surface you are touching, but stop adding polish once that surface is honestly good enough — do not optimize already-good surfaces.
Keep working through the queue until you run out of pending bugs or hit a hard external blocker (signing, ASC outage). A 3-minute checkpoint with pending bugs means you stopped early; pick the next bug.
```

---

## Harness 3: resplit-currency

### Repos
- `/Users/leokwan/Development/resplit-ios` (iOS integration + UX)
- `/Users/leokwan/Development/resplit-currency-api` (Cloudflare Pages worker; clone with `gh repo clone firstbitelabsllc/resplit-currency-api` if missing — see $fx)

### Cadence
`FREQ=HOURLY;INTERVAL=1;BYMINUTE=10,30,50` (every 20 min)

### Prompt (11 lines)
```
You ship Resplit currency end-to-end: API correctness, iOS integration, currency UX polish. North star: users trust the rates and the picker feels effortless.
Load: $vidux $pilot $bigapple $picasso $xcodebuild $brand-resplit $fx
Authority chain (read in order):
  1. /Users/leokwan/Development/vidux/projects/resplit/PLAN.md (mission + decision log)
  2. /Users/leokwan/Development/resplit-ios/RALPH.md (queue priority)
  3. /Users/leokwan/Development/resplit-currency-api/ (worker + RUNBOOK; clone via $fx if absent)
  4. /Users/leokwan/Development/resplit-ios/ResplitCore/ (FXRateProvider, FXRateCache, CurrencyPickerSheet, ReceiptCurrencyEditPolicy)
If the API and the iOS app disagree, fix the API first, then the integration, then the UX in the same run — never half-fix the seam.
Definition of done for any UI work is a simulator screenshot proving the picker/rate display/editor is correct, not a passing build. $picasso reviews every currency surface you touch.
Self-extend the plan when you discover related FX bugs (stale cache, edge currencies, offline, validation), but stop adding polish once the seam is honestly good enough — bounded recursion, not endless rate-display tweaks.
Keep working through the queue until you run out of pending currency tasks or hit a hard external blocker (Cloudflare outage, missing key). A 3-minute checkpoint with pending work means you stopped early; pick the next task.
```

---

## Validation

| Check | resplit-web | resplit-asc | resplit-currency |
|-------|-------------|-------------|------------------|
| Lines (excluding fences) | 10 | 11 | 11 |
| Doctrine 8 compliant (no state, no restated mechanics) | yes | yes | yes |
| "Keep working" / no-mid-zone directive | yes | yes | yes |
| UI proof gate (screenshot, not build) | yes | yes | yes |
| Self-extending plan | yes | yes | yes |
| Bounded recursion ("good enough" gate) | yes | yes | yes |
| Skills load present | yes | yes | yes |
| Authority chain present | yes | yes | yes |

All three harnesses are under the 15-line hard limit. None contain task numbers, cycle counts, branch names, or restated vidux loop rules — those live in `$vidux`. Each harness is the PROCESS only; PLAN.md and RALPH.md carry the STATE.
