# dotfiles

Personal configuration files managed with [chezmoi](https://www.chezmoi.io/).

## What's Included

| Category | What | Highlights |
|----------|------|------------|
| **Claude Code** | Settings, 17 subagents, 3 skills | Opus default, auto-permissions, desktop notifications |
| **Zsh** | Zim framework, autosuggestions, syntax highlighting | Fish-like experience with history substring search |
| **Git** | GPG signing, user config | DCO sign-off ready |
| **Tmux** | Mouse mode, vi keys | Minimal config |
| **macOS** | Developer defaults | Fast key repeat, Finder tweaks, Dock auto-hide, no smart quotes |

## Prerequisites

Install these before running the setup:

| Tool | Install | Purpose |
|------|---------|---------|
| **Homebrew** | [brew.sh](https://brew.sh/) | macOS package manager |
| **Git** | `brew install git` | Version control |
| **GPG** | `brew install gnupg` | Commit signing (configure your own key) |
| **Claude Code** | [claude.ai/code](https://claude.ai/code) | AI coding assistant CLI |
| **Node.js** | `brew install nvm && nvm install --lts` | JavaScript runtime |
| **Tmux** | `brew install tmux` | Terminal multiplexer |

Optional (installed automatically by configs if missing):
- **Zim** - Installed automatically by `.zshrc` on first shell launch
- **chezmoi** - Can self-install during setup (see below)

## Setup on a New Machine

This is the only time you should run `chezmoi apply` - it deploys the repo contents to the machine. After this, follow the daily workflow above.

```bash
# Install chezmoi and apply dotfiles in one command
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply kpachhai

# Or if chezmoi is already installed
chezmoi init --apply kpachhai
```

This will:
1. Clone this repo to `~/.local/share/chezmoi`
2. Copy all dotfiles to their target locations (`~/.zshrc`, `~/.claude/`, etc.)
3. Run `run_once_macos-defaults.sh` to apply macOS developer defaults (restarts Dock/Finder)
4. On first shell launch, Zim auto-installs its modules (autosuggestions, syntax highlighting, etc.)

After setup, open a new terminal or run `source ~/.zshrc` to load Zim modules. From this point on, use the daily workflow above - do not run `chezmoi apply` again unless you explicitly want to overwrite local files with repo versions.

## Daily Workflow (on your main machine)

chezmoi uses a **copy model**: source files in `~/.local/share/chezmoi` (this repo) are copied to their target locations in `~`. Edits to local files (`~/.zshrc`, `~/.claude/CLAUDE.md`, etc.) are **not** automatically reflected in the repo.

> **Warning:** Never run `chezmoi apply` on a machine where you actively edit dotfiles. It overwrites local changes with the repo version and there is no undo.

The correct direction on your main machine is **local -> repo**, not the other way around:

```bash
# 1. Edit the local file as usual (e.g. ~/.claude/CLAUDE.md, ~/.zshrc)

# 2. Commit and push - the pre-push hook runs `chezmoi re-add` automatically,
#    syncing all modified local files to source before the push goes through
cd ~/.local/share/chezmoi
git add -p
git commit -S -s -m "your message"
git push   # re-add runs here automatically

# Pull updates from GitHub (safe - only updates source, does not apply)
git pull
```

If you want to manually check or sync at any point:

```bash
chezmoi status          # see what local files differ from source
chezmoi re-add          # sync all local changes to source (no-op if clean)
chezmoi diff            # see what source differs from local (should be empty after re-add)
```

To apply source changes to local files (e.g. after pulling on a fresh machine):

```bash
# Preview first - always
chezmoi diff

# Apply only if the diff shows what you expect
chezmoi apply
```

## Claude Code Subagents

| Agent | Model | Purpose |
|-------|-------|---------|
| `code-reviewer` | Opus | Read-only code review |
| `researcher` | Opus | Deep research with citations |
| `debugger` | Opus | Systematic bug tracing |
| `writer` | Opus | Technical documentation |
| `security-auditor` | Opus | General security audit, threat modeling, OWASP |
| `blockchain-security-auditor` | Opus | Adversarial Solidity audit, DeFi exploit analysis |
| `solidity-engineer` | Opus | Smart contracts, EVM smart contracts |
| `dev-advocate` | Opus | Tutorials, demos, talks |
| `architect` | Opus | System design, ADRs |
| `frontend-developer` | Opus | React/Vue/Angular, UI, accessibility, performance |
| `backend-architect` | Opus | API design, scalability, server-side architecture |
| `ai-engineer` | Opus | ML models, LLM integration, RAG, embeddings |
| `devops-automator` | Opus | CI/CD, Docker, Kubernetes, GitHub Actions |
| `database-optimizer` | Opus | Schema design, query performance, indexing |
| `mcp-builder` | Opus | MCP server design and implementation |
| `accessibility-auditor` | Opus | WCAG compliance, ARIA, screen readers |
| `api-tester` | Opus | API validation, endpoint testing, OWASP API Security |

## Claude Code Skills (Slash Commands)

- `/review-pr <number>` - Structured PR review
- `/debug <error>` - Systematic debugging
- `/quick-research <topic>` - Fast research brief

## Zsh Features (via Zim)

- **Autosuggestions** - Fish-like suggestions as you type (right arrow to accept)
- **Syntax highlighting** - Valid commands in green, invalid in red
- **History substring search** - Type partial command, up arrow to search history
- **Smart completions** - Tab completion with descriptions
- **Git aliases** - `gst`, `gco`, `gcm`, etc.

## macOS Defaults

The `run_once_macos-defaults.sh` script runs automatically on first `chezmoi apply`. It sets:
- Fast keyboard repeat, no press-and-hold
- No smart quotes/dashes/autocorrect (breaks code)
- Finder: show extensions, path bar, list view, search current folder
- Dock: auto-hide, no animation delay, no recent apps
- Screenshots: PNG, no shadow
- Auto software updates

To re-run: `chezmoi state delete-bucket --bucket=scriptState && chezmoi apply`

## Machine-Specific Config

Not synced (use for per-machine overrides):
- `~/.claude/settings.json` - AIM hooks, machine-managed (chezmoi ignores this)
- `~/.claude/projects/` - Auto-memory (machine-specific paths)
- `~/.zim/` - Zim modules (installed per-machine)

## File Layout (chezmoi source)

```
dot_claude/           -> ~/.claude/
  agents/             -> ~/.claude/agents/
  skills/             -> ~/.claude/skills/
  rules/              -> ~/.claude/rules/
  settings.local.json -> ~/.claude/settings.local.json
  CLAUDE.md           -> ~/.claude/CLAUDE.md
dot_gitconfig         -> ~/.gitconfig
dot_tmux.conf         -> ~/.tmux.conf
dot_zshrc             -> ~/.zshrc
dot_zsh_profile       -> ~/.zsh_profile
dot_zimrc             -> ~/.zimrc
run_once_macos-defaults.sh  -> Runs once on first apply
```

## License

ISC
