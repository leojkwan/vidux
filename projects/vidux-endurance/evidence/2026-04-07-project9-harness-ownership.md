# 2026-04-07 Project 9 Harness + External-Surface Ownership Contract

## Goal
Write an evergreen harness and an explicit ownership contract for the fake insurance claims catastrophe desk, with every off-repo surface resolved to a concrete machine path before the forced-resume drill begins.

## Sources
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/PLAN.md`] Task 9.1 requires a stateless harness plus an external-surface ownership contract that resolves off-repo paths, including automation memory, to absolute paths.
- [Source: `/Users/leokwan/Development/vidux/SKILL.md`] Doctrine 8 allows only evergreen mission, authority, role boundary, design DNA, guardrails, and skills in the harness prompt.
- [Source: `/Users/leokwan/Development/vidux/SKILL.md`] Doctrine 9 requires one owned deliverable per worker, parallel fan-out, serial fan-in, and a thin coordinator.
- [Source: `/Users/leokwan/Development/vidux/SKILL.md`] The worktree handoff protocol requires a registered active worktree entry, read-before-start resume, and explicit removal at the real boundary.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project8-scorecard.md`] Project 8 failed Doctrine 9 because a worker wrote outside its owned repo file and touched automation memory.
- [Source: `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project8-drill.md`] The prior drill proved repo-local auditing was not enough because the worker escaped into `/Users/leokwan/.codex/automations/vidux-endurance/memory.md`.
- [Source: `python3 - <<'PY' ... os.path.realpath(...) ... PY`, executed 2026-04-07] The symbolic automation-memory alias `/Users/leokwan/.codex/automations/vidux-endurance/memory.md` resolves to the canonical path `/Users/leokwan/Development/ai/automations/vidux-endurance/memory.md`.
- [Source: `printf 'CODEX_HOME=%s\n' \"$CODEX_HOME\"`, executed 2026-04-07] `CODEX_HOME` is blank in this runtime, so `$CODEX_HOME/automations/...` is not safe as a contract surface without resolution.

## Findings

### 1. Proposed Project 9 harness stays stateless under Doctrine 8
Proposed prompt:

```text
Use /vidux as the control loop for the fake insurance claims catastrophe desk endurance slice in /Users/leokwan/Development/vidux.

Mission:
Validate Vidux's design-for-completion behavior, harness purity, and external-surface ownership enforcement using a fake insurance claims catastrophe desk. Surface recovery friction and coordinator failures instead of polishing the pretend product.

Authority:
Read /Users/leokwan/Development/vidux/projects/vidux-endurance/PLAN.md first on every run and treat it as the only project state store.
Use /Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/ and investigations/ only as supporting artifacts.

Role boundary:
Own the catastrophe-desk endurance lane only: harness review, worker ownership enforcement, forced-resume fan-out, doctrine scoring, and evidence checkpointing. Do not build a real claims product and do not create a second orchestration loop.

Design DNA:
Evidence over vibes.
Failure discovery is the point.
Coordinator stays thin.
Process fixes matter more than fake-project polish.

Guardrails:
Operate only in /Users/leokwan/Development/vidux.
Fake-project writes may touch only the endurance PLAN plus project-local evidence or investigations.
Resolve any off-repo surface to a concrete absolute path before using it.
Resume the recorded worktree path from PLAN.md instead of creating a sibling worktree.
Do not push to origin unless PLAN.md explicitly says to.

Skills:
Load /ledger only when cross-session coordination output must leave PLAN.md.
```

### 2. The ownership contract names repo-local write surfaces and the canonical off-repo path
Use this contract for Task 9.2:

| Role | Owned write surface | Allowed writes |
|------|----------------------|----------------|
| Coordinator | `/Users/leokwan/Development/vidux/projects/vidux-endurance/PLAN.md` | Task state, `## Active Worktrees`, Progress, Surprises, and Decision Log only |
| Coordinator | `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project9-harness-ownership.md` | This harness and ownership note only |
| Coordinator | `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project9-forced-resume-drill.md` | Fan-in synthesis, write-scope audit, and recovery proof only |
| Coordinator | `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project9-scorecard.md` | Project 9 grading only |
| Coordinator | `/Users/leokwan/Development/ai/automations/vidux-endurance/memory.md` | Final run note only, after the project boundary |
| Worker A | `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project9-slice-fnol-severity.md` | First-notice-of-loss completeness, catastrophe severity routing, and fraud-hold triggers only |
| Worker B | `/Users/leokwan/Development/vidux/projects/vidux-endurance/evidence/2026-04-07-project9-slice-adjuster-status.md` | Adjuster assignment, field-inspection dependency, and claimant-status publication only |

Rules:
- No worker may edit `PLAN.md`, the coordinator synthesis file, another worker's evidence file, or automation memory through either the `.codex` alias path or the canonical `/Users/leokwan/Development/ai/automations/vidux-endurance/memory.md` path.
- The `.codex` alias path `/Users/leokwan/.codex/automations/vidux-endurance/memory.md` is audit-relevant, but the canonical realpath above is the ownership contract source of truth.
- Each worker returns exactly one evidence note.
- The coordinator may synthesize only after rereading `PLAN.md` plus the recorded worker-file paths from disk.

### 3. The machine check should audit by time window, not only by repo status
Project 8 proved that a repo-only `git status` audit can miss off-repo writes. For Task 9.2, the machine check should:
- create a baseline timestamp after the Task 9.2 checkpoint is written
- list repo files touched under `/Users/leokwan/Development/vidux/projects/vidux-endurance` after that baseline
- fail if any touched repo file is outside the two worker evidence targets
- separately watch the canonical automation-memory path and fail if its mtime changes before project closeout

This is stronger than the Project 7/8 audit shape because it can treat repo and off-repo ownership as one verification surface.

### 4. The forced-resume checkpoint now has an explicit recovery contract
The mid-fan-out checkpoint should record:
- the active worktree entry for `/Users/leokwan/Development/vidux`
- the current task as Task 9.2
- both owned worker evidence paths
- the requirement that the recovery hop read `PLAN.md` before fan-in
- the requirement that the machine audit rerun after workers finish and before the coordinator writes any other file

That makes Task 9.2 a real external-path ownership test instead of another documentary "trust the coordinator" claim.

## Recommendations
- Use the proposed prompt as the Project 9 launch harness without adding current-state snapshots.
- Treat `/Users/leokwan/Development/ai/automations/vidux-endurance/memory.md` as the canonical automation-memory write surface for this machine, even if the `.codex` alias also exists.
- Fail the Project 9 drill if the post-fan-out audit finds any repo file outside the two worker evidence notes or any automation-memory mtime change before the scorecard boundary.
