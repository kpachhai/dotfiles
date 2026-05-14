# dotfiles

Personal configuration files managed with [chezmoi](https://www.chezmoi.io/).

## What's Included

| Category | What | Highlights |
|----------|------|------------|
| **Claude Code** | Settings, 17 subagents, 17 global skills | Opus default, auto-permissions, desktop notifications, repo PII scrubbing (`scrub-repo`) |
| **Zsh** | Zim framework, autosuggestions, syntax highlighting | Fish-like experience with history substring search |
| **Git** | GPG signing, per-machine email | DCO sign-off ready, work email auto-set for configured org repos |
| **iTerm2** | Catppuccin Mocha, MesloLGS Nerd Font | True color, auto-installed profile, 14pt font |
| **Tmux** | Catppuccin theme, easy splits, Claude Code agent teams | Alt+arrow pane nav, top status bar, vi copy mode |
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
- **iTerm2** - Installed automatically on first `chezmoi apply` with Catppuccin Mocha profile
- **MesloLGS Nerd Font** - Installed automatically with iTerm2 setup
- **Zim** - Installed automatically by `.zshrc` on first shell launch
- **chezmoi** - Can self-install during setup (see below)
- **git-filter-repo** - `brew install git-filter-repo`. Used by the `scrub-repo` skill and the `~/.claude/scripts/scrub-pii-history.sh` recovery procedure (see [MIGRATION.md](MIGRATION.md)). Skip if you do not plan to scrub any repo's history.

## Optional Add-Ons (After Setup)

These are not required to use the dotfiles, but the dotfiles ship support for them:

### CTA - Claude Token Analyzer (with English skill patches)

[`claude-token-analyzer`](https://github.com/li195111/claude-token-analyzer) is a third-party Claude Code plugin that audits token usage across your sessions. Its skills default to 繁體中文 output; the dotfiles ship English-translated skill patches at `~/.claude/cta-english-patch/`.

**Install order matters:**

1. Install the plugin first - inside any Claude Code session, run:

   ```
   /plugin marketplace add li195111/claude-token-analyzer
   /plugin install claude-token-analyzer@claude-token-analyzer
   ```

2. Apply English skill patches (from terminal, after the plugin is installed):

   ```bash
   ~/.claude/cta-english-patch/apply.sh
   ```

3. Re-apply after every `/plugin update`. The script is idempotent and warns if upstream version drifts from the pinned translation target. See `~/.claude/cta-english-patch/README.md` for details.

If you skip step 2, the plugin works but reports are in 繁體中文.

## Setup on a New Machine

Clone the repo to wherever you keep your repos, then run the setup script from inside it:

```bash
cd /path/to/cloned/dotfiles
./setup.sh
```

`setup.sh` will:
1. Create a symlink from `~/.local/share/chezmoi` to your cloned repo so chezmoi can find it
2. Install chezmoi if it is not already installed
3. Run `chezmoi init` - prompts you to select **personal** or **work** machine (controls default git email)
4. Show a diff of any conflicts between the repo and your existing dotfiles
5. Prompt you to apply, merge interactively, or exit to resolve manually
6. Run `run_once_macos-defaults.sh` automatically (once, on first apply)

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
cd ~/repos/github.com/<your-username>/dotfiles
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

> **If you edit files directly in the repo** (not in `~/`), run `chezmoi apply` **before** committing and pushing. The pre-push hook runs `chezmoi re-add` which syncs from local -> repo. If local files are stale, it will overwrite your repo changes. Always apply first so both sides match.

## Claude Code Subagents

| Agent | Model | Purpose |
|-------|-------|---------|
| `code-reviewer` | inherit | Read-only code review |
| `researcher` | inherit | Deep research with citations |
| `debugger` | inherit | Systematic bug tracing |
| `writer` | inherit | Technical documentation |
| `security-auditor` | inherit | General security audit, threat modeling, OWASP |
| `blockchain-security-auditor` | inherit | Adversarial Solidity audit, DeFi exploit analysis |
| `solidity-engineer` | inherit | Smart contracts (EVM) |
| `dev-advocate` | inherit | Tutorials, demos, talks |
| `architect` | inherit | System design, ADRs |
| `frontend-developer` | inherit | React/Vue/Angular, UI, accessibility, performance |
| `backend-architect` | inherit | API design, scalability, server-side architecture |
| `ai-engineer` | inherit | ML models, LLM integration, RAG, embeddings |
| `devops-automator` | inherit | CI/CD, Docker, Kubernetes, GitHub Actions |
| `database-optimizer` | inherit | Schema design, query performance, indexing |
| `mcp-builder` | inherit | MCP server design and implementation |
| `accessibility-auditor` | inherit | WCAG compliance, ARIA, screen readers |
| `api-tester` | inherit | API validation, endpoint testing, OWASP API Security |

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

## Tmux

Catppuccin Mocha-inspired theme with a top status bar. No plugin manager needed.

**Key bindings (cheat sheet):**

| Action | Keys |
|--------|------|
| Split horizontal | `Ctrl-b |` |
| Split vertical | `Ctrl-b -` |
| Navigate panes | `Alt + arrow` (no prefix) |
| Resize panes | `Ctrl-b + arrow` |
| Switch windows | `Shift + left/right` (no prefix) |
| New window | `Ctrl-b c` |
| Reload config | `Ctrl-b r` |
| Copy mode | `Ctrl-b [` then `v` to select, `y` to copy |

**Session management:**

```bash
tmux new -s work     # create named session
tmux a -t work       # reattach to it later
tmux ls              # list all sessions
```

Detach with `Ctrl-b d` — the session keeps running in the background.

**Claude Code + tmux:** Start tmux first (`tmux new -s claude`), then run `claude`. When Claude spawns agent teams, they automatically get their own tmux panes. The `teammateMode` defaults to `auto` - it detects tmux and uses split panes.

**Copying text in Claude Code:** Press `Ctrl-b [` to enter copy mode, then click-drag to select text. It auto-copies to clipboard on release.

## macOS Defaults

The `run_once_macos-defaults.sh` script runs automatically on first `chezmoi apply`. It sets:
- Fast keyboard repeat, no press-and-hold
- No smart quotes/dashes/autocorrect (breaks code)
- Finder: show extensions, path bar, list view, search current folder
- Dock: auto-hide, no animation delay, no recent apps
- Screenshots: PNG, no shadow
- Auto software updates

To re-run: `chezmoi state delete-bucket --bucket=scriptState && chezmoi apply`

## Identity Setup

This repo holds no PII. Personal data (your name, emails, GPG key, GitHub username, work GitHub orgs) lives in a single file outside the repo: **`~/.config/devkit/identity.json`**. All templated configs (gitconfig and friends) read from it at apply time.

Schema (see `devkit-identity.example.json` at repo root for the canonical example):

```json
{
  "full_name": "Your Name",
  "email_personal": "you@example.com",
  "email_work": "",
  "github_username": "your-gh-username",
  "gpg_signing_key": "",
  "work_gh_orgs": ["org-1", "org-2"]
}
```

**Required fields:** `full_name`, `email_personal`, `github_username`. Others are optional.

**Three ways to create the file:**

1. **chezmoi prompts (default).** On first `chezmoi apply` the run-once bootstrap script prompts for each field and writes the JSON. Edit the file later to change values.
2. **Interactive script (no chezmoi):** run `~/.claude/scripts/setup-identity.sh` after the dotfiles `setup.sh` completes. Same prompts, no chezmoi dependency.
3. **Copy and edit:** `cp devkit-identity.example.json ~/.config/devkit/identity.json` and edit by hand.

After any edit to `~/.config/devkit/identity.json`, run `chezmoi apply` to regenerate gitconfig and other dependent files.

## External References (URLs, MCP endpoints)

A second devkit file, **`~/.config/devkit/references.json`**, holds pointers to external systems your tooling integrates with — MCP server URLs, dashboards, etc. Anything that contains a secret (e.g. an access key embedded in a URL) belongs here, not in committed dotfiles.

Schema (see `devkit-references.example.json` at repo root):

```json
{
  "open_brain_mcp_url": ""
}
```

All fields optional. Today the file is consumed by:
- `run_install-claude-mcps.sh` — reads `open_brain_mcp_url` to register the persistent-memory MCP.

If you add a new external integration that needs a secret URL or token, add a key here rather than introducing a new env var. Setup:

```bash
cp devkit-references.example.json ~/.config/devkit/references.json
chmod 600 ~/.config/devkit/references.json
$EDITOR ~/.config/devkit/references.json
```

## Machine-Specific Config

`chezmoi init` prompts for a machine type (`personal` or `work`) and stores it in `~/.config/chezmoi/chezmoi.toml`. This drives:
- **Default git email** - `email_personal` on personal machines, `email_work` on work machines (both pulled from `~/.config/devkit/identity.json`)
- **includeIf directives** - On personal machines, repos under any org listed in `work_gh_orgs` use the work email; on work machines, repos under `<github_username>/` use the personal email

To change the machine type later, edit `~/.config/chezmoi/chezmoi.toml` and re-run `chezmoi apply`.

**Local extensions (gitignored, machine-specific):**
- `~/.config/devkit/identity.json` - your identity (lives outside any repo)
- `~/.config/devkit/references.json` - external system URLs/secrets (lives outside any repo)
- `~/.config/chezmoi/chezmoi.toml` - machine type
- `~/.claude/scopes/<name>.local.txt` - private repo paths for cross-project audit skills
- `~/.claude/projects/` - auto-memory (machine-specific paths)
- `~/.claude/target-repo/` - cross-repo working-mode bindings (UUID-keyed, per-session)
- `~/.zim/` - Zim modules (installed per-machine)

**Cross-machine Claude config:** `~/.claude/settings.local.json` is now chezmoi-managed (sourced from `dot_claude/settings.local.json`). Permissions, hooks, model defaults, etc. flow across personal + work machines. Work-machine-specific things (MCPs only on personal, paths with personal username) are deliberately excluded from the baseline. A pre-commit PII scan protects against accidental PII propagation when Claude Code adds permissions interactively.

## Personal Skills That Couple to Other Repos

The committed dotfiles repo is intentionally **standalone** — no skill in `dot_claude/skills/` requires you to also clone another repo (project workspace, persistent-memory recipe repo, etc.) for it to work. Skill prose uses generic terms like "your meta-stack repo" / "your persistent-memory MCP" / "your project workspace"; if you have those, the references are meaningful, otherwise just ignore them.

If you maintain personal skills that *structurally couple* to a separate repo (e.g. a skill whose entire purpose is the maintainer-side of a 2-repo workflow with a paired data-layer recipe in another repo), the recommended pattern is to keep them **outside chezmoi management on each machine**:

```bash
# Move the skill out of chezmoi management without deleting the live files:
chezmoi forget --force ~/.claude/<your-private-skill>

# Live files at ~/.claude/<your-private-skill>/ remain functional.
# Sync them across machines via your own private mechanism (e.g. a private
# dotfiles-personal git repo, rsync, etc.) — whatever fits your threat model.
```

Why outside chezmoi: a public dotfiles fork shouldn't ship references to your private companion repos. The `chezmoi forget` pattern keeps the personal skill working on your machine without leaking into the public source.

## File Layout (chezmoi source)

```
setup.sh                         Bootstrap script for new machines
.chezmoi.toml.tmpl               Chezmoi config template (prompts for machine type)
dot_claude/                   -> ~/.claude/
  agents/                     -> ~/.claude/agents/
  skills/                     -> ~/.claude/skills/
  rules/                      -> ~/.claude/rules/
  settings.local.json         -> ~/.claude/settings.local.json
  CLAUDE.md                   -> ~/.claude/CLAUDE.md
devkit-identity.example.json     Schema example for ~/.config/devkit/identity.json
devkit-references.example.json   Schema example for ~/.config/devkit/references.json (external URLs/secrets)
dot_gitconfig.tmpl            -> ~/.gitconfig (rendered from identity.json)
dot_gitconfig-work.tmpl       -> ~/.gitconfig-work (work email from identity.json)
dot_gitconfig-personal.tmpl   -> ~/.gitconfig-personal (personal email from identity.json)
run_once_before_bootstrap-identity.sh.tmpl  First-apply hook: prompts for identity values
dot_tmux.conf                 -> ~/.tmux.conf
dot_zshrc                     -> ~/.zshrc
dot_zsh_profile               -> ~/.zsh_profile
dot_zimrc                     -> ~/.zimrc
iterm2/                          iTerm2 exported preferences (Catppuccin Mocha + Nerd Font)
run_once_macos-defaults.sh       Runs once on first chezmoi apply
run_once_setup-iterm2.sh         Installs iTerm2, Nerd Font, and Catppuccin profile
run_once_install-chezmoi-hooks.sh  Installs pre-push hook on first apply
```

## License

ISC
