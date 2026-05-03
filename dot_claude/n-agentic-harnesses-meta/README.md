# n-agentic-harnesses (vendored)

The [`n-agentic-harnesses`](https://github.com/NateBJones-Projects/OB1/tree/main/skills/n-agentic-harnesses) skill lives upstream in OB1. This dir manages the vendored copy in dotfiles so it syncs across machines.

## What's Vendored

The actual skill files live one level up at `dot_claude/skills/n-agentic-harnesses/` (chezmoi-managed). They get applied to `~/.claude/skills/n-agentic-harnesses/` on every `chezmoi apply`.

This dir is a separate sibling holding maintenance metadata, not the skill itself.

## Pinning

`PINNED_COMMIT` records the upstream OB1 SHA the vendored copy was synced from. Bump it deliberately to track upstream changes; never silently drift.

## Refreshing From Upstream

**Always run from the dotfiles SOURCE directory, not from live**, so the script writes to the chezmoi-managed source path:

```bash
cd ~/repos/.../dotfiles/dot_claude/n-agentic-harnesses-meta

# Refresh against current pin (no version change):
./executable_refresh-from-upstream.sh

# Bump pin to a new commit and refresh:
COMMIT=<new-sha> ./executable_refresh-from-upstream.sh
```

The script uses its own location to compute the target dir (`$SCRIPT_DIR/../skills/n-agentic-harnesses`). When run from dotfiles source, it writes to the source skill dir. After running:

1. Review `git diff` in dotfiles to see what changed upstream.
2. `chezmoi apply --force` to push the changes to `~/.claude/skills/n-agentic-harnesses/`.
3. Commit + push the dotfiles diff.

Running from the live copy (`~/.claude/n-agentic-harnesses-meta/refresh-from-upstream.sh`) writes to live (`~/.claude/skills/`) instead of source. The live copy gets reverted on next `chezmoi apply` if source has not been updated, so always run from source for cross-machine sync.

The script:
- Wipes the target dir first (catches upstream deletions)
- Re-fetches all 17 files from the pinned SHA
- Updates `PINNED_COMMIT` if `COMMIT=` env was set
- Idempotent

## Why Vendor At All

n-agentic-harnesses is a markdown skill (no binary). We could symlink directly to a local OB1 clone, but vendoring is cleaner for cross-machine sync via dotfiles. Same pattern as `cta-english-patch/` for the other plugin patches we maintain.

## Upstream Watch

OB1 is actively developed. When the skill changes upstream, we have to deliberately pull. Cadence: re-check every ~60 days, or when Nate publishes new content about harness patterns.
