---
name: using-chezmoi-properly
description: Use when working in a chezmoi-managed dotfiles repo and chezmoi behavior surprises you - a `run_once_*` script not retrying after a precondition flip, `chezmoi diff` showing phantom diffs for plain `run_*` scripts, `chezmoi re-add` failing on `.tmpl` files, settings.json drift after Claude Code edits, or files claimed to be dotfiles-managed but `chezmoi managed` lists them as not-managed. Produces concrete chezmoi source edits, hook patches, and divergence-resolution decisions. Covers the rules that aren't in chezmoi's own docs because they only show up when multiple chezmoi behaviors interact.
---

# Using Chezmoi Properly

## Purpose

Chezmoi's documented behaviors are individually fine. The footguns happen at the intersections — `run_once_*` plus a precondition that flips, plain `run_*` plus a pre-commit hook that consumes `chezmoi diff`, `.tmpl` files plus dynamic scripts that write to live, hidden-file source paths plus the required `dot_` prefix. This skill consolidates the interaction rules from real incidents so the next person (you or another agent) doesn't rediscover them.

## When To Use

Trigger phrases / situations:

- "this chezmoi script isn't running again"
- "chezmoi diff shows divergence but I haven't touched anything"
- "I tried `chezmoi re-add` but the template didn't update"
- "the README says X is dotfiles-managed but it isn't actually syncing"
- "settings.json (or another file) keeps getting clobbered"
- About to add a new `run_*` script and unsure which variant (`once` / `onchange` / plain) to use
- About to chezmoi-manage a file that another process (e.g. Claude Code) also writes to
- Bootstrapping a fresh machine and the apply behavior is unexpected
- Designing a chezmoi-managed primitive that needs to work across personal AND work machines

## When NOT To Use

- The chezmoi behavior is fully explained by chezmoi's own docs (e.g. basic `dot_` prefix, basic `chezmoi apply`). Skim this skill first — if your situation matches one of the rules below, use it; otherwise read the actual chezmoi docs.
- The issue is generic git or shell behavior with chezmoi as the bystander.

## Core Rules (ordered by frequency-of-bite)

### Rule 1: `run_once_*` is content-hash-gated, not precondition-gated

Chezmoi runs `run_once_<name>` scripts exactly once per content hash per machine. If a script's content doesn't change, it never re-runs — even if a precondition the script checks for (a binary, a config file, an installed tool) flips from missing to present later.

**Manifest:** the script logs a "skipping because X not installed" line on first apply, then sits idle forever even after the user installs X.

**Fix:** rename to plain `run_<name>` (no `_once_` or `_onchange_`). Plain `run_*` runs on every `chezmoi apply`. Safe if the script is already idempotent. Cost: a few extra checks per apply (cheap).

**Naming reference:**
- `run_<name>` → every apply
- `run_once_<name>` → once per content hash per machine
- `run_onchange_<name>` → when the script's content changes (similar to once for most purposes)
- `run_once_before_<name>` / `run_onchange_after_<name>` → ordering variants

Rule of thumb: use `run_once_*` for true one-shots (homebrew install, GUI app setup); use plain `run_*` for anything where a precondition could legitimately flip.

### Rule 2: `chezmoi diff` shows phantom diffs for plain `run_*` scripts

Plain `run_*` scripts have no chezmoi-tracked state (they always run), so they always appear in `chezmoi diff` output as "new file" representations of what the script would do.

**Manifest:** a pre-commit hook that wraps `chezmoi diff` aborts every commit, even on a clean source tree, because plain `run_*` scripts produce perpetual phantom diff output.

**Fix:** in any hook that consumes `chezmoi diff` for divergence-detection purposes, use `chezmoi diff --exclude=scripts`. Scripts are not files; the divergence check is about files. Excluding scripts preserves the hook's safety guarantee (pre-push `chezmoi re-add` does not touch scripts either, so script "divergence" can't be silently reverted).

### Rule 3: `chezmoi re-add` cannot reverse-engineer templates

