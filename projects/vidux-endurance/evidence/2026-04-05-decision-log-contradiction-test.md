# 2026-04-05 Decision Log Contradiction Test

## Goal
Verify that vidux-loop.sh surfaces Decision Log entries and test whether contradicting tasks are caught — mechanically or via LLM judgment.

## Sources
- [Source: `/tmp/vidux-declog-test/PLAN.md`] Synthetic plan with two Decision Log entries and a task that directly contradicts a `[DELETION]` entry.
- [Source: `vidux-loop.sh` lines 56-64] Decision Log parsing implementation.
- [Source: `SKILL.md` Doctrine anti-loop section] "Contradiction detection is LLM judgment — the script removes the excuse of 'I didn't know.'"

## Findings

### 1. Decision Log entries are correctly surfaced
vidux-loop.sh parses the `## Decision Log` section and outputs:
- `decision_log_count: 2` — correct count
- `decision_log_warning: true` — warning flag set
- `decision_log_entries` — full text of both entries preserved in JSON

### 2. Contradicting tasks are NOT mechanically blocked (by design)
Task 2 ("Re-add --verbose flag") directly contradicts `[DELETION] Removed legacy --verbose flag... Do not re-add.` The script returned `action: "execute"` anyway.

This is the intended design: the script surfaces entries so the LLM cannot claim ignorance, but contradiction detection is LLM judgment. The division of responsibility:
- **Script**: parse, surface, warn (mechanical)
- **LLM**: read entries, detect contradictions, refuse to execute (semantic)

### 3. New bug: `[Depends: none]` triggers false-positive blocking
When tasks include `[Depends: none]`, the dependency matcher (line 124) searches non-completed task lines for the literal string "none". Since `[Depends: none]` appears in multiple tasks, they self-match. This is the third variant of the dependency matcher bug:
- Bug 1 (found 2026-04-04): self-match on completed dependency IDs (e.g., "2.4")
- Bug 2 (found 2026-04-04): self-match on active task's own `[Depends: X]` text
- Bug 3 (found 2026-04-05): literal "none" matches other tasks containing "[Depends: none]"

**Root cause**: line 124 does `grep -qi "$DEP_TARGET"` against full task line text instead of matching against task identifiers. Fix should either:
- Skip dependency check when `DEP_TARGET` is "none" (case-insensitive)
- Match against task IDs only, not full task text

### 4. Grade: Decision Log enforcement
| Aspect | Result |
|--------|--------|
| Entry parsing | pass |
| Warning flag | pass |
| Entry text preservation | pass |
| Mechanical contradiction blocking | n/a (by design) |
| LLM contradiction awareness | pass (entries visible in JSON) |
| Overall | pass with design-acknowledged gap |

## JSON Output — Non-contradicting Task (Task 1)
```json
{
  "cycle": 1,
  "task": "Task 1: Add --log-level flag...",
  "action": "execute",
  "decision_log_count": 2,
  "decision_log_warning": true,
  "decision_log_entries": "[DELETION] ... [DIRECTION] ..."
}
```

## JSON Output — Contradicting Task (Task 2)
```json
{
  "cycle": 2,
  "task": "Task 2: Re-add --verbose flag for backward compatibility",
  "action": "execute",
  "decision_log_count": 2,
  "decision_log_warning": true,
  "decision_log_entries": "[DELETION] Removed legacy --verbose flag... Do not re-add. [DIRECTION] Chose SQLite..."
}
```

## Recommendations
- The current design (script surfaces, LLM judges) is reasonable for v2.2.0. Mechanical contradiction detection would require NLP/pattern matching beyond bash.
- Fix the dependency matcher triple-bug before v2.3.0 — it's the most impactful mechanical issue found across the endurance test.
- Consider adding a `[Depends: none]` short-circuit in the dependency checker as an immediate fix.
