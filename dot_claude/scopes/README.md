# Improvement Scopes

This directory holds named improvement scopes for `learn-and-improve` and other audit skills.

Each `.txt` file defines one scope. Format: one absolute or `~/`-prefixed repo path per line. Comments allowed (lines starting with `#`).

## Public vs Local (Machine-Specific) Files

Each scope can have two files:

- `<name>.txt` - **committed to dotfiles**, syncs to all machines via chezmoi. Contains the default repos that are public or shared across all your machines.
- `<name>.local.txt` - **NOT committed** (gitignored via `*.local.txt` rule). Machine-specific additions: private repos, work-only repos, client-specific repos. Each machine has its own.

Skills that consume scopes read BOTH files (committed + local) and merge them, deduplicating paths.

This pattern is identical to Claude Code's own `settings.json` + `settings.local.json` split.

## Existing Scopes

- `meta-stack.txt` - the user's cross-project Claude tooling scope. The committed file is intentionally empty (no user-specific paths leak into a public dotfiles repo). All actual repo paths — your dotfiles, project workspace, persistent-memory repo, work repos, etc. — go in `meta-stack.local.txt` (gitignored, machine-local). The combined audit target is the union of both files, deduplicated and tilde-expanded.

## Adding a New Scope

Two flavors:

### Public scope (synced to all machines)
Create `~/.claude/scopes/<scope-name>.txt` and commit it via chezmoi-add + git commit.

### Local-only scope (this machine only)
Create `~/.claude/scopes/<scope-name>.local.txt` directly. Don't run `chezmoi add` on it. The `.gitignore` rule will prevent accidental commits even if you do.

### Mixed (public defaults + machine-specific extras)
Create both `<scope-name>.txt` (public) and `<scope-name>.local.txt` (extras). The skill merges them.

Example layout for a Solutions Architect across multiple machines:
```
~/.claude/scopes/
├── meta-stack.txt           # committed: empty (header-only stub)
├── meta-stack.local.txt     # personal machine: dotfiles + project workspace + persistent-memory repo
├── client-projects.local.txt  # work machine only: + client repos
└── work-internal.local.txt    # work machine only: + employer-internal repos
```

## Reading a Scope from a Skill

```bash
SCOPE_NAME="meta-stack"
PUBLIC="$HOME/.claude/scopes/${SCOPE_NAME}.txt"
LOCAL="$HOME/.claude/scopes/${SCOPE_NAME}.local.txt"

# Read both files (if they exist), strip comments and blanks, expand ~, dedup
REPOS=$(
  { [ -f "$PUBLIC" ] && cat "$PUBLIC"; [ -f "$LOCAL" ] && cat "$LOCAL"; } 2>/dev/null \
  | grep -v '^#' \
  | grep -v '^$' \
  | sed "s|^~|$HOME|" \
  | sort -u
)
```

## Listing Available Scopes

```bash
# Lists every scope, regardless of whether it has a .txt, .local.txt, or both
ls ~/.claude/scopes/*.txt 2>/dev/null \
  | xargs -n1 basename \
  | sed 's/\.local\.txt$/.txt/' \
  | sort -u \
  | sed 's/\.txt$//'
```

## Notes

- File-per-scope (not single JSON) is intentional - matches Karpathy timing principle. Start simple; evolve to JSON only if multiple metadata fields per scope become a real need.
- Use `~/` syntax for paths so files are portable across machines with different home-directory conventions. Skill code expands `~` to `$HOME` when reading.
- Skills that consume scopes should always merge public + local and dedup. Don't read only one.
- Don't `chezmoi add` `.local.txt` files. Create them directly in your live home. The `.gitignore` rule (`*.local.txt`) is defense-in-depth.
