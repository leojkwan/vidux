# 2026-04-07 — D3 Watch Harness Enforcement

## Goal
Choose the smallest enforceable D3 intervention after the runtime metric became honest, implement it inside Vidux itself, and verify it against fresh fixtures plus the live automation fleet instead of re-grading old scorecards.

## Sources
- [Source: D3 ledger integrity recheck, 2026-04-07] `/Users/leokwan/Development/vidux/projects/vidux-v230/evidence/2026-04-07-d3-ledger-integrity-and-recheck.md`
- [Source: watch/burst contract verification, 2026-04-07] `/Users/leokwan/Development/vidux/projects/vidux-v230/evidence/2026-04-07-watch-burst-contract-verification.md`
- [Source: burst vs watch insight, 2026-04-06] `/Users/leokwan/Development/vidux/projects/vidux-v230/evidence/2026-04-06-burst-vs-watch-mode-insight.md`
- [Source: live ledger, queried 2026-04-07] `~/.agent-ledger/activity.jsonl`
- [Source: live automation prompts, read 2026-04-07] `/Users/leokwan/.codex/automations/vidux-v230-planner/automation.toml`, `/Users/leokwan/.codex/automations/vidux-endurance/automation.toml`
- [Source: `scripts/vidux-doctor.sh`, updated 2026-04-07] watch-harness scope audit + automation-dir discovery
- [Source: contract suite, 2026-04-07] `python3 -m unittest tests/test_vidux_contracts.py`

## Findings

### 1. The remaining D3 problem is not the watch contract in code; it is prompt debt in the scheduled harness
`vidux-loop.sh` already exposes `mode=watch` and `next_action`, but the active cron prompts still tell the scheduled run to do burst work directly:

- `vidux-v230-planner` prompt still asks the cron run to "implement", "build new verification", "write new contract tests", and "create new fake projects"
- `vidux-endurance` prompt still asks the cron run to "work the highest-value unblocked slice to a real boundary" and "run the vidux contract suite"

That matches the honest runtime evidence from Task 4.2: the watch lane is structurally available, but the live harness still scopes the cron run as a mini-burst.

### 2. The smallest safe repo-side fix is a machine-auditable doctor check, not another prose note
Changing live automation prompts or schedules would alter operational state outside the repo and needs a deliberate follow-up lane. The enforceable move Vidux can ship immediately is:

- make `vidux-doctor.sh` discover the real automation directory (`repo/automations` first, then `~/.codex/automations`, or an explicit `--automations-dir`)
- add a `watch_harness_scope` check that flags active cron prompts with deep-work markers but no explicit watch contract markers

This turns D3 prompt debt into a first-class runtime warning instead of a scorecard-only observation.

### 3. Fresh live verification proves the audit catches the real debt now
Live doctor run against `/Users/leokwan/.codex/automations` produced:

- `watch_harness_scope: warn`
- `count: 7`
- both target automations flagged:
  - `vidux-v230-planner` -> `missing_watch_contract`
  - `vidux-endurance` -> `missing_watch_contract`

The same live run also exposed broader fleet debt (`resplit-*`, `codex-automation-orchestrator`), which is useful: D3 prompt drift is not limited to one Vidux lane.

## Fresh Verification

### New contract tests
- Added `test_doctor_watch_harness_scope_warns_on_bursty_cron_prompt`
- Added `test_doctor_watch_harness_scope_allows_explicit_watch_prompt`
- Result: both pass

### Full contract suite
- `python3 -m unittest tests/test_vidux_contracts.py`
- Result: **96/96 pass**
- Delta vs Task 4.2: **94/94 -> 96/96**

### Fresh `/tmp` fixture
- Built a temp repo under `/tmp/vidux-watch-scope-main-*`
- One bad cron prompt asked to implement + write tests + build verification in the scheduled run
- One good cron prompt declared watch mode, brief runtime, and `next_action=burst`
- Result: doctor warned on `watch-bad` only and ignored `watch-good`

### Live-pressure check
- `bash scripts/vidux-doctor.sh --json --repo /Users/leokwan/Development/vidux --automations-dir /Users/leokwan/.codex/automations`
- Result: `watch_harness_scope` now surfaces real active prompt debt immediately

## Baseline Delta

### What improved measurably
- D3 harness debt is now machine-auditable in repo tooling instead of being scorecard prose only
- contract coverage increased from `94` to `96`
- the doctor can inspect the real Codex automation directory instead of only repo-local automations

### What did not improve yet
- runtime bimodality itself
- `vidux-v230-planner` and `vidux-endurance` are still mid-heavy until their live prompts/schedules are rewritten to obey watch mode

## Decision
Task 4.7 should close as: **the smallest enforceable D3 change is a watch-harness doctor audit plus real automation discovery**.

The next deliberate move is a follow-up lane to rewrite the active cron harness prompts into explicit watch mode, then re-measure the ledger after enough fresh cycles accumulate.