`chezmoi re-add` copies live → source. For non-template source files, this is a clean copy. For `.tmpl` source files, chezmoi would need to "un-render" the live content back into a template — which is impossible (which template variables produced which substrings is not recoverable).

**Manifest:** you have a `.tmpl` source file. A script (or Claude Code) edits live. You run `chezmoi re-add`. Nothing happens to the source. Divergence persists.

**Fix paths:**
1. Update the template source directly so it renders to the live content you want.
2. Convert the source from `.tmpl` to a plain file (lose templating) and re-add can now work.
3. Move dynamic content out of the chezmoi-managed file entirely — into a separate machine-local file the templated file references.

### Rule 4: Hidden-file source paths require the `dot_` prefix

`~/.claude/foo` is the live target. The chezmoi source path is `dot_claude/foo`, NOT `.claude/foo`. Bare `.<rest>` paths in the chezmoi source root are reserved for chezmoi's own metadata (`.chezmoiignore`, `.chezmoidata`, etc.) and are NOT mapped to live $HOME files.

**Manifest:** a file lives at `.claude/foo` in the dotfiles repo. The README claims it is dotfiles-managed. `chezmoi managed` does not list it. Multi-machine drift persists silently. Live $HOME and the orphan-in-repo file are two unrelated files that happen to share content for one snapshot in time.

**Fix:** `git mv .claude/foo dot_claude/foo`. Update any docs that pointed at the old path. Run `chezmoi apply` to materialize. Verify with `chezmoi managed | grep foo`.

### Rule 5: Files Claude Code writes to should not be plain chezmoi-managed

`~/.claude/settings.json` is written by Claude Code itself when plugins install, when settings change via the UI, when permissions are granted via in-chat prompts. If chezmoi manages it as a plain file, chezmoi `apply` would clobber those writes; if it does not manage it, dotfiles drift across machines.

**Pattern:** put `~/.claude/settings.json` in `.chezmoiignore` and use `~/.claude/settings.local.json` for the dotfiles-managed cross-machine baseline. Claude Code reads BOTH and merges them. settings.local.json is rarely auto-written by Claude Code (mostly user-grant captures), so chezmoi management works there.

**Alternative pattern (for dynamic content):** use a `run_*` script that idempotently patches live settings.local.json via `jq`. Source has the static baseline; script adds/removes per-machine dynamic bits (MCP registrations gated on binary presence, etc.).

### Rule 6: Work machines often have settings.json locked

On managed machines (IT-policy enforced via MDM, or some enterprise mode), `~/.claude/settings.json` may be unwritable. Any cross-machine dotfiles pattern that needs to write hooks/permissions/config MUST target settings.local.json, NOT settings.json. The locked-on-work constraint forces this.

## Procedural Patterns

### Pattern A: Adding a new `run_*` script

1. Decide cadence: plain `run_*` if precondition can flip; `run_once_*` if true one-shot; `run_onchange_*` is rarely the right answer (similar to once).
2. Inside the script, defend against missing tools: `if ! command -v <tool> >/dev/null 2>&1; then echo "skipping"; exit 0; fi`. Plain `run_*` scripts run every apply, so they must no-op gracefully on machines lacking the prerequisite tool.
3. Inside the script, defend against partial state: every operation should be idempotent. Use `installed()` checks (`claude mcp list | grep -q`), or `jq -e ".x | index(\"y\")"` for JSON arrays.
4. If the script writes to a chezmoi-managed file (settings.local.json, etc.), accept that you'll get `chezmoi diff` drift between source and live until the next apply. Source the file from chezmoi; mutate from script; document the design.

### Pattern B: Adding a hook to settings.local.json cross-machine

Two options. Use Option 1 unless you have a specific reason to use Option 2.

**Option 1 (static baseline):** put the hook directly in `dot_claude/settings.local.json.tmpl`. Every chezmoi apply writes the hook into live. Simple. No installer script.

**Option 2 (dynamic installer):** write a `run_install-claude-hooks.sh` script that idempotently merges the hook into live settings.local.json via `jq` (similar to the MCP-registration pattern). Use this when the hook content depends on machine state, OR when you want defense-in-depth against accidental hook removal.

