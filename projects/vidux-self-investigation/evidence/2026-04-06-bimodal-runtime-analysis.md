# 2026-04-06 Bimodal Runtime Analysis

## Goal
Verify that the "keep working through queue" change to /vidux produces bimodal runtime behavior: quick checks (<2 min) or deep runs (>15 min), not 3-8 min stick-rubbing.

## Sources
- [Source: commands/vidux.md, section 3 ACT] "Keep working through the queue until you hit a real boundary"
- [Source: commands/vidux.md, section 5 DIE] "Stop only when you've hit a real boundary"
- [Source: lkwan feedback, 2026-04-06] "automations aren't creating fire — rubbing for 5 minutes but not doing anything meaningful"
- [Source: scripts/vidux-doctor.sh, CHECK 11] New bimodal runtime check added

## Findings

### 1. The Root Cause of 3-8 Min Runs
Old /vidux command said: "Do exactly one owned lane this cycle" and "land the smallest verified slice."
This created a predictable pattern:
- Agent reads PLAN.md (~30s)
- Agent finds one small task (~30s)
- Agent makes a minimal change (~2-3 min)
- Agent checkpoints and exits (~1 min)
- Total: 3-5 minutes. Every run. No deep work ever happened.

### 2. The Fix
New /vidux command says:
- "Keep working through the queue until you hit a real boundary"
- "Do NOT stop after one task. Do NOT 'land the smallest verified slice.'"
- Full e2e per task: ideate → plan → dev → test → QA → commit
- Real boundaries: build failure, blocked task, context window running low, all tasks done

### 3. Expected Bimodal Distribution
With the fix, runs should follow this pattern:

**Quick exits (<2 min):**
- All tasks [completed] → verify final state, exit
- All tasks [blocked] → log status, escalate, exit
- Plan needs evidence but no MCP available → log, exit
- Nothing changed since last cycle → noop, exit

**Deep runs (>15 min):**
- Multiple pending tasks with evidence → execute task 1, then task 2, then task 3...
- Compound task with investigation → research, write investigation, then code
- Plan creation from scratch → fan-out research, synthesize, write PLAN.md

**Dead zone (3-8 min) should only occur when:**
- Single small task remaining (legitimate, not a pattern problem)
- External dependency check that takes exactly 3-5 min (rare)

### 4. Enforcement Mechanism
vidux-doctor.sh CHECK 11 now detects dead-zone patterns:
- Parses git commit timestamps on PLAN.md to estimate cycle duration
- Flags projects where >30% of runs fall in the 3-8 min range
- Reports as a warning with per-project breakdown (dead-zone count, percentage, median)
- Works in both human-readable and JSON output modes

### 5. Validation
- Doctor runs clean with 11/11 checks
- Bimodal check correctly reports "pass" when no dead-zone patterns exist
- The check is conservative: only flags when >30% of runs are in dead zone
- Uses git log timestamps (accurate) rather than Progress section timestamps (may be approximate)

## Recommendations
- Monitor bimodal check results after deploying to production automations
- Consider adding the check to the coordinator automation (Doctrine 8 coordinator pattern)
- The 30% threshold may need tuning based on real fleet data — start conservative, tighten later
