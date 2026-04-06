# 2026-04-05 Control-Plane Hygiene Checks Design

## Goal
Design the complete set of control-plane hygiene checks for Vidux, answering Task 0.5: what to detect, where each check lives, and what action it takes. Ground every design decision in two-machine endurance evidence.

## Sources
- [Source: other-computer control-plane radar] `/Users/leokwan/Desktop/vidux-endurance/evidence/2026-04-05-live-radar-regression-trend.md` -- 9+ detached same-HEAD worktrees, dual active automations on one authority plan, orphan automation dirs, stale sibling plans
- [Source: other-computer live radar and stuck-loop precheck] `/Users/leokwan/Desktop/vidux-endurance/evidence/2026-04-05-live-radar-and-stuck-loop-precheck.md` -- missing `## Active Worktrees`, stale `[in_progress]` in amp/disk-cleaner plans, orphan `vidux-stress-lab/memory.md`
- [Source: other-computer live control-plane radar (2026-04-04)] `/Users/leokwan/Desktop/vidux-endurance/evidence/2026-04-04-live-control-plane-radar.md` -- researcher+endurance sharing one authority plan, 137 ledger rows dominated by churn
- [Source: two-machine convergence] `evidence/2026-04-05-two-machine-convergence.md` -- control-plane hygiene rated STRONG convergence
- [Source: v2.3.0 mega plan] `PLAN.md` -- Task 0.5 spec, Q1/Q3 open questions
- [Source: existing doctor checks] `scripts/vidux-install.sh` lines 488-660 -- 14 existing probes (symlinks, hooks, config, conflicts, stale siblings, VERSION, agents, core files)
- [Source: existing contract tests] `tests/test_vidux_contracts.py` -- 63 tests, all passing
- [Source: live worktree state, 2026-04-05] `git worktree list --porcelain` -- 2 worktrees (main + codex/vidux-operator-surface)
- [Source: live automation state, 2026-04-05] `automations/*/automation.toml` -- 11 automations (2 ACTIVE, 9 PAUSED)
- [Source: live stale in_progress scan, 2026-04-05] `grep -nE '^\- \[in_progress\]' projects/*/PLAN.md` -- 6 in_progress tasks across 4 projects

---

## Q1 Answer: Where Do the Checks Live?

**Decision: Create a new `vidux-doctor.sh` script. Do NOT add to `vidux-loop.sh` or the Python contract tests.**

Rationale (three-way evaluation):

### Option A: Extend `vidux-loop.sh`
- Against: `vidux-loop.sh` operates on a SINGLE plan file (`vidux-loop.sh <plan-path>`). Control-plane hygiene checks are CROSS-plan and CROSS-repo (worktrees, automations, sibling projects). Adding them to the loop script would break its single-responsibility: "read one plan, assess one task, output JSON."
- Against: The loop runs on every cycle for every automation. Worktree enumeration and cross-plan scanning would add latency to every cycle for checks that matter at most once per session.
- Against: The loop is stateless by design (line 2: "stateless cycle script"). Hygiene checks need repo-wide context.

### Option B: Extend Python contract tests (`test_vidux_contracts.py`)
- Against: Contract tests validate the SPEC ("if they fail, fix the docs -- not the tests"). Hygiene checks validate the LIVE STATE of a specific machine's control plane. A stale worktree is not a spec violation -- it is residue from a prior run.
- Against: The tests use `unittest` and run in CI-like conditions. Hygiene checks need access to the live `git worktree list`, live `automations/` directory, and live project plans -- which vary per machine.
- Against: Contract tests should not mutate state. Several hygiene checks should auto-fix (prune worktrees, flag stale tasks).

