#!/usr/bin/env bash
# vidux-gather.sh — Fan-out research template generator
# Outputs prompt templates for Tier 1 (4 groups), Tier 2 (synthesizer), Tier 3 (critic)
# Usage: vidux-gather.sh "What reactive patterns does the team prefer?"
set -euo pipefail
T="${1:?Usage: vidux-gather.sh \"<research topic>\"}"

cat <<EOF
# Vidux Gather — Fan-Out Research Templates
**Topic:** ${T}

## Tier 1: Research Groups (run all 4 in parallel)

### Group A — Evidence
\`\`\`
Research agent for: ${T}
Search team chat for discussions and decisions about this topic.
Search code review comments for related feedback patterns.
Search the issue tracker for requirements and specs.
Search knowledge bases and wikis for documentation.

Write evidence.md with sections: Chat & Discussions, Code Review Feedback,
Issue Tracker, Documentation. Every entry: [Source: type, ref, date] finding.
No unsourced claims. If a section is empty, say so explicitly.
\`\`\`

### Group B — Architecture
\`\`\`
Architecture agent for: ${T}
Search the code repository for existing patterns and implementations.
Read design documents and architecture decision records.
Identify naming conventions, file structure, and module boundaries.
Map dependencies and integration points relevant to this topic.

Write architecture.md with sections: Existing Patterns, Conventions,
Dependencies & Integration Points, Design Documents.
Every finding cites file:line or document reference.
\`\`\`

### Group C — Constraints
\`\`\`
Constraints agent for: ${T}
Search code review history for recurring reviewer preferences.
Search team chat for stated conventions and strong opinions.
Check linter configs, CI rules, and style guides.
Identify stakeholders and what they care about.

Write constraints.md with sections: ALWAYS (must be true), NEVER (forbidden),
ASK FIRST (needs approval + who), Reviewer Preferences (name + source),
Enforced by Tooling. Every constraint cites a source. Mark inferences [Inferred].
\`\`\`

### Group D — Tasks
\`\`\`
Task analysis agent for: ${T}
Search the issue tracker for related work items and epics.
Analyze the codebase for files and modules that would be touched.
Identify dependency chains — what must happen before what.
Flag risks: unknowns, high-churn areas, complex integrations.

Write tasks.md with sections: Candidate Work Items (checkboxed, with scope
S/M/L and risk low/med/high), Dependency Chain, Risks & Unknowns,
Related Existing Work. Be specific about files and scope.
\`\`\`

---
## Tier 2: Synthesizer (after all Tier 1 groups finish)

\`\`\`
Synthesizer for: ${T}
Read: evidence.md, architecture.md, constraints.md, tasks.md

Cross-reference findings — do tasks respect constraints?
Resolve conflicts between groups. Order tasks by dependency and priority.
Flag open questions where groups disagree or evidence is thin.

Write PLAN.md with sections: Purpose, Evidence (merged + cited),
Constraints (ALWAYS/NEVER/ASK FIRST), Decisions (forced by evidence),
Tasks (ordered checkboxes with citations, [P] = parallelizable),
Open Questions (with research actions).
Every claim MUST cite a source from the research outputs.
\`\`\`

---
## Tier 3: Critic (after Tier 2 finishes)

\`\`\`
Critic for: ${T}
Read: PLAN.md, evidence.md, architecture.md, constraints.md, tasks.md

Challenge checklist:
1. Missing evidence — any plan entries unsupported by research?
2. Contradictions — any tasks violate stated constraints?
3. Scope creep — tasks not justified by the original topic?
4. Dependency gaps — missing dependencies between tasks?
5. Stakeholder blind spots — would any key reviewer object?
6. Risk underestimation — risks flagged but not mitigated?

Append ## Critic Review to PLAN.md with: Approved items, Challenged items
(with specific objections), Missing research, Verdict (READY / NEEDS REVISION).
Be adversarial. A weak plan caught now saves days of rework.
\`\`\`
EOF
