# 2026-04-07 Play Package Rerestore Proof

## Goal
Record the fact that the latest `/tmp` restore lost the Android Play package again, then prove the lane is back to a truthful launch-ready package with restored totals, rebuilt docs/assets, and a fresh seeded screenshot wave.

## Sources
- [Source: iOS source truth] `/Users/leokwan/Development/resplit-ios/ReceiptSplitter/Calculators/ReceiptTotalCalculator.swift`
- [Source: code change] `/tmp/resplit-android/app/src/main/java/com/resplit/android/domain/model/ReceiptTotalCalculator.kt`
- [Source: code change] `/tmp/resplit-android/app/src/main/java/com/resplit/android/ui/home/HomeViewModel.kt`
- [Source: code change] `/tmp/resplit-android/app/src/main/java/com/resplit/android/ui/home/HomeScreen.kt`
- [Source: code change] `/tmp/resplit-android/app/src/main/java/com/resplit/android/ui/folder/FolderViewModel.kt`
- [Source: code change] `/tmp/resplit-android/app/src/main/java/com/resplit/android/ui/folder/FolderDetailScreen.kt`
- [Source: test] `/tmp/resplit-android/app/src/test/java/com/resplit/android/domain/model/ReceiptTotalCalculatorTest.kt`
- [Source: build proof] `JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home ANDROID_HOME=$HOME/Library/Android/sdk ANDROID_SDK_ROOT=$HOME/Library/Android/sdk /tmp/resplit-android/gradlew --no-daemon -p /tmp/resplit-android testDebugUnitTest assembleDebug assembleRelease bundleRelease assembleDebugAndroidTest`
- [Source: emulator seed proof] `run-as com.resplit.android sqlite3 databases/resplit.db`
- [Source: artifact proof] `find /tmp/resplit-android/docs/play-store -maxdepth 3 -type f | sort`
- [Source: dimension proof] `sips -g pixelWidth -g pixelHeight /tmp/resplit-android/docs/play-store/assets/play-icon-512.png /tmp/resplit-android/docs/play-store/assets/feature-graphic-1024x500.png /tmp/resplit-android/docs/play-store/screenshots/wave-1/*.png`
- [Source: MCP status] `nia` resources/templates listing still failed during initialize handshake on 2026-04-07

## Findings

### 1. The rerestored workspace had drifted behind the last honest screenshot truth
After the latest replay, Home and Folder detail were back on partial receipt math (`taxAmount + tipPercent` and `taxAmount`) rather than actual totals. That would have made any recaptured Play screenshots misleading.

### 2. Receipt totals are truthful again on the launch surfaces
This run restored the shared total calculation on Android by adding `ReceiptTotalCalculator` and wiring Home plus Folder detail to item-backed totals before runtime proof. The supporting unit test passed in the rebuilt serial gate.

### 3. The Play package exists again on disk
The missing launch docs were rebuilt under `/tmp/resplit-android/docs/play-store/`, including:
- `data-safety-draft.md`
- `metadata-draft.md`
- `privacy-policy-android-p1.md`
- `privacy-policy-android-p1.html`
- `screenshot-shot-list.md`
- `ship-checklist.md`
- `assets/play-icon-512.png`
- `assets/feature-graphic-1024x500.png`

### 4. The screenshot wave was recaptured from the seeded emulator path
The emulator was reseeded with deterministic local Room data (`3` people, `2` receipts, `1` folder, `5` items, `4` receipt participants, `2` folder links), then the real app flow was replayed to capture:
- `01-home.png`
- `02-receipt-detail.png`
- `03-folder-list.png`
- `04-folder-detail.png`
- `05-settlement.png`
- `06-people.png`

All six screenshots now exist at `1080 x 2220`. The rebuilt icon and feature graphic also exist at `512 x 512` and `1024 x 500`.

### 5. The full Android gate is green again with launch artifacts present
The serial verification command returned `BUILD SUCCESSFUL in 26s`, and the debug APK, release APK, release AAB, and androidTest APK all remain present under `/tmp/resplit-android/app/build/outputs/`. The launch artifact gate is satisfied again because the docs, assets, screenshots, and release outputs coexist on disk.

### 6. The next boundary is owner-side Play submission again
With the Android lane re-proved, the remaining work is external:
- host the Android privacy-policy HTML at a public URL
- provide release signing or Play App Signing upload inputs
- confirm final category, pricing, content rating, and Data safety answers
- complete the first Play Console submission
