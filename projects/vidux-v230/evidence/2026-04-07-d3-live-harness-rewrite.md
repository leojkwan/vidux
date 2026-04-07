# 2026-04-07 — D3 Live Harness Rewrite

## Goal
Rewrite the active `vidux-v230-planner` and `vidux-endurance` cron harnesses into explicit watch mode, verify that the live prompts no longer trip Vidux's `watch_harness_scope` audit, and record the honest blocker for the runtime re-measurement.

## Sources
- [Source: D3 watch harness enforcement, 2026-04-07] `/Users/leokwan/Development/vidux/projects/vidux-v230/evidence/2026-04-07-d3-watch-harness-enforcement.md`
- [Source: D3 ledger integrity recheck, 2026-04-07] `/Users/leokwan/Development/vidux/projects/vidux-v230/evidence/2026-04-07-d3-ledger-integrity-and-recheck.md`
- [Source: live automation prompt, read 2026-04-07] `/Users/leokwan/.codex/automations/vidux-v230-planner/automation.toml`
- [Source: live automation prompt, read 2026-04-07] `/Users/leokwan/.codex/automations/vidux-endurance/automation.toml`
- [Source: `scripts/vidux-doctor.sh`, read 2026-04-07] watch harness prompt scan markers
- [Source: live ledger, queried 2026-04-07] `~/.agent-ledger/activity.jsonl`

## Findings

### 1. The live fix had to be a true scope rewrite, not additive watch prose
`watch_harness_scope` flags two failure modes:

- `missing_watch_contract` when burst markers appear without watch markers
- `mixed_watch_and_burst_scope` when both appear in the same prompt

Because the deep marker list includes literal phrases such as `implement`, `build new verification`, `write new contract tests`, `create new fake projects`, `work the highest-value unblocked slice to a real boundary`, and `run the vidux contract suite`, the live automation prompts needed those phrases removed entirely. Adding watch text on top would still fail the audit.

### 2. Both live cron harnesses now follow the same watch contract
Fresh prompt rewrite for `vidux-v230-planner`:

- declares `watch mode`
- says `keep this run brief`
- says `stay under 2 minutes`
- requires `next_action=burst` when real work exists
- limits the scheduled run to queue inspection, blocker detection, and checkpoint updates

Fresh prompt rewrite for `vidux-endurance`:

- declares `watch mode`
- says `keep this run brief`
- says `stay under 2 minutes`
- requires `next_action=burst` when real validation work exists
- limits the scheduled run to queue inspection, doctrine-gap triage, and explicit burst handoff

### 3. The live scope debt is fixed for the two Vidux harnesses, but the repo-wide doctor still warns on unrelated automations
After the rewrite, direct prompt scans for the two target TOMLs show all watch markers present and zero matched deep markers. The repo-wide doctor still returns `watch_harness_scope: warn`, but only because other active automations outside this slice (`codex-automation-orchestrator`, `resplit-android`, `resplit-asc`, `resplit-currency`, `resplit-web`) still carry bursty prompts. Neither `vidux-v230-planner` nor `vidux-endurance` appears in that warning list anymore.

The runtime distribution has only started to move because the ledger still mostly reflects the pre-rewrite run mix:

- `vidux-v230-planner`: `8 runs`, `2 quick`, `6 mid`, `0 normal`, `0 deep`
- `vidux-endurance`: `10 runs`, `1 quick`, `6 mid`, `3 normal`, `0 deep`
- repo total: `19 runs`, `3 quick`, `13 mid`, `3 normal`, `0 deep`, `bimodal_score=15`

So Task 4.8 is only partially complete after this run. The prompt surface is fixed; the runtime metric is still waiting on enough new watch-mode invocations.

## Fresh Verification

### Live doctor check
- Command: `bash scripts/vidux-doctor.sh --json --repo /Users/leokwan/Development/vidux --automations-dir /Users/leokwan/.codex/automations`
- Result: repo-wide `watch_harness_scope` still returns `status=warn`, `count=5`, but the warning list no longer contains `vidux-v230-planner` or `vidux-endurance`
- Delta vs 2026-04-07 Task 4.7: the two target automations dropped out of the warning list; only unrelated automations remain

### Direct prompt scan
- Command: local TOML scan of `/Users/leokwan/.codex/automations/vidux-v230-planner/automation.toml` and `/Users/leokwan/.codex/automations/vidux-endurance/automation.toml`
- Result: both prompts match watch markers and match zero deep markers
- Interpretation: the live harness rewrite itself is mechanically clean

### Live ledger read
- Command: `source scripts/lib/ledger-query.sh && ledger_bimodal_distribution vidux 168 | jq .`
- Result: still mid-heavy, but with a small early shift after the first rewritten planner run (`bimodal_score=15`, planner quick count `1 -> 2`)
- Interpretation: prompt scope is fixed, but there are not enough post-rewrite runs yet to judge D3 runtime shape honestly

## Baseline Delta

### What improved measurably
- The two active Vidux cron harnesses no longer violate the machine-level watch prompt audit.
- The exact D3 debt shifted from `prompt still wrong` to `waiting on fresh runtime evidence`.
- The live ledger shows an early quick-run increase for `vidux-v230-planner` (`1/7 -> 2/8`), though that is not enough to close the runtime lane.

### What did not improve yet
- The 168-hour runtime distribution.
- The 2026-04-07 honest D3 baseline still stands until enough new watch-mode runs accumulate.

## Verdict
This run closes the live prompt rewrite half of Task 4.8.

The next deliberate move is to wait for enough new scheduled cycles under the rewritten harnesses, then re-run the live 168-hour ledger comparison and decide whether D3 finally moved off the 3-8 minute dead zone.
