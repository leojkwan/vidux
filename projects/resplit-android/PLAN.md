# Resplit Android — Offline Launch Parity

## Purpose
Build Resplit Android in [`/tmp/resplit-android`](/tmp/resplit-android) to honest user-facing parity with the local-only core of Resplit iOS while staying Android-native, fully offline, one-time-purchase, and free of accounts, cloud sync, or network services.

## Recovery Note
- [2026-04-06] The old `resplit-android` plan path disappeared during the `vidux` repo split. This file rehydrates current truth at the live store path `skills/vidux/projects/resplit-android/PLAN.md` -> [`/Users/leokwan/Development/vidux/projects/resplit-android/PLAN.md`](/Users/leokwan/Development/vidux/projects/resplit-android/PLAN.md).
- [2026-04-06] Historical completed work survives mainly in automation memory and the Android workspace itself. This recovered plan tracks the current frontier instead of replaying every deleted intermediate note.

## Scope
- P1 shipped/verified target: local receipt splitting, participant management, trip/folder organization, settlement, manual entry, Material 3 theming, accessibility/test tags, Room-only persistence, share/deep-link foundations, Play launch package
- P2 planned only: CSV export UI/file-writing surface
- Explicitly out of scope: auth, subscriptions, cloud sync, analytics, network OCR, remote storage, modifying [`/Users/leokwan/Development/resplit-ios`](/Users/leokwan/Development/resplit-ios)

## Constraints
- ALWAYS build product code in [`/tmp/resplit-android`](/tmp/resplit-android)
- ALWAYS keep Room as the only durable app data layer
- ALWAYS cite iOS source truth before parity work
- ALWAYS verify with serial Android proof for this workspace
- NEVER add network calls, cloud sync, auth, analytics, or remote persistence
- NEVER modify [`/Users/leokwan/Development/resplit-ios`](/Users/leokwan/Development/resplit-ios)
- NEVER choose KMP without explicit approval

## Product DNA
- One-time purchase utility, not a service
- Utility as kindness
- Split in 30 seconds
- Five words max where possible
- Teal anchor: `#2EAD85`
- Android-native feel beats mechanical iOS mirroring

## Evidence Summary
- iOS parity references still anchor the shipped Android shape:
  - settlement truth in [`/Users/leokwan/Development/resplit-ios/ReceiptSplitter/SettlementService.swift`](/Users/leokwan/Development/resplit-ios/ReceiptSplitter/SettlementService.swift)
  - people/source separation in [`/Users/leokwan/Development/resplit-ios/ResplitCore/UI/LiveSplit/PeoplePickerViewModel.swift`](/Users/leokwan/Development/resplit-ios/ResplitCore/UI/LiveSplit/PeoplePickerViewModel.swift)
  - folder lifecycle in [`/Users/leokwan/Development/resplit-ios/ResplitCore/Managers/FolderManager.swift`](/Users/leokwan/Development/resplit-ios/ResplitCore/Managers/FolderManager.swift)
  - CSV contract source in [`/Users/leokwan/Development/resplit-ios/ResplitCore/Managers/ReceiptCSVExporter.swift`](/Users/leokwan/Development/resplit-ios/ResplitCore/Managers/ReceiptCSVExporter.swift)
- Current launch and offline-boundary audit lives in [`/Users/leokwan/Development/vidux/projects/resplit-android/evidence/2026-04-06-launch-handoff-audit.md`](/Users/leokwan/Development/vidux/projects/resplit-android/evidence/2026-04-06-launch-handoff-audit.md)
- Current Android launch package lives in:
  - [`/tmp/resplit-android/docs/play-store/metadata-draft.md`](/tmp/resplit-android/docs/play-store/metadata-draft.md)
  - [`/tmp/resplit-android/docs/play-store/ship-checklist.md`](/tmp/resplit-android/docs/play-store/ship-checklist.md)
  - [`/tmp/resplit-android/docs/play-store-launch.md`](/tmp/resplit-android/docs/play-store-launch.md)
  - [`/tmp/resplit-android/docs/play-store/data-safety-draft.md`](/tmp/resplit-android/docs/play-store/data-safety-draft.md)
  - [`/tmp/resplit-android/docs/play-store/privacy-policy-android-p1.md`](/tmp/resplit-android/docs/play-store/privacy-policy-android-p1.md)

## Milestone Status
- [completed] M1: Android architecture foundation is in place: Hilt injection, typed navigation, Room schema export/migrations, repository seams
- [completed] M2: Core parity surfaces are in place: home/list, receipt detail, people, trips/folders, settlement, share/deep-link entry
- [completed] M3: Android-native finishing is in place: Material 3 token layer, accessibility tags, Compose/instrumentation coverage, CSV schema contract
- [completed] M4: Play launch package exists: screenshots, icon/feature graphic, listing copy draft, release outputs, support coordinates
- [completed] M5: Offline-truth correction landed on 2026-04-06 by disabling Android Auto Backup and drafting Android-specific Data safety/privacy copy

## Active Queue
- [blocked] Task E1: Owner completes first Play Console submission using the prepared Android launch package. Remaining owner work:
  - publish or host the Android-specific privacy policy from [`/tmp/resplit-android/docs/play-store/privacy-policy-android-p1.md`](/tmp/resplit-android/docs/play-store/privacy-policy-android-p1.md)
  - provide release signing / Play App Signing upload credentials
  - confirm first-upload `versionCode` / `versionName`, category, pricing, content rating, and final Data safety declarations
  - enter the prepared listing copy and assets into Play Console
  [Evidence: `/tmp/resplit-android/docs/play-store-launch.md`, `evidence/2026-04-06-launch-handoff-audit.md`]
