# Phase 3 Refresh And Doctor Repo Fix

**Date:** 2026-04-06
**Goal:** Re-run Phase 3 verification on fresh `/tmp` fixtures, validate current live plans against the 2026-04-05 baseline, and fix any new regressions found during that refresh.

## Sources
- [Source: baseline scorecard, 2026-04-05] `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-05-final-endurance-scorecard.md`
- [Source: other-machine scorecard, 2026-04-05] `/Users/leokwan/Desktop/vidux-endurance/evidence/2026-04-05-batch-1-scorecard-and-vnext.md`
- [Source: current script read, 2026-04-06] `/Users/leokwan/Development/vidux/scripts/vidux-loop.sh`
- [Source: current doctor read, 2026-04-06] `/Users/leokwan/Development/vidux/scripts/vidux-doctor.sh`
- [Source: current contract suite, 2026-04-06] `/Users/leokwan/Development/vidux/tests/test_vidux_contracts.py`
- [Source: current doctrine read, 2026-04-06] `/Users/leokwan/Development/vidux/SKILL.md`
- [Source: fresh `/tmp` verification bundle, 2026-04-06] `/tmp/vidux-v230-2026-04-06-postfix`
- [Source: extra `/tmp` contradiction + mixed-format bundle, 2026-04-06] `/tmp/vidux-v230-2026-04-06-extra`
- [Source: live plan runs, 2026-04-06] `bash scripts/vidux-loop.sh projects/vidux-v230/PLAN.md`, `bash scripts/vidux-loop.sh projects/resplit-android/PLAN.md`, `bash scripts/vidux-loop.sh projects/context-ops/PLAN.md`

## Findings

### 1. Fresh `/tmp` verification still proves the core v2.3.x fixes

Post-fix refresh bundle `/tmp/vidux-v230-2026-04-06-postfix` returned **8/8 PASS**:

1. dependency multi-dep blocking still stops on the first unresolved dependency (`Waiting on: 0.4`)
2. contradiction warning still fires for `[DELETION]` overlap
3. stuck-loop still auto-blocks and writes a readable `[STUCK]` entry
4. `vidux-doctor.sh --repo` now blocks merge conflicts in a temp repo
5. live `vidux-v230` output still includes contradiction fields
6. live `resplit-android` output still includes contradiction fields
7. live `context-ops` output still includes contradiction fields
8. historical `perf-investigation/PLAN.md` is now absent and returns `{"error":"no plan found","action":"create_plan"}`

Extra `/tmp` bundle `/tmp/vidux-v230-2026-04-06-extra` returned **8/8 PASS**:

1. contradiction overlap case fires
2. explicit `[Contradicts: DL-1]` tagging fires and populates `contradicts_tag`
3. `[RATE-LIMIT]`-only plans do not false-flag contradiction
4. plans without `## Decision Log` keep contradiction fields false/empty
5. v1 checkbox + v2 FSM mixed plans execute cleanly
6. sparse plans without Progress/Decision Log execute cleanly
7. empty tasks plans return `action: "create_tasks"`
8. large plans degrade gracefully and emit context archival advice

### 2. New bug found: `vidux-doctor.sh --repo` was only half-scoped

Fresh validation exposed a new runtime bug that yesterday's evidence did not cover:

- A temp repo with `projects/test-conflict/PLAN.md` containing merge conflict markers returned `plan_merge_conflicts: pass` and exit code `0`.
- Root cause: `--repo PATH` updated `REPO`, but `VIDUX_ROOT`, `CONFIG`, and `PROJECTS_DIR` remained pinned to the script checkout. Worktree/automation checks used the target repo, while project-plan checks still scanned the home checkout.
- Impact: `vidux-doctor.sh --repo <temp-repo>` could miss the exact cross-repo conflict case Task 3.2f was meant to prove.

### 3. Fix shipped: repo scoping now follows the resolved target repo

Changed in `scripts/vidux-doctor.sh`:

- resolve `REPO` to an absolute path after arg parsing
- derive `VIDUX_ROOT`, `CONFIG`, `PROJECTS_DIR`, and `AUTOMATIONS_DIR` from that resolved repo

Changed in `tests/test_vidux_contracts.py`:

- added `test_doctor_repo_flag_rescopes_project_scan`
- contract creates a temp repo with `projects/test-conflict/PLAN.md`
- asserts `--repo <temp>` returns exit code `1` and `plan_merge_conflicts == block`

### 4. Post-fix verification is measurably better than the baseline

- Contract suite moved from **63/63** on 2026-04-05 to **84/84** on 2026-04-06, still with zero warnings.
- The new 2026-04-06 temp-repo merge-conflict case was **failing before the fix** and **passes after the fix**.
- Live-plan verification is fresher than the baseline:
  - `vidux-v230`: still selects the Phase 3 execution lane cleanly
  - `resplit-android`: now surfaces a task-linked open question and correctly returns `action: "refine"` instead of pretending execution can continue
  - `context-ops`: current live pressure plan executes and surfaces contradiction matches as designed
- Historical `perf-investigation/PLAN.md` is no longer present in `projects/`; this is repo drift, not a loop crash. It needs a replacement live plan or an archival decision in the mega-plan.

## Contract Suite

```text
----------------------------------------------------------------------
Ran 84 tests in 13.084s

OK
```

## SKILL.md Doctrine Check

The current `SKILL.md` is aligned with the shipped behavior:

- Prompt Amplification section is present and uses `GATHER -> AMPLIFY -> PRESENT -> STEER -> FIRE`
- skip rules are explicit for cron, `[in_progress]`, and `"fire"/"go"/"continue"/"keep going"`
- contradiction detection is documented as mechanical keyword overlap + explicit tag recognition, not LLM-only
- stuck-loop section documents `[STUCK]` Decision Log writes and `auto_blocked: true`
- Companion Skills table includes `vidux-doctor.sh`
- There is no separate `/vidux-amp` skill anymore; the built-in section explicitly says "no separate `/vidux-amp` needed"

## Conclusion

The 2026-04-06 refresh found one real regression hole in the control plane, fixed it, and proved the fix with a new contract plus fresh `/tmp` and live-plan verification. This is measurable improvement over the 2026-04-05 baseline, not just a re-run of yesterday's green checks.
