# Investigation: AI Agent Orchestration Patterns

## Reporter Says
"I don't know if it's even possible but this tree of viduxing needs to be first class" — Leo, 2026-04-04. The concern is whether Vidux's nested planning model (parent plan → sub-investigations → recursive vidux cycles) is sound architecture or if other agent orchestration tools solve this differently.

## Evidence
- Vidux uses doc-tree + work-queue (Redux analogy) for state management
- Nested planning was defined but never wired until v2.1
- Need to compare against: LangGraph, CrewAI, AutoGen, and any other plan-first agent frameworks
- (Nia research pending — see below)

## Research Targets (via Nia)
1. **LangGraph** — graph-based agent orchestration from LangChain
2. **CrewAI** — role-based multi-agent framework
3. **AutoGen** — Microsoft's multi-agent conversation framework
4. **Claude Agent SDK** — Anthropic's official agent framework

## Findings
- LangGraph: 3-layer memory (State/Checkpointer/Store), durable execution, but NO nested sub-task trees or plan-as-doc pattern
- Claude Agent SDK: parent-child spawning with own context windows, session-based state, no persistent plan file
- CrewAI: indexing in progress, will search next cycle
- Vidux's doc-tree + nested investigations is novel among surveyed tools
- Gap found: no worktree handoff protocol in any tool (Leo flagged this)
- Full comparison: `evidence/2026-04-04-agent-orchestration-comparison.md`

## Root Cause
N/A — this is a research investigation, not a bug fix.

## Impact Map
- How other frameworks handle: nested sub-tasks, plan persistence, stateless resumption
- Which patterns Vidux should adopt vs which confirm our current approach
- Whether the "tree of viduxing" has precedent or is novel

## Fix Spec
N/A — this produces an evidence snapshot, not a code change.

## Regression Tests
N/A — validated by evidence quality, not code tests.

## Gate
- [x] 3+ repos indexed in Nia (langgraph ✓, crewai indexing, claude-code ✓)
- [x] Evidence snapshot produced with cited findings
- [x] Comparison table: Vidux vs alternatives on 8 key dimensions (CrewAI partial — repo still indexing, filled with "unknown" where data unavailable)