- [blocked] Task E2: Wait on owner inputs before any new Android lane work. Fresh serial proof on 2026-04-06 reconfirmed there is no unblocked Android workspace slice ahead of Play submission.
  [Evidence: `evidence/2026-04-06-launch-handoff-audit.md`]

## Current Decisions
- [2026-04-06] Decision: Android P1 must not opt into cloud backup. Rationale: Auto Backup weakened the harness promise of fully offline/no-cloud behavior and complicated a truthful Play Data safety answer.
- [2026-04-06] Decision: Android P1 privacy/public copy must be Android-specific. Rationale: the current iOS web privacy page still describes iCloud, analytics, and third-party processing.
- [2026-04-06] Decision: `versionCode = 1` / `versionName = "1.0"` is acceptable for the first upload, but every later release must increment `versionCode`. Rationale: Android official versioning guidance.

## Verification Gates
- Serial build/test gate:
  - `JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home ANDROID_HOME=$HOME/Library/Android/sdk ANDROID_SDK_ROOT=$HOME/Library/Android/sdk ./gradlew --no-daemon testDebugUnitTest assembleDebug assembleRelease bundleRelease assembleDebugAndroidTest`
- Runtime/device smoke:
  - use an emulator/device when available to replay the seeded home -> receipt -> trip -> settlement path
- Launch artifact gate:
  - screenshots, listing art, Data safety draft, privacy-policy draft, and release outputs all exist together in `/tmp/resplit-android/docs/play-store/`

## Open Questions
- [ ] Q1: Which owner-managed public URL will host the Android privacy policy draft before Play submission?
- [ ] Q2: Will the first Play upload keep `versionName = "1.0"` or use a launch-specific marketing string while preserving `versionCode = 1`?

## Progress
- [2026-04-06] Rehydrated the missing `resplit-android` authority store at the live `vidux` path from surviving automation memory plus the current Android workspace.
- [2026-04-06] Audited official Play Data safety guidance and local manifest/build truth, then corrected the one remaining product-truth mismatch by disabling Android Auto Backup.
- [2026-04-06] Prepared Android-specific Play Console handoff docs for Data safety and privacy so the remaining blocker is owner execution, not missing Android lane artifacts.
- [2026-04-06] Re-ran the full serial Android gate after the launch handoff and reconfirmed the same boundary: `/tmp/resplit-android` still builds cleanly, launch docs are present, and only owner-side Play submission inputs remain.
- [2026-04-06] Latest automation pass revalidated the unchanged launch boundary from local workspace truth and a fresh serial Gradle gate: `android:allowBackup="false"` in the manifest, `versionCode = 1` / `versionName = "1.0"` in `app/build.gradle.kts`, launch docs still present, `./gradlew --no-daemon testDebugUnitTest assembleDebug assembleRelease bundleRelease assembleDebugAndroidTest` returned `BUILD SUCCESSFUL in 14s`, and Nia MCP still unavailable from Codex so there is no new research delta to absorb.
- [2026-04-06 18:59 EDT] Revalidated the unchanged launch boundary from live workspace truth again: [`/tmp/resplit-android/app/src/main/AndroidManifest.xml`](/tmp/resplit-android/app/src/main/AndroidManifest.xml) still sets `android:allowBackup="false"`, [`/tmp/resplit-android/app/build.gradle.kts`](/tmp/resplit-android/app/build.gradle.kts) still sets `versionCode = 1` / `versionName = "1.0"`, Play launch docs/assets/screenshots plus release outputs still exist under [`/tmp/resplit-android/docs/play-store/`](/tmp/resplit-android/docs/play-store/) and [`/tmp/resplit-android/app/build/outputs/`](/tmp/resplit-android/app/build/outputs/), the full serial gate `./gradlew --no-daemon testDebugUnitTest assembleDebug assembleRelease bundleRelease assembleDebugAndroidTest` returned `BUILD SUCCESSFUL in 6s`, and Nia MCP again failed to initialize from Codex, so no new research or implementation slice is unblocked ahead of owner Play submission.
- [2026-04-06 19:14 EDT] Revalidated the unchanged Play-submission boundary from live workspace truth once more: [`/tmp/resplit-android/app/src/main/AndroidManifest.xml`](/tmp/resplit-android/app/src/main/AndroidManifest.xml) still sets `android:allowBackup="false"`, [`/tmp/resplit-android/app/build.gradle.kts`](/tmp/resplit-android/app/build.gradle.kts) still sets `versionCode = 1` / `versionName = "1.0"`, Play docs remain under [`/tmp/resplit-android/docs/play-store/`](/tmp/resplit-android/docs/play-store/) and release outputs remain under [`/tmp/resplit-android/app/build/outputs/`](/tmp/resplit-android/app/build/outputs/), the full serial gate `./gradlew --no-daemon testDebugUnitTest assembleDebug assembleRelease bundleRelease assembleDebugAndroidTest` returned `BUILD SUCCESSFUL in 8s` (`real 8.62`), and Nia MCP still fails to initialize from Codex, so no new Android implementation slice is unblocked before owner Play submission.

## Next
- Owner must publish the Android privacy-policy URL, provide signing or Play App Signing inputs, and complete the first Play Console submission using the prepared launch package.
- Keep the Android lane blocked until owner submission exposes a concrete blocker or parity regression.
- If the owner provides the URL or requests final upload review, resume from Task E1 only.
