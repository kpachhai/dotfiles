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

## Subagents Available

Use these when the task matches their specialty:
- `code-reviewer` - Read-only code review (Sonnet, fast)
- `researcher` - Deep research with web search (Opus, thorough)
- `debugger` - Systematic bug tracing (Sonnet, fast)
- `writer` - Technical documentation (Sonnet)
- `security-auditor` - Security audit and threat modeling (Opus, thorough)
- `solidity-engineer` - Smart contracts and EVM smart contracts (Opus)
- `dev-advocate` - Tutorials, demos, conference content (Sonnet)
- `architect` - System design and ADRs (Opus)
