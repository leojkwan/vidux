# 2026-04-07 Resplit Web Memory Contract

## Goal
Record the active `resplit-web` harness drift where memory is part of the authority chain but the prompt never tells the loop how to write back or compact that memory, allowing duplicate retained notes to accumulate.

## Sources
- [Source: `/Users/leokwan/Development/ai/automations/resplit-web/automation.toml`, read 2026-04-07] The active harness reads `/Users/leokwan/.codex/automations/resplit-web/memory.md` as authority item `5`, but it does not include a checkpoint rule for updating that file or retaining only a rolling recent window.
- [Source: `/Users/leokwan/Development/ai/automations/resplit-web/memory.md`, read 2026-04-07] The live memory file currently contains `5` notes, with the `06:27 EDT` footer note and the `06:48 EDT` hero-handoff note each duplicated once.
- [Source: `~/.codex/sqlite/codex-dev.db` table `automations`, queried 2026-04-07] The live scheduler row for `resplit-web` still matches repo truth on shared fields, so this is a harness-and-memory hygiene fix rather than a repo-vs-DB mismatch.
- [Source: `~/.codex/sqlite/codex-dev.db` table `automation_runs`, queried 2026-04-07] Recent `resplit-web` runs are active and shipping real UI slices (`Marketing hero proof shipped`, `Reviews section polished`, `Mobile header and pricing polished`), so the memory drift is happening on a healthy live lane rather than a paused relic.

## Findings

### 1. The harness names memory as authority but not as checkpoint state
`resplit-web` treats its memory file as part of the read order, but unlike the other recently-normalized active loops it never says where to write the file back, how to resolve `$CODEX_HOME` vs `~/.codex`, or how many notes to retain when the run ends.

### 2. The live memory file already drifted beyond its own stated window
The memory file has `5` retained entries even though the authority line says `last 3 notes only`, and two of those entries are exact duplicates of already-retained proof notes. That is prompt-state bloat, not new queue truth.

### 3. This is a safe active-lane repair
The row is repo-backed and currently active, but the repair only needs a prompt contract normalization plus a memory compaction. No cadence, mission ownership, or status change is required.

## Recommendations
- Normalize the `resplit-web` harness to read memory through the standard `$CODEX_HOME` or `~/.codex` fallback contract.
- Add an explicit checkpoint rule telling the loop to update the live `resplit-web` memory file and keep only the last `3` unique notes.
- Trim the current live memory file to the real rolling window and sync the updated prompt into SQLite.
