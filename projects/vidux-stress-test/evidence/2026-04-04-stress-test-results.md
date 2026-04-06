# 2026-04-04 Vidux v2.1 Stress Test Results

## Goal
Validate that unified Vidux v2.1 handles nested planning, multiple investigation files, and the full unidirectional flow across repeated cycles.

## Sources
- [Source: test-web-project agent] /tmp/vidux-test-web/ — 3 cycles, 4 commits
- [Source: test-ios-project agent] /tmp/vidux-test-ios/ — 3 cycles, 3 commits
- [Source: stress-test cron cycles 0-2] skills/vidux/projects/vidux-stress-test/
- [Source: Nia research, langgraph + claude-code + crewai] evidence/2026-04-04-agent-orchestration-comparison.md
- [Source: debug-team, test-team, codex-team] 3 parallel swarm analyses

## Findings

### 1. Nested Planning Works End-to-End
Investigation routing in the ASSESS decision tree correctly identifies compound tasks via [Investigation:] markers. The Fix Spec gate prevents premature coding. Status propagation matches the SKILL.md table. Both web and iOS test scenarios passed all assertions.

### 2. Three-Strike Escalation Works
When 3+ tickets hit the same surface, the investigation correctly requires a full Impact Map before any code. Tested on the iOS popover amount-editor scenario.

### 3. Q-Gating Works
Global open questions do NOT block task execution unless their Q-ref appears in the task description. This prevents a growing Q-list from silently halting progress.

### 4. Vidux is Novel Among Surveyed Tools
Compared against LangGraph, CrewAI, Claude Agent SDK. No other tool has:
- Nested sub-task plans (investigations)
- Decision Log for anti-remediation-spam
- Evidence citation requirements
- Human-readable git-backed state

### 5. Codex Subagent Support Confirmed
Codex now has first-class subagent support: custom TOML agents, max_threads up to 24, max_depth configurable, per-agent model selection, CSV batch processing. Maps directly to Vidux fan-out pattern.

### 6. Three Friction Points Identified
1. `[in_progress]` too broad for compound tasks (investigating vs executing)
2. Atomic tasks starve behind multi-cycle compound tasks
3. Investigation stub timing unclear (GATHER vs pickup)

### 7. Two Doctrine Gaps Found
1. No worktree handoff protocol for incomplete cron work
2. Stuck-loop detection exists in vidux-loop.sh but harness doesn't mechanically enforce it

### 8. What Shipped This Session
- Unified v1+v2 into single /vidux (688 lines, down from 736)
- Wired investigation routing into command files
- Inlined investigation template in Doctrine 7
- Trimmed Doctrine 5 and 8 (moved reference material to guides)
- Deleted vidux_v1/ (7,600 lines of merge debris) and vidux-v2/
- Built vidux-install.sh with install/upgrade/doctor/version (13/13 checks pass)
- Upgraded pre-commit hook to accept FSM states
- 63/63 contract tests pass
- VERSION: 2.1.0

## Recommendations
- Ship v2.1.0 as-is (beta-quality, validated)
- Address friction points in v2.2.0
- Add Doctrine 9: subagent coordinator pattern
- Create Codex custom agents (.codex/agents/vidux-*.toml)
- Add worktree handoff to doctrine
- Wire stuck-loop enforcement in harness
