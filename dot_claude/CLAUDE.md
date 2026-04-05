# Global Claude Code Instructions

## Identity

I'm YOUR_NAME - software engineer working primarily in blockchain (platform/platform ecosystem), full-stack development, and developer advocacy. I work across Solidity, Go, TypeScript, Python, and Rust.

## Git Commits

- **ALWAYS** use `git commit -S -s -m` for every commit in every repo. Never use plain `git commit -m`.
  - `-S` - GPG sign the commit
  - `-s` - add Signed-off-by line (DCO)
- **NEVER** add `Co-Authored-By` lines or mention Claude/AI in commit messages.
- **NEVER** run `git commit` or `git push` unless the user explicitly asks you to. Always wait for the user to initiate commits and pushes. Preparing changes is fine; committing and pushing is the user's decision.

## Code Style Preferences

- Prefer simplicity over cleverness - readable code wins
- Use descriptive variable names - no single-letter variables except loop counters
- Error handling: fail fast, fail loud - don't silently swallow errors
- Use hyphens (`-`) or semicolons (`;`) instead of em-dashes in all generated content
- Prefer composition over inheritance
- Keep functions small - if it doesn't fit on one screen, split it

## Communication Style

- Be concise and direct - lead with the answer, not the reasoning
- No trailing summaries of what was just done (I can read the diff)
- No emojis unless I explicitly ask
- When giving options, recommend one and explain why

## Review Standards

- Security is non-negotiable - always check for OWASP Top 10
- Always verify facts and stats against current sources before hardcoding
- No placeholder text in final outputs
- Test every code example before presenting it

## Workspace Conventions

- All project artifacts go in `workspace/<project>/`, never at repo root
- Consistent naming: lowercase, hyphens only
- Versioned files: `<slug>-<type>-v<N>.md` - keep only latest version
- North Star documents are immutable once approved

## Global Skills

Available across all projects via `~/.claude/skills/`:
- `skill-improver` - Extracts reusable knowledge from work sessions into skill updates or new skills. Triggers: investigation > 10 min, workaround found, misleading error, config diverged from docs. Opt-in only.
- `session-wrap` - Structured end-of-session protocol capturing: accomplished, learned, should change, ACT NOW, PARKED items. Triggers on wrap-up cues. Opt-in only.
- `review-pr` - PR review with structured checklist
- `debug` - Systematic debugging workflow
- `quick-research` - Quick research briefs
- `dev-orchestrator` - Session-level development conductor. Reads project context (CLAUDE.md, milestones, git history), presents briefing, recommends tasks with agent assignments, dispatches agents on demand. Opt-in; trigger with "let's work on [project]" or "what should I work on next?"

## Subagents Available

Use these when the task matches their specialty:
- `code-reviewer` - Read-only code review
- `researcher` - Deep research with web search
- `debugger` - Systematic bug tracing
- `writer` - Technical documentation
- `security-auditor` - General security audit and threat modeling
- `blockchain-security-auditor` - Adversarial Solidity audit, DeFi exploit analysis
- `solidity-engineer` - Smart contracts and EVM smart contracts
- `dev-advocate` - Tutorials, demos, conference content
- `architect` - System design and ADRs
- `frontend-developer` - React/Vue/Angular, UI, accessibility, performance
- `backend-architect` - API design, scalability, server-side architecture
- `ai-engineer` - ML models, LLM integration, RAG, embeddings
- `devops-automator` - CI/CD, Docker, Kubernetes, GitHub Actions
- `database-optimizer` - Schema design, query performance, indexing
- `mcp-builder` - MCP server design and implementation
- `accessibility-auditor` - WCAG compliance, ARIA, screen readers
- `api-tester` - API validation, endpoint testing, OWASP API Security
