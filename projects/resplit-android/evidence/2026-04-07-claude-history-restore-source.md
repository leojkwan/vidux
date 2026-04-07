# 2026-04-07 Claude History Restore Source

## Goal
Determine whether the missing [`/tmp/resplit-android`](/tmp/resplit-android) workspace still has a concrete, local restore source instead of remaining blocked on an unnamed archive or owner handoff.

## Sources
- [Source: shell + Python, 2026-04-07] Parsed `~/.claude/projects/**/*.jsonl` for `Write` and `Edit` tool records touching `/tmp/resplit-android/`.
- [Source: shell + Python, 2026-04-07] Parsed `~/.claude/file-history/**` for files whose contents begin with `package com.resplit.android`.
- [Source: shell, 2026-04-07] `rg -n --hidden '/tmp/resplit-android/docs/play-store|privacy-policy-android-p1|play-store-launch|metadata-draft|ship-checklist|data-safety-draft' ~/.claude`
- [Source: archived Claude session data, 2026-04-07] Session `44ce7a52-ff1d-4f88-bce6-64b8e4df715f` includes the only recoverable `Write`/`Edit` records for `/tmp/resplit-android/`.
- [Source: shell + Python replay, 2026-04-07 02:58 EDT] Replayed deduplicated `Write`/`Edit` operations from session `44ce7a52-ff1d-4f88-bce6-64b8e4df715f` into a fresh `/tmp/resplit-android` tree; materialized `45` files with no edit-application warnings.
- [Source: shell, 2026-04-07 02:58 EDT] Verified restored tree counts: `36` app source files under `app/src/main/java`, `2` unit-test files, `1` Android UI test file.
- [Source: shell, 2026-04-07 02:58 EDT] Verified boundary after replay: no `/tmp/resplit-android/gradlew`, no `gradle/wrapper/gradle-wrapper.properties`, no `gradle/wrapper/gradle-wrapper.jar`, and no system `gradle` or `sdkmanager` on `PATH`, while Android Studio JBR exists at `/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/java`.

## Findings

### 1. The Android workspace has an explicit local restore source
`~/.claude/projects/**/*.jsonl` contains `90` `Write`/`Edit` records spanning `45` unique files under `/tmp/resplit-android/`, all from one coherent Claude session: `44ce7a52-ff1d-4f88-bce6-64b8e4df715f`. This is a named, local provenance source rather than a vague archived hint.

### 2. The recoverable baseline covers core app code and build scripts
The recovered file set includes root Gradle scripts, app module Gradle config, the manifest, Room entities and DAOs, Compose screens, navigation, theme files, domain use cases, and unit or UI tests. The latest recoverable source edit landed at `2026-04-05T13:45:14Z` in [`/tmp/resplit-android/app/src/main/java/com/resplit/android/ui/home/HomeViewModel.kt`](/tmp/resplit-android/app/src/main/java/com/resplit/android/ui/home/HomeViewModel.kt).

### 3. No second session surfaced with later `/tmp/resplit-android` source edits
A wider scan across all `~/.claude/projects/**/*.jsonl` found the same `45` files and the same single session. Inference: the recoverable baseline is coherent, but it may not include later April 6 launch-readiness edits unless those were never written through Claude tools.

### 4. Play handoff docs and wrapper artifacts are not covered by the same history
Searches across `~/.claude` did not surface direct file writes for `/tmp/resplit-android/docs/play-store/...`, `privacy-policy-android-p1`, `play-store-launch`, `metadata-draft`, or `data-safety-draft`. The same history also did not yield a recoverable `gradle-wrapper.jar` or `gradlew` file path. That means the restore source is strong enough for the app baseline, but not yet for the full launch package.

### 5. The baseline source tree now exists again, but build tooling does not
Replaying the deduplicated history recreated `/tmp/resplit-android` with the root Gradle scripts plus the `app/` source tree and tests. The replay produced no missing-edit warnings, which is strong evidence that the recovered baseline is internally coherent. The next boundary is no longer "missing workspace"; it is "missing wrapper or Gradle bootstrap," because the restored tree still has no `gradlew`, no wrapper jar or properties, and no system `gradle` binary to run the serial gate yet.

## Recommendations
- Treat Claude session `44ce7a52-ff1d-4f88-bce6-64b8e4df715f` plus matching `~/.claude/file-history` snapshots as the current named restore source for the Android baseline.
- Treat the baseline reconstruction as complete enough to move E0 into wrapper or build-bootstrap recovery, not source-provenance recovery.
- Recreate wrapper or otherwise supply a local Gradle bootstrap, then regenerate missing launch artifacts, then run the serial Android gate.
