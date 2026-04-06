# Task 0.7: Phase 0 Design Review — Ready for Code Verdict

**Date:** 2026-04-05
**Reviewer:** Coordinator (synthesizing 5 subagent design documents)

## Documents Reviewed

1. `evidence/2026-04-05-two-machine-convergence.md` — Task 0.1 (convergence analysis)
2. `evidence/2026-04-05-vidux-loop-annotated-analysis.md` — Task 0.2 (code analysis)
3. `evidence/2026-04-05-dependency-matcher-fix-design.md` — Task 0.3 (dep matcher fix)
4. `evidence/2026-04-05-contradiction-detection-design.md` — Task 0.4 (contradiction detection)
5. `evidence/2026-04-05-control-plane-hygiene-design.md` — Task 0.5 (hygiene checks)
6. `evidence/2026-04-05-d6-enforcement-design.md` — Task 0.6 (D6 enforcement)

## Cross-Check: Conflicts Between Designs

### vidux-loop.sh modification map

| Design | What changes | Lines affected | Conflict? |
|--------|-------------|----------------|-----------|
| 0.3-A (DL-STUCK-TAG-BLIND) | Add `\|STUCK` to regex | Line 59 | None |
| 0.3-B (DEP-MATCHER-TRIPLE) | Replace dependency block | Lines 116-127 | None |
| 0.4 (contradiction detection) | Insert ~50 lines + helper func | After line 31 (func) + after line 99 (logic) | None |
| 0.6 (process_fix_declared) | Add field extraction | After line 114 | None |
| JSON output (0.4 + 0.6) | Add 4 new fields | Lines 220-241 + early-exit blocks (83, 89, 91) | **Coordinate** |

**No conflicts.** All modifications touch different sections. The JSON output block needs 4 new fields from two designs (3 from 0.4, 1 from 0.6) — these are independent additions to the same heredoc.

### Implementation order matters

Because 0.4 inserts ~50 lines after line 99, subsequent line numbers shift. Recommendation: **implement using string matching (Edit tool), not line numbers.** Apply in this order:
1. Fix 0.3-A (line 59 regex — tiny, non-disruptive)
2. Fix 0.3-B (lines 116-127 replacement — contained block)
3. Fix 0.4 helper function (after line 31 — top of file)
4. Fix 0.4 logic (after line 99 — uses string matching)
5. Fix 0.6 field extraction (after line 114 — uses string matching)
6. Update JSON output block (lines 220-241 — add all 4 new fields at once)
7. Update early-exit JSON blocks (lines 83, 89, 91)

### Separate scripts (no vidux-loop.sh conflict)

| Design | Script | Conflict? |
|--------|--------|-----------|
| 0.5 (hygiene) | New `vidux-doctor.sh` | None — separate file |
| 0.6 (process fix verification) | `vidux-checkpoint.sh` | None — separate file |

## Cross-Check: Backward Compatibility

| Change | Breaks existing plans? | Breaks existing JSON consumers? | Breaks contract tests? |
|--------|:---:|:---:|:---:|
| 0.3-A: `\|STUCK` in regex | No — additive pattern | No — DL_COUNT may increase for plans with `[STUCK]` entries (correct behavior) | No |
| 0.3-B: dep matcher rewrite | **Behavioral change** — unstructured tasks degrade to not-blocked (was false-blocked). Strictly better. | No | Verify: existing dep-related tests must still pass |
| 0.4: contradiction detection | No — optional `[Contradicts:]` tag | **Additive** — 3 new JSON fields. Consumers ignoring them are unaffected. | No |
| 0.6: process_fix_declared | No — optional `[ProcessFix:]` tag | **Additive** — 1 new JSON field | No |
| 0.5: vidux-doctor.sh | No — separate script | No | No |

**Verdict: No backward compatibility breakage.** The dep matcher behavioral change is strictly better (false negatives < false positives). All JSON changes are additive fields.

## Cross-Check: Bash Compatibility

| Feature | Bash version | Status |
|---------|-------------|--------|
| `${var,,}` lowercase | Bash 4+ only | **FIXED** — 0.3 design uses `grep -qi '^none$'` instead (Bash 3.2 safe) |
| Process substitution `<(...)` | Bash 3.2+ | OK — already used in existing script |
| `[[ ]]` tests | Bash 3.2+ | OK |
| `read -ra` (array) | Bash 3.2+ | OK |
| `comm -12` | POSIX | OK |
| `case` pattern matching | POSIX | OK |

**No Bash 3.2 issues** in the final designs.

## Cross-Check: Missing Edge Cases

### Found and resolved in designs

1. **Empty `[Depends: ]`** — handled (0.3: empty DEP_PART skipped)
2. **Multiple `[Depends:]` tags** — acknowledged limitation (only first is checked). Pre-existing, not in scope.
3. **`[STUCK]` entries in contradiction check** — handled (0.4: skipped by DL_TAG filter matching only DELETION/DIRECTION)
4. **Unicode in task descriptions** — handled (0.4: `tr -cs '[:alnum:]-'` works for English plans)
5. **Unstructured tasks (no `Task N:` prefix)** — handled (0.3: graceful degradation to not-blocked)

### Not covered but acceptable

1. **Concurrent modifications to PLAN.md** — if two agents checkpoint simultaneously, race condition on file writes. Out of scope for v2.3.0 (existing limitation, not introduced by these changes).
2. **Very large Decision Logs (100+ entries)** — performance untested at scale. Acceptable: real plans have 1-10 entries.

## Open Questions Status

- [x] Q1: Where do hygiene checks live? → `vidux-doctor.sh` (answered by 0.5)
- [x] Q2: Bash sufficient for contradiction detection? → Yes (answered by 0.4)
- [x] Q3: Stale threshold? → 3 calendar days since last Progress entry (answered by 0.5)

**No remaining open questions.**

## Verdict: READY FOR CODE

All 6 Phase 0 designs are complete, non-conflicting, backward-compatible, and Bash 3.2 safe. All open questions are answered. Implementation should proceed with Phase 1 (P0 fixes) in this order:

1. **Task 1.1**: Apply 0.3-A (DL-STUCK-TAG-BLIND, line 59) + 0.3-B (dep matcher, lines 116-127) to vidux-loop.sh
2. **Task 1.2**: Fix ResourceWarning in test_vidux_contracts.py line 983
3. **Task 1.3**: Run contract tests — all 63 must pass, ResourceWarning must be gone

Phase 1 implementation uses string-matching edits, not line-number edits, to avoid shift issues from insertion order.
