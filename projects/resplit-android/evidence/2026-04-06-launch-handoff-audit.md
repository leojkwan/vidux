# Evidence — 2026-04-06 Launch Handoff Audit

## Why this snapshot exists
The original `resplit-android` authority store disappeared during the `vidux` repo split. This file rehydrates the current launch frontier from surviving automation memory, the live Android workspace in [`/tmp/resplit-android`](/tmp/resplit-android), and current official Android/Play guidance.

## Tooling note
- Nia-first check failed in this session because the `nia` MCP server would not initialize from Codex. Official-source fallback was used instead.

## Official-source findings
- Google Play Data safety requires every published app to complete the form and provide a privacy policy link, even if the app does not collect any user data: <https://support.google.com/googleplay/android-developer/answer/10787469?hl=en>
- Google Play defines `collect` as transmitting data off-device and excludes purely on-device processing from collected-data disclosure: <https://support.google.com/googleplay/android-developer/answer/10787469?hl=en>
- Android’s data-use guidance calls out backup workflows as a relevant data-use surface, which made the prior Auto Backup posture incompatible with a simple `no data collected` answer: <https://developer.android.com/privacy-and-security/declare-your-apps-data-use>
- Android app-version guidance allows the first release to start at `versionCode = 1`, but every later release must increment that integer: <https://developer.android.com/studio/publish/versioning>

## Workspace audit before correction
- [`/tmp/resplit-android/app/src/main/AndroidManifest.xml`](/tmp/resplit-android/app/src/main/AndroidManifest.xml) had `android:allowBackup="true"` plus explicit backup XML references. That undermined the Android harness promise of fully local/no-cloud behavior.
- The manifest declares no network permissions and no contact/camera runtime permissions.
- [`/tmp/resplit-android/app/build.gradle.kts`](/tmp/resplit-android/app/build.gradle.kts) includes no analytics, crash-reporting, or network client SDKs.
- [`/tmp/resplit-android/app/src/main/java/com/resplit/android/ui/receipt/ReceiptImageStore.kt`](/tmp/resplit-android/app/src/main/java/com/resplit/android/ui/receipt/ReceiptImageStore.kt) stores imported receipt images in app-local files.
- [`/Users/leokwan/Development/resplit-ios/resplit-web/app/privacy-policy/page.tsx`](/Users/leokwan/Development/resplit-ios/resplit-web/app/privacy-policy/page.tsx) still describes iCloud, analytics, and third-party services, so it cannot serve as Android P1 privacy/data-safety truth.

## Corrections landed this run
- Disabled Android Auto Backup in [`/tmp/resplit-android/app/src/main/AndroidManifest.xml`](/tmp/resplit-android/app/src/main/AndroidManifest.xml) and removed the unused backup XML files.
- Added operator-ready Play Console drafts:
  - [`/tmp/resplit-android/docs/play-store/data-safety-draft.md`](/tmp/resplit-android/docs/play-store/data-safety-draft.md)
  - [`/tmp/resplit-android/docs/play-store/privacy-policy-android-p1.md`](/tmp/resplit-android/docs/play-store/privacy-policy-android-p1.md)
- Updated the launch/checklist docs so the store package now reflects the stricter offline boundary:
  - [`/tmp/resplit-android/docs/play-store/ship-checklist.md`](/tmp/resplit-android/docs/play-store/ship-checklist.md)
  - [`/tmp/resplit-android/docs/play-store/metadata-draft.md`](/tmp/resplit-android/docs/play-store/metadata-draft.md)
  - [`/tmp/resplit-android/docs/play-store-launch.md`](/tmp/resplit-android/docs/play-store-launch.md)

## Verification
- Fresh serial proof passed after the correction:
  - `JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home ANDROID_HOME=$HOME/Library/Android/sdk ANDROID_SDK_ROOT=$HOME/Library/Android/sdk ./gradlew --no-daemon testDebugUnitTest assembleDebug assembleRelease bundleRelease assembleDebugAndroidTest`

## Verification refresh
- [2026-04-06 17:53 EDT] Re-ran the same serial proof command in [`/tmp/resplit-android`](/tmp/resplit-android); Gradle reported `BUILD SUCCESSFUL in 6s` with `130 actionable tasks: 2 executed, 128 up-to-date`.
- Reconfirmed the offline/package truth in local source:
  - [`/tmp/resplit-android/app/src/main/AndroidManifest.xml`](/tmp/resplit-android/app/src/main/AndroidManifest.xml) still sets `android:allowBackup="false"`.
  - [`/tmp/resplit-android/app/build.gradle.kts`](/tmp/resplit-android/app/build.gradle.kts) still sets `versionCode = 1` and `versionName = "1.0"`.
  - The Play launch handoff docs still exist under [`/tmp/resplit-android/docs/play-store/`](/tmp/resplit-android/docs/play-store/).
- Nia MCP was retried at session start and still failed to initialize from Codex (`initialize response` connection closed), so this run stayed on local workspace truth instead of new research.

## Current blocker shape
- Product/build truth is now aligned again: offline, no accounts, no cloud backup, no network SDKs.
- Remaining blockers are operator-owned:
  - publish or host the Android-specific privacy policy from the new draft
  - provide release signing / Play App Signing upload credentials
  - finish Play Console entry and declarations