### Option C: New `vidux-doctor.sh` script (CHOSEN)
- For: Already has a natural home -- `vidux-install.sh doctor` runs 14 probes for installation health. `vidux-doctor.sh` extends this to RUNTIME health.
- For: Can be called from automation harness prompts at session start ("run doctor before your first cycle") without coupling to the per-plan loop.
- For: Matches the pattern from the other-computer evidence: "one explicit hygiene check that flags... multiple active worktree automations on one authority plan, detached same-HEAD worktree growth, and stale `[in_progress]` plans" [Source: regression trend recommendations].
- For: Can reuse the existing `vidux-install.sh` color/output helpers and the `ok()/warn()/fail()` pattern.
- For: Produces JSON output (like `vidux-loop.sh`) so agents can parse results programmatically AND human-readable PASS/FAIL output (like `vidux-install.sh doctor`).

### Relationship to existing `vidux-install.sh doctor`
The existing 14 checks in `vidux-install.sh doctor` are INSTALLATION checks (symlinks, hooks, config, files). The new `vidux-doctor.sh` checks are RUNTIME checks (worktrees, automations, plans, state). They are complementary, not overlapping. `vidux-install.sh doctor` answers "is Vidux installed correctly?" while `vidux-doctor.sh` answers "is the live control plane healthy?"

Later in Phase 2, Task 2.4, we may add a convenience alias so `vidux-install.sh doctor` also runs `vidux-doctor.sh`, but for now they are separate scripts with separate concerns.

---

## Q3 Answer: Stale Threshold

**Decision: Use Progress-section cycle count, not calendar time, consistent with the existing stuck-loop detector.**

The existing stuck-loop enforcement (vidux-loop.sh line 160) uses 3+ Progress entries for a single task as the threshold. For cross-plan staleness, we adapt this: an `[in_progress]` task is "stale" if the plan has received 0 new Progress entries in the last 3 calendar days OR the plan has no `## Progress` section at all. Calendar time is the right signal here because cross-plan checks cannot observe another plan's cycle count -- they can only observe the last-modified timestamp or the date in the most recent Progress entry.

---

## Check Inventory

There are 7 hygiene checks across 3 categories.

### Category 1: Git Worktree Hygiene

#### Check 1: Detached Same-HEAD Worktrees
- **What it detects**: Worktrees where the HEAD commit matches the main branch HEAD and the worktree is not on an active named branch. These are residue from completed or abandoned automation runs.
- **Evidence**: "ten detached `ai` worktrees... all at `567f53d`... the live topology is moving in the wrong direction rather than self-healing" [Source: regression trend, finding 2]
- **Shell logic**:
  ```bash
  MAIN_HEAD=$(git -C "$REPO" rev-parse HEAD)
  git -C "$REPO" worktree list --porcelain | \
    awk '/^worktree /{wt=$2} /^HEAD /{head=$2} /^detached/{if(head==main_head) print wt}' \
    main_head="$MAIN_HEAD"
  ```
  Count results. If > 0, flag each path.
- **Action**: WARN + offer auto-fix. The auto-fix is `git worktree remove <path>` for each detached same-HEAD worktree. The script lists them and auto-prunes if invoked with `--fix`, otherwise warns.
- **Severity**: HIGH. Evidence shows this grows monotonically without intervention.

#### Check 2: Worktree Count Threshold
- **What it detects**: Total worktree count exceeding a sane maximum (default: 5). Even if worktrees are on named branches, having 10+ is a sign of accumulation.
- **Evidence**: "main checkout plus ten detached `ai` worktrees" [Source: regression trend]. The vidux.config.json `max_parallel_agents` is 4, so 5 worktrees (main + 4 agents) is the reasonable ceiling.
- **Shell logic**:
  ```bash
  WT_COUNT=$(git -C "$REPO" worktree list | wc -l | tr -d ' ')
  MAX_WT=$(python3 -c "import json;c=json.load(open('$CONFIG'));print(c.get('defaults',{}).get('max_worktrees', c.get('guidelines',{}).get('max_parallel_agents',4)+1))" 2>/dev/null || echo 5)
  ```
- **Action**: WARN if `WT_COUNT > MAX_WT`. No auto-fix -- the excess worktrees may be intentionally active.
- **Severity**: MEDIUM.

### Category 2: Automation Topology Hygiene

