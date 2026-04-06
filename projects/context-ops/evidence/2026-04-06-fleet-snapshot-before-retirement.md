# 2026-04-06 Fleet Snapshot Before Retirement

## Goal
Capture the full state of all 13 active Codex automations before retiring repo-backed TOML source control. This is the seed for rebuilding automations fresh via interactive `/vidux` sessions.

## Sources
- [Source: SQLite query] `SELECT id, status, prompt FROM automations WHERE status='ACTIVE'`
- [Source: repo files] `ai/automations/*/automation.toml` and `ai/automations/*/memory.md`
- [Source: repo files] `~/.codex/automations/*/memory.md`

## Fleet Topology

### By Project

| Project | Writer | Radars | Other | PLAN.md Location |
|---------|--------|--------|-------|------------------|
| Resplit iOS | resplit-nurse | resplit-vidux | resplit-launch-loop (release) | vidux/projects/resplit/PLAN.md |
| Resplit Android | resplit-android | — | — | vidux/projects/resplit-android/PLAN.md |
| StrongYes | strongyes-release-train | flow, content, ux, revenue | — | strongyes-web/vidux/ux-overhaul/PLAN.md |
| FCP Workflow | hourly-media-studio | — | — | fcp-workflow/vidux/media-studio/PLAN.md |
| Vidux Meta | vidux-v230-planner | — | vidux-endurance, codex-automation-orchestrator | vidux/projects/vidux-v230/PLAN.md |

### Cadence (all gpt-5.4, xhigh reasoning)

| Minute offset | Automation |
|---------------|------------|
| :00,:20,:40 | resplit-launch-loop |
| :01,:21,:41 | strongyes-ux-radar |
| :02,:22,:42 | strongyes-release-train |
| :04,:24,:44 | codex-automation-orchestrator |
| :05,:25,:45 | hourly-media-studio |
| :07,:27,:47 | strongyes-flow-radar |
| :09,:29,:49 | strongyes-content |
| :11,:31,:51 | strongyes-revenue-radar |
| :12,:32,:52 | resplit-android |

vidux-endurance and vidux-v230-planner: active but zero runs (scheduler drift, unresolved).

### Paused (11 DB-only rows)
dji-regrade-loop, resplit-hourly-mayor, resplit-ios-ux-lab, resplit-oversight, resplit-super-nurse-hourly, resplit-super-team-hourly, strongyes-vidux, vidux-endurance-test, vidux-hourly-doctor-2, vidux-stress-lab, vidux-v2-rebuild

## Proven Patterns (What Worked)

### 1. Writer + Radar Fleet
One writer automation ships code. N radars are read-mostly, feeding evidence to the writer. Radars never open competing code branches. This prevents collision and duplicate work.
- Resplit: nurse (writer) + vidux (radar) + launch-loop (release specialist)
- StrongYes: release-train (writer) + 4 radars (flow, content, ux, revenue)

### 2. Authority Chain
Every automation reads a plan store first. Supporting evidence second. Memory third. This prevents drift from accumulating in memory files.

### 3. Anti-Thrash Rules
- 3-strike blocker: if same blocker in last 3 notes, change approach or escalate
- Fresh fact requirement: every blocker checkpoint must carry one new fact
- 10-minute minimum: runs under 10 min only valid if they land proof or record a fresh blocker
- Ledger compaction: compact `live` rows before reasoning

### 4. Mission Honesty
Separate three things in every checkpoint: current slice status, release/upload status, overall mission completion. Don't conflate "this slice is done" with "the product is done."

### 5. Worktree Protocol
Writer loops create fresh disposable worktrees for code. Durable truth stays on the stable branch. Worktrees are temporary isolation only.

### 6. Queue-Pressure Bias
Don't idle when the plan has executable tasks. Writer loops must scan for `[pending]` and `[in_progress]` before declaring cold.

### 7. Radar Escalation
If the same writer-ready move repeats across 2+ radar notes and isn't in the plan, the radar adds it to the plan store. Cues don't live only in memory.

## Per-Automation Essence

### resplit-nurse
**Role:** Only code-shipping Resplit automation. Ships iOS product slices.
**Key DNA:** RALPH.md is primary authority (repo queue). External vidux plan supports but doesn't override. Specialist routing table for iOS/web/design. Four latency buckets: hygiene, discovery, implementation, proof/wait.
**Execution:** worktree mode. Reads repo-local plans first, vidux store second.

