# Archived Tasks

Tasks completed and archived from PLAN.md to keep context lean.

## Archived 2026-04-01
- [x] Write SKILL.md with doctrine, loop mechanics, PLAN.md structure, failure protocol

## Archived 2026-04-07
- [x] Write this PLAN.md (meta: Vidux plans itself)
- [x] Write DOCTRINE.md — standalone principles doc (the 60%) for quick reference
- [x] Set up hourly cron to iterate on these docs
- [x] Survey 26 open source skills/plugins for ingredients [Evidence: research agent]
- [x] Write LOOP.md — detailed loop mechanics (the 30%) with examples [Done: 2026-03-31]
- [x] Write INGREDIENTS.md — top 10 open source patterns to adopt with attribution [Done: 2026-03-31]
- [x] Write `vidux-loop.sh` — stateless cycle script (113 lines, JSON output, 7 edge cases) [Done: 2026-04-01]
- [x] Write `vidux-gather.sh` — fan-out research template generator [Done: 2026-04-01]
- [x] Write `vidux-checkpoint.sh` — structured checkpoint writer (81 lines, idempotent) [Done: 2026-04-01]
- [x] Test one full cycle: gather -> plan -> execute -> verify -> checkpoint [Depends: all above] [Done: 2026-04-01]
- [x] Add PreToolUse hook guidance + full ENFORCEMENT.md (389 lines, 4 hooks, three-strike gate) [Done: 2026-04-01]
- [x] Add /harness integration for failure protocol (three-strike gate in ENFORCEMENT.md) [Done: 2026-04-01] [Evidence: Jeffrey's PR #265]
- [x] Add contract tests (10 tests, all passing) [Done: 2026-04-01] [Evidence: Jeffrey's pattern]
- [x] Create .claude-plugin/plugin.json manifest [Done: 2026-04-01]
- [x] Create /vidux command wrapper [Done: 2026-04-01]
- [x] Create /vidux-plan command (plan-only mode) [Done: 2026-04-01]
- [x] Create /vidux-status command (quick status check) [Done: 2026-04-01]
- [x] Wire ledger lifecycle events (AGENT_LANE, mission_id) — DONE on main via pilot-ledger-emit.sh [Done: 2026-04-01]
- [x] Wire project-specific build recipe — DONE on main [Done: 2026-04-01]
- [x] Wire Captain install — no changes needed, auto-installs via symlinks. Added install-hooks.sh for optional enforcement. [Done: 2026-04-01]
- [x] [P2 — deferred] Cross-tool and cross-machine testing moved to future scope. Solo-computer, source-controlled is the v1 contract. [Done: 2026-04-01]
- [x] Expand harness: contract tests for scripts (executable, valid JSON), commands (frontmatter), hooks (valid JSON), ENFORCEMENT.md (4 hooks), INGREDIENTS.md (10 items) [Evidence: Jeffrey's contract-test-as-harness pattern from PR #265] [Done: 2026-04-01]
- [x] Write quickstart guide: guides/vidux/quickstart.md — activation, installation, first /vidux run [Done: 2026-04-01]
- [x] Write architecture guide: guides/vidux/architecture.md — two data structures, unidirectional flow, Layer 1 vs Layer 2, Redux analogy [Done: 2026-04-01]
- [x] Write best practices guide: guides/vidux/best-practices.md — PLAN.md writing, overnight cron, fan-out, common mistakes, Vidux vs Pilot [Done: 2026-04-01]
- [x] End-to-end verification: run expanded harness, verify all scripts, verify symlinks, checkpoint [Depends: all Phase 6 above] [Done: 2026-04-01]
- [x] Export the portable Vidux core into its own public repo with docs, commands, scripts, hooks, and tests. [Done: 2026-04-06]
- [x] Add README, LICENSE, CONTRIBUTING, .github templates. [Done: 2026-04-06]
- [x] Rewire all paths from `skills/vidux/` to repo-root. [Done: 2026-04-06]
- [x] Restore full build history PLAN.md to public repo. [Done: 2026-04-06]
- [x] Bring over vidux-development project evidence (v230, endurance, stress-test). [Done: 2026-04-06]
- [x] Bring over ARCHIVE.md and SETUP_NEW_MACHINE.md. [Done: 2026-04-06]
- [x] Build /vidux-loop command — fleet creation, lean prompts, staggered schedules, coordinator pattern, bimodal quality enforcement. [Done: 2026-04-06]
- [x] Fix "smallest slice" language in /vidux command — agents keep working through queue until real boundary. [Done: 2026-04-06]
- [x] Absorb Ralph into vidux core — Ralph had no hooks, no commands, just a SKILL.md. Queue contract is PLAN.md task FSM. Removed all references. [Done: 2026-04-06]
- [completed] Integrate ledger into this repo — built thin integration layer (scripts/lib/ledger-config.sh, ledger-emit.sh, ledger-query.sh) that discovers ~/.agent-ledger/ and provides fleet analysis functions. Wired into vidux-loop.sh (loop_start, conflict check, ledger_available in JSON output) and vidux-checkpoint.sh (checkpoint events). Updated vidux-manager.md to use ledger-query.sh. 83/83 tests pass. [Done: 2026-04-06] [Evidence: real ledger data: 3205 entries, 14 automations, bimodal scores computed]
- [completed] Retire `ai/skills/vidux/` — all 9 automation.toml files updated to canonical path. Ralph + vidux-amp dead refs removed. ai/skills/vidux symlink removed. [Done: 2026-04-06] [Evidence: `projects/vidux-self-investigation/evidence/2026-04-06-stale-path-audit.md`]
- [completed] Add bimodal runtime enforcement to vidux-doctor.sh — CHECK 11: flags projects where >30% of runs fall in 3-8 min dead zone. Uses git commit timestamps. [Done: 2026-04-06]
- [completed] Build automation quality inspector — vidux-fleet-quality.sh reads memory.md files, classifies runs (quick/deep/mid/normal), reports per-automation and fleet-wide bimodal quality. [Done: 2026-04-06]

## Archived 2026-04-07 (Cycle 38) — Phases 8-12

### Phase 8: Canonical Unification
### Phase 9: Automation Quality — fleet configs, e2e tests (NextJS 17/20, iOS 19/20)
### Phase 10: Visibility, Intelligence & Health — 7 tasks (10.1-10.7): stage indicators, config extensions, ledger integration, dashboard, prune, manager, 30 contract tests
### Phase 11: Dispatch/Reduce + Fleet Hardening — 9 tasks (11.1-11.9): doctrine bake, dispatch.sh, reduce mode, exit-criteria, Codex DB resilience, stale ref prune, queue-jsonl, lifecycle hooks. 11.5 blocked (Vercel MCP).
### Phase 12: Continuous Feedback Loop — 6 tasks (12.1-12.6): merge-gate, auto-pause, bimodal enforcement, witness.sh, self-extension metric, 11 contract tests (149 total)
