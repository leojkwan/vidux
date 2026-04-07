# 2026-04-07 Project 8 Lane Contract

## Goal
Define the fake airport baggage exception desk lane so Project 8 can test one real `/tmp` code fix, one machine-auditable process fix, and one bounded two-role coordinator drill without reopening the Project 5 ownership leak.

## Sources
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/PLAN.md`] Task 8.1 requires a lane contract with one machine-auditable process fix and the exact proof artifact or command that verifies the process fix exists.
- [Source: `/Users/leokwan/Development/vidux/SKILL.md`] Doctrine 6 requires a durable process fix that makes the next run smarter, not only an immediate code repair.
- [Source: `/Users/leokwan/Development/vidux/SKILL.md`] Doctrine 9 requires one bounded slice per worker, serial fan-in, and a thin coordinator instead of a second orchestration loop.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project6-scorecard.md`] Project 6 proved a credible process fix, but the enforcement stayed documentary rather than machine-auditable.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project7-scorecard.md`] Project 7 cleaned up worker ownership, but the enforcement still depended on post-run auditing instead of a mechanical check.

## Findings

### 1. Project 8 should stay on one shared baggage-reconciliation defect
Use one fake root cause for the `/tmp` drill: a baggage desk reconciler that lets a late belt scan or duplicate load scan overwrite a manual reroute hold. That gives Worker A one bounded code surface while still forcing a real process-fix rule about replay and manual-override coverage.

### 2. The owned write surfaces are explicit
Use this contract for Task 8.2:

| Role | Owned write surface | Allowed writes |
|------|----------------------|----------------|
| Coordinator | `projects/vidux-endurance/PLAN.md` | Task state, Progress, Surprises, and closeout checkpoints only |
| Coordinator | `projects/vidux-endurance/evidence/2026-04-07-project8-lane-contract.md` | This contract note only |
| Coordinator | `projects/vidux-endurance/evidence/2026-04-07-project8-drill.md` | Fan-in synthesis, write audit, and proof summary only |
| Coordinator | `projects/vidux-endurance/evidence/2026-04-07-project8-scorecard.md` | Project 8 grading only |
| Coordinator | `$CODEX_HOME/automations/vidux-endurance/memory.md` | Final run note only, after the project boundary |
| Worker A | `/tmp/vidux-endurance-baggage/` | Fake baggage reconciler, regression tests, process-audit script, proof artifact, and test logs only |
| Worker B | `projects/vidux-endurance/evidence/2026-04-07-project8-process-audit.md` | Process-fix audit note only |

Rules:
- Worker A may not edit any repo file.
- Worker B may read `/tmp/vidux-endurance-baggage/` but may not write inside `/tmp`.
- No worker may edit `PLAN.md`, automation memory, or another role's owned surface.
- The coordinator may fan in only after rereading `PLAN.md`, Worker B's audit note, and the `/tmp` proof artifact from disk.

### 3. The machine-auditable process fix is named up front
Project 8 closes only if the baggage fixture contains both of these named regression cases:
- `test_duplicate_load_scan_does_not_reopen_manual_hold`
- `test_late_belt_scan_cannot_override_manual_reroute`

The proof command is:

```bash
python3 /tmp/vidux-endurance-baggage/audit_process_fix.py \
  --root /tmp/vidux-endurance-baggage \
  --output /tmp/vidux-endurance-baggage/proof/process_fix_audit.json
```

The proof artifact is:

```text
/tmp/vidux-endurance-baggage/proof/process_fix_audit.json
```

Passing audit criteria:
- `required_tests_present` is `true`
- `required_tests` lists both named regression cases
- `process_fix_rule` records that duplicate replay plus late manual-override precedence coverage is mandatory before closure

### 4. The acceptance gate must prove both code repair and process-fix proof
Task 8.2 only closes when all three checks pass:
- `python3 -m unittest discover -s /tmp/vidux-endurance-baggage -p 'test_*.py' -q`
- the `audit_process_fix.py` command above
- a repo write audit showing only the expected Project 8 coordinator/audit files changed inside `/Users/leokwan/Development/vidux`

## Recommendations
- Treat the audit command as the Doctrine 6 proof, not as optional supporting evidence.
- Keep Worker A repo-silent so the ownership audit cleanly distinguishes `/tmp` implementation from repo-local documentation.
- Fail Project 8 if the process-fix audit note lacks the exact JSON artifact path or if the proof command cannot be rerun from disk.
