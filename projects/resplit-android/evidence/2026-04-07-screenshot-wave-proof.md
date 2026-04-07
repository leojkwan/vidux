# 2026-04-07 Screenshot Wave Proof

## Goal
Record the proof that the recovered Android workspace now has an honest Play screenshot wave and note the final boundary after recapture.

## Sources
- [Source: code change] `/tmp/resplit-android/app/src/main/java/com/resplit/android/ui/home/HomeScreen.kt`
- [Source: code change] `/tmp/resplit-android/app/src/main/java/com/resplit/android/ui/home/HomeViewModel.kt`
- [Source: code change] `/tmp/resplit-android/app/src/main/java/com/resplit/android/ui/folder/FolderDetailScreen.kt`
- [Source: code change] `/tmp/resplit-android/app/src/main/java/com/resplit/android/ui/folder/FolderViewModel.kt`
- [Source: code change] `/tmp/resplit-android/app/src/main/java/com/resplit/android/data/dao/ReceiptDao.kt`
- [Source: code change] `/tmp/resplit-android/app/src/main/java/com/resplit/android/domain/model/ReceiptTotalCalculator.kt`
- [Source: test] `/tmp/resplit-android/app/src/test/java/com/resplit/android/domain/model/ReceiptTotalCalculatorTest.kt`
- [Source: build proof] `JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home ANDROID_HOME=$HOME/Library/Android/sdk ANDROID_SDK_ROOT=$HOME/Library/Android/sdk ./gradlew --no-daemon testDebugUnitTest assembleDebug assembleRelease bundleRelease assembleDebugAndroidTest`
- [Source: emulator proof] headless AVD `Pixel_3a_API_34_extension_level_7_arm64-v8a`
- [Source: local DB proof] `run-as com.resplit.android sqlite3 databases/resplit.db`
- [Source: MCP status] `nia` MCP resource listing still failed during initialize handshake on 2026-04-07

## Findings

### 1. The recovered Home and Folder surfaces now show honest totals
This run replaced partial header math on Home and Folder receipt cards with a shared item-backed total calculation derived from receipt items plus tax and tip, aligning Android with the iOS receipt-total product truth before capture.

### 2. The serial Android gate passed after the total fix
The full verification command completed successfully after the UI/data-layer changes: `./gradlew --no-daemon testDebugUnitTest assembleDebug assembleRelease bundleRelease assembleDebugAndroidTest` returned `BUILD SUCCESSFUL in 9s`.

### 3. Screenshot recapture used real emulator state, not mocked assets
The screenshot wave was recaptured from the local Android emulator after seeding Room directly through `run-as ... sqlite3` with a deterministic offline sample:
- `01-home.png`
- `02-receipt-detail.png`
- `03-folder-list.png`
- `04-folder-detail.png`
- `05-settlement.png`
- `06-people.png`

All six files exist at `1080 x 2220` under `/tmp/resplit-android/docs/play-store/screenshots/wave-1/`.

### 4. The launch boundary is owner-side again
With screenshots restored, the Android lane no longer has an internal Play package gap. The remaining work is the same owner-side boundary: host the Android privacy HTML publicly, provide signing or Play App Signing inputs, confirm final Play metadata answers, and complete the first Play Console submission.

## Recommendations
- Treat the screenshot wave as restored and move the plan back to the owner handoff boundary.
- Use the existing six PNGs as the baseline asset set unless a later product change makes them stale.
