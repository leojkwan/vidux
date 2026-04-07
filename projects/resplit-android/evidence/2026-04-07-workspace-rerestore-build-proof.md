# 2026-04-07 Workspace Rerestore Build Proof

## Goal
Record the second `/tmp` workspace loss, prove that the Android code/build lane is restored again, and checkpoint the fact that the Play launch package is no longer present on disk.

## Sources
- [Source: local provenance, 2026-04-07] Claude session `44ce7a52-ff1d-4f88-bce6-64b8e4df715f` plus matching `~/.claude/file-history`
- [Source: shell, 2026-04-07] local replay script rebuilt `/tmp/resplit-android` from 90 recorded `Write`/`Edit` operations and overlaid later file-history snapshots
- [Source: shell, 2026-04-07] `JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home ANDROID_HOME=$HOME/Library/Android/sdk ANDROID_SDK_ROOT=$HOME/Library/Android/sdk ~/.gradle/wrapper/dists/gradle-8.4-bin/*/gradle-8.4/bin/gradle --no-daemon wrapper --gradle-version 8.4`
- [Source: shell, 2026-04-07] `JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home ANDROID_HOME=$HOME/Library/Android/sdk ANDROID_SDK_ROOT=$HOME/Library/Android/sdk /tmp/resplit-android/gradlew --no-daemon -p /tmp/resplit-android testDebugUnitTest assembleDebug assembleRelease bundleRelease assembleDebugAndroidTest`
- [Source: shell, 2026-04-07] `find /tmp/resplit-android/app/build/outputs -maxdepth 4 -type f | sort`
- [Source: shell, 2026-04-07] `if [ -d /tmp/resplit-android/docs/play-store ]; then find /tmp/resplit-android/docs/play-store -maxdepth 3 -type f | sort; else echo 'MISSING:/tmp/resplit-android/docs/play-store'; fi`
- [Source: code change, 2026-04-07] `/tmp/resplit-android/app/src/main/AndroidManifest.xml`
- [Source: code change, 2026-04-07] `/tmp/resplit-android/app/src/main/java/com/resplit/android/ui/home/HomeScreen.kt`
- [Source: code change, 2026-04-07] `/tmp/resplit-android/app/src/main/java/com/resplit/android/ui/home/HomeViewModel.kt`
- [Source: code change, 2026-04-07] `/tmp/resplit-android/app/src/main/java/com/resplit/android/ui/receipt/EditReceiptScreen.kt`

## Findings

### 1. The Android workspace disappeared again and had to be reconstructed from local provenance
`/tmp/resplit-android` was missing at the start of this run, so the prior owner-blocked Play-submission assumption was no longer trustworthy. The only surviving local source remained Claude session `44ce7a52-ff1d-4f88-bce6-64b8e4df715f` plus `~/.claude/file-history`, and replaying those artifacts rebuilt a 45-file Android workspace.

### 2. The recovered tree needed real repair work before it was honestly buildable
The rerestore surfaced missing manifest-linked resources and an incomplete Home-screen overlay. This run:
- kept `android:allowBackup="false"` in the manifest
- restored missing XML resource files and adaptive launcher assets
- replaced the Hilt-overlaid Home files with the Room-backed versions that match the recovered tree
- swapped the remaining unsupported `HorizontalDivider` usage back to `Divider`

These were not cosmetic edits; without them the recovered workspace failed the serial build gate.

### 3. The full serial Android gate passes again
After the restore fixes, the exact serial verification command succeeded:

```bash
JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home \
ANDROID_HOME=$HOME/Library/Android/sdk \
ANDROID_SDK_ROOT=$HOME/Library/Android/sdk \
/tmp/resplit-android/gradlew --no-daemon -p /tmp/resplit-android \
  testDebugUnitTest assembleDebug assembleRelease bundleRelease assembleDebugAndroidTest
```

Gradle reported `BUILD SUCCESSFUL in 9s`.

### 4. Release outputs exist again
The rebuilt workspace currently produces:
- `/tmp/resplit-android/app/build/outputs/apk/debug/app-debug.apk`
- `/tmp/resplit-android/app/build/outputs/apk/release/app-release-unsigned.apk`
- `/tmp/resplit-android/app/build/outputs/bundle/release/app-release.aab`
- `/tmp/resplit-android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk`

### 5. The Play launch package is currently absent
The launch-artifact probe returned `MISSING:/tmp/resplit-android/docs/play-store`. That means the app/build lane is green again, but the Play package docs, privacy/data-safety artifacts, listing drafts, and screenshot wave are not currently present together on disk.

### 6. The honest next boundary moved back into the Android lane
Because the code/build proof and launch-artifact proof are no longer aligned, the next slice is not owner Play submission. The next Android task is to regenerate `/tmp/resplit-android/docs/play-store/` and `/tmp/resplit-android/docs/play-store-launch.md`, then re-prove the launch package before handing the lane back to the owner.

## Recommendations
- Keep the workspace-rerestore proof and the launch-artifact proof as separate checkpoints whenever `/tmp` churn occurs.
- Treat Play launch package regeneration as the explicit next Android lane, not a side note to the owner-blocked submission step.
