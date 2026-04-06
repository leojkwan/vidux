# 2026-04-05 D6 Enforcement Design — Process Fix Verifiability

## Goal
Design a mechanism for Vidux to mechanically verify that a "process fix" is enforceable (produces a machine-checkable artifact) rather than prose-only. This addresses D6 (Process fixes > code fixes) being the weakest doctrine in the two-machine endurance convergence.

## Sources
- [Source: other-computer batch scorecard, 2026-04-05] `/Users/leokwan/Desktop/vidux-endurance/evidence/2026-04-05-batch-1-scorecard-and-vnext.md` — "Vidux can describe the right process fix, but it does not yet enforce it consistently enough to prevent recurrence on its own."
- [Source: two-machine convergence, 2026-04-05] `evidence/2026-04-05-two-machine-convergence.md` — D6 divergence: this machine scored PASS (lower bar), other machine scored FRICTION (higher bar: only counts when process fix is machine-checkable).
- [Source: DOCTRINE.md] "Every failure produces two things: a code fix and a process fix. The process fix (new constraint, test, hook, or skill update) is the valuable one."
- [Source: ENFORCEMENT.md] Existing hook architecture: prompt hooks for plan compliance, command hooks for objective checks.
- [Source: vidux-loop.sh] Current checkpoint mode (lines 204-217) marks tasks done but does not inspect what the task produced.
- [Source: vidux-checkpoint.sh] Checkpoint accepts `--status` and `--outcome` but has no artifact-verification step.
- [Source: pre-commit-plan-check.sh] Existing pattern: scan staged files to verify plan coverage. Proves artifact-scanning is feasible in bash at commit time.

## The Problem

Doctrine D6 says every failure produces a code fix AND a process fix. The process fix is the valuable one because it prevents recurrence. But Vidux currently has no way to distinguish:

- **Enforceable process fix**: adds a test, hook, linter rule, CI check, or constraint that a machine can verify.
- **Prose process fix**: writes "always run tests before deploying" in PLAN.md Decisions section. Decays as soon as a new agent session starts with different context pressure.

The endurance test proved this gap is real: Project 2 only became convincing once the process fix was upgraded from a prose constraint to a machine-checkable smoke-test pattern. Without that upgrade, the "process fix" was indistinguishable from a comment.

## Evaluation of Three Approaches

### Approach A: Tag-Based (`[ProcessFix: type]`)

**How it works**: Tasks that claim a process fix must include a `[ProcessFix: test|hook|linter|script|constraint]` tag. The tag names the artifact type. vidux-loop.sh or vidux-checkpoint.sh can verify the tag exists before marking the task `[completed]`.

Example task:
```
- [in_progress] Task 2.3: Fix build failure. [ProcessFix: test] [Evidence: ...]
```

**Implementation in vidux-checkpoint.sh**: At checkpoint time, grep the task line for `[ProcessFix: ...]`. If present, the checkpoint proceeds (the tag is a declaration). If absent and the task description mentions "fix", "failure", "bug", or "broke", emit a warning: "This looks like a fix task but has no [ProcessFix:] tag. Did you produce a process fix?"

**False positives**: Tasks that are not fixes (new features, research, docs) would never have the tag, so no false positives from missing tags. However, the tag itself is still a declaration — the agent says "I made a test" but the tag does not prove the test exists.

**False negatives**: An agent could add the tag without actually creating the artifact. The tag is self-reported. This is the same problem as prose, just with structured prose.

**Implementable in bash**: Yes. Simple grep/sed.

**Backward compat**: No breakage. Tags are optional annotations. Existing plans without tags work unchanged.

**Verdict**: Necessary but not sufficient. The tag creates a structured vocabulary for process fixes but does not verify the artifact exists. It is metadata, not enforcement.

### Approach B: Artifact-Scan (diff inspection at checkpoint)

**How it works**: After a task completes and before the checkpoint commits, scan the git diff for evidence of enforceable artifacts. If the task claimed a process fix (via tag or heuristic) but the diff contains no qualifying artifact, flag it.

Qualifying artifacts (detectable by file path or diff content):
| Artifact type | Detection heuristic |
|---|---|
| **test** | New/modified files matching `*test*`, `*spec*`, `*_test.*`, `test_*` |
| **hook** | New/modified files in `hooks/`, `.husky/`, `.git/hooks/`, or containing `pre-commit`/`post-commit` |
| **linter rule** | Changes to `.eslintrc*`, `.swiftlint.yml`, `pylintrc`, `.rubocop.yml`, or similar |
| **CI check** | Changes to `.github/workflows/`, `Jenkinsfile`, `.circleci/`, `bitrise.yml` |
| **script** | New executable files (`chmod +x`) or files in `scripts/` |
| **constraint** | New `ALWAYS:` or `NEVER:` line in PLAN.md Constraints section |

