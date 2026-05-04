# CTA English Skill Patch

Translates the [`claude-token-analyzer`](https://github.com/li195111/claude-token-analyzer) plugin's skills from 繁體中文 to English. The plugin's analyzer engine (Rust + MCP server) is unchanged - this only patches the SKILL.md prompt files so output is in English.

## Prerequisite

The plugin must be installed first. Inside any Claude Code session, run:

```
/plugin marketplace add li195111/claude-token-analyzer
/plugin install claude-token-analyzer@claude-token-analyzer
```

## Apply Patches

After install (or after `/plugin update`), run:

```bash
~/.claude/cta-english-patch/apply.sh
```

The script:
- Detects the installed plugin version
- Warns if version differs from `PINNED_VERSION` (currently `0.1.0`)
- Copies translated SKILL.md files over the installed ones
- Idempotent - safe to re-run

## What Gets Patched

Seven skill files in `~/.claude/plugins/cache/claude-token-analyzer/claude-token-analyzer/<version>/skills/`:

- `cta` (router)
- `cta-health-check`
- `cta-cost-audit`
- `cta-anomaly-hunt`
- `cta-project-review`
- `cta-trend-watch`
- `cta-usage-pattern`

The MCP server (Rust binary), pricing tables, hooks, and references are NOT modified.

## When to Re-Apply

- After every `/plugin update` (the patch directory should be updated against the new upstream version first if the upstream skills changed).
- After re-installing Claude Code or moving to a new machine (chezmoi syncs the patch dir; you still need to install the plugin and run apply.sh).

## Maintenance

If upstream ships a new plugin version, the patch directory will be out of sync. The script refuses to apply by default in that case (warns + exits). To update:

1. Read the upstream SKILL.md files at the new version.
2. Update each `skills/<name>/SKILL.md` in this patch directory.
3. Bump `PINNED_VERSION` to the new upstream version.
4. Re-run `apply.sh`.

The maintainer-friendly long-term fix is to land an upstream config option (`CTA_LANG=en` env var or skill flag). File an upstream issue when you have time.

## Why This Exists

The plugin's skills hardcode 繁體中文 output via skill-prompt instructions and template strings. There is no runtime language config. Per the parallel-tool check (Phase 3.5/3.6 lens Q6 in `learn-and-improve`), the right path is contribute upstream first and only patch locally as a temporary workaround. This patch is the temporary workaround.
