# Resplit Automation Skill Surface

## Purpose
Inventory the actual skill surface available to Resplit recurring automations so the loops stop hand-waving “review the UX” and instead route each lane through named specialists that really exist on this host.

## Evidence
- [Source: `/Users/leokwan/Development/resplit-ios/ai/skills`, read 2026-04-06] Repo-local skills available inside the Resplit checkout: `figma-implement-design`, `hooks`, `picasso`, `release-train`, `sentry-triage`, and repo-local `vidux`.
- [Source: `/Users/leokwan/Development/ai/skills`, read 2026-04-06] Shared host skills available to Codex for Resplit include orchestration (`vidux`, `pilot`, `ledger`, `captain`, `ralph`, `multithready`), iOS and product engineering (`bigapple`, `xcodebuild`, `tuist`, `brand-resplit`, `resplit-engineering`, `swift-concurrency`, `fx`), proof/research (`figma`, `playwright`, `posthog-analytics`, `seo`, `clipdiff`, `dead-code-sweep`), and broader Sentry workflows.
- [Source: current Codex skill registry for this session, checked 2026-04-06] The host currently exposes `vercel:react-best-practices`, `vercel:agent-browser`, and `vercel:agent-browser-verify`, but does not expose the old `build-web-apps:*` or `build-ios-apps:*` plugin skills that earlier prompts referenced.
- [Source: user directives on 2026-04-01 and 2026-04-06] The recurring automations should keep UX/UI pressure high, explicitly route through Vidux and Picasso, and avoid vague “audit the UX” prompts that do not name the actual proof or specialist stack.

## Orchestration Spine
- `vidux` — `/Users/leokwan/Development/ai/skills/vidux/SKILL.md`
- `pilot` — `/Users/leokwan/Development/ai/skills/pilot/SKILL.md`
- `ledger` — `/Users/leokwan/Development/ai/skills/ledger/SKILL.md`
- `captain` — `/Users/leokwan/Development/ai/skills/captain/SKILL.md`
- `ralph` — `/Users/leokwan/Development/ai/skills/ralph/SKILL.md`
- `multithready` — `/Users/leokwan/Development/ai/skills/multithready/SKILL.md`

## Native UX / SwiftUI Stack
- repo-local `picasso` — `/Users/leokwan/Development/resplit-ios/ai/skills/picasso/SKILL.md`
- `bigapple` — `/Users/leokwan/Development/ai/skills/bigapple/SKILL.md`
- `xcodebuild` — `/Users/leokwan/Development/ai/skills/xcodebuild/SKILL.md`
- `tuist` — `/Users/leokwan/Development/ai/skills/tuist/SKILL.md`
- `brand-resplit` — `/Users/leokwan/Development/ai/skills/brand-resplit/SKILL.md`
- `resplit-engineering` — `/Users/leokwan/Development/ai/skills/resplit-engineering/SKILL.md`
- `swift-concurrency` — `/Users/leokwan/Development/ai/skills/swift-concurrency/SKILL.md`

## Web / Parity Stack
- `playwright` — `/Users/leokwan/Development/ai/skills/playwright/SKILL.md`
- `vercel:react-best-practices` — available through the Vercel plugin in this Codex environment
- `vercel:agent-browser` — available through the Vercel plugin in this Codex environment
- `vercel:agent-browser-verify` — available through the Vercel plugin in this Codex environment

## Design / Research / Proof Stack
- `figma` — `/Users/leokwan/Development/ai/skills/figma/SKILL.md`
- repo-local `figma-implement-design` — `/Users/leokwan/Development/resplit-ios/ai/skills/figma-implement-design/SKILL.md`
- repo-local `hooks` — `/Users/leokwan/Development/resplit-ios/ai/skills/hooks/SKILL.md`
- repo-local `release-train` — `/Users/leokwan/Development/resplit-ios/ai/skills/release-train/SKILL.md`
- repo-local `sentry-triage` — `/Users/leokwan/Development/resplit-ios/ai/skills/sentry-triage/SKILL.md`
- `sentry-workflow` — `/Users/leokwan/Development/ai/skills/sentry-workflow/SKILL.md`
- `posthog-analytics` — `/Users/leokwan/Development/ai/skills/posthog-analytics/SKILL.md`
- `seo` — `/Users/leokwan/Development/ai/skills/seo/SKILL.md`
- `fx` — `/Users/leokwan/Development/ai/skills/fx/SKILL.md`
- `clipdiff` — `/Users/leokwan/Development/ai/skills/clipdiff/SKILL.md`
- `dead-code-sweep` — `/Users/leokwan/Development/ai/skills/dead-code-sweep/SKILL.md`

## Routing Rules
- iOS UI, SwiftUI, simulator, or “why does this screen feel wrong?” work must route through repo-local `picasso` plus at least one native proof skill such as `xcodebuild` or `bigapple`.
- Web-facing, marketing, or parity-sensitive UX work must route through `playwright` plus at least one of `vercel:react-best-practices`, `vercel:agent-browser`, or `vercel:agent-browser-verify`.
- Design-token, motif, or copy-hierarchy work must route through `brand-resplit`.
- Figma URLs, screenshots, or fidelity-sensitive implementation work must route through `figma` or repo-local `figma-implement-design`.
- Release, upload, TestFlight, or screenshot-capture work must route through repo-local `release-train` and repo-local `hooks`.
- If a recurring lane cannot name the specialist stack it is using, it is not ready to execute.
