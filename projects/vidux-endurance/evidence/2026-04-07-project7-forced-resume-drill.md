# 2026-04-07 Project 7 Forced-Resume Coordinator Drill

## Goal
Prove that the permit-board coordinator can checkpoint mid-fan-out, recover from disk-only state, fan in two worker-owned evidence slices, and avoid both ownership leaks and duplicate worktree creation.

## Sources
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/PLAN.md`] Task 7.2 requires a forced-resume drill using `PLAN.md` plus recorded evidence paths as the recovery source of truth.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project7-harness-ownership.md`] Task 7.1 defined the evergreen harness and the exact ownership contract for the coordinator and two workers.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project7-slice-intake-completeness.md`] Worker A's bounded intake-completeness slice.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project7-slice-routing-status.md`] Worker B's bounded routing/status slice.
- [Source: `git -C /Users/leokwan/Development/vidux worktree list`, executed 2026-04-07 before and after recovery] Worktree inventory used to verify no new sibling worktree was created during the drill.
- [Source: `git -C /Users/leokwan/Development/vidux status --short -- projects/vidux-endurance/PLAN.md projects/vidux-endurance/evidence/2026-04-07-project7-harness-ownership.md projects/vidux-endurance/evidence/2026-04-07-project7-slice-intake-completeness.md projects/vidux-endurance/evidence/2026-04-07-project7-slice-routing-status.md`, executed 2026-04-07] Repo write audit showing only the expected Project 7 plan/evidence surfaces changed during the worker drill.
- [Source: `stat -f '%Sm %N' -t '%Y-%m-%d %H:%M:%S' /Users/leokwan/.codex/automations/vidux-endurance/memory.md`, executed 2026-04-07] Automation-memory timestamp remained `2026-04-06 20:15:53`, so neither worker leaked into the memory file during fan-out.

## Findings

### 1. The recovery hop worked from disk-only state
After the mid-fan-out checkpoint, the coordinator reread `PLAN.md`, the harness/ownership note, and the recorded worker-file paths before looking at worker output. Both worker evidence files were discoverable from the checkpoint line alone, which is the core Doctrine 5 proof this slice needed.

### 2. The workers respected the explicit ownership contract
Worker A returned only the intake-completeness file and Worker B returned only the routing/status file. The repo write audit showed only the expected Project 7 plan plus the three evidence files, and the automation-memory timestamp stayed unchanged from the prior run. That is a clean contrast with the Project 5 ownership leak.

### 3. The coordinator recovered without creating a duplicate worktree
`git worktree list` before the checkpoint and during the recovery hop showed the same inventory: the main repo at `/Users/leokwan/Development/vidux` plus the pre-existing detached Codex worktrees. No sibling permit-board worktree appeared during resume, so the drill passed its duplicate-worktree check.

### 4. The remaining friction is still post-hoc enforcement
This was a cleaner Doctrine 9 result than Project 5, but the protection is still contractual rather than mechanical. The workers stayed in bounds because the ownership table was explicit and the coordinator audited the result afterward, not because Vidux mechanically sandboxes the write set.

## Verdict
- recovery from `PLAN.md`: pass
- worker ownership: pass
- duplicate-worktree avoidance: pass
- mechanical enforcement: pass with friction

## Recommendations
- Keep the explicit ownership table in the harness note whenever a coordinator drill uses subagents.
- Treat the mid-fan-out checkpoint line as mandatory whenever recovery is part of the doctrine under test.
- Add a future machine check that compares actual touched files against the ownership contract so D9 enforcement does not rely only on post-run auditing.