#### Check 3: Multiple Active Automations on One Authority Plan
- **What it detects**: Two or more `ACTIVE` automations in `automations/` whose prompts reference the same authority plan path.
- **Evidence**: "both `automations/vidux-researcher/automation.toml` and `automations/vidux-endurance/automation.toml` are `ACTIVE`, use `execution_environment = \"worktree\"`, and point at the same endurance authority plan" [Source: stuck-loop precheck, finding 2]. "The plan advice is accurate, but still passive... nothing in the loop forces cleanup or consolidation" [Source: regression trend, finding 3].
- **Shell logic**:
  ```bash
  # For each ACTIVE automation, extract the plan path from the prompt field
  # (grep for the projects/*/PLAN.md pattern inside the prompt)
  for toml in "$REPO"/automations/*/automation.toml; do
    dir=$(dirname "$toml")
    name=$(basename "$dir")
    st=$(grep -o 'status = "[^"]*"' "$toml" | grep -o '"[^"]*"' | tr -d '"')
    [[ "$st" != "ACTIVE" ]] && continue
    plan_ref=$(grep -oE 'skills/vidux/projects/[^/]+/PLAN\.md' "$toml" | head -1)
    [[ -n "$plan_ref" ]] && echo "$name|$plan_ref"
  done | sort -t'|' -k2 | uniq -d -f1
  ```
  Any line in the output means two ACTIVE automations share one authority plan.
- **Action**: WARN. Do NOT auto-fix -- the human must decide which automation to pause. Output names the conflicting automations and the shared plan.
- **Severity**: HIGH. This directly causes churn (137 ledger rows, 30 repeats of the same summary) [Source: control-plane radar, finding 2].

#### Check 4: Orphan Automation Directories
- **What it detects**: Directories in `automations/` that have `memory.md` but no `automation.toml`. These are residue from deleted or never-completed automation setups.
- **Evidence**: "`automations/vidux-stress-lab/` has decayed into an orphan `memory.md` without a companion `automation.toml`, which is residue rather than an owned live loop" [Source: stuck-loop precheck, finding 2].
- **Shell logic**:
  ```bash
  for d in "$REPO"/automations/*/; do
    [[ -f "$d/memory.md" ]] && [[ ! -f "$d/automation.toml" ]] && echo "$(basename "$d")"
  done
  ```
- **Action**: WARN + offer auto-fix. Auto-fix with `--fix` removes the orphan directory (after confirming memory.md has no unique content worth preserving -- check if it is under 5 lines).
- **Severity**: LOW. Orphans are cosmetic clutter, not active harm.

### Category 3: Plan State Hygiene

#### Check 5: Stale `[in_progress]` Tasks Across Projects
- **What it detects**: Any project plan with `[in_progress]` tasks where the most recent `## Progress` entry is older than 3 calendar days (or the Progress section is empty/missing).
- **Evidence**: "`amp` Task 8 and `disk-cleaner` Task 4 are plainly stale `[in_progress]` residue with no `## Active Worktrees` accounting... `context-ops/PLAN.md` still shows `in_progress`, but it also has fresh April 4 progress, so it looks open rather than abandoned" [Source: stuck-loop precheck, finding 2]. The evidence distinguishes "stale abandoned" from "active open" by checking for recent Progress entries -- the design replicates this judgment mechanically.
- **Shell logic**:
  ```bash
  THREE_DAYS_AGO=$(date -v-3d +%Y-%m-%d 2>/dev/null || date -d '3 days ago' +%Y-%m-%d)
  for plan in "$PROJECTS_DIR"/*/PLAN.md; do
    has_ip=$(grep -cE '^\- \[in_progress\]' "$plan" || true)
    [[ "$has_ip" -eq 0 ]] && continue
    # Extract the most recent date from ## Progress section
    last_date=$(awk '/^## Progress/{found=1; next} found && /^## /{found=0} found{print}' "$plan" \
      | grep -oE '\[20[0-9]{2}-[0-9]{2}-[0-9]{2}\]' | sort -r | head -1 | tr -d '[]')
    if [[ -z "$last_date" ]] || [[ "$last_date" < "$THREE_DAYS_AGO" ]]; then
      project=$(basename "$(dirname "$plan")")
      echo "$project|$has_ip|${last_date:-never}"
    fi
  done
  ```
