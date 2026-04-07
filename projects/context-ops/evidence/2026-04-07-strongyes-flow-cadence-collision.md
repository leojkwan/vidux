# 2026-04-07 StrongYes Flow Cadence Collision

## Why this slice
The cooled DB-only governance seam should stay cold until approval state changes, so this run needed a different hot fleet-health slice. `strongyes-flow-radar` was the clearest current pressure point: it kept proving the same writer-owned StrongYes domain/auth seam on a 20-minute cadence even though the last 3 retained notes already showed runtimes longer than the interval.

## Facts gathered
- [Source: `/Users/leokwan/Development/ai/automations/strongyes-flow-radar/automation.toml`, read 2026-04-07] `strongyes-flow-radar` is `ACTIVE` on `FREQ=HOURLY;INTERVAL=1;BYMINUTE=7,27,47`, so the lane dispatches every 20 minutes.
- [Source: `/Users/leokwan/Development/ai/automations/strongyes-flow-radar/memory.md`, read 2026-04-07] The last 3 retained flow notes report runtimes of `~25m`, `~32m`, and `~26m`, each on the same unchanged public-auth/domain seam already represented in the StrongYes plan store.
- [Source: `~/.codex/sqlite/codex-dev.db` `automation_runs`, queried 2026-04-07] The latest 6 `strongyes-flow-radar` runs are spaced exactly `20` minutes apart and all ended `PENDING_REVIEW`, so the lane was dispatching faster than its own observed runtime.
- [Source: `~/.codex/sqlite/codex-dev.db` `automation_runs`, queried 2026-04-07] The latest `strongyes-release-train`, `strongyes-ux-radar`, and `strongyes-revenue-radar` inbox summaries still point to the same blocked StrongYes public auth/domain seam with the same reopen condition, so Flow was not discovering a new writer-ready move by repeating the full browser bundle.
- [Source: `/Users/leokwan/Development/ai/automations/strongyes-flow-radar/memory.md`, read 2026-04-07] Each recent run rebuilt a full desktop/mobile Playwright proof bundle even though the note itself already said the seam was unchanged and already represented in the store.
- [Source: repo-vs-DB comparison, audit 2026-04-07] The canonical repo-backed fleet still has `26` shared IDs with `0` repo/DB field mismatches, so this is a safe live-root slice: update one active repo-backed lane and sync the matching SQLite row.

## Change shipped
1. Tightened `strongyes-flow-radar` so when the last 3 flow notes plus the latest release-train note all point to the same unchanged writer-owned auth/domain seam, the lane performs only a lightweight route probe plus one representative rendered check instead of rebuilding the full desktop/mobile browser bundle.
2. Slowed `strongyes-flow-radar` from a 20-minute cadence to one hourly pass so the lane no longer self-overlaps while the seam is externally blocked.
3. Synced the matching live SQLite row's `prompt`, `rrule`, `updated_at`, and `next_run_at` back to repo truth.

## Remaining exposure
- The rest of the StrongYes cluster still repeats the same blocked public-auth/domain seam, but `strongyes-flow-radar` was the only browser-heavy lane whose recent runtimes already exceeded its interval.
- If StrongYes thread pressure remains hot after this cooldown lands, `strongyes-ux-radar` is the next candidate because it is still re-proving the same blocked pricing-auth seam every 20 minutes, even though its own runtimes are shorter.
