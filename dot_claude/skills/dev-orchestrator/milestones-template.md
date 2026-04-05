---
name: milestones-template
description: Template for creating a milestones.md file in any project repo. Copy this template and fill in project-specific milestones.
---

# Milestones Template

Copy the structure below into your project repo as `milestones.md` and fill in your project-specific milestones.

## Format Rules

1. Each milestone has a status tag: `[DONE]`, `[IN PROGRESS]`, or `[PLANNED]`
2. Tasks within milestones use checkbox syntax: `[x]` for done, `[ ]` for remaining
3. Only ONE milestone should be `[IN PROGRESS]` at a time
4. Keep task descriptions short (one line) but specific enough to verify against code
5. Group milestones by phase if the project has multiple phases

## Template

```markdown
# Milestones

## Phase 0

### M1: {Title} [DONE]
- [x] {Completed task 1}
- [x] {Completed task 2}

### M2: {Title} [IN PROGRESS]
- [x] {Completed task}
- [ ] {Remaining task 1}
- [ ] {Remaining task 2}

### M3: {Title} [PLANNED]
- [ ] {Planned task 1}
- [ ] {Planned task 2}

## Phase 1 (Future)

### M4: {Title} [PLANNED]
- [ ] {Planned task 1}
```

## Verification Hints

For each `[DONE]` milestone, the orchestrator will spot-check:
- Do the source files mentioned or implied by the tasks exist?
- Do relevant test files exist and have test cases?
- Does `git log` show commits related to these tasks?

For `[IN PROGRESS]` tasks:
- Are there recent commits touching related files?
- Are there any failing tests that suggest incomplete work?

Tag tasks with file paths where possible to help verification:
```markdown
- [x] Supabase migrations (8 tables) - `supabase/migrations/`
- [x] GameModule interface - `src/game-engine/GameModule.ts`
- [ ] Stripe webhook handler - `src/app/api/v1/payments/`
```