- **Action**: WARN. List each stale project with its in_progress count and last progress date. No auto-fix -- the human decides whether to complete, block, or abandon.
- **Severity**: MEDIUM. Stale in_progress tasks pollute the control plane's "what is active" signal.

#### Check 6: Missing `## Active Worktrees` Section in Plans with Worktree-Backed Automations
- **What it detects**: Any plan that is referenced by a worktree-execution automation but does not contain an `## Active Worktrees` section documenting which worktrees are operating on it.
- **Evidence**: "No Vidux plan currently exposes an `## Active Worktrees` section, so that topology drift is only implicit" [Source: stuck-loop precheck, finding 2].
- **Shell logic**:
  ```bash
  for toml in "$REPO"/automations/*/automation.toml; do
    exec_env=$(grep -o 'execution_environment = "[^"]*"' "$toml" | grep -o '"[^"]*"' | tr -d '"')
    [[ "$exec_env" != "worktree" ]] && continue
    st=$(grep -o 'status = "[^"]*"' "$toml" | grep -o '"[^"]*"' | tr -d '"')
    [[ "$st" != "ACTIVE" ]] && continue
    plan_ref=$(grep -oE 'skills/vidux/projects/[^/]+/PLAN\.md' "$toml" | head -1)
    [[ -z "$plan_ref" ]] && continue
    plan_path="$REPO/$plan_ref"
    [[ ! -f "$plan_path" ]] && continue
    if ! grep -q '^## Active Worktrees' "$plan_path"; then
      echo "$(basename "$(dirname "$toml")")|$plan_ref"
    fi
  done
  ```
- **Action**: WARN. Suggest adding `## Active Worktrees` section to the flagged plan. No auto-fix -- the section needs content (which worktrees, which branches) that only the agent/human can provide.
- **Severity**: MEDIUM. Missing section makes topology drift invisible.

#### Check 7: Plan Files with Merge Conflict Markers in Projects Directory
- **What it detects**: Any `PLAN.md` in `projects/` containing `<<<<<<<`, `=======`, or `>>>>>>>` markers. This is a projects-directory-specific version of the existing merge-conflict check in `vidux-install.sh doctor` (which only scans vidux core files).
- **Evidence**: "Dirty repo state is a real doctrine-pressure source... git pull --rebase failures because those local changes were already present" [Source: control-plane radar, finding 4]. Merge conflicts in plan files are the most dangerous form of dirty state because they corrupt the plan-as-store.
- **Shell logic**:
  ```bash
  grep -rlE '^(<{7}|>{7}|={7})' "$PROJECTS_DIR"/*/PLAN.md 2>/dev/null
  ```
- **Action**: BLOCK. If any plan has conflict markers, the doctor reports FAIL and exits non-zero. This is the only blocking check because a corrupted plan file will cause the loop script to produce unpredictable results.
- **Severity**: CRITICAL.

---

## Output Format

`vidux-doctor.sh` produces TWO outputs:

### 1. Human-readable (stdout)
Matches the existing `vidux-install.sh doctor` pattern:
```
  Vidux Doctor (Runtime)
  Version: 2.3.0
  Host:    leos-mbp

== Worktrees ==
  ! 2 detached same-HEAD worktrees (run with --fix to prune)
  ok Worktree count: 3 (max: 5)

== Automations ==
  ok No conflicting active automations
  ! 1 orphan automation directory: vidux-stress-lab

== Plans ==
  ! 2 stale [in_progress] projects: amp (last: never), disk-cleaner (last: 2026-04-03)
  ok No missing Active Worktrees sections
  ok No merge conflicts in project plans

  WARN  5/7 checks pass (2 warnings)
```

