# 2026-04-07 Resplit Local Fastlane Release Contract

## Goal
Correct the public Resplit control plane after a stale assumption treated GitHub Actions as the release gate even though the current Resplit shipping path is local fastlane.

## Sources
- [Source: `/Users/leokwan/Development/resplit-ios/CLAUDE.md`, read 2026-04-07] The repo's own workflow says distribution is Tuist Previews via `bundle exec fastlane beta` / `release`, and App Store flow is local archive + upload. It explicitly says `no Xcode Cloud`.
- [Source: `/Users/leokwan/Development/resplit-ios/fastlane/Fastfile`, read 2026-04-07] `lane :beta` builds `Resplit Debug` and shares a Tuist Preview; `lane :testflight_upload` performs local archive/export/upload + Friends & Family distribution; `lane :release` builds a release preview, tags `vX.Y.Z`, and can call `testflight_upload(testflight:true)`.
- [Source: `/Users/leokwan/Development/resplit-ios/ai/skills/release-train/SKILL.md`, read 2026-04-07 before correction] The release skill had drifted into a GitHub Actions mental model even though the repo's actual shipping lane is local fastlane.
- [Source: `/Users/leokwan/Development/ai/automations/resplit-launch-loop/automation.toml`, read 2026-04-07 before correction] The launch-loop harness still told the lane to reason about hosted CI/billing state instead of local fastlane preview/upload state.
- [Source: `ls -l /Users/leokwan/.private_keys /Users/leokwan/Development/resplit-ios/fastlane/AuthKey_32D626LB6H.p8`, run 2026-04-07] No Admin key file is currently present at the local ASC path.
- [Source: `security find-identity -v -p codesigning`, run 2026-04-07] This host currently exposes only Apple Development identities and no Apple Distribution identity.

## Findings

### 1. GitHub-hosted CI is no longer the Resplit release authority
The durable local sources agree that the canonical release boundary is local fastlane, not a hosted workflow trigger. `fastlane beta` is the preview/dogfood path; `testflight_upload` and `release testflight:true` are the Friends & Family path.

### 2. The real blockers are local ASC and export-signing prerequisites
The missing ASC Admin key at `~/.private_keys/AuthKey_32D626LB6H.p8` is a real blocker. Separately, this machine currently lacks Apple Distribution signing proof, so `ensure_testflight_export_prerequisites!` would still fail until Leo either restores a distribution cert or signs Xcode into an account that can satisfy cloud-managed signing for export.

### 3. The control-plane drift was in the harness and store, not in the product repo
The stale GitHub Actions story lived in the automation prompt, the nurse log summary, the public Vidux store, and the release-train skill. Those are the surfaces that needed correction so future loops stop chasing the wrong blocker.

## Recommendations
- Keep `resplit-launch-loop` focused on local fastlane preview/upload state, not GitHub workflow state.
- Treat Task 9 as local prerequisite clearing: restore `~/.private_keys/AuthKey_32D626LB6H.p8`, then satisfy export-signing proof on this host.
- Once those prerequisites pass, prefer the canonical local boundary: `bundle exec fastlane release version:X.Y.Z testflight:true` from clean trunk, with `bundle exec fastlane beta` only when fresh preview proof is needed first.
