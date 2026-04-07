# 2026-04-07 Resplit Release Lane Ownership Audit

## Why this slice
The user wants the control plane to keep cutting fresh Resplit TestFlight builds and pushing Friends & Family testing when enough changes accumulate. The live fleet was not aligned with that goal: the ASC bug-fix lane was active, but the dedicated release lane was paused and easy to confuse with it.

## Facts gathered
- [Source: `/Users/leokwan/Development/ai/automations/resplit-asc/automation.toml`, read 2026-04-07] `resplit-asc` is an active ASC feedback investigation harness with screenshot and test gates, but no ownership for tagging, TestFlight upload, or Friends & Family distribution.
- [Source: `/Users/leokwan/Development/ai/automations/resplit-launch-loop/automation.toml`, read 2026-04-07] `resplit-launch-loop` is the dedicated release-proof lane for merge-back, TestFlight boundary, and release recommendation quality, but it was still `PAUSED` in repo truth.
- [Source: `~/.codex/sqlite/codex-dev.db` table `automations`, queried 2026-04-07] Live scheduler row `resplit-launch-loop | Resplit iOS Release` was also `PAUSED` with null `last_run_at` and `next_run_at`, while `resplit-asc` remained the only active Resplit row on a release-adjacent cadence.
- [Source: `/Users/leokwan/Development/resplit-ios/.env`, read 2026-04-07] The repo already carries the expected non-secret ASC config: `ASC_KEY_PATH=/Users/leokwan/.private_keys/AuthKey_32D626LB6H.p8`, `ASC_KEY_ID=32D626LB6H`, and `ASC_ISSUER_ID=a83bc1e6-1c71-405a-b068-3964f3a09260`.
- [Source: filesystem checks, 2026-04-07] `/Users/leokwan/.private_keys/` does not exist on this machine and repo `fastlane/AuthKey_32D626LB6H.p8` is absent, so the ASC Admin key file is the concrete missing auth dependency.
- [Source: `gh run view 24061628125` in `/Users/leokwan/Development/resplit-ios`, read 2026-04-07] The latest `Resplit CI/CD` run still aborts before `Build & Test` with GitHub's billing annotation: recent account payments failed or the spending limit needs to be increased.

## Change shipped
1. Activated `resplit-launch-loop` in repo truth and aligned its mission text with the explicit goal of landing a fresh TestFlight/Friends & Family boundary from clean trunk.
2. Slowed the release lane to one hourly pass so it matches the requested control-loop cadence without reopening the same release blocker multiple times per hour.
3. Seeded `resplit-launch-loop` memory with the current blocker contract so the first active run starts with the exact missing key path and the confirmed GitHub billing wall.
4. Tightened `resplit-asc` so it explicitly hands release/upload ownership to `resplit-launch-loop` instead of looking like the uploader by implication.
5. Synced the same `resplit-launch-loop` and `resplit-asc` prompt/status/cadence changes into live SQLite.

## Remaining exposure
- This run did not restore the missing Admin key or GitHub billing. The release loop can now own the correct mission, but it still cannot cut a real upload until Leo restores `/Users/leokwan/.private_keys/AuthKey_32D626LB6H.p8` and clears the Actions billing block.
- The canonical `/Users/leokwan/Development/ai` checkout is still dirty, so this remains a narrow live-root control-plane patch rather than a clean git-sync pass.