### 2. Machine-readable (--json flag)
```json
{
  "version": "2.3.0",
  "host": "leos-mbp",
  "timestamp": "2026-04-05T15:30:00Z",
  "pass": 5,
  "total": 7,
  "checks": [
    {
      "id": "detached_same_head",
      "category": "worktrees",
      "status": "warn",
      "count": 2,
      "details": ["/Users/leokwan/.codex/worktrees/0d02/ai", "/Users/leokwan/.codex/worktrees/0f20/ai"],
      "fix_available": true
    },
    {
      "id": "worktree_count",
      "category": "worktrees",
      "status": "pass",
      "count": 3,
      "max": 5
    },
    {
      "id": "dual_active_automations",
      "category": "automations",
      "status": "pass"
    },
    {
      "id": "orphan_automations",
      "category": "automations",
      "status": "warn",
      "count": 1,
      "details": ["vidux-stress-lab"],
      "fix_available": true
    },
    {
      "id": "stale_in_progress",
      "category": "plans",
      "status": "warn",
      "count": 2,
      "details": [
        {"project": "amp", "in_progress_count": 1, "last_progress": null},
        {"project": "disk-cleaner", "in_progress_count": 1, "last_progress": "2026-04-03"}
      ]
    },
    {
      "id": "missing_active_worktrees",
      "category": "plans",
      "status": "pass"
    },
    {
      "id": "plan_merge_conflicts",
      "category": "plans",
      "status": "pass"
    }
  ]
}
```

---

## Script Interface

```
Usage: vidux-doctor.sh [options]
  --json        Machine-readable JSON output (no colors)
  --fix         Auto-fix issues with fix_available=true
  --repo PATH   Override repo root (default: autodetect from script location)
  --stale-days N  Override stale threshold in days (default: 3)
```

Exit codes:
- 0: All checks pass (or only warnings)
- 1: One or more BLOCK-severity checks failed (merge conflicts)
- 2: Script error (bad arguments, missing repo)

---

## Integration Points

### 1. Automation Harness Prompt
Automation prompts (e.g., `vidux-endurance/automation.toml`) should include:
```
Before your first cycle, run:
  bash ~/Development/ai/skills/vidux/scripts/vidux-doctor.sh
If any check returns BLOCK, stop and report. If checks return WARN, note them in your first Progress entry.
```
This is a prompt-level nudge, not a mechanical gate -- consistent with the existing ENFORCEMENT.md gradient (Level 2: Friction).

### 2. `vidux-install.sh upgrade`
Step 7 of the existing `cmd_upgrade()` function runs contract tests. Add a step 7.5:
```bash
echo -e "${BOLD}== 7.5. Runtime health ==${RESET}"
if bash "$VIDUX_ROOT/scripts/vidux-doctor.sh" --json >/dev/null 2>&1; then
  ok "Runtime health check passed"
else
  warn "Runtime health issues found (run: vidux-doctor.sh)"
fi
```

### 3. `vidux-install.sh doctor`
Add a final section that calls `vidux-doctor.sh` if it exists, so the existing doctor command surfaces both installation AND runtime health:
```bash
# 9. Runtime health (if vidux-doctor.sh exists)
echo -e "${BOLD}== Runtime health ==${RESET}"
if [[ -x "$VIDUX_ROOT/scripts/vidux-doctor.sh" ]]; then
  bash "$VIDUX_ROOT/scripts/vidux-doctor.sh" 2>/dev/null && ((pass++)) || true
  ((total++)) || true
fi
```

### 4. Contract Tests (Additions)
Add 3 new tests to `test_vidux_contracts.py` that validate the DOCTOR SCRIPT itself (not the live state):

