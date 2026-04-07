# 2026-04-06 StrongYes Content Memory Contract

## Why this slice
`strongyes-content` was still using a pre-fallback memory contract even after the shared StrongYes release lane had already been normalized. That left the content radar able to miss its own freshest notes whenever `$CODEX_HOME` is unset, while the shared live memory file kept growing with repeated cold-state checkpoints.

## Facts gathered
- [Source: `printenv CODEX_HOME`, read 2026-04-06 22:2x EDT] `CODEX_HOME` is unset in the shell used for this run.
- [Source: `/Users/leokwan/Development/ai/automations/strongyes-content/automation.toml`, read 2026-04-06] The active repo-backed `strongyes-content` harness still read both self and sibling memory only from `$CODEX_HOME/automations/...` and did not tell the loop to keep memory to a rolling last-3-note window.
- [Source: `~/.codex/sqlite/codex-dev.db` row `strongyes-content`, queried 2026-04-06] The live scheduler prompt matched that same fallback-less harness text, so this was active repo-and-DB drift rather than a stale checkout-only issue.
- [Source: `/Users/leokwan/Development/ai/automations/strongyes-content/memory.md`, read 2026-04-06] The shared live memory file had grown to `10` retained notes and `11557` bytes even though the latest notes were all repeating the same cold-state boundary: Nia initialize still fails, release-train owns the adjacent writer lane, and no named content/provenance lane is active.
- [Source: `/Users/leokwan/Development/ai/automations/strongyes-release-train/automation.toml`, read 2026-04-06] The sibling writer lane already uses the correct `$CODEX_HOME` or `~/.codex` fallback contract plus an explicit keep-last-3 checkpoint rule, so the content radar was the inconsistent outlier inside the same fleet slice.

## Change shipped
1. Tightened `/Users/leokwan/Development/ai/automations/strongyes-content/automation.toml` so self and sibling memory reads fall back to `~/.codex/automations/...` when `$CODEX_HOME` is unset.
2. Added an explicit checkpoint rule requiring the live `strongyes-content` memory file to keep only the last 3 notes.
3. Trimmed the shared `strongyes-content` memory file down to the latest 3 notes.
4. Synced the live SQLite prompt for `strongyes-content` to the same fallback-aware harness text.

## Remaining exposure
- `resplit-nurse`, `resplit-asc`, and `strongyes-flow-radar` still carry more than 3 retained shared notes or larger-than-needed shared memory files, so they remain the next obvious prompt-state hygiene candidates.
- The `7` DB-only active rows (`6` StrongYes burst lanes plus `vidux-meta`) still sit outside repo truth and still need a real ownership decision after the memory-drift cleanup lane.