**Implementation in vidux-checkpoint.sh**: After marking the task `[completed]` but before the git commit, run:
```bash
# Get staged files
STAGED=$(git diff --cached --name-only)

# Check for artifact types
HAS_TEST=$(echo "$STAGED" | grep -iE '(test|spec)' || true)
HAS_HOOK=$(echo "$STAGED" | grep -iE '(hooks/|\.husky/|pre-commit|post-commit)' || true)
HAS_LINTER=$(echo "$STAGED" | grep -iE '(eslint|swiftlint|pylint|rubocop|lint)' || true)
HAS_CI=$(echo "$STAGED" | grep -iE '(\.github/workflows|Jenkinsfile|circleci|bitrise)' || true)
HAS_SCRIPT=$(echo "$STAGED" | grep -iE '(scripts/)' || true)
HAS_CONSTRAINT=$(git diff --cached -- '*.md' | grep -E '^\+.*(ALWAYS|NEVER):' || true)
```

**False positives**: Editing an existing test file for non-process-fix reasons (refactoring a test's formatting) would register as "has test artifact." A feature task that happens to touch a CI file would be flagged as having a process fix when it was just incidental. Mitigation: only run the scan when the task has a `[ProcessFix:]` tag or the task description matches fix-heuristic keywords.

**False negatives**: A constraint added to PLAN.md is still prose — it prevents recurrence only if the next agent reads and respects it. The scan would count it as an artifact, but it is weaker than a test or hook. Also, process fixes in external systems (e.g., a Slack reminder, a calendar event) are invisible to git diff. Mitigation: accept that the scan catches the common case (code artifacts) and acknowledge the prose-constraint gap explicitly.

**Implementable in bash**: Yes. The pattern mirrors `pre-commit-plan-check.sh` which already scans staged files. No Python needed.

**Backward compat**: No breakage. The scan is additive — it runs at checkpoint time and emits warnings. It does not block the commit (that would be too aggressive for v2.3.0).

**Verdict**: Mechanically sound for the common case. Catches 80% of missing process fixes (tests, hooks, scripts, CI). Cannot catch prose-only constraints or external-system fixes. The pre-commit-plan-check.sh pattern proves this is maintainable.

### Approach C: Manual Annotation Only

**How it works**: Trust the agent to mark process fixes correctly. No mechanical verification. The agent writes "Process fix: added test for X" in the Progress entry and that is the record.

**False positives**: None (no detection = no false signal).

**False negatives**: All of them. This is exactly the current state. The endurance test proved it fails: agents write prose process fixes that decay.

**Implementable in bash**: N/A (no implementation needed).

**Backward compat**: Full compatibility (nothing changes).

**Verdict**: Rejected. This is the status quo that the endurance test identified as the weakest doctrine. Choosing this approach means accepting that D6 remains unenforceable.

## Recommended Design: Hybrid (A + B)

**Tag-based declaration + artifact-scan verification.** Neither alone is sufficient. Together they cover both intent and evidence.

### How it works

1. **Declaration (Approach A)**: Tasks that include a fix must carry a `[ProcessFix: <type>]` tag where `<type>` is one of: `test`, `hook`, `linter`, `script`, `ci`, `constraint`.

2. **Verification (Approach B)**: At checkpoint time, if the task has a `[ProcessFix:]` tag, scan the staged git diff for a matching artifact. If the artifact type does not appear in the diff, emit a warning.

3. **Heuristic fallback**: If a task has NO `[ProcessFix:]` tag but its description matches fix-heuristic keywords (`fix`, `bug`, `broke`, `failure`, `regression`), emit a softer advisory: "This looks like a fix task. Did you produce a process fix?"

### Integration points

#### 1. vidux-checkpoint.sh (primary enforcement)

Add a process-fix verification step between "mark task completed" and "git commit". This is the natural place because:
- The task description is available as `$TASK`
- Staged files are available via `git diff --cached`
- The checkpoint already validates task state before committing
- Warning output goes to stderr and does not block the commit

New code block (inserted after line 182, before the git commit on line 219):

```bash
# --- Process-fix verification ------------------------------------------------ #
PROCESS_FIX_TAG=$(echo "$TASK" | grep -oE '\[ProcessFix: ?[a-z_]+\]' || true)
FIX_HEURISTIC=$(echo "$TASK" | grep -iE '(fix|bug|broke|failure|regression)' || true)

if [[ -n "$PROCESS_FIX_TAG" ]]; then
  PF_TYPE=$(echo "$PROCESS_FIX_TAG" | sed -E 's/\[ProcessFix: ?([a-z_]+)\]/\1/')
  STAGED=$(git diff --cached --name-only 2>/dev/null || true)
  PF_FOUND=false

  case "$PF_TYPE" in
    test)       echo "$STAGED" | grep -qiE '(test|spec)' && PF_FOUND=true ;;
    hook)       echo "$STAGED" | grep -qiE '(hooks/|\.husky/|pre-commit|post-commit)' && PF_FOUND=true ;;
    linter)     echo "$STAGED" | grep -qiE '(eslint|swiftlint|pylint|rubocop|lint)' && PF_FOUND=true ;;
    ci)         echo "$STAGED" | grep -qiE '(\.github/workflows|Jenkinsfile|circleci|bitrise)' && PF_FOUND=true ;;
    script)     echo "$STAGED" | grep -qiE '(scripts/)' && PF_FOUND=true ;;
    constraint) git diff --cached -- '*.md' 2>/dev/null | grep -qE '^\+.*(ALWAYS|NEVER):' && PF_FOUND=true ;;
    *)          echo "WARNING: Unknown ProcessFix type: $PF_TYPE" >&2 ;;
  esac

  if [[ "$PF_FOUND" = false ]]; then
    echo "PROCESS-FIX WARNING: Task declares [ProcessFix: $PF_TYPE] but no matching artifact found in staged files." >&2
    echo "  Expected: a new or modified $PF_TYPE artifact in the commit." >&2
    echo "  Staged files: $(echo "$STAGED" | tr '\n' ' ')" >&2
  fi
elif [[ -n "$FIX_HEURISTIC" && "$STATUS" != "blocked" ]]; then
  echo "PROCESS-FIX ADVISORY: Task description mentions a fix but has no [ProcessFix:] tag." >&2
  echo "  Doctrine D6: every failure produces a code fix AND a process fix." >&2
  echo "  Consider: did this fix also produce a test, hook, linter rule, or script?" >&2
fi
```

#### 2. vidux-loop.sh (read-time awareness)

Add a `process_fix_declared` field to the JSON output so downstream consumers (LLM agents, dashboards) know whether the current task claims a process fix. This is a read-only addition to the assess step.

New field extraction (after line 114, alongside `HAS_EVIDENCE`):

```bash
# Process fix tag detection
PROCESS_FIX_TAG=""
echo "$TASK_DESC" | grep -qoE '\[ProcessFix: ?[a-z_]+\]' && \
  PROCESS_FIX_TAG="$(echo "$TASK_DESC" | grep -oE '\[ProcessFix: ?[a-z_]+\]' | sed -E 's/\[ProcessFix: ?([a-z_]+)\]/\1/')"
```

New field in JSON output (after `has_evidence`):

```json
"process_fix_declared": "$PROCESS_FIX_TAG"
```

Empty string means no process fix declared. Non-empty means the declared type.

#### 3. Contract tests (new tests, not modifications to existing 63)

Add three new contract tests:

```python
def test_process_fix_tag_format(self):
    """[ProcessFix: type] tag must use a known artifact type."""
    known_types = {"test", "hook", "linter", "script", "ci", "constraint"}
    # ... validate any [ProcessFix:] tags in PLAN.md use known types

def test_fix_tasks_have_process_fix_tag(self):
    """Tasks whose description matches fix heuristics should have [ProcessFix:] tags.
    This is advisory — test emits warnings, does not fail."""
    # ... scan for fix-heuristic keywords without [ProcessFix:] tag

def test_checkpoint_script_has_process_fix_verification(self):
    """vidux-checkpoint.sh must contain process-fix verification logic."""
    text = (ROOT / "scripts" / "vidux-checkpoint.sh").read_text()
    self.assertIn("ProcessFix", text)
```

#### 4. ENFORCEMENT.md (documentation)

Add a new section "Hook 5: Process Fix Verification" documenting the checkpoint-time scan. This follows the existing pattern of prompt hooks for judgment calls and command-like checks for objective verification.

#### 5. DOCTRINE.md (no change)

D6 wording remains unchanged. The doctrine is correct — "the process fix is the valuable one." The enforcement gap was in tooling, not doctrine language.

### What the hybrid catches vs misses

| Scenario | Tag present? | Artifact in diff? | Result |
|---|---|---|---|
| Fix task, added test, tagged | Yes (test) | Yes (test file) | Clean pass |
| Fix task, added test, forgot tag | No | Yes (test file) | Advisory: "no tag, but looks like a fix" |
| Fix task, tagged, but only prose constraint | Yes (constraint) | Yes (ALWAYS/NEVER line) | Pass (constraint counted) |
| Fix task, tagged test, but no test in diff | Yes (test) | No | **WARNING: declared test but none found** |
| Fix task, no tag, no artifact | No | No | Advisory: "looks like fix, no process fix" |
| Feature task, no fix involved | No | N/A | Silent (no scan triggered) |
| Fix task, process fix in external system | Yes (hook) | No (hook is in CI, not local) | False warning — acceptable |

### Enforcement gradient

This design follows the existing ENFORCEMENT.md gradient:

1. **Advisory** (softest): Fix-heuristic tasks without `[ProcessFix:]` tag get a stderr message. Agent can ignore it.
2. **Warning** (medium): Tagged tasks without matching artifact get a louder stderr warning with staged file list. Agent sees what is missing.
3. **No block** (v2.3.0): Neither advisory nor warning blocks the commit. This is deliberate — v2.3.0 establishes the detection. v2.4.0 can escalate to blocking after the false-positive rate is calibrated.

The progression matches how Vidux introduced stuck-loop detection: first as a `stuck: true` flag in JSON output (v2.0), then as `auto_blocked` with plan mutation (v2.1). Process-fix verification follows the same ramp: first as warnings (v2.3.0), then as enforcement (future).

### Backward compatibility

| Existing artifact | Impact |
|---|---|
| PLAN.md task format | No breakage. `[ProcessFix:]` is an optional tag. Plans without it work identically. |
| vidux-loop.sh JSON | Additive field (`process_fix_declared`). Consumers that do not read it are unaffected. |
| vidux-checkpoint.sh | New code path only fires when `[ProcessFix:]` tag or fix-heuristic is present. Existing checkpoints without fix tasks are unchanged. |
| Contract tests (63/63) | No modification. New tests are additive. |
| Hooks (pre-commit, etc.) | No change. The verification runs inside checkpoint.sh, not as a separate hook. |

### Open questions resolved by this design

- **"Is bash sufficient?"** — Yes. The artifact scan is file-path pattern matching on `git diff --cached --name-only`, which is the same technique as `pre-commit-plan-check.sh`. No Python needed.
- **"Does it break backward compat?"** — No. All additions are optional and additive.
- **"What about prose constraints?"** — Counted as the weakest artifact type (`constraint`). The scan checks for `ALWAYS:`/`NEVER:` additions to markdown files. This is better than nothing but acknowledged as softer than a test or hook.

### What this design does NOT solve (acknowledged scope limits)

1. **External-system process fixes** (Slack reminders, calendar events, manual checklists) are invisible to git diff. The scan will emit a false warning. Mitigation: agent can add `[ProcessFix: constraint]` and add a PLAN.md constraint documenting the external fix.

2. **Quality of the process fix** is not assessed. A test that asserts `true` technically passes the artifact scan. This is a deeper problem that requires LLM judgment — future work for a PostToolUse prompt hook that asks "does this test actually prevent recurrence?"

3. **Retroactive verification** of already-completed tasks is not in scope. The scan only fires at checkpoint time for the current task.

## Implementation Checklist

1. Add `[ProcessFix:]` tag parsing and `process_fix_declared` field to vidux-loop.sh
2. Add process-fix verification block to vidux-checkpoint.sh
3. Add 3 new contract tests (advisory, not breaking the 63/63 suite)
4. Add "Hook 5: Process Fix Verification" section to ENFORCEMENT.md
5. Update LOOP.md checkpoint section to mention `[ProcessFix:]` tag
6. Run full contract suite: 63 existing + 3 new must all pass

## Verdict

The hybrid approach (tag + scan) is the right design for v2.3.0. It follows Vidux's established pattern of graduated enforcement: declare intent via structured metadata, verify via mechanical artifact inspection, warn without blocking. The tag gives the agent a vocabulary for process fixes. The scan gives the system a way to verify the claim. Neither alone would work — together they close the gap that both machines identified as D6's weakness.
