# Changelog

All notable changes to Vidux are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Vidux uses [Semantic Versioning](https://semver.org/) — minor bumps may tighten doctrine; major bumps change the cycle or `PLAN.md` shape. This file starts at 2.9.0; earlier history lives in git.

---

## [2.9.0] — 2026-04-17

Doctrine patch targeting a specific failure mode: at fleet scale, agents consistently picked cheap meta-tasks (audit a row, flip a status, close an investigation) over real bug fixes, producing a steady stream of green PRs while user-visible bugs sat unaddressed. Two surgical rule changes plus one deprecation close the loop.

**Net effect on the code base:** −19 lines across 9 files. The discipline gets smaller, not bigger.

### Added

- **`observed` is now a first-class evidence type.** User-observed behavior is citable evidence of equal standing to `codebase grep`, `GitHub PR`, or `design doc`. This closes the ingest path for bugs a human sees in the running app.

  ```markdown
  ## Evidence
  - [Source: observed] "flicker on first render after launch" (v2.4.1)
  - [Source: observed] "Remove button silently no-ops during active session"
  ```

  Previously the allowed evidence sources were all document-oriented. If no one had written the bug into a PR, a design doc, or a chat log, the bug had no way to enter the plan. The doctrine now treats the running app as a valid source.

### Changed — Core Rule

- **Progress is code change.** A PR that only touches `PLAN.md`, `investigations/`, `evidence/`, or `INBOX.md` without a source-code change is bookkeeping, not progress. Bundle plan updates into the code PR that ships the fix, or keep notes local until a fix is ready.

  The following shapes are now prohibited as standalone PRs:
  - `flip row to [completed]`
  - `reconcile Phase N`
  - `audit already-delivered`
  - `investigation closeout` without a code fix

  **Why:** at fleet scale, the cheap tasks produce mergeable PRs faster than real bug fixes. Lanes that optimize for merge count will consistently pick the cheap path. This rule takes the cheap path off the table — when a lane needs a task, the only moves left are actual code changes.

- **Investigation-only cycles no longer commit.** Previously the doctrine said *"the cycle is investigation only — no code"* in several places, permitting a commit of only the investigation file. The rule is now inverted: if a cycle produces no code, it produces no commit and no PR. The investigation file stays on disk for the next cycle to pick up, and ships in the same PR as the fix.

  Before:
  > If the Fix Spec is missing, the cycle is investigation only -- no code.

  After:
  > Investigation notes live locally in the working tree until the fix ships — they are not a separate deliverable.

- **LOOP.md checkpoint rule inverted.** *"Every cycle MUST produce a checkpoint commit, even if no code changed"* → *"A cycle produces a commit only when code changed."*

- **24/7 lane count recommendation simplified.** Was 3–7 lanes per repo (coordinator + optional observer + session-gc). Now 2–4 lanes per repo (coordinator + session-gc). The observer slot is gone.

### Deprecated — Observer Lane Pattern

Observer lanes (read-only audit lanes that watch a writer each cycle) are deprecated as an orchestration smell. They add memory.md files, cross-lane reads, and cycle offsets without catching bugs that the writer could not already see in its own logs. Drift belongs upstream — fix the writer's prompt or the doctrine producing drift. Don't pay for a second scheduled lane to report it back.

Deprecation targets:

| Location | Change |
|---|---|
| `references/automation.md` Section 8 (Observer Pairs) | Full section collapsed to a 3-line deprecation notice |
| `references/automation.md` Section 3 "The observer" subsection | Rewritten as "Observer lanes are deprecated" |
| `references/automation.md` Section 8.5 step 4 (Cross-Fleet Coordination) | Observer-as-fleet-health step removed |
| `guides/recipes.md` Recipe 1 (Fleet Watcher) | Marked DEPRECATED with blockquote warning |
| `guides/recipes.md` Recipe 4 (Observer Pair) | Marked DEPRECATED with blockquote warning |
| `docs/index.md` Fleet Intelligence feature card | "Observer pairs" removed from description |

**Alternatives if you need what observers were doing:**

- **Independent eyes on a specific concern.** Run a one-shot audit by hand. A human reading the writer's recent memory.md tail for 5 minutes catches more than a scheduled observer running every cycle.
- **Fleet health tracking.** Put health checks in the writer's own cycle — it already reads its state each fire. `session-gc` already tracks disk pressure across sessions.
- **Prompt drift detection.** If a writer keeps producing the wrong thing, fix the writer's prompt. The observer catching the drift does not fix the underlying bug.

Existing observer lanes are not auto-migrated. They will continue to work. Consider winding them down at your next maintenance window.

### Migration Guide

If your lane prompts, `CLAUDE.md`, `AGENTS.md`, or automation README files reference the old doctrine phrasings, replace them:

| Old phrasing | New phrasing |
|---|---|
| `investigation only — no code` | `no PR until the fix ships` |
| `no code this cycle` | `no commit until the fix ships` |
| `Every cycle MUST produce a checkpoint commit` | `A cycle produces a commit only when code changed` |
| `observer pair`, `fleet watcher` | (deprecated — see alternatives above) |
| `preemptive observer` | (deprecated) |

No change to:

- The five principles (1–5 all preserved).
- The cycle (READ → ASSESS → ACT → VERIFY → CHECKPOINT).
- The PLAN.md template structure (Purpose, Evidence, Constraints, Tasks, Decision Log, Open Questions, Surprises, Progress).
- `INBOX.md` ingest pattern.
- The agent ledger (`.agent-ledger/activity.jsonl`).
- Planning and nested planning (compound tasks, `[Investigation: ...]` markers, sub-plans).
- The automation harness (session management, cron scheduling, session-gc).
- Delegation modes (Mode A research / Mode B implementation).
- Draft-PR flow.
- Evidence file naming and format (aside from the new `observed` source type).

### Contract Tests

`tests/test_vidux_contracts.py` passes at the same level as before: 133 pass / 3 pre-existing failures, none introduced by this release.

---

## Versioning Policy

- **Patch (2.9.0 → 2.9.1):** typo fixes, doc clarifications, additional examples.
- **Minor (2.9.0 → 2.10.0):** tightening rules, adding evidence types, deprecating patterns. No breaking changes to the cycle or `PLAN.md` template.
- **Major (2.9.0 → 3.0.0):** changes to the cycle shape, the five principles, or the required `PLAN.md` sections. Contract tests would change.

This release is minor because: new evidence type adds a valid shape (backward compatible); "no metadata-only PR" tightens but doesn't break existing valid PRs; observer deprecation does not remove the capability to run a read-only lane, only the official pattern recommendation.
