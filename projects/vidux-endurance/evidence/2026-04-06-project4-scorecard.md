# 2026-04-06 Project 4 Scorecard

## Goal
Grade Project 4 (Resplit Android) on all 9 Vidux doctrines after reconciling the stale endurance parent queue against the child Android authority store and verifying the current owner-blocked launch boundary.

## Sources
- [Source: `projects/resplit-android/PLAN.md`] Canonical child store for the Android lane, including the recovery note and the active owner-blocked queue (`Task E1`, `Task E2`).
- [Source: `projects/resplit-android/evidence/2026-04-06-launch-handoff-audit.md`] Launch-handoff audit, offline-truth correction, and prior serial Android proof.
- [Source: `/tmp/resplit-android/app/src/androidTest/java/com/resplit/android/ResplitUiTest.kt`] Core seeded UI-flow coverage for home, trips/settlement, and people flows.
- [Source: `/tmp/resplit-android/app/build/outputs/androidTest-results/connected/debug/TEST-Pixel_3a_API_34_extension_level_7_arm64-v8a(AVD) - 14-_app-.xml`] Connected emulator result timestamped `2026-04-06T18:44:50`: 8 tests, 0 failures, 0 errors, 0 skipped.
- [Source: `JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home ANDROID_HOME=$HOME/Library/Android/sdk ANDROID_SDK_ROOT=$HOME/Library/Android/sdk ./gradlew --no-daemon testDebugUnitTest assembleDebug assembleRelease bundleRelease assembleDebugAndroidTest`, executed 2026-04-06 in `/tmp/resplit-android`] Returned `BUILD SUCCESSFUL in 8s` with `130 actionable tasks: 2 executed, 128 up-to-date`.
- [Source: `python3 -m unittest discover -s /Users/leokwan/Development/vidux/tests -p 'test_*.py' -q`, executed 2026-04-06] Vidux contract suite passed 83/83 tests.

## Findings

### 1. Doctrine 1 -- Plan is the store: pass
Project 4 only made sense once the endurance parent queue stopped pretending `Task 4.2` was still active and deferred to the child store in `projects/resplit-android/PLAN.md`. That child plan already held the real boundary (`Task E1` and `Task E2` blocked on owner Play submission inputs), so the correct move was to repair the parent queue, not reopen Android implementation work.

### 2. Doctrine 2 -- Unidirectional flow: pass
This recovery slice followed gather -> verify -> checkpoint cleanly. The run read the child plan and launch audit, verified current Android proof in `/tmp/resplit-android`, reran the serial Gradle gate and Vidux contract suite, then wrote the scorecard back into endurance evidence before mutating the parent plan.

### 3. Doctrine 3 -- 50/30/20 split: friction
Project 4 still skewed toward burst implementation first and plan repair later. The recovered boundary is disciplined, but the overall project life did not stay close to a balanced planning/coding/last-mile split. This remains the doctrine most at risk once Vidux leaves synthetic exercises and touches a real product lane.

### 4. Doctrine 4 -- Evidence over instinct: pass
Every claim in this closeout is grounded in disk evidence: the child plan's blocked queue, the launch audit, the `ResplitUiTest` source, the connected-test XML, the fresh Gradle gate, and the fresh contract run. No Android status was inferred from memory alone.

### 5. Doctrine 5 -- Design for completion: pass
The original Android authority path disappeared during the repo split, but the project still resumed cleanly because the surviving child plan and launch audit preserved the state needed to understand the true boundary. This is the strongest Project 4 proof that Vidux can survive context loss and path churn in a real lane.

### 6. Doctrine 6 -- Process fixes > code fixes: pass
The most valuable outcome was not the Android code itself; it was the operator handoff package and the plan repair. Disabling Auto Backup mattered, but the durable gain was tightening the offline/privacy contract, drafting Android-specific Play submission docs, and codifying that child stores override stale parent queues.

### 7. Doctrine 7 -- Bug tickets are investigations: minimal exercise
Project 4 did not center on a multi-ticket bug surface or a nested investigation tree. The lane closed on a launch handoff boundary instead of a bug-cluster root-cause analysis.

### 8. Doctrine 8 -- Cron prompts are harnesses, not snapshots: minimal exercise
This project produced a strong operator handoff, but it did not author or evaluate a new evergreen harness prompt. That doctrine remains under-tested in real-product mode.

### 9. Doctrine 9 -- Subagent coordinator pattern: minimal exercise
No subagent fan-out was required to reconcile the Project 4 boundary. The coordinator pattern remains better-tested in Project 1 than in this real Android lane.

## Summary Table

| Doctrine | Grade | Notes |
|----------|-------|-------|
| D1: Plan is the store | pass | Child Android plan overruled stale parent queue |
| D2: Unidirectional flow | pass | Gather -> verify -> evidence -> parent-plan repair |
| D3: 50/30/20 split | friction | Real-product burst still outpaced store-first discipline |
| D4: Evidence over instinct | pass | Child plan, audit, XML, Gradle, and contracts all cited |
| D5: Design for death | pass | Repo-split recovery still resumed cleanly from disk |
| D6: Process fixes > code fixes | pass | Launch docs and queue-repair rule mattered more than code |
| D7: Bug tickets are investigations | minimal exercise | No bug-cluster investigation drove the lane |
| D8: Cron harnesses not snapshots | minimal exercise | No new harness prompt was authored here |
| D9: Subagent coordinator | minimal exercise | No fan-out needed for this closeout slice |

## Verification Notes
- Current connected-device proof is same-day on-disk evidence, not a fresh rerun in this shell. `adb` was available only by absolute SDK path and no device was attached during this run, so the honest proof boundary is:
  - connected suite already passed earlier on `2026-04-06T18:44:50`
  - fresh serial Android gate passed again in this run
  - fresh Vidux contract suite passed again in this run
- This is still sufficient to close the fake project because the child plan's boundary is owner-blocked Play submission, not an active Android implementation lane.

## Strength Surfaced
- Real child-plan recovery worked. Even after path churn from the repo split, Vidux could resume from the surviving plan/evidence pair and avoid redundant Android work.

## Friction Surfaced
- Parent/child store drift is real. The endurance parent plan lagged behind the child store and would have reopened solved work without this reconciliation pass.

## Recommendations
- Add an explicit "child plan wins" rule to the endurance control loop whenever a fake project owns its own `PLAN.md`.
- For real-product fake lanes, snapshot key connected-test results into endurance evidence on the same run so proof does not depend on long-lived `/tmp` build artifacts alone.
- Use the next fake project to stress the doctrines Project 4 barely touched: D3, D8, and D9, with explicit worktree handoff as part of the setup.
