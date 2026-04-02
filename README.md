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

Clone the repo to wherever you keep your repos, then run the setup script from inside it:

```bash
cd /path/to/cloned/dotfiles
./setup.sh
```

`setup.sh` will:
1. Create a symlink from `~/.local/share/chezmoi` to your cloned repo so chezmoi can find it
2. Install chezmoi if it is not already installed
3. Show a diff of any conflicts between the repo and your existing dotfiles
4. Prompt you to apply, merge interactively, or exit to resolve manually
5. Run `run_once_macos-defaults.sh` automatically (once, on first apply)

If you already have dotfiles on this machine, choose **merge** at the prompt. This opens a 3-way merge for each conflicting file so you can pick which parts to keep. After resolving, `chezmoi apply` is called automatically.

If you skip the prompt, you can resolve conflicts manually at any time:

```bash
chezmoi diff        # review what would change
chezmoi merge-all   # merge conflicts interactively file by file
chezmoi apply       # apply after resolving
```

After setup, open a new terminal or run `source ~/.zshrc` to load Zim modules. Then follow the daily workflow below.

> `chezmoi apply` is a one-time deploy step. Do not run it again on a machine where you are actively editing dotfiles - it overwrites local changes with no undo.

## Daily Workflow (on your main machine)

chezmoi uses a **copy model**: source files in this repo are copied to their target locations in `~`. This means edits to `~/.zshrc`, `~/.claude/CLAUDE.md`, etc. are **not** automatically reflected in the repo - you have to push them back.

The correct direction on your main machine is **local -> repo**:

```bash
# 1. Edit the local file as usual (e.g. ~/.claude/CLAUDE.md, ~/.zshrc)

# 2. Commit and push from the dotfiles repo
#    The pre-push hook runs `chezmoi re-add` automatically before pushing,
#    syncing all modified local files to source so nothing is lost.
cd ~/repos/github.com/kpachhai/dotfiles
git add -p
git commit -S -s -m "your message"
git push

# Pull updates from GitHub (only updates source, does not touch local files)
git pull
```

If you want to check or sync manually at any point:

```bash
chezmoi status    # see which local files differ from source
chezmoi re-add    # sync all local changes to source
chezmoi diff      # see what source differs from local (should be empty after re-add)
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
setup.sh                         Bootstrap script for new machines
dot_claude/                   -> ~/.claude/
  agents/                     -> ~/.claude/agents/
  skills/                     -> ~/.claude/skills/
  rules/                      -> ~/.claude/rules/
  settings.local.json         -> ~/.claude/settings.local.json
  CLAUDE.md                   -> ~/.claude/CLAUDE.md
dot_gitconfig                 -> ~/.gitconfig
dot_tmux.conf                 -> ~/.tmux.conf
dot_zshrc                     -> ~/.zshrc
dot_zsh_profile               -> ~/.zsh_profile
dot_zimrc                     -> ~/.zimrc
run_once_macos-defaults.sh       Runs once on first chezmoi apply
run_once_install-chezmoi-hooks.sh  Installs pre-push hook on first apply
```

## License

ISC
