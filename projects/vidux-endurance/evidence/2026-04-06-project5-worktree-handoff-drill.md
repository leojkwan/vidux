# 2026-04-06 Project 5 Worktree Handoff Drill

## Goal
Run the Project 5 two-hop worktree handoff drill against the endurance authority plan, prove that a second hop can resume from recorded disk state alone, and log any duplicate-worktree or stale-drift friction.

## Sources
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/PLAN.md`] Task 5.2, the `## Active Worktrees` checkpoint, the `[WORKTREE]` Decision Log entry, and the Cycle 10/11 Progress notes record the drill directly in the authority store.
- [Source: `/Users/leokwan/Development/vidux/SKILL.md`] The worktree handoff protocol requires register-on-entry, read-before-start resume, remove-on-completion, and stale detection after 3 no-progress cycles.
- [Source: `bash /Users/leokwan/Development/vidux/scripts/vidux-loop.sh /Users/leokwan/Development/vidux/projects/vidux-endurance/PLAN.md`, executed 2026-04-06 after the mid-task checkpoint] Returned `is_resuming: true`, `action: "execute"`, and `context: "Resuming in_progress task"` for Task 5.2.
- [Source: `git -C /Users/leokwan/Development/vidux worktree list --porcelain`, executed 2026-04-06] Reported the main repo worktree plus multiple detached Codex worktrees for the same repo.

## Findings

### 1. The two-hop resume worked from disk state
Hop 1 registered the live repo path (`/Users/leokwan/Development/vidux`) in `## Active Worktrees`, left Task 5.2 `in_progress`, and checkpointed the next-hop instruction in Progress. Hop 2 reread `PLAN.md`, reused the recorded path, and reached the evidence boundary without inventing a sibling worktree.

### 2. Duplicate-worktree risk is real in this repo
The repo already has several detached Vidux worktrees alongside the main checkout. That means the handoff protocol is not theoretical protection; without an explicit recorded path, a later automation could easily resume the same endurance lane from a different checkout and drift the store.

### 3. Active-worktree state is still documentary, not loop-mechanical
`vidux-loop.sh` resumed the task because it saw `[in_progress]`, but its JSON output did not surface the recorded worktree path or branch from `## Active Worktrees`. The second hop therefore depended on manually rereading `PLAN.md`, not on machine-readable loop output. The doctrine exists, but the current control plane does not enforce it.

### 4. The remove-on-boundary step cleans the store correctly
After the second hop completed, the plan removed the active-worktree claim and added a `[WORKTREE]` Decision Log entry explaining why the registration was abandoned. That leaves the authority store clean and makes the end of the drill auditable.

## Strength Surfaced
- The plan-as-store model is strong enough to carry a worktree path across hops without relying on chat memory or tool-local state.

## Friction Surfaced
- Path-aware resume is still manual. If an agent only reads `vidux-loop.sh` output and not the plan body, it can miss the active worktree metadata and create duplicate checkouts.

## Recommendations
- Extend `vidux-loop.sh` or `vidux-doctor.sh` to parse `## Active Worktrees` and expose the active path/branch in machine-readable output.
- Keep the `## Active Worktrees` protocol in the endurance harness even before tooling catches up; the drift risk is already real in a repo with many detached worktrees.
