# Vidux Public Plan

## Purpose
Open-source the portable Vidux core as a lightweight orchestration system for long-running AI work, with documentation, hooks, and scripts that can survive session death and keep agent work grounded in evidence.

## Evidence
- [Source: `SKILL.md`] Vidux defines the plan as the store, code as the view, and separates Layer 1 core from Layer 2 project wiring.
- [Source: `DOCTRINE.md`] The public doctrine already captures the Redux mapping and the 50/30/20 planning split.
- [Source: `LOOP.md`] The core loop is stateless and file-backed, which makes it open-sourceable without private runtime infrastructure.
- [Source: `guides/vidux/quickstart.md`] The install and first-run story can be documented from repo-root paths without relying on Leo's private `ai` super-repo layout.

## Constraints
- ALWAYS: keep the public repo Layer 1 and company-agnostic.
- ALWAYS: make scripts and docs work from this repo root.
- ASK FIRST: accept external pull requests or major doctrine rewrites.
- NEVER: publish private project evidence, local machine paths, or repo-specific product plans.
- NEVER: turn the public repo into a dump of internal automation state.

## Decisions
- [2026-04-06] Decision: publish the portable Vidux core in its own public repo instead of exposing the entire `ai` skills repo. Alternatives: keep Vidux private, or publish the whole skills tree. Rationale: the core is reusable, while the surrounding repo carries personal and project-specific wiring. Evidence: `SKILL.md`, `DOCTRINE.md`, `guides/vidux/architecture.md`.
- [2026-04-06] Decision: use Issues for public feedback and decline outside PR contributions for now. Alternatives: accept open PRs immediately, or disable public feedback entirely. Rationale: feedback is useful for shaping the doctrine, but maintaining review quality on unsolicited code is not the current goal. Evidence: `README.md`, `CONTRIBUTING.md`.

## Tasks
- [completed] Task 1: Export the portable Vidux core into a dedicated public repo with docs, commands, scripts, hooks, and tests. [Evidence: `SKILL.md`, `LOOP.md`, `guides/vidux/quickstart.md`] [Depends: none]
- [pending] Task 2: Add a public example mission under `projects/` that shows a clean external-plan workflow without private repo references. [Evidence: `guides/vidux/quickstart.md`, `commands/vidux.md`] [Depends: Task 1]
- [pending] Task 3: Harden the generic install and doctor helpers against more non-Leo layouts and validate them on a clean checkout. [Evidence: `scripts/vidux-install.sh`, `scripts/vidux-doctor.sh`] [Depends: Task 1]

## Open Questions
- [ ] Q1: Should the public repo ship example automation harnesses, or stay focused on the skill and loop contract first? -> Action: gather feedback from Issues after first publish.

## Surprises
- [2026-04-06] The first scaffold pass accidentally mirrored internal root plan files. Impact: public repo would have leaked the wrong story. Plan update: replace them with a public-facing root plan and keep private project history out of this repo.

## Progress
- [2026-04-06] Cycle 1: Seeded the public repo with the portable Vidux docs, commands, hooks, scripts, and contract tests, then rewired the docs to repo-root paths and added a feedback-only public policy. outcome=useful. Next: Task 2. Blocker: none.

