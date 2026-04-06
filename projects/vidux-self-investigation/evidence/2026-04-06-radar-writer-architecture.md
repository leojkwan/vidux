# Radar → Writer Feedback Architecture

**Date:** 2026-04-06
**Source:** radar-writer-arch agent (codebase + web research)

## Architecture: FINDINGS/ as Action Bus

```
Radars write findings → CONSOLIDATED.md → Writer claims → PLAN.md task → Fix → Decision Log
```

### Findings Directory Structure
```
vidux/FINDINGS/
  ux-radar/
    2026-04-06_05-35_run.md
    2026-04-06_05-35_evidence/
    memory.md
  perf-radar/
    ...
  CONSOLIDATED.md (all radars, deduplicated, prioritized)
```

### Finding Format
- Status: new | acknowledged | fixed | declined
- Severity: critical | high | medium | low
- Handoff status: unclaimed | claimed-by-[writer] | staged-in-[task-id]

### Writer Pickup (Pull-from-CONSOLIDATED)
1. Writer reads CONSOLIDATED.md once per cycle at startup
2. Claims highest-priority unclaimed finding
3. Generates compound task in PLAN.md
4. Full e2e: investigate → plan fix → test → commit

### Bidirectional Feedback
- Writer marks finding `fixed` with commit hash + regression test link
- Writer can `decline` with Decision Log entry (prevents radar re-flagging)
- Coordinator watches for unclaimed findings > 2 cycles → escalates

### Redux Analogy
- FINDINGS/ = actions dispatched by radars
- CONSOLIDATED.md = action queue (deduped, sorted)
- PLAN.md = store (writer reduces findings into tasks)
- Coordinator = supervisor (watches quality, adjusts focus)

### Key Rules
- Radars never touch PLAN.md directly — only write to FINDINGS/
- Writers claim from CONSOLIDATED, don't create work from thin air
- Decision Log entries prevent radars from re-surfacing declined findings for 2 weeks
- Compound tasks created when multiple radars flag same surface
