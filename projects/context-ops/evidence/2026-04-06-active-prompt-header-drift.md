# 2026-04-06 Active Prompt Header Drift

## Why this slice
Two active repo-backed automations were still running with visibly truncated harness headers after the Vidux path-normalization work. The loops stayed active in SQLite, but the prompt text that should explicitly invoke `[$vidux]` had collapsed to `Use  ...`, which is self-inflicted control-plane drift.

## Facts gathered
- [Source: `/Users/leokwan/Development/ai/automations/strongyes-release-train/automation.toml`, read 2026-04-06] The prompt now starts `Use  and [$ledger]...` instead of naming the Vidux skill explicitly.
- [Source: `/Users/leokwan/Development/ai/automations/vidux-v230-planner/automation.toml`, read 2026-04-06] The prompt now starts `Use  to continuously improve Vidux itself...` instead of naming the Vidux skill explicitly.
- [Source: `git show a037a1e:automations/strongyes-release-train/automation.toml`, read 2026-04-06] The earlier repo-backed StrongYes writer harness explicitly loaded `[$vidux]`, so the blank header is a regression rather than an intentional simplification.
- [Source: `git show a037a1e:automations/vidux-v230-planner/automation.toml`, read 2026-04-06] The earlier Vidux planner harness also explicitly loaded `[$vidux]`, confirming the current blank header is prompt corruption.
- [Source: `/Users/leokwan/Development/vidux/SKILL.md`, read 2026-04-06] The canonical Vidux skill path is now `/Users/leokwan/Development/vidux/SKILL.md`, so the fix should restore that public path rather than the retired `ai/skills/vidux` path.
- [Source: `~/.codex/sqlite/codex-dev.db` tables `automations` and `automation_runs`, queried 2026-04-06] Both affected IDs remain active in the live scheduler, with `strongyes-release-train` showing `33` run records and `vidux-v230-planner` showing `2`, so repo truth and live DB prompt text must be repaired together.

## Change shipped
1. Restored the explicit `[$vidux](/Users/leokwan/Development/vidux/SKILL.md)` activation line in the repo-backed `strongyes-release-train` and `vidux-v230-planner` TOMLs.
2. Synced the live SQLite `prompt` field for both automation rows back to the same repo-backed text, without changing cadence, status, model, or reasoning.

## Remaining exposure
- `strongyes-release-train` still has no repo-backed `memory.md`, even though sibling radars read its last notes.
- Other active repo-backed loops still have missing or malformed memory contracts (`resplit-asc`, `resplit-currency`, `vidux-v230-planner`), which is a separate fleet-health slice.
