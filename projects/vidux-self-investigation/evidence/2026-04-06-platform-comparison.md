# Claude Code vs Codex Automation Comparison

**Date:** 2026-04-06
**Source:** platform-research agent (web search + codebase analysis)

## Claude Code — 3 Tiers of Scheduling

| Tier | Persistence | Location | Min Interval | Local Files | Worktree |
|------|-------------|----------|-------------|-------------|----------|
| `/loop` (session) | None — dies with session | In-memory | 1 min | Yes | No |
| Desktop Scheduled Tasks | Yes — survives restart | `~/.claude/scheduled-tasks/` | 1 min | Yes | Toggle per task |
| Cloud Scheduled Tasks | Yes — Anthropic infra | Web UI / `/schedule` | 1 hour | No (fresh clone) | N/A |

- Desktop tasks are the closest equivalent to Codex automations for local execution
- Cloud tasks always start from a fresh clone on `claude/`-prefixed branches
- Desktop tasks catch up missed runs (1 catch-up within 7 days)

## Codex CLI Automations

- Config: `~/.codex/automations/<name>/automation.toml` (TOML with RRULE scheduling)
- State DB: `~/.codex/state_5.sqlite` (vidux-doctor.sh queries this)
- Fleet pattern: writer + radars + coordinator with staggered BYMINUTE offsets
- Execution: `local` or `cloud` via `execution_environment` field

## Platform Detection

- **Codex:** Check `~/.codex/state_5.sqlite` or `$CODEX_HOME`
- **Claude Code:** Check `claude` CLI or `~/.claude/` directory

## Worktree vs Local

| Dimension | Worktree | Local |
|-----------|----------|-------|
| Isolation | Full (branch) | None |
| Freshness | Snapshot at creation | Always current |
| Disk space | Additional copy | None |
| Concurrent safety | Multi-agent safe | One writer at a time |
| Best for | Writers, parallel agents | Radars (read-only) |

## Key Finding

vidux's `/vidux-loop` is platform-agnostic — generates TOML for Codex, cron for Claude Desktop, or manual instructions. The fleet pattern works identically on both.
