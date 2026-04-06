# 2026-04-05 Two-Machine Convergence Analysis

## Goal
Cross-reference endurance findings from two independent machines to identify where they converge (strong signal) vs diverge (needs investigation).

## Sources
- [Source: this-computer scorecard] `skills/vidux/projects/vidux-endurance/evidence/2026-04-05-final-endurance-scorecard.md`
- [Source: other-computer scorecard] `/Users/leokwan/Desktop/vidux-endurance/evidence/2026-04-05-batch-1-scorecard-and-vnext.md`
- [Source: this-computer contradiction test] `skills/vidux/projects/vidux-endurance/evidence/2026-04-05-decision-log-contradiction-test.md`
- [Source: other-computer decision log drill] `/Users/leokwan/Desktop/vidux-endurance/evidence/2026-04-05-decision-log-and-q-gating-drill.md`
- [Source: this-computer stuck-loop test] `skills/vidux/projects/vidux-endurance/evidence/2026-04-05-stuck-loop-mechanical-test.md`
- [Source: other-computer stuck-loop precheck] `/Users/leokwan/Desktop/vidux-endurance/evidence/2026-04-05-live-radar-and-stuck-loop-precheck.md`
- [Source: other-computer control-plane radar] `/Users/leokwan/Desktop/vidux-endurance/evidence/2026-04-05-live-radar-regression-trend.md`

## Findings

### 1. Doctrine Scorecard Convergence

| Doctrine | This Machine | Other Machine | Convergence |
|----------|:---:|:---:|:---:|
| D1: Plan is the store | PASS | pass | **STRONG** — both clean across all projects |
| D2: Unidirectional flow | PASS | pass | **STRONG** — both clean across all projects |
| D3: 50/30/20 split | FRICTION | pass | **DIVERGENT** — this machine couldn't test it (synthetic projects skew planning-heavy); other machine scored it pass |
| D4: Evidence over instinct | PASS | pass | **STRONG** — both cite evidence discipline as a top strength |
| D5: Design for death | PASS | pass-with-friction | **PARTIAL** — both pass the synthetic drill, but other machine found live topology (stale worktrees, missing Active Worktrees) dragging it down |
| D6: Process fixes > code fixes | PASS | friction (weakest) | **DIVERGENT** — this machine scored it pass; other machine identified it as the weakest doctrine batch-wide. Other machine's bar is higher: only counts as pass when process fix is machine-checkable, not prose |
| D7: Investigations not tickets | PASS | friction | **PARTIAL** — this machine's investigation bundling worked well; other machine found scope discipline friction |
| D8: Harnesses are evergreen | PASS | pass-with-friction | **PARTIAL** — both pass the core harness test; other machine found live loop quality issues |
| D9: Subagent coordinator | PASS | pass-with-friction | **PARTIAL** — both confirm the pattern works; other machine found ROI friction on small slices |

### 2. Bug Convergence

| Bug | This Machine | Other Machine | Convergence |
|-----|:---:|:---:|:---:|
| Dependency matcher triple-bug (line 124) | Found: 3 failure modes (self-match, own-depends, "none") | Found: `[Depends: none]` false blocker, dependency self-match | **STRONG** — independently discovered the same root cause |
| Stuck-loop text fragility (line 160) | Found: auto_blocked fires correctly when text matches | Found: first-40-char match misses paraphrased Progress lines | **STRONG** — complementary: this machine proved it works, other proved it's fragile |
| Decision Log contradiction = warning-only | Found: script surfaces entries, LLM judges | Found: agent respected it, but no mechanical block | **STRONG** — same finding from different test approaches |
| ResourceWarning (line 983) | Found: unclosed file handle in every test run | Found: same warning in contract test output | **STRONG** — identical finding |
| blocked vs auto_blocked inconsistency | Found: two fields, no unified contract | Not separately called out | **PARTIAL** — this machine only |
| hot_tasks pre-mutation count (line 42) | Found: computed before stuck-loop mutation | Not separately called out | **PARTIAL** — this machine only |
| Control-plane hygiene | Noted but not deeply explored | Found: 9+ stale worktrees, dual automations on one authority, orphan dirs, stale sibling plans, missing Active Worktrees | **STRONG** — other machine went much deeper; this machine's endurance format didn't exercise live loops |
| D6 enforcement gap | Not separately identified | Found: process fixes decay to prose without machine-checkable artifacts | **PARTIAL** — other machine's key insight; this machine scored D6 pass (lower bar) |

### 3. Strength Convergence

| Strength | This Machine | Other Machine | Convergence |
|----------|:---:|:---:|:---:|
| D1+D2 plan discipline | "rock-solid" | "stable strengths" | **STRONG** |
| D4 evidence discipline | "strongest cultural outcome" | "consistently stronger than intuition-first" | **STRONG** |
| D7 investigation bundling | "one root cause, multiple surfaces" | "valuable when surface genuinely needs them" | **STRONG** |
| D9 subagent fan-out | "saved coordinator context" | "can work well for narrow judgment" | **PARTIAL** — both positive, different scope |
| Product judgment quality | N/A (built real Android app) | "right shape of solution, not busywork" | **PARTIAL** — different evidence but both positive |
| Contract suite stability | 63/63 both runs | 63/63 both runs | **STRONG** |

### 4. Key Divergences to Resolve

1. **D3 scoring**: This machine scored FRICTION (untestable in synthetic format), other machine scored pass. Resolution: D3 is format-dependent — synthetic projects inherently skew planning-heavy. Need a real mini-project to validate.

2. **D6 bar height**: This machine scored PASS (process fix was described), other machine scored FRICTION (process fix must be machine-checkable). Resolution: adopt the higher bar — prose-only process fixes should not count as pass. This is the other machine's strongest insight.

3. **Control-plane scope**: This machine focused on vidux-loop.sh mechanical bugs, other machine focused on live automation topology. Resolution: both are v2.3.0 scope — mechanical fixes AND hygiene checks.

## Recommendations
- Use the STRONG convergence findings as P0 priorities — both machines agree these are real
- Adopt the other machine's higher D6 bar — process fixes must produce enforceable artifacts
- Treat PARTIAL convergence as P1 — real but lower confidence
- Resolve D3 divergence with a real mini-project test in Phase 3
