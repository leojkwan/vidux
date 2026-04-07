# 2026-04-07 Script Hardening Audit

## Goal
Identify security, portability, correctness, and performance issues across all vidux bash scripts.

## Sources
- [Source: codebase audit] All scripts in scripts/ and scripts/lib/
- [Source: agent audit] Systematic review of error handling, portability, security, performance

## Findings

### 1. SQL injection in vidux-fleet-rebuild.sh (CRITICAL)
`sqlite3 "$DB" "DELETE FROM automations WHERE id='$id';"` — string interpolation into SQL. Same pattern in codex-db.sh. Use parameterized queries via python3 instead.

### 2. json_escape doesn't handle backticks, $, or all RFC 8259 chars (HIGH)
Present in vidux-loop.sh:33-36, vidux-dispatch.sh:37-40, vidux-witness.sh:19-22, vidux-prune.sh:48-51. Task descriptions with backticks get shell-evaluated. Missing forward slash, null byte, unicode control char escaping. Fix: use `python3 -c "import json,sys; print(json.dumps(sys.argv[1]))"` or jq.

### 3. vidux-checkpoint.sh sed fails on regex metacharacters (HIGH)
Line 216: escapes &/\[] but misses .*+?(){}^$|. Task descriptions with parens or dots match wrong lines. Fix: grep -Fn for line number, sed by line number.

### 4. vidux-prune.sh uses macOS-only stat -f (HIGH portability)
Lines 193-196: `stat -f '%m'` is macOS-only. Linux needs `stat -c '%Y'`. Worktree age detection silently returns 0 on Linux. vidux-witness.sh line 193 has same issue with `date -j -f`.

### 5. Config parsing via python3 with interpolated path (HIGH security)
vidux-loop.sh:19-21, vidux-doctor.sh:45-52, vidux-prune.sh:31. Path containing single quote breaks Python string and allows code execution. Fix: pass path as sys.argv[1].

### 6. vidux-checkpoint.sh archive pipe race under pipefail (MEDIUM)
Line 118: `echo | head` pipe can exit 141 (SIGPIPE). Variable could end up empty, causing lines deleted from PLAN.md without being archived.

### 7. vidux-dispatch.sh merge-gate cd never returns (MEDIUM)
Lines 190, 219: uses `cd` for git operations. Fix: use `git -C "$dir"`.

### 8. vidux-doctor.sh non-atomic JSON assembly (MEDIUM)
Lines 63-64, 1158-1176. Concurrent doctor runs safe but python3 missing = silent failure.

### 9. Every config-reading script spawns multiple python3 processes (MEDIUM perf)
vidux-doctor.sh spawns 8 separate python3 calls to read 8 config values. ~50-100ms each. Fix: single python3 call for all values.

### 10. sedi append syntax fragile with / and & in content (MEDIUM portability)
vidux-loop.sh:322-323, vidux-checkpoint.sh:265-267. DL_ENTRY includes task descriptions with file paths (/) that break sed.

## Recommendations
- Priority 1: Fix json_escape (affects 4 scripts, corrupts JSON output)
- Priority 2: Fix config path injection (affects 3 scripts, security)
- Priority 3: Add portability layer for stat/date (affects 2 scripts)
- Priority 4: Fix checkpoint sed metacharacter handling
