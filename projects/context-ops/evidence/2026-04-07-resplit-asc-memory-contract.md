# 2026-04-07 Resplit ASC Memory Contract

## Goal
Record the active `resplit-asc` harness drift where memory is part of the authority chain but the prompt still hardcodes one machine-local path and never states how the loop should write memory back or retain only the rolling recent window.

## Sources
- [Source: `/Users/leokwan/Development/ai/automations/resplit-asc/automation.toml`, read 2026-04-07] The active harness still reads `~/.codex/automations/resplit-asc/memory.md` directly as authority item `5`, with no `$CODEX_HOME` fallback, no repo fallback, and no checkpoint rule for updating the file before stop.
- [Source: `/Users/leokwan/Development/ai/automations/resplit-asc/memory.md`, read 2026-04-07] The live memory file currently contains `1` note, so the defect is not retained-note bloat today; it is prompt-contract drift that would break or silently stale on a different automation root.
- [Source: `~/.codex/sqlite/codex-dev.db` table `automations`, queried 2026-04-07] The live scheduler row for `resplit-asc` still matches repo truth on shared fields before this change, so this is a safe harness normalization rather than a repo-vs-DB mismatch.
- [Source: `~/.codex/sqlite/codex-dev.db` table `automation_runs`, queried 2026-04-07] Recent `resplit-asc` runs are active and shipping real ASC slices (`Workbench fallback copy fixed`, `OCR polling ASC fix verified`, `Folder ASC proof ready`), so the harness drift is happening on a healthy live lane rather than a paused historical loop.

## Findings

### 1. The authority chain still assumes one specific local automation root
`resplit-asc` is the remaining active Resplit shipper that still points straight at `~/.codex/automations/...` instead of using the standard `$CODEX_HOME` then `~/.codex` runtime fallback used by the normalized shared lanes.

### 2. The harness reads memory but never tells the lane how to checkpoint it
Unlike `resplit-web`, `resplit-currency`, and `resplit-android`, the ASC harness never says where to write its memory file back, how many notes to retain, or what proof details must survive in that checkpoint.

### 3. This is a safe active-lane repair
The current live memory file is already within the desired rolling window, so the repair only needs a prompt-contract update plus a matching SQLite row sync. No cadence, status, or mission-ownership change is required.

## Recommendations
- Normalize the `resplit-asc` authority chain to read memory through `$CODEX_HOME/automations/...`, then `~/.codex/automations/...`, with repo fallback only if neither runtime path exists.
- Add an explicit checkpoint rule telling the loop to update the live `resplit-asc` memory file and keep only the last `3` concise timestamped notes.
- Sync the updated prompt into SQLite without changing cadence, status, or the current live memory content.
