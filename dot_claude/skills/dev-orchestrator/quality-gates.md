---
name: quality-gates
description: Post-task quality checks triggered by the orchestrator. Mandatory gates always run; suggested gates are recommended but user-optional.
---

# Quality Gates

## How To Use

After each task completes, the orchestrator checks this file for matching triggers. If a trigger matches, the orchestrator recommends (or requires) the specified quality gate.

**Mandatory gates** are non-negotiable - the orchestrator will insist on running them.
**Suggested gates** are recommended - the orchestrator presents them but the user can skip.

## Gates

### Payment Code Touched
- **Trigger:** Any file in `src/app/api/v1/payments/`, `src/server/handlers/` related to credits, or `src/lib/validators/payment*.ts` was created or modified
- **Gate:** Security audit
- **Agent:** `security-auditor`
- **Mandatory:** Yes
- **Focus areas:** Webhook signature verification (timing-safe comparison), idempotency, credit race conditions, input validation, PCI compliance patterns

### New API Endpoint Created
- **Trigger:** New file in `src/app/api/v1/`
- **Gate:** Input validation check
- **Agent:** `code-reviewer`
- **Mandatory:** No
- **Focus areas:** Zod schema completeness, auth middleware presence, error format consistency, rate limiting

### New Game Module Added
- **Trigger:** New directory in `src/game-engine/modules/`
- **Gate:** Interface compliance + test coverage
- **Agent:** `test-engineer`
- **Mandatory:** No
- **Focus areas:** All GameModule interface methods implemented, pure functions (no side effects), immutable state, min 20 test cases, all player count variants tested

### UI Component Created or Modified
- **Trigger:** Files in `src/components/` created or significantly modified
- **Gate:** Accessibility check
- **Agent:** `accessibility-auditor`
- **Mandatory:** No
- **Focus areas:** ARIA attributes, keyboard navigation, color contrast, screen reader compatibility, responsive behavior

### Database Migration Added
- **Trigger:** New file in `supabase/migrations/`
- **Gate:** RLS policy review
- **Agent:** `security-auditor`
- **Mandatory:** Only if migration includes RLS policy changes
- **Focus areas:** RLS policy correctness, no accidental data exposure, index on foreign keys, rollback safety

### Milestone Completion
- **Trigger:** User says a milestone is done, or all tasks in a milestone are checked off
- **Gate:** Full test suite + lint + typecheck
- **Agent:** `test-engineer`
- **Mandatory:** Yes
- **Run:** `npm run test && npm run lint && npm run typecheck`
- **Focus areas:** No regressions, all new code has tests, no type errors, no lint violations

### Before Merge to Main
- **Trigger:** User says they want to merge or create a PR
- **Gate:** Multi-agent review
- **Agents:** `code-reviewer` + `security-auditor`
- **Mandatory:** Yes
- **Focus areas:** Code quality, security vulnerabilities, test coverage, documentation completeness

## Evolving Gates

Track gate effectiveness in the Lessons Log (SKILL.md):
- If a suggested gate catches a real issue 3+ times, upgrade it to mandatory
- If a mandatory gate has never caught an issue after 10+ runs, consider downgrading to suggested
- If a gate consistently provides low-value feedback, remove it
