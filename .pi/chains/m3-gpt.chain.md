---
name: m3-gpt
description: MiniMax implementation followed by GPT-5.5 xhigh review gate
---

## scout
model: minimax/MiniMax-M3
output: context.md

Inspect the codebase for {task}. Gather only the context needed for implementation. Include relevant files, entry points, constraints, risks, and open questions.

## planner
model: openai-codex/gpt-5.5:xhigh
reads: context.md
output: plan.md

Create a concrete implementation plan for {task}. Follow SPEC.md, TODO.md, and AGENTS.md. Do not edit code.

## worker
model: minimax/MiniMax-M3
reads: context.md+plan.md
progress: true

Implement the approved plan with the smallest correct change. Follow existing patterns. Run focused validation. Do not make unapproved product or architecture decisions.

## reviewer
model: openai-codex/gpt-5.5:xhigh
reads: context.md+plan.md+progress.md

Review-only. Do not edit files.

Inspect the actual diff, changed files, SPEC.md, TODO.md, AGENTS.md, and relevant tests directly from the repository.

Check:
- correctness and regressions
- alignment with SPEC.md and TODO.md
- architecture boundaries
- tests and validation quality
- unnecessary complexity
- AI-slop patterns
- edge cases

Return blockers, fixes worth doing now, optional improvements, and feedback to ignore or defer.