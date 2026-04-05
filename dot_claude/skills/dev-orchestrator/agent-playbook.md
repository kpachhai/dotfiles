---
name: agent-playbook
description: Maps task patterns to optimal agent sequences and quality gates. Living document - update when sequences prove suboptimal.
---

# Agent Playbook

## How To Use

When the orchestrator identifies a task, look up the matching pattern below. The agent sequence defines which agents to dispatch and in what order. The quality gate defines what review runs after the task completes.

**Conventions:**
- Agent names match the `subagent_type` values from the Agent tool
- Sequential agents run one after another (output of one informs the next)
- Parallel agents (marked with `||`) can run simultaneously
- Quality gates marked `MANDATORY` always run; others are suggested

## Task Patterns

### New API Endpoint
- **Agents:** `backend-architect` -> `test-engineer` -> `code-reviewer`
- **Quality Gate:** `security-auditor` (MANDATORY if touches auth or payments)
- **Context to provide:** API conventions from CLAUDE.md Section 4 (API Routes), Zod validator patterns from `src/lib/validators/`, existing route examples from `src/app/api/v1/`

### New Game Module
- **Agents:** `architect` (design board geometry + rules) -> `backend` (implement GameModule interface) -> `test-engineer` (min 20 test cases per variant) -> `code-reviewer`
- **Quality Gate:** `frontend-developer` (board renderer component)
- **Context to provide:** GameModule interface from `src/game-engine/GameModule.ts`, existing module examples (LudoModule, ChessModule), AI strategy interface from `src/game-engine/ai/types.ts`

### UI Component or Page
- **Agents:** `frontend-developer` -> `accessibility-auditor` -> `test-engineer`
- **Quality Gate:** `code-reviewer`
- **Context to provide:** Existing UI components in `src/components/ui/`, Tailwind config, responsive breakpoint conventions, dark theme color palette

### Database Migration
- **Agents:** `database-optimizer` (schema review) -> `backend` (write migration SQL) -> `test-engineer`
- **Quality Gate:** `security-auditor` (MANDATORY if RLS policy changes)
- **Context to provide:** Existing migrations in `supabase/migrations/`, current schema types from `src/types/database.ts`, RLS patterns from existing policies

### WebSocket Handler
- **Agents:** `backend-architect` -> `test-engineer` -> `code-reviewer`
- **Quality Gate:** `security-auditor` (if auth-related)
- **Context to provide:** Message protocol from `src/types/ws.ts`, existing handlers in `src/server/handlers/`, GameRoom patterns from `src/server/GameRoom.ts`

### Payment Integration
- **Agents:** `backend-architect` -> `test-engineer` -> `security-auditor` (MANDATORY)
- **Quality Gate:** `code-reviewer`
- **Context to provide:** Credit transaction schema, payment webhook patterns, Zod validators for payment payloads, idempotency key patterns

### Performance Optimization
- **Agents:** `code-reviewer` (profile and identify bottlenecks) -> domain-specific agent -> `test-engineer`
- **Quality Gate:** None
- **Context to provide:** Performance targets from north-star (<3s load, 60fps, <100ms move latency)

### Bug Fix
- **Agents:** `debugger` (root cause analysis) -> domain-specific agent (implement fix) -> `test-engineer` (regression test)
- **Quality Gate:** `code-reviewer`
- **Context to provide:** Error logs, reproduction steps, relevant test files

### Documentation
- **Agents:** `writer`
- **Quality Gate:** None
- **Context to provide:** Existing docs in `docs/`, README conventions

### Deployment / Infrastructure
- **Agents:** `devops-automator`
- **Quality Gate:** `security-auditor`
- **Context to provide:** Current hosting setup (Vercel + Railway), environment variable patterns, CI/CD config

## Updating This Playbook

When an agent sequence proves suboptimal (wrong agent order, missing agent, unnecessary step), update this file and add an entry to the Lessons Log in SKILL.md. Examples of when to update:
- Security audit found issues that test-engineer should have caught first
- An agent was dispatched but had nothing useful to contribute
- Parallel agents would have been faster than sequential
- A quality gate consistently catches nothing (remove it)
- A quality gate consistently catches real issues (upgrade to MANDATORY)
