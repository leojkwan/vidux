# 2026-04-07 Paused Automation Name Collisions

## Goal
Record the paused historical automation rows whose human-facing names still collide with active or sibling scheduler rows, making the fleet read as if duplicate missions are still live.

## Sources
- [Source: `/Users/leokwan/Development/ai/automations/resplit-super-nurse-hourly/automation.toml`, read 2026-04-07] The paused historical definition still uses `name = "Resplit Super Team Hourly"` even though its own prompt begins with `Deprecated historical definition`.
- [Source: `/Users/leokwan/Development/ai/automations/resplit-super-team-hourly/automation.toml`, read 2026-04-07] The separate paused super-team definition also uses `name = "Resplit Super Team Hourly"`.
- [Source: `/Users/leokwan/Development/ai/automations/vidux-endurance-test/automation.toml`, read 2026-04-07] The paused historical endurance definition still uses `name = "Vidux Endurance Test"`.
- [Source: `/Users/leokwan/Development/ai/automations/vidux-endurance/automation.toml`, read 2026-04-07] The active endurance watcher also uses `name = "Vidux Endurance Test"`.
- [Source: `~/.codex/sqlite/codex-dev.db` table `automations`, queried 2026-04-07] The live scheduler currently exposes the same duplicate name pairs: `resplit-super-nurse-hourly` and `resplit-super-team-hourly`, plus `vidux-endurance-test` and `vidux-endurance`.

## Findings

### 1. Two paused Resplit rows share one display identity
`resplit-super-nurse-hourly` and `resplit-super-team-hourly` are both `PAUSED`, but both present as `Resplit Super Team Hourly` in the scheduler. One of them is already explicitly marked as deprecated in its prompt body, so the ambiguous name is the drift, not the mission state.

### 2. A paused Vidux endurance relic still looks identical to the active lane
`vidux-endurance-test` is `PAUSED`, while `vidux-endurance` is `ACTIVE`, yet both present as `Vidux Endurance Test`. That makes the historical row look like a second live endurance loop rather than a retired predecessor.

### 3. This is a safe paused-loop repair
The affected rows are already paused, so the lowest-risk fix is to rename the paused historical definitions to explicit legacy identities and sync the same `name` fields into SQLite. No cadence, status, prompt routing, or ownership changes are required for this pass.

## Recommendations
- Rename `resplit-super-nurse-hourly` to an explicit legacy label.
- Rename `vidux-endurance-test` to an explicit legacy label.
- Mirror the same `name` changes into the SQLite scheduler so repo truth and live control-plane UI stay aligned.