For the work-machine constraint: settings.local.json is writable on both personal and work. Either option works on both.

### Pattern C: Resolving a "chezmoi source/live divergence" pre-commit abort

The pre-commit hook's typical message lists three options:

- `chezmoi apply --force` → source wins; live overwritten. Use when you trust source and live just has stale state.
- `chezmoi re-add` → live wins; source overwritten. Use when live has user-edits you want to keep + source is stale. **Fails on `.tmpl` files** (Rule 3); for those, edit source directly.
- `chezmoi merge-all` → interactive 3-way merge. Use when both source and live have unique edits worth preserving.

If the divergence is just a phantom diff from a plain `run_*` script (Rule 2), patch the hook to use `chezmoi diff --exclude=scripts` and re-attempt.

If the divergence is from a `.tmpl` file plus a dynamic script that writes to live (chezmoi-managed-baseline + script-driven mutations), the divergence is BY DESIGN. Either accept it (use `--force` after every apply / commit cycle), or restructure so the script's writes match what the template renders.

### Pattern D: Verifying a file is actually chezmoi-managed

Quick check: `chezmoi managed | grep <path>`. If absent, the file is not managed regardless of where it sits in the source tree.

Common cause for "claimed managed but not actually": missing `dot_` prefix (Rule 4) or the path is in `.chezmoiignore`.

## Output Contract

This skill produces inline guidance + concrete chezmoi source edits. Specifically:

**Required outputs:**
- Identification of which Rule (1-6) the situation maps to
- The exact `git mv` / file rename / hook patch needed to fix
- A `chezmoi apply` (with or without `--force`) and verification command

**Optional outputs:**
- A summary edit to the dotfiles README if the misunderstanding traced to a stale claim there
- A `[Friction]` thought capture + friction-log dual-write if a footgun was hit

**Out of scope (this skill does NOT produce):**
- Chezmoi documentation rewrites
- A generic chezmoi tutorial (link to chezmoi's actual docs)
- Cross-tool sync mechanisms (rsync, Syncthing, etc.)

**Format guarantees:**
- Edits are made to source paths (chezmoi sourcedir), never live $HOME files directly
- After edits, `chezmoi apply` is the next step (not `cp` or manual file ops)

## Common Pitfalls

- **"It worked on first apply, so it's done."** First apply often hides `run_once_*` precondition bugs because the precondition happens to be met then. The bug surfaces on the SECOND machine.
- **Editing live `$HOME/.claude/settings.local.json` directly without re-adding to source.** Pre-push `chezmoi re-add` catches most cases, but a long stretch between commits can lose work. Always edit source.
- **Using `chezmoi apply --force` reflexively.** It is destructive to live state. The pre-commit hook offers it as ONE of three resolution paths for a reason. Prefer `chezmoi re-add` when live has user-edits.
- **Forgetting that `~/.local/share/chezmoi` is the canonical source path.** If your dotfiles git checkout lives at `~/repos/github.com/<you>/dotfiles`, that path should be a symlink TO `~/.local/share/chezmoi` (or vice versa). The setup.sh in this dotfiles repo handles the symlink; verify with `readlink ~/.local/share/chezmoi`.
- **Assuming `.git/hooks/` is chezmoi-managed.** It's per-clone, not version-controlled. Hooks are installed by `run_once_install-chezmoi-hooks.sh` writing them via heredocs into the live `.git/hooks/` directory. Update the heredoc in the installer, not `.git/hooks/<hook>` directly (those changes are local to this clone).

## Source

Operationalized from a dotfiles overhaul session of 2026-05-13 → 2026-05-14 — see this dotfiles repo's commits `ad92b13` (run_once footgun fix) and `ae63d2b` (settings.local.json migration + cross-repo PII bundle). The rule extraction came from five distinct frictions that hit during a fresh work-machine engram bootstrap + meta-stack infrastructure overhaul. See `[Pattern]` and `[Friction]` thoughts dated 2026-05-13 / 2026-05-14 in your persistent-memory MCP(s) for the source incidents.

---

**Version:** 1.0.0
