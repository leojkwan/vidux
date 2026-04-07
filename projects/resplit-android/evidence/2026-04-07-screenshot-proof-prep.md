# 2026-04-07 Screenshot Proof Prep

## Goal
Record the honest-proof blockers discovered while preparing the recovered Play screenshot wave from the restored Android workspace.

## Sources
- [Source: codebase grep] `/tmp/resplit-android/app/src/main/java/com/resplit/android/ui/home/HomeScreen.kt:141`
- [Source: codebase grep] `/tmp/resplit-android/app/src/main/java/com/resplit/android/ui/folder/FolderDetailScreen.kt:273`
- [Source: codebase read] `/tmp/resplit-android/app/src/main/java/com/resplit/android/data/entity/ReceiptEntity.kt`
- [Source: codebase read] `/tmp/resplit-android/app/src/main/java/com/resplit/android/data/dao/ReceiptDao.kt`
- [Source: iOS source truth] `/Users/leokwan/Development/resplit-ios/ReceiptSplitter/Calculators/ReceiptTotalCalculator.swift`
- [Source: local tool check] Android emulator AVD list via `$HOME/Library/Android/sdk/emulator/emulator -list-avds`
- [Source: MCP status] `nia` MCP resource listing attempt on 2026-04-07 failed during initialize handshake

## Findings

### 1. Screenshot recovery is unblocked on device availability
The local Android SDK still exposes the named AVD `Pixel_3a_API_34_extension_level_7_arm64-v8a`, so the next screenshot wave can be captured from a real emulator instead of fabricating static mock assets.

### 2. Home receipt cards currently show a false total
`HomeScreen.kt:141` renders `receipt.taxAmount + receipt.tipPercent` as the amount label. `ReceiptEntity` does not store a full total or subtotal, so this label is mathematically wrong for any populated receipt and would make Play screenshots dishonest.

### 3. Folder receipt cards currently show tax only
`FolderDetailScreen.kt:273` renders only `receipt.taxAmount` as the receipt amount chip. That is also inconsistent with real receipt totals and would make trip/folder screenshots misleading.

### 4. iOS parity truth expects totals derived from item sum plus tax and tip
The iOS reference uses `ReceiptTotalCalculator` to derive total from subtotal/items, tax, tip, and extras rather than reading a partial header field. Android should follow that same product truth before capturing the screenshot wave.

### 5. Nia remains unavailable in this Codex session
The required Nia-first check was attempted again through MCP resource listing, but the `nia` server still failed its initialize handshake. No ecosystem research decision is blocked on that failure for this slice, but it remains part of the run proof.

## Recommendations
- Fix the Android list/card amount rendering to compute total from receipt items plus tax and tip before capturing Play screenshots.
- After the fix, rerun the serial Android gate and then capture the screenshot wave from the local AVD into `docs/play-store/screenshots/wave-1/`.
