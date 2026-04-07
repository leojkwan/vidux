# 2026-04-07 DB-Only Governance Escalation

## Why this slice
The same stalled DB-only `ACTIVE` cluster has now repeated across the last 3 retained orchestrator notes even though the shared repo-backed fleet is healthy and the public doctor already surfaces the defect. Another blind row edit would just repeat the same loop. The control-plane move now needs to be governance, not another scheduler poke.

## Facts gathered
- [Source: repo-vs-DB comparison against `/Users/leokwan/Development/ai/automations`, audit 2026-04-07 02:00-02:10 EDT] The canonical fleet currently has `26` repo-backed automation TOMLs, `34` live SQLite rows, `26` shared IDs, and `0` shared-field mismatches on `name`, `status`, `rrule`, `cwds`, `model`, or `reasoning_effort`.
- [Source: `~/.codex/sqlite/codex-dev.db` table `automations`, queried 2026-04-07 02:04 EDT] The remaining DB-only `ACTIVE` rows are `strongyes-backend`, `strongyes-content-scraper`, `strongyes-email`, `strongyes-problem-builder`, `strongyes-product`, `strongyes-ux`, `vidux-meta`, and `vidux-test-grader`.
- [Source: `~/.codex/sqlite/codex-dev.db` table `automation_runs`, queried 2026-04-07 02:05 EDT] None of those `8` DB-only IDs has any recorded run rows at all, while the repo-backed active rows continue to accumulate fresh runs.
- [Source: `/Users/leokwan/Development/vidux/scripts/vidux-doctor.sh`, live audit 2026-04-07] The public doctor already contains `stalled_active_automation_rows` and is designed to warn on exactly this condition, so the fleet already has machine-visible evidence of the stall.
- [Source: `/Users/leokwan/Development/ai/automations/codex-automation-orchestrator/memory.md`, read 2026-04-07 02:12 EDT] The last 3 retained orchestrator notes all point back to the same DB-only stalled cluster as the next move, so the anti-loop rule now applies: stop retrying the same unresolved seam and escalate the process fix.
- [Source: DB prompt headers, queried 2026-04-07 02:09 EDT] The `6` StrongYes DB-only rows and `vidux-meta` are broad dispatch lanes over roots that already have repo-backed active automation coverage, while `vidux-test-grader` is the only DB-only row that looks like a distinct utility lane rather than a duplicate shipping owner.
- [Source: `~/.codex/sqlite/codex-dev.db` row `vidux-test-grader`, queried 2026-04-07 02:09 EDT] `vidux-test-grader` also carries `updated_at=1775538002`, a second-based timestamp anomaly in a millisecond scheduler schema, which makes blind scheduler mutation even less trustworthy.

## Recommendation matrix
- `strongyes-backend`, `strongyes-content-scraper`, `strongyes-email`, `strongyes-problem-builder`, `strongyes-product`, `strongyes-ux`: archive-by-default unless Leo explicitly wants the DB-only StrongYes burst fleet to replace the current repo-backed StrongYes automations. If that cutover is desired, promote them into `/Users/leokwan/Development/ai/automations` first and retire overlapping repo-backed lanes in the same approved change.
- `vidux-meta`: archive-by-default unless Leo explicitly wants a dedicated repo-backed Vidux meta loop in addition to the active orchestrator and repo-backed Vidux lanes. Leaving it DB-only and `ACTIVE` is not a coherent steady state.
- `vidux-test-grader`: separate promote-or-archive decision required. If the lane is still wanted, promote it into repo truth with a clean scheduler row and explicit model choice. Otherwise archive it with the rest of the stalled DB-only cluster.

## Change shipped
1. Converted the repeated stalled-row seam into an explicit governance recommendation instead of another live DB mutation.
2. Left repo-backed TOMLs and live scheduler rows untouched in this run because the healthy shared fleet already matches live SQLite and the stalled DB-only cluster now needs owner intent, not more row surgery.

## Remaining exposure
- The `8` DB-only rows are still marked `ACTIVE` locally until a human approves archive or promotion.
- The canonical `/Users/leokwan/Development/ai` checkout is still dirty and `behind 1`, so any eventual archive/promotion cutover must stay narrowly scoped.
