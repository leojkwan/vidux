# 2026-04-04 Agent Orchestration Pattern Comparison

## Goal
Compare Vidux's doc-tree + work-queue model against LangGraph, CrewAI, and Claude Agent SDK to validate or challenge the "tree of viduxing" nested planning approach.

## Sources
- [Source: Nia search, langchain-ai/langgraph] README.md, concepts/durable_execution.md, concepts/agentic_concepts.md, agents/context.md, cloud/how-tos/stateless_runs.md
- [Source: Nia search, anthropics/claude-code] Agent SDK architecture (general patterns, limited specific file access)
- [Source: Nia index, crewAIInc/crewAI] Indexing in progress — will search next cycle

## Findings

### 1. LangGraph: Graph-based state with checkpointer persistence
- Uses **State + Checkpointer + Store** three-layer memory model
- State = session schema, Checkpointer = step-level saves, Store = cross-session long-term
- Supports **durable execution**: auto-resume from checkpoints after failures
- Tasks are async with checkpointing but **no explicit nested sub-task hierarchy**
- Human-in-the-loop: execution can pause indefinitely for approval
- **Key gap vs Vidux**: No plan-as-store concept. State is graph state, not a human-readable doc tree. No investigation/sub-plan pattern.

### 2. Claude Agent SDK: Session-based with parent-child agents
- Sub-agents spawned for specialized tasks with own context windows
- Parent aggregates results from children
- State snapshots for session handoff
- **Key gap vs Vidux**: No persistent plan file. State lives in session, not in git-tracked markdown. No evidence-citation or decision-log pattern.

### 3. Vidux Differentiation (confirmed)
- **Doc tree IS the store**: human-readable, git-tracked, any-agent-resumable
- **Nested investigations**: recursive plan-within-a-plan (unique among surveyed tools)
- **Decision Log**: prevents remediation spam in stateless cron loops (no equivalent in LangGraph/CrewAI)
- **Evidence citation**: every plan entry traces to a source (no equivalent)
- **Trade-off**: Vidux requires markdown literacy; LangGraph/CrewAI use programmatic state

### 4. Gap Identified: Worktree Handoff
- None of the surveyed tools have a "pass incomplete worktree to next cron cycle" pattern
- LangGraph's checkpointer comes closest but operates at graph-state level, not git-worktree level
- This is a real gap in Vidux doctrine — Leo flagged it in this session

### 5. Comparison Table

| Dimension | LangGraph | CrewAI (partial) | Claude Agent SDK | **Vidux** |
|-----------|-----------|------------------|------------------|-----------|
| State store | Graph state object | Agent memory (indexing) | Session snapshots | **PLAN.md (git-tracked markdown)** |
| Nested sub-tasks | No native hierarchy | Role delegation (TBD) | Parent-child spawning | **Investigation files (recursive plans)** |
| Stateless resume | Checkpointer replay | Unknown | Session restore | **Any agent reads PLAN.md, picks up** |
| Cross-session persistence | Store (long-term memory) | Unknown | Manual snapshots | **Git history IS persistence** |
| Anti-loop protection | None found | Unknown | None found | **Decision Log + stuck detection** |
| Evidence citation | None | None | None | **Every plan entry cites a source** |
| Human readability | Low (graph state) | Medium (agent config) | Low (session state) | **High (markdown in git)** |
| Parallel execution | Task system (async) | Multi-agent roles | Agent Teams | **Fan-out pattern + worktrees** |

## Recommendations
- The tree-of-viduxing (nested investigations) IS novel and worth keeping
- Add worktree handoff protocol to Vidux doctrine (note incomplete worktree in PLAN.md Progress for next cycle)
- Add mechanical stuck-loop enforcement: if vidux-loop.sh reports `stuck: true`, the harness should mark the task [blocked] and move to the next lane
- Add Doctrine 9: subagent coordinator pattern for token efficiency (parent reads plan, spawns workers, stays lean)
