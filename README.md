# Vidux

The Redux of planned vibe coding.

Vidux is a lightweight orchestration system for long-running AI work. The core rule is simple:

- The plan is the store.
- Code is the view.
- Every change flows through evidence -> plan -> execution -> verification -> checkpoint.

Vidux is built for work that spans multiple sessions, multiple agents, or multiple days. Instead of hiding state in chat history, it keeps state in files that any fresh agent can rehydrate from.

## What Ships Here

- `SKILL.md` — the full Vidux contract
- `DOCTRINE.md` — the short doctrine
- `LOOP.md` — the stateless cycle
- `commands/` — `/vidux`, `/vidux-plan`, `/vidux-status`
- `scripts/` — loop, checkpoint, gather, doctor, install helpers
- `hooks/` — prompt-hook nudges for plan discipline
- `guides/vidux/` — quickstart, architecture, best practices
- `tests/` — contract tests for the public surface

## Install

Clone the repo anywhere, then symlink it into your tool:

```bash
git clone git@github.com:leojkwan/vidux.git
ln -sfn /path/to/vidux ~/.claude/skills/vidux
ln -sfn /path/to/vidux ~/.cursor/skills/vidux
ln -sfn /path/to/vidux ~/.codex/skills/vidux
```

Optional hook install for a target repo:

```bash
bash scripts/install-hooks.sh /path/to/your/project
```

## Why It Exists

Most agent failures are state failures:

- the plan lived in chat instead of files
- code was written before evidence existed
- a later session could not tell what was intentional
- the same bug got "fixed" three different ways

Vidux solves that by making documentation the control plane.

## Public Policy

This repo is public because the core ideas are meant to be reused and pressure-tested.

- Feedback is welcome through GitHub Issues.
- External pull requests are not being accepted yet.
- The public repo only ships the portable Layer 1 core, not private Layer 2 project wiring.

## Start Here

- [Quickstart](guides/vidux/quickstart.md)
- [Architecture](guides/vidux/architecture.md)
- [Best Practices](guides/vidux/best-practices.md)
