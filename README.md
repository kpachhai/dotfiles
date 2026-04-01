# dotfiles

Personal configuration files managed with [chezmoi](https://www.chezmoi.io/).

## What's Included

| Category | What | Highlights |
|----------|------|------------|
| **Claude Code** | Settings, 8 subagents, 3 skills | Opus default, auto-permissions, desktop notifications |
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

After setup, install Zim modules by opening a new terminal or running `source ~/.zshrc`.

## Day-to-Day Usage

```bash
# After changing a config file locally, update the source
chezmoi add ~/.zshrc              # Re-add changed file

# See what would change
chezmoi diff

# Apply changes from source to home
chezmoi apply

# Pull latest from GitHub and apply
chezmoi update
```

## Claude Code Subagents

| Agent | Model | Purpose |
|-------|-------|---------|
| `code-reviewer` | Opus | Read-only code review |
| `researcher` | Opus | Deep research with citations |
| `debugger` | Opus | Systematic bug tracing |
| `writer` | Opus | Technical documentation |
| `security-auditor` | Opus | Security audit, threat modeling |
| `solidity-engineer` | Opus | Smart contracts, EVM smart contracts |
| `dev-advocate` | Opus | Tutorials, demos, talks |
| `architect` | Opus | System design, ADRs |

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
- `~/.claude/settings.local.json` - AIM hooks, machine-specific permissions
- `~/.claude/projects/` - Auto-memory (machine-specific paths)
- `~/.zim/` - Zim modules (installed per-machine)

## File Layout (chezmoi source)

```
dot_claude/           -> ~/.claude/
  agents/             -> ~/.claude/agents/
  skills/             -> ~/.claude/skills/
  rules/              -> ~/.claude/rules/
  settings.json       -> ~/.claude/settings.json
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