### resplit-vidux
**Role:** UX radar for Resplit. Maps surfaces, discovers forgotten work, hardens shared store.
**Key DNA:** Read-mostly. Never ships code unless no active shipper lane exists. Maps: home, receipt detail, live split, merge flows, trip summary, camera, onboarding, web shell, marketing site.

### resplit-launch-loop
**Role:** Release-proof lane. TestFlight boundary, merge-back, upload.
**Key DNA:** Queue-pressure bias is aggressive. Release-train skill from resplit-ios repo. Anti-thrash: compacts ledger `live` rows. Worktree execution.

### resplit-android
**Role:** Build Android parity with iOS. Research + implementation.
**Key DNA:** Completely offline, one-time purchase, Room-only. Material 3 + Compose, not a port. Code in /tmp, plans in vidux store. Nia-first research for Android ecosystem.

### strongyes-release-train
**Role:** Only code-shipping StrongYes automation. Web product execution.
**Key DNA:** Revenue first. READ discipline: must name current release recommendation, mission status, all tasks, remaining gaps, newest radar cue before acting. Worktree execution.

### strongyes-flow-radar
**Role:** Buyer path honesty on strongyes.io.
**Key DNA:** Playwright proof. Owned surfaces: /, /about, /prep, /pricing, /auth/login, signup/checkout.

### strongyes-content
**Role:** Company intelligence, public digest, /learn voice system.
**Key DNA:** Nia-first research. Source breadcrumbs explicit, uncertainty honest, disclosure modes precise.

### strongyes-revenue-radar
**Role:** Stripe, Supabase, auth, checkout, webhook, route-handler risk.
**Key DNA:** Concrete contract evidence: code paths, env contracts, route responses, logs, analytics, schema shape.

### strongyes-ux-radar
**Role:** Whole-site hierarchy, trust, composition, mobile/desktop parity.
**Key DNA:** Screenshots and browser proof over abstract design critique. Homepage trust harness.

### hourly-media-studio
**Role:** FCP workflow. Media ETL, timeline assembly, story packets.
**Key DNA:** Safety over speed for media integrity. SSD4 only (no backup drive). Leo makes the final cut. Static holds are acceptable. Nested plans: UAE reel, DJI cleanup. Coordination with dji-regrade-loop toggle.

### codex-automation-orchestrator
**Role:** Fleet health. Repo ↔ DB sync. Self-audit. Vidux OSS meta lane.
**Key DNA:** One bounded improvement per run. Includes itself in audit. Context Ops plan store. NOW RETIRED — Leo + Claude are the orchestrator.

### vidux-endurance
**Role:** Validate vidux under sustained operation via fake projects.
**Key DNA:** Failure discovery is the point. Fake projects in /tmp. Grade all 9 doctrines. Process fixes > fake-project polish.

### vidux-v230-planner
**Role:** Improve vidux using vidux.
**Key DNA:** Cross-machine evidence (laptop + desktop). New verification required (don't just re-run old tests). Before/after doctrine grades.

## What Was Broken

1. **Repo ↔ DB sync** was the #1 time sink. Constant drift, constant churn. Orchestrator spent most cycles on it.
2. **Prompt bloat** — resplit-nurse (~350 lines), resplit-vidux (~400 lines) are massive. Most automations restate vidux doctrine.
3. **vidux-endurance and vidux-v230-planner** are ACTIVE but have zero automation_runs — scheduler drift, never investigated.
4. **11 paused legacy rows** in DB with no repo backing. Dead weight.
5. **Memory files scattered** between repo (`ai/automations/*/memory.md`) and Codex home (`~/.codex/automations/*/memory.md`).

## Recommendations
- Orchestrator automation is retired. Leo + Claude own fleet changes interactively.
- When recreating automations, use Doctrine 8 lean harnesses (end goal + authority + boundary + guardrails only).
- Bloated prompts (nurse, vidux-radar) should be halved — the vidux skill already carries the doctrine.
- Clean up 11 paused DB rows.
- Investigate scheduler drift on endurance/v230 lanes.
