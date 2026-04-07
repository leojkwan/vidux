# 2026-04-07 Workspace Restore Proof

## Goal
Verify whether the reconstructed `/tmp/resplit-android` workspace is buildable again, restore the missing local bootstrap and launch-package docs that were lost with the `/tmp` cleanup, and identify the next honest boundary.

## Sources
- [Source: shell, 2026-04-07] Local Gradle distribution found at `~/.gradle/wrapper/dists/gradle-8.4-bin/*/gradle-8.4/bin/gradle`.
- [Source: shell, 2026-04-07] `JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home ANDROID_HOME=$HOME/Library/Android/sdk ANDROID_SDK_ROOT=$HOME/Library/Android/sdk ~/.gradle/wrapper/dists/gradle-8.4-bin/*/gradle-8.4/bin/gradle --no-daemon wrapper --gradle-version 8.4`
- [Source: shell, 2026-04-07] `JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home ANDROID_HOME=$HOME/Library/Android/sdk ANDROID_SDK_ROOT=$HOME/Library/Android/sdk ./gradlew --no-daemon testDebugUnitTest assembleDebug assembleRelease bundleRelease assembleDebugAndroidTest`
- [Source: codebase grep/read, 2026-04-07] Restored manifest and receipt-screen source files in `/tmp/resplit-android`
- [Source: shell, 2026-04-07] `find /tmp/resplit-android/app/build/outputs -maxdepth 4 -type f`
- [Source: shell, 2026-04-07] `find /tmp/resplit-android/docs/play-store -maxdepth 3 -type f`
- [Source: shell, 2026-04-07] `sips -g pixelWidth -g pixelHeight /tmp/resplit-android/docs/play-store/assets/play-icon-512.png /tmp/resplit-android/docs/play-store/assets/feature-graphic-1024x500.png`
- [Source: shell, 2026-04-07] `~/Library/Android/sdk/emulator/emulator -list-avds`
- [Source: MCP `nia` resources/list + templates/list, 2026-04-07] Nia still failed to initialize from Codex: `initialize response` connection closed.

## Findings

### 1. Local bootstrap is restored
The replayed workspace was missing `gradlew` and wrapper files, but the machine already had a local Gradle 8.4 distribution in `~/.gradle/wrapper/dists`. Using that local binary, the project successfully regenerated `gradlew`, `gradle/wrapper/gradle-wrapper.jar`, and `gradle/wrapper/gradle-wrapper.properties`, so E0 is no longer blocked on missing build tooling.

### 2. The recovered source baseline needed two real code-truth fixes
The replayed manifest had drifted back to `android:allowBackup="true"` despite the April 6 offline-truth correction, and the replay had lost launcher icon resources entirely. Restoring `android:allowBackup="false"`, regenerating adaptive launcher assets, and replacing two unsupported `HorizontalDivider` references with `Divider` moved the workspace from partial replay state to a fully buildable state.

### 3. The full serial Android gate passes again
With the restored wrapper and code/resource fixes in place, the exact serial proof command succeeded:

```bash
JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home \
ANDROID_HOME=$HOME/Library/Android/sdk \
ANDROID_SDK_ROOT=$HOME/Library/Android/sdk \
./gradlew --no-daemon testDebugUnitTest assembleDebug assembleRelease bundleRelease assembleDebugAndroidTest
```

Gradle reported `BUILD SUCCESSFUL in 39s`.

### 4. Release outputs are present again
The restored workspace now produces:
- `/tmp/resplit-android/app/build/outputs/apk/debug/app-debug.apk`
- `/tmp/resplit-android/app/build/outputs/apk/release/app-release-unsigned.apk`
- `/tmp/resplit-android/app/build/outputs/bundle/release/app-release.aab`
- `/tmp/resplit-android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk`

### 5. The written Play package and static assets are restored, but screenshots are still missing
This run rebuilt:
- `/tmp/resplit-android/docs/play-store/data-safety-draft.md`
- `/tmp/resplit-android/docs/play-store/metadata-draft.md`
- `/tmp/resplit-android/docs/play-store/privacy-policy-android-p1.md`
- `/tmp/resplit-android/docs/play-store/privacy-policy-android-p1.html`
- `/tmp/resplit-android/docs/play-store/ship-checklist.md`
- `/tmp/resplit-android/docs/play-store-launch.md`
- `/tmp/resplit-android/docs/play-store/assets/play-icon-512.png` (`512x512`)
- `/tmp/resplit-android/docs/play-store/assets/feature-graphic-1024x500.png` (`1024x500`)

However, `/tmp/resplit-android/docs/play-store/screenshots/wave-1/` still contains `0` files.

### 6. Screenshot recapture is the remaining Android-lane artifact gap
The machine still has the named AVD `Pixel_3a_API_34_extension_level_7_arm64-v8a`, so screenshot capture is plausibly recoverable locally. But there is no fresh screenshot wave on disk yet, and this run did not create placeholder screenshots because that would weaken launch truth rather than restore it.

## Recommendations
- Keep Task E0 open, but narrow it to honest screenshot-wave recapture now that the workspace, wrapper, docs, and static assets are restored.
- Leave the owner-side Play submission boundary unchanged after screenshot recovery: public privacy-policy URL, signing/App Signing inputs, and final Play Console entry.
