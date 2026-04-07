# 2026-04-07 Android Workspace Provenance Audit

## Goal
Tighten Task E0 from "missing `/tmp` directory" to the more specific recovery truth: what kind of workspace `/tmp/resplit-android` actually was, and whether any local canonical restore source still exists.

## Sources
- [Source: archived Codex session `rollout-2026-04-05T19-14-20-019d5fed-0030-7303-a91a-537dd642c116.jsonl`, read 2026-04-07] `ls -la /tmp/resplit-android` showed a live Gradle project on `2026-04-05 23:14 UTC` with top-level files `build.gradle.kts`, `settings.gradle.kts`, `gradlew`, `gradle/`, and `app/`.
- [Source: same archived session, read 2026-04-07] `rg --files /tmp/resplit-android ...` showed the Android workspace contained a full Kotlin/Compose app tree including `app/src/main/java/com/resplit/android/...`, `app/src/androidTest/...`, Room DAOs/entities, theme files, and wrapper artifacts.
- [Source: archived Codex session `rollout-2026-04-06T19-12-58-019d6512-1bf3-7122-bc57-b6bc1de88244.jsonl`, read 2026-04-07] `git -C /tmp/resplit-android status --short` and `git -C /tmp/resplit-android log --oneline -10` both failed with `fatal: not a git repository`, while direct file reads from the same path succeeded.
- [Source: shell, 2026-04-07] `find /Users/leokwan/Development -maxdepth 4 \( -iname '*resplit*android*' -o -iname 'resplit-android*' -o -iname '*android*resplit*' \)` returned only the Vidux project store and automation definition.
- [Source: shell, 2026-04-07] Focused searches for matching repo config files and archives under `/Users/leokwan/Development`, `/Users/leokwan/Documents`, `/Users/leokwan/Downloads`, `/Users/leokwan/Desktop`, and `/Users/leokwan/.codex/worktrees` found no git remote/config containing `resplit-android` or `com.resplit.android`, and no `resplit-android*.zip` or tar archive.
- [Source: MCP `nia` resources/list, 2026-04-07] Nia still failed to initialize from Codex: `initialize response` connection closed.

## Findings

### 1. The missing workspace was real but unversioned
The archived session trail proves `/tmp/resplit-android` was a functioning Android project with Gradle wrapper, app code, tests, and docs. It also proves the workspace was not a git checkout at the moment it was last revalidated locally.

### 2. No local canonical restore source surfaced
Within the normal developer roots and current Codex worktrees, there is no surviving clone, bare repo, or archive whose naming or config points to the Android workspace. The only durable local artifacts still present are the Vidux plan/evidence store and the automation definition.

### 3. Recovery cannot honestly assume "just re-clone the repo"
The earlier blocker wording implied a canonical repo or archive probably existed somewhere. Current evidence weakens that assumption: the live workspace appears to have been built directly inside `/tmp`, then iterated there. Inference: the restore path is now either an explicit owner-provided source or a deliberate reconstruction from archived session artifacts, not a simple hidden checkout recovery.

## Recommendations
- Keep Task E0 blocked until a restore source is named explicitly.
- Treat archived session transcripts as provenance evidence, not yet as a canonical restore artifact.
- Do not rerun build/proof loops until `/tmp/resplit-android` is restored from a named source.
