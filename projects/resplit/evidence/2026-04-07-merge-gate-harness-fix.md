# Merge-Gate Harness Fix — 2026-04-07

## Problem

All three active Resplit automations (resplit-web, resplit-asc, resplit-currency) ship code to git worktrees but never merge back to master. This means no TestFlight builds get cut from completed work. Additionally, resplit-android is owner-blocked (needs privacy policy URL and Play signing inputs) but was running every 20 minutes, burning tokens for zero output.

## Changes Made

### 1. Merge-to-master instruction appended to 3 automation prompts

Added to resplit-web, resplit-asc, resplit-currency:

> After completing work in a worktree: merge the worktree branch to origin/master, push, then delete the worktree. If merge conflicts exist, resolve them. A worktree with completed work that is NOT merged to master is unfinished work — do not checkpoint until the merge lands.

### 2. resplit-android paused

Status changed from ACTIVE to PAUSED until privacy policy URL and Play signing inputs are provided.

## Before/After Prompt Sizes

| Automation        | Before (chars) | After (chars) | Delta |
|-------------------|----------------|---------------|-------|
| resplit-web       | 2069           | 2345          | +276  |
| resplit-asc       | 2306           | 2582          | +276  |
| resplit-currency  | 2613           | 2889          | +276  |

## Final Verification

| Automation        | Status | Prompt Length |
|-------------------|--------|--------------|
| resplit-web       | ACTIVE | 2345         |
| resplit-asc       | ACTIVE | 2582         |
| resplit-currency  | ACTIVE | 2889         |
| resplit-android   | PAUSED | 2998         |

## Rationale

Worktree isolation is good for parallel development but worthless if completed work never reaches master. The merge instruction closes the loop: work is not considered done until it lands on origin/master and the worktree is cleaned up. This directly unblocks TestFlight builds. Pausing android stops a known-blocked automation from consuming Codex tokens with no possible output.

## DB Modified

`~/.codex/sqlite/codex-dev.db` — automations table, updated_at set to current epoch ms.
