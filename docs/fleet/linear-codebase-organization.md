# Linear Codebase Organization

Last updated: 2026-04-27.

This is the durable plan for organizing Linear around codebase-owned Vidux
lanes across Vidux, StrongYes, Resplit Web, and Resplit iOS. It supersedes the
earlier read-only port audit as the active organization plan, but it does not
authorize bulk deletion, project archival, or issue creation on its own.

## Purpose

Linear Projects should answer "which codebase owns this work?" for Vidux
intake. Codebase projects are `strongyes-web`, `resplit-web`, `resplit-ios`,
and `vidux`. Product, feature, and domain groupings such as "UX Overhaul",
"Infrastructure", or "Game Plan" remain useful planning views, but they should
not be the primary project binding that a repo lane ingests from.

## Current Project Map

| Codebase | Linear project | Project id | Repo config state |
| --- | --- | --- | --- |
| `vidux` | `vidux` | `b1473b94-8909-40f4-9cd6-5c6e395f7fb5` | PR `leojkwan/vidux#70` |
| `strongyes-web` | `strongyes-web` | `bf8d1895-4e49-412e-8fc2-71c4ec003f5e` | PR `leojkwan/strongyes-web#937` |
| `resplit-web` | `resplit-web` | `87181bb4-379d-4254-ae5b-4f652cf66755` | PR `firstbitelabsllc/resplit-web#381` |
| `resplit-ios` | `resplit-ios` | `e73259aa-9870-4b5e-b80f-e31e517755a4` | PR `firstbitelabsllc/resplit-ios#514` |

The FirstBite Linear team id used for these project checks is
`2f745857-a4df-4f99-93a9-6ac89f9991a2`.

## Evidence

- The Linear Projects UI on 2026-04-27 showed product/domain buckets as the
  visible project list instead of codebase-owned repo intake projects.
- The Linear API inventory found 255 FirstBite issues during the organization
  pass.
- Sidecar ownership tracing showed 132 active no-project issues were
  owner-proven by StrongYes sidecars, with 0 ambiguous or unmapped issues in
  that batch.
- Linear mutations moved 220 active StrongYes-owned issues into
  `strongyes-web` with 0 API errors.
- Post-move counts were `strongyes-web` total=220 active=220 and `vidux`
  total=35 active=4.

## Guardrails

- Always set both `linear.project_id` and `linear.project_name` once a repo has
  a codebase-owned Linear project.
- Bulk moves require current sidecar or config proof of repo ownership.
- Do not delete Linear issues as part of organization.
- Do not archive or complete legacy product/domain projects without explicit
  confirmation after active issues have been moved.
- Do not treat stale copied sidecar mappings as ownership when another repo's
  current sidecar also owns the issue.

## Tasks

- [completed] LC-1: Inventory Linear projects, FirstBite team, and issue counts.
- [completed] LC-2: Create or normalize codebase projects for active repos.
- [completed] LC-3: Move owner-proven active StrongYes issues into
  `strongyes-web`.
- [in_progress] LC-4: Land Vidux core guardrails so repo configs fail closed
  when a Linear project id resolves to the wrong project name.
- [in_progress] LC-5: Land Resplit repo ports to the codebase projects.
- [in_progress] LC-6: Land StrongYes config scoped to
  `project_id=bf8d1895-4e49-412e-8fc2-71c4ec003f5e` and
  `project_name=strongyes-web`.
- [pending] LC-7: Re-check Linear UI and API after the PRs merge: no active
  codebase-owned issue should live in `(no project)` or a legacy product
  bucket.
- [pending] LC-8: Audit legacy product/domain projects after active movement
  and prepare an archive/keep recommendation for Leo.
- [pending] LC-9: Fix Vidux auto-promote dedupe so a project-scoped source does
  not append items already mapped in any sub-plan sidecar.

## Decisions

- Linear Projects are codebase intake containers for Vidux automation. Product
  structure belongs in plan paths, labels, milestones, or issue text.
- StrongYes stays scoped by `project_id` and `project_name` now, but Linear
  auto-promote remains off until LC-9 is fixed. A dry-run showed
  `auto_promote_target=vidux` would duplicate 220 already-mapped issues into
  the root StrongYes plan.
- Legacy product/domain projects are not automatically archived. They may hold
  useful history and need a separate explicit archive decision.
