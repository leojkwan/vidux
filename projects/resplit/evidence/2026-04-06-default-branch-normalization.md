# 2026-04-06 Default-Branch Normalization

## Why This Pass Happened

Cycle 2 left public Task 4 pending because the remaining-gap rebaseline still described AP539 as a possible follow-through seam while attached-root notes were suspected to contain stale `origin/main` reopen language. This pass needed to answer one narrower question from fresh repo truth: is AP539 still a code lane, or is it already fixed on the canonical default branch and only waiting on the next uploaded build?

## Fresh Repo Truth

- `git symbolic-ref refs/remotes/origin/HEAD` still returns `refs/remotes/origin/master`.
- `git merge-base --is-ancestor b394ab48 origin/master && echo AP539_ON_MASTER` returns `AP539_ON_MASTER`, which means the AP539 replay already belongs to the shipping branch.
- `git log --oneline -n 12 origin/master` shows the broader post-`1107` replay set already stacked on `origin/master`, including:
  - `32d24c00` / `8359e2b8` support-page follow-through
  - `96b651b4` marketing primary-features recovery
  - `078a8463` join-shell density recovery
  - `340a44a0` home-row hierarchy fix
  - `e879eb6f` unresolved-review handoff fix
  - `e58eb883` participant-share copy fix

## Checkpoint Audit

- `RALPH.md` already states the remote default branch is `origin/master` and tells future lanes to ship from merged `origin/master`.
- `.agent-ledger/hot-files.md` now records AP539 as merged on `origin/master` with explicit reopen criteria tied to a later uploaded build or device trace, not to an off-branch recovery.
- `.cursor/plans/app-store-feedback.plan.md` marks `AP539ClB0F16Az7Cv-DkwXA` as `fixed`, cites the clean-`origin/master` replay, and now keeps the row in next-build/device verification only.
- `.cursor/plans/resplit-nurse.log.md` now treats AP539 as closed code work and names `remaining-work.plan.md` row `p0-native-readiness` as the next honest fallback if the release wall stays unchanged.
- A targeted AP539 checkpoint audit across those files found no stale reopen instruction pointing at `origin/main`; the only remaining mention is the new warning sentence telling future lanes not to reuse that stale assumption.

## Outcome

Task 4 is complete:

1. The repo-owned checkpoints now agree on the canonical default branch.
2. AP539 is no longer a forgotten code seam.
3. AP539 remains a release-boundary verification row because build `1107` still predates `b394ab48`.

## Next Honest Slice

If the external release wall changes, rerun ASC sync and upload work from clean `origin/master`.

If the release wall stays unchanged, keep AP539 closed and take a different repo-owned slice, starting from `remaining-work.plan.md` row `p0-native-readiness` instead of reopening the same screenshot family.
