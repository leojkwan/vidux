# 2026-04-07 Project 9 Forced-Resume Drill

## Goal
Prove that the claims-desk coordinator can checkpoint mid-fan-out, recover from `PLAN.md` only, fan in two worker-owned evidence slices, and use a machine audit that covers both repo writes and the canonical automation-memory surface.

## Sources
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/PLAN.md`] Task 9.2 requires a forced-resume coordinator drill that recovers from `PLAN.md` and verifies a machine check over repo plus explicit off-repo surfaces.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project9-harness-ownership.md`] Task 9.1 defined the evergreen harness, worker ownership contract, and the canonical automation-memory path for this machine.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project9-slice-fnol-severity.md`] Worker A's bounded FNOL, catastrophe-severity, and fraud-hold slice.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project9-slice-adjuster-status.md`] Worker B's bounded adjuster-assignment, field-inspection, and claimant-status slice.
- [Source: `find /Users/leokwan/Development/vidux/projects/vidux-endurance -type f -newer /tmp/vidux-endurance-claims/project9-baseline.ts | sort`, executed 2026-04-07] Repo write-scope audit after fan-out.
- [Source: `find /Users/leokwan/Development/ai/automations/vidux-endurance -type f -newer /tmp/vidux-endurance-claims/project9-baseline.ts | sort`, executed 2026-04-07] Canonical automation-memory audit after fan-out.
- [Source: `git -C /Users/leokwan/Development/vidux worktree list`, executed 2026-04-07 before and after recovery] Worktree inventory used to verify no duplicate claims worktree was created during the drill.
- [Source: `stat -f 'mtime=%Sm size=%z path=%N' -t '%Y-%m-%d %H:%M:%S' /Users/leokwan/Development/ai/automations/vidux-endurance/memory.md`, executed 2026-04-07 before and after recovery] Automation memory stayed at `2026-04-06 20:58:20`, so no worker leaked into the coordinator-only off-repo surface.

## Findings

### 1. The recovery hop worked from `PLAN.md` plus recorded worker paths
After the checkpoint, the coordinator reread `PLAN.md` and used the recorded `Cycle 19` resume instruction to locate the two worker evidence files from disk. No fan-in step depended on chat memory, which is the main Doctrine 5 proof this project needed.

### 2. The machine audit now covers repo and off-repo ownership in one pass
The repo write-scope audit listed exactly two files touched after the baseline timestamp:
- `projects/vidux-endurance/evidence/2026-04-07-project9-slice-adjuster-status.md`
- `projects/vidux-endurance/evidence/2026-04-07-project9-slice-fnol-severity.md`

The canonical automation-memory audit returned no touched files after the same baseline. That closes the exact blind spot Project 8 exposed: the coordinator can now verify both repo-local and external-path ownership without trusting a repo-only audit.

### 3. The workers stayed inside their owned slices and the worktree inventory stayed flat
Worker A remained inside the FNOL/severity/fraud boundary and Worker B remained inside the adjuster/inspection/status boundary. `git worktree list` before and after fan-out matched exactly, so the resume hop did not create a sibling claims worktree.

### 4. The remaining friction is still post-hoc enforcement, not live sandboxing
Project 9 is a stronger Doctrine 9 result than Project 8 because the machine audit now includes the off-repo memory surface, but the check still runs after the workers finish. Vidux can detect the wrong write set here; it still does not prevent it at execution time.

## Verdict
- recovery from `PLAN.md`: pass
- worker ownership: pass
- external-path machine audit: pass
- duplicate-worktree avoidance: pass
- mechanical enforcement: pass with friction

## Recommendations
- Use the Project 9 audit shape as the new reference for any coordinator drill that reserves off-repo surfaces like automation memory.
- Keep the baseline timestamp step mandatory so repo writes and off-repo writes share the same audit window.
- Treat live write prevention as the next real Doctrine 9 frontier; Project 9 proves detection, not sandboxing.
