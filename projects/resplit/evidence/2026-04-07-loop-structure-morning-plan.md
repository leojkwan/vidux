# 2026-04-07 Resplit Loop Structure Morning Plan

## Goal
Reconcile live Resplit automation topology with repo queue truth so the morning plan reflects the real hot lanes, real blockers, and the loops that should cool.

## Sources
- [Source: `/Users/leokwan/Development/ai/automations/resplit-web/automation.toml`, read 2026-04-07] `resplit-web` is active on `FREQ=HOURLY;INTERVAL=1;BYMINUTE=0,20,40` and still requires a minimum 30 minutes of active work per run.
- [Source: `/Users/leokwan/Development/ai/automations/resplit-asc/automation.toml`, read 2026-04-07] `resplit-asc` is active on `FREQ=HOURLY;INTERVAL=1;BYMINUTE=5,25,45`, explicitly owns ASC feedback proof, and explicitly hands TestFlight/Friends & Family upload back to `resplit-launch-loop`.
- [Source: `/Users/leokwan/Development/ai/automations/resplit-launch-loop/automation.toml`, read 2026-04-07] `resplit-launch-loop` is active and now owns the clean-trunk TestFlight / Friends & Family boundary on an hourly cadence.
- [Source: `/Users/leokwan/Development/ai/automations/resplit-currency/automation.toml`, read 2026-04-07] `resplit-currency` is still active on `FREQ=HOURLY;INTERVAL=1;BYMINUTE=10,30,50` and is optimized for visible currency UI work, not the repo queue's current `p0-fx-ops` operational-truth lane.
- [Source: `/Users/leokwan/Development/ai/automations/resplit-android/automation.toml`, read 2026-04-07] `resplit-android` is still active on `FREQ=HOURLY;INTERVAL=1;BYMINUTE=12,32,52` even though its own method says repeated unchanged owner-blocked Play-input boundaries should checkpoint tersely and stop.
- [Source: live SQLite `automations`, queried 2026-04-07] Current active Resplit rows are `resplit-web`, `resplit-asc`, `resplit-currency`, `resplit-android`, and `resplit-launch-loop`; paused historical rows (`resplit-nurse`, `resplit-vidux`, `resplit-hourly-mayor`, etc.) remain mounted but cold.
- [Source: `/Users/leokwan/Development/ai/automations/resplit-web/memory.md`, read 2026-04-07] Latest `resplit-web` run shipped `/beta` continuity in `~16m`, which is substantial but not a 3x-per-hour lane by default while launch work is live.
- [Source: `/Users/leokwan/Development/ai/automations/resplit-asc/memory.md`, read 2026-04-07] Latest `resplit-asc` run took `~63m` to verify a bundled ASC fix lane, which directly contradicts a 20-minute recurring cadence.
- [Source: `/Users/leokwan/Development/ai/automations/resplit-currency/memory.md`, read 2026-04-07] Latest `resplit-currency` runs took `~35m`, `~44m`, and `~40m`, again contradicting a 20-minute recurring cadence.
- [Source: `/Users/leokwan/Development/ai/automations/resplit-android/memory.md`, read 2026-04-07] Latest `resplit-android` notes are `~2m`, `~7m`, and `~4m` owner-blocked or proof-refresh checkpoints with no product-state change, which is the unhealthy mid-zone pattern Vidux tries to avoid.
- [Source: `/Users/leokwan/Development/resplit-ios/RALPH.md`, read 2026-04-07] Repo queue truth says launch work defaults to hourly cadence while live, and queue order is ASC/TestFlight first, then hot launch blockers, then receipt/detail parity, release readiness, release assets, observability, and remaining launch polish.
- [Source: `/Users/leokwan/Development/resplit-ios/.cursor/plans/remaining-work.plan.md`, read 2026-04-07] The next real blockers are `p0-native-readiness`, `p0-migration-branch-triage`, `p0-fx-ops`, and final release evidence; the file also says FX is mostly implemented and the remaining FX work is operational clarity, not missing UI architecture.
- [Source: `/Users/leokwan/Development/resplit-ios/.cursor/plans/resplit-nurse.log.md`, read 2026-04-07] The release wall is local: build `1107` is still the active uploaded wall, `AuthKey_32D626LB6H.p8` is missing from `~/.private_keys/`, and this host currently lacks Apple Distribution signing proof for Fastlane export.

## Findings

### 1. The public Resplit mission store is stale about its own active loop topology
The store still carries a 2026-04-06 deletion note saying `resplit-launch-loop` was removed, but live repo truth and SQLite now show `resplit-launch-loop` active again and explicitly owning TestFlight/Friends & Family. That contradiction is now a planning bug, not just a control-plane detail.

### 2. Several active Resplit lanes are overscheduled relative to their own runtime contract
`resplit-asc` took about 63 minutes for the latest bundled fix/proof cycle, and `resplit-currency` is repeatedly taking 35-44 minutes. Both are still scheduled every 20 minutes. `resplit-web` is shipping real work in about 16 minutes, but it still carries a 30-minute-minimum execution contract. The live cadence is therefore denser than the documented workload.

### 3. Android is a blocked boundary, not a hot ship lane this morning
The Android lane is repeatedly re-proving the same owner-blocked Play handoff in 2-7 minute cycles with no product-state change. That is useful as a checkpoint once, but not as a 3x-per-hour hot lane while launch work is live elsewhere.

### 4. FX loop purpose has drifted from the repo queue
`remaining-work.plan.md` says the live FX work is `p0-fx-ops`: runbook truth, worker-domain smoke evidence, and release-contract clarity. The active `resplit-currency` harness is still spending time on visible picker polish. That is a mission mismatch even if the UI work is high quality.

### 5. The real morning stack is release + ASC + bounded web, with FX and Android cooled unless they match queue truth
`RALPH.md` puts ASC/TestFlight first and says hourly cadence is the default while launch work is live. The nurse log confirms the release wall is currently external. That makes the honest morning order:
1. clear local key/signing blockers for release
2. keep `resplit-launch-loop` ready to cut the next boundary
3. let `resplit-asc` keep taking the next unowned ASC bug bundle
4. keep `resplit-web` on one bounded final-parity seam at a time
5. cool Android and reframe FX before more churn

## Recommendations
- Update the public Resplit store so `resplit-launch-loop` is explicitly back in the hot topology and the 2026-04-06 deletion note is treated as historical, not current truth.
- Normalize hot Resplit writer lanes to hourly max while launch work is live, unless a lane proves it is a genuinely short proof loop.
- Treat Android as cooled or paused until owner Play inputs change.
- Rewrite `resplit-currency` toward `p0-fx-ops` operational truth or park it until that becomes the active queue slice.
- Use this morning's human time on the local release blockers first: restore the ASC Admin key file and satisfy local export-signing prerequisites.