```python
def test_doctor_script_exists_and_executable(self):
    """vidux-doctor.sh must exist and be executable."""
    script = self.SCRIPTS_DIR / "vidux-doctor.sh"
    self.assertTrue(script.exists(), "vidux-doctor.sh missing")
    self.assertTrue(os.access(script, os.X_OK), "vidux-doctor.sh not executable")

def test_doctor_json_output_is_valid(self):
    """vidux-doctor.sh --json must produce valid JSON with required fields."""
    result = subprocess.run(
        ["bash", str(self.SCRIPTS_DIR / "vidux-doctor.sh"), "--json"],
        capture_output=True, text=True, timeout=15,
    )
    # May exit 0 or 1 depending on live state -- just check JSON is valid
    data = json.loads(result.stdout)
    for key in ("version", "pass", "total", "checks"):
        self.assertIn(key, data)
    self.assertIsInstance(data["checks"], list)
    self.assertGreaterEqual(len(data["checks"]), 7)

def test_doctor_checks_have_required_fields(self):
    """Each check in doctor JSON output must have id, category, and status."""
    result = subprocess.run(
        ["bash", str(self.SCRIPTS_DIR / "vidux-doctor.sh"), "--json"],
        capture_output=True, text=True, timeout=15,
    )
    data = json.loads(result.stdout)
    for check in data["checks"]:
        self.assertIn("id", check)
        self.assertIn("category", check)
        self.assertIn("status", check)
        self.assertIn(check["status"], ("pass", "warn", "block"))
```

These test the script CONTRACT (valid JSON, required fields), not the live state. They belong in the contract test suite.

---

## Config Additions

Add to `vidux.config.json`:
```json
{
  "defaults": {
    "archive_threshold": 30,
    "context_warning_lines": 200,
    "max_worktrees": 5,
    "stale_in_progress_days": 3
  }
}
```

The new fields (`max_worktrees`, `stale_in_progress_days`) are read by `vidux-doctor.sh` with fallback defaults, matching the existing pattern where `vidux-loop.sh` reads `archive_threshold` and `context_warning_lines` with fallbacks.

---

## Check Summary Table

| # | Check ID | Category | Detects | Action | Severity | Auto-Fix |
|---|----------|----------|---------|--------|----------|----------|
| 1 | `detached_same_head` | worktrees | Worktrees at main HEAD with no branch | WARN | HIGH | Yes (`--fix` prunes) |
| 2 | `worktree_count` | worktrees | Total worktrees exceeding max | WARN | MEDIUM | No |
| 3 | `dual_active_automations` | automations | 2+ ACTIVE automations on one plan | WARN | HIGH | No |
| 4 | `orphan_automations` | automations | memory.md without automation.toml | WARN | LOW | Yes (`--fix` removes dir) |
| 5 | `stale_in_progress` | plans | [in_progress] with no recent Progress | WARN | MEDIUM | No |
| 6 | `missing_active_worktrees` | plans | Plan lacks ## Active Worktrees when needed | WARN | MEDIUM | No |
| 7 | `plan_merge_conflicts` | plans | Conflict markers in project PLAN.md files | BLOCK | CRITICAL | No |

---

## What This Design Does NOT Cover

1. **Ledger churn detection** -- The evidence shows 137 ledger rows with 30 repeats of the same summary. This is a ledger-level problem, not a control-plane problem. It belongs in the ledger skill, not vidux-doctor.
2. **Automation execution_environment mismatch** -- The evidence notes that `vidux-researcher` uses `execution_environment = "worktree"` when it should be local. This is a per-automation configuration judgment, not a mechanical check.
3. **Cross-machine sync validation** -- The two-machine contract ("pull before work, push after changes") is a git workflow discipline problem. `vidux-install.sh version` already reports sync status.
4. **Stuck-loop enforcement within a single plan** -- Already handled by `vidux-loop.sh` lines 157-201. The doctor checks the CROSS-plan view; the loop checks the WITHIN-plan view.

---

## Implementation Order (for Task 2.4)

1. Create `scripts/vidux-doctor.sh` with all 7 checks
2. Add `max_worktrees` and `stale_in_progress_days` to `vidux.config.json`
3. Add 3 contract tests for the doctor script to `test_vidux_contracts.py`
4. Add the integration hook in `vidux-install.sh doctor` to call `vidux-doctor.sh`
5. Update `scripts/vidux-install.sh` `test_scripts_exist_and_executable` expected list
6. Run full contract suite -- must still pass 63 existing + 3 new = 66 total
