# 2026-04-07 Agentic Orchestration Patterns Research

## Goal
Identify patterns and gaps in vidux by surveying the current agentic orchestration landscape.

## Sources
- [Source: nia_research, 2026-04-07] MCO (mco-org/mco), MCO Squad (mco-org/squad), OpenSpec (Fission-AI/OpenSpec)
- [Source: nia_research, 2026-04-07] anthropics/claude-code CHANGELOG.md, plugins/
- [Source: nia_research, 2026-04-07] OpenClaw PR #42933 (circuit breaker), bradAGI/awesome-cli-coding-agents
- [Source: nia_research, 2026-04-07] BSWEN SDD survey (2026-03-25)

## Findings

### 1. MCO — neutral orchestration layer with mature task FSM
MCO fans out tasks to Claude Code, Codex CLI, Gemini CLI in parallel, synthesizes via agreement scoring. Task states: DRAFT→QUEUED→DISPATCHED→RUNNING→COMPLETED/FAILED/CANCELLED/EXPIRED. Dual timeouts: 900s stall detection (output byte monitoring) + 1800s hard deadline. Ships MCP server mode (`mco serve`). Vidux is architecturally distinct (plan-first vs task-parallel-consensus) but MCO's transport layer and stall detection are adoptable patterns.

### 2. MCO Squad — SQLite coordination bus with lease-based ownership
Rust CLI, agents join via slash commands, coordinate through shared SQLite+WAL. Key patterns vidux lacks: 15-minute lease-based task ownership, heartbeat staleness (active <60s, idle 1-10m, stale >10m), session displacement tokens. `squad doctor` checks orphaned tasks.

### 3. OpenSpec — validates vidux's plan-first thesis
TypeScript SDD framework: Draft→Proposed→Applying→Archived. Requirements use SHALL/MUST keywords. Artifact dependency graph (proposal→specs→design→tasks), each PENDING→READY→DONE. Close to vidux's unidirectional flow but adds formal requirement syntax and DAG-structured tasks.

### 4. Claude Code native multi-agent primitives
Now includes: /loop, /batch, TeammateIdle/TaskCompleted hook events, named subagents with @mention, background agents with auto-resume, task management with dependency tracking. Vidux should emit these hooks for native integration.

### 5. Circuit breakers are production necessities
OpenClaw PR #42933: session-level circuit breaker, pause after N consecutive errors. MCO: dual timeouts. GSD (46K stars): dedicated stuck-loop detection. Vidux mentions "design for completion" but has no formal circuit breaker.

### 6. Landscape: 106+ CLI agents, orchestrators ~10%
Plan-driven tools are ~5 entries (4%). Vidux sits at plan-driven + orchestrator intersection — almost unique positioning.

## Recommendations (priority gaps)
1. Circuit breaker / stuck detection — adopt MCO dual-timeout + OpenClaw consecutive-error counter
2. Task dependency graph — flat tasks → DAG-structured (OpenSpec model)
3. Lease-based task ownership — MCO Squad 15-min lease pattern
4. Hook integration — emit TeammateIdle/TaskCompleted for Claude Code awareness
5. MCP server transport — expose vidux as MCP tools for cross-tool portability
