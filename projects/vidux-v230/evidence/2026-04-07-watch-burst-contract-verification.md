# 2026-04-07 — Watch/Burst Contract Verification

## Goal
Turn the D3 watch-vs-burst insight into an enforceable artifact, not a prose-only recommendation, and verify the contract with fresh runs instead of re-grading yesterday's work.

## Sources
- [Source: burst vs watch insight, 2026-04-06] `/Users/leokwan/Development/vidux/projects/vidux-v230/evidence/2026-04-06-burst-vs-watch-mode-insight.md`
- [Source: v2.3.1 final scorecard, 2026-04-06] `/Users/leokwan/Development/vidux/projects/vidux-v230/evidence/2026-04-06-v231-final-scorecard.md`
- [Source: other-machine batch scorecard, 2026-04-05] `/Users/leokwan/Desktop/vidux-endurance/evidence/2026-04-05-batch-1-scorecard-and-vnext.md`
- [Source: this-computer baseline scorecard, 2026-04-05] `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-05-final-endurance-scorecard.md`
- [Source: `scripts/vidux-loop.sh`, read 2026-04-07] Watch assessor output lacked explicit `mode` / `next_action` fields.
- [Source: `scripts/vidux-burst.sh`, read 2026-04-07] Burst assessor existed already but had no contract tests.
- [Source: `scripts/lib/ledger-query.sh`, queried 2026-04-07] `ledger_bimodal_distribution vidux 168`

## Findings

### 1. The structural split existed in code, but not in the enforceable contract
`vidux-burst.sh` was already present in the repo, so the April 6 insight was not purely theoretical anymore. The missing part was enforcement:

- `vidux-loop.sh` did not label itself as watch mode
- `vidux-loop.sh` did not expose a machine-readable burst handoff field
- `vidux-burst.sh` had zero contract coverage

That left D3 dependent on human interpretation of raw JSON instead of a stable surface the tests could lock.

### 2. Fresh verification exposed a real burst-mode bug
The first fresh dry-run against a temp plan produced invalid JSON:

- `"in_progress": 0`
- followed by an extra `0,`

Root cause: `grep -c ... || echo 0` in `vidux-burst.sh` double-emitted zero on no-match paths. The script existed, but its zero-count path was not safe until this run.

### 3. The minimal enforceable v2.4 shape is now concrete
Implemented and verified:

- `vidux-loop.sh` now emits `mode: "watch"`
- `vidux-loop.sh` now emits `next_action: "burst" | "none"`
- `vidux-burst.sh` zero-count paths now produce valid JSON
- contract suite now covers both watch routing and burst outputs

This is the smallest backward-compatible contract that makes the watch/burst split visible and testable without changing existing legacy fields.

## Fresh Verification

### Contract suite
- `python3 -m unittest tests/test_vidux_contracts.py`
- Result: **89/89 pass**
- Delta vs 2026-04-06 scorecard: **84/84 -> 89/89**

New coverage added in this run:
- watch mode exposes `mode=watch`
- watch mode routes runnable work to `next_action=burst`
- watch mode routes empty queues to `next_action=none`
- burst dry-run emits valid JSON contract
- burst assessment emits protocol fields

### Temp `/tmp` stress bundle
Fresh temp plans created under `/tmp/vidux-watch-burst-WCg4Ac`:

1. Pending temp plan:
   - watch output: `action=execute`, `next_action=burst`
   - burst dry-run output: `recommendation=fire_burst`
   - burst output: valid JSON with `action=execute_burst`
2. Done temp plan:
   - watch output: `action=complete`, `next_action=none`

### Live-pressure verification
1. Real `projects/vidux-v230/PLAN.md`
   - watch output: `mode=watch`, `action=execute`, `next_action=burst`
2. Real `projects/resplit/PLAN.md`
   - burst dry-run output: `recommendation=nothing_pending`

## Ledger Baseline
Current 168-hour ledger query for repo `vidux`:

- total runs: `289`
- quick: `275`
- deep: `4`
- mid: `1`
- normal: `9`
- bimodal score: `96`

Relevant current automation rows:
- `vidux-endurance`: `24 quick`, `2 deep`, `1 mid`, `2 normal`
- `vidux-v230-planner`: `13 quick`, `2 deep`, `0 mid`, `4 normal`

This run does **not** claim a post-fix runtime-distribution improvement yet. It establishes the contract and the baseline needed to judge later runs honestly.

## Before / After

### Before this run
- D3 structural split was documented but only partially enforced
- watch mode had no explicit machine-readable identity
- burst mode had no contract tests
- burst zero-count dry-runs could emit invalid JSON

### After this run
- watch/burst split is machine-readable
- the burst handoff is explicit and test-locked
- burst zero-count JSON is fixed
- the contract suite now fails loudly if the split regresses

## Verdict
This run makes D3 **more enforceable** than the 2026-04-05 and 2026-04-06 baselines, but not fully re-scored yet.

What improved measurably now:
- contract coverage: `84 -> 89`
- one real burst-mode bug fixed
- watch/burst routing is no longer prose-only

What still needs a later run:
- post-change ledger comparison after enough new automation cycles accumulate
- specifically: compare mid-zone share against today's `1 / 289` baseline for repo `vidux`
