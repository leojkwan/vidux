# 2026-04-06 Vidux v230 Memory Contract Audit

## Why this slice
The shared repo-backed fleet is currently clean on prompt, cadence, model, and reasoning fields, so the next bounded defect is an active loop whose durable memory surface is too thin to support reliable recent-state rehydration.

## Facts gathered
- [Source: shared automation tree audit, 2026-04-06] The current control plane still has `27` repo-backed automation definitions on disk and `34` live scheduler rows, with `7` DB-only active rows outside the shared tree.
- [Source: repo-vs-DB comparison, 2026-04-06] The `27` shared IDs had zero mismatches on `status`, `rrule`, `model`, `reasoning_effort`, `cwds`, or `prompt` before this slice.
- [Source: shared `vidux-v230-planner` memory file, read 2026-04-06] The active repo-backed `vidux-v230-planner` loop had a `memory.md` file, but it contained only one plain-text note with no heading or explicit last-3 retention contract.
- [Source: `automation_runs` audit for `vidux-v230-planner`, read 2026-04-06 closeout] Recent run history now exposes the three durable checkpoints that should survive in shared memory at close: `Watch burst contract locked`, `D6 enforcement landed`, and `D3 ledger gauge fixed`.
- [Source: shared `vidux-v230-planner` prompt, read 2026-04-06] The harness told future runs to update `memory.md` with one concise note, but it did not require keeping the file trimmed to the last 3 notes, so the loop had no stable recent-memory contract comparable to the orchestrator and other repaired active lanes.

## Change shipped
1. Tightened the shared `vidux-v230-planner` prompt so future runs must keep `memory.md` to the last 3 notes and leave the next deliberate move explicit.
2. Normalized the shared `vidux-v230-planner/memory.md` file into a headed last-3-note format using the latest durable run history, including the concurrent `D3 ledger gauge fixed` checkpoint that landed during verification.
3. Synced the live scheduler prompt for `vidux-v230-planner` back to the repo-backed text.

## Remaining exposure
- `hourly-media-studio` and `vidux-endurance` still use thinner memory formatting than the newer shared contract, but they already retain multiple recent checkpoints and did not need a prompt sync in this slice.
- The `7` DB-only active rows remain the next higher-risk hidden-state cluster once active shared memory hygiene is no longer drifting.
